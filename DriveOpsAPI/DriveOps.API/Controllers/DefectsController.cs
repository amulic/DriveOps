using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using DriveOps.Model.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Management-side defect workflow (list/resolve/reopen).
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "admin,dispatcher")]
    public class DefectsController : ControllerBase
    {
        private readonly IVehicleService _vehicleService;

        public DefectsController(IVehicleService vehicleService)
        {
            _vehicleService = vehicleService;
        }

        [HttpGet]
        public async Task<IActionResult> GetDefects(
            [FromQuery] string? status,
            [FromQuery] DefectSeverity? severity,
            [FromQuery] Guid? vehicleId,
            [FromQuery] Guid? driverId)
        {
            var reports = await _vehicleService.GetDefectsAsync(status, severity, vehicleId, driverId);
            return Ok(reports.Select(r => r.ToResponse()));
        }

        [HttpPost("{id:guid}/resolve")]
        public async Task<IActionResult> ResolveDefect(Guid id, [FromBody] ResolveDefectRequest request)
        {
            try
            {
                var report = await _vehicleService.ResolveDefectAsync(id, request.ResolutionNotes);
                return Ok(report.ToResponse());
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id:guid}/reopen")]
        public async Task<IActionResult> ReopenDefect(Guid id)
        {
            try
            {
                var report = await _vehicleService.ReopenDefectAsync(id);
                return Ok(report.ToResponse());
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
