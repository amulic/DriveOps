using DriveOps.Application.DTOs;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Enums;
using DriveOps.RealTime.Contracts.Events;
using FluentValidation;

namespace DriveOps.Application.Services
{
    public class DriverService : IDriverService
    {
        private readonly IDriverRepository _driverRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IEventPublisher _eventPublisher;
        private readonly IKeycloakAdminService _keycloakAdminService;
        private readonly IValidator<CreateDriverDto> _createDriverValidator;
        private readonly IValidator<OnboardDriverDto> _onboardDriverValidator;

        public DriverService(IDriverRepository driverRepository, IUnitOfWork unitOfWork, IEventPublisher eventPublisher, IKeycloakAdminService keycloakAdminService, IValidator<CreateDriverDto> createDriverValidator, IValidator<OnboardDriverDto> onboardDriverValidator)
        {
            _driverRepository = driverRepository;
            _unitOfWork = unitOfWork;
            _eventPublisher = eventPublisher;
            _keycloakAdminService = keycloakAdminService;
            _createDriverValidator = createDriverValidator;
            _onboardDriverValidator = onboardDriverValidator;
        }

        public async Task<PaginatedResult<DriverDto>> GetAllDriversAsync(int page = 1, int pageSize = 50)
        {
            var drivers = await _driverRepository.GetAllDriversAsync(page, pageSize);
            var total = await _driverRepository.CountAllDriversAsync();
            return new PaginatedResult<DriverDto>
            {
                Items = drivers.Select(d => d.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<DriverDto?> GetDriverByIdAsync(Guid driverId)
        {
            var driver = await _driverRepository.GetWithVehiclesAsync(driverId);
            return driver?.ToDto();
        }

        public async Task<DriverDto?> GetDriverByKeycloakIdAsync(Guid keycloakId)
        {
            var driver = await _driverRepository.GetByKeycloakIdAsync(keycloakId);
            return driver?.ToDto();
        }

        public async Task<PaginatedResult<DriverDto>> GetAvailableDriversAsync(int page = 1, int pageSize = 50)
        {
            var drivers = await _driverRepository.GetAvailableDriversAsync(page, pageSize);
            var total = await _driverRepository.CountAvailableDriversAsync();
            return new PaginatedResult<DriverDto>
            {
                Items = drivers.Select(d => d.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<PaginatedResult<DriverDto>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm, int page = 1, int pageSize = 50)
        {
            var drivers = await _driverRepository.GetNearbyDriversAsync(latitude, longitude, radiusKm, page, pageSize);
            var total = await _driverRepository.CountNearbyDriversAsync(latitude, longitude, radiusKm);
            return new PaginatedResult<DriverDto>
            {
                Items = drivers.Select(d => d.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<DriverDto> CreateDriverAsync(CreateDriverDto dto)
        {
            // FluentValidation is not wired to an automatic filter — enforce the create
            // contract here so both POST /api/driver and POST /api/driver/promote get it.
            await _createDriverValidator.ValidateAndThrowAsync(dto);

            var existingDriver = await _driverRepository.GetByKeycloakIdAsync(dto.KeycloakId);
            if (existingDriver != null)
                throw new InvalidOperationException($"Driver with KeycloakId {dto.KeycloakId} already exists.");

            var driver = dto.ToEntity();
            await _driverRepository.AddAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            var result = await _driverRepository.GetWithVehiclesAsync(driver.Id);
            return result!.ToDto();
        }

        public async Task<List<PromotionCandidateDto>> GetPromotionCandidatesAsync(string search)
        {
            var users = await _keycloakAdminService.SearchUsersAsync(search ?? string.Empty);
            var regularUsers = users
                .Where(u => u.Enabled)
                .Where(u => !u.Username.StartsWith("service-account-", StringComparison.OrdinalIgnoreCase))
                .ToList();

            var keycloakIds = regularUsers
                .Select(u => u.Id)
                .Where(id => Guid.TryParse(id, out _))
                .Select(Guid.Parse)
                .ToList();
            var existingKeycloakIds = await _driverRepository.GetExistingKeycloakIdsAsync(keycloakIds);

            // Fetch realm roles for all candidates in parallel (was a sequential N+1).
            // HttpClient sends are thread-safe and the token cache is semaphore-guarded.
            var candidateTasks = regularUsers.Select(async user =>
            {
                if (!Guid.TryParse(user.Id, out var keycloakId))
                    return null;

                var realmRoles = await _keycloakAdminService.GetUserRealmRolesAsync(user.Id);
                return new PromotionCandidateDto
                {
                    KeycloakId = keycloakId,
                    Username = user.Username,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Email = user.Email,
                    RealmRoles = realmRoles,
                    HasDriverProfile = existingKeycloakIds.Contains(keycloakId)
                };
            });

            return (await Task.WhenAll(candidateTasks))
                .Where(c => c != null)
                .Cast<PromotionCandidateDto>()
                .ToList();
        }

        public async Task<DriverDto> PromoteDriverAsync(CreateDriverDto dto)
        {
            // Validate up front so an invalid payload fails before any Keycloak side effects.
            await _createDriverValidator.ValidateAndThrowAsync(dto);

            var existingDriver = await _driverRepository.GetByKeycloakIdAsync(dto.KeycloakId);
            if (existingDriver != null)
                throw new DuplicateDriverException($"Driver with KeycloakId {dto.KeycloakId} already exists.");

            var keycloakUser = await _keycloakAdminService.GetUserByIdAsync(dto.KeycloakId.ToString())
                ?? throw new KeycloakUserNotFoundException($"Keycloak user {dto.KeycloakId} not found.");

            await _keycloakAdminService.AssignRealmRoleAsync(keycloakUser.Id, "driver");

            // If the local create fails after the role was granted, the role remains —
            // acceptable and documented: retry is idempotent (duplicate check rejects,
            // role assignment skips).
            return await CreateDriverAsync(dto);
        }

        public async Task<DriverDto> OnboardDriverAsync(OnboardDriverDto dto)
        {
            // Validate up front so an invalid payload fails before any Keycloak side effects.
            await _onboardDriverValidator.ValidateAndThrowAsync(dto);

            var keycloakUser = await _keycloakAdminService.CreateUserAsync(
                dto.Username, dto.Email, dto.FirstName, dto.LastName, dto.TemporaryPassword);

            if (!Guid.TryParse(keycloakUser.Id, out var keycloakId))
                throw new InvalidOperationException($"Keycloak returned a non-GUID user id '{keycloakUser.Id}'.");

            await _keycloakAdminService.AssignRealmRoleAsync(keycloakUser.Id, "driver");

            // If the local create fails here, the Keycloak account remains (already holding the
            // driver role) — recovery is the existing promote flow (candidates → promote), which
            // is idempotent.
            return await CreateDriverAsync(new CreateDriverDto
            {
                KeycloakId = keycloakId,
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Email = dto.Email,
                PhoneNumber = dto.PhoneNumber,
                LicenseNumber = dto.LicenseNumber,
                LicenseExpiryDate = dto.LicenseExpiryDate,
                EmergencyContactName = dto.EmergencyContactName,
                EmergencyContactPhone = dto.EmergencyContactPhone
            });
        }

        public async Task<DriverDto> UpdateDriverAsync(UpdateDriverDto dto)
        {
            var driver = await _driverRepository.GetWithVehiclesAsync(dto.Id)
                ?? throw new KeyNotFoundException($"Driver {dto.Id} not found.");

            if (dto.FirstName != null) driver.FirstName = dto.FirstName;
            if (dto.LastName != null) driver.LastName = dto.LastName;
            if (dto.Email != null) driver.Email = dto.Email;
            if (dto.PhoneNumber != null) driver.PhoneNumber = dto.PhoneNumber;
            if (dto.LicenseNumber != null) driver.LicenseNumber = dto.LicenseNumber;
            if (dto.LicenseExpiryDate.HasValue) driver.LicenseExpiryDate = dto.LicenseExpiryDate.Value;
            if (dto.EmergencyContactName != null) driver.EmergencyContactName = dto.EmergencyContactName;
            if (dto.EmergencyContactPhone != null) driver.EmergencyContactPhone = dto.EmergencyContactPhone;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
            await _unitOfWork.SaveChangesAsync();
            return driver.ToDto();
        }

        public async Task UpdateDriverLocationAsync(UpdateDriverLocationDto dto)
        {
            var driver = await _driverRepository.GetByIdWithTripsAsync(dto.DriverId)
                ?? throw new KeyNotFoundException($"Driver {dto.DriverId} not found.");

            driver.CurrentLatitude = dto.Latitude;
            driver.CurrentLongitude = dto.Longitude;
            driver.LastLocationUpdate = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            var activeTripId = driver.Trips
                ?.FirstOrDefault(t => t.TripStatus == TripStatus.InProgress)
                ?.Id;

            await _eventPublisher.PublishAsync("driveops.location", "driver.location",
                new DriverLocationUpdatedEvent(
                    dto.DriverId, dto.Latitude, dto.Longitude,
                    DateTime.UtcNow, activeTripId));
        }

        public async Task SetDriverOnlineStatusAsync(Guid driverId, bool isOnline)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.IsOnline = isOnline;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.location", "driver.availability",
                new DriverAvailabilityChangedEvent(driverId, isOnline, DateTime.UtcNow));

            await _eventPublisher.PublishAsync("driveops.fleet", "driver.status.changed",
                new DriverStatusChangedEvent(driverId,
                    $"{driver.FirstName} {driver.LastName}",
                    driver.Status?.ToString() ?? "Unknown", isOnline, DateTime.UtcNow));
        }

        public async Task SuspendDriverAsync(Guid driverId)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.Status = DriverStatus.Suspended;
            driver.IsOnline = false;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.location", "driver.availability",
                new DriverAvailabilityChangedEvent(driverId, false, DateTime.UtcNow));

            await _eventPublisher.PublishAsync("driveops.fleet", "driver.status.changed",
                new DriverStatusChangedEvent(driverId,
                    $"{driver.FirstName} {driver.LastName}",
                    "Suspended", false, DateTime.UtcNow));
        }

        public async Task ActivateDriverAsync(Guid driverId)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.Status = DriverStatus.Active;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.location", "driver.availability",
                new DriverAvailabilityChangedEvent(driverId, driver.IsOnline ?? false, DateTime.UtcNow));

            await _eventPublisher.PublishAsync("driveops.fleet", "driver.status.changed",
                new DriverStatusChangedEvent(driverId,
                    $"{driver.FirstName} {driver.LastName}",
                    "Active", driver.IsOnline ?? false, DateTime.UtcNow));
        }
    }
}
