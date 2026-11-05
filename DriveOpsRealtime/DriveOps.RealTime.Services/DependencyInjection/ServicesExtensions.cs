using DriveOps.RealTime.Contracts.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace DriveOps.RealTime.Services.DependencyInjection;

public static class ServicesExtensions
{
    public static IServiceCollection AddRealTimeServices(this IServiceCollection services)
    {
        services.AddScoped<IConnectionMappingService, ConnectionMappingService>();
        services.AddScoped<IChatService, ChatService>();
        services.AddScoped<INotificationService, NotificationService>();

        return services;
    }
}
