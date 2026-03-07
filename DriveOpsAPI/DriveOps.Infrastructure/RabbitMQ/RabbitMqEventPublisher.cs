using System.Text;
using System.Text.Json;
using DriveOps.Application.Interfaces;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DriveOps.Infrastructure.RabbitMQ;

public class RabbitMqEventPublisher : IEventPublisher, IAsyncDisposable
{
    private readonly IConnection _connection;
    private readonly IChannel _channel;
    private readonly ILogger<RabbitMqEventPublisher> _logger;

    public RabbitMqEventPublisher(IConnection connection, ILogger<RabbitMqEventPublisher> logger)
    {
        _connection = connection;
        _channel = _connection.CreateChannelAsync().GetAwaiter().GetResult();
        _logger = logger;
    }

    public async Task PublishAsync<T>(string exchange, string routingKey, T message, CancellationToken cancellationToken = default)
    {
        try
        {
            await _channel.ExchangeDeclareAsync(exchange, ExchangeType.Topic, durable: true, cancellationToken: cancellationToken);

            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            var props = new BasicProperties
            {
                ContentType = "application/json",
                DeliveryMode = DeliveryModes.Persistent
            };

            await _channel.BasicPublishAsync(exchange, routingKey, mandatory: false, props, body, cancellationToken);
            _logger.LogDebug("Published {Event} to {Exchange}/{RoutingKey}", typeof(T).Name, exchange, routingKey);
        }
        catch (Exception ex)
        {
            // Fire-and-forget: if RabbitMQ is down, log warning but don't break the API operation
            _logger.LogWarning(ex, "Failed to publish {Event} to {Exchange}/{RoutingKey}", typeof(T).Name, exchange, routingKey);
        }
    }

    public async ValueTask DisposeAsync()
    {
        await _channel.CloseAsync();
        await _channel.DisposeAsync();
    }
}
