using DriveOps.Application.Interfaces;
using DriveOps.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DriveOps.Application.DependencyInjection
{
    public static class ApplicationServiceExtensions
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IDriverService, DriverService>();
            services.AddScoped<ICustomerService, CustomerService>();
            services.AddScoped<IVehicleService, VehicleService>();
            services.AddScoped<ITripService, TripService>();

            return services;
        }
    }
}
