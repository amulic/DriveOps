using DriveOps.Application.DTOs;
using FluentValidation;

namespace DriveOps.Application.Validation;

public class CreateTripDtoValidator : AbstractValidator<CreateTripDto>
{
    public CreateTripDtoValidator()
    {
        RuleFor(x => x.CustomerId).NotEmpty();
        RuleFor(x => x.PickupLatitude)
            .InclusiveBetween(-90m, 90m)
            .WithMessage("Pickup latitude must be between -90 and 90.");
        RuleFor(x => x.PickupLongitude)
            .InclusiveBetween(-180m, 180m)
            .WithMessage("Pickup longitude must be between -180 and 180.");
        RuleFor(x => x.DropoffLatitude)
            .InclusiveBetween(-90m, 90m)
            .WithMessage("Dropoff latitude must be between -90 and 90.");
        RuleFor(x => x.DropoffLongitude)
            .InclusiveBetween(-180m, 180m)
            .WithMessage("Dropoff longitude must be between -180 and 180.");
        RuleFor(x => x.PickupAddress)
            .NotEmpty().MaximumLength(500);
        RuleFor(x => x.DropoffAddress)
            .NotEmpty().MaximumLength(500);
        RuleFor(x => x.SpecialInstructions)
            .MaximumLength(500).When(x => x.SpecialInstructions != null);
    }
}

public class CreateDriverDtoValidator : AbstractValidator<CreateDriverDto>
{
    public CreateDriverDtoValidator()
    {
        RuleFor(x => x.KeycloakId).NotEmpty();
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(255);
        RuleFor(x => x.PhoneNumber).NotEmpty().MaximumLength(20);
        RuleFor(x => x.LicenseNumber)
            .NotEmpty().MaximumLength(50);
        RuleFor(x => x.LicenseExpiryDate)
            .NotEmpty()
            .Must(d => d >= DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("License must not be expired.");
        RuleFor(x => x.EmergencyContactPhone)
            .MaximumLength(20).When(x => x.EmergencyContactPhone != null);
    }
}

public class OnboardDriverDtoValidator : AbstractValidator<OnboardDriverDto>
{
    public OnboardDriverDtoValidator()
    {
        RuleFor(x => x.Username).NotEmpty().MinimumLength(3).MaximumLength(50);
        RuleFor(x => x.TemporaryPassword).NotEmpty().MinimumLength(8).MaximumLength(128)
            .WithMessage("Temporary password must be at least 8 characters.");
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(255);
        RuleFor(x => x.PhoneNumber).NotEmpty().MaximumLength(20);
        RuleFor(x => x.LicenseNumber).NotEmpty().MaximumLength(50);
        RuleFor(x => x.LicenseExpiryDate)
            .NotEmpty()
            .Must(d => d >= DateOnly.FromDateTime(DateTime.UtcNow))
            .WithMessage("License must not be expired.");
        RuleFor(x => x.EmergencyContactPhone)
            .MaximumLength(20).When(x => x.EmergencyContactPhone != null);
    }
}

public class CreateVehicleDtoValidator : AbstractValidator<CreateVehicleDto>
{
    public CreateVehicleDtoValidator()
    {
        RuleFor(x => x.LicensePlate)
            .NotEmpty().MaximumLength(20);
        RuleFor(x => x.Make)
            .NotEmpty().MaximumLength(50);
        RuleFor(x => x.Model)
            .NotEmpty().MaximumLength(50);
        RuleFor(x => x.Year)
            .InclusiveBetween(1900, DateTime.UtcNow.Year + 1);
        RuleFor(x => x.Color)
            .NotEmpty().MaximumLength(30);
        RuleFor(x => x.Vin)
            .NotEmpty().Length(17)
            .WithMessage("VIN must be exactly 17 characters.");
        RuleFor(x => x.InsurancePolicyNumber)
            .NotEmpty().MaximumLength(50);
        RuleFor(x => x.InsuranceExpiryDate)
            .NotEmpty();
        RuleFor(x => x.RegistrationExpiryDate)
            .NotEmpty();
    }
}

public class UpdateDriverLocationDtoValidator : AbstractValidator<UpdateDriverLocationDto>
{
    public UpdateDriverLocationDtoValidator()
    {
        RuleFor(x => x.DriverId).NotEmpty();
        RuleFor(x => x.Latitude)
            .InclusiveBetween(-90m, 90m);
        RuleFor(x => x.Longitude)
            .InclusiveBetween(-180m, 180m);
    }
}

public class RateTripDtoValidator : AbstractValidator<RateTripDto>
{
    public RateTripDtoValidator()
    {
        RuleFor(x => x.TripId).NotEmpty();
        RuleFor(x => x.Rating)
            .InclusiveBetween(1, 5)
            .WithMessage("Rating must be between 1 and 5.");
        RuleFor(x => x.Feedback)
            .MaximumLength(1000).When(x => x.Feedback != null);
    }
}