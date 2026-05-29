using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.Infrastructure.Persistence;

public static class SeedData
{
    public static async Task SeedAsync(ApplicationDbContext context, ILogger logger)
    {
        if (await context.Users.AnyAsync())
        {
            logger.LogInformation("Database already seeded. Skipping.");
            return;
        }

        logger.LogInformation("Seeding database...");

        var users = new[]
        {
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                Email = "admin@driveops.com",
                PasswordHash = "seeded",
                FirstName = "Admin",
                LastName = "Manager",
                PhoneNumber = "+1-555-0001",
                UserType = (int)UserType.Admin,
                IsActive = true
            },
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0002-4000-8000-000000000002"),
                Email = "marcus.johnson@driveops.com",
                PasswordHash = "seeded",
                FirstName = "Marcus",
                LastName = "Johnson",
                PhoneNumber = "+1-555-0101",
                UserType = (int)UserType.Driver,
                IsActive = true
            },
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0003-4000-8000-000000000003"),
                Email = "sarah.williams@driveops.com",
                PasswordHash = "seeded",
                FirstName = "Sarah",
                LastName = "Williams",
                PhoneNumber = "+1-555-0102",
                UserType = (int)UserType.Driver,
                IsActive = true
            },
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0004-4000-8000-000000000004"),
                Email = "david.chen@driveops.com",
                PasswordHash = "seeded",
                FirstName = "David",
                LastName = "Chen",
                PhoneNumber = "+1-555-0103",
                UserType = (int)UserType.Driver,
                IsActive = true
            },
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0005-4000-8000-000000000005"),
                Email = "emily.rodriguez@driveops.com",
                PasswordHash = "seeded",
                FirstName = "Emily",
                LastName = "Rodriguez",
                PhoneNumber = "+1-555-0104",
                UserType = (int)UserType.Driver,
                IsActive = true
            },
            new User
            {
                Id = Guid.Parse("a1b2c3d4-0006-4000-8000-000000000006"),
                Email = "james.brown@driveops.com",
                PasswordHash = "seeded",
                FirstName = "James",
                LastName = "Brown",
                PhoneNumber = "+1-555-0105",
                UserType = (int)UserType.Driver,
                IsActive = true
            }
        };

        await context.Users.AddRangeAsync(users);

        var customers = new[]
        {
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0001-4000-8000-000000000001"),
                Name = "John Doe",
                PhoneNumber = "+1-555-1001",
                Email = "john.doe@email.com",
                Rating = 4.80m,
                TotalTrips = 12,
                PreferredPaymentMethod = (int)PaymentMethod.CreditCard
            },
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0002-4000-8000-000000000002"),
                Name = "Jane Smith",
                PhoneNumber = "+1-555-1002",
                Email = "jane.smith@email.com",
                Rating = 4.90m,
                TotalTrips = 24,
                PreferredPaymentMethod = (int)PaymentMethod.DigitalWallet
            },
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0003-4000-8000-000000000003"),
                Name = "Bob Wilson",
                PhoneNumber = "+1-555-1003",
                Email = "bob.wilson@email.com",
                Rating = 4.50m,
                TotalTrips = 5,
                PreferredPaymentMethod = (int)PaymentMethod.Cash
            }
        };

        await context.Customers.AddRangeAsync(customers);

        var drivers = new[]
        {
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0001-4000-8000-000000000001"),
                UserId = users[1].Id,
                LicenseNumber = "DL-001234",
                LicenseExpiryDate = new DateOnly(2027, 6, 15),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+1-555-9901",
                Status = DriverStatus.Active,
                Rating = 4.90m,
                TotalTrips = 342,
                TotalRevenue = 18500.00m,
                IsOnline = true,
                CurrentLatitude = 40.7128m,
                CurrentLongitude = -74.0060m,
                LastLocationUpdate = DateTime.UtcNow
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0002-4000-8000-000000000002"),
                UserId = users[2].Id,
                LicenseNumber = "DL-005678",
                LicenseExpiryDate = new DateOnly(2026, 12, 1),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+1-555-9902",
                Status = DriverStatus.Active,
                Rating = 4.85m,
                TotalTrips = 290,
                TotalRevenue = 15200.00m,
                IsOnline = true,
                CurrentLatitude = 40.7282m,
                CurrentLongitude = -73.7949m
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0003-4000-8000-000000000003"),
                UserId = users[3].Id,
                LicenseNumber = "DL-009012",
                LicenseExpiryDate = new DateOnly(2027, 3, 20),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+1-555-9903",
                Status = DriverStatus.Active,
                Rating = 4.75m,
                TotalTrips = 178,
                TotalRevenue = 9800.00m,
                IsOnline = false,
                CurrentLatitude = 40.7580m,
                CurrentLongitude = -73.9855m
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0004-4000-8000-000000000004"),
                UserId = users[4].Id,
                LicenseNumber = "DL-003456",
                LicenseExpiryDate = new DateOnly(2026, 9, 30),
                Status = DriverStatus.OnTrip,
                Rating = 4.70m,
                TotalTrips = 150,
                TotalRevenue = 8200.00m,
                IsOnline = true,
                CurrentLatitude = 40.6892m,
                CurrentLongitude = -74.0445m
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0005-4000-8000-000000000005"),
                UserId = users[5].Id,
                LicenseNumber = "DL-007890",
                LicenseExpiryDate = new DateOnly(2027, 8, 10),
                Status = DriverStatus.Suspended,
                Rating = 3.80m,
                TotalTrips = 45,
                TotalRevenue = 2100.00m,
                IsOnline = false
            }
        };

        await context.Drivers.AddRangeAsync(drivers);

        var vehicles = new[]
        {
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0001-4000-8000-000000000001"),
                LicensePlate = "ABC-1234",
                Make = "Toyota",
                Model = "Camry",
                Year = 2022,
                Color = "Silver",
                Vin = "VIN00123456789012",
                InsurancePolicyNumber = "INS-001",
                InsuranceExpiryDate = new DateOnly(2026, 3, 15),
                RegistrationExpiryDate = new DateOnly(2026, 9, 30),
                Status = VehicleStatus.Available,
                Mileage = 45200,
                FuelType = FuelType.Petrol,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[0].Id
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0002-4000-8000-000000000002"),
                LicensePlate = "DEF-5678",
                Make = "Honda",
                Model = "Civic",
                Year = 2023,
                Color = "Black",
                Vin = "VIN56789012345678",
                InsurancePolicyNumber = "INS-002",
                InsuranceExpiryDate = new DateOnly(2026, 7, 1),
                RegistrationExpiryDate = new DateOnly(2027, 1, 15),
                Status = VehicleStatus.Available,
                Mileage = 22100,
                FuelType = FuelType.Hybrid,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[1].Id
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0003-4000-8000-000000000003"),
                LicensePlate = "GHI-9012",
                Make = "Tesla",
                Model = "Model 3",
                Year = 2023,
                Color = "White",
                Vin = "VIN90123456789012",
                InsurancePolicyNumber = "INS-003",
                InsuranceExpiryDate = new DateOnly(2026, 11, 20),
                RegistrationExpiryDate = new DateOnly(2027, 5, 10),
                Status = VehicleStatus.Available,
                Mileage = 18500,
                FuelType = FuelType.Electric,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[2].Id
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0004-4000-8000-000000000004"),
                LicensePlate = "JKL-3456",
                Make = "Hyundai",
                Model = "Ioniq",
                Year = 2022,
                Color = "Blue",
                Vin = "VIN34567890123456",
                InsurancePolicyNumber = "INS-004",
                InsuranceExpiryDate = new DateOnly(2026, 5, 8),
                RegistrationExpiryDate = new DateOnly(2026, 12, 1),
                Status = VehicleStatus.InUse,
                Mileage = 38700,
                FuelType = FuelType.Hybrid,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[3].Id
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0005-4000-8000-000000000005"),
                LicensePlate = "MNO-7890",
                Make = "Ford",
                Model = "Escape",
                Year = 2021,
                Color = "Red",
                Vin = "VIN78901234567890",
                InsurancePolicyNumber = "INS-005",
                InsuranceExpiryDate = new DateOnly(2025, 12, 31),
                RegistrationExpiryDate = new DateOnly(2026, 6, 30),
                Status = VehicleStatus.Maintenance,
                Mileage = 62000,
                FuelType = FuelType.Petrol,
                SeatingCapacity = 5
            }
        };

        await context.Vehicles.AddRangeAsync(vehicles);

        var now = DateTime.UtcNow;

        var trips = new[]
        {
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0001-4000-8000-000000000001"),
                CustomerId = customers[0].Id,
                DriverId = drivers[0].Id,
                VehicleId = vehicles[0].Id,
                TripStatus = TripStatus.Completed,
                TripType = TripType.Standard,
                PickupLatitude = 40.7128m,
                PickupLongitude = -74.0060m,
                PickupAddress = "123 Main St, Downtown",
                DropoffLatitude = 40.7580m,
                DropoffLongitude = -73.9855m,
                DropoffAddress = "456 Oak Ave, Uptown",
                RequestedAt = now.AddDays(-5),
                AssignedAt = now.AddDays(-5).AddMinutes(2),
                PickupTime = now.AddDays(-5).AddMinutes(5),
                DropoffTime = now.AddDays(-5).AddMinutes(25),
                EstimatedDistance = 8.5m,
                ActualDistance = 9.2m,
                EstimatedDuration = 22,
                ActualDuration = 25,
                EstimatedFare = 18.25m,
                ActualFare = 19.30m,
                PaymentMethod = PaymentMethod.CreditCard,
                PaymentStatus = PaymentStatus.Completed,
                CustomerRating = 5,
                DriverRating = 4
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0002-4000-8000-000000000002"),
                CustomerId = customers[1].Id,
                DriverId = drivers[1].Id,
                VehicleId = vehicles[1].Id,
                TripStatus = TripStatus.InProgress,
                TripType = TripType.Premium,
                PickupLatitude = 40.7282m,
                PickupLongitude = -73.7949m,
                PickupAddress = "789 Pine Rd, Midtown",
                DropoffLatitude = 40.6892m,
                DropoffLongitude = -74.0445m,
                DropoffAddress = "321 Elm St, Eastside",
                RequestedAt = now.AddMinutes(-15),
                AssignedAt = now.AddMinutes(-13),
                PickupTime = now.AddMinutes(-10),
                EstimatedDistance = 12.0m,
                EstimatedDuration = 30,
                EstimatedFare = 24.00m,
                PaymentMethod = PaymentMethod.DigitalWallet,
                PaymentStatus = PaymentStatus.Pending
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0003-4000-8000-000000000003"),
                CustomerId = customers[2].Id,
                TripStatus = TripStatus.Requested,
                TripType = TripType.Standard,
                PickupLatitude = 40.7580m,
                PickupLongitude = -73.9855m,
                PickupAddress = "555 Cedar Ln, Westend",
                DropoffLatitude = 40.7128m,
                DropoffLongitude = -74.0060m,
                DropoffAddress = "888 Maple Dr, Southside",
                RequestedAt = now.AddMinutes(-2),
                EstimatedDistance = 6.3m,
                EstimatedDuration = 18,
                EstimatedFare = 14.45m,
                PaymentMethod = PaymentMethod.Cash,
                PaymentStatus = PaymentStatus.Pending
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0004-4000-8000-000000000004"),
                CustomerId = customers[0].Id,
                DriverId = drivers[0].Id,
                VehicleId = vehicles[0].Id,
                TripStatus = TripStatus.Cancelled,
                TripType = TripType.Standard,
                PickupLatitude = 40.7300m,
                PickupLongitude = -73.9900m,
                PickupAddress = "222 Birch Ave, Northside",
                DropoffLatitude = 40.7500m,
                DropoffLongitude = -73.9800m,
                DropoffAddress = "333 Spruce Way, Downtown",
                RequestedAt = now.AddDays(-2),
                CancellationReason = "Customer requested cancellation",
                EstimatedDistance = 4.1m,
                EstimatedDuration = 12,
                EstimatedFare = 10.65m,
                PaymentStatus = PaymentStatus.Pending
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0005-4000-8000-000000000005"),
                CustomerId = customers[1].Id,
                DriverId = drivers[3].Id,
                VehicleId = vehicles[3].Id,
                TripStatus = TripStatus.Assigned,
                TripType = TripType.Standard,
                PickupLatitude = 40.7400m,
                PickupLongitude = -73.9950m,
                PickupAddress = "444 Walnut St, Midtown",
                DropoffLatitude = 40.7200m,
                DropoffLongitude = -73.9700m,
                DropoffAddress = "666 Cherry Blvd, Uptown",
                RequestedAt = now.AddMinutes(-8),
                AssignedAt = now.AddMinutes(-5),
                EstimatedDistance = 5.7m,
                EstimatedDuration = 16,
                EstimatedFare = 14.05m,
                PaymentMethod = PaymentMethod.DebitCard,
                PaymentStatus = PaymentStatus.Pending
            }
        };

        await context.Trips.AddRangeAsync(trips);
        await context.SaveChangesAsync();

        logger.LogInformation("Database seeded with {UserCount} users, {CustomerCount} customers, {DriverCount} drivers, {VehicleCount} vehicles, {TripCount} trips.",
            users.Length, customers.Length, drivers.Length, vehicles.Length, trips.Length);
    }
}