namespace DriveOps.Application.DTOs
{
    public record AccountDto(
        string Id,
        string Username,
        string? Email,
        string? FirstName,
        string? LastName,
        bool Enabled,
        IReadOnlyList<string> Roles);

    public class CreateAccountDto
    {
        public string Username { get; set; } = null!;
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string TemporaryPassword { get; set; } = null!;
        public List<string> Roles { get; set; } = [];
    }

    public class UpdateAccountDto
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public bool? Enabled { get; set; }
    }

    public class SetAccountRolesDto
    {
        public List<string> Roles { get; set; } = [];
    }

    public class ResetAccountPasswordDto
    {
        public string TemporaryPassword { get; set; } = null!;
    }
}
