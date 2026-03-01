using DriveOps.Model.Enums;
using System;
using System.Collections.Generic;

namespace DriveOps.Model.Entity;

public partial class Vehicle
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

    public int? Mileage { get; set; }

    public FuelType FuelType { get; set; }

    public int? SeatingCapacity { get; set; }

    public Guid? AssignedDriverId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Driver? AssignedDriver { get; set; }

    public virtual ICollection<Trip> Trips { get; set; } = new List<Trip>();
}
