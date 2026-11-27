using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using FluentValidation;

namespace DriveOps.Application.Services
{
    public class AccountAdminService : IAccountAdminService
    {
        public static readonly string[] AppRoles = ["admin", "dispatcher", "driver", "customer"];

        private readonly IKeycloakAdminService _keycloak;
        private readonly IDriverRepository _driverRepository;

        public AccountAdminService(IKeycloakAdminService keycloak, IDriverRepository driverRepository)
        {
            _keycloak = keycloak;
            _driverRepository = driverRepository;
        }

        public async Task<List<AccountDto>> GetAccountsAsync(string? search, int first, int max, CancellationToken cancellationToken = default)
        {
            var users = await _keycloak.GetUsersAsync(search, first, max);
            var roleTasks = users.Select(async user => new
            {
                User = user,
                Roles = await _keycloak.GetUserRealmRolesAsync(user.Id)
            });

            var results = await Task.WhenAll(roleTasks);

            return results.Select(r => ToDto(
                    r.User.Id, r.User.Username, r.User.Email,
                    r.User.FirstName, r.User.LastName, r.User.Enabled, r.Roles))
                .ToList();
        }

        public async Task<AccountDto> CreateAccountAsync(CreateAccountDto dto, CancellationToken cancellationToken = default)
        {
            var roles = NormalizeRoles(dto.Roles);

            var user = await _keycloak.CreateUserAsync(
                dto.Username, dto.Email, dto.FirstName, dto.LastName, dto.TemporaryPassword);

            foreach (var role in roles)
                await _keycloak.AssignRealmRoleAsync(user.Id, role);

            return ToDto(user.Id, user.Username, user.Email, user.FirstName, user.LastName, true, roles);
        }

        public async Task<AccountDto> UpdateAccountAsync(string accountId, UpdateAccountDto dto, CancellationToken cancellationToken = default)
        {
            if (dto.FirstName != null || dto.LastName != null || dto.Email != null)
                await _keycloak.UpdateUserAsync(accountId, dto.FirstName, dto.LastName, dto.Email);

            if (dto.Enabled.HasValue)
                await _keycloak.SetUserEnabledAsync(accountId, dto.Enabled.Value);

            var user = await _keycloak.GetUserByIdAsync(accountId)
                ?? throw new KeyNotFoundException($"Account {accountId} not found.");
            var roles = await _keycloak.GetUserRealmRolesAsync(accountId);

            return ToDto(user.Id, user.Username, user.Email, user.FirstName, user.LastName, user.Enabled, roles);
        }

        public async Task<AccountDto> SetRolesAsync(string accountId, IReadOnlyCollection<string> roles, CancellationToken cancellationToken = default)
        {
            var desired = NormalizeRoles(roles);
            var current = await _keycloak.GetUserRealmRolesAsync(accountId);

            // Keep the driver role while a local driver profile is linked to the account.
            if (current.Contains("driver") && !desired.Contains("driver")
                && Guid.TryParse(accountId, out var keycloakGuid)
                && await _driverRepository.GetByKeycloakIdAsync(keycloakGuid) != null)
                throw new InvalidOperationException(
                    "This account has a linked driver profile; suspend or retire the driver instead of removing the driver role.");

            foreach (var role in AppRoles.Where(r => current.Contains(r) && !desired.Contains(r)))
                await _keycloak.RemoveRealmRoleAsync(accountId, role);

            foreach (var role in desired.Where(r => !current.Contains(r)))
                await _keycloak.AssignRealmRoleAsync(accountId, role);

            var user = await _keycloak.GetUserByIdAsync(accountId)
                ?? throw new KeyNotFoundException($"Account {accountId} not found.");
            var updatedRoles = await _keycloak.GetUserRealmRolesAsync(accountId);

            return ToDto(user.Id, user.Username, user.Email, user.FirstName, user.LastName, user.Enabled, updatedRoles);
        }

        public Task ResetPasswordAsync(string accountId, string temporaryPassword, CancellationToken cancellationToken = default)
            => _keycloak.ResetPasswordAsync(accountId, temporaryPassword);

        private static List<string> NormalizeRoles(IEnumerable<string> roles)
        {
            var normalized = roles
                .Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim().ToLowerInvariant())
                .Distinct()
                .ToList();

            var invalid = normalized.Where(r => !AppRoles.Contains(r)).ToList();
            if (invalid.Count > 0)
                throw new InvalidOperationException(
                    $"Unknown role(s): {string.Join(", ", invalid)}. Allowed: {string.Join(", ", AppRoles)}.");

            return normalized;
        }

        private static AccountDto ToDto(
            string id, string username, string? email,
            string? firstName, string? lastName, bool enabled, IEnumerable<string> roles)
            => new(
                id,
                username,
                email,
                firstName,
                lastName,
                enabled,
                roles.Where(r => AppRoles.Contains(r)).Distinct().OrderBy(r => r).ToList());
    }
}
