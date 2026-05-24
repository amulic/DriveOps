using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Infrastructure.RabbitMQ;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DriveOps.RealTime.Infrastructure.DependencyInjection;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddRealTimeInfrastructure(this IServiceCollection services,
        string connectionString, string rabbitHost, int rabbitPort, string rabbitUser, string rabbitPass)
    {
        var mysqlServerVersion = new MySqlServerVersion(new Version(8, 0, 36));
        services.AddDbContext<RealTimeDbContext>(options =>
            options.UseMySql(connectionString, mysqlServerVersion));

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

        services.AddSingleton<IEventPublisher>(sp =>
            new RabbitMqEventPublisher(
                sp.GetRequiredService<IConnection>(),
                sp.GetRequiredService<ILogger<RabbitMqEventPublisher>>(),
                poolSize: 5));

        services.AddHostedService<TripEventConsumer>();
        services.AddHostedService<LocationEventConsumer>();
        services.AddHostedService<FleetEventConsumer>();

        return services;
    }
}
