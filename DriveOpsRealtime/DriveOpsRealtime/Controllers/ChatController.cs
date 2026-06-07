using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace DriveOpsRealtime.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(IChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    [HttpGet("conversations")]
    public async Task<IActionResult> GetMyConversations()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            _logger.LogInformation("GetMyConversations called for user {UserId}", userId);
            var conversations = await _chatService.GetMyConversationsAsync(userId.Value);
            return Ok(conversations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetMyConversations: {Message}", ex.Message);
            return StatusCode(500, "An error occurred while retrieving conversations.");
        }
    }

    [HttpGet("conversations/{id:guid}")]
    public async Task<IActionResult> GetConversation(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var conversation = await _chatService.GetConversationAsync(id, userId.Value);
            if (conversation == null) return NotFound();
            return Ok(conversation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving conversation {ConversationId}: {Message}", id, ex.Message);
            return StatusCode(500, "An error occurred while retrieving the conversation.");
        }
    }

    [HttpGet("conversations/{id:guid}/messages")]
    public async Task<IActionResult> GetMessages(Guid id, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var messages = await _chatService.GetMessagesAsync(id, userId.Value, page, pageSize);
            return Ok(messages);
        }
        catch (KeyNotFoundException) { return NotFound(); }
        catch (InvalidOperationException ex) { return Forbid(ex.Message); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving messages for conversation {ConversationId}: {Message}", id, ex.Message);
            return StatusCode(500, "An error occurred while retrieving messages.");
        }
    }

    [HttpPost("conversations")]
    public async Task<IActionResult> CreateDirectConversation([FromBody] CreateDirectConversationRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var conversation = await _chatService.CreateDirectConversationAsync(userId.Value, request.OtherUserId);
            return Ok(conversation);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation creating direct conversation: {Message}", ex.Message);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create direct conversation for user {UserId}", userId);
            return StatusCode(500, "An error occurred while creating the conversation.");
        }
    }

    [HttpPost("conversations/{id:guid}/join")]
    public async Task<IActionResult> JoinConversation(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        try
        {
            var conversation = await _chatService.JoinConversationAsync(id, userId.Value);
            return Ok(conversation);
        }
        catch (KeyNotFoundException) { return NotFound(); }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error joining conversation {ConversationId}: {Message}", id, ex.Message);
            return StatusCode(500, "An error occurred while joining the conversation.");
        }
    }

    [HttpGet("trip-conversations")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetActiveTripConversations()
    {
        try
        {
            var conversations = await _chatService.GetActiveTripConversationsAsync();
            return Ok(conversations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving active trip conversations: {Message}", ex.Message);
            return StatusCode(500, "An error occurred while retrieving trip conversations.");
        }
    }

    [AllowAnonymous]
    [HttpGet("debug")]
    public IActionResult Debug()
    {
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Ok(new { isAuth = User.Identity?.IsAuthenticated ?? false, claims });
    }

    [HttpGet("whoami")]
    public IActionResult WhoAmI()
    {
        var userId = GetUserId();
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Ok(new
        {
            userId = userId?.ToString(),
            isAuth = User.Identity?.IsAuthenticated ?? false,
            claims
        });
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