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

    public async Task<IEnumerable<ConversationSummaryDto>> GetMyConversationsAsync(Guid userId)
    {
        var conversationIds = await _dbContext.ConversationParticipants
            .Where(p => p.UserId == userId)
            .Select(p => p.ConversationId)
            .Distinct()
            .ToListAsync();

        if (!conversationIds.Any())
            return Enumerable.Empty<ConversationSummaryDto>();

        var conversations = await _dbContext.Conversations
            .AsNoTracking()
            .Include(c => c.Participants)
            .Where(c => conversationIds.Contains(c.Id))
            .OrderByDescending(c => c.UpdatedAt)
            .ToListAsync();

        var result = new List<ConversationSummaryDto>();
        foreach (var c in conversations)
        {
            var participant = c.Participants.FirstOrDefault(p => p.UserId == userId);
            var lastMessage = await _dbContext.ChatMessages
                .Where(m => m.ConversationId == c.Id)
                .OrderByDescending(m => m.SentAt)
                .ThenByDescending(m => m.Seq)
                .Select(m => new { m.SentAt, m.SenderUserId })
                .FirstOrDefaultAsync();

            var unreadCount = 0;
            if (lastMessage != null && participant?.LastReadAt != null)
            {
                unreadCount = await _dbContext.ChatMessages
                    .CountAsync(m => m.ConversationId == c.Id && m.SentAt > participant.LastReadAt && m.SenderUserId != userId);
            }
            else if (lastMessage != null)
            {
                unreadCount = await _dbContext.ChatMessages
                    .CountAsync(m => m.ConversationId == c.Id && m.SenderUserId != userId);
            }

            result.Add(new ConversationSummaryDto(
                c.Id,
                c.TripId,
                c.TripId == null ? "direct" : "trip",
                lastMessage?.SentAt ?? c.CreatedAt,
                unreadCount,
                c.Participants.Select(p => p.UserId)
            ));
        }

        return result;
    }

    public async Task<PagedMessagesDto> GetMessagesAsync(Guid conversationId, Guid userId, int page, int pageSize)
    {
        var conversation = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation == null)
            throw new KeyNotFoundException($"Conversation {conversationId} not found.");

        if (!conversation.Participants.Any(p => p.UserId == userId))
            throw new InvalidOperationException("User is not a participant in this conversation.");

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 200);

        var totalCount = await _dbContext.ChatMessages
            .CountAsync(m => m.ConversationId == conversationId);

        // Newest-first (page 1 = most recent page). Seq is the deterministic
        // tiebreaker for messages sharing the same SentAt tick.
        var messages = await _dbContext.ChatMessages
            .Where(m => m.ConversationId == conversationId)
            .OrderByDescending(m => m.SentAt)
            .ThenByDescending(m => m.Seq)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedMessagesDto(
            totalCount,
            page,
            pageSize,
            messages.Select(m => new ChatMessageDto(m.Id, m.ConversationId, m.SenderUserId, m.Content, m.SentAt))
        );
    }

    public async Task<ConversationDto> CreateDirectConversationAsync(Guid initiatorUserId, Guid otherUserId)
    {
        var existing = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c =>
                c.TripId == null &&
                c.Participants.Any(p => p.UserId == initiatorUserId) &&
                c.Participants.Any(p => p.UserId == otherUserId));

        if (existing != null)
        {
            return await GetConversationAsync(existing.Id, initiatorUserId)
                ?? throw new InvalidOperationException("Failed to retrieve existing conversation.");
        }

        var conversation = new Conversation
        {
            Id = Guid.NewGuid(),
            TripId = null,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        conversation.Participants = new List<ConversationParticipant>
        {
            new() { Id = Guid.NewGuid(), ConversationId = conversation.Id, UserId = initiatorUserId, JoinedAt = DateTime.UtcNow },
            new() { Id = Guid.NewGuid(), ConversationId = conversation.Id, UserId = otherUserId, JoinedAt = DateTime.UtcNow }
        };

        _dbContext.Conversations.Add(conversation);
        await _dbContext.SaveChangesAsync();

        _logger.LogInformation("Created direct conversation {ConversationId} between {UserA} and {UserB}", conversation.Id, initiatorUserId, otherUserId);

        return new ConversationDto(conversation.Id, conversation.TripId, conversation.IsActive,
            conversation.CreatedAt, conversation.UpdatedAt,
            conversation.Participants.Select(p => p.UserId), 0);
    }

    public async Task<ConversationDto> JoinConversationAsync(Guid conversationId, Guid userId)
    {
        var conversation = await _dbContext.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => c.Id == conversationId);

        if (conversation == null)
            throw new KeyNotFoundException($"Conversation {conversationId} not found.");

        if (!conversation.IsActive)
            throw new InvalidOperationException("Cannot join a closed conversation.");

        if (conversation.Participants.Any(p => p.UserId == userId))
            return await GetConversationAsync(conversationId, userId)
                ?? throw new InvalidOperationException("Failed to retrieve conversation.");

        conversation.Participants.Add(new ConversationParticipant
        {
            Id = Guid.NewGuid(),
            ConversationId = conversation.Id,
            UserId = userId,
            JoinedAt = DateTime.UtcNow
        });

        conversation.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        _logger.LogInformation("User {UserId} joined conversation {ConversationId}", userId, conversationId);

        return await GetConversationAsync(conversationId, userId)
            ?? throw new InvalidOperationException("Failed to retrieve conversation after joining.");
    }

    public async Task<IEnumerable<ConversationSummaryDto>> GetActiveTripConversationsAsync()
    {
        var conversations = await _dbContext.Conversations
            .Include(c => c.Participants)
            .Include(c => c.Messages)
            .Where(c => c.TripId != null && c.IsActive)
            .OrderByDescending(c => c.UpdatedAt)
            .ToListAsync();

        return conversations.Select(c =>
        {
            var lastMessageAt = c.Messages.Any() ? c.Messages.Max(m => m.SentAt) : c.CreatedAt;

            return new ConversationSummaryDto(
                c.Id,
                c.TripId,
                "trip",
                lastMessageAt,
                0,
                c.Participants.Select(p => p.UserId)
            );
        });
    }
}
