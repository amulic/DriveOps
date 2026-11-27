using DriveOps.Model.Enums;
using System;

namespace DriveOps.Model.Entity;

public partial class VehicleServiceRecord
{
    public Guid Id { get; set; }

    public Guid VehicleId { get; set; }

    public DateTime ServiceDate { get; set; }

    public VehicleServiceType ServiceType { get; set; }

    public string? Description { get; set; }

    public string? PerformedBy { get; set; }

    public decimal? OdometerKm { get; set; }

    public decimal? Cost { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Vehicle Vehicle { get; set; } = null!;
}
