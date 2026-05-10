using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;


namespace DriveOps.RealTime.Hubs.Services
{
        public class NotificationHubService : INotificationHubService
        {
            private readonly IHubContext<NotificationHub> _hubContext;
            private readonly ILogger<NotificationHubService> _logger;

            public NotificationHubService(IHubContext<NotificationHub> hubContext, ILogger<NotificationHubService> logger)
            {
                _hubContext = hubContext;
                _logger = logger;
            }

            public async Task SendNewTripRequestAsync(TripRequestDto dto)
            {
                await _hubContext.Clients.Group("available-drivers").SendAsync("NewTripRequest", dto);
                _logger.LogDebug("Broadcast NewTripRequest for trip {TripId}", dto.TripId);
            }

            public async Task SendTripAssignedAsync(Guid customerUserId, TripAssignedDto dto)
            {
                await _hubContext.Clients.Group($"user-{customerUserId}").SendAsync("TripAssigned", dto);
                _logger.LogDebug("Sent TripAssigned to customer {CustomerId}", customerUserId);
            }

            public async Task SendTripStatusChangedAsync(Guid driverId, TripStatusChangedDto dto)
            {
                await _hubContext.Clients.Group($"driver-{driverId}").SendAsync("TripStatusChanged", dto);
                _logger.LogDebug("Sent TripStatusChanged to driver {DriverId}", driverId);
            }

            public async Task SendTripStatusChangedToUserAsync(Guid userId, TripStatusChangedDto dto)
            {
                await _hubContext.Clients.Group($"user-{userId}").SendAsync("TripStatusChanged", dto);
                _logger.LogDebug("Sent TripStatusChanged to user {UserId}", userId);
            }

            public async Task SendSystemNotificationAsync(Guid userId, NotificationDto dto)
            {
                await _hubContext.Clients.Group($"user-{userId}").SendAsync("SystemNotification", dto);
            }
        }
}
