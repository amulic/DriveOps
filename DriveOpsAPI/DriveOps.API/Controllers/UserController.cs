using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        public UserController() { }

        [HttpGet("me")]
        public IActionResult GetCurrentUser()
        {
            var keycloakId = GetClaimValue("sub")
                ?? GetClaimValue(ClaimTypes.NameIdentifier)
                ?? GetClaimValue("preferred_username");

            if (string.IsNullOrEmpty(keycloakId))
                return Unauthorized("No user claims.");

            var email = GetClaimValue("email") ?? GetClaimValue(ClaimTypes.Email);
            var firstName = GetClaimValue("given_name") ?? "";
            var lastName = GetClaimValue("family_name") ?? "";
            var username = GetClaimValue("preferred_username") ?? "";

            var roles = User.Claims
                .Where(c => c.Type == ClaimTypes.Role || c.Type == "role" || c.Type == "roles")
                .Select(c => c.Value)
                .Distinct()
                .ToList();

            var realmRoles = new List<string>();
            var realmAccessJson = GetClaimValue("realm_access");
            if (!string.IsNullOrEmpty(realmAccessJson))
            {
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(realmAccessJson);
                    if (doc.RootElement.TryGetProperty("roles", out var r) && r.ValueKind == System.Text.Json.JsonValueKind.Array)
                    {
                        foreach (var role in r.EnumerateArray())
                        {
                            var roleStr = role.GetString();
                            if (!string.IsNullOrEmpty(roleStr))
                                realmRoles.Add(roleStr);
                        }
                    }
                }
                catch { }
            }

            return Ok(new
            {
                keycloakId,
                email,
                firstName,
                lastName,
                username,
                roles = roles.Any() ? roles : realmRoles
            });
        }

        private string? GetClaimValue(string claimType)
            => User.Claims.FirstOrDefault(c => c.Type == claimType)?.Value;
    }
}
