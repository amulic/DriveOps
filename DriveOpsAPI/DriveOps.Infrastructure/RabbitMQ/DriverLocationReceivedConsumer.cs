using System.Collections.Generic;
using System.Text;
using System.Text.Json;
using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.RealTime.Contracts.Events;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace DriveOps.Infrastructure.RabbitMQ;

/// <summary>
/// Consumes DriverLocationReceivedEvent from SignalR service and persists via DriverService.
/// </summary>
public class DriverLocationReceivedConsumer : BackgroundService
{
    private readonly IConnection _connection;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<DriverLocationReceivedConsumer> _logger;
    private IChannel? _channel;

    private const string Exchange = "driveops.realtime";
    private const string Queue = "api.driver.location";
    private const string RoutingKey = "driver.location.received";

    public DriverLocationReceivedConsumer(
        IConnection connection,
        IServiceScopeFactory scopeFactory,
        ILogger<DriverLocationReceivedConsumer> logger)
    {
        _connection = connection;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _channel = await _connection.CreateChannelAsync(cancellationToken: stoppingToken);
        await _channel.ExchangeDeclareAsync(Exchange, ExchangeType.Topic, durable: true, cancellationToken: stoppingToken);
        await _channel.ExchangeDeclareAsync("driveops.dlx", ExchangeType.Topic, durable: true, cancellationToken: stoppingToken);
        await _channel.QueueDeclareAsync(Queue, durable: true, exclusive: false, autoDelete: false,
            arguments: new Dictionary<string, object?> { { "x-dead-letter-exchange", "driveops.dlx" } },
            cancellationToken: stoppingToken);
        await _channel.QueueBindAsync(Queue, Exchange, RoutingKey, cancellationToken: stoppingToken);

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                var body = Encoding.UTF8.GetString(ea.Body.Span);
                var locationEvent = JsonSerializer.Deserialize<DriverLocationReceivedEvent>(body)!;

                using var scope = _scopeFactory.CreateScope();
                var driverService = scope.ServiceProvider.GetRequiredService<IDriverService>();

                await driverService.UpdateDriverLocationAsync(new UpdateDriverLocationDto
                {
                    DriverId = locationEvent.DriverId,
                    Latitude = locationEvent.Latitude,
                    Longitude = locationEvent.Longitude
                });

                await _channel.BasicAckAsync(ea.DeliveryTag, false);
                _logger.LogDebug("Persisted location for driver {DriverId}", locationEvent.DriverId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing driver location event");
                await _channel.BasicNackAsync(ea.DeliveryTag, false, true);
            }
        };

        await _channel.BasicConsumeAsync(Queue, autoAck: false, consumer: consumer, cancellationToken: stoppingToken);
        _logger.LogInformation("DriverLocationReceivedConsumer started");

        try
        {
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException)
        {
            // Expected on shutdown
        }
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_channel != null)
        {
            await _channel.CloseAsync(cancellationToken);
            await _channel.DisposeAsync();
        }
        await base.StopAsync(cancellationToken);
    }
}
