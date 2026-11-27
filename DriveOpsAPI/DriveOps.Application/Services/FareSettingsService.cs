using DriveOps.Application.Helpers;
using DriveOps.Application.Interfaces;
using DriveOps.Model.Entity;

namespace DriveOps.Application.Services
{
    public class FareSettingsService : IFareSettingsProvider
    {
        private const int SingletonRowId = 1;

        private readonly IFareSettingsRepository _repository;
        private readonly FareCalculatorOptions _defaults;

        public FareSettingsService(IFareSettingsRepository repository, FareCalculatorOptions defaults)
        {
            _repository = repository;
            _defaults = defaults;
        }

        public async Task<FareCalculatorOptions> GetAsync(CancellationToken cancellationToken = default)
        {
            var setting = await _repository.GetAsync(cancellationToken);
            return setting is null ? Clone(_defaults) : ToOptions(setting);
        }

        public async Task<FareCalculatorOptions> UpdateAsync(
            FareCalculatorOptions options,
            string? updatedBy,
            CancellationToken cancellationToken = default)
        {
            var setting = await _repository.GetAsync(cancellationToken);

            if (setting is null)
            {
                setting = new FareSetting { Id = SingletonRowId };
            }

            setting.BaseFare = options.BaseFare;
            setting.PerKmRate = options.PerKmRate;
            setting.PerMinuteRate = options.PerMinuteRate;
            setting.PremiumMultiplier = options.PremiumMultiplier;
            setting.SharedMultiplier = options.SharedMultiplier;
            setting.UpdatedBy = updatedBy;
            setting.UpdatedAt = DateTime.UtcNow;

            await _repository.UpsertAsync(setting, cancellationToken);
            return ToOptions(setting);
        }

        private static FareCalculatorOptions ToOptions(FareSetting setting) => new()
        {
            BaseFare = setting.BaseFare,
            PerKmRate = setting.PerKmRate,
            PerMinuteRate = setting.PerMinuteRate,
            PremiumMultiplier = setting.PremiumMultiplier,
            SharedMultiplier = setting.SharedMultiplier
        };

        private static FareCalculatorOptions Clone(FareCalculatorOptions options) => new()
        {
            BaseFare = options.BaseFare,
            PerKmRate = options.PerKmRate,
            PerMinuteRate = options.PerMinuteRate,
            PremiumMultiplier = options.PremiumMultiplier,
            SharedMultiplier = options.SharedMultiplier
        };
    }
}
