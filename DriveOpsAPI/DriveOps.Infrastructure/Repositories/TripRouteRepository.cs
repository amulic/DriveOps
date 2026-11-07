using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class TripRouteRepository : Repository<TripRoute>, ITripRouteRepository
    {
        public TripRouteRepository(ApplicationDbContext context) : base(context) { }

        public Task AddBatchAsync(IEnumerable<TripRoute> routePoints)
        {
            _dbSet.AddRange(routePoints);
            return Task.CompletedTask;
        }

        public async Task<IEnumerable<TripRoute>> GetByTripIdAsync(Guid tripId, int page, int pageSize)
        {
            return await _dbSet
                .Where(r => r.TripId == tripId)
                .OrderBy(r => r.Timestamp)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountByTripIdAsync(Guid tripId)
        {
            return await _dbSet.CountAsync(r => r.TripId == tripId);
        }
    }
}
