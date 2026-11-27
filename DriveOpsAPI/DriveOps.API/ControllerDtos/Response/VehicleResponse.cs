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
        public VehicleStatus? Status { get; set; }
        public decimal? Mileage { get; set; }
        public FuelType FuelType { get; set; }
        public int? SeatingCapacity { get; set; }
        public Guid? AssignedDriverId { get; set; }
        public string? AssignedDriverName { get; set; }
        public string? PhotoUrl { get; set; }
        public string? InternalName { get; set; }
        public DateTime? LastServiceDate { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class VehicleDefectReportResponse
    {
        public Guid Id { get; set; }
        public Guid VehicleId { get; set; }
        public string? VehicleLicensePlate { get; set; }
        public string? VehicleInternalName { get; set; }
        public Guid DriverId { get; set; }
        public string? DriverName { get; set; }
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public DefectSeverity Severity { get; set; }
        public string Status { get; set; } = "Reported";
        public DateTime ReportedAt { get; set; }
        public DateTime? ResolvedAt { get; set; }
        public string? ResolutionNotes { get; set; }
    }

    public class VehicleServiceRecordResponse
    {
        public Guid Id { get; set; }
        public Guid VehicleId { get; set; }
        public DateTime ServiceDate { get; set; }
        public string ServiceType { get; set; } = "RoutineMaintenance";
        public string? Description { get; set; }
        public string? PerformedBy { get; set; }
        public decimal? OdometerKm { get; set; }
        public decimal? Cost { get; set; }
        public DateTime? CreatedAt { get; set; }
    }

    public class VehicleServiceReminderResponse
    {
        public Guid VehicleId { get; set; }
        public string LicensePlate { get; set; } = null!;
        public string Make { get; set; } = null!;
        public string Model { get; set; } = null!;
        public string Type { get; set; } = null!;
        public string Reason { get; set; } = null!;
        public DateTime? DueAt { get; set; }
    }
}
