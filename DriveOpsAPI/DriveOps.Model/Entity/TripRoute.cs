using System;
using System.Collections.Generic;

namespace DriveOps.Model.Entity;

public partial class TripRoute
{
    public Guid Id { get; set; }

    public Guid TripId { get; set; }

    public decimal Latitude { get; set; }

    public decimal Longitude { get; set; }

    public DateTime? Timestamp { get; set; }

    public virtual Trip Trip { get; set; } = null!;
}
