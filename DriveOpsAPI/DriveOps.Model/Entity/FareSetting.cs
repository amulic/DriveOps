using System;

namespace DriveOps.Model.Entity;

/// <summary>
/// Single-row global fare configuration managed from the admin area.
/// Falls back to appsettings defaults when no row has been saved yet.
/// </summary>
public partial class FareSetting
{
    public int Id { get; set; }

    public decimal BaseFare { get; set; }

    public decimal PerKmRate { get; set; }

    public decimal PerMinuteRate { get; set; }

    public decimal PremiumMultiplier { get; set; }

    public decimal SharedMultiplier { get; set; }

    public string? UpdatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
