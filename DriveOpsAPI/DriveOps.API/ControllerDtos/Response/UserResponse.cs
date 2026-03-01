namespace DriveOps.API.ControllerDtos.Response
{
    public class UserResponse
    {
        public Guid Id { get; set; }
        public string? KeycloakId { get; set; }
        public string Email { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public int UserType { get; set; }
        public bool? IsActive { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? Address { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
