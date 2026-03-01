using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VehicleController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;

        public VehicleController(IVehicleService vehicleService)
        {
            _vehicleService = vehicleService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllVehicles()
        {
            var vehicles = await _vehicleService.GetAllVehiclesAsync();
            return Ok(vehicles.Select(v => v.ToResponse()));
        }

        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableVehicles()
        {
            var vehicles = await _vehicleService.GetAvailableVehiclesAsync();
            return Ok(vehicles.Select(v => v.ToResponse()));
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
        public async Task<IActionResult> CreateVehicle([FromBody] CreateVehicleRequest request)
        {
            var vehicle = await _vehicleService.CreateVehicleAsync(request.ToApplicationDto());
            return CreatedAtAction(nameof(GetVehicleById), new { id = vehicle.Id }, vehicle.ToResponse());
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateVehicle(Guid id, [FromBody] UpdateVehicleRequest request)
        {
            var vehicle = await _vehicleService.UpdateVehicleAsync(request.ToApplicationDto(id));
            return Ok(vehicle.ToResponse());
        }

        [HttpPost("{id:guid}/assign")]
        public async Task<IActionResult> AssignToDriver(Guid id, [FromBody] AssignVehicleRequest request)
        {
            var vehicle = await _vehicleService.AssignVehicleToDriverAsync(id, request.DriverId);
            return Ok(vehicle.ToResponse());
        }

        [HttpPost("{id:guid}/unassign")]
        public async Task<IActionResult> UnassignVehicle(Guid id)
        {
            var vehicle = await _vehicleService.UnassignVehicleAsync(id);
            return Ok(vehicle.ToResponse());
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> DeleteVehicle(Guid id)
        {
            await _vehicleService.DeleteVehicleAsync(id);
            return NoContent();
        }
    }
}
