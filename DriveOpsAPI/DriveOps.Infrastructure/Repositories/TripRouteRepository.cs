using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class TripRouteRepository : Repository<TripRoute>, ITripRouteRepository
    {
        public TripRouteRepository(ApplicationDbContext context) : base(context) { }

        public async Task AddBatchAsync(IEnumerable<TripRoute> routePoints)
        {
            await _dbSet.AddRangeAsync(routePoints);
            await _context.SaveChangesAsync();
        }

        public async Task<IEnumerable<TripRoute>> GetByTripIdAsync(Guid tripId)
        {
            return await _dbSet
                .Where(r => r.TripId == tripId)
                .OrderBy(r => r.Timestamp)
                .ToListAsync();
        }
    }
}
