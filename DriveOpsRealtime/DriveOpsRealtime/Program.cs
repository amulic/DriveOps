using DriveOps.RealTime.Hubs;
using DriveOps.RealTime.Hubs.DependencyInjection;
using DriveOps.RealTime.Infrastructure.DependencyInjection;
using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Services.DependencyInjection;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Connection strings and config
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

var rabbitHost = builder.Configuration["RabbitMQ:HostName"] ?? "localhost";
var rabbitPort = int.Parse(builder.Configuration["RabbitMQ:Port"] ?? "5672");
var rabbitUser = builder.Configuration["RabbitMQ:UserName"] ?? "guest";
var rabbitPass = builder.Configuration["RabbitMQ:Password"] ?? "guest";

// SignalR
builder.Services.AddSignalR();

// DI - Infrastructure (DbContext, RabbitMQ, Consumers)
builder.Services.AddRealTimeInfrastructure(connectionString, rabbitHost, rabbitPort, rabbitUser, rabbitPass);

// DI - Services (ConnectionMapping, Chat)
builder.Services.AddRealTimeServices();

// DI - Hub services (NotificationHubService, LocationService)
builder.Services.AddRealTimeHubs();


// Keycloak JWT Auth
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = builder.Configuration["Keycloak:Authority"];
        options.Audience = builder.Configuration["Keycloak:Audience"];
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();

        options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
        {
            ValidateAudience = true,
            ValidateIssuer = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidAudience = builder.Configuration["Keycloak:Audience"],
            ValidIssuer = builder.Configuration["Keycloak:Authority"],
            ClockSkew = TimeSpan.Zero
        };

        // SignalR sends JWT via query string (WebSocket connections can't use Authorization headers)
        options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

// Database migrations
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<RealTimeDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<RealTimeDbContext>>();
    try
    {
        await db.Database.MigrateAsync();
        logger.LogInformation("Realtime database migrations applied successfully.");
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "Migrations not available yet. Run 'dotnet ef database update' or ensure migrations exist. Falling back to EnsureCreated.");
        await db.Database.EnsureCreatedAsync();
    }
}

app.UseCors("AllowFrontend");

app.UseAuthentication();
app.UseAuthorization();

// Map SignalR hubs
app.MapHub<LocationHub>("/hubs/location");
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<NotificationHub>("/hubs/notifications");


app.Run();
