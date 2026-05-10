using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class DriverRepository : Repository<Driver>, IDriverRepository
    {
        public DriverRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<Driver>> GetAvailableDriversAsync(int page = 1, int pageSize = 50)
        {
            return await _dbSet
                .Include(d => d.User)
                .Where(d => d.IsOnline == true && d.Status == DriverStatus.Active)
                .OrderBy(d => d.Status)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountAvailableDriversAsync()
        {
            return await _dbSet
                .CountAsync(d => d.IsOnline == true && d.Status == DriverStatus.Active);
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

        public async Task<Driver?> GetByIdWithTripsAsync(Guid driverId)
        {
            return await _dbSet
                .Include(d => d.User)
                .Include(d => d.Trips)
                .FirstOrDefaultAsync(d => d.Id == driverId);
        }

        public async Task<IEnumerable<Driver>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm, int page = 1, int pageSize = 50)
        {
            const decimal latDegreesPerKm = 0.009m;
            var latRange = radiusKm * latDegreesPerKm;

            var cosLat = (decimal)Math.Cos((double)latitude * Math.PI / 180.0);
            var lonRange = cosLat > 0m ? latRange / cosLat : latRange;

            return await _dbSet
                .Include(d => d.User)
                .Where(d => d.IsOnline == true
                    && d.Status == DriverStatus.Active
                    && d.CurrentLatitude != null
                    && d.CurrentLongitude != null
                    && d.CurrentLatitude >= latitude - latRange
                    && d.CurrentLatitude <= latitude + latRange
                    && d.CurrentLongitude >= longitude - lonRange
                    && d.CurrentLongitude <= longitude + lonRange)
                .OrderBy(d => d.Status)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm)
        {
            const decimal latDegreesPerKm = 0.009m;
            var latRange = radiusKm * latDegreesPerKm;
            var cosLat = (decimal)Math.Cos((double)latitude * Math.PI / 180.0);
            var lonRange = cosLat > 0m ? latRange / cosLat : latRange;

            return await _dbSet
                .CountAsync(d => d.IsOnline == true
                    && d.Status == DriverStatus.Active
                    && d.CurrentLatitude != null
                    && d.CurrentLongitude != null
                    && d.CurrentLatitude >= latitude - latRange
                    && d.CurrentLatitude <= latitude + latRange
                    && d.CurrentLongitude >= longitude - lonRange
                    && d.CurrentLongitude <= longitude + lonRange);
        }
    }
}
