namespace DriveOps.Application.DTOs
{
    public record TripDto
    {
        public Guid Id { get; init; }
        public Guid CustomerId { get; init; }
        public string? CustomerName { get; init; }
        public Guid? DriverId { get; init; }
        public string? DriverName { get; init; }
        public Guid? VehicleId { get; init; }
        public string? VehiclePlate { get; init; }
        public int TripStatus { get; init; }
        public int TripType { get; init; }
        public decimal PickupLatitude { get; init; }
        public decimal PickupLongitude { get; init; }
        public string PickupAddress { get; init; } = null!;
        public decimal DropoffLatitude { get; init; }
        public decimal DropoffLongitude { get; init; }
        public string DropoffAddress { get; init; } = null!;
        public DateTime? RequestedAt { get; init; }
        public DateTime? ScheduledAt { get; init; }
        public DateTime? PickupTime { get; init; }
        public DateTime? DropoffTime { get; init; }
        public decimal? EstimatedDistance { get; init; }
        public decimal? ActualDistance { get; init; }
        public int? EstimatedDuration { get; init; }
        public int? ActualDuration { get; init; }
        public decimal? EstimatedFare { get; init; }
        public decimal? ActualFare { get; init; }
        public int? PaymentMethod { get; init; }
        public int? PaymentStatus { get; init; }
        public int? CustomerRating { get; init; }
        public int? DriverRating { get; init; }
        public string? CancellationReason { get; init; }
        public DateTime? CreatedAt { get; init; }
    }

    public class CreateTripDto
    {
        public Guid CustomerId { get; set; }
        public int TripType { get; set; } = 1;
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        public string PickupAddress { get; set; } = null!;
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        public string DropoffAddress { get; set; } = null!;
        public DateTime? ScheduledAt { get; set; }
        public int? PaymentMethod { get; set; }
        public string? SpecialInstructions { get; set; }
    }

    public class RateTripDto
    {
        public Guid TripId { get; set; }
        public int Rating { get; set; }
        public string? Feedback { get; set; }
        public bool IsCustomerRating { get; set; }
    }

    public record TripEstimateDto
    {
        public double DistanceKm { get; init; }
        public int DurationMinutes { get; init; }
        public decimal EstimatedFare { get; init; }
        public List<RoutePointDto> RoutePoints { get; init; } = [];
    }
}
