using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Infrastructure.RabbitMQ;
using DriveOps.Infrastructure.Repositories;
using DriveOps.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;

namespace DriveOps.Infrastructure.DependencyInjection
{
    public static class InfrastructureServiceExtensions
    {
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, string connectionString)
        {
            var mysqlServerVersion = new MySqlServerVersion(new Version(8, 0, 36));
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseMySql(connectionString, mysqlServerVersion));

            // Repositories
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            services.AddScoped<IDriverRepository, DriverRepository>();
            services.AddScoped<ICustomerRepository, CustomerRepository>();
            services.AddScoped<IVehicleRepository, VehicleRepository>();
            services.AddScoped<ITripRepository, TripRepository>();
            services.AddScoped<ITripRouteRepository, TripRouteRepository>();

            // External services
            services.AddHttpClient<IRoutingService, OsrmRoutingService>(client =>
            {
                client.BaseAddress = new Uri("http://router.project-osrm.org/");
                client.Timeout = TimeSpan.FromSeconds(10);
            });

            return services;
        }

        public static IServiceCollection AddRabbitMq(this IServiceCollection services, string host, int port, string user, string pass)
        {
            // RabbitMQ connection (singleton)
            services.AddSingleton<IConnection>(sp =>
            {
                var factory = new ConnectionFactory
                {
                    HostName = host,
                    Port = port,
                    UserName = user,
                    Password = pass
                };
                return factory.CreateConnectionAsync().GetAwaiter().GetResult();
            });

            services.AddSingleton<IEventPublisher>(sp =>
                new RabbitMqEventPublisher(
                    sp.GetRequiredService<IConnection>(),
                    sp.GetRequiredService<ILogger<RabbitMqEventPublisher>>()));
            services.AddHostedService<DriverLocationReceivedConsumer>();

            return services;
        }
    }
}
