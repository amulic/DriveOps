using DriveOps.Application.DTOs;
using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    /// <summary>
    /// Business-level payment operations: saved-card management for customers,
    /// trip charging, and webhook processing. Stripe specifics live behind IPaymentGateway.
    /// </summary>
    public interface IPaymentService
    {
        /// <summary>
        /// Creates a setup session so the customer can save a card in the app.
        /// Lazily creates and links the gateway customer on first use.
        /// </summary>
        Task<SetupSessionDto> CreateSetupSessionAsync(Guid keycloakId);

        Task<IReadOnlyList<SavedCardDto>> GetSavedCardsAsync(Guid keycloakId);

        Task DeleteCardAsync(Guid keycloakId, string paymentMethodId);

        /// <summary>
        /// Charges the trip's actual fare to the customer's saved card (off-session).
        /// Called by TripService after a card trip completes; records a Payments ledger row and
        /// flips the trip PaymentStatus to Completed or Failed. Never throws — failures are persisted.
        /// </summary>
        Task ChargeCompletedTripAsync(Guid tripId);

        /// <summary>
        /// Creates an on-session PaymentIntent for a failed/pending card payment so the customer
        /// can retry interactively in the app (handles 3DS).
        /// </summary>
        Task<RetryPaymentSessionDto> CreateRetryPaymentAsync(Guid keycloakId, Guid tripId);

        /// <summary>
        /// Verifies and processes a provider webhook (payment_intent.succeeded / payment_failed),
        /// updating the Payments ledger row and the trip PaymentStatus. Idempotent.
        /// </summary>
        Task HandleWebhookAsync(string rawBody, string signatureHeader);

        /// <summary>True when the customer has a gateway customer with at least one saved card.</summary>
        Task<bool> CustomerHasSavedCardAsync(Guid customerId);
    }
}
