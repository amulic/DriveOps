using DriveOps.API.ControllerDtos.Request;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
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
            var keycloakId = User.Claims.First(c => c.Type == "sub")?.Value;
            var email = User.Claims.First(c => c.Type == "email")?.Value;
            var firstName = User.Claims.First(c => c.Type == "given_name")?.Value;
            var lastName = User.Claims.First(c => c.Type == "family_name")?.Value;

            if(string.IsNullOrEmpty(keycloakId) || string.IsNullOrEmpty(email))
                return BadRequest("Invalid user claims.");

            var user = await _userService.CreateOrUpdateUserAsync(keycloakId);

            await _userService.UpdateLastLoginAsync(user.Id);

            return Ok(new
            {
                user.Id,
                user.KeycloakId,
                user.Email,
                user.FirstName,
                user.LastName,
                user.UserType,
                user.IsActive,
                Message = "User synced successfully"
            });
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUser()
        {
            var keycloakId = User.Claims.First(c => c.Type == "sub")?.Value;

            if (string.IsNullOrEmpty(keycloakId))
                return Unauthorized("No user claims.");

            var user = await _userService.GetUserByKeycloakIdAsync(keycloakId);

            if (user == null)
                return NotFound("User not found.");

            return Ok(new
            {
                user.Id,
                user.KeycloakId,
                user.Email,
                user.FirstName,
                user.LastName,
                user.UserType,
                user.IsActive
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetUserById([FromQuery] Guid uuid)
        {
            return Ok(_userService.GetUserByDbIdAsync(uuid));
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] UserRequestDto userRequest)
        {
            var newUser = await _userService.CreateUserAsync(userRequest);
            return Ok(newUser);
        }   

        [HttpPut]
        public async Task<IActionResult> UpdateProfile([FromBody] UserRequestDto userRequest)
        {
            var updatedUser = await _userService.UpdateUserAsync(user);
            return Ok(updatedUser);
        }
    }
}
