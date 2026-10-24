using DriveOps.Application.Interfaces;
using DriveOps.Application.Services;
using DriveOps.Application.Validation;
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace DriveOps.Application.DependencyInjection
{
    public static class ApplicationServiceExtensions
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {
            services.AddScoped<IDriverService, DriverService>();
            services.AddScoped<ICustomerService, CustomerService>();
            services.AddScoped<IVehicleService, VehicleService>();
            services.AddScoped<ITripService, TripService>();
            services.AddScoped<IDriverRecommendationService, DriverRecommendationService>();
            services.AddScoped<IPaymentService, PaymentService>();

            services.AddValidatorsFromAssemblyContaining<CreateTripDtoValidator>();

            return services;
        }
    }
}
