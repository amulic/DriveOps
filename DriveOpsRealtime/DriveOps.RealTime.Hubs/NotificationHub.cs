using System.Security.Claims;
using DriveOps.RealTime.Contracts.Enums;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace DriveOps.RealTime.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    private readonly IConnectionMappingService _connectionMapping;
    private readonly IDriverProfileResolver _driverProfileResolver;

    public NotificationHub(IConnectionMappingService connectionMapping, IDriverProfileResolver driverProfileResolver)
    {
        _connectionMapping = connectionMapping;
        _driverProfileResolver = driverProfileResolver;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();

        // Capture the access token once per connection so later hub calls can
        // forward it to the API even if GetHttpContext no longer exposes it.
        var accessToken = GetAccessToken();
        if (!string.IsNullOrWhiteSpace(accessToken))
            Context.Items["access_token"] = accessToken;

        await _connectionMapping.AddConnectionAsync(userId, Context.ConnectionId, "notifications");
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await _connectionMapping.RemoveConnectionAsync(Context.ConnectionId, "notifications");
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinAvailableDrivers(Guid driverId)
    {
        if (!Context.User?.IsInRole("driver") ?? true)
            throw new HubException("Access denied. Driver role required.");

        var userId = GetUserId();
        var accessToken = Context.Items.TryGetValue("access_token", out var stored) && stored is string token
            ? token
            : GetAccessToken();
        var profile = await _driverProfileResolver.GetByUserAsync(
            userId, accessToken, Context.ConnectionAborted);

        if (profile == null || profile.DriverId != driverId)
            throw new HubException("Access denied. Driver profile does not match the authenticated user.");

        if (profile.Status is not (DriverStatus.Active or DriverStatus.OnTrip))
            throw new HubException("Access denied. Driver profile is not active.");

        await Groups.AddToGroupAsync(Context.ConnectionId, "available-drivers");
        await Groups.AddToGroupAsync(Context.ConnectionId, $"driver-{driverId}");
    }

    public async Task LeaveAvailableDrivers(Guid driverId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "available-drivers");
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"driver-{driverId}");
    }

    public async Task JoinAdminDashboard()
    {
        if (!IsInManagementRole())
            throw new HubException("Access denied. Management role required.");

        await Groups.AddToGroupAsync(Context.ConnectionId, "admin-dashboard");
    }

    public async Task LeaveAdminDashboard()
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "admin-dashboard");
    }

    private bool IsInManagementRole() =>
        Context.User?.IsInRole("admin") == true || Context.User?.IsInRole("dispatcher") == true;

    private string? GetAccessToken()
    {
        var httpContext = Context.GetHttpContext();
        var queryToken = httpContext?.Request.Query["access_token"].ToString();
        if (!string.IsNullOrWhiteSpace(queryToken))
            return queryToken;

        var authorization = httpContext?.Request.Headers.Authorization.ToString();
        return authorization?.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) == true
            ? authorization["Bearer ".Length..]
            : null;
    }

    private Guid GetUserId()
    {
        var sub = Context.User?.FindFirstValue("sub");
        if (!string.IsNullOrEmpty(sub) && Guid.TryParse(sub, out var subGuid))
            return subGuid;

        var nameId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(nameId) && Guid.TryParse(nameId, out var nameGuid))
            return nameGuid;

        throw new HubException("User ID not found in token.");
    }
}