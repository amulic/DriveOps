namespace DriveOps.API.ControllerDtos.Response
{
    public class CustomerResponse
    {
        public Guid Id { get; set; }
        public Guid KeycloakId { get; set; }
        public string Name { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string? Email { get; set; }
        public decimal? Rating { get; set; }
        public int? TotalTrips { get; set; }
        public int? PreferredPaymentMethod { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
