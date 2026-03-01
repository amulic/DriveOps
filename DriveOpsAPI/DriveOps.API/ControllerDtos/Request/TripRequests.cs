using DriveOps.Model.Enums;

namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateTripRequest
    {
        public Guid CustomerId { get; set; }
        public TripType TripType { get; set; } = TripType.Standard;
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        public string PickupAddress { get; set; } = null!;
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        public string DropoffAddress { get; set; } = null!;
        public DateTime? ScheduledAt { get; set; }
        public PaymentMethod? PaymentMethod { get; set; }
        public string? SpecialInstructions { get; set; }
    }

    public class AssignDriverRequest
    {
        public Guid DriverId { get; set; }
        public Guid VehicleId { get; set; }
    }

    public class CompleteTripRequest
    {
        public decimal ActualDistance { get; set; }
    }

    public class CancelTripRequest
    {
        public string? Reason { get; set; }
    }

    public class RateTripRequest
    {
        public int Rating { get; set; }
        public string? Feedback { get; set; }
        public bool IsCustomerRating { get; set; }
    }

    public class TripEstimateRequest
    {
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        public TripType TripType { get; set; } = TripType.Standard;
    }

    public class AddRoutePointsRequest
    {
        public List<RoutePointRequest> Points { get; set; } = [];
    }

    public class RoutePointRequest
    {
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public DateTime? Timestamp { get; set; }
    }
}
