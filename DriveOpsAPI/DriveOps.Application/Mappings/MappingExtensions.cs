using DriveOps.Application.DTOs;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Mappings
{
    public static class MappingExtensions
    {
        // ── User ──
        public static UserDto ToDto(this User user) => new()
        {
            Id = user.Id,
            KeycloakId = user.KeycloakId,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName,
            PhoneNumber = user.PhoneNumber,
            UserType = user.UserType,
            IsActive = user.IsActive,
            ProfileImageUrl = user.ProfileImageUrl,
            Address = user.Address,
            DateOfBirth = user.DateOfBirth,
            CreatedAt = user.CreatedAt
        };

        public static User ToEntity(this CreateUserDto dto) => new()
        {
            Id = Guid.NewGuid(),
            Email = dto.Email,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            PhoneNumber = dto.PhoneNumber,
            UserType = dto.UserType,
            PasswordHash = "KEYCLOAK_MANAGED",
            ProfileImageUrl = dto.ProfileImageUrl,
            Address = dto.Address,
            DateOfBirth = dto.DateOfBirth,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── Driver ──
        public static DriverDto ToDto(this Driver driver) => new()
        {
            Id = driver.Id,
            UserId = driver.UserId,
            DriverName = driver.User != null
                ? $"{driver.User.FirstName} {driver.User.LastName}"
                : string.Empty,
            Email = driver.User?.Email ?? string.Empty,
            PhoneNumber = driver.User?.PhoneNumber ?? string.Empty,
            LicenseNumber = driver.LicenseNumber,
            LicenseExpiryDate = driver.LicenseExpiryDate,
            EmergencyContactName = driver.EmergencyContactName,
            EmergencyContactPhone = driver.EmergencyContactPhone,
            Status = driver.Status,
            Rating = driver.Rating,
            TotalTrips = driver.TotalTrips,
            TotalRevenue = driver.TotalRevenue,
            IsOnline = driver.IsOnline,
            CurrentLatitude = driver.CurrentLatitude,
            CurrentLongitude = driver.CurrentLongitude,
            LastLocationUpdate = driver.LastLocationUpdate,
            CreatedAt = driver.CreatedAt
        };

        public static Driver ToEntity(this CreateDriverDto dto) => new()
        {
            Id = Guid.NewGuid(),
            UserId = dto.UserId,
            LicenseNumber = dto.LicenseNumber,
            LicenseExpiryDate = dto.LicenseExpiryDate,
            EmergencyContactName = dto.EmergencyContactName,
            EmergencyContactPhone = dto.EmergencyContactPhone,
            Status = 0, // Pending
            IsOnline = false,
            Rating = 5.00m,
            TotalTrips = 0,
            TotalRevenue = 0m,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── Customer ──
        public static CustomerDto ToDto(this Customer customer) => new()
        {
            Id = customer.Id,
            UserId = customer.UserId,
            Name = customer.Name,
            PhoneNumber = customer.PhoneNumber,
            Email = customer.Email,
            Rating = customer.Rating,
            TotalTrips = customer.TotalTrips,
            PreferredPaymentMethod = customer.PreferredPaymentMethod,
            CreatedAt = customer.CreatedAt
        };

        public static Customer ToEntity(this CreateCustomerDto dto) => new()
        {
            Id = Guid.NewGuid(),
            UserId = dto.UserId,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
            Email = dto.Email,
            PreferredPaymentMethod = dto.PreferredPaymentMethod,
            Rating = 5.00m,
            TotalTrips = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── Vehicle ──
        public static VehicleDto ToDto(this Vehicle vehicle) => new()
        {
            Id = vehicle.Id,
            LicensePlate = vehicle.LicensePlate,
            Make = vehicle.Make,
            Model = vehicle.Model,
            Year = vehicle.Year,
            Color = vehicle.Color,
            Vin = vehicle.Vin,
            InsurancePolicyNumber = vehicle.InsurancePolicyNumber,
            InsuranceExpiryDate = vehicle.InsuranceExpiryDate,
            RegistrationExpiryDate = vehicle.RegistrationExpiryDate,
            Status = vehicle.Status,
            Mileage = vehicle.Mileage,
            FuelType = vehicle.FuelType,
            SeatingCapacity = vehicle.SeatingCapacity,
            AssignedDriverId = vehicle.AssignedDriverId,
            AssignedDriverName = vehicle.AssignedDriver?.User != null
                ? $"{vehicle.AssignedDriver.User.FirstName} {vehicle.AssignedDriver.User.LastName}"
                : null,
            CreatedAt = vehicle.CreatedAt
        };

        public static Vehicle ToEntity(this CreateVehicleDto dto) => new()
        {
            Id = Guid.NewGuid(),
            LicensePlate = dto.LicensePlate,
            Make = dto.Make,
            Model = dto.Model,
            Year = dto.Year,
            Color = dto.Color,
            Vin = dto.Vin,
            InsurancePolicyNumber = dto.InsurancePolicyNumber,
            InsuranceExpiryDate = dto.InsuranceExpiryDate,
            RegistrationExpiryDate = dto.RegistrationExpiryDate,
            FuelType = dto.FuelType,
            SeatingCapacity = dto.SeatingCapacity ?? 4,
            Status = VehicleStatus.Available,
            Mileage = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── Trip ──
        public static TripDto ToDto(this Trip trip) => new()
        {
            Id = trip.Id,
            CustomerId = trip.CustomerId,
            CustomerName = trip.Customer?.Name,
            DriverId = trip.DriverId,
            DriverName = trip.Driver?.User != null
                ? $"{trip.Driver.User.FirstName} {trip.Driver.User.LastName}"
                : null,
            VehicleId = trip.VehicleId,
            VehiclePlate = trip.Vehicle?.LicensePlate,
            TripStatus = trip.TripStatus,
            TripType = trip.TripType,
            PickupLatitude = trip.PickupLatitude,
            PickupLongitude = trip.PickupLongitude,
            PickupAddress = trip.PickupAddress,
            DropoffLatitude = trip.DropoffLatitude,
            DropoffLongitude = trip.DropoffLongitude,
            DropoffAddress = trip.DropoffAddress,
            RequestedAt = trip.RequestedAt,
            ScheduledAt = trip.ScheduledAt,
            PickupTime = trip.PickupTime,
            DropoffTime = trip.DropoffTime,
            EstimatedDistance = trip.EstimatedDistance,
            ActualDistance = trip.ActualDistance,
            EstimatedDuration = trip.EstimatedDuration,
            ActualDuration = trip.ActualDuration,
            EstimatedFare = trip.EstimatedFare,
            ActualFare = trip.ActualFare,
            PaymentMethod = trip.PaymentMethod,
            PaymentStatus = trip.PaymentStatus,
            CustomerRating = trip.CustomerRating,
            DriverRating = trip.DriverRating,
            CancellationReason = trip.CancellationReason,
            CreatedAt = trip.CreatedAt
        };

        public static Trip ToEntity(this CreateTripDto dto) => new()
        {
            Id = Guid.NewGuid(),
            CustomerId = dto.CustomerId,
            TripType = dto.TripType,
            TripStatus = TripStatus.Requested,
            PickupLatitude = dto.PickupLatitude,
            PickupLongitude = dto.PickupLongitude,
            PickupAddress = dto.PickupAddress,
            DropoffLatitude = dto.DropoffLatitude,
            DropoffLongitude = dto.DropoffLongitude,
            DropoffAddress = dto.DropoffAddress,
            ScheduledAt = dto.ScheduledAt,
            PaymentMethod = dto.PaymentMethod,
            SpecialInstructions = dto.SpecialInstructions,
            PaymentStatus = PaymentStatus.Pending,
            RequestedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // ── TripRoute ──
        public static RoutePointDto ToDto(this TripRoute routePoint) => new()
        {
            Latitude = routePoint.Latitude,
            Longitude = routePoint.Longitude,
            Timestamp = routePoint.Timestamp
        };
    }
}
