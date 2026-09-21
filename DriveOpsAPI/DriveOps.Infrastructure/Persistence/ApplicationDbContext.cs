using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.Infrastructure.Persistence
{
    public partial class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) {
        }

        public virtual DbSet<Customer> Customers { get; set; }

        public virtual DbSet<Driver> Drivers { get; set; }

        public virtual DbSet<Trip> Trips { get; set; }

        public virtual DbSet<TripRoute> TripRoutes { get; set; }

        public virtual DbSet<Vehicle> Vehicles { get; set; }

        public virtual DbSet<VehicleDefectReport> VehicleDefectReports { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                var fallbackConnectionString = "Server=localhost;Port=3306;Database=driveops_api;User=driveops_api;Password=driveops_api;";
                var mysqlServerVersion = new MySqlServerVersion(new Version(8, 0, 36));
                optionsBuilder.UseMySql(fallbackConnectionString, mysqlServerVersion);
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Customer>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__Customer__3214EC074429FDDF");

                entity.HasIndex(e => e.KeycloakId, "UQ__Customer__KeycloakId").IsUnique();

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.Email).HasMaxLength(255);
                entity.Property(e => e.Name).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20);
                entity.Property(e => e.Rating)
                    .HasDefaultValue(5.00m)
                    .HasColumnType("decimal(3, 2)");
                entity.Property(e => e.TotalTrips).HasDefaultValue(0);
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
            });

            modelBuilder.Entity<Driver>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__Drivers__3214EC07B4817E92");

                entity.HasIndex(e => e.KeycloakId, "UQ__Drivers__KeycloakId").IsUnique();
                entity.HasIndex(e => e.LicenseNumber, "UQ__Drivers__E88901666371942D").IsUnique();

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.CurrentLatitude).HasColumnType("decimal(10, 8)");
                entity.Property(e => e.CurrentLongitude).HasColumnType("decimal(11, 8)");
                entity.Property(e => e.Email).HasMaxLength(255);
                entity.Property(e => e.EmergencyContactName).HasMaxLength(100);
                entity.Property(e => e.EmergencyContactPhone).HasMaxLength(20);
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.IsOnline).HasDefaultValue(false);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.LicenseNumber).HasMaxLength(50);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20);
                entity.Property(e => e.ProfileImageUrl).HasMaxLength(500);
                entity.Property(e => e.Rating)
                    .HasDefaultValue(5.00m)
                    .HasColumnType("decimal(3, 2)");
                entity.Property(e => e.Status).HasDefaultValue(DriverStatus.Active);
                entity.Property(e => e.TotalRevenue)
                    .HasDefaultValue(0m)
                    .HasColumnType("decimal(10, 2)");
                entity.Property(e => e.TotalTrips).HasDefaultValue(0);
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
            });

            modelBuilder.Entity<Trip>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__Trips__3214EC075F28D6FF");

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.ActualDistance).HasColumnType("decimal(8, 2)");
                entity.Property(e => e.ActualFare).HasColumnType("decimal(10, 2)");
                entity.Property(e => e.CancellationReason).HasMaxLength(500);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.CustomerFeedback).HasMaxLength(1000);
                entity.Property(e => e.DriverFeedback).HasMaxLength(1000);
                entity.Property(e => e.DropoffAddress).HasMaxLength(500);
                entity.Property(e => e.DropoffLatitude).HasColumnType("decimal(10, 8)");
                entity.Property(e => e.DropoffLongitude).HasColumnType("decimal(11, 8)");
                entity.Property(e => e.EstimatedDistance).HasColumnType("decimal(8, 2)");
                entity.Property(e => e.EstimatedFare).HasColumnType("decimal(10, 2)");
                entity.Property(e => e.PaymentStatus).HasDefaultValue(PaymentStatus.Pending);
                entity.Property(e => e.PickupAddress).HasMaxLength(500);
                entity.Property(e => e.PickupLatitude).HasColumnType("decimal(10, 8)");
                entity.Property(e => e.PickupLongitude).HasColumnType("decimal(11, 8)");
                entity.Property(e => e.RequestedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.SpecialInstructions).HasMaxLength(500);
                entity.Property(e => e.TripStatus).HasDefaultValue(TripStatus.Requested);
                entity.Property(e => e.TripType).HasDefaultValue(TripType.Standard);
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");

                entity.HasOne(d => d.Customer).WithMany(p => p.Trips)
                    .HasForeignKey(d => d.CustomerId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK__Trips__CustomerI__5CD6CB2B");

                entity.HasOne(d => d.Driver).WithMany(p => p.Trips)
                    .HasForeignKey(d => d.DriverId)
                    .HasConstraintName("FK__Trips__DriverId__5DCAEF64");

                entity.HasOne(d => d.Vehicle).WithMany(p => p.Trips)
                    .HasForeignKey(d => d.VehicleId)
                    .HasConstraintName("FK__Trips__VehicleId__5EBF139D");
            });

            modelBuilder.Entity<TripRoute>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__TripRout__3214EC077D385975");

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.Latitude).HasColumnType("decimal(10, 8)");
                entity.Property(e => e.Longitude).HasColumnType("decimal(11, 8)");
                entity.Property(e => e.Timestamp).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");

                entity.HasOne(d => d.Trip).WithMany(p => p.TripRoutes)
                    .HasForeignKey(d => d.TripId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK__TripRoute__TripI__68487DD7");
            });

            modelBuilder.Entity<Vehicle>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__Vehicles__3214EC076C52E23F");

                entity.HasIndex(e => e.LicensePlate, "UQ__Vehicles__026BC15CA221806E").IsUnique();

                entity.HasIndex(e => e.Vin, "UQ__Vehicles__C5DF234CE959122A").IsUnique();

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.Color).HasMaxLength(30);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.InsurancePolicyNumber).HasMaxLength(50);
                entity.Property(e => e.InternalName).HasMaxLength(100);
                entity.Property(e => e.LicensePlate).HasMaxLength(20);
                entity.Property(e => e.Make).HasMaxLength(50);
                entity.Property(e => e.Mileage).HasDefaultValue(0);
                entity.Property(e => e.Model).HasMaxLength(50);
                entity.Property(e => e.PhotoUrl).HasMaxLength(500);
                entity.Property(e => e.SeatingCapacity).HasDefaultValue(4);
                entity.Property(e => e.Status).HasDefaultValue(VehicleStatus.Available);
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");
                entity.Property(e => e.Vin)
                    .HasMaxLength(50)
                    .HasColumnName("VIN");

                entity.HasOne(d => d.AssignedDriver).WithMany(p => p.Vehicles)
                    .HasForeignKey(d => d.AssignedDriverId)
                    .HasConstraintName("FK__Vehicles__Assign__4F7CD00D");
            });

            modelBuilder.Entity<VehicleDefectReport>(entity =>
            {
                entity.HasKey(e => e.Id).HasName("PK__VehicleDefectReports__3214EC07");

                entity.Property(e => e.Id).HasDefaultValueSql("(UUID())");
                entity.Property(e => e.Title).HasMaxLength(200);
                entity.Property(e => e.Description).HasMaxLength(2000);
                entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Reported");
                entity.Property(e => e.ReportedAt).HasDefaultValueSql("CURRENT_TIMESTAMP(6)");

                entity.HasOne(d => d.Vehicle).WithMany()
                    .HasForeignKey(d => d.VehicleId)
                    .HasConstraintName("FK__VehicleDefectReports__VehicleId");

                entity.HasOne(d => d.Driver).WithMany()
                    .HasForeignKey(d => d.DriverId)
                    .HasConstraintName("FK__VehicleDefectReports__DriverId");
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);

    }
}
