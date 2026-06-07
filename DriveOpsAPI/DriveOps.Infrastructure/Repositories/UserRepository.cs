using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class UserRepository : Repository<User>, IUserRepository
    {
        public UserRepository(ApplicationDbContext context) : base(context) { }
        public async Task<bool> EmailExistsAsync(string email)
        {
            return await _dbSet.AnyAsync(u => u.Email == email);
        }

        public async Task<IEnumerable<User>> GetActiveUsersAsync()
        {
            return await base._dbSet.Where(u => u.IsActive == true).ToListAsync();
        }

        public async Task<User?> GetByEmailAsync(string email)
        {
            return await _dbSet.FirstOrDefaultAsync(u => u.Email == email);
        }

        public async Task<User?> GetByKeycloakIdAsync(string keycloakId)
        {
            return await base.WhereByExprFirstOrDefaultAsync(u => u.KeycloakId == keycloakId);
        }

        public async Task<IEnumerable<User>> GetByIdsAsync(IEnumerable<Guid> ids)
        {
            return await _dbSet.Where(u => ids.Contains(u.Id)).ToListAsync();
        }

        public async Task<IEnumerable<User>> GetByKeycloakIdsAsync(IEnumerable<string> keycloakIds)
        {
            return await _dbSet.Where(u => u.KeycloakId != null && keycloakIds.Contains(u.KeycloakId)).ToListAsync();
        }
    }
}
