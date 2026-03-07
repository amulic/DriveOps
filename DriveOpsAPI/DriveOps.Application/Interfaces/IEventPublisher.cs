namespace DriveOps.Application.Interfaces;

public interface IEventPublisher
{
    Task PublishAsync<T>(string exchange, string routingKey, T message, CancellationToken cancellationToken = default);
}
