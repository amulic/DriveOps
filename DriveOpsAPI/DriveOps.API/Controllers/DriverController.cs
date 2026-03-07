using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DriverController : ControllerBase
    {
        private readonly IDriverService _driverService;

        public DriverController(IDriverService driverService)
        {
            _driverService = driverService;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetDriverById(Guid id)
        {
            var driver = await _driverService.GetDriverByIdAsync(id);
            if (driver == null)
                return NotFound();

            return Ok(driver.ToResponse());
        }

        [HttpGet("user/{userId:guid}")]
        public async Task<IActionResult> GetDriverByUserId(Guid userId)
        {
            var driver = await _driverService.GetDriverByUserIdAsync(userId);
            if (driver == null)
                return NotFound();

            return Ok(driver.ToResponse());
        }

        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableDrivers()
        {
            var drivers = await _driverService.GetAvailableDriversAsync();
            return Ok(drivers.Select(d => d.ToResponse()));
        }

        [HttpGet("nearby")]
        public async Task<IActionResult> GetNearbyDrivers(
            [FromQuery] decimal latitude,
            [FromQuery] decimal longitude,
            [FromQuery] decimal radiusKm = 5)
        {
            var drivers = await _driverService.GetNearbyDriversAsync(latitude, longitude, radiusKm);
            return Ok(drivers.Select(d => d.ToResponse()));
        }

        [HttpPost]
        public async Task<IActionResult> CreateDriver([FromBody] CreateDriverRequest request)
        {
            var driver = await _driverService.CreateDriverAsync(request.ToApplicationDto());
            return CreatedAtAction(nameof(GetDriverById), new { id = driver.Id }, driver.ToResponse());
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateDriver(Guid id, [FromBody] UpdateDriverRequest request)
        {
            var driver = await _driverService.UpdateDriverAsync(request.ToApplicationDto(id));
            return Ok(driver.ToResponse());
        }

        [HttpPatch("{id:guid}/location")]
        public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateDriverLocationRequest request)
        {
            await _driverService.UpdateDriverLocationAsync(request.ToApplicationDto(id));
            return NoContent();
        }

        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> SetOnlineStatus(Guid id, [FromBody] SetDriverStatusRequest request)
        {
            await _driverService.SetDriverOnlineStatusAsync(id, request.IsOnline);
            return NoContent();
        }

        [HttpPost("{id:guid}/suspend")] // deactivate
        public async Task<IActionResult> SuspendDriver(Guid id)
        {
            await _driverService.SuspendDriverAsync(id);
            return NoContent();
        }

        [HttpPost("{id:guid}/activate")]
        public async Task<IActionResult> ActivateDriver(Guid id)
        {
            await _driverService.ActivateDriverAsync(id);
            return NoContent();
        }
    }
}
