using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.Infrastructure.Persistence;

public static class SeedData
{
    // Mostar reference points
    // Center ~43.3438,17.8078 | Musala 43.3428,17.8085 | Stari Most 43.3371,17.8154
    // Mepas Mall 43.3453,17.7990 | Rondo 43.3485,17.8120 | Bus station 43.3447,17.8015
    // Airport (OMO) 43.2829,17.8459 | Blagaj 43.2570,17.9000
    public static async Task SeedAsync(ApplicationDbContext context, ILogger logger)
    {
        if (await context.Drivers.AnyAsync() || await context.Customers.AnyAsync())
        {
            logger.LogInformation("Database already seeded. Skipping.");
            return;
        }

        logger.LogInformation("Seeding database...");

        var now = DateTime.UtcNow;

        var customers = new[]
        {
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0001-4000-8000-000000000001"),
                KeycloakId = Guid.Parse("b1b2c3d4-0001-4000-8000-000000000001"),
                Name = "John Doe",
                PhoneNumber = "+387 61 100 001",
                Email = "john.doe@email.com",
                Rating = 4.80m,
                TotalTrips = 12,
                PreferredPaymentMethod = (int)PaymentMethod.CreditCard
            },
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0002-4000-8000-000000000002"),
                KeycloakId = Guid.Parse("b1b2c3d4-0002-4000-8000-000000000002"),
                Name = "Jane Smith",
                PhoneNumber = "+387 61 100 002",
                Email = "jane.smith@email.com",
                Rating = 4.90m,
                TotalTrips = 24,
                PreferredPaymentMethod = (int)PaymentMethod.DigitalWallet
            },
            new Customer
            {
                Id = Guid.Parse("b1b2c3d4-0003-4000-8000-000000000003"),
                KeycloakId = Guid.Parse("b1b2c3d4-0003-4000-8000-000000000003"),
                Name = "Bob Wilson",
                PhoneNumber = "+387 61 100 003",
                Email = "bob.wilson@email.com",
                Rating = 4.50m,
                TotalTrips = 5,
                PreferredPaymentMethod = (int)PaymentMethod.Cash
            }
        };

        await context.Customers.AddRangeAsync(customers);

        // Demo setup: exactly two bookable drivers (IsOnline && Active) —
        // Marcus close to the Mostar center, Sarah ~9 km out (still inside the
        // 10 km recommendation radius so scoring is visible). The rest stay in
        // the DB for list/suspend/approval demos but never appear as candidates.
        var drivers = new[]
        {
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0001-4000-8000-000000000001"),
                KeycloakId = Guid.Parse("a1b2c3d4-0002-4000-8000-000000000002"),
                FirstName = "Marcus",
                LastName = "Johnson",
                Email = "marcus.johnson@driveops.com",
                PhoneNumber = "+387 63 200 001",
                LicenseNumber = "DL-001234",
                LicenseExpiryDate = new DateOnly(2027, 6, 15),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+387 63 990 001",
                Status = DriverStatus.Active,
                Rating = 4.90m,
                TotalTrips = 342,
                TotalRevenue = 18500.00m,
                IsOnline = true,
                CurrentLatitude = 43.3390m,   // Musala area, ~0.6 km from the center
                CurrentLongitude = 17.8100m,
                LastLocationUpdate = now
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0002-4000-8000-000000000002"),
                KeycloakId = Guid.Parse("a1b2c3d4-0003-4000-8000-000000000003"),
                FirstName = "Sarah",
                LastName = "Williams",
                Email = "sarah.williams@driveops.com",
                PhoneNumber = "+387 63 200 002",
                LicenseNumber = "DL-005678",
                LicenseExpiryDate = new DateOnly(2026, 12, 1),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+387 63 990 002",
                Status = DriverStatus.Active,
                Rating = 4.85m,
                TotalTrips = 290,
                TotalRevenue = 15200.00m,
                IsOnline = true,
                CurrentLatitude = 43.2780m,   // Buna/Blagaj direction, ~9 km out (still < 10 km radius)
                CurrentLongitude = 17.8720m,
                LastLocationUpdate = now
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0003-4000-8000-000000000003"),
                KeycloakId = Guid.Parse("a1b2c3d4-0004-4000-8000-000000000004"),
                FirstName = "David",
                LastName = "Chen",
                Email = "david.chen@driveops.com",
                PhoneNumber = "+387 63 200 003",
                LicenseNumber = "DL-009012",
                LicenseExpiryDate = new DateOnly(2027, 3, 20),
                EmergencyContactName = "Emergency Contact",
                EmergencyContactPhone = "+387 63 990 003",
                Status = DriverStatus.Active,
                Rating = 4.75m,
                TotalTrips = 178,
                TotalRevenue = 9800.00m,
                IsOnline = false,               // offline -> excluded from available/nearby
                CurrentLatitude = 43.3500m,
                CurrentLongitude = 17.7900m
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0004-4000-8000-000000000004"),
                KeycloakId = Guid.Parse("a1b2c3d4-0005-4000-8000-000000000005"),
                FirstName = "Emily",
                LastName = "Rodriguez",
                Email = "emily.rodriguez@driveops.com",
                PhoneNumber = "+387 63 200 004",
                LicenseNumber = "DL-003456",
                LicenseExpiryDate = new DateOnly(2027, 9, 30),
                Status = DriverStatus.Inactive,
                Rating = 4.70m,
                TotalTrips = 150,
                TotalRevenue = 8200.00m,
                IsOnline = false
            },
            new Driver
            {
                Id = Guid.Parse("c1b2c3d4-0005-4000-8000-000000000005"),
                KeycloakId = Guid.Parse("a1b2c3d4-0006-4000-8000-000000000006"),
                FirstName = "James",
                LastName = "Brown",
                Email = "james.brown@driveops.com",
                PhoneNumber = "+387 63 200 005",
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
                LicensePlate = "M12-A-345",
                Make = "Toyota",
                Model = "Camry",
                Year = 2022,
                Color = "Silver",
                Vin = "VIN00123456789012",
                InsurancePolicyNumber = "INS-001",
                InsuranceExpiryDate = new DateOnly(2027, 3, 15),
                RegistrationExpiryDate = new DateOnly(2027, 9, 30),
                Status = VehicleStatus.Available,
                Mileage = 45200,
                FuelType = FuelType.Petrol,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[0].Id,   // Marcus
                InternalName = "Taxi no. 12",
                LastServiceDate = now.AddDays(-40)
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0002-4000-8000-000000000002"),
                LicensePlate = "M07-K-118",
                Make = "Honda",
                Model = "Civic",
                Year = 2023,
                Color = "Black",
                Vin = "VIN56789012345678",
                InsurancePolicyNumber = "INS-002",
                InsuranceExpiryDate = new DateOnly(2027, 7, 1),
                RegistrationExpiryDate = new DateOnly(2028, 1, 15),
                Status = VehicleStatus.Available,
                Mileage = 22100,
                FuelType = FuelType.Hybrid,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[1].Id,   // Sarah
                InternalName = "Taxi no. 7",
                LastServiceDate = now.AddDays(-25)
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0003-4000-8000-000000000003"),
                LicensePlate = "M03-T-902",
                Make = "Tesla",
                Model = "Model 3",
                Year = 2023,
                Color = "White",
                Vin = "VIN90123456789012",
                InsurancePolicyNumber = "INS-003",
                InsuranceExpiryDate = new DateOnly(2027, 11, 20),
                RegistrationExpiryDate = new DateOnly(2028, 5, 10),
                Status = VehicleStatus.Available,
                Mileage = 18500,
                FuelType = FuelType.Electric,
                SeatingCapacity = 5,
                AssignedDriverId = drivers[2].Id,   // David (offline)
                InternalName = "Taxi no. 3",
                LastServiceDate = now.AddDays(-60)
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0004-4000-8000-000000000004"),
                LicensePlate = "M21-H-456",
                Make = "Hyundai",
                Model = "Ioniq",
                Year = 2022,
                Color = "Blue",
                Vin = "VIN34567890123456",
                InsurancePolicyNumber = "INS-004",
                InsuranceExpiryDate = new DateOnly(2027, 5, 8),
                RegistrationExpiryDate = new DateOnly(2027, 12, 1),
                Status = VehicleStatus.Available,   // unassigned spare for the assign dialog
                Mileage = 38700,
                FuelType = FuelType.Hybrid,
                SeatingCapacity = 5,
                InternalName = "Taxi no. 21",
                LastServiceDate = now.AddDays(-15)
            },
            new Vehicle
            {
                Id = Guid.Parse("d1b2c3d4-0005-4000-8000-000000000005"),
                LicensePlate = "M09-F-733",
                Make = "Ford",
                Model = "Escape",
                Year = 2021,
                Color = "Red",
                Vin = "VIN78901234567890",
                InsurancePolicyNumber = "INS-005",
                InsuranceExpiryDate = new DateOnly(2026, 12, 31),
                RegistrationExpiryDate = new DateOnly(2027, 6, 30),
                Status = VehicleStatus.Maintenance,
                Mileage = 62000,
                FuelType = FuelType.Petrol,
                SeatingCapacity = 5,
                InternalName = "Taxi no. 9",
                LastServiceDate = now.AddDays(-5)
            }
        };

        await context.Vehicles.AddRangeAsync(vehicles);

        // Fares follow the FareCalculator formula (2.50 + 1.50/km + 0.25/min,
        // Premium x1.5) so seeded numbers are internally consistent.
        var trips = new[]
        {
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0001-4000-8000-000000000001"),
                CustomerId = customers[0].Id,       // johndoe - demo customer, terminal trips only
                DriverId = drivers[0].Id,           // Marcus
                VehicleId = vehicles[0].Id,
                TripStatus = TripStatus.Completed,
                TripType = TripType.Standard,
                PickupLatitude = 43.3428m,
                PickupLongitude = 17.8085m,
                PickupAddress = "Musala, Mostar",
                DropoffLatitude = 43.2829m,
                DropoffLongitude = 17.8459m,
                DropoffAddress = "Mostar International Airport (OMO)",
                RequestedAt = now.AddDays(-3),
                AssignedAt = now.AddDays(-3).AddMinutes(2),
                PickupTime = now.AddDays(-3).AddMinutes(8),
                DropoffTime = now.AddDays(-3).AddMinutes(27),
                EstimatedDistance = 7.6m,
                ActualDistance = 8.1m,
                EstimatedDuration = 18,
                ActualDuration = 19,
                EstimatedFare = 18.40m,
                ActualFare = 19.40m,
                PaymentMethod = PaymentMethod.Cash,
                PaymentStatus = PaymentStatus.Completed,
                CustomerRating = 5,
                DriverRating = 4
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0002-4000-8000-000000000002"),
                CustomerId = customers[0].Id,       // johndoe
                TripStatus = TripStatus.Cancelled,
                TripType = TripType.Standard,
                PickupLatitude = 43.3485m,
                PickupLongitude = 17.8120m,
                PickupAddress = "Rondo, Mostar",
                DropoffLatitude = 43.3371m,
                DropoffLongitude = 17.8154m,
                DropoffAddress = "Stari Most (Old Bridge), Mostar",
                RequestedAt = now.AddDays(-1),
                CancellationReason = "Customer requested cancellation",
                EstimatedDistance = 2.1m,
                EstimatedDuration = 7,
                EstimatedFare = 7.40m,
                PaymentStatus = PaymentStatus.Pending
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0003-4000-8000-000000000003"),
                CustomerId = customers[1].Id,       // janesmith
                DriverId = drivers[1].Id,           // Sarah
                VehicleId = vehicles[1].Id,
                TripStatus = TripStatus.Completed,
                TripType = TripType.Premium,
                PickupLatitude = 43.2570m,
                PickupLongitude = 17.9000m,
                PickupAddress = "Blagaj, Mostar",
                DropoffLatitude = 43.3447m,
                DropoffLongitude = 17.8015m,
                DropoffAddress = "Mostar Bus Station",
                RequestedAt = now.AddDays(-2),
                AssignedAt = now.AddDays(-2).AddMinutes(3),
                PickupTime = now.AddDays(-2).AddMinutes(9),
                DropoffTime = now.AddDays(-2).AddMinutes(35),
                EstimatedDistance = 13.5m,
                ActualDistance = 14.2m,
                EstimatedDuration = 24,
                ActualDuration = 26,
                EstimatedFare = 43.13m,
                ActualFare = 45.45m,
                PaymentMethod = PaymentMethod.Cash,
                PaymentStatus = PaymentStatus.Completed,
                CustomerRating = 5,
                DriverRating = 5
            },
            new Trip
            {
                Id = Guid.Parse("e1b2c3d4-0004-4000-8000-000000000004"),
                CustomerId = customers[2].Id,       // bobwilson
                DriverId = drivers[0].Id,           // Marcus
                VehicleId = vehicles[0].Id,
                TripStatus = TripStatus.Completed,
                TripType = TripType.Standard,
                PickupLatitude = 43.3453m,
                PickupLongitude = 17.7990m,
                PickupAddress = "Mepas Mall, Mostar",
                DropoffLatitude = 43.3485m,
                DropoffLongitude = 17.8120m,
                DropoffAddress = "Rondo, Mostar",
                RequestedAt = now.AddDays(-4),
                AssignedAt = now.AddDays(-4).AddMinutes(2),
                PickupTime = now.AddDays(-4).AddMinutes(6),
                DropoffTime = now.AddDays(-4).AddMinutes(12),
                EstimatedDistance = 1.4m,
                ActualDistance = 1.6m,
                EstimatedDuration = 5,
                ActualDuration = 6,
                EstimatedFare = 5.85m,
                ActualFare = 6.40m,
                PaymentMethod = PaymentMethod.Cash,
                PaymentStatus = PaymentStatus.Completed,
                CustomerRating = 4,
                DriverRating = 5
            },
            new Trip
            {
                // Pre-seeded live request so the dispatcher can demo
                // recommended drivers + assign without touching the mobile app.
                Id = Guid.Parse("e1b2c3d4-0005-4000-8000-000000000005"),
                CustomerId = customers[2].Id,       // bobwilson
                TripStatus = TripStatus.Requested,
                TripType = TripType.Standard,
                PickupLatitude = 43.3371m,
                PickupLongitude = 17.8154m,
                PickupAddress = "Stari Most (Old Bridge), Mostar",
                DropoffLatitude = 43.3447m,
                DropoffLongitude = 17.8015m,
                DropoffAddress = "Mostar Bus Station",
                RequestedAt = now.AddMinutes(-2),
                EstimatedDistance = 2.3m,
                EstimatedDuration = 8,
                EstimatedFare = 7.95m,
                PaymentMethod = PaymentMethod.Cash,
                PaymentStatus = PaymentStatus.Pending
            }
        };

        await context.Trips.AddRangeAsync(trips);

        // Cash ledger rows for the completed trips (no fake Stripe pi_... refs).
        var payments = new[]
        {
            new Payment
            {
                Id = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                TripId = trips[0].Id,
                Amount = 19.40m,
                Method = PaymentMethod.Cash,
                Status = PaymentStatus.Completed,
                CreatedAt = trips[0].DropoffTime,
                ProcessedAt = trips[0].DropoffTime
            },
            new Payment
            {
                Id = Guid.Parse("a1b2c3d4-0002-4000-8000-000000000002"),
                TripId = trips[2].Id,
                Amount = 45.45m,
                Method = PaymentMethod.Cash,
                Status = PaymentStatus.Completed,
                CreatedAt = trips[2].DropoffTime,
                ProcessedAt = trips[2].DropoffTime
            },
            new Payment
            {
                Id = Guid.Parse("a1b2c3d4-0003-4000-8000-000000000003"),
                TripId = trips[3].Id,
                Amount = 6.40m,
                Method = PaymentMethod.Cash,
                Status = PaymentStatus.Completed,
                CreatedAt = trips[3].DropoffTime,
                ProcessedAt = trips[3].DropoffTime
            }
        };

        await context.Payments.AddRangeAsync(payments);

        var defectReports = new[]
        {
            new VehicleDefectReport
            {
                Id = Guid.Parse("f1b2c3d4-0001-4000-8000-000000000001"),
                VehicleId = vehicles[4].Id,
                DriverId = drivers[3].Id,
                Title = "Engine warning light",
                Description = "Check-engine light came on during a shift; vehicle hesitates under acceleration.",
                Severity = DefectSeverity.Critical,
                Status = DefectStatus.Reported,
                ReportedAt = now.AddDays(-2)
            },
            new VehicleDefectReport
            {
                Id = Guid.Parse("f1b2c3d4-0002-4000-8000-000000000002"),
                VehicleId = vehicles[0].Id,
                DriverId = drivers[0].Id,
                Title = "Cracked windshield",
                Description = "Small crack on the passenger side, spreading slowly.",
                Severity = DefectSeverity.Medium,
                Status = DefectStatus.Reported,
                ReportedAt = now.AddDays(-1)
            },
            new VehicleDefectReport
            {
                Id = Guid.Parse("f1b2c3d4-0003-4000-8000-000000000003"),
                VehicleId = vehicles[1].Id,
                DriverId = drivers[1].Id,
                Title = "Wiper blades worn",
                Description = "Front wipers smear in heavy rain.",
                Severity = DefectSeverity.Low,
                Status = DefectStatus.Resolved,
                ReportedAt = now.AddDays(-6),
                ResolvedAt = now.AddDays(-3),
                ResolutionNotes = "Wiper blades replaced at partner garage."
            }
        };

        await context.VehicleDefectReports.AddRangeAsync(defectReports);
        await context.SaveChangesAsync();

        logger.LogInformation("Database seeded with {CustomerCount} customers, {DriverCount} drivers, {VehicleCount} vehicles, {TripCount} trips, {PaymentCount} payments, {DefectCount} defect reports.",
            customers.Length, drivers.Length, vehicles.Length, trips.Length, payments.Length, defectReports.Length);
    }
}
