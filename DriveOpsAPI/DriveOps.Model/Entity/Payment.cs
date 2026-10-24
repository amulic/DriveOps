using DriveOps.Model.Enums;
using System;

namespace DriveOps.Model.Entity;

/// <summary>
/// Payment transaction ledger per trip (see FUTURE_TABLES_AI.md §1).
/// One row per charge attempt; TransactionId carries the Stripe PaymentIntent id.
/// </summary>
public partial class Payment
{
    public Guid Id { get; set; }

    public Guid TripId { get; set; }

    public decimal Amount { get; set; }

    public PaymentMethod Method { get; set; }

    public PaymentStatus Status { get; set; }

    /// <summary>External processor reference (Stripe PaymentIntent id, e.g. pi_...).</summary>
    public string? TransactionId { get; set; }

    public string? FailureReason { get; set; }

    public DateTime? ProcessedAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Trip Trip { get; set; } = null!;
}
