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

        [HttpGet]
        public async Task<IActionResult> GetAllDrivers(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _driverService.GetAllDriversAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetDriverById(Guid id)
        {
            var driver = await _driverService.GetDriverByIdAsync(id);
            if (driver == null)
                return NotFound();

            return Ok(driver.ToResponse());
        }

        [HttpGet("keycloak/{keycloakId:guid}")]
        public async Task<IActionResult> GetDriverByKeycloakId(Guid keycloakId)
        {
            var driver = await _driverService.GetDriverByKeycloakIdAsync(keycloakId);
            if (driver == null)
                return NotFound();

            return Ok(driver.ToResponse());
        }

        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableDrivers(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _driverService.GetAvailableDriversAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("nearby")]
        public async Task<IActionResult> GetNearbyDrivers(
            [FromQuery] decimal latitude,
            [FromQuery] decimal longitude,
            [FromQuery] decimal radiusKm = 5,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _driverService.GetNearbyDriversAsync(latitude, longitude, radiusKm, page, pageSize);
            return Ok(result);
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

        [HttpPost("{id:guid}/suspend")]
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
