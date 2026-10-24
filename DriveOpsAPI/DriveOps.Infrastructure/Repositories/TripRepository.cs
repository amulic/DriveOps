using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class TripRepository : Repository<Trip>, ITripRepository
    {
        public TripRepository(ApplicationDbContext context) : base(context) { }

        public async Task<IEnumerable<Trip>> GetAllTripsAsync(int page = 1, int pageSize = 20)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Driver)
                .Include(t => t.Vehicle)
                .OrderByDescending(t => t.RequestedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountAllTripsAsync()
        {
            return await _dbSet.CountAsync();
        }

        public async Task<IEnumerable<Trip>> GetActiveTripsByDriverIdAsync(Guid driverId)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Vehicle)
                .Where(t => t.DriverId == driverId
                    && t.TripStatus != TripStatus.Completed
                    && t.TripStatus != TripStatus.Cancelled)
                .OrderByDescending(t => t.RequestedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Trip>> GetActiveTripsByCustomerIdAsync(Guid customerId)
        {
            return await _dbSet
                .Where(t => t.CustomerId == customerId
                    && (t.TripStatus == TripStatus.Requested
                        || t.TripStatus == TripStatus.Assigned
                        || t.TripStatus == TripStatus.DriverEnRoute
                        || t.TripStatus == TripStatus.InProgress))
                .OrderByDescending(t => t.RequestedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Trip>> GetByCustomerIdAsync(Guid customerId, int page = 1, int pageSize = 20)
        {
            return await _dbSet
                .Include(t => t.Driver)
                .Include(t => t.Vehicle)
                .Where(t => t.CustomerId == customerId)
                .OrderByDescending(t => t.RequestedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Trip>> GetByDriverIdAsync(Guid driverId, int page = 1, int pageSize = 20)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Vehicle)
                .Where(t => t.DriverId == driverId)
                .OrderByDescending(t => t.RequestedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> CountByCustomerIdAsync(Guid customerId)
        {
            return await _dbSet.CountAsync(t => t.CustomerId == customerId);
        }

        public async Task<int> CountByDriverIdAsync(Guid driverId)
        {
            return await _dbSet.CountAsync(t => t.DriverId == driverId);
        }

        public async Task<Trip?> GetWithDetailsAsync(Guid tripId)
        {
            return await _dbSet
                .Include(t => t.Customer)
                .Include(t => t.Driver)
                .Include(t => t.Vehicle)
                .Include(t => t.TripRoutes.OrderBy(r => r.Timestamp))
                .FirstOrDefaultAsync(t => t.Id == tripId);
        }
    }
}
