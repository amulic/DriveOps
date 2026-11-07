using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace DriveOpsRealtime.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ILogger<NotificationsController> _logger;

    public NotificationsController(INotificationService notificationService, ILogger<NotificationsController> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] bool unreadOnly = false)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var notifications = await _notificationService.GetForUserAsync(userId.Value, page, pageSize, unreadOnly);
            return Ok(notifications);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving notifications for user {UserId}: {Message}", userId, ex.Message);
            return StatusCode(500, "An error occurred while retrieving notifications.");
        }
    }

    [HttpPost("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var marked = await _notificationService.MarkAsReadAsync(userId.Value, id);
            return marked ? NoContent() : NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking notification {NotificationId} as read: {Message}", id, ex.Message);
            return StatusCode(500, "An error occurred while updating the notification.");
        }
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            await _notificationService.MarkAllAsReadAsync(userId.Value);
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking all notifications as read for user {UserId}: {Message}", userId, ex.Message);
            return StatusCode(500, "An error occurred while updating notifications.");
        }
    }

    private Guid? GetUserId()
    {
        var sub = User.FindFirstValue("sub");
        if (!string.IsNullOrEmpty(sub))
        {
            if (Guid.TryParse(sub, out var guid))
                return guid;
            _logger.LogWarning("'sub' claim is not a valid GUID: {Sub}", sub);
        }

        var nameId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(nameId) && Guid.TryParse(nameId, out var nameGuid))
            return nameGuid;

        _logger.LogError("Unable to extract user ID from claims. Available claims: {Claims}",
            string.Join(", ", User.Claims.Select(c => $"{c.Type}={c.Value}")));
        return null;
    }
}
