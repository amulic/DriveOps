using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IDriverService
    {
        Task<PaginatedResult<DriverDto>> GetAllDriversAsync(int page = 1, int pageSize = 50);
        Task<DriverDto?> GetDriverByIdAsync(Guid driverId);
        Task<DriverDto?> GetDriverByKeycloakIdAsync(Guid keycloakId);
        Task<PaginatedResult<DriverDto>> GetAvailableDriversAsync(int page = 1, int pageSize = 50);
        Task<PaginatedResult<DriverDto>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm, int page = 1, int pageSize = 50);
        Task<DriverDto> CreateDriverAsync(CreateDriverDto dto);
        Task<List<PromotionCandidateDto>> GetPromotionCandidatesAsync(string search);
        Task<DriverDto> PromoteDriverAsync(CreateDriverDto dto);
        Task<DriverDto> OnboardDriverAsync(OnboardDriverDto dto);
        Task<DriverDto> UpdateDriverAsync(UpdateDriverDto dto);
        Task UpdateDriverLocationAsync(UpdateDriverLocationDto dto);
        Task SetDriverOnlineStatusAsync(Guid driverId, bool isOnline);
        Task SuspendDriverAsync(Guid driverId);
        Task ActivateDriverAsync(Guid driverId);
    }
}
