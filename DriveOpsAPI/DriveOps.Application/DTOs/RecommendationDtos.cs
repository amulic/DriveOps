namespace DriveOps.Application.DTOs
{
    public record RecommendedDriverDto
    {
        public Guid DriverId { get; init; }
        public string DriverName { get; init; } = null!;
        public decimal? Rating { get; init; }
        public int? TotalTrips { get; init; }
        public decimal? CurrentLatitude { get; init; }
        public decimal? CurrentLongitude { get; init; }
        public double? DistanceKm { get; init; }
        /// <summary>0–1 proximity component; null when the driver has no GPS fix.</summary>
        public double? DistanceScore { get; init; }
        /// <summary>0–1 rating component (rating / 5).</summary>
        public double RatingScore { get; init; }
        public double Score { get; init; }
        public Guid? VehicleId { get; init; }
        public string? VehiclePlate { get; init; }
    }
}
