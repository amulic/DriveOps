using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Models.Entities;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.RealTime.Services;

public class ConnectionMappingService : IConnectionMappingService
{
    private readonly RealTimeDbContext _dbContext;
    private readonly ILogger<ConnectionMappingService> _logger;

    public ConnectionMappingService(RealTimeDbContext dbContext, ILogger<ConnectionMappingService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task AddConnectionAsync(Guid userId, string connectionId, string hubName)
    {
        var connection = new UserConnection
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ConnectionId = connectionId,
            HubName = hubName,
            ConnectedAt = DateTime.UtcNow
        };

        _dbContext.UserConnections.Add(connection);
        await _dbContext.SaveChangesAsync();
        _logger.LogDebug("Added connection {ConnectionId} for user {UserId} on {HubName}", connectionId, userId, hubName);
    }

    public async Task RemoveConnectionAsync(string connectionId, string hubName)
    {
        var connection = await _dbContext.UserConnections
            .FirstOrDefaultAsync(c => c.ConnectionId == connectionId && c.HubName == hubName);

        if (connection != null)
        {
            _dbContext.UserConnections.Remove(connection);
            await _dbContext.SaveChangesAsync();
            _logger.LogDebug("Removed connection {ConnectionId} from {HubName}", connectionId, hubName);
        }
    }
}
