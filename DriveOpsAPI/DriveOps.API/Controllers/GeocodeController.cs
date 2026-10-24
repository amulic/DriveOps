using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GeocodeController : ControllerBase
    {
        private readonly IGeocodingService _geocodingService;

        public GeocodeController(IGeocodingService geocodingService)
        {
            _geocodingService = geocodingService;
        }

        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] string? q, [FromQuery] int limit = 5)
        {
            if (string.IsNullOrWhiteSpace(q))
                return BadRequest(new { message = "Query parameter 'q' is required." });

            try
            {
                var results = await _geocodingService.SearchAsync(q, Math.Clamp(limit, 1, 10));
                return Ok(results);
            }
            catch (HttpRequestException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }

        [HttpGet("reverse")]
        public async Task<IActionResult> Reverse([FromQuery] decimal lat, [FromQuery] decimal lng)
        {
            try
            {
                var displayName = await _geocodingService.ReverseAsync(lat, lng);
                if (displayName == null)
                    return NotFound(new { message = "No address found for the given coordinates." });

                return Ok(new { displayName });
            }
            catch (HttpRequestException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }
    }
}
