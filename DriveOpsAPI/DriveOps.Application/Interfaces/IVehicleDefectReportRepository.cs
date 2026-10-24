using DriveOps.Model.Entity;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleDefectReportRepository : IRepository<VehicleDefectReport>
    {
        Task<IEnumerable<VehicleDefectReport>> GetByVehicleIdAsync(Guid vehicleId);
        Task<VehicleDefectReport?> GetByIdWithDetailsAsync(Guid id);
        Task<IEnumerable<VehicleDefectReport>> GetFilteredAsync(string? status, DefectSeverity? severity, Guid? vehicleId, Guid? driverId);
    }
}
