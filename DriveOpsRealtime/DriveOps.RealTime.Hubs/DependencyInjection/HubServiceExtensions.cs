

using DriveOps.RealTime.Contracts.Interfaces;
using DriveOps.RealTime.Hubs.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DriveOps.RealTime.Hubs.DependencyInjection
{
public static class HubServiceExtensions
{
    public static IServiceCollection AddRealTimeHubs(this IServiceCollection services, string apiBaseUrl)
    {
        services.AddScoped<INotificationHubService, NotificationHubService>();
        services.AddScoped<ILocationService, LocationService>();

        services.AddMemoryCache();
        services.AddHttpClient<IDriverProfileResolver, ApiDriverProfileResolver>(client =>
        {
            client.BaseAddress = new Uri(apiBaseUrl);
        });

        return services;
    }
}

}