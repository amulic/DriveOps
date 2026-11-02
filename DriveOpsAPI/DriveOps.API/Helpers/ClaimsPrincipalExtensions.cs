using System.Security.Claims;

namespace DriveOps.API.Helpers
{
    public static class ClaimsPrincipalExtensions
    {
        /// <summary>Keycloak user id from the JWT <c>sub</c> claim.</summary>
        public static Guid? GetKeycloakId(this ClaimsPrincipal user)
        {
            var sub = user.FindFirst("sub")?.Value;
            return Guid.TryParse(sub, out var id) ? id : null;
        }

        /// <summary>True for the management roles (admin or dispatcher).</summary>
        public static bool IsInManagementRole(this ClaimsPrincipal user) =>
            user.IsInRole("admin") || user.IsInRole("dispatcher");
    }
}
