namespace DriveOps.Application.DTOs
{
    public record RoutePointDto
    {
        public decimal Latitude { get; init; }
        public decimal Longitude { get; init; }
        public DateTime? Timestamp { get; init; }
    }

    public record RouteResultDto
    {
        public double DistanceKm { get; init; }
        public int DurationMinutes { get; init; }
        public List<RoutePointDto> RoutePoints { get; init; } = [];
    }
}
