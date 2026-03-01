using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class TripRepository : Repository<Trip>, ITripRepository
    {
        public TripRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<Trip>> GetActiveTripsByDriverIdAsync(Guid driverId)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Vehicle)
                .Where(t => t.DriverId == driverId
                    && t.TripStatus != 5  // Completed
                    && t.TripStatus != 6) // Cancelled
                .OrderByDescending(t => t.RequestedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Trip>> GetByCustomerIdAsync(Guid customerId)
        {
            return await _dbSet
                .Include(t => t.Driver)
                .Include(t => t.Vehicle)
                .Where(t => t.CustomerId == customerId)
                .OrderByDescending(t => t.RequestedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Trip>> GetByDriverIdAsync(Guid driverId)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Vehicle)
                .Where(t => t.DriverId == driverId)
                .OrderByDescending(t => t.RequestedAt)
                .ToListAsync();
        }

        public async Task<Trip?> GetWithDetailsAsync(Guid tripId)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Driver)
                    .ThenInclude(d => d!.User)
                .Include(t => t.Vehicle)
                .Include(t => t.TripRoutes.OrderBy(r => r.Timestamp))
                .FirstOrDefaultAsync(t => t.Id == tripId);
        }
    }
}
