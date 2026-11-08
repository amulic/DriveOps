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
        public VehicleStatus? Status { get; init; }
        public int? Mileage { get; init; }
        public FuelType FuelType { get; init; }
        public int? SeatingCapacity { get; init; }
        public Guid? AssignedDriverId { get; init; }
        public string? AssignedDriverName { get; init; }
        public string? PhotoUrl { get; init; }
        public string? InternalName { get; init; }
        public DateTime? LastServiceDate { get; init; }
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
        public string? PhotoUrl { get; set; }
        public string? InternalName { get; set; }
        public DateTime? LastServiceDate { get; set; }
    }

    public class UpdateVehicleDto
    {
        public Guid Id { get; set; }
        public string? LicensePlate { get; set; }
        public string? Make { get; set; }
        public string? Model { get; set; }
        public int? Year { get; set; }
        public string? Vin { get; set; }
        public FuelType? FuelType { get; set; }
        public int? SeatingCapacity { get; set; }
        public string? Color { get; set; }
        public string? InsurancePolicyNumber { get; set; }
        public DateOnly? InsuranceExpiryDate { get; set; }
        public DateOnly? RegistrationExpiryDate { get; set; }
        public VehicleStatus? Status { get; set; }
        public int? Mileage { get; set; }
        public string? PhotoUrl { get; set; }
        public string? InternalName { get; set; }
        public DateTime? LastServiceDate { get; set; }
    }

    public class ReportVehicleDefectDto
    {
        public Guid VehicleId { get; set; }
        public Guid DriverId { get; set; }
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public DefectSeverity Severity { get; set; } = DefectSeverity.Medium;
    }

    public record VehicleDefectReportDto
    {
        public Guid Id { get; init; }
        public Guid VehicleId { get; init; }
        public string? VehicleLicensePlate { get; init; }
        public string? VehicleInternalName { get; init; }
        public Guid DriverId { get; init; }
        public string? DriverName { get; init; }
        public string Title { get; init; } = null!;
        public string Description { get; init; } = null!;
        public DefectSeverity Severity { get; init; }
        public string Status { get; init; } = DefectStatus.Reported;
        public DateTime ReportedAt { get; init; }
        public DateTime? ResolvedAt { get; init; }
        public string? ResolutionNotes { get; init; }
    }

    public class ResolveVehicleDefectDto
    {
        public string? ResolutionNotes { get; set; }
    }
}
