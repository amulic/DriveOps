using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using DriveOps.RealTime.Contracts.Enums;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace DriveOps.RealTime.Hubs.Services;

public class ApiDriverProfileResolver : IDriverProfileResolver
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(2);

    private readonly HttpClient _httpClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ApiDriverProfileResolver> _logger;

    public ApiDriverProfileResolver(
        HttpClient httpClient,
        IMemoryCache cache,
        ILogger<ApiDriverProfileResolver> logger)
    {
        _httpClient = httpClient;
        _cache = cache;
        _logger = logger;
    }

    public async Task<DriverProfileSnapshot?> GetByUserAsync(
        Guid userKeycloakId,
        string? accessToken,
        CancellationToken cancellationToken = default)
    {
        var cacheKey = $"driver-profile:{userKeycloakId}";
        if (_cache.TryGetValue<DriverProfileSnapshot>(cacheKey, out var cached) && cached != null)
            return cached;

        using var request = new HttpRequestMessage(HttpMethod.Get, $"api/driver/keycloak/{userKeycloakId}");
        if (!string.IsNullOrWhiteSpace(accessToken))
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        if (response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.Forbidden)
            return null;

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Driver profile lookup for {KeycloakId} failed with {StatusCode}",
                userKeycloakId, (int)response.StatusCode);
            return null;
        }

        var profile = await response.Content.ReadFromJsonAsync<DriverProfileResponse>(cancellationToken: cancellationToken);
        if (profile == null)
            return null;

        var snapshot = new DriverProfileSnapshot(
            profile.Id,
            (DriverStatus)(profile.Status ?? (int)DriverStatus.Pending),
            profile.IsOnline ?? false);

        _cache.Set(cacheKey, snapshot, CacheTtl);
        return snapshot;
    }

    private sealed class DriverProfileResponse
    {
        public Guid Id { get; set; }
        public int? Status { get; set; }
        public bool? IsOnline { get; set; }
    }
}
