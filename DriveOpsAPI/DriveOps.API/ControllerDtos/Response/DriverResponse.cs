namespace DriveOps.API.ControllerDtos.Response
{
    public class DriverResponse
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string DriverName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string LicenseNumber { get; set; } = null!;
        public DateOnly LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
        public int? Status { get; set; }
        public decimal? Rating { get; set; }
        public int? TotalTrips { get; set; }
        public decimal? TotalRevenue { get; set; }
        public bool? IsOnline { get; set; }
        public decimal? CurrentLatitude { get; set; }
        public decimal? CurrentLongitude { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
