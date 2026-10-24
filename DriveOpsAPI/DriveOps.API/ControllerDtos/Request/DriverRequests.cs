namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateDriverRequest
    {
        public Guid KeycloakId { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string LicenseNumber { get; set; } = null!;
        public DateOnly LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class OnboardDriverRequest
    {
        public string Username { get; set; } = null!;
        public string TemporaryPassword { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string LicenseNumber { get; set; } = null!;
        public DateOnly LicenseExpiryDate { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactPhone { get; set; }
    }

    public class UpdateDriverRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
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
