namespace DriveOps.Application.Exceptions
{
    public class ActiveTripExistsException : Exception
    {
        public ActiveTripExistsException(string message) : base(message) { }
    }

    /// <summary>
    /// A request that does not satisfy a business precondition (e.g. card chosen
    /// without a saved card, unsupported payment method). Carries a stable code
    /// so clients can react specifically instead of treating it as an outage.
    /// </summary>
    public class TripRequestValidationException : Exception
    {
        public string Code { get; }

        public TripRequestValidationException(string code, string message) : base(message)
        {
            Code = code;
        }
    }
}
