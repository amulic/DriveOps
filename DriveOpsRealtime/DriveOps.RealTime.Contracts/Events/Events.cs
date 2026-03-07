using DriveOps.RealTime.Contracts.Enums;

namespace DriveOps.RealTime.Contracts.Events;

public record TripRequestedEvent(
    Guid TripId,
    Guid CustomerId,
    TripStatus Status,
    TripType TripType,
    decimal PickupLatitude,
    decimal PickupLongitude,
    string PickupAddress,
    decimal DropoffLatitude,
    decimal DropoffLongitude,
    string DropoffAddress,
    decimal? EstimatedFare,
    int? EstimatedDuration,
    DateTime RequestedAt
);

public record TripAssignedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    Guid VehicleId,
    string DriverName,
    decimal DriverLatitude,
    decimal DriverLongitude,
    DateTime AssignedAt
);

public record TripStartedEvent(Guid TripId, Guid CustomerId, Guid DriverId, DateTime PickupTime);

public record TripCompletedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    decimal ActualDistance,
    decimal ActualFare,
    DateTime DropoffTime
);

public record TripCancelledEvent(Guid TripId, Guid CustomerId, Guid? DriverId, string? Reason, DateTime CancelledAt);

public record DriverLocationUpdatedEvent(
    Guid DriverId,
    decimal Latitude,
    decimal Longitude,
    DateTime Timestamp,
    Guid? ActiveTripId
);

public record DriverAvailabilityChangedEvent(Guid DriverId, bool IsOnline, DateTime Timestamp);

public record TripRouteUpdatedEvent(Guid TripId, IEnumerable<RoutePointEvent> Points);
public record RoutePointEvent(decimal Latitude, decimal Longitude, DateTime Timestamp);

public record DriverLocationReceivedEvent(
    Guid DriverId,
    decimal Latitude,
    decimal Longitude,
    DateTime Timestamp
);
