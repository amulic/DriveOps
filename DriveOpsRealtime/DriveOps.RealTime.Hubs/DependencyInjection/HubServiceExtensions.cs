

using DriveOps.RealTime.Contracts.Interfaces;
using DriveOps.RealTime.Hubs.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DriveOps.RealTime.Hubs.DependencyInjection
{
public static class HubServiceExtensions
{
    public static IServiceCollection AddRealTimeHubs(this IServiceCollection services)
    {
        services.AddScoped<INotificationHubService, NotificationHubService>();
        services.AddScoped<ILocationService, LocationService>();

        return services;
    }
}

}