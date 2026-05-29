using System.Text;
using System.Text.Json;
using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Events;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace DriveOps.RealTime.Infrastructure.RabbitMQ;

public class FleetEventConsumer : BackgroundService
{
    private readonly IConnection _connection;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<FleetEventConsumer> _logger;
    private IChannel? _channel;

    private const string Exchange = "driveops.fleet";

    public FleetEventConsumer(
        IConnection connection,
        IServiceScopeFactory scopeFactory,
        ILogger<FleetEventConsumer> logger)
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

        var queues = new Dictionary<string, string>
        {
            { "realtime.fleet.vehicle.assigned", "vehicle.assigned" },
            { "realtime.fleet.vehicle.unassigned", "vehicle.unassigned" },
            { "realtime.fleet.driver.status.changed", "driver.status.changed" },
            { "realtime.fleet.vehicle.status.changed", "vehicle.status.changed" }
        };

        foreach (var (queue, routingKey) in queues)
        {
            await _channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false,
                arguments: new Dictionary<string, object?>
                {
                    { "x-dead-letter-exchange", "driveops.dlx" }
                },
                cancellationToken: stoppingToken);
            await _channel.QueueBindAsync(queue, Exchange, routingKey, cancellationToken: stoppingToken);
        }

        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                var body = Encoding.UTF8.GetString(ea.Body.Span);

                using var scope = _scopeFactory.CreateScope();
                var notifications = scope.ServiceProvider.GetRequiredService<INotificationHubService>();

                switch (ea.RoutingKey)
                {
                    case "vehicle.assigned":
                        var assigned = JsonSerializer.Deserialize<VehicleAssignedEvent>(body)!;
                        await notifications.SendFleetUpdateAsync(new FleetUpdateDto(
                            "VehicleAssigned",
                            JsonSerializer.Serialize(assigned),
                            assigned.AssignedAt));
                        break;

                    case "vehicle.unassigned":
                        var unassigned = JsonSerializer.Deserialize<VehicleUnassignedEvent>(body)!;
                        await notifications.SendFleetUpdateAsync(new FleetUpdateDto(
                            "VehicleUnassigned",
                            JsonSerializer.Serialize(unassigned),
                            unassigned.UnassignedAt));
                        break;

                    case "driver.status.changed":
                        var driverStatus = JsonSerializer.Deserialize<DriverStatusChangedEvent>(body)!;
                        await notifications.SendFleetUpdateAsync(new FleetUpdateDto(
                            "DriverStatusChanged",
                            JsonSerializer.Serialize(driverStatus),
                            driverStatus.ChangedAt));
                        break;

                    case "vehicle.status.changed":
                        var vehicleStatus = JsonSerializer.Deserialize<VehicleStatusChangedEvent>(body)!;
                        await notifications.SendFleetUpdateAsync(new FleetUpdateDto(
                            "VehicleStatusChanged",
                            JsonSerializer.Serialize(vehicleStatus),
                            vehicleStatus.ChangedAt));
                        break;
                }

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing fleet event on route {RoutingKey}", ea.RoutingKey);
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
