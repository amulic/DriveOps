using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class DriverRepository : Repository<Driver>, IDriverRepository
    {
        public DriverRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<Driver>> GetAvailableDriversAsync()
        {
            return await _dbSet
                .Include(d => d.User)
                .Where(d => d.IsOnline == true && d.Status == 1)
                .ToListAsync();
        }

        public async Task<Driver?> GetByUserIdAsync(Guid userId)
        {
            return await _dbSet
                .Include(d => d.User)
                .FirstOrDefaultAsync(d => d.UserId == userId);
        }

        public async Task<Driver?> GetWithVehiclesAsync(Guid driverId)
        {
            return await _dbSet
                .Include(d => d.User)
                .Include(d => d.Vehicles)
                .FirstOrDefaultAsync(d => d.Id == driverId);
        }

        public async Task<IEnumerable<Driver>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm)
        {
            const decimal degreesPerKm = 0.009m;
            var latRange = radiusKm * degreesPerKm;
            var lonRange = radiusKm * degreesPerKm;

            return await _dbSet
                .Include(d => d.User)
                .Where(d => d.IsOnline == true
                    && d.Status == 1
                    && d.CurrentLatitude != null
                    && d.CurrentLongitude != null
                    && d.CurrentLatitude >= latitude - latRange
                    && d.CurrentLatitude <= latitude + latRange
                    && d.CurrentLongitude >= longitude - lonRange
                    && d.CurrentLongitude <= longitude + lonRange)
                .ToListAsync();
        }
    }
}
