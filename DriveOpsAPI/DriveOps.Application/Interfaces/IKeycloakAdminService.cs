using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IKeycloakAdminService
    {
        Task<List<KeycloakUserDto>> SearchUsersAsync(string search);
        Task<List<KeycloakUserDto>> GetUsersAsync(string? search, int first, int max);
        Task<KeycloakUserDto?> GetUserByIdAsync(string userId);
        Task<List<string>> GetUserRealmRolesAsync(string userId);
        Task AssignRealmRoleAsync(string userId, string roleName);
        Task RemoveRealmRoleAsync(string userId, string roleName);
        Task<KeycloakUserDto> CreateUserAsync(string username, string? email, string? firstName, string? lastName, string temporaryPassword);
        Task UpdateUserAsync(string userId, string? firstName, string? lastName, string? email);
        Task SetUserEnabledAsync(string userId, bool enabled);
        Task ResetPasswordAsync(string userId, string temporaryPassword);
    }
}
