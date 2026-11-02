namespace DriveOps.API.ControllerDtos.Request
{
    /// <summary>Management-initiated refund. Amount null = refund the remaining charged amount.</summary>
    public class RefundTripRequest
    {
        public decimal? Amount { get; set; }
        public string? Reason { get; set; }
    }
}
