using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IDriverRecommendationService
    {
        Task<IEnumerable<RecommendedDriverDto>> GetRecommendedDriversAsync(Guid tripId, int count = 5);
    }
}
