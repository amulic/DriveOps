using DriveOps.API.Helpers;
using DriveOps.Application.DTOs;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Interfaces;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Admin-only account and role management (Keycloak-backed). Dispatchers are
    /// deliberately excluded: this is an administrative surface, not daily ops.
    /// </summary>
    [ApiController]
    [Route("api/admin/accounts")]
    [Authorize(Roles = "admin")]
    public class AdminAccountsController : ControllerBase
    {
        private readonly IAccountAdminService _accounts;
        private readonly IValidator<CreateAccountDto> _createValidator;
        private readonly IValidator<UpdateAccountDto> _updateValidator;
        private readonly IValidator<SetAccountRolesDto> _rolesValidator;
        private readonly IValidator<ResetAccountPasswordDto> _passwordValidator;

        public AdminAccountsController(
            IAccountAdminService accounts,
            IValidator<CreateAccountDto> createValidator,
            IValidator<UpdateAccountDto> updateValidator,
            IValidator<SetAccountRolesDto> rolesValidator,
            IValidator<ResetAccountPasswordDto> passwordValidator)
        {
            _accounts = accounts;
            _createValidator = createValidator;
            _updateValidator = updateValidator;
            _rolesValidator = rolesValidator;
            _passwordValidator = passwordValidator;
        }

        [HttpGet]
        public async Task<IActionResult> GetAccounts(
            [FromQuery] string? search,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 25)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 50);

            try
            {
                var accounts = await _accounts.GetAccountsAsync(search, (page - 1) * pageSize, pageSize);
                return Ok(accounts);
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateAccount([FromBody] CreateAccountDto dto)
        {
            await _createValidator.ValidateAndThrowAsync(dto);

            try
            {
                return Ok(await _accounts.CreateAccountAsync(dto));
            }
            catch (KeycloakUserConflictException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAccount(string id, [FromBody] UpdateAccountDto dto)
        {
            await _updateValidator.ValidateAndThrowAsync(dto);

            if (IsSelf(id) && dto.Enabled == false)
                return BadRequest(new { message = "You cannot disable your own account." });

            try
            {
                return Ok(await _accounts.UpdateAccountAsync(id, dto));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPut("{id}/roles")]
        public async Task<IActionResult> SetRoles(string id, [FromBody] SetAccountRolesDto dto)
        {
            await _rolesValidator.ValidateAndThrowAsync(dto);

            var normalized = dto.Roles.Select(r => r.ToLowerInvariant()).ToHashSet();
            if (IsSelf(id) && !normalized.Contains("admin"))
                return BadRequest(new { message = "You cannot remove your own admin role." });

            try
            {
                return Ok(await _accounts.SetRolesAsync(id, dto.Roles));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        [HttpPost("{id}/reset-password")]
        public async Task<IActionResult> ResetPassword(string id, [FromBody] ResetAccountPasswordDto dto)
        {
            await _passwordValidator.ValidateAndThrowAsync(dto);

            try
            {
                await _accounts.ResetPasswordAsync(id, dto.TemporaryPassword);
                return NoContent();
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex) when (IsKeycloakFailure(ex))
            {
                return KeycloakError(ex);
            }
        }

        private bool IsSelf(string accountId) =>
            string.Equals(accountId, User.GetKeycloakId()?.ToString(), StringComparison.OrdinalIgnoreCase);

        private static bool IsKeycloakFailure(Exception ex) =>
            ex is InvalidOperationException or HttpRequestException or TaskCanceledException;

        private IActionResult KeycloakError(Exception ex) =>
            StatusCode(502, new { message = $"Keycloak admin service error: {ex.Message}" });
    }
}
