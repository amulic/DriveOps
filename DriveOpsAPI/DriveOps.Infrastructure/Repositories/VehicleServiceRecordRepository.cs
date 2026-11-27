using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class VehicleServiceRecordRepository : Repository<VehicleServiceRecord>, IVehicleServiceRecordRepository
    {
        public VehicleServiceRecordRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<VehicleServiceRecord>> GetByVehicleIdAsync(Guid vehicleId, int page, int pageSize)
        {
            return await _dbSet
                .AsNoTracking()
                .Where(r => r.VehicleId == vehicleId)
                .OrderByDescending(r => r.ServiceDate)
                .ThenByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountByVehicleIdAsync(Guid vehicleId)
        {
            return await _dbSet.CountAsync(r => r.VehicleId == vehicleId);
        }

        public async Task<VehicleServiceRecord?> GetLatestByVehicleIdAsync(Guid vehicleId)
        {
            return await _dbSet
                .AsNoTracking()
                .Where(r => r.VehicleId == vehicleId)
                .OrderByDescending(r => r.ServiceDate)
                .ThenByDescending(r => r.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<IEnumerable<VehicleServiceRecord>> GetLatestByVehicleIdsAsync(IEnumerable<Guid> vehicleIds)
        {
            var ids = vehicleIds.Distinct().ToList();
            if (ids.Count == 0)
                return Enumerable.Empty<VehicleServiceRecord>();

            return await _dbSet
                .AsNoTracking()
                .Where(r => ids.Contains(r.VehicleId))
                .OrderByDescending(r => r.ServiceDate)
                .ThenByDescending(r => r.CreatedAt)
                .ToListAsync();
        }
    }
}
