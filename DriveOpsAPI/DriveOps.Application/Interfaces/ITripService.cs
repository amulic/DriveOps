using DriveOps.Application.DTOs;
using DriveOps.RealTime.Contracts.Enums;

namespace DriveOps.Application.Interfaces
{
    public interface ITripService
    {
        Task<PaginatedResult<TripDto>> GetAllTripsAsync(int page = 1, int pageSize = 20);
        Task<TripDto?> GetTripByIdAsync(Guid tripId);
        Task<PaginatedResult<TripDto>> GetTripsByCustomerAsync(Guid customerId, int page = 1, int pageSize = 20);
        Task<PaginatedResult<TripDto>> GetTripsByDriverAsync(Guid driverId, int page = 1, int pageSize = 20);
        Task<PaginatedResult<TripDto>> GetActiveTripsForDriverAsync(Guid driverId, int page = 1, int pageSize = 20);
        Task<TripDto> RequestTripAsync(CreateTripDto dto);
        Task<TripDto> AssignDriverAsync(Guid tripId, Guid driverId, Guid vehicleId);
        Task<TripDto> StartTripAsync(Guid tripId);
        Task<TripDto> CompleteTripAsync(Guid tripId, decimal actualDistance);
        Task<TripDto> CancelTripAsync(Guid tripId, string? reason);
        Task<TripDto> DeclineTripAsync(Guid tripId, Guid driverId, string? reason);
        Task<TripDto> RateTripAsync(RateTripDto dto);
        Task<TripEstimateDto> GetTripEstimateAsync(decimal pickupLat, decimal pickupLon, decimal dropoffLat, decimal dropoffLon, TripType tripType);
        Task<PaginatedResult<RoutePointDto>> GetTripRouteAsync(Guid tripId, int page = 1, int pageSize = 500);
        Task AddRoutePointsAsync(Guid tripId, IEnumerable<RoutePointDto> points);
    }
}
