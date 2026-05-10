using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Models.Entities;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.RealTime.Services;

public class ChatService : IChatService
{
    private readonly RealTimeDbContext _dbContext;
    private readonly ILogger<ChatService> _logger;

    public ChatService(RealTimeDbContext dbContext, ILogger<ChatService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<ChatMessageDto> SendMessageAsync(Guid conversationId, Guid senderUserId, string content)
    {
        var conversation = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.Id == conversationId)
            ?? throw new KeyNotFoundException($"Conversation {conversationId} not found.");

        if (!conversation.IsActive)
            throw new InvalidOperationException("Cannot send messages to a closed conversation.");

        if (!conversation.Participants.Any(p => p.UserId == senderUserId))
            throw new InvalidOperationException("User is not a participant in this conversation.");

        var message = new ChatMessage
        {
            Id = Guid.NewGuid(),
            ConversationId = conversationId,
            SenderUserId = senderUserId,
            Content = content,
            SentAt = DateTime.UtcNow
        };

        _dbContext.ChatMessages.Add(message);
        conversation.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return new ChatMessageDto(message.Id, message.ConversationId, message.SenderUserId, message.Content, message.SentAt);
    }

    public async Task<ChatMessageDto> SendTripMessageAsync(Guid tripId, Guid senderUserId, string content)
    {
        var conversation = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.TripId == tripId && c.IsActive);

        if (conversation == null)
            throw new KeyNotFoundException($"No active conversation for trip {tripId}.");

        return await SendMessageAsync(conversation.Id, senderUserId, content);
    }

    public async Task MarkAsReadAsync(Guid conversationId, Guid userId)
    {
        var participant = await _dbContext.ConversationParticipants
            .FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == userId);

        if (participant != null)
        {
            participant.LastReadAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();
        }
    }

    public async Task CloseConversationByTripIdAsync(Guid tripId)
    {
        var conversation = await _dbContext.Conversations
            .FirstOrDefaultAsync(c => c.TripId == tripId && c.IsActive);

        if (conversation != null)
        {
            conversation.IsActive = false;
            conversation.UpdatedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();
            _logger.LogInformation("Closed conversation for trip {TripId}", tripId);
        }
    }

    public async Task<ConversationDto?> GetConversationAsync(Guid conversationId, Guid userId)
    {
        var conversation = await _dbContext.Conversations
            .Include(c => c.Participants)
            .Include(c => c.Messages)
            .FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation == null) return null;

        var participant = conversation.Participants.FirstOrDefault(p => p.UserId == userId);
        var unreadCount = participant?.LastReadAt != null
            ? conversation.Messages.Count(m => m.SentAt > participant.LastReadAt && m.SenderUserId != userId)
            : conversation.Messages.Count(m => m.SenderUserId != userId);

        return new ConversationDto(
            conversation.Id,
            conversation.TripId,
            conversation.IsActive,
            conversation.CreatedAt,
            conversation.UpdatedAt,
            conversation.Participants.Select(p => p.UserId),
            unreadCount);
    }

    public async Task<ConversationDto?> GetOrCreateTripConversationAsync(Guid tripId, Guid customerId, Guid driverId)
    {
        var existing = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.TripId == tripId && c.IsActive);

        if (existing != null)
        {
            return new ConversationDto(existing.Id, existing.TripId, existing.IsActive,
                existing.CreatedAt, existing.UpdatedAt,
                existing.Participants.Select(p => p.UserId), 0);
        }

        var conversation = new Conversation
        {
            Id = Guid.NewGuid(),
            TripId = tripId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        conversation.Participants = new List<ConversationParticipant>
        {
            new() { Id = Guid.NewGuid(), ConversationId = conversation.Id, UserId = customerId, JoinedAt = DateTime.UtcNow },
            new() { Id = Guid.NewGuid(), ConversationId = conversation.Id, UserId = driverId, JoinedAt = DateTime.UtcNow }
        };

        _dbContext.Conversations.Add(conversation);
        await _dbContext.SaveChangesAsync();

        _logger.LogInformation("Created trip conversation {ConversationId} for trip {TripId}", conversation.Id, tripId);
        return new ConversationDto(conversation.Id, conversation.TripId, conversation.IsActive,
            conversation.CreatedAt, conversation.UpdatedAt,
            conversation.Participants.Select(p => p.UserId), 0);
    }
}
