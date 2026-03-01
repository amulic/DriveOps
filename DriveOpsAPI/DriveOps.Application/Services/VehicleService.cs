using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;

namespace DriveOps.Application.Services
{
    public class VehicleService : IVehicleService
    {
        private readonly IVehicleRepository _vehicleRepository;
        private readonly IDriverRepository _driverRepository;
        private readonly IUnitOfWork _unitOfWork;

        public VehicleService(IVehicleRepository vehicleRepository, IDriverRepository driverRepository, IUnitOfWork unitOfWork)
        {
            _vehicleRepository = vehicleRepository;
            _driverRepository = driverRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<VehicleDto?> GetVehicleByIdAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId);
            return vehicle?.ToDto();
        }

        public async Task<IEnumerable<VehicleDto>> GetAllVehiclesAsync()
        {
            var vehicles = await _vehicleRepository.GetAllAsync();
            return vehicles.Select(v => v.ToDto());
        }

        public async Task<IEnumerable<VehicleDto>> GetAvailableVehiclesAsync()
        {
            var vehicles = await _vehicleRepository.GetAvailableVehiclesAsync();
            return vehicles.Select(v => v.ToDto());
        }

        public async Task<VehicleDto> CreateVehicleAsync(CreateVehicleDto dto)
        {
            var existingPlate = await _vehicleRepository.GetByLicensePlateAsync(dto.LicensePlate);
            if (existingPlate != null)
                throw new InvalidOperationException($"Vehicle with license plate '{dto.LicensePlate}' already exists.");

            var existingVin = await _vehicleRepository.GetByVinAsync(dto.Vin);
            if (existingVin != null)
                throw new InvalidOperationException($"Vehicle with VIN '{dto.Vin}' already exists.");

            var vehicle = dto.ToEntity();
            await _vehicleRepository.AddAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            return vehicle.ToDto();
        }

        public async Task<VehicleDto> UpdateVehicleAsync(UpdateVehicleDto dto)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(dto.Id)
                ?? throw new KeyNotFoundException($"Vehicle {dto.Id} not found.");

            if (dto.Color != null) vehicle.Color = dto.Color;
            if (dto.InsurancePolicyNumber != null) vehicle.InsurancePolicyNumber = dto.InsurancePolicyNumber;
            if (dto.InsuranceExpiryDate.HasValue) vehicle.InsuranceExpiryDate = dto.InsuranceExpiryDate.Value;
            if (dto.RegistrationExpiryDate.HasValue) vehicle.RegistrationExpiryDate = dto.RegistrationExpiryDate.Value;
            if (dto.Status.HasValue) vehicle.Status = dto.Status;
            if (dto.Mileage.HasValue) vehicle.Mileage = dto.Mileage;
            vehicle.UpdatedAt = DateTime.UtcNow;

            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            return vehicle.ToDto();
        }

        public async Task<VehicleDto> AssignVehicleToDriverAsync(Guid vehicleId, Guid driverId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            var driverExists = await _driverRepository.ExistsAsync(driverId);
            if (!driverExists)
                throw new KeyNotFoundException($"Driver {driverId} not found.");

            vehicle.AssignedDriverId = driverId;
            vehicle.UpdatedAt = DateTime.UtcNow;

            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            return vehicle.ToDto();
        }

        public async Task<VehicleDto> UnassignVehicleAsync(Guid vehicleId)
        {
            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            vehicle.AssignedDriverId = null;
            vehicle.UpdatedAt = DateTime.UtcNow;

            await _vehicleRepository.UpdateAsync(vehicle);
            await _unitOfWork.SaveChangesAsync();
            return vehicle.ToDto();
        }

        public async Task DeleteVehicleAsync(Guid vehicleId)
        {
            await _vehicleRepository.DeleteAsync(vehicleId);
            await _unitOfWork.SaveChangesAsync();
        }
    }
}
