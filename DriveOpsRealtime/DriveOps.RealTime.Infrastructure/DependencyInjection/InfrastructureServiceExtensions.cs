using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Infrastructure.RabbitMQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using RabbitMQ.Client;

namespace DriveOps.RealTime.Infrastructure.DependencyInjection;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddRealTimeInfrastructure(this IServiceCollection services,
        string connectionString, string rabbitHost, int rabbitPort, string rabbitUser, string rabbitPass)
    {
        services.AddDbContext<RealTimeDbContext>(options =>
            options.UseSqlServer(connectionString));

        services.AddSingleton<IConnection>(sp =>
        {
            var factory = new ConnectionFactory
            {
                HostName = rabbitHost,
                Port = rabbitPort,
                UserName = rabbitUser,
                Password = rabbitPass
            };
            return factory.CreateConnectionAsync().GetAwaiter().GetResult();
        });

        services.AddSingleton<IEventPublisher, RabbitMqEventPublisher>();

        services.AddHostedService<TripEventConsumer>();
        services.AddHostedService<LocationEventConsumer>();

        return services;
    }
}
