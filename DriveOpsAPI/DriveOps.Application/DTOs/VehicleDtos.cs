using DriveOps.Model.Enums;

namespace DriveOps.Application.DTOs
{
    public record VehicleDto
    {
        public Guid Id { get; init; }
        public string LicensePlate { get; init; } = null!;
        public string Make { get; init; } = null!;
        public string Model { get; init; } = null!;
        public int Year { get; init; }
        public string Color { get; init; } = null!;
        public string Vin { get; init; } = null!;
        public string InsurancePolicyNumber { get; init; } = null!;
        public DateOnly InsuranceExpiryDate { get; init; }
        public DateOnly RegistrationExpiryDate { get; init; }
        public int? Status { get; init; }
        public int? Mileage { get; init; }
        public FuelType FuelType { get; init; }
        public int? SeatingCapacity { get; init; }
        public Guid? AssignedDriverId { get; init; }
        public string? AssignedDriverName { get; init; }
        public DateTime? CreatedAt { get; init; }
    }

    public class CreateVehicleDto
    {
        public string LicensePlate { get; set; } = null!;
        public string Make { get; set; } = null!;
        public string Model { get; set; } = null!;
        public int Year { get; set; }
        public string Color { get; set; } = null!;
        public string Vin { get; set; } = null!;
        public string InsurancePolicyNumber { get; set; } = null!;
        public DateOnly InsuranceExpiryDate { get; set; }
        public DateOnly RegistrationExpiryDate { get; set; }
        public FuelType FuelType { get; set; }
        public int? SeatingCapacity { get; set; }
    }

    public class UpdateVehicleDto
    {
        public Guid Id { get; set; }
        public string? Color { get; set; }
        public string? InsurancePolicyNumber { get; set; }
        public DateOnly? InsuranceExpiryDate { get; set; }
        public DateOnly? RegistrationExpiryDate { get; set; }
        public int? Status { get; set; }
        public int? Mileage { get; set; }
    }
}
