using DriveOps.Application.Helpers;

namespace DriveOps.Application.Interfaces
{
    /// <summary>
    /// Provides the effective fare configuration: the persisted admin override when
    /// present, otherwise the appsettings defaults.
    /// </summary>
    public interface IFareSettingsProvider
    {
        Task<FareCalculatorOptions> GetAsync(CancellationToken cancellationToken = default);

        Task<FareCalculatorOptions> UpdateAsync(
            FareCalculatorOptions options,
            string? updatedBy,
            CancellationToken cancellationToken = default);
    }
}
