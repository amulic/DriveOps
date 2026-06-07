using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IUserService
    {
        Task<UserDto?> GetUserByIdAsync(Guid userId);
        Task<UserDto?> GetUserByKeycloakIdAsync(string keycloakId);
        Task<UserDto> CreateUserAsync(CreateUserDto dto);
        Task<UserDto> UpdateUserAsync(UpdateUserDto dto);
        Task<UserDto> CreateOrUpdateFromKeycloakAsync(string keycloakId, string email, string firstName, string lastName);
        Task UpdateLastLoginAsync(Guid userId);
        Task<IEnumerable<UserDto>> GetUsersByIdsAsync(IEnumerable<Guid> userIds);
        Task<IEnumerable<UserDto>> GetUsersByKeycloakIdsAsync(IEnumerable<string> keycloakIds);
    }
}
