namespace DriveOps.Application.DTOs
{
    public record UserDto
    {
        public Guid Id { get; init; }
        public string? KeycloakId { get; init; }
        public string Email { get; init; } = null!;
        public string FirstName { get; init; } = null!;
        public string LastName { get; init; } = null!;
        public string PhoneNumber { get; init; } = null!;
        public int UserType { get; init; }
        public bool? IsActive { get; init; }
        public string? ProfileImageUrl { get; init; }
        public string? Address { get; init; }
        public DateOnly? DateOfBirth { get; init; }
        public DateTime? CreatedAt { get; init; }
    }

    public class CreateUserDto
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

    public class UpdateUserDto
    {
        public Guid Id { get; set; }
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? Address { get; set; }
        public DateOnly? DateOfBirth { get; set; }
    }
}
