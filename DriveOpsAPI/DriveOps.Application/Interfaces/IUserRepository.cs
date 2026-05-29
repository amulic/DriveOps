using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IUserRepository : IRepository<User>
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByKeycloakIdAsync(string keycloakId);
        Task<bool> EmailExistsAsync(string email);
        Task<IEnumerable<User>> GetActiveUsersAsync();
        Task<IEnumerable<User>> GetByIdsAsync(IEnumerable<Guid> ids);
    }
}
