using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class VehicleRepository : Repository<Vehicle>, IVehicleRepository
    {
        public VehicleRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<Vehicle>> GetAvailableVehiclesAsync()
        {
            return await _dbSet
                .Where(v => v.Status == VehicleStatus.Available && v.AssignedDriverId == null)
                .ToListAsync();
        }

        public async Task<IEnumerable<Vehicle>> GetByDriverIdAsync(Guid driverId)
        {
            return await _dbSet
                .Where(v => v.AssignedDriverId == driverId)
                .ToListAsync();
        }

        public async Task<Vehicle?> GetByLicensePlateAsync(string licensePlate)
        {
            return await _dbSet.FirstOrDefaultAsync(v => v.LicensePlate == licensePlate);
        }

        public async Task<Vehicle?> GetByVinAsync(string vin)
        {
            return await _dbSet.FirstOrDefaultAsync(v => v.Vin == vin);
        }
    }
}
