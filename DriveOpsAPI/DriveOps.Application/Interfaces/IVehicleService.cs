using DriveOps.Application.DTOs;

namespace DriveOps.Application.Interfaces
{
    public interface IVehicleService
    {
        Task<VehicleDto?> GetVehicleByIdAsync(Guid vehicleId);
        Task<PaginatedResult<VehicleDto>> GetAllVehiclesAsync(int page = 1, int pageSize = 20);
        Task<PaginatedResult<VehicleDto>> GetAvailableVehiclesAsync(int page = 1, int pageSize = 20);
        Task<VehicleDto> CreateVehicleAsync(CreateVehicleDto dto);
        Task<VehicleDto> UpdateVehicleAsync(UpdateVehicleDto dto);
        Task<VehicleDto> AssignVehicleToDriverAsync(Guid vehicleId, Guid driverId);
        Task<VehicleDto> UnassignVehicleAsync(Guid vehicleId);
        Task DeleteVehicleAsync(Guid vehicleId);
        Task<VehicleDefectReportDto> ReportVehicleDefectAsync(ReportVehicleDefectDto dto);
        Task<PaginatedResult<VehicleDefectReportDto>> GetVehicleDefectsAsync(Guid vehicleId, int page = 1, int pageSize = 20);
        Task<PaginatedResult<VehicleDefectReportDto>> GetDefectsAsync(string? status, DriveOps.Model.Enums.DefectSeverity? severity, Guid? vehicleId, Guid? driverId, int page = 1, int pageSize = 20);
        Task<VehicleDefectReportDto> ResolveDefectAsync(Guid defectId, string? resolutionNotes);
        Task<VehicleDefectReportDto> ReopenDefectAsync(Guid defectId);
    }
}
