using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface ITripService
    {
        Task<TripDto?> GetTripByIdAsync(Guid tripId);
        Task<IEnumerable<TripDto>> GetTripsByCustomerAsync(Guid customerId);
        Task<IEnumerable<TripDto>> GetTripsByDriverAsync(Guid driverId);
        Task<IEnumerable<TripDto>> GetActiveTripsForDriverAsync(Guid driverId);
        Task<TripDto> RequestTripAsync(CreateTripDto dto);
        Task<TripDto> AssignDriverAsync(Guid tripId, Guid driverId, Guid vehicleId);
        Task<TripDto> StartTripAsync(Guid tripId);
        Task<TripDto> CompleteTripAsync(Guid tripId, decimal actualDistance);
        Task<TripDto> CancelTripAsync(Guid tripId, string? reason);
        Task<TripDto> RateTripAsync(RateTripDto dto);
        Task<TripEstimateDto> GetTripEstimateAsync(decimal pickupLat, decimal pickupLon, decimal dropoffLat, decimal dropoffLon, int tripType);
        Task<IEnumerable<RoutePointDto>> GetTripRouteAsync(Guid tripId);
        Task AddRoutePointsAsync(Guid tripId, IEnumerable<RoutePointDto> points);
    }
}
