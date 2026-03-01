namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateUserRequest
    {
        public string Email { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public int UserType { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? Address { get; set; }
        public DateOnly? DateOfBirth { get; set; }
    }

    public class UpdateUserRequest
    {
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? Address { get; set; }
        public DateOnly? DateOfBirth { get; set; }
    }
}
