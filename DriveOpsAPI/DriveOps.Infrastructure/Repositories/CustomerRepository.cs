using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class CustomerRepository : Repository<Customer>, ICustomerRepository
    {
        public CustomerRepository(ApplicationDbContext context) : base(context) { }

        public async Task<Customer?> GetByPhoneNumberAsync(string phoneNumber)
        {
            return await _dbSet.FirstOrDefaultAsync(c => c.PhoneNumber == phoneNumber);
        }

        public async Task<Customer?> GetByKeycloakIdAsync(Guid keycloakId)
        {
            return await _dbSet
                .FirstOrDefaultAsync(c => c.KeycloakId == keycloakId);
        }
    }
}
