using DriveOps.RealTime.Contracts.Enums;

namespace DriveOps.Application.Helpers
{
    public class FareCalculatorOptions
    {
        public decimal BaseFare { get; set; } = 2.50m;
        public decimal PerKmRate { get; set; } = 1.50m;
        public decimal PerMinuteRate { get; set; } = 0.25m;
        public decimal PremiumMultiplier { get; set; } = 1.5m;
        public decimal SharedMultiplier { get; set; } = 0.7m;
    }

    public static class FareCalculator
    {
        private static FareCalculatorOptions _options = new();

        public static void Configure(FareCalculatorOptions options) => _options = options;

        public static FareCalculatorOptions CurrentOptions => _options;

        public static decimal Calculate(decimal distanceKm, int durationMinutes, TripType tripType)
            => Calculate(distanceKm, durationMinutes, tripType, _options);

        public static decimal Calculate(decimal distanceKm, int durationMinutes, TripType tripType, FareCalculatorOptions options)
        {
            decimal multiplier = tripType switch
            {
                TripType.Premium => options.PremiumMultiplier,
                TripType.Shared => options.SharedMultiplier,
                _ => 1.0m
            };

            return Math.Round(
                (options.BaseFare + distanceKm * options.PerKmRate + durationMinutes * options.PerMinuteRate) * multiplier, 2);
        }
    }
}