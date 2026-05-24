using System.Security.Claims;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace DriveOps.RealTime.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    private readonly IConnectionMappingService _connectionMapping;

    public NotificationHub(IConnectionMappingService connectionMapping)
    {
        _connectionMapping = connectionMapping;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();
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
        if (!Context.User?.IsInRole("admin") ?? true)
            throw new HubException("Access denied. Admin role required.");

        await Groups.AddToGroupAsync(Context.ConnectionId, "admin-dashboard");
    }

    public async Task LeaveAdminDashboard()
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "admin-dashboard");
    }

    private Guid GetUserId()
    {
        var sub = Context.User?.FindFirstValue("sub")
            ?? Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new HubException("User not authenticated.");
        return Guid.Parse(sub);
    }
}