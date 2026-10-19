using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using System.Globalization;
using System.Net.Http.Json;
using System.Text.Json.Serialization;

namespace DriveOps.Infrastructure.Services
{
    /// Geocoding via Nominatim (OpenStreetMap). The typed HttpClient carries
    /// the User-Agent the Nominatim usage policy requires (registered in DI).
    public class NominatimGeocodingService : IGeocodingService
    {
        private readonly HttpClient _httpClient;

        public NominatimGeocodingService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<IReadOnlyList<GeocodingResultDto>> SearchAsync(string query, int limit = 5)
        {
            if (string.IsNullOrWhiteSpace(query))
                return [];

            var url = $"search?q={Uri.EscapeDataString(query)}&format=jsonv2&limit={limit}";
            var results = await _httpClient.GetFromJsonAsync<List<NominatimResult>>(url) ?? [];

            var mapped = new List<GeocodingResultDto>();
            foreach (var r in results)
            {
                if (decimal.TryParse(r.Lat, NumberStyles.Number, CultureInfo.InvariantCulture, out var lat) &&
                    decimal.TryParse(r.Lon, NumberStyles.Number, CultureInfo.InvariantCulture, out var lon))
                {
                    mapped.Add(new GeocodingResultDto
                    {
                        DisplayName = r.DisplayName ?? string.Empty,
                        Latitude = lat,
                        Longitude = lon
                    });
                }
            }
            return mapped;
        }

        public async Task<string?> ReverseAsync(decimal lat, decimal lng)
        {
            var url = "reverse" +
                $"?lat={lat.ToString(CultureInfo.InvariantCulture)}" +
                $"&lon={lng.ToString(CultureInfo.InvariantCulture)}" +
                "&format=jsonv2";

            var response = await _httpClient.GetAsync(url);
            if (!response.IsSuccessStatusCode)
                return null;

            var result = await response.Content.ReadFromJsonAsync<NominatimResult>();
            return string.IsNullOrWhiteSpace(result?.DisplayName) ? null : result.DisplayName;
        }

        private class NominatimResult
        {
            [JsonPropertyName("display_name")]
            public string? DisplayName { get; set; }

            [JsonPropertyName("lat")]
            public string? Lat { get; set; }

            [JsonPropertyName("lon")]
            public string? Lon { get; set; }
        }
    }
}
