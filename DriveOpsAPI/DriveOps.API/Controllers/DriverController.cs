using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Helpers;
using DriveOps.API.Mappings;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class DriverController : ControllerBase
    {
        private readonly IDriverService _driverService;

        public DriverController(IDriverService driverService)
        {
            _driverService = driverService;
        }

        [HttpGet]
        [Authorize(Roles = "admin,dispatcher")]
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

            if (!User.IsInManagementRole() && driver.KeycloakId != User.GetKeycloakId())
                return Forbid();

            return Ok(driver.ToResponse());
        }

        [HttpGet("keycloak/{keycloakId:guid}")]
        public async Task<IActionResult> GetDriverByKeycloakId(Guid keycloakId)
        {
            if (!User.IsInManagementRole() && keycloakId != User.GetKeycloakId())
                return Forbid();

            var driver = await _driverService.GetDriverByKeycloakIdAsync(keycloakId);
            if (driver == null)
                return NotFound();

            return Ok(driver.ToResponse());
        }

        [HttpGet("available")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> GetAvailableDrivers(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _driverService.GetAvailableDriversAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("nearby")]
        [Authorize(Roles = "admin,dispatcher")]
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
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> CreateDriver([FromBody] CreateDriverRequest request)
        {
            try
            {
                var driver = await _driverService.CreateDriverAsync(request.ToApplicationDto());
                return CreatedAtAction(nameof(GetDriverById), new { id = driver.Id }, driver.ToResponse());
            }
            catch (FluentValidation.ValidationException ex)
            {
                return BadRequest(new { message = string.Join(" ", ex.Errors.Select(e => e.ErrorMessage)) });
            }
        }

        // Keycloak-side search is hard-capped at 20 results, so no pagination is needed.
        [HttpGet("candidates")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> GetPromotionCandidates([FromQuery] string? search)
        {
            try
            {
                var candidates = await _driverService.GetPromotionCandidatesAsync(search ?? string.Empty);
                return Ok(candidates.Select(c => c.ToResponse()).ToList());
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPost("promote")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> PromoteDriver([FromBody] CreateDriverRequest request)
        {
            try
            {
                var driver = await _driverService.PromoteDriverAsync(request.ToApplicationDto());
                return CreatedAtAction(nameof(GetDriverById), new { id = driver.Id }, driver.ToResponse());
            }
            catch (KeycloakUserNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (DuplicateDriverException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (FluentValidation.ValidationException ex)
            {
                return BadRequest(new { message = string.Join(" ", ex.Errors.Select(e => e.ErrorMessage)) });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPost("onboard")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> OnboardDriver([FromBody] OnboardDriverRequest request)
        {
            try
            {
                var driver = await _driverService.OnboardDriverAsync(request.ToApplicationDto());
                return CreatedAtAction(nameof(GetDriverById), new { id = driver.Id }, driver.ToResponse());
            }
            catch (FluentValidation.ValidationException ex)
            {
                return BadRequest(new { message = string.Join(" ", ex.Errors.Select(e => e.ErrorMessage)) });
            }
            catch (KeycloakUserConflictException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        // KeycloakAdminService throws InvalidOperationException on non-success admin/token
        // responses; HttpRequestException = Keycloak unreachable; TaskCanceledException = timeout.
        private static bool IsKeycloakFailure(Exception ex) =>
            ex is InvalidOperationException or HttpRequestException or TaskCanceledException;

        private IActionResult KeycloakError(Exception ex) =>
            StatusCode(502, new { message = $"Keycloak admin service error: {ex.Message}" });

        [HttpPut("{id:guid}")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> UpdateDriver(Guid id, [FromBody] UpdateDriverRequest request)
        {
            var driver = await _driverService.UpdateDriverAsync(request.ToApplicationDto(id));
            return Ok(driver.ToResponse());
        }

        [HttpPatch("{id:guid}/location")]
        public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateDriverLocationRequest request)
        {
            var forbidden = await ForbidUnlessSelfOrManagementAsync(id);
            if (forbidden != null)
                return forbidden;

            await _driverService.UpdateDriverLocationAsync(request.ToApplicationDto(id));
            return NoContent();
        }

        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> SetOnlineStatus(Guid id, [FromBody] SetDriverStatusRequest request)
        {
            var forbidden = await ForbidUnlessSelfOrManagementAsync(id);
            if (forbidden != null)
                return forbidden;

            await _driverService.SetDriverOnlineStatusAsync(id, request.IsOnline);
            return NoContent();
        }

        [HttpPost("{id:guid}/suspend")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> SuspendDriver(Guid id)
        {
            await _driverService.SuspendDriverAsync(id);
            return NoContent();
        }

        [HttpPost("{id:guid}/activate")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> ActivateDriver(Guid id)
        {
            await _driverService.ActivateDriverAsync(id);
            return NoContent();
        }

        private async Task<IActionResult?> ForbidUnlessSelfOrManagementAsync(Guid driverId)
        {
            if (User.IsInManagementRole())
                return null;

            var driver = await _driverService.GetDriverByIdAsync(driverId);
            if (driver == null)
                return NotFound();

            return driver.KeycloakId == User.GetKeycloakId() ? null : Forbid();
        }
    }
}
