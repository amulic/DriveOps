using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
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
    }
}
