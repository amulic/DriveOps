using DriveOps.Model.Entity;

namespace DriveOps.Infrastructure.Interface
{
    public interface IUserRepository : IRepository<User>
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByKeycloakIdAsync(string keycloakId);
        Task<bool> EmailExistsAsync(string email);
        Task<IEnumerable<User>> GetActiveUsersAsync();
    }
}
