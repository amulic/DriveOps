using DriveOps.RealTime.Contracts.Enums;

namespace DriveOps.RealTime.Contracts.Interfaces;

public record DriverProfileSnapshot(
    Guid DriverId,
    DriverStatus Status,
    bool IsOnline
);

/// <summary>
/// Maps an authenticated Keycloak user to their internal driver profile.
/// The Realtime service has no driver data of its own, so the mapping is
/// resolved from the API using the caller's access token.
/// </summary>
public interface IDriverProfileResolver
{
    Task<DriverProfileSnapshot?> GetByUserAsync(
        Guid userKeycloakId,
        string? accessToken,
        CancellationToken cancellationToken = default);
}
