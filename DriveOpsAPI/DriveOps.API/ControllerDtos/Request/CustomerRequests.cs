namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateCustomerRequest
    {
        public Guid? UserId { get; set; }
        public string Name { get; set; } = null!;
        public string PhoneNumber { get; set; } = null!;
        public string? Email { get; set; }
        public int? PreferredPaymentMethod { get; set; }
    }

    public class UpdateCustomerRequest
    {
        public string? Name { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public int? PreferredPaymentMethod { get; set; }
    }
}
