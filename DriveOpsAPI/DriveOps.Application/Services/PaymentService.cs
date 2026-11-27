using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Model.Entity;
using ModelEnums = DriveOps.Model.Enums;

namespace DriveOps.Application.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly ICustomerRepository _customerRepository;
        private readonly ITripRepository _tripRepository;
        private readonly IPaymentRepository _paymentRepository;
        private readonly IPaymentGateway _gateway;
        private readonly IUnitOfWork _unitOfWork;
        private readonly PaymentServiceOptions _options;

        public PaymentService(
            ICustomerRepository customerRepository,
            ITripRepository tripRepository,
            IPaymentRepository paymentRepository,
            IPaymentGateway gateway,
            IUnitOfWork unitOfWork,
            PaymentServiceOptions options)
        {
            _customerRepository = customerRepository;
            _tripRepository = tripRepository;
            _paymentRepository = paymentRepository;
            _gateway = gateway;
            _unitOfWork = unitOfWork;
            _options = options;
        }

        public async Task<SetupSessionDto> CreateSetupSessionAsync(Guid keycloakId)
        {
            var customer = await _customerRepository.GetByKeycloakIdAsync(keycloakId)
                ?? throw new KeyNotFoundException("Customer profile not found for the current user.");

            if (customer.StripeCustomerId == null)
            {
                customer.StripeCustomerId = await _gateway.CreateCustomerAsync(
                    customer.Name, customer.Email, customer.PhoneNumber, keycloakId);
                customer.UpdatedAt = DateTime.UtcNow;
                await _customerRepository.UpdateAsync(customer);
                await _unitOfWork.SaveChangesAsync();
            }

            var session = await _gateway.CreateSetupSessionAsync(customer.StripeCustomerId);
            return new SetupSessionDto(session.SetupIntentClientSecret, session.EphemeralKey, session.CustomerId);
        }

        public async Task<IReadOnlyList<SavedCardDto>> GetSavedCardsAsync(Guid keycloakId)
        {
            var customer = await _customerRepository.GetByKeycloakIdAsync(keycloakId)
                ?? throw new KeyNotFoundException("Customer profile not found for the current user.");

            if (customer.StripeCustomerId == null)
                return Array.Empty<SavedCardDto>();

            var cards = await _gateway.ListCardsAsync(customer.StripeCustomerId);
            return cards.Select(c => new SavedCardDto(c.Id, c.Brand, c.Last4, c.ExpMonth, c.ExpYear)).ToList();
        }

        public async Task DeleteCardAsync(Guid keycloakId, string paymentMethodId)
        {
            var customer = await _customerRepository.GetByKeycloakIdAsync(keycloakId)
                ?? throw new KeyNotFoundException("Customer profile not found for the current user.");

            if (customer.StripeCustomerId == null)
                throw new KeyNotFoundException("No saved cards for this customer.");

            await _gateway.DetachCardAsync(customer.StripeCustomerId, paymentMethodId);
        }

        public async Task ChargeCompletedTripAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.PaymentMethod is not (ModelEnums.PaymentMethod.CreditCard or ModelEnums.PaymentMethod.DebitCard))
                return; // Cash — collected by the driver, nothing to charge.
            if (trip.PaymentStatus == ModelEnums.PaymentStatus.Completed)
                return; // Already paid — idempotent.
            if (trip.ActualFare is not decimal fare || fare <= 0)
                return;

            var customer = await _customerRepository.GetByIdAsync(trip.CustomerId);

            var payment = new Payment
            {
                // Client-side id: EF treats an empty key with the (UUID()) DB default as
                // store-generated, and Pomelo can't retrieve server-generated Guids
                // (renders broken `WHERE ROW_COUNT() = 1 AND ;` SQL). All entities set
                // their id client-side — see MappingExtensions/TripRoute.
                Id = Guid.NewGuid(),
                TripId = trip.Id,
                Amount = fare,
                Method = trip.PaymentMethod.Value,
                Status = ModelEnums.PaymentStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            if (customer?.StripeCustomerId == null)
            {
                payment.Status = ModelEnums.PaymentStatus.Failed;
                payment.FailureReason = "Customer has no saved card.";
                payment.ProcessedAt = DateTime.UtcNow;
                if (trip.PaymentStatus == ModelEnums.PaymentStatus.Pending)
                    trip.PaymentStatus = ModelEnums.PaymentStatus.Failed;
            }
            else
            {
                try
                {
                    var intentId = await _gateway.ChargeOffSessionAsync(
                        customer.StripeCustomerId, fare, _options.Currency,
                        $"trip-{tripId}",
                        new Dictionary<string, string> { ["tripId"] = tripId.ToString() });

                    payment.TransactionId = intentId;
                    payment.Status = ModelEnums.PaymentStatus.Completed;
                    payment.ProcessedAt = DateTime.UtcNow;
                    trip.PaymentStatus = ModelEnums.PaymentStatus.Completed;
                }
                catch (PaymentGatewayException ex)
                {
                    payment.TransactionId = ex.PaymentIntentId;
                    payment.Status = ModelEnums.PaymentStatus.Failed;
                    payment.FailureReason = ex.Message.Length <= 500 ? ex.Message : ex.Message[..500];
                    payment.ProcessedAt = DateTime.UtcNow;
                    // Never downgrade a payment that was already confirmed elsewhere.
                    if (trip.PaymentStatus == ModelEnums.PaymentStatus.Pending)
                        trip.PaymentStatus = ModelEnums.PaymentStatus.Failed;
                }
            }

            await _paymentRepository.AddAsync(payment);
            await _tripRepository.UpdateAsync(trip);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<RetryPaymentSessionDto> CreateRetryPaymentAsync(Guid keycloakId, Guid tripId)
        {
            var customer = await _customerRepository.GetByKeycloakIdAsync(keycloakId)
                ?? throw new KeyNotFoundException("Customer profile not found for the current user.");

            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.CustomerId != customer.Id)
                throw new UnauthorizedAccessException("You can only pay for your own trips.");
            if (trip.TripStatus != ModelEnums.TripStatus.Completed)
                throw new InvalidOperationException("Only completed trips can be paid.");
            if (trip.PaymentMethod is not (ModelEnums.PaymentMethod.CreditCard or ModelEnums.PaymentMethod.DebitCard))
                throw new InvalidOperationException("This trip was not set to be paid by card.");
            if (trip.ActualFare is not decimal fare || fare <= 0)
                throw new InvalidOperationException("This trip has no fare to pay.");

            // Retry only while an amount is actually owed.
            if (trip.PaymentStatus == ModelEnums.PaymentStatus.Completed)
                throw new InvalidOperationException("This trip is already paid.");
            if (trip.PaymentStatus == ModelEnums.PaymentStatus.Refunded)
                throw new InvalidOperationException("This trip has been fully refunded; nothing is owed.");
            if (trip.PaymentStatus is not (ModelEnums.PaymentStatus.Pending or ModelEnums.PaymentStatus.Failed))
                throw new InvalidOperationException("This trip does not have an outstanding amount to pay.");

            if (customer.StripeCustomerId == null)
                throw new InvalidOperationException("Add a card first (Profile → Payment methods).");

            // One active attempt per trip: a Pending ledger row with an intent means
            // the customer must finish (or wait for) that attempt first. Abandoned
            // attempts expire so a retry is never blocked forever.
            var attempts = await _paymentRepository.GetByTripIdAsync(tripId);
            var activeAttempt = attempts
                .Where(p => p.Status == ModelEnums.PaymentStatus.Pending && p.TransactionId != null)
                .OrderByDescending(p => p.CreatedAt)
                .FirstOrDefault();

            if (activeAttempt != null)
            {
                var now = DateTime.UtcNow;
                var createdAt = activeAttempt.CreatedAt ?? DateTime.MinValue;
                if (now - createdAt < TimeSpan.FromMinutes(15))
                    throw new InvalidOperationException(
                        "A payment attempt is already in progress. Finish it before starting a new one.");

                activeAttempt.Status = ModelEnums.PaymentStatus.Failed;
                activeAttempt.FailureReason = "Payment attempt expired before confirmation.";
                activeAttempt.ProcessedAt = now;
                await _paymentRepository.UpdateAsync(activeAttempt);
                await _unitOfWork.SaveChangesAsync();
            }

            var session = await _gateway.CreateOnSessionPaymentIntentAsync(
                customer.StripeCustomerId, fare, _options.Currency,
                $"trip-{tripId}-retry-{Guid.NewGuid():N}",
                new Dictionary<string, string> { ["tripId"] = tripId.ToString() });

            // Ledger row for the retry attempt; the webhook flips it once the app confirms.
            await _paymentRepository.AddAsync(new Payment
            {
                Id = Guid.NewGuid(),
                TripId = trip.Id,
                Amount = fare,
                Method = trip.PaymentMethod.Value,
                Status = ModelEnums.PaymentStatus.Pending,
                TransactionId = session.PaymentIntentId,
                CreatedAt = DateTime.UtcNow
            });
            await _unitOfWork.SaveChangesAsync();

            return new RetryPaymentSessionDto(session.ClientSecret, session.EphemeralKey, session.CustomerId);
        }

        public async Task HandleWebhookAsync(string rawBody, string signatureHeader)
        {
            if (string.IsNullOrWhiteSpace(_options.WebhookSecret))
                throw new InvalidOperationException(
                    "Stripe webhook secret is not configured. Set 'Stripe:WebhookSecret' (see stripe listen).");

            var evt = _gateway.ConstructWebhookEvent(rawBody, signatureHeader, _options.WebhookSecret);

            if (evt.Type is not ("payment_intent.succeeded" or "payment_intent.payment_failed"))
                return; // Not an event we act on — acknowledge with 200.

            var succeeded = evt.Type == "payment_intent.succeeded";

            var payment = await _paymentRepository.GetByTransactionIdAsync(evt.PaymentIntentId);
            if (payment == null)
            {
                // The charge succeeded but no ledger row was persisted (e.g. the process
                // crashed after charging, before SaveChanges). Reconcile from the
                // PaymentIntent's metadata.tripId so the trip does not stay Pending.
                if (!evt.TripId.HasValue)
                    return; // Unknown intent (not created by us) — acknowledge with 200.

                var orphanTrip = await _tripRepository.GetByIdAsync(evt.TripId.Value);
                if (orphanTrip == null)
                    return; // Unknown trip — acknowledge with 200.

                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    // Re-check inside the transaction; a concurrent delivery may have won.
                    if (await _paymentRepository.GetByTransactionIdAsync(evt.PaymentIntentId) != null)
                        return;
                    if (orphanTrip.PaymentStatus == ModelEnums.PaymentStatus.Completed)
                        return; // Already final — idempotent.

                    var reconciled = new Payment
                    {
                        Id = Guid.NewGuid(),
                        TripId = orphanTrip.Id,
                        Amount = orphanTrip.ActualFare ?? 0,
                        Method = orphanTrip.PaymentMethod ?? ModelEnums.PaymentMethod.CreditCard,
                        Status = succeeded ? ModelEnums.PaymentStatus.Completed : ModelEnums.PaymentStatus.Failed,
                        TransactionId = evt.PaymentIntentId,
                        ProcessedAt = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    };
                    if (!succeeded && evt.FailureMessage != null)
                        reconciled.FailureReason = evt.FailureMessage.Length <= 500 ? evt.FailureMessage : evt.FailureMessage[..500];

                    await _paymentRepository.AddAsync(reconciled);

                    // Preserve a confirmed/refunded trip state when processing an
                    // event for a different (orphaned) attempt.
                    if (succeeded)
                    {
                        if (orphanTrip.PaymentStatus is not (ModelEnums.PaymentStatus.Completed or ModelEnums.PaymentStatus.Refunded))
                            orphanTrip.PaymentStatus = ModelEnums.PaymentStatus.Completed;
                    }
                    else if (orphanTrip.PaymentStatus is ModelEnums.PaymentStatus.Pending or ModelEnums.PaymentStatus.Failed)
                    {
                        orphanTrip.PaymentStatus = ModelEnums.PaymentStatus.Failed;
                    }

                    orphanTrip.UpdatedAt = DateTime.UtcNow;
                    await _tripRepository.UpdateAsync(orphanTrip);
                    await _unitOfWork.SaveChangesAsync();
                });
                return;
            }

            // A finalized successful charge is immutable. Late events for the same
            // intent must never unpay the trip or downgrade the ledger row.
            if (payment.Status == ModelEnums.PaymentStatus.Completed)
                return;

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                payment.Status = succeeded ? ModelEnums.PaymentStatus.Completed : ModelEnums.PaymentStatus.Failed;
                payment.ProcessedAt = DateTime.UtcNow;
                if (!succeeded && evt.FailureMessage != null)
                    payment.FailureReason = evt.FailureMessage.Length <= 500 ? evt.FailureMessage : evt.FailureMessage[..500];
                await _paymentRepository.UpdateAsync(payment);

                var trip = await _tripRepository.GetByIdAsync(payment.TripId);
                if (trip != null)
                {
                    // Only move forward: a success confirms the trip unless it was
                    // already refunded; a failure must not clobber a payment that
                    // was already confirmed through another attempt.
                    if (succeeded)
                    {
                        if (trip.PaymentStatus is not (ModelEnums.PaymentStatus.Completed or ModelEnums.PaymentStatus.Refunded))
                            trip.PaymentStatus = ModelEnums.PaymentStatus.Completed;
                    }
                    else if (trip.PaymentStatus is ModelEnums.PaymentStatus.Pending or ModelEnums.PaymentStatus.Failed)
                    {
                        trip.PaymentStatus = ModelEnums.PaymentStatus.Failed;
                    }

                    trip.UpdatedAt = DateTime.UtcNow;
                    await _tripRepository.UpdateAsync(trip);
                }

                await _unitOfWork.SaveChangesAsync();
            });
        }

        public async Task<RefundResultDto> RefundTripPaymentAsync(Guid tripId, decimal? amount, string? reason)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.Completed
                || trip.PaymentMethod is not (ModelEnums.PaymentMethod.CreditCard or ModelEnums.PaymentMethod.DebitCard)
                || trip.PaymentStatus != ModelEnums.PaymentStatus.Completed)
                throw new InvalidOperationException(
                    "Only a completed card trip with a completed payment can be refunded.");

            var payments = await _paymentRepository.GetByTripIdAsync(tripId);
            var charge = payments.FirstOrDefault(p =>
                    p.Status == ModelEnums.PaymentStatus.Completed && p.TransactionId != null)
                ?? throw new InvalidOperationException("No completed card charge was found for this trip.");

            // Refund against the amount actually charged (ledger), never against ActualFare blindly.
            var totalRefunded = payments
                .Where(p => p.Status == ModelEnums.PaymentStatus.Refunded)
                .Sum(p => p.Amount);
            var remaining = charge.Amount - totalRefunded;
            if (remaining <= 0)
                throw new InvalidOperationException("This payment has already been fully refunded.");

            decimal refundAmount;
            if (amount.HasValue)
            {
                if (amount.Value <= 0 || amount.Value > remaining)
                    throw new InvalidOperationException(
                        $"Refund amount must be greater than 0 and at most {remaining:0.00}.");
                refundAmount = amount.Value;
            }
            else
            {
                refundAmount = remaining;
            }

            // Provider call BEFORE the DB transaction: a decline leaves nothing persisted,
            // so the operator can retry safely.
            var metadata = new Dictionary<string, string> { ["tripId"] = tripId.ToString() };
            if (!string.IsNullOrWhiteSpace(reason))
                metadata["reason"] = reason!;

            var refund = await _gateway.RefundAsync(
                charge.TransactionId!, refundAmount, _options.Currency,
                $"refund-{tripId}-{Guid.NewGuid():N}", metadata);

            var fullyRefunded = totalRefunded + refund.Amount >= charge.Amount;

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // Append-only ledger: the original charge row is never mutated.
                await _paymentRepository.AddAsync(new Payment
                {
                    Id = Guid.NewGuid(),
                    TripId = tripId,
                    Amount = refund.Amount,
                    Method = charge.Method,
                    Status = ModelEnums.PaymentStatus.Refunded,
                    TransactionId = refund.RefundId,
                    ProcessedAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow
                });

                if (fullyRefunded)
                {
                    trip.PaymentStatus = ModelEnums.PaymentStatus.Refunded;
                    trip.UpdatedAt = DateTime.UtcNow;
                    await _tripRepository.UpdateAsync(trip);
                }

                await _unitOfWork.SaveChangesAsync();
            });

            return new RefundResultDto(
                charge.Id,
                refund.RefundId,
                refund.Amount,
                totalRefunded + refund.Amount,
                fullyRefunded);
        }

        public async Task<bool> CustomerHasSavedCardAsync(Guid customerId)
        {
            var customer = await _customerRepository.GetByIdAsync(customerId);
            if (customer?.StripeCustomerId == null)
                return false;

            var cards = await _gateway.ListCardsAsync(customer.StripeCustomerId);
            return cards.Count > 0;
        }
    }

    /// <summary>Non-secret payment settings wired from configuration in Program.cs.</summary>
    public class PaymentServiceOptions
    {
        public string Currency { get; set; } = "eur";
        public string WebhookSecret { get; set; } = "";
    }
}
