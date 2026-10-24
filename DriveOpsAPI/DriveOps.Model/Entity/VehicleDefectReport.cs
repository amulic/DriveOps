using DriveOps.Model.Enums;
using System;

namespace DriveOps.Model.Entity;

public partial class VehicleDefectReport
{
    public Guid Id { get; set; }

    public Guid VehicleId { get; set; }

    public Guid DriverId { get; set; }

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public DefectSeverity Severity { get; set; }

    public string Status { get; set; } = "Reported";

    public DateTime ReportedAt { get; set; }

    public DateTime? ResolvedAt { get; set; }

    public string? ResolutionNotes { get; set; }

    public virtual Vehicle Vehicle { get; set; } = null!;

    public virtual Driver Driver { get; set; } = null!;
}
