using DriveOps.Application.DTOs;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Helpers;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using DriveOps.RealTime.Contracts.Events;
using FluentValidation;

namespace DriveOps.Application.Services
{
    public class VehicleService : IVehicleService
    {
        private readonly IVehicleRepository _vehicleRepository;
        private readonly IDriverRepository _driverRepository;
        private readonly IVehicleDefectReportRepository _vehicleDefectReportRepository;
        private readonly IVehicleServiceRecordRepository _vehicleServiceRecordRepository;
        private readonly ITripRepository _tripRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IEventPublisher _eventPublisher;
        private readonly IValidator<CreateVehicleDto> _createVehicleValidator;
        private readonly IValidator<UpdateVehicleDto> _updateVehicleValidator;

        public VehicleService(
            IVehicleRepository vehicleRepository,
            IDriverRepository driverRepository,
            IVehicleDefectReportRepository vehicleDefectReportRepository,
            IVehicleServiceRecordRepository vehicleServiceRecordRepository,
            ITripRepository tripRepository,
            IUnitOfWork unitOfWork,
            IEventPublisher eventPublisher,
            IValidator<CreateVehicleDto> createVehicleValidator,
            IValidator<UpdateVehicleDto> updateVehicleValidator)
        {
            _vehicleRepository = vehicleRepository;
            _driverRepository = driverRepository;
            _vehicleDefectReportRepository = vehicleDefectReportRepository;
            _vehicleServiceRecordRepository = vehicleServiceRecordRepository;
            _tripRepository = tripRepository;
            _unitOfWork = unitOfWork;
            _eventPublisher = eventPublisher;
            _createVehicleValidator = createVehicleValidator;
            _updateVehicleValidator = updateVehicleValidator;
        }

        public async Task<VehicleDto?> GetVehicleByIdAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId);
            return vehicle?.ToDto();
        }

        public async Task<PaginatedResult<VehicleDto>> GetAllVehiclesAsync(int page = 1, int pageSize = 20)
        {
            var vehicles = await _vehicleRepository.GetAllAsync(page, pageSize);
            var total = await _vehicleRepository.CountAsync();
            return new PaginatedResult<VehicleDto>
            {
                Items = vehicles.Select(v => v.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<PaginatedResult<VehicleDto>> GetAvailableVehiclesAsync(int page = 1, int pageSize = 20)
        {
            var vehicles = await _vehicleRepository.GetAvailableVehiclesAsync(page, pageSize);
            var total = await _vehicleRepository.CountAsync(v =>
                v.Status == VehicleStatus.Available && v.AssignedDriverId == null);
            return new PaginatedResult<VehicleDto>
            {
                Items = vehicles.Select(v => v.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<VehicleDto> CreateVehicleAsync(CreateVehicleDto dto)
        {
            // Apply the defined VIN/year/length rules before any write.
            await _createVehicleValidator.ValidateAndThrowAsync(dto);

            var existingPlate = await _vehicleRepository.GetByLicensePlateAsync(dto.LicensePlate);
            if (existingPlate != null)
                throw new InvalidOperationException($"Vehicle with license plate '{dto.LicensePlate}' already exists.");

            var existingVin = await _vehicleRepository.GetByVinAsync(dto.Vin);
            if (existingVin != null)
                throw new InvalidOperationException($"Vehicle with VIN '{dto.Vin}' already exists.");

            var vehicle = dto.ToEntity();
            await _vehicleRepository.AddAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            await PublishRemindersAsync(vehicle);
            return vehicle.ToDto();
        }

        public async Task<VehicleDto> UpdateVehicleAsync(UpdateVehicleDto dto)
        {
            await _updateVehicleValidator.ValidateAndThrowAsync(dto);

            var vehicle = await _vehicleRepository.GetByIdAsync(dto.Id)
                  ?? throw new KeyNotFoundException($"Vehicle {dto.Id} not found.");

            if (!string.IsNullOrWhiteSpace(dto.LicensePlate)
                && !string.Equals(dto.LicensePlate, vehicle.LicensePlate, StringComparison.OrdinalIgnoreCase))
            {
                var existingPlate = await _vehicleRepository.GetByLicensePlateAsync(dto.LicensePlate);
                if (existingPlate != null && existingPlate.Id != vehicle.Id)
                    throw new InvalidOperationException($"Vehicle with license plate '{dto.LicensePlate}' already exists.");
            }

            if (!string.IsNullOrWhiteSpace(dto.Vin)
                && !string.Equals(dto.Vin, vehicle.Vin, StringComparison.OrdinalIgnoreCase))
            {
                var existingVin = await _vehicleRepository.GetByVinAsync(dto.Vin);
                if (existingVin != null && existingVin.Id != vehicle.Id)
                    throw new InvalidOperationException($"Vehicle with VIN '{dto.Vin}' already exists.");
            }

            if (dto.LicensePlate != null) vehicle.LicensePlate = dto.LicensePlate;
            if (dto.Make != null) vehicle.Make = dto.Make;
            if (dto.Model != null) vehicle.Model = dto.Model;
            if (dto.Year.HasValue) vehicle.Year = dto.Year.Value;
            if (dto.Vin != null) vehicle.Vin = dto.Vin;
            if (dto.FuelType.HasValue) vehicle.FuelType = dto.FuelType.Value;
            if (dto.SeatingCapacity.HasValue) vehicle.SeatingCapacity = dto.SeatingCapacity;
            if (dto.Color != null) vehicle.Color = dto.Color;
            if (dto.InsurancePolicyNumber != null) vehicle.InsurancePolicyNumber = dto.InsurancePolicyNumber;
            if (dto.InsuranceExpiryDate.HasValue) vehicle.InsuranceExpiryDate = dto.InsuranceExpiryDate.Value;
            if (dto.RegistrationExpiryDate.HasValue) vehicle.RegistrationExpiryDate = dto.RegistrationExpiryDate.Value;
            if (dto.Status.HasValue) vehicle.Status = dto.Status;
            if (dto.Mileage.HasValue) vehicle.Mileage = dto.Mileage;
            if (dto.PhotoUrl != null) vehicle.PhotoUrl = dto.PhotoUrl;
            if (dto.InternalName != null) vehicle.InternalName = dto.InternalName;
            if (dto.LastServiceDate.HasValue) vehicle.LastServiceDate = dto.LastServiceDate;
            vehicle.UpdatedAt = DateTime.UtcNow;

            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            await PublishRemindersAsync(vehicle);
            return vehicle.ToDto();
        }

        public async Task<VehicleDto> AssignVehicleToDriverAsync(Guid vehicleId, Guid driverId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            if (vehicle.Status == VehicleStatus.Retired)
                throw new InvalidOperationException("Cannot assign a retired vehicle.");

            // Assignment (zaduženje) is independent from trip usage: a vehicle may be
            // assigned to a driver while still Available, but it must never be moved
            // between drivers while an active trip is using it.
            if (vehicle.Status == VehicleStatus.InUse || await _tripRepository.HasActiveTripForVehicleAsync(vehicleId))
                throw new InvalidOperationException(
                    $"Vehicle {vehicle.LicensePlate} is on an active trip. Complete or cancel it before changing the assignment.");

            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            var previousDriverId = vehicle.AssignedDriverId;

            // One vehicle per driver: release the driver's current vehicle(s) without
            // touching their operational status.
            var currentVehicles = (await _vehicleRepository.GetByDriverIdAsync(driverId))
                .Where(v => v.Id != vehicleId)
                .ToList();

            foreach (var currentVehicle in currentVehicles)
            {
                if (currentVehicle.Status == VehicleStatus.InUse
                    || await _tripRepository.HasActiveTripForVehicleAsync(currentVehicle.Id))
                    throw new InvalidOperationException(
                        $"Driver's current vehicle {currentVehicle.LicensePlate} is on an active trip. Cannot reassign now.");
            }

            var previousVehicleId = currentVehicles.FirstOrDefault()?.Id;

            foreach (var currentVehicle in currentVehicles)
            {
                currentVehicle.AssignedDriverId = null;
                currentVehicle.UpdatedAt = DateTime.UtcNow;
                await _vehicleRepository.UpdateAsync(currentVehicle);
            }

            vehicle.AssignedDriverId = driverId;
            // Do NOT set Status = InUse here — that state belongs to active trips.
            vehicle.UpdatedAt = DateTime.UtcNow;
            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.assigned",
                new VehicleAssignedEvent(
                    vehicle.Id, vehicle.LicensePlate, vehicle.Make, vehicle.Model,
                    previousDriverId,
                    driverId,
                    $"{driver.FirstName} {driver.LastName}".Trim(),
                    previousVehicleId,
                    DateTime.UtcNow));

            return vehicle.ToDto();
        }

        public async Task<VehicleDto> UnassignVehicleAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            if (vehicle.Status == VehicleStatus.InUse || await _tripRepository.HasActiveTripForVehicleAsync(vehicleId))
                throw new InvalidOperationException(
                    $"Vehicle {vehicle.LicensePlate} is on an active trip. Complete or cancel it before unassigning.");

            var previousDriverId = vehicle.AssignedDriverId;
            var previousDriver = previousDriverId.HasValue ? await _driverRepository.GetByIdAsync(previousDriverId.Value) : null;

            vehicle.AssignedDriverId = null;
            // Operational status is left unchanged (Available/Maintenance/Retired).
            vehicle.UpdatedAt = DateTime.UtcNow;

            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();

            if (previousDriverId.HasValue)
            {
                await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.unassigned",
                    new VehicleUnassignedEvent(
                        vehicle.Id, vehicle.LicensePlate, vehicle.Make, vehicle.Model,
                        previousDriverId.Value,
                        previousDriver != null ? $"{previousDriver.FirstName} {previousDriver.LastName}" : string.Empty,
                        DateTime.UtcNow));
            }

            return vehicle.ToDto();
        }

        public async Task DeleteVehicleAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            var tripCount = await _tripRepository.CountByVehicleIdAsync(vehicleId);
            var defectCount = await _vehicleDefectReportRepository.CountByVehicleIdAsync(vehicleId);
            var serviceCount = await _vehicleServiceRecordRepository.CountByVehicleIdAsync(vehicleId);

            if (tripCount > 0 || defectCount > 0 || serviceCount > 0)
                throw new VehicleHasDependenciesException(
                    $"Vehicle {vehicle.LicensePlate} cannot be deleted: it is referenced by {tripCount} trip(s), " +
                    $"{defectCount} defect report(s) and {serviceCount} service record(s). " +
                    "Retire the vehicle instead so its history is preserved.");

            await _vehicleRepository.DeleteAsync(vehicleId);
            await _unitOfWork.SaveChangesAsync();
        }

        public async Task<VehicleDefectReportDto> ReportVehicleDefectAsync(ReportVehicleDefectDto dto)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(dto.VehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {dto.VehicleId} not found.");

            var driver = await _driverRepository.GetByIdAsync(dto.DriverId)
                ?? throw new KeyNotFoundException($"Driver {dto.DriverId} not found.");

            var report = new DriveOps.Model.Entity.VehicleDefectReport
            {
                Id = Guid.NewGuid(),
                VehicleId = dto.VehicleId,
                DriverId = dto.DriverId,
                Title = dto.Title,
                Description = dto.Description,
                Severity = dto.Severity,
                Status = DefectStatus.Reported,
                ReportedAt = DateTime.UtcNow
            };

            await _vehicleDefectReportRepository.AddAsync(report);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.defect.reported",
                new VehicleDefectReportedEvent(
                    report.Id,
                    vehicle.Id,
                    vehicle.LicensePlate,
                    driver.Id,
                    $"{driver.FirstName} {driver.LastName}",
                    report.Title,
                    (int)report.Severity,
                    report.ReportedAt));

            await PublishRemindersAsync(vehicle);

            report.Driver = driver;
            report.Vehicle = vehicle;
            return report.ToDto();
        }

        public async Task<PaginatedResult<VehicleDefectReportDto>> GetVehicleDefectsAsync(Guid vehicleId, int page = 1, int pageSize = 20)
        {
            var vehicleExists = await _vehicleRepository.ExistsAsync(vehicleId);
            if (!vehicleExists)
                throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            var reports = await _vehicleDefectReportRepository.GetByVehicleIdAsync(vehicleId, page, pageSize);
            var total = await _vehicleDefectReportRepository.CountByVehicleIdAsync(vehicleId);
            return new PaginatedResult<VehicleDefectReportDto>
            {
                Items = reports.Select(r => r.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<PaginatedResult<VehicleDefectReportDto>> GetDefectsAsync(string? status, DefectSeverity? severity, Guid? vehicleId, Guid? driverId, int page = 1, int pageSize = 20)
        {
            var reports = await _vehicleDefectReportRepository.GetFilteredAsync(status, severity, vehicleId, driverId, page, pageSize);
            var total = await _vehicleDefectReportRepository.CountFilteredAsync(status, severity, vehicleId, driverId);
            return new PaginatedResult<VehicleDefectReportDto>
            {
                Items = reports.Select(r => r.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<VehicleDefectReportDto> ResolveDefectAsync(Guid defectId, string? resolutionNotes)
        {
            var report = await _vehicleDefectReportRepository.GetByIdWithDetailsAsync(defectId)
                ?? throw new KeyNotFoundException($"Defect report {defectId} not found.");

            if (report.Status == DefectStatus.Resolved)
                throw new InvalidOperationException("Defect report is already resolved.");

            report.Status = DefectStatus.Resolved;
            report.ResolvedAt = DateTime.UtcNow;
            report.ResolutionNotes = resolutionNotes;

            await _vehicleDefectReportRepository.UpdateAsync(report);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.defect.resolved",
                new VehicleDefectResolvedEvent(
                    report.Id,
                    report.VehicleId,
                    report.Vehicle?.LicensePlate ?? string.Empty,
                    report.DriverId,
                    report.Driver != null ? $"{report.Driver.FirstName} {report.Driver.LastName}" : string.Empty,
                    report.Title,
                    false,
                    DateTime.UtcNow));

            await PublishRemindersForVehicleIdAsync(report.VehicleId);

            return report.ToDto();
        }

        public async Task<VehicleDefectReportDto> ReopenDefectAsync(Guid defectId)
        {
            var report = await _vehicleDefectReportRepository.GetByIdWithDetailsAsync(defectId)
                ?? throw new KeyNotFoundException($"Defect report {defectId} not found.");

            if (report.Status != DefectStatus.Resolved)
                throw new InvalidOperationException("Only resolved defect reports can be reopened.");

            report.Status = DefectStatus.Reported;
            report.ResolvedAt = null;

            await _vehicleDefectReportRepository.UpdateAsync(report);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.defect.resolved",
                new VehicleDefectResolvedEvent(
                    report.Id,
                    report.VehicleId,
                    report.Vehicle?.LicensePlate ?? string.Empty,
                    report.DriverId,
                    report.Driver != null ? $"{report.Driver.FirstName} {report.Driver.LastName}" : string.Empty,
                    report.Title,
                    true,
                    DateTime.UtcNow));

            await PublishRemindersForVehicleIdAsync(report.VehicleId);

            return report.ToDto();
        }

        public async Task<PaginatedResult<VehicleServiceRecordDto>> GetVehicleServiceRecordsAsync(Guid vehicleId, int page = 1, int pageSize = 20)
        {
            if (!await _vehicleRepository.ExistsAsync(vehicleId))
                throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 100);

            var records = await _vehicleServiceRecordRepository.GetByVehicleIdAsync(vehicleId, page, pageSize);
            var total = await _vehicleServiceRecordRepository.CountByVehicleIdAsync(vehicleId);

            return new PaginatedResult<VehicleServiceRecordDto>
            {
                Items = records.Select(r => r.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<VehicleServiceRecordDto> AddVehicleServiceRecordAsync(CreateVehicleServiceRecordDto dto)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(dto.VehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {dto.VehicleId} not found.");

            var record = new VehicleServiceRecord
            {
                Id = Guid.NewGuid(),
                VehicleId = vehicle.Id,
                ServiceDate = dto.ServiceDate == default ? DateTime.UtcNow : dto.ServiceDate,
                ServiceType = dto.ServiceType,
                Description = dto.Description,
                PerformedBy = dto.PerformedBy,
                OdometerKm = dto.OdometerKm,
                Cost = dto.Cost,
                CreatedAt = DateTime.UtcNow
            };

            // Previous records are never overwritten — a new service is appended and
            // the vehicle's last-service pointer/odometer move forward.
            await _vehicleServiceRecordRepository.AddAsync(record);

            if (vehicle.LastServiceDate is null || record.ServiceDate > vehicle.LastServiceDate.Value)
                vehicle.LastServiceDate = record.ServiceDate;

            if (dto.OdometerKm.HasValue && (vehicle.Mileage ?? 0m) < dto.OdometerKm.Value)
                vehicle.Mileage = dto.OdometerKm.Value;

            vehicle.UpdatedAt = DateTime.UtcNow;
            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.service.recorded",
                new VehicleServiceRecordedEvent(
                    vehicle.Id,
                    vehicle.LicensePlate,
                    DateOnly.FromDateTime(record.ServiceDate),
                    record.ServiceType.ToString(),
                    record.OdometerKm,
                    DateTime.UtcNow));

            await PublishRemindersAsync(vehicle);

            return record.ToDto();
        }

        public async Task<IEnumerable<VehicleServiceReminderDto>> GetServiceRemindersAsync()
        {
            var vehicles = (await _vehicleRepository.GetAllAsync()).ToList();
            if (vehicles.Count == 0)
                return Enumerable.Empty<VehicleServiceReminderDto>();

            var latestRecords = await _vehicleServiceRecordRepository.GetLatestByVehicleIdsAsync(vehicles.Select(v => v.Id));
            var latestByVehicle = latestRecords
                .GroupBy(r => r.VehicleId)
                .ToDictionary(
                    g => g.Key,
                    g => g.OrderByDescending(r => r.ServiceDate).ThenByDescending(r => r.CreatedAt).First());

            var highSeverityVehicleIds = (await _vehicleDefectReportRepository.GetVehicleIdsWithOpenHighSeverityDefectsAsync())
                .ToHashSet();

            var now = DateTime.UtcNow;
            var reminders = new List<VehicleServiceReminderDto>();

            foreach (var vehicle in vehicles)
            {
                latestByVehicle.TryGetValue(vehicle.Id, out var latestRecord);
                reminders.AddRange(VehicleReminderHelper.Evaluate(
                    vehicle, latestRecord, highSeverityVehicleIds.Contains(vehicle.Id), now));
            }

            return reminders;
        }

        private async Task PublishRemindersForVehicleIdAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId);
            if (vehicle != null)
                await PublishRemindersAsync(vehicle);
        }

        private async Task PublishRemindersAsync(Vehicle vehicle)
        {
            var latestRecord = await _vehicleServiceRecordRepository.GetLatestByVehicleIdAsync(vehicle.Id);
            var highSeverityVehicleIds = await _vehicleDefectReportRepository.GetVehicleIdsWithOpenHighSeverityDefectsAsync();
            var reminders = VehicleReminderHelper.Evaluate(
                vehicle, latestRecord, highSeverityVehicleIds.Contains(vehicle.Id), DateTime.UtcNow);

            foreach (var reminder in reminders)
            {
                if (reminder.Type == "Service")
                {
                    await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.service.due",
                        new VehicleServiceDueEvent(
                            vehicle.Id, vehicle.LicensePlate, reminder.Reason, reminder.DueAt, DateTime.UtcNow));
                }
                else
                {
                    await _eventPublisher.PublishAsync("driveops.fleet", "vehicle.inspection.due",
                        new VehicleInspectionDueEvent(
                            vehicle.Id, vehicle.LicensePlate, reminder.Reason, reminder.DueAt, DateTime.UtcNow));
                }
            }
        }
    }
}
