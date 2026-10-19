namespace DriveOps.Application.DTOs
{
    public record GeocodingResultDto
    {
        public string DisplayName { get; init; } = string.Empty;
        public decimal Latitude { get; init; }
        public decimal Longitude { get; init; }
    }
}
