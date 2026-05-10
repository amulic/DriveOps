using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Events;

namespace DriveOps.RealTime.Contracts.Interfaces;

public interface ILocationService
{
    Task HandleDriverLocationUpdatedAsync(DriverLocationUpdatedEvent locationEvent);
    Task HandleDriverAvailabilityChangedAsync(DriverAvailabilityChangedEvent availabilityEvent);
    Task HandleTripRouteUpdatedAsync(TripRouteUpdatedEvent routeEvent);
    Task UpdateDriverLocationFromClientAsync(Guid driverId, decimal latitude, decimal longitude);
    Task<IEnumerable<DriverLocationDto>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm);
}
