namespace DriveOps.Application.Interfaces
{
    /// <summary>
    /// Card payment provider abstraction (implemented by Stripe in Infrastructure).
    /// All amounts are decimal major units (e.g. euros); the gateway handles minor-unit conversion.
    /// </summary>
    public interface IPaymentGateway
    {
        /// <summary>Creates a payment-provider customer for the given local customer and returns its id.</summary>
        Task<string> CreateCustomerAsync(string name, string? email, string? phone, Guid keycloakId);

        /// <summary>
        /// Creates a card-setup session (SetupIntent + ephemeral key) so the client can save a card
        /// without touching card numbers.
        /// </summary>
        Task<GatewaySetupSession> CreateSetupSessionAsync(string gatewayCustomerId);

        /// <summary>Lists the customer's saved cards.</summary>
        Task<IReadOnlyList<GatewaySavedCard>> ListCardsAsync(string gatewayCustomerId);

        /// <summary>Detaches a saved card. Ownership against the customer must hold.</summary>
        Task DetachCardAsync(string gatewayCustomerId, string paymentMethodId);

        /// <summary>
        /// Charges a saved card without the customer present (off-session).
        /// Returns the provider PaymentIntent id. Throws <see cref="PaymentGatewayException"/> on decline/failure.
        /// </summary>
        Task<string> ChargeOffSessionAsync(
            string gatewayCustomerId, decimal amount, string currency,
            string idempotencyKey, IDictionary<string, string> metadata);

        /// <summary>
        /// Creates an unconfirmed PaymentIntent for the client to confirm interactively (retry flow).
        /// Returns the PaymentIntent id; the client secret is exposed via <see cref="GatewayPaymentIntentSession.ClientSecret"/>.
        /// </summary>
        Task<GatewayPaymentIntentSession> CreateOnSessionPaymentIntentAsync(
            string gatewayCustomerId, decimal amount, string currency,
            string idempotencyKey, IDictionary<string, string> metadata);

        /// <summary>
        /// Verifies the webhook signature and returns the typed event.
        /// Throws <see cref="PaymentGatewayException"/> when the signature is invalid.
        /// </summary>
        GatewayWebhookEvent ConstructWebhookEvent(string rawBody, string signatureHeader, string webhookSecret);
    }

    public record GatewaySetupSession(string SetupIntentClientSecret, string EphemeralKey, string CustomerId);

    public record GatewaySavedCard(string Id, string Brand, string Last4, int ExpMonth, int ExpYear);

    public record GatewayPaymentIntentSession(string PaymentIntentId, string ClientSecret, string EphemeralKey, string CustomerId);

    /// <summary>Normalized webhook event. Type is "payment_intent.succeeded" or "payment_intent.payment_failed".</summary>
    public record GatewayWebhookEvent(string Type, string PaymentIntentId, string? FailureMessage);

    public class PaymentGatewayException : Exception
    {
        /// <summary>Provider PaymentIntent id when the failure happened during confirm — lets the ledger row reference it.</summary>
        public string? PaymentIntentId { get; init; }

        public PaymentGatewayException(string message) : base(message) { }
        public PaymentGatewayException(string message, Exception inner) : base(message, inner) { }
    }
}
