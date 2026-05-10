namespace DriveOps.RealTime.Infrastructure.RabbitMQ;

public interface IEventPublisher
{
    Task PublishAsync<T>(string exchange, string routingKey, T message);
}
