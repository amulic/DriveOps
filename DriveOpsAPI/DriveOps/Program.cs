using DriveOps.Application.DependencyInjection;
using DriveOps.Infrastructure.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "Bearer",
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
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

// DI - Infrastructure (DbContext, Repositories, External Services)
builder.Services.AddInfrastructure(connectionString);

// DI - Application (Services)
builder.Services.AddApplication();

// Keycloak
builder.Services.AddAuthentication("Bearer")
   .AddJwtBearer("Bearer", options =>
   {
       options.Authority = builder.Configuration["Keycloak:Authority"];
       options.Audience = builder.Configuration["Keycloak:Audience"];
       options.RequireHttpsMetadata = false;

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

       options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
       {
           OnAuthenticationFailed = context =>
           {
               Console.WriteLine("Authentication failed: " + context.Exception.Message);
               return Task.CompletedTask;
           },
           OnTokenValidated = context =>
           {
               Console.WriteLine("Token validated for: " + context.Principal.Identity.Name);
               return Task.CompletedTask;
           }
       };
   });

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173") // TODO change to whatever frontend is
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

builder.Services.AddAuthorization();

var app = builder.Build();



// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");

app.UseHttpsRedirection();


app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
