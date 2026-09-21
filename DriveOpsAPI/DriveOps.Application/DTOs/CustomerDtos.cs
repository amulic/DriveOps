namespace DriveOps.Application.DTOs
{
    public record CustomerDto
    {
        public Guid Id { get; init; }
        public Guid KeycloakId { get; init; }
        public string Name { get; init; } = null!;
        public string PhoneNumber { get; init; } = null!;
        public string? Email { get; init; }
        public decimal? Rating { get; init; }
        public int? TotalTrips { get; init; }
        public int? PreferredPaymentMethod { get; init; }
        public DateTime? CreatedAt { get; init; }
    }

    public class CreateCustomerDto
    {
        public Guid KeycloakId { get; set; }
        public string Name { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string? Email { get; set; }
        public int? PreferredPaymentMethod { get; set; }
    }

    public class UpdateCustomerDto
    {
        public Guid Id { get; set; }
        public string? Name { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public int? PreferredPaymentMethod { get; set; }
    }
}
