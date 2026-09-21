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
        public double Score { get; init; }
        public Guid? VehicleId { get; init; }
        public string? VehiclePlate { get; init; }
    }
}
