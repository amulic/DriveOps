using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleServiceRecordRepository : IRepository<VehicleServiceRecord>
    {
        Task<IEnumerable<VehicleServiceRecord>> GetByVehicleIdAsync(Guid vehicleId, int page, int pageSize);
        Task<int> CountByVehicleIdAsync(Guid vehicleId);
        Task<VehicleServiceRecord?> GetLatestByVehicleIdAsync(Guid vehicleId);
        Task<IEnumerable<VehicleServiceRecord>> GetLatestByVehicleIdsAsync(IEnumerable<Guid> vehicleIds);
    }
}
