using DriveOps.Application.Interfaces;
using DriveOps.Application.DTOs;
using DriveOps.Model.Enums;
using System.Globalization;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace DriveOps.Infrastructure.Services
{
    public class OsrmRoutingService : IRoutingService
    {
        private readonly HttpClient _httpClient;

        public OsrmRoutingService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<RouteResultDto?> GetRouteAsync(decimal originLat, decimal originLon, decimal destLat, decimal destLon)
        {
            var url = $"route/v1/driving/" +
                $"{FormatCoord(originLon)},{FormatCoord(originLat)};" +
                $"{FormatCoord(destLon)},{FormatCoord(destLat)}" +
                $"?overview=full&geometries=geojson&steps=true";

            var response = await _httpClient.GetAsync(url);
            if (!response.IsSuccessStatusCode)
                return null;

            var osrmResult = await response.Content.ReadFromJsonAsync<OsrmResponse>();
            if (osrmResult?.Routes == null || osrmResult.Routes.Count == 0)
                return null;

            var route = osrmResult.Routes[0];

            var routePoints = new List<RoutePointDto>();
            if (route.Geometry?.Coordinates != null)
            {
                foreach (var coord in route.Geometry.Coordinates)
                {
                    if (coord.Count >= 2)
                    {
                        routePoints.Add(new RoutePointDto
                        {
                            Latitude = coord[1],
                            Longitude = coord[0]
                        });
                    }
                }
            }

            return new RouteResultDto
            {
                DistanceKm = Math.Round(route.Distance / 1000.0, 2),
                DurationMinutes = (int)Math.Ceiling(route.Duration / 60.0),
                RoutePoints = routePoints
            };
        }

        public async Task<TripEstimateDto> GetTripEstimateAsync(
            decimal originLat, decimal originLon,
            decimal destLat, decimal destLon,
            TripType tripType)
        {
            var route = await GetRouteAsync(originLat, originLon, destLat, destLon);

            if (route == null)
                throw new InvalidOperationException("Route could not be calculated for the given coordinates.");

            var fare = CalculateFare(route.DistanceKm, route.DurationMinutes, tripType);

            return new TripEstimateDto
            {
                DistanceKm = route.DistanceKm,
                DurationMinutes = route.DurationMinutes,
                EstimatedFare = fare,
                RoutePoints = route.RoutePoints
            };
        }

        private static decimal CalculateFare(double distanceKm, int durationMinutes, TripType tripType)
        {
            // Base fare + per-km rate + per-minute rate
            decimal baseFare = 2.50m;
            decimal perKmRate = 1.50m;
            decimal perMinuteRate = 0.25m;

            decimal multiplier = tripType switch
            {
                TripType.Premium  => 1.5m,
                TripType.Shared   => 0.7m,
                _                 => 1.0m
            };

            var fare = (baseFare + (decimal)distanceKm * perKmRate + durationMinutes * perMinuteRate) * multiplier;
            return Math.Round(fare, 2);
        }

        private static string FormatCoord(decimal value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }

        // OSRM response models (internal)
        private class OsrmResponse
        {
            [JsonPropertyName("code")]
            public string? Code { get; set; }

            [JsonPropertyName("routes")]
            public List<OsrmRoute>? Routes { get; set; }
        }

        private class OsrmRoute
        {
            [JsonPropertyName("distance")]
            public double Distance { get; set; }

            [JsonPropertyName("duration")]
            public double Duration { get; set; }

            [JsonPropertyName("geometry")]
            public OsrmGeometry? Geometry { get; set; }
        }

        private class OsrmGeometry
        {
            [JsonPropertyName("type")]
            public string? Type { get; set; }

            [JsonPropertyName("coordinates")]
            public List<List<decimal>>? Coordinates { get; set; }
        }
    }
}
