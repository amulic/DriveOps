using System.Text;
using System.Text.Json;
using DriveOps.RealTime.Contracts.Events;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace DriveOps.RealTime.Infrastructure.RabbitMQ;

public class LocationEventConsumer : BackgroundService
{
    private readonly IConnection _connection;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<LocationEventConsumer> _logger;
    private IChannel? _channel;

    private const string Exchange = "driveops.location";

    public LocationEventConsumer(
        IConnection connection,
        IServiceScopeFactory scopeFactory,
        ILogger<LocationEventConsumer> logger)
    {
        _connection = connection;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
        await _channel.ExchangeDeclareAsync(Exchange, ExchangeType.Topic, durable: true, cancellationToken: stoppingToken);

        var queues = new Dictionary<string, string>
        {
            { "realtime.driver.location", "driver.location" },
            { "realtime.driver.availability", "driver.availability" },
            { "realtime.trip.route", "trip.route.updated" }
        };

        foreach (var (queue, routingKey) in queues)
        {
            await _channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false, cancellationToken: stoppingToken);
            await _channel.QueueBindAsync(queue, Exchange, routingKey, cancellationToken: stoppingToken);
        }

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                var body = Encoding.UTF8.GetString(ea.Body.Span);

                using var scope = _scopeFactory.CreateScope();
                var locationService = scope.ServiceProvider.GetRequiredService<ILocationService>();

                switch (ea.RoutingKey)
                {
                    case "driver.location":
                        await locationService.HandleDriverLocationUpdatedAsync(
                            JsonSerializer.Deserialize<DriverLocationUpdatedEvent>(body)!);
                        break;

                    case "driver.availability":
                        await locationService.HandleDriverAvailabilityChangedAsync(
                            JsonSerializer.Deserialize<DriverAvailabilityChangedEvent>(body)!);
                        break;

                    case "trip.route.updated":
                        await locationService.HandleTripRouteUpdatedAsync(
                            JsonSerializer.Deserialize<TripRouteUpdatedEvent>(body)!);
                        break;
                }

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing location event on route {RoutingKey}", ea.RoutingKey);
                await _channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: false, cancellationToken: stoppingToken);
            }
        };

        foreach (var (queue, _) in queues)
            await _channel.BasicConsumeAsync(queue, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);

        await Task.Delay(Timeout.Infinite, stoppingToken);
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await base.StopAsync(cancellationToken);
        if (_channel != null)
            await _channel.DisposeAsync();
    }
}
