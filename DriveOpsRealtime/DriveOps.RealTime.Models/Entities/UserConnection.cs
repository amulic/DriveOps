namespace DriveOps.RealTime.Models.Entities;

public class UserConnection
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ConnectionId { get; set; } = string.Empty;
    public string HubName { get; set; } = string.Empty;
    public DateTime ConnectedAt { get; set; }
}
