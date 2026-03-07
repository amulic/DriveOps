using System.Text;
using System.Text.Json;
using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Enums;
using DriveOps.RealTime.Contracts.Events;
using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace DriveOps.RealTime.Infrastructure.RabbitMQ;

public class TripEventConsumer : BackgroundService
{
    private readonly IConnection _connection;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<TripEventConsumer> _logger;
    private IChannel? _channel;

    private const string Exchange = "driveops.trips";

    public TripEventConsumer(
        IConnection connection,
        IServiceScopeFactory scopeFactory,
        ILogger<TripEventConsumer> logger)
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
            { "realtime.trip.requested", "trip.requested" },
            { "realtime.trip.assigned", "trip.assigned" },
            { "realtime.trip.started", "trip.started" },
            { "realtime.trip.completed", "trip.completed" },
            { "realtime.trip.cancelled", "trip.cancelled" }
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
                var notifications = scope.ServiceProvider.GetRequiredService<INotificationHubService>();
                var chat = scope.ServiceProvider.GetRequiredService<IChatService>();

                switch (ea.RoutingKey)
                {
                    case "trip.requested":
                        var requested = JsonSerializer.Deserialize<TripRequestedEvent>(body)!;
                        await notifications.SendNewTripRequestAsync(new TripRequestDto(
                            requested.TripId, requested.CustomerId, requested.TripType,
                            requested.PickupLatitude, requested.PickupLongitude, requested.PickupAddress,
                            requested.DropoffLatitude, requested.DropoffLongitude, requested.DropoffAddress,
                            requested.EstimatedFare, requested.RequestedAt));
                        break;

                    case "trip.assigned":
                        var assigned = JsonSerializer.Deserialize<TripAssignedEvent>(body)!;
                        await notifications.SendTripAssignedAsync(assigned.CustomerId, new TripAssignedDto(
                            assigned.TripId, assigned.DriverId, assigned.VehicleId,
                            assigned.DriverName, assigned.DriverLatitude, assigned.DriverLongitude, assigned.AssignedAt));
                        await chat.GetOrCreateTripConversationAsync(assigned.TripId, assigned.CustomerId, assigned.DriverId);
                        break;

                    case "trip.started":
                        var started = JsonSerializer.Deserialize<TripStartedEvent>(body)!;
                        var startedDto = new TripStatusChangedDto(started.TripId, TripStatus.InProgress, started.CustomerId, started.DriverId, started.PickupTime);
                        await notifications.SendTripStatusChangedAsync(started.DriverId, startedDto);
                        await notifications.SendTripStatusChangedToUserAsync(started.CustomerId, startedDto);
                        break;

                    case "trip.completed":
                        var completed = JsonSerializer.Deserialize<TripCompletedEvent>(body)!;
                        var completedDto = new TripStatusChangedDto(completed.TripId, TripStatus.Completed, completed.CustomerId, completed.DriverId, completed.DropoffTime);
                        await notifications.SendTripStatusChangedAsync(completed.DriverId, completedDto);
                        await notifications.SendTripStatusChangedToUserAsync(completed.CustomerId, completedDto);
                        await chat.CloseConversationByTripIdAsync(completed.TripId);
                        break;

                    case "trip.cancelled":
                        var cancelled = JsonSerializer.Deserialize<TripCancelledEvent>(body)!;
                        var cancelledDto = new TripStatusChangedDto(cancelled.TripId, TripStatus.Cancelled, cancelled.CustomerId, cancelled.DriverId, cancelled.CancelledAt);
                        await notifications.SendTripStatusChangedToUserAsync(cancelled.CustomerId, cancelledDto);
                        if (cancelled.DriverId.HasValue)
                            await notifications.SendTripStatusChangedAsync(cancelled.DriverId.Value, cancelledDto);
                        await chat.CloseConversationByTripIdAsync(cancelled.TripId);
                        break;
                }

                await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false, cancellationToken: stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing trip event on route {RoutingKey}", ea.RoutingKey);
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
