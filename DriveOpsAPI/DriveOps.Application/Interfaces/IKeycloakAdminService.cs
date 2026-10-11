using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IKeycloakAdminService
    {
        Task<List<KeycloakUserDto>> SearchUsersAsync(string search);
        Task<KeycloakUserDto?> GetUserByIdAsync(string userId);
        Task<List<string>> GetUserRealmRolesAsync(string userId);
        Task AssignRealmRoleAsync(string userId, string roleName);
        Task<KeycloakUserDto> CreateUserAsync(string username, string? email, string? firstName, string? lastName, string temporaryPassword);
    }
}
