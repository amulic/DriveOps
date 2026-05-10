namespace DriveOps.RealTime.Models.Entities;

public class ChatMessage
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid SenderUserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public Conversation Conversation { get; set; } = null!;
}
