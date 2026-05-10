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
            var userId = GetUserId();
            await _locationService.UpdateDriverLocationFromClientAsync(userId, latitude, longitude);
        }

        public async Task SubscribeToTripLocation(Guid tripId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"trip-location-{tripId}");
        }

        public async Task UnsubscribeFromTripLocation(Guid tripId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"trip-location-{tripId}");
        }

        public async Task GetNearbyDrivers(decimal latitude, decimal longitude, decimal radiusKm)
        {
            var drivers = await _locationService.GetNearbyDriversAsync(latitude, longitude, radiusKm);
            await Clients.Caller.SendAsync("NearbyDrivers", drivers);
        }

        private Guid GetUserId()
        {
            var sub = Context.User?.FindFirstValue("sub")
                ?? Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? throw new HubException("User not authenticated.");
            return Guid.Parse(sub);
        }
    }

}
