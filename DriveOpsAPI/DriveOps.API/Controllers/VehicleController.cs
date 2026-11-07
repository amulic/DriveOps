using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Helpers;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class VehicleController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;
        private readonly IDriverRepository _driverRepository;

        public VehicleController(IVehicleService vehicleService, IDriverRepository driverRepository)
        {
            _vehicleService = vehicleService;
            _driverRepository = driverRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllVehicles(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var vehicles = await _vehicleService.GetAllVehiclesAsync(page, pageSize);
            return Ok(vehicles.MapPage(v => v.ToResponse()));
        }

        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableVehicles(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var vehicles = await _vehicleService.GetAvailableVehiclesAsync(page, pageSize);
            return Ok(vehicles.MapPage(v => v.ToResponse()));
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetVehicleById(Guid id)
        {
            var vehicle = await _vehicleService.GetVehicleByIdAsync(id);
            if (vehicle == null)
                return NotFound();

            return Ok(vehicle.ToResponse());
        }

        [HttpPost]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> CreateVehicle([FromBody] CreateVehicleRequest request)
        {
            var vehicle = await _vehicleService.CreateVehicleAsync(request.ToApplicationDto());
            return CreatedAtAction(nameof(GetVehicleById), new { id = vehicle.Id }, vehicle.ToResponse());
        }

        [HttpPut("{id:guid}")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> UpdateVehicle(Guid id, [FromBody] UpdateVehicleRequest request)
        {
            var vehicle = await _vehicleService.UpdateVehicleAsync(request.ToApplicationDto(id));
            return Ok(vehicle.ToResponse());
        }

        [HttpPost("{id:guid}/assign")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> AssignToDriver(Guid id, [FromBody] AssignVehicleRequest request)
        {
            var vehicle = await _vehicleService.AssignVehicleToDriverAsync(id, request.DriverId);
            return Ok(vehicle.ToResponse());
        }

        [HttpPost("{id:guid}/unassign")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> UnassignVehicle(Guid id)
        {
            var vehicle = await _vehicleService.UnassignVehicleAsync(id);
            return Ok(vehicle.ToResponse());
        }

        [HttpDelete("{id:guid}")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> DeleteVehicle(Guid id)
        {
            await _vehicleService.DeleteVehicleAsync(id);
            return NoContent();
        }

        [HttpPost("{id:guid}/defects")]
        public async Task<IActionResult> ReportDefect(Guid id, [FromBody] ReportVehicleDefectRequest request)
        {
            if (!User.IsInManagementRole())
            {
                // Drivers may only report defects on the vehicle assigned to them.
                var vehicle = await _vehicleService.GetVehicleByIdAsync(id);
                if (vehicle == null)
                    return NotFound();

                var driver = await _driverRepository.GetByIdAsync(request.DriverId);
                if (!User.IsInRole("driver") || vehicle.AssignedDriverId != request.DriverId
                    || driver?.KeycloakId != User.GetKeycloakId())
                    return Forbid();
            }

            try
            {
                var report = await _vehicleService.ReportVehicleDefectAsync(new Application.DTOs.ReportVehicleDefectDto
                {
                    VehicleId = id,
                    DriverId = request.DriverId,
                    Title = request.Title,
                    Description = request.Description,
                    Severity = request.Severity
                });
                return CreatedAtAction(nameof(GetDefects), new { id }, report.ToResponse());
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

        [HttpGet("{id:guid}/defects")]
        public async Task<IActionResult> GetDefects(Guid id,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!User.IsInManagementRole())
            {
                // Drivers may only see defects on the vehicle assigned to them.
                var vehicle = await _vehicleService.GetVehicleByIdAsync(id);
                if (vehicle == null)
                    return NotFound();

                var driver = vehicle.AssignedDriverId.HasValue
                    ? await _driverRepository.GetByIdAsync(vehicle.AssignedDriverId.Value)
                    : null;
                if (driver?.KeycloakId != User.GetKeycloakId())
                    return Forbid();
            }

            try
            {
                page = Math.Max(1, page);
                pageSize = Math.Clamp(pageSize, 1, 100);
                var reports = await _vehicleService.GetVehicleDefectsAsync(id, page, pageSize);
                return Ok(reports.MapPage(r => r.ToResponse()));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }
    }
}
