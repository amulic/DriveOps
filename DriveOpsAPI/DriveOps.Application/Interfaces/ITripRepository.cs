using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ITripRepository : IRepository<Trip>
    {
        Task<IEnumerable<Trip>> GetByCustomerIdAsync(Guid customerId, int page = 1, int pageSize = 20);
        Task<IEnumerable<Trip>> GetByDriverIdAsync(Guid driverId, int page = 1, int pageSize = 20);
        Task<IEnumerable<Trip>> GetActiveTripsByDriverIdAsync(Guid driverId);
        Task<Trip?> GetWithDetailsAsync(Guid tripId);
        Task<int> CountByCustomerIdAsync(Guid customerId);
        Task<int> CountByDriverIdAsync(Guid driverId);
    }
}
