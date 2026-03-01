using DriveOps.Model.Enums;

namespace DriveOps.API.ControllerDtos.Response
{
    public class VehicleResponse
    {
        public Guid Id { get; set; }
        public string LicensePlate { get; set; } = null!;
        public string Make { get; set; } = null!;
        public string Model { get; set; } = null!;
        public int Year { get; set; }
        public string Color { get; set; } = null!;
        public string Vin { get; set; } = null!;
        public string InsurancePolicyNumber { get; set; } = null!;
        public DateOnly InsuranceExpiryDate { get; set; }
        public DateOnly RegistrationExpiryDate { get; set; }
        public int? Status { get; set; }
        public int? Mileage { get; set; }
        public FuelType FuelType { get; set; }
        public int? SeatingCapacity { get; set; }
        public Guid? AssignedDriverId { get; set; }
        public string? AssignedDriverName { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
