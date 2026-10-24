namespace DriveOps.API.ControllerDtos.Response
{
    public class KeycloakCandidateResponse
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
