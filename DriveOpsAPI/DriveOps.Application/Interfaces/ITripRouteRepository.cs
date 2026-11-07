using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface ITripRouteRepository : IRepository<TripRoute>
    {
        Task<IEnumerable<TripRoute>> GetByTripIdAsync(Guid tripId, int page = 1, int pageSize = 500);
        Task<int> CountByTripIdAsync(Guid tripId);
        Task AddBatchAsync(IEnumerable<TripRoute> routePoints);
    }
}
