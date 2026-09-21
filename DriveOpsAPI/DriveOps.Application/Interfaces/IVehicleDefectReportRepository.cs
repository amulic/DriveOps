using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleDefectReportRepository : IRepository<VehicleDefectReport>
    {
        Task<IEnumerable<VehicleDefectReport>> GetByVehicleIdAsync(Guid vehicleId);
    }
}
