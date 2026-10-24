using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.Mappings;
using DriveOps.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CustomerController : ControllerBase
    {
        private readonly ICustomerService _customerService;

        public CustomerController(ICustomerService customerService)
        {
            _customerService = customerService;
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetCustomerById(Guid id)
        {
            var customer = await _customerService.GetCustomerByIdAsync(id);
            if (customer == null)
                return NotFound();

            return Ok(customer.ToResponse());
        }

        [HttpGet("keycloak/{keycloakId:guid}")]
        public async Task<IActionResult> GetCustomerByKeycloakId(Guid keycloakId)
        {
            var customer = await _customerService.GetCustomerByKeycloakIdAsync(keycloakId);
            if (customer == null)
                return NotFound();

            return Ok(customer.ToResponse());
        }

        // Self-service onboarding: any authenticated user may create their own customer
        // profile (mobile first-login flow)
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateCustomer([FromBody] CreateCustomerRequest request)
        {
            // DefaultMapInboundClaims = false keeps the claim name as "sub".
            var sub = User.FindFirst("sub")?.Value;
            if (sub == null || !string.Equals(sub, request.KeycloakId.ToString(), StringComparison.OrdinalIgnoreCase))
                return StatusCode(403, new { message = "You can only create a customer profile for your own account." });

            var customer = await _customerService.CreateCustomerAsync(request.ToApplicationDto());
            return CreatedAtAction(nameof(GetCustomerById), new { id = customer.Id }, customer.ToResponse());
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> UpdateCustomer(Guid id, [FromBody] UpdateCustomerRequest request)
        {
            var customer = await _customerService.UpdateCustomerAsync(request.ToApplicationDto(id));
            return Ok(customer.ToResponse());
        }
    }
}
