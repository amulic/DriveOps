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
        try
        {
            var userId = GetUserId();
            _logger.LogInformation("GetMyConversations called for user {UserId}", userId);
            var conversations = await _chatService.GetMyConversationsAsync(userId);
            return Ok(conversations);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetMyConversations: {Message}", ex.Message);
            throw;
        }
    }

    [HttpGet("conversations/{id:guid}")]
    public async Task<IActionResult> GetConversation(Guid id)
    {
        var userId = GetUserId();
        var conversation = await _chatService.GetConversationAsync(id, userId);
        if (conversation == null) return NotFound();
        return Ok(conversation);
    }

    [HttpGet("conversations/{id:guid}/messages")]
    public async Task<IActionResult> GetMessages(Guid id, [FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var userId = GetUserId();
        try
        {
            var messages = await _chatService.GetMessagesAsync(id, userId, page, pageSize);
            return Ok(messages);
        }
        catch (KeyNotFoundException) { return NotFound(); }
        catch (InvalidOperationException ex) { return Forbid(ex.Message); }
    }

    [HttpPost("conversations")]
    public async Task<IActionResult> CreateDirectConversation([FromBody] CreateDirectConversationRequest request)
    {
        var userId = GetUserId();
        try
        {
            var conversation = await _chatService.CreateDirectConversationAsync(userId, request.OtherUserId);
            return Ok(conversation);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create direct conversation");
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("conversations/{id:guid}/join")]
    public async Task<IActionResult> JoinConversation(Guid id)
    {
        var userId = GetUserId();
        try
        {
            var conversation = await _chatService.JoinConversationAsync(id, userId);
            return Ok(conversation);
        }
        catch (KeyNotFoundException) { return NotFound(); }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
    }

    [HttpGet("trip-conversations")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetActiveTripConversations()
    {
        var conversations = await _chatService.GetActiveTripConversationsAsync();
        return Ok(conversations);
    }

    [AllowAnonymous]
    [HttpGet("debug")]
    public IActionResult Debug()
    {
        var claims = User.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Ok(new { isAuth = User.Identity?.IsAuthenticated ?? false, claims });
    }

    private Guid GetUserId()
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
        throw new UnauthorizedAccessException("User ID not found in token.");
    }
}