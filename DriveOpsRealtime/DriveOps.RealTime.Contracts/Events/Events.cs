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
    DateTime RequestedAt,
    Guid? CustomerKeycloakId = null
);

public record TripAssignedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    Guid VehicleId,
    string DriverName,
    decimal DriverLatitude,
    decimal DriverLongitude,
    DateTime AssignedAt,
    Guid? CustomerKeycloakId = null,
    Guid? DriverKeycloakId = null
);

public record TripStartedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    DateTime PickupTime,
    Guid? CustomerKeycloakId = null,
    Guid? DriverKeycloakId = null
);

public record TripCompletedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    decimal ActualDistance,
    decimal ActualFare,
    DateTime DropoffTime,
    Guid? CustomerKeycloakId = null
);

public record TripCancelledEvent(
    Guid TripId,
    Guid CustomerId,
    Guid? DriverId,
    string? Reason,
    DateTime CancelledAt,
    Guid? CustomerKeycloakId = null,
    Guid? DriverKeycloakId = null
);

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

public record VehicleAssignedEvent(
    Guid VehicleId,
    string LicensePlate,
    string Make,
    string Model,
    Guid? PreviousDriverId,
    Guid DriverId,
    string DriverName,
    Guid? PreviousVehicleId,
    DateTime AssignedAt
);

public record VehicleUnassignedEvent(
    Guid VehicleId,
    string LicensePlate,
    string Make,
    string Model,
    Guid PreviousDriverId,
    string PreviousDriverName,
    DateTime UnassignedAt
);

public record DriverStatusChangedEvent(
    Guid DriverId,
    string DriverName,
    string NewStatus,
    bool IsOnline,
    DateTime ChangedAt
);

public record VehicleStatusChangedEvent(
    Guid VehicleId,
    string LicensePlate,
    string Make,
    string Model,
    string NewStatus,
    DateTime ChangedAt
);
