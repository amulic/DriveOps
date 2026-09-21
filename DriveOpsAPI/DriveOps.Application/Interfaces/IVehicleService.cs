using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleService
    {
        Task<VehicleDto?> GetVehicleByIdAsync(Guid vehicleId);
        Task<IEnumerable<VehicleDto>> GetAllVehiclesAsync();
        Task<IEnumerable<VehicleDto>> GetAvailableVehiclesAsync();
        Task<VehicleDto> CreateVehicleAsync(CreateVehicleDto dto);
        Task<VehicleDto> UpdateVehicleAsync(UpdateVehicleDto dto);
        Task<VehicleDto> AssignVehicleToDriverAsync(Guid vehicleId, Guid driverId);
        Task<VehicleDto> UnassignVehicleAsync(Guid vehicleId);
        Task DeleteVehicleAsync(Guid vehicleId);
        Task<VehicleDefectReportDto> ReportVehicleDefectAsync(ReportVehicleDefectDto dto);
        Task<IEnumerable<VehicleDefectReportDto>> GetVehicleDefectsAsync(Guid vehicleId);
    }
}
