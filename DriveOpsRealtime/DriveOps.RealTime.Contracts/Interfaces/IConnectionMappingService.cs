namespace DriveOps.RealTime.Contracts.Interfaces;

public interface IConnectionMappingService
{
    Task AddConnectionAsync(Guid userId, string connectionId, string hubName);
    Task RemoveConnectionAsync(string connectionId, string hubName);
}
