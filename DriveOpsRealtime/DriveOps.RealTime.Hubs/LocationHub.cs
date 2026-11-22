using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace DriveOps.RealTime.Hubs
{

    [Authorize]
    public class LocationHub : Hub
    {
        private readonly IConnectionMappingService _connectionMapping;
        private readonly ILocationService _locationService;

        public LocationHub(IConnectionMappingService connectionMapping, ILocationService locationService)
        {
            _connectionMapping = connectionMapping;
            _locationService = locationService;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            await _connectionMapping.AddConnectionAsync(userId, Context.ConnectionId, "location");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            await _connectionMapping.RemoveConnectionAsync(Context.ConnectionId, "location");
            await base.OnDisconnectedAsync(exception);
        }

        public async Task SendDriverLocation(decimal latitude, decimal longitude)
        {
            if (!Context.User?.IsInRole("driver") ?? true)
                throw new HubException("Access denied. Driver role required.");

            var userId = GetUserId();
            await _locationService.UpdateDriverLocationFromClientAsync(userId, latitude, longitude);
        }

        public async Task SubscribeToTripLocation(Guid tripId)
        {
            var userId = GetUserId();
            var isStaff = IsInManagementRole();
            if (!isStaff && !await _locationService.CanAccessTripLocationAsync(tripId, userId))
                throw new HubException("Access denied. You are not a participant in this trip.");

            await Groups.AddToGroupAsync(Context.ConnectionId, $"trip-location-{tripId}");
        }

        public async Task UnsubscribeFromTripLocation(Guid tripId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"trip-location-{tripId}");
        }

        public async Task GetNearbyDrivers(decimal latitude, decimal longitude, decimal radiusKm)
        {
            if (!IsInManagementRole())
                throw new HubException("Access denied. Management role required.");

            var drivers = await _locationService.GetNearbyDriversAsync(latitude, longitude, radiusKm);
            await Clients.Caller.SendAsync("NearbyDrivers", drivers);
        }

        private bool IsInManagementRole() =>
            Context.User?.IsInRole("admin") == true || Context.User?.IsInRole("dispatcher") == true;

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

}
