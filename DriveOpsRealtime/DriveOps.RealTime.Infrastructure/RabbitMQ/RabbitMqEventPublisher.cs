using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DriveOps.RealTime.Infrastructure.RabbitMQ;

public class RabbitMqEventPublisher : IEventPublisher
{
    private readonly IConnection _connection;
    private readonly ILogger<RabbitMqEventPublisher> _logger;
    private readonly ConcurrentBag<IChannel> _channelPool = new();
    private readonly SemaphoreSlim _semaphore = new(1, 1);
    private readonly int _poolSize;

    public RabbitMqEventPublisher(IConnection connection, ILogger<RabbitMqEventPublisher> logger, int poolSize = 5)
    {
        _connection = connection;
        _logger = logger;
        _poolSize = poolSize;
    }

    private async Task<IChannel> GetChannelAsync(CancellationToken ct)
    {
        if (_channelPool.TryTake(out var channel))
            return channel;

        return await _connection.CreateChannelAsync(cancellationToken: ct);
    }

    private void ReturnChannel(IChannel channel)
    {
        if (_channelPool.Count < _poolSize)
            _channelPool.Add(channel);
        else
        {
            channel.CloseAsync().AsTask().GetAwaiter().GetResult();
            channel.DisposeAsync().AsTask().GetAwaiter().GetResult();
        }
    }

    public async Task PublishAsync<T>(string exchange, string routingKey, T message)
    {
        IChannel? channel = null;
        try
        {
            await _semaphore.WaitAsync();
            channel = await GetChannelAsync(CancellationToken.None);
            await channel.ExchangeDeclareAsync(exchange, ExchangeType.Topic, durable: true);

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
            var props = new BasicProperties
            {
                ContentType = "application/json",
                Persistent = true
            };

            await channel.BasicPublishAsync(exchange, routingKey, mandatory: false, basicProperties: props, body: body);
            _logger.LogDebug("Published to {Exchange}/{RoutingKey}", exchange, routingKey);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish to {Exchange}/{RoutingKey}", exchange, routingKey);
        }
        finally
        {
            if (channel != null)
                ReturnChannel(channel);
            _semaphore.Release();
        }
    }
}