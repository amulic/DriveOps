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

        public override async Task<IEnumerable<Vehicle>> GetAllAsync()
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .ToListAsync();
        }

        public async Task<IEnumerable<Vehicle>> GetAllAsync(int page, int pageSize)
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .OrderBy(v => v.LicensePlate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Vehicle>> GetAvailableVehiclesAsync(int page, int pageSize)
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .Where(v => v.Status == VehicleStatus.Available && v.AssignedDriverId == null)
                .OrderBy(v => v.LicensePlate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Vehicle>> GetByDriverIdAsync(Guid driverId)
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .Where(v => v.AssignedDriverId == driverId)
                .ToListAsync();
        }

        public async Task<Vehicle?> GetByLicensePlateAsync(string licensePlate)
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .FirstOrDefaultAsync(v => v.LicensePlate == licensePlate);
        }

        public async Task<Vehicle?> GetByVinAsync(string vin)
        {
            return await _dbSet
                .Include(v => v.AssignedDriver)
                .FirstOrDefaultAsync(v => v.Vin == vin);
        }
    }
}
