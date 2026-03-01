using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IRoutingService
    {
        Task<RouteResultDto?> GetRouteAsync(decimal originLat, decimal originLon, decimal destLat, decimal destLon);
        Task<TripEstimateDto> GetTripEstimateAsync(decimal originLat, decimal originLon, decimal destLat, decimal destLon, int tripType);
    }
}
