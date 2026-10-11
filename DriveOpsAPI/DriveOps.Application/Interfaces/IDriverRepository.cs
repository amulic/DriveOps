using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IDriverRepository : IRepository<Driver>
    {
        Task<IEnumerable<Driver>> GetAllDriversAsync(int page = 1, int pageSize = 50);
        Task<int> CountAllDriversAsync();
        Task<Driver?> GetByKeycloakIdAsync(Guid keycloakId);
        Task<List<Guid>> GetExistingKeycloakIdsAsync(IEnumerable<Guid> keycloakIds);
        Task<IEnumerable<Driver>> GetAvailableDriversAsync(int page = 1, int pageSize = 50);
        Task<int> CountAvailableDriversAsync();
        Task<IEnumerable<Driver>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm, int page = 1, int pageSize = 50);
        Task<int> CountNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm);
        Task<Driver?> GetWithVehiclesAsync(Guid driverId);
        Task<Driver?> GetByIdWithTripsAsync(Guid driverId);
    }
}
