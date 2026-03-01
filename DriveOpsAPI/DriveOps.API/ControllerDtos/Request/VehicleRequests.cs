using DriveOps.Model.Enums;

namespace DriveOps.API.ControllerDtos.Request
{
    public class CreateVehicleRequest
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

    public class UpdateVehicleRequest
    {
        public string? Color { get; set; }
        public string? InsurancePolicyNumber { get; set; }
        public DateOnly? InsuranceExpiryDate { get; set; }
        public DateOnly? RegistrationExpiryDate { get; set; }
        public VehicleStatus? Status { get; set; }
        public int? Mileage { get; set; }
    }

    public class AssignVehicleRequest
    {
        public Guid DriverId { get; set; }
    }
}
