using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using DriveOps.Application.DTOs;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace DriveOps.Infrastructure.Services
{
    public class KeycloakAdminService : IKeycloakAdminService
    {
        // Typed clients are transient — the token cache must be shared across instances.
        private static readonly SemaphoreSlim TokenLock = new(1, 1);
        private static string? CachedToken;
        private static DateTime CachedTokenExpiresUtc = DateTime.MinValue;

        private readonly HttpClient _httpClient;
        private readonly string _realm;
        private readonly string _clientId;
        private readonly string _clientSecret;

        public KeycloakAdminService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;

            var adminBaseUrl = (configuration["Keycloak:AdminBaseUrl"] ?? "http://localhost:8081").TrimEnd('/');
            _httpClient.BaseAddress = new Uri(adminBaseUrl + "/");
            _httpClient.Timeout = TimeSpan.FromSeconds(15);

            var authority = (configuration["Keycloak:Authority"] ?? $"{adminBaseUrl}/realms/driveops-dev").TrimEnd('/');
            _realm = authority.Split('/').Last();

            _clientId = configuration["Keycloak:AdminClientId"] ?? "driveops-backend";
            // No secret fallback — supply Keycloak:AdminClientSecret via env/.env.
            _clientSecret = configuration["Keycloak:AdminClientSecret"] ?? string.Empty;
        }

        public async Task<List<KeycloakUserDto>> SearchUsersAsync(string search)
        {
            var token = await GetAccessTokenAsync();
            var url = $"admin/realms/{_realm}/users?search={Uri.EscapeDataString(search ?? string.Empty)}&briefRepresentation=true&max=20";
            var users = await GetAsync<List<KeycloakUserDto>>(token, url);
            return users ?? [];
        }

        public async Task<KeycloakUserDto?> GetUserByIdAsync(string userId)
        {
            var token = await GetAccessTokenAsync();
            var url = $"admin/realms/{_realm}/users/{Uri.EscapeDataString(userId)}";
            using var response = await SendAsync(token, HttpMethod.Get, url);
            if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                return null;
            if (!response.IsSuccessStatusCode)
                throw new InvalidOperationException($"Keycloak admin call '{url}' failed with status {(int)response.StatusCode}.");
            return await response.Content.ReadFromJsonAsync<KeycloakUserDto>();
        }

        public async Task<List<string>> GetUserRealmRolesAsync(string userId)
        {
            var token = await GetAccessTokenAsync();
            var url = $"admin/realms/{_realm}/users/{Uri.EscapeDataString(userId)}/role-mappings/realm";
            var roles = await GetAsync<List<KeycloakRoleRepresentation>>(token, url);
            return roles?.Select(r => r.Name).Where(n => n != null).Cast<string>().ToList() ?? [];
        }

        public async Task AssignRealmRoleAsync(string userId, string roleName)
        {
            var existingRoles = await GetUserRealmRolesAsync(userId);
            if (existingRoles.Contains(roleName))
                return;

            var token = await GetAccessTokenAsync();
            var roleUrl = $"admin/realms/{_realm}/roles/{Uri.EscapeDataString(roleName)}";
            var role = await GetAsync<KeycloakRoleRepresentation>(token, roleUrl)
                ?? throw new InvalidOperationException($"Realm role '{roleName}' not found in Keycloak realm '{_realm}'.");

            var assignUrl = $"admin/realms/{_realm}/users/{Uri.EscapeDataString(userId)}/role-mappings/realm";
            using var request = new HttpRequestMessage(HttpMethod.Post, assignUrl)
            {
                Content = JsonContent.Create(new[]
                {
                    new KeycloakRoleRepresentation { Id = role.Id, Name = role.Name }
                })
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            using var response = await _httpClient.SendAsync(request);
            if (!response.IsSuccessStatusCode)
                throw new InvalidOperationException($"Keycloak role assignment failed with status {(int)response.StatusCode}.");
        }

        public async Task<KeycloakUserDto> CreateUserAsync(string username, string? email, string? firstName, string? lastName, string temporaryPassword)
        {
            var token = await GetAccessTokenAsync();
            var url = $"admin/realms/{_realm}/users";
            var payload = new KeycloakCreateUserRequest
            {
                Username = username,
                Email = email,
                FirstName = firstName,
                LastName = lastName,
                Enabled = true,
                EmailVerified = true,
                Credentials =
                [
                    // Temporary password: Keycloak forces a change at first login (UPDATE_PASSWORD).
                    new KeycloakCredential { Type = "password", Value = temporaryPassword, Temporary = true }
                ]
            };
            using var request = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = JsonContent.Create(payload)
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            using var response = await _httpClient.SendAsync(request);

            if (response.StatusCode == System.Net.HttpStatusCode.Conflict)
            {
                var error = await response.Content.ReadFromJsonAsync<KeycloakErrorResponse>();
                throw new KeycloakUserConflictException(
                    error?.ErrorMessage ?? $"A Keycloak user with username '{username}' or this email already exists.");
            }
            if (!response.IsSuccessStatusCode)
                throw new InvalidOperationException($"Keycloak user creation failed with status {(int)response.StatusCode}.");

            // Keycloak returns 201 with the new user URL in the Location header (…/users/{id}).
            var location = response.Headers.Location?.ToString()
                ?? throw new InvalidOperationException("Keycloak user creation returned no Location header.");
            var id = location.TrimEnd('/').Split('/').Last();

            return new KeycloakUserDto
            {
                Id = id,
                Username = username,
                Email = email,
                FirstName = firstName,
                LastName = lastName,
                Enabled = true
            };
        }

        private async Task<T?> GetAsync<T>(string token, string url)
        {
            using var response = await SendAsync(token, HttpMethod.Get, url);
            if (!response.IsSuccessStatusCode)
                throw new InvalidOperationException($"Keycloak admin call '{url}' failed with status {(int)response.StatusCode}.");
            return await response.Content.ReadFromJsonAsync<T>();
        }

        private Task<HttpResponseMessage> SendAsync(string token, HttpMethod method, string url)
        {
            using var request = new HttpRequestMessage(method, url);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return _httpClient.SendAsync(request);
        }

        private async Task<string> GetAccessTokenAsync()
        {
            await TokenLock.WaitAsync();
            try
            {
                if (CachedToken != null && DateTime.UtcNow < CachedTokenExpiresUtc.AddSeconds(-60))
                    return CachedToken;

                var body = new Dictionary<string, string>
                {
                    ["grant_type"] = "client_credentials",
                    ["client_id"] = _clientId,
                    ["client_secret"] = _clientSecret
                };
                using var request = new HttpRequestMessage(HttpMethod.Post, $"realms/{_realm}/protocol/openid-connect/token")
                {
                    Content = new FormUrlEncodedContent(body)
                };
                using var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                    throw new InvalidOperationException($"Keycloak client-credentials token request failed with status {(int)response.StatusCode}.");

                var tokenResponse = await response.Content.ReadFromJsonAsync<KeycloakTokenResponse>()
                    ?? throw new InvalidOperationException("Keycloak token response was empty.");

                CachedToken = tokenResponse.AccessToken;
                CachedTokenExpiresUtc = DateTime.UtcNow.AddSeconds(tokenResponse.ExpiresIn);
                return CachedToken;
            }
            finally
            {
                TokenLock.Release();
            }
        }

        private class KeycloakTokenResponse
        {
            [JsonPropertyName("access_token")]
            public string AccessToken { get; set; } = null!;

            [JsonPropertyName("expires_in")]
            public long ExpiresIn { get; set; }
        }

        private class KeycloakRoleRepresentation
        {
            [JsonPropertyName("id")]
            public string? Id { get; set; }

            [JsonPropertyName("name")]
            public string? Name { get; set; }
        }

        private class KeycloakCredential
        {
            [JsonPropertyName("type")]
            public string Type { get; set; } = null!;

            [JsonPropertyName("value")]
            public string Value { get; set; } = null!;

            [JsonPropertyName("temporary")]
            public bool Temporary { get; set; }
        }

        private class KeycloakCreateUserRequest
        {
            [JsonPropertyName("username")]
            public string Username { get; set; } = null!;

            [JsonPropertyName("email")]
            public string? Email { get; set; }

            [JsonPropertyName("firstName")]
            public string? FirstName { get; set; }

            [JsonPropertyName("lastName")]
            public string? LastName { get; set; }

            [JsonPropertyName("enabled")]
            public bool Enabled { get; set; }

            [JsonPropertyName("emailVerified")]
            public bool EmailVerified { get; set; }

            [JsonPropertyName("credentials")]
            public List<KeycloakCredential> Credentials { get; set; } = [];
        }

        private class KeycloakErrorResponse
        {
            [JsonPropertyName("errorMessage")]
            public string? ErrorMessage { get; set; }
        }
    }
}
