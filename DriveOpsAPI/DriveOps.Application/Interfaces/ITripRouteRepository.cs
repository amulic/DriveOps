using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ITripRouteRepository : IRepository<TripRoute>
    {
        Task<IEnumerable<TripRoute>> GetByTripIdAsync(Guid tripId);
        Task AddBatchAsync(IEnumerable<TripRoute> routePoints);
    }
}
