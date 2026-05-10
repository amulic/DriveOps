using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration.Json;

namespace DriveOps.Infrastructure.Persistence
{
    public class ApplicationDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
    {
        public ApplicationDbContext CreateDbContext(string[] args)
        {
            var environment = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT") ?? "Development";

            var basePath = Path.Combine(Directory.GetCurrentDirectory(), "..", "DriveOps");

            if(!Directory.Exists(basePath))
            {
                basePath = Path.Combine(Directory.GetCurrentDirectory(), "DriveOpsAPI");
            }

            if(!Directory.Exists(basePath))
            {
                basePath = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "../../DriveOps"));
            }

            var config = new ConfigurationBuilder()
                .SetBasePath(basePath)
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = config.GetConnectionString("DefaultConnection")
                                   ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

            var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
            var mysqlServerVersion = new MySqlServerVersion(new Version(8, 0, 36));
            optionsBuilder.UseMySql(connectionString, mysqlServerVersion);

            return new ApplicationDbContext(optionsBuilder.Options);
        }
    }
}
