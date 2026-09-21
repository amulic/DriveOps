using DriveOpsRealtime.Controllers;
using DriveOps.RealTime.Hubs;
using DriveOps.RealTime.Hubs.DependencyInjection;
using DriveOps.RealTime.Infrastructure.DependencyInjection;
using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Services.DependencyInjection;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;

JwtSecurityTokenHandler.DefaultMapInboundClaims = false;

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

// Controllers
builder.Services.AddControllers();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();

        options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Keycloak:Authority"],
            ClockSkew = TimeSpan.Zero,
            RoleClaimType = System.Security.Claims.ClaimTypes.Role
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
            },
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices.GetService<ILogger<Program>>();
                logger?.LogWarning(context.Exception, "JWT authentication failed for {Path}: {Error}", context.Request.Path, context.Exception.Message);
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                var identity = context.Principal?.Identity as System.Security.Claims.ClaimsIdentity;
                if (identity == null) return Task.CompletedTask;

                var realmAccessClaim = context.Principal!.FindFirst("realm_access");
                if (realmAccessClaim != null)
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(realmAccessClaim.Value);
                    if (doc.RootElement.TryGetProperty("roles", out var roles))
                    {
                        foreach (var role in roles.EnumerateArray())
                        {
                            identity.AddClaim(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, role.GetString() ?? ""));
                        }
                    }
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireRole("admin"));
});

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

        options.AddPolicy("AllowAnyDev", policy =>
        {
            if (builder.Environment.IsDevelopment())
            {
                policy.SetIsOriginAllowed(_ => true)
                      .AllowAnyHeader()
                      .AllowAnyMethod()
                      .AllowCredentials();
            }
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

if (app.Environment.IsDevelopment())
{
    app.UseCors("AllowAnyDev");
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseCors("AllowFrontend");
}

app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception ex)
    {
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Unhandled exception in request {Method} {Path}: {Message}", context.Request.Method, context.Request.Path, ex.Message);
        
        if (context.Response.HasStarted)
        {
            throw;
        }
        
        context.Response.StatusCode = 500;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = app.Environment.IsDevelopment() ? ex.ToString() : "An internal server error occurred." });
    }
});

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Map SignalR hubs
app.MapHub<LocationHub>("/hubs/location");
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<NotificationHub>("/hubs/notifications");


app.Run();
