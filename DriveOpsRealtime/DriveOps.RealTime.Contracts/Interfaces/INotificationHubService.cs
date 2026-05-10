using DriveOps.RealTime.Contracts.DTOs;

namespace DriveOps.RealTime.Contracts.Interfaces;

public interface INotificationHubService
{
    Task SendNewTripRequestAsync(TripRequestDto dto);
    Task SendTripAssignedAsync(Guid customerUserId, TripAssignedDto dto);
    Task SendTripStatusChangedAsync(Guid driverId, TripStatusChangedDto dto);
    Task SendTripStatusChangedToUserAsync(Guid userId, TripStatusChangedDto dto);
    Task SendSystemNotificationAsync(Guid userId, NotificationDto dto);
}
