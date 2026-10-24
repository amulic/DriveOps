using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class VehicleDefectReportRepository : Repository<VehicleDefectReport>, IVehicleDefectReportRepository
    {
        public VehicleDefectReportRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<VehicleDefectReport>> GetByVehicleIdAsync(Guid vehicleId)
        {
            return await _dbSet
                .Include(r => r.Driver)
                .Where(r => r.VehicleId == vehicleId)
                .OrderByDescending(r => r.ReportedAt)
                .ToListAsync();
        }

        public async Task<VehicleDefectReport?> GetByIdWithDetailsAsync(Guid id)
        {
            return await _dbSet
                .Include(r => r.Driver)
                .Include(r => r.Vehicle)
                .FirstOrDefaultAsync(r => r.Id == id);
        }

        public async Task<IEnumerable<VehicleDefectReport>> GetFilteredAsync(string? status, DefectSeverity? severity, Guid? vehicleId, Guid? driverId)
        {
            var query = _dbSet
                .Include(r => r.Driver)
                .Include(r => r.Vehicle)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(status))
                query = query.Where(r => r.Status == status);
            if (severity.HasValue)
                query = query.Where(r => r.Severity == severity.Value);
            if (vehicleId.HasValue)
                query = query.Where(r => r.VehicleId == vehicleId.Value);
            if (driverId.HasValue)
                query = query.Where(r => r.DriverId == driverId.Value);

            // Open (non-resolved) reports first, then newest first.
            return await query
                .OrderBy(r => r.Status == DefectStatus.Resolved)
                .ThenByDescending(r => r.ReportedAt)
                .ToListAsync();
        }
    }
}
