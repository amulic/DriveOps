using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.ControllerDtos.Response;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;

        public UserController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("sync")]
        public async Task<IActionResult> SyncUser()
        {
            var keycloakId = User.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;
            var email = User.Claims.FirstOrDefault(c => c.Type == "email")?.Value;
            var firstName = User.Claims.FirstOrDefault(c => c.Type == "given_name")?.Value ?? "";
            var lastName = User.Claims.FirstOrDefault(c => c.Type == "family_name")?.Value ?? "";

            if (string.IsNullOrEmpty(keycloakId) || string.IsNullOrEmpty(email))
                return BadRequest("Invalid user claims.");

            var user = await _userService.CreateOrUpdateFromKeycloakAsync(keycloakId, email, firstName, lastName);
            await _userService.UpdateLastLoginAsync(user.Id);

            return Ok(user.ToResponse());
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var keycloakId = User.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;

            if (string.IsNullOrEmpty(keycloakId))
                return Unauthorized("No user claims.");

            var user = await _userService.GetUserByKeycloakIdAsync(keycloakId);
            if (user == null)
                return NotFound("User not found.");

            return Ok(user.ToResponse());
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetUserById(Guid id)
        {
            var user = await _userService.GetUserByIdAsync(id);
            if (user == null)
                return NotFound();

            return Ok(user.ToResponse());
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            try
            {
                var user = await _userService.CreateUserAsync(request.ToApplicationDto());
                return CreatedAtAction(nameof(GetUserById), new { id = user.Id }, user.ToResponse());
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(ex.Message);
            }
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest request)
        {
            var user = await _userService.UpdateUserAsync(request.ToApplicationDto(id));
            return Ok(user.ToResponse());
        }
    }
}
