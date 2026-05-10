using DriveOps.RealTime.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace DriveOps.RealTime.Infrastructure.Persistence;

public class RealTimeDbContextFactory : IDesignTimeDbContextFactory<RealTimeDbContext>
{
    public RealTimeDbContext CreateDbContext(string[] args)
    {
        var basePath = Path.Combine(Directory.GetCurrentDirectory(), "..", "DriveOpsRealtime");
        if (File.Exists(Path.Combine(basePath, "DriveOpsRealtime.csproj")) == false)
            basePath = Directory.GetCurrentDirectory();

        var config = new ConfigurationBuilder()
            .SetBasePath(basePath)
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        var connectionString = config.GetConnectionString("DefaultConnection")
            ?? "Server=localhost;Port=3306;Database=driveops_realtime;User=driveops_realtime;Password=driveops_realtime;";

        var optionsBuilder = new DbContextOptionsBuilder<RealTimeDbContext>();
        var serverVersion = new MySqlServerVersion(new Version(8, 0, 36));
        optionsBuilder.UseMySql(connectionString, serverVersion);

        return new RealTimeDbContext(optionsBuilder.Options);
    }
}
