using DriveOps.RealTime.Models.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Metadata;

namespace DriveOps.RealTime.Infrastructure.Configurations;

public class ConversationConfiguration : IEntityTypeConfiguration<Conversation>
{
    public void Configure(EntityTypeBuilder<Conversation> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).ValueGeneratedOnAdd();
        builder.HasIndex(c => c.TripId);

        builder.HasMany(c => c.Participants)
            .WithOne(p => p.Conversation)
            .HasForeignKey(p => p.ConversationId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.Messages)
            .WithOne(m => m.Conversation)
            .HasForeignKey(m => m.ConversationId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public class ConversationParticipantConfiguration : IEntityTypeConfiguration<ConversationParticipant>
{
    public void Configure(EntityTypeBuilder<ConversationParticipant> builder)
    {
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).ValueGeneratedOnAdd();
        builder.HasIndex(p => new { p.ConversationId, p.UserId }).IsUnique();
    }
}

public class ChatMessageConfiguration : IEntityTypeConfiguration<ChatMessage>
{
    public void Configure(EntityTypeBuilder<ChatMessage> builder)
    {
        builder.HasKey(m => m.Id);
        builder.Property(m => m.Id).ValueGeneratedOnAdd();
        builder.Property(m => m.Content).IsRequired().HasMaxLength(4000);
        builder.Property(m => m.Seq)
            .ValueGeneratedOnAdd()
            .HasAnnotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn);
        builder.HasIndex(m => m.ConversationId);
        builder.HasIndex(m => m.Seq).IsUnique();
    }
}

public class DriverLocationCacheConfiguration : IEntityTypeConfiguration<DriverLocationCache>
{
    public void Configure(EntityTypeBuilder<DriverLocationCache> builder)
    {
        builder.HasKey(d => d.DriverId);
        builder.Property(d => d.DriverId).ValueGeneratedNever();
        builder.Property(d => d.Latitude).HasPrecision(10, 8);
        builder.Property(d => d.Longitude).HasPrecision(11, 8);
    }
}

public class UserConnectionConfiguration : IEntityTypeConfiguration<UserConnection>
{
    public void Configure(EntityTypeBuilder<UserConnection> builder)
    {
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).ValueGeneratedOnAdd();
        builder.Property(u => u.ConnectionId).IsRequired().HasMaxLength(450);
        builder.HasIndex(u => u.ConnectionId).IsUnique();
        builder.HasIndex(u => u.UserId);
    }
}
