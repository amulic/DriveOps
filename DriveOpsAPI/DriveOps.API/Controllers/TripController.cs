using DriveOps.API.ControllerDtos.Request;
using DriveOps.API.ControllerDtos.Response;
using DriveOps.API.Helpers;
using DriveOps.API.Mappings;
using DriveOps.Application.DTOs;
using DriveOps.Application.Exceptions;
using DriveOps.Application.Interfaces;
using DriveOps.Model.Entity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class TripController : ControllerBase
    {
        private readonly ITripService _tripService;
        private readonly IDriverRecommendationService _recommendationService;
        private readonly ITripRepository _tripRepository;
        private readonly ICustomerRepository _customerRepository;
        private readonly IDriverRepository _driverRepository;

        public TripController(
            ITripService tripService,
            IDriverRecommendationService recommendationService,
            ITripRepository tripRepository,
            ICustomerRepository customerRepository,
            IDriverRepository driverRepository)
        {
            _tripService = tripService;
            _recommendationService = recommendationService;
            _tripRepository = tripRepository;
            _customerRepository = customerRepository;
            _driverRepository = driverRepository;
        }

        [HttpGet]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> GetAllTrips(
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _tripService.GetAllTripsAsync(page, pageSize);
            return Ok(result);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetTripById(Guid id)
        {
            var forbidden = await ForbidUnlessParticipantAsync(id);
            if (forbidden != null)
                return forbidden;

            var trip = await _tripService.GetTripByIdAsync(id);
            if (trip == null)
                return NotFound();

            return Ok(trip.ToResponse());
        }

        [HttpGet("customer/{customerId:guid}")]
        public async Task<IActionResult> GetTripsByCustomer(Guid customerId,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!User.IsInManagementRole())
            {
                var customer = await _customerRepository.GetByIdAsync(customerId);
                if (customer == null)
                    return NotFound();
                if (customer.KeycloakId != User.GetKeycloakId())
                    return Forbid();
            }

            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _tripService.GetTripsByCustomerAsync(customerId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("driver/{driverId:guid}")]
        public async Task<IActionResult> GetTripsByDriver(Guid driverId,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!User.IsInManagementRole())
            {
                var driver = await _driverRepository.GetByIdAsync(driverId);
                if (driver == null)
                    return NotFound();
                if (driver.KeycloakId != User.GetKeycloakId())
                    return Forbid();
            }

            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _tripService.GetTripsByDriverAsync(driverId, page, pageSize);
            return Ok(result);
        }

        [HttpGet("driver/{driverId:guid}/active")]
        public async Task<IActionResult> GetActiveTripsForDriver(Guid driverId,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            if (!User.IsInManagementRole())
            {
                var driver = await _driverRepository.GetByIdAsync(driverId);
                if (driver == null)
                    return NotFound();
                if (driver.KeycloakId != User.GetKeycloakId())
                    return Forbid();
            }

            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var trips = await _tripService.GetActiveTripsForDriverAsync(driverId, page, pageSize);
            return Ok(trips.MapPage(t => t.ToResponse()));
        }

        [HttpPost]
        public async Task<IActionResult> RequestTrip([FromBody] CreateTripRequest request)
        {
            // Customers may only request trips for their own profile; the body id is never trusted.
            var customer = await _customerRepository.GetByIdAsync(request.CustomerId);
            if (customer == null || customer.KeycloakId != User.GetKeycloakId())
                return Forbid();

            try
            {
                var trip = await _tripService.RequestTripAsync(request.ToApplicationDto());
                return CreatedAtAction(nameof(GetTripById), new { id = trip.Id }, trip.ToResponse());
            }
            catch (ActiveTripExistsException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (PaymentGatewayException ex)
            {
                // Stripe unreachable while checking the saved-card guard.
                return StatusCode(502, new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                // Routing failure (e.g. OSRM could not calculate a route).
                return StatusCode(502, new { message = ex.Message });
            }
            catch (HttpRequestException ex)
            {
                // Routing service unreachable.
                return StatusCode(502, new { message = ex.Message });
            }
        }

        [HttpPost("estimate")]
        public async Task<IActionResult> GetTripEstimate([FromBody] TripEstimateRequest request)
        {
            try
            {
                var estimate = await _tripService.GetTripEstimateAsync(
                    request.PickupLatitude, request.PickupLongitude,
                    request.DropoffLatitude, request.DropoffLongitude,
                    (DriveOps.RealTime.Contracts.Enums.TripType)(int)request.TripType);

                return Ok(estimate.ToResponse());
            }
            catch (InvalidOperationException ex)
            {
                // Routing failure (e.g. OSRM could not calculate a route).
                return StatusCode(502, new { message = ex.Message });
            }
            catch (HttpRequestException ex)
            {
                // Routing service unreachable.
                return StatusCode(502, new { message = ex.Message });
            }
        }

        [HttpPost("{id:guid}/assign")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> AssignDriver(Guid id, [FromBody] AssignDriverRequest request)
        {
            var trip = await _tripService.AssignDriverAsync(id, request.DriverId, request.VehicleId);
            return Ok(trip.ToResponse());
        }

        [HttpPost("{id:guid}/start")]
        public async Task<IActionResult> StartTrip(Guid id)
        {
            var forbidden = await ForbidUnlessTripDriverAsync(id);
            if (forbidden != null)
                return forbidden;

            var trip = await _tripService.StartTripAsync(id);
            return Ok(trip.ToResponse());
        }

        [HttpPost("{id:guid}/complete")]
        public async Task<IActionResult> CompleteTrip(Guid id, [FromBody] CompleteTripRequest request)
        {
            var forbidden = await ForbidUnlessTripDriverAsync(id);
            if (forbidden != null)
                return forbidden;

            var trip = await _tripService.CompleteTripAsync(id, request.ActualDistance);
            return Ok(trip.ToResponse());
        }

        [HttpPost("{id:guid}/cancel")]
        public async Task<IActionResult> CancelTrip(Guid id, [FromBody] CancelTripRequest request)
        {
            var forbidden = await ForbidUnlessTripCustomerOrManagementAsync(id);
            if (forbidden != null)
                return forbidden;

            var trip = await _tripService.CancelTripAsync(id, request.Reason);
            return Ok(trip.ToResponse());
        }

        [HttpPost("{id:guid}/decline")]
        public async Task<IActionResult> DeclineTrip(Guid id, [FromBody] DeclineTripRequest request)
        {
            var forbidden = await ForbidUnlessTripDriverAsync(id);
            if (forbidden != null)
                return forbidden;

            try
            {
                var trip = await _tripService.DeclineTripAsync(id, request.DriverId, request.Reason);
                return Ok(trip.ToResponse());
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id:guid}/rate")]
        public async Task<IActionResult> RateTrip(Guid id, [FromBody] RateTripRequest request)
        {
            var trip = await _tripRepository.GetWithDetailsAsync(id);
            if (trip == null)
                return NotFound();

            var keycloakId = User.GetKeycloakId();
            if (!IsParticipant(trip, keycloakId))
                return Forbid();

            // Rating direction is fixed by the caller: customers rate drivers and vice versa.
            var raterIsCustomer = trip.Customer?.KeycloakId == keycloakId;
            if (request.IsCustomerRating != raterIsCustomer)
                return Forbid();

            var dto = new RateTripDto
            {
                TripId = id,
                Rating = request.Rating,
                Feedback = request.Feedback,
                IsCustomerRating = request.IsCustomerRating
            };

            var result = await _tripService.RateTripAsync(dto);
            return Ok(result.ToResponse());
        }

        [HttpGet("{id:guid}/recommended-drivers")]
        [Authorize(Roles = "admin,dispatcher")]
        public async Task<IActionResult> GetRecommendedDrivers(Guid id, [FromQuery] int count = 5)
        {
            try
            {
                var drivers = await _recommendationService.GetRecommendedDriversAsync(id, Math.Clamp(count, 1, 20));
                return Ok(drivers);
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id:guid}/route")]
        public async Task<IActionResult> GetTripRoute(Guid id,
            [FromQuery] int page = 1, [FromQuery] int pageSize = 500)
        {
            var forbidden = await ForbidUnlessParticipantAsync(id);
            if (forbidden != null)
                return forbidden;

            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, 500);
            var route = await _tripService.GetTripRouteAsync(id, page, pageSize);
            return Ok(route.MapPage(r => r.ToResponse()));
        }

        [HttpPost("{id:guid}/route")]
        public async Task<IActionResult> AddRoutePoints(Guid id, [FromBody] AddRoutePointsRequest request)
        {
            var forbidden = await ForbidUnlessTripDriverOrManagementAsync(id);
            if (forbidden != null)
                return forbidden;

            var points = request.Points.Select(p => new RoutePointDto
            {
                Latitude = p.Latitude,
                Longitude = p.Longitude,
                Timestamp = p.Timestamp
            });

            await _tripService.AddRoutePointsAsync(id, points);
            return NoContent();
        }

        private static bool IsParticipant(Trip trip, Guid? keycloakId) =>
            keycloakId.HasValue &&
            (trip.Customer?.KeycloakId == keycloakId || trip.Driver?.KeycloakId == keycloakId);

        private static bool IsTripDriver(Trip trip, Guid? keycloakId) =>
            keycloakId.HasValue && trip.Driver?.KeycloakId == keycloakId;

        private static bool IsTripCustomer(Trip trip, Guid? keycloakId) =>
            keycloakId.HasValue && trip.Customer?.KeycloakId == keycloakId;

        private async Task<IActionResult?> ForbidUnlessParticipantAsync(Guid tripId)
        {
            if (User.IsInManagementRole())
                return null;

            var trip = await _tripRepository.GetWithDetailsAsync(tripId);
            if (trip == null)
                return NotFound();

            return IsParticipant(trip, User.GetKeycloakId()) ? null : Forbid();
        }

        private async Task<IActionResult?> ForbidUnlessTripDriverAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetWithDetailsAsync(tripId);
            if (trip == null)
                return NotFound();

            return IsTripDriver(trip, User.GetKeycloakId()) ? null : Forbid();
        }

        private async Task<IActionResult?> ForbidUnlessTripDriverOrManagementAsync(Guid tripId)
        {
            if (User.IsInManagementRole())
                return null;

            return await ForbidUnlessTripDriverAsync(tripId);
        }

        private async Task<IActionResult?> ForbidUnlessTripCustomerOrManagementAsync(Guid tripId)
        {
            if (User.IsInManagementRole())
                return null;

            var trip = await _tripRepository.GetWithDetailsAsync(tripId);
            if (trip == null)
                return NotFound();

            return IsTripCustomer(trip, User.GetKeycloakId()) ? null : Forbid();
        }
    }
}
