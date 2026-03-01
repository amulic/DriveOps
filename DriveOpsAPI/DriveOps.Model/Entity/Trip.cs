using DriveOps.Model.Enums;
using System;
using System.Collections.Generic;

namespace DriveOps.Model.Entity;

public partial class Trip
{
    public Guid Id { get; set; }

    public Guid CustomerId { get; set; }

    public Guid? DriverId { get; set; }

    public Guid? VehicleId { get; set; }

    public TripStatus TripStatus { get; set; }

    public TripType TripType { get; set; }

    public decimal PickupLatitude { get; set; }

    public decimal PickupLongitude { get; set; }

    public string PickupAddress { get; set; } = null!;

    public decimal DropoffLatitude { get; set; }

    public decimal DropoffLongitude { get; set; }

    public string DropoffAddress { get; set; } = null!;

    public DateTime? RequestedAt { get; set; }

    public DateTime? ScheduledAt { get; set; }

    public DateTime? AssignedAt { get; set; }

    public DateTime? PickupTime { get; set; }

    public DateTime? DropoffTime { get; set; }

    public decimal? EstimatedDistance { get; set; }

    public decimal? ActualDistance { get; set; }

    public int? EstimatedDuration { get; set; }

    public int? ActualDuration { get; set; }

    public decimal? EstimatedFare { get; set; }

    public decimal? ActualFare { get; set; }

    public PaymentMethod? PaymentMethod { get; set; }

    public PaymentStatus? PaymentStatus { get; set; }

    public int? CustomerRating { get; set; }

    public int? DriverRating { get; set; }

    public string? CustomerFeedback { get; set; }

    public string? DriverFeedback { get; set; }

    public string? SpecialInstructions { get; set; }

    public string? CancellationReason { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Customer Customer { get; set; } = null!;

    public virtual Driver? Driver { get; set; }

    public virtual ICollection<TripRoute> TripRoutes { get; set; } = new List<TripRoute>();

    public virtual Vehicle? Vehicle { get; set; }
}
