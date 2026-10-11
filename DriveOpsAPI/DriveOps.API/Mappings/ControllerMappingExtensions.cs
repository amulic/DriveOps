using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.ControllerDtos.Response;
using DriveOps.Application.DTOs;

namespace DriveOps.API.Mappings
{
    public static class ControllerMappingExtensions
    {
        // ── Driver ──
        public static CreateDriverDto ToApplicationDto(this CreateDriverRequest request) => new()
        {
            KeycloakId = request.KeycloakId,
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            LicenseNumber = request.LicenseNumber,
            LicenseExpiryDate = request.LicenseExpiryDate,
            EmergencyContactName = request.EmergencyContactName,
            EmergencyContactPhone = request.EmergencyContactPhone
        };

        public static OnboardDriverDto ToApplicationDto(this OnboardDriverRequest request) => new()
        {
            Username = request.Username,
            TemporaryPassword = request.TemporaryPassword,
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            LicenseNumber = request.LicenseNumber,
            LicenseExpiryDate = request.LicenseExpiryDate,
            EmergencyContactName = request.EmergencyContactName,
            EmergencyContactPhone = request.EmergencyContactPhone
        };

        public static UpdateDriverDto ToApplicationDto(this UpdateDriverRequest request, Guid driverId) => new()
        {
            Id = driverId,
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            LicenseNumber = request.LicenseNumber,
            LicenseExpiryDate = request.LicenseExpiryDate,
            EmergencyContactName = request.EmergencyContactName,
            EmergencyContactPhone = request.EmergencyContactPhone
        };

        public static UpdateDriverLocationDto ToApplicationDto(this UpdateDriverLocationRequest request, Guid driverId) => new()
        {
            DriverId = driverId,
            Latitude = request.Latitude,
            Longitude = request.Longitude
        };

        public static DriverResponse ToResponse(this DriverDto dto) => new()
        {
            Id = dto.Id,
            KeycloakId = dto.KeycloakId,
            DriverName = dto.DriverName,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email,
            PhoneNumber = dto.PhoneNumber,
            LicenseNumber = dto.LicenseNumber,
            LicenseExpiryDate = dto.LicenseExpiryDate,
            EmergencyContactName = dto.EmergencyContactName,
            EmergencyContactPhone = dto.EmergencyContactPhone,
            Status = dto.Status,
            Rating = dto.Rating,
            TotalTrips = dto.TotalTrips,
            TotalRevenue = dto.TotalRevenue,
            IsOnline = dto.IsOnline,
            CurrentLatitude = dto.CurrentLatitude,
            CurrentLongitude = dto.CurrentLongitude,
            ProfileImageUrl = dto.ProfileImageUrl,
            CreatedAt = dto.CreatedAt
        };

        public static KeycloakCandidateResponse ToResponse(this PromotionCandidateDto dto) => new()
        {
            KeycloakId = dto.KeycloakId,
            Username = dto.Username,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email,
            RealmRoles = dto.RealmRoles,
            HasDriverProfile = dto.HasDriverProfile
        };

        // ── Customer ──
        public static CreateCustomerDto ToApplicationDto(this CreateCustomerRequest request) => new()
        {
            KeycloakId = request.KeycloakId,
            Name = request.Name,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email,
            PreferredPaymentMethod = request.PreferredPaymentMethod
        };

        public static UpdateCustomerDto ToApplicationDto(this UpdateCustomerRequest request, Guid customerId) => new()
        {
            Id = customerId,
            Name = request.Name,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email,
            PreferredPaymentMethod = request.PreferredPaymentMethod
        };

        public static CustomerResponse ToResponse(this CustomerDto dto) => new()
        {
            Id = dto.Id,
            KeycloakId = dto.KeycloakId,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
            Email = dto.Email,
            Rating = dto.Rating,
            TotalTrips = dto.TotalTrips,
            PreferredPaymentMethod = dto.PreferredPaymentMethod,
            CreatedAt = dto.CreatedAt
        };

        // ── Vehicle ──
        public static CreateVehicleDto ToApplicationDto(this CreateVehicleRequest request) => new()
        {
            LicensePlate = request.LicensePlate,
            Make = request.Make,
            Model = request.Model,
            Year = request.Year,
            Color = request.Color,
            Vin = request.Vin,
            InsurancePolicyNumber = request.InsurancePolicyNumber,
            InsuranceExpiryDate = request.InsuranceExpiryDate,
            RegistrationExpiryDate = request.RegistrationExpiryDate,
            FuelType = request.FuelType,
            SeatingCapacity = request.SeatingCapacity,
            PhotoUrl = request.PhotoUrl,
            InternalName = request.InternalName,
            LastServiceDate = request.LastServiceDate
        };

        public static UpdateVehicleDto ToApplicationDto(this UpdateVehicleRequest request, Guid vehicleId) => new()
        {
            Id = vehicleId,
            Color = request.Color,
            InsurancePolicyNumber = request.InsurancePolicyNumber,
            InsuranceExpiryDate = request.InsuranceExpiryDate,
            RegistrationExpiryDate = request.RegistrationExpiryDate,
            Status = request.Status,
            Mileage = request.Mileage,
            PhotoUrl = request.PhotoUrl,
            InternalName = request.InternalName,
            LastServiceDate = request.LastServiceDate
        };

        public static VehicleResponse ToResponse(this VehicleDto dto) => new()
        {
            Id = dto.Id,
            LicensePlate = dto.LicensePlate,
            Make = dto.Make,
            Model = dto.Model,
            Year = dto.Year,
            Color = dto.Color,
            Vin = dto.Vin,
            InsurancePolicyNumber = dto.InsurancePolicyNumber,
            InsuranceExpiryDate = dto.InsuranceExpiryDate,
            RegistrationExpiryDate = dto.RegistrationExpiryDate,
            Status = dto.Status,
            Mileage = dto.Mileage,
            FuelType = dto.FuelType,
            SeatingCapacity = dto.SeatingCapacity,
            AssignedDriverId = dto.AssignedDriverId,
            AssignedDriverName = dto.AssignedDriverName,
            PhotoUrl = dto.PhotoUrl,
            InternalName = dto.InternalName,
            LastServiceDate = dto.LastServiceDate,
            CreatedAt = dto.CreatedAt
        };

        public static VehicleDefectReportResponse ToResponse(this VehicleDefectReportDto dto) => new()
        {
            Id = dto.Id,
            VehicleId = dto.VehicleId,
            DriverId = dto.DriverId,
            DriverName = dto.DriverName,
            Title = dto.Title,
            Description = dto.Description,
            Severity = dto.Severity,
            Status = dto.Status,
            ReportedAt = dto.ReportedAt,
            ResolvedAt = dto.ResolvedAt
        };

        // ── Trip ──
        public static CreateTripDto ToApplicationDto(this CreateTripRequest request) => new()
        {
            CustomerId = request.CustomerId,
            TripType = request.TripType,
            PickupLatitude = request.PickupLatitude,
            PickupLongitude = request.PickupLongitude,
            PickupAddress = request.PickupAddress,
            DropoffLatitude = request.DropoffLatitude,
            DropoffLongitude = request.DropoffLongitude,
            DropoffAddress = request.DropoffAddress,
            ScheduledAt = request.ScheduledAt,
            PaymentMethod = request.PaymentMethod,
            SpecialInstructions = request.SpecialInstructions
        };

        public static TripResponse ToResponse(this TripDto dto) => new()
        {
            Id = dto.Id,
            CustomerId = dto.CustomerId,
            CustomerName = dto.CustomerName,
            DriverId = dto.DriverId,
            DriverName = dto.DriverName,
            VehicleId = dto.VehicleId,
            VehiclePlate = dto.VehiclePlate,
            TripStatus = dto.TripStatus,
            TripType = dto.TripType,
            PickupLatitude = dto.PickupLatitude,
            PickupLongitude = dto.PickupLongitude,
            PickupAddress = dto.PickupAddress,
            DropoffLatitude = dto.DropoffLatitude,
            DropoffLongitude = dto.DropoffLongitude,
            DropoffAddress = dto.DropoffAddress,
            RequestedAt = dto.RequestedAt,
            ScheduledAt = dto.ScheduledAt,
            PickupTime = dto.PickupTime,
            DropoffTime = dto.DropoffTime,
            EstimatedDistance = dto.EstimatedDistance,
            ActualDistance = dto.ActualDistance,
            EstimatedDuration = dto.EstimatedDuration,
            ActualDuration = dto.ActualDuration,
            EstimatedFare = dto.EstimatedFare,
            ActualFare = dto.ActualFare,
            PaymentMethod = dto.PaymentMethod,
            PaymentStatus = dto.PaymentStatus,
            CustomerRating = dto.CustomerRating,
            DriverRating = dto.DriverRating,
            CancellationReason = dto.CancellationReason,
            CreatedAt = dto.CreatedAt
        };

        public static TripEstimateResponse ToResponse(this TripEstimateDto dto) => new()
        {
            DistanceKm = dto.DistanceKm,
            DurationMinutes = dto.DurationMinutes,
            EstimatedFare = dto.EstimatedFare,
            RoutePoints = dto.RoutePoints.Select(p => new RoutePointResponse
            {
                Latitude = p.Latitude,
                Longitude = p.Longitude,
                Timestamp = p.Timestamp
            }).ToList()
        };

        public static RoutePointResponse ToResponse(this RoutePointDto dto) => new()
        {
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            Timestamp = dto.Timestamp
        };
    }
}
