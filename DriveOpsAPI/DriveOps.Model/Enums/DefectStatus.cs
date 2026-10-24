namespace DriveOps.Model.Enums;

/// <summary>
/// Workflow states for <see cref="DriveOps.Model.Entity.VehicleDefectReport.Status"/>
/// (stored as a string column). Reported → Resolved; a resolved report can be reopened
/// back to Reported.
/// </summary>
public static class DefectStatus
{
    public const string Reported = "Reported";
    public const string Resolved = "Resolved";
}
