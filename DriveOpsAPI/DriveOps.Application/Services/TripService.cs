using DriveOps.Application.DTOs;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;

namespace DriveOps.Application.Services
{
    public class TripService : ITripService
    {
        private readonly ITripRepository _tripRepository;
        private readonly ITripRouteRepository _tripRouteRepository;
        private readonly IDriverRepository _driverRepository;
        private readonly IVehicleRepository _vehicleRepository;
        private readonly IRoutingService _routingService;
        private readonly IUnitOfWork _unitOfWork;

        public TripService(
            ITripRepository tripRepository,
            ITripRouteRepository tripRouteRepository,
            IDriverRepository driverRepository,
            IVehicleRepository vehicleRepository,
            IRoutingService routingService,
            IUnitOfWork unitOfWork)
        {
            _tripRepository = tripRepository;
            _tripRouteRepository = tripRouteRepository;
            _driverRepository = driverRepository;
            _vehicleRepository = vehicleRepository;
            _routingService = routingService;
            _unitOfWork = unitOfWork;
        }

        public async Task<TripDto?> GetTripByIdAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetWithDetailsAsync(tripId);
            return trip?.ToDto();
        }

        public async Task<IEnumerable<TripDto>> GetTripsByCustomerAsync(Guid customerId)
        {
            var trips = await _tripRepository.GetByCustomerIdAsync(customerId);
            return trips.Select(t => t.ToDto());
        }

        public async Task<IEnumerable<TripDto>> GetTripsByDriverAsync(Guid driverId)
        {
            var trips = await _tripRepository.GetByDriverIdAsync(driverId);
            return trips.Select(t => t.ToDto());
        }

        public async Task<IEnumerable<TripDto>> GetActiveTripsForDriverAsync(Guid driverId)
        {
            var trips = await _tripRepository.GetActiveTripsByDriverIdAsync(driverId);
            return trips.Select(t => t.ToDto());
        }

        public async Task<TripDto> RequestTripAsync(CreateTripDto dto)
        {
            // Get route estimate from OSRM
            var estimate = await _routingService.GetTripEstimateAsync(
                dto.PickupLatitude, dto.PickupLongitude,
                dto.DropoffLatitude, dto.DropoffLongitude,
                dto.TripType);

            var trip = dto.ToEntity();
            trip.EstimatedDistance = (decimal)estimate.DistanceKm;
            trip.EstimatedDuration = estimate.DurationMinutes;
            trip.EstimatedFare = estimate.EstimatedFare;

            var created = await _tripRepository.AddAsync(trip);
            return created.ToDto();
        }

        public async Task<TripDto> AssignDriverAsync(Guid tripId, Guid driverId, Guid vehicleId)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != TripStatus.Requested)
                throw new InvalidOperationException("Trip is not in a requestable state.");

            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.DriverId = driverId;
                trip.VehicleId = vehicleId;
                trip.TripStatus = TripStatus.Assigned;
                trip.AssignedAt = DateTime.UtcNow;
                trip.UpdatedAt = DateTime.UtcNow;

                driver.Status = DriverStatus.OnTrip;
                driver.UpdatedAt = DateTime.UtcNow;

                vehicle.Status = VehicleStatus.InUse;
                vehicle.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            return result!.ToDto();
        }

        public async Task<TripDto> StartTripAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != TripStatus.Assigned && trip.TripStatus != TripStatus.DriverEnRoute)
                throw new InvalidOperationException("Trip cannot be started in its current state.");

            trip.TripStatus = TripStatus.InProgress;
            trip.PickupTime = DateTime.UtcNow;
            trip.UpdatedAt = DateTime.UtcNow;

            await _tripRepository.UpdateAsync(trip);

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            return result!.ToDto();
        }

        public async Task<TripDto> CompleteTripAsync(Guid tripId, decimal actualDistance)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != TripStatus.InProgress)
                throw new InvalidOperationException("Trip is not in progress.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.TripStatus = TripStatus.Completed;
                trip.DropoffTime = DateTime.UtcNow;
                trip.ActualDistance = actualDistance;
                trip.ActualDuration = trip.PickupTime.HasValue
                    ? (int)(DateTime.UtcNow - trip.PickupTime.Value).TotalMinutes
                    : null;
                trip.ActualFare = trip.EstimatedFare;
                trip.PaymentStatus = PaymentStatus.Completed;
                trip.UpdatedAt = DateTime.UtcNow;

                if (trip.DriverId.HasValue)
                {
                    var driver = await _driverRepository.GetByIdAsync(trip.DriverId.Value);
                    if (driver != null)
                    {
                        driver.Status = DriverStatus.Active;
                        driver.TotalTrips = (driver.TotalTrips ?? 0) + 1;
                        driver.TotalRevenue = (driver.TotalRevenue ?? 0) + (trip.ActualFare ?? 0);
                        driver.UpdatedAt = DateTime.UtcNow;
                    }
                }

                if (trip.VehicleId.HasValue)
                {
                    var vehicle = await _vehicleRepository.GetByIdAsync(trip.VehicleId.Value);
                    if (vehicle != null)
                    {
                        vehicle.Status = VehicleStatus.Available;
                        vehicle.Mileage = (vehicle.Mileage ?? 0) + (int)actualDistance;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                    }
                }

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            return result!.ToDto();
        }

        public async Task<TripDto> CancelTripAsync(Guid tripId, string? reason)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus == TripStatus.Completed || trip.TripStatus == TripStatus.Cancelled)
                throw new InvalidOperationException("Trip cannot be cancelled in its current state.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.TripStatus = TripStatus.Cancelled;
                trip.CancellationReason = reason;
                trip.UpdatedAt = DateTime.UtcNow;

                if (trip.DriverId.HasValue)
                {
                    var driver = await _driverRepository.GetByIdAsync(trip.DriverId.Value);
                    if (driver != null)
                    {
                        driver.Status = DriverStatus.Active;
                        driver.UpdatedAt = DateTime.UtcNow;
                    }
                }

                if (trip.VehicleId.HasValue)
                {
                    var vehicle = await _vehicleRepository.GetByIdAsync(trip.VehicleId.Value);
                    if (vehicle != null)
                    {
                        vehicle.Status = VehicleStatus.Available;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                    }
                }

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            return result!.ToDto();
        }

        public async Task<TripDto> RateTripAsync(RateTripDto dto)
        {
            var trip = await _tripRepository.GetByIdAsync(dto.TripId)
                ?? throw new KeyNotFoundException($"Trip {dto.TripId} not found.");

            if (trip.TripStatus != TripStatus.Completed)
                throw new InvalidOperationException("Only completed trips can be rated.");

            if (dto.IsCustomerRating)
            {
                trip.CustomerRating = dto.Rating;
                trip.CustomerFeedback = dto.Feedback;
            }
            else
            {
                trip.DriverRating = dto.Rating;
                trip.DriverFeedback = dto.Feedback;
            }

            trip.UpdatedAt = DateTime.UtcNow;
            await _tripRepository.UpdateAsync(trip);

            var result = await _tripRepository.GetWithDetailsAsync(dto.TripId);
            return result!.ToDto();
        }

        public async Task<TripEstimateDto> GetTripEstimateAsync(
            decimal pickupLat, decimal pickupLon,
            decimal dropoffLat, decimal dropoffLon,
            TripType tripType)
        {
            return await _routingService.GetTripEstimateAsync(
                pickupLat, pickupLon,
                dropoffLat, dropoffLon,
                tripType);
        }

        public async Task<IEnumerable<RoutePointDto>> GetTripRouteAsync(Guid tripId)
        {
            var routePoints = await _tripRouteRepository.GetByTripIdAsync(tripId);
            return routePoints.Select(r => r.ToDto());
        }

        public async Task AddRoutePointsAsync(Guid tripId, IEnumerable<RoutePointDto> points)
        {
            var tripExists = await _tripRepository.ExistsAsync(tripId);
            if (!tripExists)
                throw new KeyNotFoundException($"Trip {tripId} not found.");

            var routePoints = points.Select(p => new TripRoute
            {
                Id = Guid.NewGuid(),
                TripId = tripId,
                Latitude = p.Latitude,
                Longitude = p.Longitude,
                Timestamp = p.Timestamp ?? DateTime.UtcNow
            });

            await _tripRouteRepository.AddBatchAsync(routePoints);
        }
    }
}
