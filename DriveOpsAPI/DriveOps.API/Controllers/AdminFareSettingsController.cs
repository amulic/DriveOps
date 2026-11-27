using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Services;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Admin-only fare settings. Values are persisted and applied immediately to
    /// estimates and completed-trip fare calculation.
    /// </summary>
    [ApiController]
    [Route("api/admin/settings/fare")]
    [Authorize(Roles = "admin")]
    public class AdminFareSettingsController : ControllerBase
    {
        private readonly IFareSettingsProvider _fareSettings;
        private readonly PaymentServiceOptions _paymentOptions;
        private readonly IValidator<UpdateFareSettingsDto> _validator;

        public AdminFareSettingsController(
            IFareSettingsProvider fareSettings,
            PaymentServiceOptions paymentOptions,
            IValidator<UpdateFareSettingsDto> validator)
        {
            _fareSettings = fareSettings;
            _paymentOptions = paymentOptions;
            _validator = validator;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var options = await _fareSettings.GetAsync();
            return Ok(ToResponse(options));
        }

        [HttpPut]
        public async Task<IActionResult> Update([FromBody] UpdateFareSettingsDto dto)
        {
            await _validator.ValidateAndThrowAsync(dto);

            var caller = User.FindFirst("sub")?.Value ?? User.Identity?.Name;
            var updated = await _fareSettings.UpdateAsync(new DriveOps.Application.Helpers.FareCalculatorOptions
            {
                BaseFare = dto.BaseFare,
                PerKmRate = dto.PerKmRate,
                PerMinuteRate = dto.PerMinuteRate,
                PremiumMultiplier = dto.PremiumMultiplier,
                SharedMultiplier = dto.SharedMultiplier
            }, caller);

            return Ok(ToResponse(updated));
        }

        private object ToResponse(DriveOps.Application.Helpers.FareCalculatorOptions options) => new
        {
            baseFare = options.BaseFare,
            perKmRate = options.PerKmRate,
            perMinuteRate = options.PerMinuteRate,
            premiumMultiplier = options.PremiumMultiplier,
            sharedMultiplier = options.SharedMultiplier,
            currency = _paymentOptions.Currency.ToUpperInvariant()
        };
    }
}
