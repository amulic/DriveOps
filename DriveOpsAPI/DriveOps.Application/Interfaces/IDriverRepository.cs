using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IDriverRepository : IRepository<Driver>
    {
        Task<Driver?> GetByUserIdAsync(Guid userId);
        Task<IEnumerable<Driver>> GetAvailableDriversAsync();
        Task<IEnumerable<Driver>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm);
        Task<Driver?> GetWithVehiclesAsync(Guid driverId);
    }
}
