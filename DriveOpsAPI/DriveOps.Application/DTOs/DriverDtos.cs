using DriveOps.Model.Enums;

namespace DriveOps.Application.DTOs
{
    public record DriverDto
    {
        public Guid Id { get; init; }
        public Guid UserId { get; init; }
        public string DriverName { get; init; } = null!;
        public string Email { get; init; } = null!;
        public string PhoneNumber { get; init; } = null!;
        public string LicenseNumber { get; init; } = null!;
        public DateOnly LicenseExpiryDate { get; init; }
        public string? EmergencyContactName { get; init; }
        public string? EmergencyContactPhone { get; init; }
        public DriverStatus? Status { get; init; }
        public decimal? Rating { get; init; }
        public int? TotalTrips { get; init; }
        public decimal? TotalRevenue { get; init; }
        public bool? IsOnline { get; init; }
        public decimal? CurrentLatitude { get; init; }
        public decimal? CurrentLongitude { get; init; }
        public DateTime? LastLocationUpdate { get; init; }
        public DateTime? CreatedAt { get; init; }
    }

    public class CreateDriverDto
    {
        public Guid UserId { get; set; }
        public string LicenseNumber { get; set; } = null!;
        public DateOnly LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class UpdateDriverDto
    {
        public Guid Id { get; set; }
        public string? LicenseNumber { get; set; }
        public DateOnly? LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class UpdateDriverLocationDto
    {
        public Guid DriverId { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
    }
}
