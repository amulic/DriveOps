namespace DriveOps.RealTime.Models.Entities;

public class ChatMessage
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid SenderUserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }

    /// <summary>
    /// Database-generated monotonic sequence (auto-increment). Used as the
    /// tiebreaker for deterministic history ordering when messages share an
    /// identical <see cref="SentAt"/> tick (Windows timer granularity ~15.6 ms).
    /// </summary>
    public long Seq { get; set; }
    public Conversation Conversation { get; set; } = null!;
}
