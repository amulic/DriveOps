using DriveOps.RealTime.Contracts.DTOs;

namespace DriveOps.RealTime.Contracts.Interfaces;

public interface IChatService
{
    Task<ChatMessageDto> SendMessageAsync(Guid conversationId, Guid senderUserId, string content);
    Task<ChatMessageDto> SendTripMessageAsync(Guid tripId, Guid senderUserId, string content);
    Task MarkAsReadAsync(Guid conversationId, Guid userId);
    Task CloseConversationByTripIdAsync(Guid tripId);
    Task<ConversationDto?> GetConversationAsync(Guid conversationId, Guid userId);
    Task<ConversationDto?> GetOrCreateTripConversationAsync(Guid tripId, Guid customerId, Guid driverId);
}
