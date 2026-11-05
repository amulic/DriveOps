using DriveOps.RealTime.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.RealTime.Infrastructure.Persistence;

public class RealTimeDbContext : DbContext
{
    public RealTimeDbContext(DbContextOptions<RealTimeDbContext> options) : base(options) { }

    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<ConversationParticipant> ConversationParticipants => Set<ConversationParticipant>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<DriverLocationCache> DriverLocationCaches => Set<DriverLocationCache>();
    public DbSet<UserConnection> UserConnections => Set<UserConnection>();
    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(RealTimeDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
