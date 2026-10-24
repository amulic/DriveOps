using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IGeocodingService
    {
        Task<IReadOnlyList<GeocodingResultDto>> SearchAsync(string query, int limit = 5);
        Task<string?> ReverseAsync(decimal lat, decimal lng);
    }
}
