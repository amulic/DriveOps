using DriveOps.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Stripe;

namespace DriveOps.Infrastructure.Payments
{
    /// <summary>
    /// Stripe implementation of <see cref="IPaymentGateway"/>.
    /// Card data never touches our servers — the mobile app talks to Stripe via PaymentSheet;
    /// this service only creates intents/keys and charges saved cards.
    /// </summary>
    public class StripePaymentGateway : IPaymentGateway
    {
        private readonly StripeClient _client;
        private readonly ILogger<StripePaymentGateway> _logger;

        public StripePaymentGateway(string secretKey, ILogger<StripePaymentGateway> logger)
        {
            if (string.IsNullOrWhiteSpace(secretKey))
                throw new InvalidOperationException(
                    "Stripe secret key is not configured. Set 'Stripe:SecretKey' (e.g. via dotnet user-secrets).");
            _client = new StripeClient(secretKey);
            _logger = logger;
        }

        public async Task<string> CreateCustomerAsync(string name, string? email, string? phone, Guid keycloakId)
        {
            try
            {
                var customer = await new CustomerService(_client).CreateAsync(new CustomerCreateOptions
                {
                    Name = name,
                    Email = email,
                    Phone = phone,
                    Metadata = new Dictionary<string, string> { ["keycloakId"] = keycloakId.ToString() }
                });
                return customer.Id;
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "create Stripe customer");
            }
        }

        public async Task<GatewaySetupSession> CreateSetupSessionAsync(string gatewayCustomerId)
        {
            try
            {
                var setupIntent = await new SetupIntentService(_client).CreateAsync(new SetupIntentCreateOptions
                {
                    Customer = gatewayCustomerId,
                    AutomaticPaymentMethods = new SetupIntentAutomaticPaymentMethodsOptions { Enabled = true }
                });

                var ephemeralKey = await CreateEphemeralKeyAsync(gatewayCustomerId);

                return new GatewaySetupSession(setupIntent.ClientSecret, ephemeralKey, gatewayCustomerId);
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "create setup session");
            }
        }

        public async Task<IReadOnlyList<GatewaySavedCard>> ListCardsAsync(string gatewayCustomerId)
        {
            try
            {
                var methods = await new PaymentMethodService(_client).ListAsync(new PaymentMethodListOptions
                {
                    Customer = gatewayCustomerId,
                    Type = "card"
                });

                return methods.Data
                    .Where(m => m.Card != null)
                    .Select(m => new GatewaySavedCard(
                        m.Id,
                        m.Card.Brand ?? "card",
                        m.Card.Last4 ?? "****",
                        (int)m.Card.ExpMonth,
                        (int)m.Card.ExpYear))
                    .ToList();
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "list saved cards");
            }
        }

        public async Task DetachCardAsync(string gatewayCustomerId, string paymentMethodId)
        {
            try
            {
                var service = new PaymentMethodService(_client);
                var method = await service.GetAsync(paymentMethodId);
                if (method.CustomerId != gatewayCustomerId)
                    throw new PaymentGatewayException("Payment method does not belong to this customer.");

                await service.DetachAsync(paymentMethodId);
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "delete saved card");
            }
        }

        public async Task<string> ChargeOffSessionAsync(
            string gatewayCustomerId, decimal amount, string currency,
            string idempotencyKey, IDictionary<string, string> metadata)
        {
            // Off-session charges need an explicit payment method — use the customer's most recent card.
            var cards = await ListCardsAsync(gatewayCustomerId);
            var defaultCard = cards.FirstOrDefault()
                ?? throw new PaymentGatewayException("Customer has no saved card to charge.");

            var service = new PaymentIntentService(_client);
            PaymentIntent intent;
            try
            {
                intent = await service.CreateAsync(new PaymentIntentCreateOptions
                {
                    Amount = ToMinorUnits(amount),
                    Currency = currency,
                    Customer = gatewayCustomerId,
                    Metadata = new Dictionary<string, string>(metadata)
                }, new RequestOptions { IdempotencyKey = idempotencyKey });
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "create payment intent");
            }

            try
            {
                // Separate create/confirm: a declined confirm still leaves us the PaymentIntent id,
                // which the ledger row needs so the async webhook can find it.
                await service.ConfirmAsync(intent.Id, new PaymentIntentConfirmOptions
                {
                    PaymentMethod = defaultCard.Id,
                    OffSession = true
                });
                return intent.Id;
            }
            catch (StripeException ex)
            {
                var wrapped = Wrap(ex, "charge saved card");
                throw new PaymentGatewayException(wrapped.Message, ex) { PaymentIntentId = intent.Id };
            }
        }

        public async Task<GatewayPaymentIntentSession> CreateOnSessionPaymentIntentAsync(
            string gatewayCustomerId, decimal amount, string currency,
            string idempotencyKey, IDictionary<string, string> metadata)
        {
            try
            {
                var intent = await new PaymentIntentService(_client).CreateAsync(new PaymentIntentCreateOptions
                {
                    Amount = ToMinorUnits(amount),
                    Currency = currency,
                    Customer = gatewayCustomerId,
                    // Save the card used for the retry as the new default for future off-session charges.
                    SetupFutureUsage = "off_session",
                    AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions { Enabled = true },
                    Metadata = new Dictionary<string, string>(metadata)
                }, new RequestOptions { IdempotencyKey = idempotencyKey });

                var ephemeralKey = await CreateEphemeralKeyAsync(gatewayCustomerId);

                return new GatewayPaymentIntentSession(intent.Id, intent.ClientSecret, ephemeralKey, gatewayCustomerId);
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "create retry payment");
            }
        }

        public async Task<GatewayRefundResult> RefundAsync(
            string paymentIntentId, decimal? amount, string currency,
            string idempotencyKey, IDictionary<string, string> metadata)
        {
            try
            {
                var refund = await new RefundService(_client).CreateAsync(new RefundCreateOptions
                {
                    PaymentIntent = paymentIntentId,
                    Amount = amount.HasValue ? ToMinorUnits(amount.Value) : null,
                    Reason = "requested_by_customer",
                    Metadata = new Dictionary<string, string>(metadata)
                }, new RequestOptions { IdempotencyKey = idempotencyKey });

                return new GatewayRefundResult(
                    refund.Id,
                    refund.Amount / 100m,
                    refund.Status ?? "succeeded");
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "refund payment");
            }
        }

        public GatewayWebhookEvent ConstructWebhookEvent(string rawBody, string signatureHeader, string webhookSecret)
        {
            try
            {
                var stripeEvent = EventUtility.ConstructEvent(rawBody, signatureHeader, webhookSecret);

                if (stripeEvent.Data?.Object is not PaymentIntent intent)
                    return new GatewayWebhookEvent(stripeEvent.Type, "", null);

                Guid? tripId = null;
                if (intent.Metadata != null
                    && intent.Metadata.TryGetValue("tripId", out var rawTripId)
                    && Guid.TryParse(rawTripId, out var parsedTripId))
                {
                    tripId = parsedTripId;
                }

                return new GatewayWebhookEvent(
                    stripeEvent.Type,
                    intent.Id,
                    intent.LastPaymentError?.Message,
                    tripId);
            }
            catch (StripeException ex)
            {
                throw Wrap(ex, "verify webhook signature");
            }
        }

        private async Task<string> CreateEphemeralKeyAsync(string gatewayCustomerId)
        {
            var key = await new EphemeralKeyService(_client).CreateAsync(new EphemeralKeyCreateOptions
            {
                Customer = gatewayCustomerId,
                // Ephemeral keys require an explicit Stripe-Version for the mobile SDK.
                StripeVersion = StripeConfiguration.ApiVersion
            });
            return key.Secret;
        }

        private static long ToMinorUnits(decimal amount) =>
            (long)Math.Round(amount * 100m, MidpointRounding.AwayFromZero);

        private PaymentGatewayException Wrap(StripeException ex, string operation)
        {
            var detail = ex.StripeError?.Message ?? ex.Message;
            _logger.LogWarning(ex, "Stripe {Operation} failed: {Detail}", operation, detail);
            return new PaymentGatewayException($"Stripe failed to {operation}: {detail}", ex);
        }
    }
}
