using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ITripRepository : IRepository<Trip>
    {
        Task<IEnumerable<Trip>> GetByCustomerIdAsync(Guid customerId);
        Task<IEnumerable<Trip>> GetByDriverIdAsync(Guid driverId);
        Task<IEnumerable<Trip>> GetActiveTripsByDriverIdAsync(Guid driverId);
        Task<Trip?> GetWithDetailsAsync(Guid tripId);
    }
}
