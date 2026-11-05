using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Interfaces;
using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Models.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.RealTime.Services;

public class NotificationService : INotificationService
{
    private readonly RealTimeDbContext _dbContext;
    private readonly INotificationHubService _notificationHub;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        RealTimeDbContext dbContext,
        INotificationHubService notificationHub,
        ILogger<NotificationService> logger)
    {
        _dbContext = dbContext;
        _notificationHub = notificationHub;
        _logger = logger;
    }

    public async Task<NotificationDto> CreateAsync(
        Guid userId,
        string type,
        string title,
        string message,
        Guid? tripId,
        CancellationToken cancellationToken = default)
    {
        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = type,
            Title = title,
            Message = message,
            TripId = tripId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Notifications.Add(notification);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var dto = ToDto(notification);

        // The notification is already persisted: a push failure must never lose
        // the row (clients recover it from REST on next open/refresh).
        try
        {
            await _notificationHub.SendSystemNotificationAsync(userId, dto);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to push notification {NotificationId} to user {UserId}", notification.Id, userId);
        }

        return dto;
    }

    public async Task<PagedNotificationsDto> GetForUserAsync(
        Guid userId,
        int page,
        int pageSize,
        bool unreadOnly,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _dbContext.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId);

        var totalCount = await query.CountAsync(cancellationToken);
        var unreadCount = await query.CountAsync(n => !n.IsRead, cancellationToken);

        if (unreadOnly)
            query = query.Where(n => !n.IsRead);

        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedNotificationsDto(
            totalCount,
            unreadCount,
            page,
            pageSize,
            notifications.Select(ToDto));
    }

    public async Task<bool> MarkAsReadAsync(Guid userId, Guid notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await _dbContext.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId, cancellationToken);

        if (notification == null)
            return false;

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return true;
    }

    public async Task<int> MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var unread = await _dbContext.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync(cancellationToken);

        if (unread.Count == 0)
            return 0;

        var now = DateTime.UtcNow;
        foreach (var notification in unread)
        {
            notification.IsRead = true;
            notification.ReadAt = now;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        return unread.Count;
    }

    private static NotificationDto ToDto(Notification notification) =>
        new(
            notification.Id,
            notification.Type,
            notification.Title,
            notification.Message,
            notification.TripId,
            notification.IsRead,
            // Values are stored as UTC; MySQL reads them back with an
            // Unspecified kind, so mark them UTC for correct "Z" JSON output.
            DateTime.SpecifyKind(notification.CreatedAt, DateTimeKind.Utc));
}
