using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Payments;
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
        public static IServiceCollection AddInfrastructure(this IServiceCollection services, string connectionString, string? osrmBaseUrl = null, string? nominatimBaseUrl = null)
        {
            var mysqlServerVersion = new MySqlServerVersion(new Version(8, 0, 36));
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseMySql(connectionString, mysqlServerVersion));

            // Repositories
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            services.AddScoped<IDriverRepository, DriverRepository>();
            services.AddScoped<ICustomerRepository, CustomerRepository>();
            services.AddScoped<IVehicleRepository, VehicleRepository>();
            services.AddScoped<IVehicleDefectReportRepository, VehicleDefectReportRepository>();
            services.AddScoped<ITripRepository, TripRepository>();
            services.AddScoped<ITripRouteRepository, TripRouteRepository>();
            services.AddScoped<IPaymentRepository, PaymentRepository>();

            // External services
            services.AddHttpClient<IRoutingService, OsrmRoutingService>(client =>
            {
                client.BaseAddress = new Uri(osrmBaseUrl ?? "http://router.project-osrm.org/");
                client.Timeout = TimeSpan.FromSeconds(10);
                // The OSRM demo server rejects UA-less requests with 403.
                client.DefaultRequestHeaders.UserAgent.ParseAdd("DriveOps/1.0 (driveops dev)");
            });
            services.AddHttpClient<IGeocodingService, NominatimGeocodingService>(client =>
            {
                client.BaseAddress = new Uri(nominatimBaseUrl ?? "https://nominatim.openstreetmap.org/");
                client.Timeout = TimeSpan.FromSeconds(10);
                // Nominatim's usage policy requires an identifying User-Agent.
                client.DefaultRequestHeaders.UserAgent.ParseAdd("DriveOps/1.0 (driveops dev)");
            });
            services.AddHttpClient<IKeycloakAdminService, KeycloakAdminService>(client =>
            {
                client.Timeout = TimeSpan.FromSeconds(15);
            });

            return services;
        }

        public static IServiceCollection AddPayments(this IServiceCollection services, string? stripeSecretKey)
        {
            services.AddSingleton<IPaymentGateway>(sp =>
                new StripePaymentGateway(
                    stripeSecretKey ?? "",
                    sp.GetRequiredService<ILogger<StripePaymentGateway>>()));
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
