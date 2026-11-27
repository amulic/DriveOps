using DriveOps.Application.DTOs;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Helpers
{
    /// <summary>
    /// Single source of truth for the service/inspection reminder rules shared by
    /// the reminders endpoint and the fleet notifications.
    /// </summary>
    public static class VehicleReminderHelper
    {
        public const int ServiceIntervalDays = 180;
        public const decimal MileageServiceIntervalKm = 10_000m;
        public const int ExpiryWarningDays = 30;

        public static bool IsMileageServiceDue(Vehicle vehicle, VehicleServiceRecord? latestRecord)
        {
            if (vehicle.Mileage is null || latestRecord?.OdometerKm is null)
                return false;

            return vehicle.Mileage.Value - latestRecord.OdometerKm.Value >= MileageServiceIntervalKm;
        }

        public static List<VehicleServiceReminderDto> Evaluate(
            Vehicle vehicle,
            VehicleServiceRecord? latestRecord,
            bool hasOpenHighSeverityDefects,
            DateTime now)
        {
            var reminders = new List<VehicleServiceReminderDto>();
            var today = DateOnly.FromDateTime(now);

            string? serviceReason = null;
            DateTime? serviceDueAt = null;

            if (vehicle.Status == VehicleStatus.Maintenance)
            {
                serviceReason = "Vehicle is marked for maintenance.";
            }
            else if (vehicle.LastServiceDate is null)
            {
                serviceReason = "No service history recorded.";
            }
            else
            {
                var lastService = vehicle.LastServiceDate.Value;
                var dueAt = lastService.AddDays(ServiceIntervalDays);

                if (dueAt <= now)
                {
                    serviceReason = $"Last service was {(now - lastService).Days} days ago.";
                    serviceDueAt = dueAt;
                }
                else if (IsMileageServiceDue(vehicle, latestRecord))
                {
                    serviceReason = $"More than {MileageServiceIntervalKm:0} km since the last service.";
                }
            }

            if (serviceReason is null && IsMileageServiceDue(vehicle, latestRecord))
                serviceReason = $"More than {MileageServiceIntervalKm:0} km since the last service.";

            if (serviceReason is not null)
            {
                reminders.Add(new VehicleServiceReminderDto
                {
                    VehicleId = vehicle.Id,
                    LicensePlate = vehicle.LicensePlate,
                    Make = vehicle.Make,
                    Model = vehicle.Model,
                    Type = "Service",
                    Reason = serviceReason,
                    DueAt = serviceDueAt
                });
            }

            var inspectionParts = new List<string>();
            var warningDate = today.AddDays(ExpiryWarningDays);

            if (vehicle.InsuranceExpiryDate < today)
                inspectionParts.Add($"Insurance expired on {vehicle.InsuranceExpiryDate:yyyy-MM-dd}.");
            else if (vehicle.InsuranceExpiryDate <= warningDate)
                inspectionParts.Add($"Insurance expires on {vehicle.InsuranceExpiryDate:yyyy-MM-dd}.");

            if (vehicle.RegistrationExpiryDate < today)
                inspectionParts.Add($"Registration expired on {vehicle.RegistrationExpiryDate:yyyy-MM-dd}.");
            else if (vehicle.RegistrationExpiryDate <= warningDate)
                inspectionParts.Add($"Registration expires on {vehicle.RegistrationExpiryDate:yyyy-MM-dd}.");

            if (hasOpenHighSeverityDefects)
                inspectionParts.Add("Open high-severity defect reports require inspection.");

            if (inspectionParts.Count > 0)
            {
                reminders.Add(new VehicleServiceReminderDto
                {
                    VehicleId = vehicle.Id,
                    LicensePlate = vehicle.LicensePlate,
                    Make = vehicle.Make,
                    Model = vehicle.Model,
                    Type = "Inspection",
                    Reason = string.Join(" ", inspectionParts),
                    DueAt = null
                });
            }

            return reminders;
        }
    }
}
