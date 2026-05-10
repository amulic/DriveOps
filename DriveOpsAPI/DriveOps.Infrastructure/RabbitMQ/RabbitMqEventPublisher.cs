using System.Text;
using System.Text.Json;
using DriveOps.Application.Interfaces;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DriveOps.Infrastructure.RabbitMQ;

public class RabbitMqEventPublisher : IEventPublisher, IAsyncDisposable
{
    private readonly IConnection _connection;
    private readonly ILogger<RabbitMqEventPublisher> _logger;
    private readonly SemaphoreSlim _semaphore = new(1, 1);
    private bool _disposed;

    public RabbitMqEventPublisher(IConnection connection, ILogger<RabbitMqEventPublisher> logger)
    {
        _connection = connection;
        _logger = logger;
    }

    public async Task PublishAsync<T>(string exchange, string routingKey, T message, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            return;

        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var channel = await _connection.CreateChannelAsync(cancellationToken: cancellationToken);
            try
            {
                await channel.ExchangeDeclareAsync(exchange, ExchangeType.Topic, durable: true, cancellationToken: cancellationToken);

                var json = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(json);

                var props = new BasicProperties
                {
                    ContentType = "application/json",
                    DeliveryMode = DeliveryModes.Persistent
                };

                const int maxRetries = 3;
                for (int attempt = 1; attempt <= maxRetries; attempt++)
                {
                    try
                    {
                        await channel.BasicPublishAsync(exchange, routingKey, mandatory: false, props, body, cancellationToken);
                        _logger.LogDebug("Published {Event} to {Exchange}/{RoutingKey}", typeof(T).Name, exchange, routingKey);
                        return;
                    }
                    catch (Exception ex) when (attempt < maxRetries)
                    {
                        _logger.LogWarning(ex,
                            "Publish attempt {Attempt}/{MaxRetries} failed for {Event} on {Exchange}/{RoutingKey}",
                            attempt, maxRetries, typeof(T).Name, exchange, routingKey);
                        await Task.Delay(TimeSpan.FromMilliseconds(100 * attempt), cancellationToken);
                    }
                }
            }
            finally
            {
                await channel.CloseAsync(cancellationToken);
                await channel.DisposeAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish {Event} to {Exchange}/{RoutingKey} after retries",
                typeof(T).Name, exchange, routingKey);
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_disposed) return;
        _disposed = true;
        _semaphore.Dispose();
        await ValueTask.CompletedTask;
    }
}