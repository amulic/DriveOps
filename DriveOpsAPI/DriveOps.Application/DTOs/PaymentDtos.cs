namespace DriveOps.Application.DTOs
{
    /// <summary>Everything the mobile PaymentSheet needs to save a card (setup mode).</summary>
    public record SetupSessionDto(
        string SetupIntentClientSecret,
        string EphemeralKey,
        string GatewayCustomerId);

    public record SavedCardDto(string Id, string Brand, string Last4, int ExpMonth, int ExpYear);

    /// <summary>Everything the mobile PaymentSheet needs to confirm a retry (payment mode).</summary>
    public record RetryPaymentSessionDto(
        string PaymentIntentClientSecret,
        string EphemeralKey,
        string GatewayCustomerId);
}
