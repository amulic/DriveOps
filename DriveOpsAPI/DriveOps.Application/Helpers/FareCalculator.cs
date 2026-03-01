using DriveOps.Model.Enums;

namespace DriveOps.Application.Helpers
{
    public static class FareCalculator
    {
        public static decimal Calculate(decimal distanceKm, int durationMinutes, TripType tripType)
        {
            const decimal baseFare = 2.50m;
            const decimal perKmRate = 1.50m;
            const decimal perMinuteRate = 0.25m;

            decimal multiplier = tripType switch
            {
                TripType.Premium => 1.5m,
                TripType.Shared  => 0.7m,
                _                => 1.0m
            };

            return Math.Round(
                (baseFare + distanceKm * perKmRate + durationMinutes * perMinuteRate) * multiplier, 2);
        }
    }
}
