using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleRepository : IRepository<Vehicle>
    {
        Task<Vehicle?> GetByLicensePlateAsync(string licensePlate);
        Task<IEnumerable<Vehicle>> GetAvailableVehiclesAsync();
        Task<IEnumerable<Vehicle>> GetByDriverIdAsync(Guid driverId);
        Task<Vehicle?> GetByVinAsync(string vin);
    }
}
