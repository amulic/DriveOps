using DriveOps.Model.Enums;

namespace DriveOps.API.ControllerDtos.Response
{
    public class TripResponse
    {
        public Guid Id { get; set; }
        public Guid CustomerId { get; set; }
        public string? CustomerName { get; set; }
        public Guid? DriverId { get; set; }
        public string? DriverName { get; set; }
        public Guid? VehicleId { get; set; }
        public string? VehiclePlate { get; set; }
        public TripStatus TripStatus { get; set; }
        public TripType TripType { get; set; }
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        public string PickupAddress { get; set; } = null!;
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        public string DropoffAddress { get; set; } = null!;
        public DateTime? RequestedAt { get; set; }
        public DateTime? PickupTime { get; set; }
        public DateTime? DropoffTime { get; set; }
        public decimal? EstimatedDistance { get; set; }
        public decimal? ActualDistance { get; set; }
        public int? EstimatedDuration { get; set; }
        public int? ActualDuration { get; set; }
        public decimal? EstimatedFare { get; set; }
        public decimal? ActualFare { get; set; }
        public PaymentMethod? PaymentMethod { get; set; }
        public PaymentStatus? PaymentStatus { get; set; }
        public int? CustomerRating { get; set; }
        public int? DriverRating { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class TripEstimateResponse
    {
        public double DistanceKm { get; set; }
        public int DurationMinutes { get; set; }
        public decimal EstimatedFare { get; set; }
        public List<RoutePointResponse> RoutePoints { get; set; } = [];
    }

    public class RoutePointResponse
    {
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public DateTime? Timestamp { get; set; }
    }
}
