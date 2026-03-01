namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateDriverRequest
    {
        public Guid UserId { get; set; }
        public string LicenseNumber { get; set; } = null!;
        public DateOnly LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class UpdateDriverRequest
    {
        public string? LicenseNumber { get; set; }
        public DateOnly? LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class UpdateDriverLocationRequest
    {
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
    }

    public class SetDriverStatusRequest
    {
        public bool IsOnline { get; set; }
    }
}
