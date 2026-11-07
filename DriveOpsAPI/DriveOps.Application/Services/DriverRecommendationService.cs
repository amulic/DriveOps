using DriveOps.Application.DTOs;
using DriveOps.Application.Helpers;
using DriveOps.Application.Interfaces;
using ModelEnums = DriveOps.Model.Enums;

namespace DriveOps.Application.Services
{
    public class DriverRecommendationService : IDriverRecommendationService
    {
        private const decimal SearchRadiusKm = 10m;

        private readonly ITripRepository _tripRepository;
        private readonly IDriverRepository _driverRepository;

        public DriverRecommendationService(
            ITripRepository tripRepository,
            IDriverRepository driverRepository)
        {
            _tripRepository = tripRepository;
            _driverRepository = driverRepository;
        }

        public async Task<IEnumerable<RecommendedDriverDto>> GetRecommendedDriversAsync(Guid tripId, int count = 5)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.Requested
                && trip.TripStatus != ModelEnums.TripStatus.NoDriverAvailable)
                throw new InvalidOperationException("Trip is not in an assignable state.");

            // Availability is a hard filter: both queries only return online, active drivers.
            // GetNearbyDriversAsync additionally requires coordinates, so drivers on a trip
            // (OnTrip) are excluded by construction.
            var candidates = await _driverRepository.GetNearbyDriversAsync(
                trip.PickupLatitude, trip.PickupLongitude, SearchRadiusKm);

            if (!candidates.Any())
                candidates = await _driverRepository.GetAvailableDriversAsync();

            var scored = candidates
                .Select(d =>
                {
                    double? distanceKm = null;
                    double distanceScore = 0;

                    if (d.CurrentLatitude != null && d.CurrentLongitude != null)
                    {
                        distanceKm = GeoHelper.DistanceKm(
                            d.CurrentLatitude.Value, d.CurrentLongitude.Value,
                            trip.PickupLatitude, trip.PickupLongitude);
                        distanceScore = Math.Max(0, 1 - distanceKm.Value / (double)SearchRadiusKm);
                    }

                    var ratingScore = (double)((d.Rating ?? 5.0m) / 5.0m);
                    var score = 0.6 * distanceScore + 0.4 * ratingScore;

                    return new RecommendedDriverDto
                    {
                        DriverId = d.Id,
                        DriverName = $"{d.FirstName} {d.LastName}".Trim(),
                        Rating = d.Rating,
                        TotalTrips = d.TotalTrips,
                        CurrentLatitude = d.CurrentLatitude,
                        CurrentLongitude = d.CurrentLongitude,
                        DistanceKm = distanceKm,
                        DistanceScore = distanceKm.HasValue ? distanceScore : null,
                        RatingScore = ratingScore,
                        Score = score
                    };
                })
                .OrderByDescending(dto => dto.Score)
                .Take(count)
                .ToList();

            // Assign requires a vehicleId, so enrich each candidate with their first
            // available vehicle (enables one-click assign; null when none).
            for (var i = 0; i < scored.Count; i++)
            {
                var dto = scored[i];
                var withVehicles = await _driverRepository.GetWithVehiclesAsync(dto.DriverId);
                var vehicle = withVehicles?.Vehicles
                    .FirstOrDefault(v => v.Status == ModelEnums.VehicleStatus.Available);

                if (vehicle != null)
                {
                    scored[i] = dto with { VehicleId = vehicle.Id, VehiclePlate = vehicle.LicensePlate };
                }
            }

            return scored;
        }
    }
}
