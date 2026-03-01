using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Services
{
    public class DriverService : IDriverService
    {
        private readonly IDriverRepository _driverRepository;
        private readonly IUserRepository _userRepository;

        public DriverService(IDriverRepository driverRepository, IUserRepository userRepository)
        {
            _driverRepository = driverRepository;
            _userRepository = userRepository;
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

        public async Task<IEnumerable<DriverDto>> GetAvailableDriversAsync()
        {
            var drivers = await _driverRepository.GetAvailableDriversAsync();
            return drivers.Select(d => d.ToDto());
        }

        public async Task<IEnumerable<DriverDto>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm)
        {
            var drivers = await _driverRepository.GetNearbyDriversAsync(latitude, longitude, radiusKm);
            return drivers.Select(d => d.ToDto());
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
            var created = await _driverRepository.AddAsync(driver);

            var result = await _driverRepository.GetWithVehiclesAsync(created.Id);
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
            return driver.ToDto();
        }

        public async Task UpdateDriverLocationAsync(UpdateDriverLocationDto dto)
        {
            var driver = await _driverRepository.GetByIdAsync(dto.DriverId)
                ?? throw new KeyNotFoundException($"Driver {dto.DriverId} not found.");

            driver.CurrentLatitude = dto.Latitude;
            driver.CurrentLongitude = dto.Longitude;
            driver.LastLocationUpdate = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
        }

        public async Task SetDriverOnlineStatusAsync(Guid driverId, bool isOnline)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.IsOnline = isOnline;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
        }

        public async Task SuspendDriverAsync(Guid driverId)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.Status = DriverStatus.Suspended;
            driver.IsOnline = false;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
        }

        public async Task ActivateDriverAsync(Guid driverId)
        {
            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            driver.Status = DriverStatus.Active;
            driver.UpdatedAt = DateTime.UtcNow;

            await _driverRepository.UpdateAsync(driver);
        }
    }
}
