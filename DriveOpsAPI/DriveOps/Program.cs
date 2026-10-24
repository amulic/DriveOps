using DriveOps.Application.DependencyInjection;
using DriveOps.Application.Helpers;
using DriveOps.Infrastructure.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;

JwtSecurityTokenHandler.DefaultMapInboundClaims = false;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Enter JWT Authorization from Keycloak"
    });

    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
        new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

// DI - Infrastructure (DbContext, Repositories, External Services)
var osrmBaseUrl = builder.Configuration["Osrm:BaseUrl"];
var nominatimBaseUrl = builder.Configuration["Nominatim:BaseUrl"];
builder.Services.AddInfrastructure(connectionString, osrmBaseUrl, nominatimBaseUrl);

// DI - RabbitMQ (Event Publishing + Consumers)
var rabbitHost = builder.Configuration["RabbitMQ:HostName"] ?? "localhost";
var rabbitPort = int.Parse(builder.Configuration["RabbitMQ:Port"] ?? "5672");
var rabbitUser = builder.Configuration["RabbitMQ:UserName"] ?? "guest";
var rabbitPass = builder.Configuration["RabbitMQ:Password"] ?? "guest";
builder.Services.AddRabbitMq(rabbitHost, rabbitPort, rabbitUser, rabbitPass);

// DI - Application (Services)
builder.Services.AddApplication();

// DI - Payments (Stripe gateway + non-secret options; secrets come from user-secrets/env)
builder.Services.AddPayments(builder.Configuration["Stripe:SecretKey"]);
builder.Services.AddSingleton(new DriveOps.Application.Services.PaymentServiceOptions
{
    Currency = builder.Configuration["Stripe:Currency"] ?? "eur",
    WebhookSecret = builder.Configuration["Stripe:WebhookSecret"] ?? ""
});

// Fare Calculator configuration
builder.Services.Configure<FareCalculatorOptions>(
    builder.Configuration.GetSection("FareCalculator"));
var fareSection = builder.Configuration.GetSection("FareCalculator");
if (fareSection.Exists())
{
    FareCalculator.Configure(new FareCalculatorOptions
    {
        BaseFare = fareSection.GetValue<decimal>("BaseFare", 2.50m),
        PerKmRate = fareSection.GetValue<decimal>("PerKmRate", 1.50m),
        PerMinuteRate = fareSection.GetValue<decimal>("PerMinuteRate", 0.25m),
        PremiumMultiplier = fareSection.GetValue<decimal>("PremiumMultiplier", 1.5m),
        SharedMultiplier = fareSection.GetValue<decimal>("SharedMultiplier", 0.7m)
    });
}

// Keycloak
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
             // Accept tokens issued via localhost (desktop) or the Android emulator loopback alias (mobile dev).
             ValidIssuers = new[]
             {
                 builder.Configuration["Keycloak:Authority"],
                 builder.Configuration["Keycloak:Authority"]?.Replace("localhost", "10.0.2.2")
             },
             ClockSkew = TimeSpan.Zero,
             RoleClaimType = System.Security.Claims.ClaimTypes.Role
         };

       options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
       {
           OnAuthenticationFailed = context =>
           {
               var logger = context.HttpContext.RequestServices
                   .GetRequiredService<ILoggerFactory>()
                   .CreateLogger("Authentication");

               logger.LogWarning("JWT authentication failed: {ExceptionType}", context.Exception.GetType().Name);
               return Task.CompletedTask;
           },
OnTokenValidated = context =>
            {
                var logger = context.HttpContext.RequestServices
                    .GetRequiredService<ILoggerFactory>()
                    .CreateLogger("Authentication");

                logger.LogDebug("JWT token validated successfully.");

                // With DefaultMapInboundClaims = false, Keycloak realm roles stay nested in the
                // "realm_access" claim — expand them into ClaimTypes.Role so [Authorize(Roles=...)] works.
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
                            identity.AddClaim(new System.Security.Claims.Claim(
                                System.Security.Claims.ClaimTypes.Role, role.GetString() ?? ""));
                        }
                    }
                }

                return Task.CompletedTask;
            }
       };
   });

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:42069", "http://localhost:42069")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.AddAuthorization();

// Logging
builder.Logging.ClearProviders();   
builder.Logging.AddConsole();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<DriveOps.Infrastructure.Persistence.ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    db.Database.Migrate();
    DriveOps.Infrastructure.Persistence.SeedData.SeedAsync(db, logger).GetAwaiter().GetResult();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}


app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
