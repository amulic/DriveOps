using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    /// <summary>
    /// Stripe-backed card payments: saved-card management (PaymentSheet setup),
    /// retrying failed trip payments, and the provider webhook.
    /// All endpoints are customer self-service — the caller is resolved from the JWT sub.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        /// <summary>Creates a setup session for saving a card via the Stripe PaymentSheet.</summary>
        [HttpPost("setup-intent")]
        public async Task<IActionResult> CreateSetupIntent()
        {
            if (!TryGetSub(out var keycloakId))
                return Unauthorized();

            try
            {
                return Ok(await _paymentService.CreateSetupSessionAsync(keycloakId));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (PaymentGatewayException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }

        /// <summary>Lists the customer's saved cards.</summary>
        [HttpGet("methods")]
        public async Task<IActionResult> GetSavedCards()
        {
            if (!TryGetSub(out var keycloakId))
                return Unauthorized();

            try
            {
                return Ok(await _paymentService.GetSavedCardsAsync(keycloakId));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (PaymentGatewayException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }

        /// <summary>Detaches a saved card.</summary>
        [HttpDelete("methods/{paymentMethodId}")]
        public async Task<IActionResult> DeleteCard(string paymentMethodId)
        {
            if (!TryGetSub(out var keycloakId))
                return Unauthorized();

            try
            {
                await _paymentService.DeleteCardAsync(keycloakId, paymentMethodId);
                return NoContent();
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (PaymentGatewayException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }

        /// <summary>Creates an on-session PaymentIntent to retry a failed/pending card payment for a completed trip.</summary>
        [HttpPost("trips/{tripId:guid}/retry")]
        public async Task<IActionResult> RetryTripPayment(Guid tripId)
        {
            if (!TryGetSub(out var keycloakId))
                return Unauthorized();

            try
            {
                return Ok(await _paymentService.CreateRetryPaymentAsync(keycloakId, tripId));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (PaymentGatewayException ex)
            {
                return StatusCode(502, new { message = ex.Message });
            }
        }

        /// <summary>
        /// Stripe webhook receiver. Anonymous (Stripe calls it) but signature-verified against
        /// Stripe:WebhookSecret. Always 200s events that are valid but not actionable.
        /// </summary>
        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            var rawBody = await new StreamReader(Request.Body).ReadToEndAsync();
            var signature = Request.Headers["Stripe-Signature"].ToString();

            try
            {
                await _paymentService.HandleWebhookAsync(rawBody, signature);
                return Ok();
            }
            catch (PaymentGatewayException ex)
            {
                // Signature verification failed.
                return BadRequest(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                // Webhook secret not configured.
                return StatusCode(500, new { message = ex.Message });
            }
        }

        // DefaultMapInboundClaims = false keeps the claim name as "sub".
        private bool TryGetSub(out Guid keycloakId) =>
            Guid.TryParse(User.FindFirst("sub")?.Value, out keycloakId);
    }
}
