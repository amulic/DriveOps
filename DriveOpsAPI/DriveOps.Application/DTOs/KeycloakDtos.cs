namespace DriveOps.Application.DTOs
{
    public class KeycloakUserDto
    {
        public string Id { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public bool Enabled { get; set; }
    }

    public class PromotionCandidateDto
    {
        public Guid KeycloakId { get; set; }
        public string Username { get; set; } = null!;
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public List<string> RealmRoles { get; set; } = [];
        public bool HasDriverProfile { get; set; }
    }
}
