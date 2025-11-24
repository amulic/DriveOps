using DriveOps.Application.Interfaces;
using DriveOps.Application.Services;
using DriveOps.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options => options.UseSqlServer(connectionString));

// DI
builder.Services.AddScoped<ICarService, CarService>();

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
           ValidAudience = builder.Configuration["Keycloak:Audience"],
           ValidIssuer = builder.Configuration["Keycloak:Authority"]
       };
   });

builder.Services.AddAuthorization();

var app = builder.Build();



// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
