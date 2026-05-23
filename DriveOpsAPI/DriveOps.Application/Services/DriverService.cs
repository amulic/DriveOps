using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Enums;
using DriveOps.RealTime.Contracts.Events;

namespace DriveOps.Application.Services
{
    public class DriverService : IDriverService
    {
        private readonly IDriverRepository _driverRepository;
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IEventPublisher _eventPublisher;

        public DriverService(IDriverRepository driverRepository, IUserRepository userRepository, IUnitOfWork unitOfWork, IEventPublisher eventPublisher)
        {
            _driverRepository = driverRepository;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
            _eventPublisher = eventPublisher;
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

        public async Task<DriverDto?> GetDriverByUserIdAsync(Guid userId)
        {
            var driver = await _driverRepository.GetByUserIdAsync(userId);
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
            var userExists = await _userRepository.ExistsAsync(dto.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User {dto.UserId} not found.");

            var existingDriver = await _driverRepository.GetByUserIdAsync(dto.UserId);
            if (existingDriver != null)
                throw new InvalidOperationException($"User {dto.UserId} is already registered as a driver.");

            var driver = dto.ToEntity();
            await _driverRepository.AddAsync(driver);
            await _unitOfWork.SaveChangesAsync();

            var result = await _driverRepository.GetWithVehiclesAsync(driver.Id);
            return result!.ToDto();
        }

        public async Task<DriverDto> UpdateDriverAsync(UpdateDriverDto dto)
        {
            var driver = await _driverRepository.GetWithVehiclesAsync(dto.Id)
                ?? throw new KeyNotFoundException($"Driver {dto.Id} not found.");

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
        }
    }
}
