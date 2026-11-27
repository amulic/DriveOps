using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model.Entity;
using Microsoft.EntityFrameworkCore;

namespace DriveOps.Infrastructure.Repositories
{
    internal class FareSettingsRepository : IFareSettingsRepository
    {
        private readonly ApplicationDbContext _context;

        public FareSettingsRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<FareSetting?> GetAsync(CancellationToken cancellationToken = default)
        {
            return await _context.FareSettings
                .OrderBy(s => s.Id)
                .FirstOrDefaultAsync(cancellationToken);
        }

        public async Task UpsertAsync(FareSetting setting, CancellationToken cancellationToken = default)
        {
            var exists = await _context.FareSettings
                .AnyAsync(s => s.Id == setting.Id, cancellationToken);

            if (exists)
                _context.FareSettings.Update(setting);
            else
                _context.FareSettings.Add(setting);

            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
