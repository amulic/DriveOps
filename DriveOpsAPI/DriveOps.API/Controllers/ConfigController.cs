using DriveOps.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Public, non-secret client configuration. The currency is read from the same
    /// options object that configures Stripe charging, so what the user sees matches
    /// what is actually charged. Anonymous so both apps can fetch it on startup.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class ConfigController : ControllerBase
    {
        private readonly PaymentServiceOptions _paymentOptions;

        public ConfigController(PaymentServiceOptions paymentOptions)
        {
            _paymentOptions = paymentOptions;
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Get() => Ok(new
        {
            currency = _paymentOptions.Currency.ToUpperInvariant()
        });
    }
}
