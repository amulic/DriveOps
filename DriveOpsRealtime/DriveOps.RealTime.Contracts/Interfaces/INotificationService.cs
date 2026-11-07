using DriveOps.RealTime.Contracts.DTOs;

namespace DriveOps.RealTime.Contracts.Interfaces;

public interface INotificationService
{
    Task<NotificationDto> CreateAsync(
        Guid userId,
        string type,
        string title,
        string message,
        Guid? tripId,
        CancellationToken cancellationToken = default);

    Task<PagedNotificationsDto> GetForUserAsync(
        Guid userId,
        int page,
        int pageSize,
        bool unreadOnly,
        CancellationToken cancellationToken = default);

    Task<bool> MarkAsReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken = default);

    Task<int> MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken = default);
}
