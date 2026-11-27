using DriveOps.Model.Entity;

namespace DriveOps.Application.Interfaces
{
    public interface IFareSettingsRepository
    {
        Task<FareSetting?> GetAsync(CancellationToken cancellationToken = default);
        Task UpsertAsync(FareSetting setting, CancellationToken cancellationToken = default);
    }
}
