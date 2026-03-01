using DriveOps.Application.DTOs;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Interfaces
{
    public interface IRoutingService
    {
        Task<RouteResultDto?> GetRouteAsync(decimal originLat, decimal originLon, decimal destLat, decimal destLon);
        Task<TripEstimateDto> GetTripEstimateAsync(decimal originLat, decimal originLon, decimal destLat, decimal destLon, TripType tripType);
    }
}
