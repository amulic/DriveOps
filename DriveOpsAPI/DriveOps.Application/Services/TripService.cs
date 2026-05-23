using DriveOps.Application.DTOs;
using DriveOps.Application.Helpers;
using DriveOps.Application.Interfaces;
using DriveOps.Application.Mappings;
using DriveOps.Model.Entity;
using DriveOps.RealTime.Contracts.Enums;
using DriveOps.RealTime.Contracts.Events;
using ModelEnums = DriveOps.Model.Enums;

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
        private readonly IEventPublisher _eventPublisher;

        public TripService(
            ITripRepository tripRepository,
            ITripRouteRepository tripRouteRepository,
            IDriverRepository driverRepository,
            IVehicleRepository vehicleRepository,
            IRoutingService routingService,
            IUnitOfWork unitOfWork,
            IEventPublisher eventPublisher)
        {
            _tripRepository = tripRepository;
            _tripRouteRepository = tripRouteRepository;
            _driverRepository = driverRepository;
            _vehicleRepository = vehicleRepository;
            _routingService = routingService;
            _unitOfWork = unitOfWork;
            _eventPublisher = eventPublisher;
        }

        public async Task<PaginatedResult<TripDto>> GetAllTripsAsync(int page = 1, int pageSize = 20)
        {
            var trips = await _tripRepository.GetAllTripsAsync(page, pageSize);
            var total = await _tripRepository.CountAllTripsAsync();
            return new PaginatedResult<TripDto>
            {
                Items = trips.Select(t => t.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<TripDto?> GetTripByIdAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetWithDetailsAsync(tripId);
            return trip?.ToDto();
        }

        public async Task<PaginatedResult<TripDto>> GetTripsByCustomerAsync(Guid customerId, int page = 1, int pageSize = 20)
        {
            var trips = await _tripRepository.GetByCustomerIdAsync(customerId, page, pageSize);
            var total = await _tripRepository.CountByCustomerIdAsync(customerId);
            return new PaginatedResult<TripDto>
            {
                Items = trips.Select(t => t.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<PaginatedResult<TripDto>> GetTripsByDriverAsync(Guid driverId, int page = 1, int pageSize = 20)
        {
            var trips = await _tripRepository.GetByDriverIdAsync(driverId, page, pageSize);
            var total = await _tripRepository.CountByDriverIdAsync(driverId);
            return new PaginatedResult<TripDto>
            {
                Items = trips.Select(t => t.ToDto()).ToList(),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
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
                (DriveOps.RealTime.Contracts.Enums.TripType)(int)dto.TripType);

            var trip = dto.ToEntity();
            trip.EstimatedDistance = (decimal)estimate.DistanceKm;
            trip.EstimatedDuration = estimate.DurationMinutes;
            trip.EstimatedFare = estimate.EstimatedFare;

            await _tripRepository.AddAsync(trip);
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.trips", "trip.requested",
                new TripRequestedEvent(
                    trip.Id, trip.CustomerId,
                    (TripStatus)trip.TripStatus,
                    (TripType)trip.TripType,
                    dto.PickupLatitude, dto.PickupLongitude, dto.PickupAddress ?? "",
                    dto.DropoffLatitude, dto.DropoffLongitude, dto.DropoffAddress ?? "",
                    trip.EstimatedFare, trip.EstimatedDuration, trip.RequestedAt ?? DateTime.UtcNow));

            return trip.ToDto();
        }

        public async Task<TripDto> AssignDriverAsync(Guid tripId, Guid driverId, Guid vehicleId)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.Requested)
                throw new InvalidOperationException("Trip is not in a requestable state.");

            var driver = await _driverRepository.GetByIdAsync(driverId)
                ?? throw new KeyNotFoundException($"Driver {driverId} not found.");

            var vehicle = await _vehicleRepository.GetByIdAsync(vehicleId)
                ?? throw new KeyNotFoundException($"Vehicle {vehicleId} not found.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.DriverId = driverId;
                trip.VehicleId = vehicleId;
                trip.TripStatus = ModelEnums.TripStatus.Assigned;
                trip.AssignedAt = DateTime.UtcNow;
                trip.UpdatedAt = DateTime.UtcNow;

                driver.Status = ModelEnums.DriverStatus.OnTrip;
                driver.UpdatedAt = DateTime.UtcNow;

                vehicle.Status = ModelEnums.VehicleStatus.InUse;
                vehicle.UpdatedAt = DateTime.UtcNow;

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            var customerUserId = result?.Customer?.UserId;
            var driverDisplayName = result?.Driver?.User != null
                ? $"{result.Driver.User.FirstName} {result.Driver.User.LastName}".Trim()
                : string.Empty;

            await _eventPublisher.PublishAsync("driveops.trips", "trip.assigned",
                new TripAssignedEvent(
                    tripId, trip.CustomerId, driverId, vehicleId,
                    driverDisplayName,
                    driver.CurrentLatitude ?? 0, driver.CurrentLongitude ?? 0,
                    trip.AssignedAt ?? DateTime.UtcNow,
                    customerUserId,
                    driver.UserId));

            return result!.ToDto();
        }

        public async Task<TripDto> StartTripAsync(Guid tripId)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.Assigned && trip.TripStatus != ModelEnums.TripStatus.DriverEnRoute)
                throw new InvalidOperationException("Trip cannot be started in its current state.");

            trip.TripStatus = ModelEnums.TripStatus.InProgress;
            trip.PickupTime = DateTime.UtcNow;
            trip.UpdatedAt = DateTime.UtcNow;

            await _tripRepository.UpdateAsync(trip);
            await _unitOfWork.SaveChangesAsync();

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            var customerUserId = result?.Customer?.UserId;

            await _eventPublisher.PublishAsync("driveops.trips", "trip.started",
                new TripStartedEvent(tripId, trip.CustomerId, trip.DriverId!.Value, trip.PickupTime!.Value, customerUserId));

            return result!.ToDto();
        }

        public async Task<TripDto> CompleteTripAsync(Guid tripId, decimal actualDistance)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.InProgress)
                throw new InvalidOperationException("Trip is not in progress.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.TripStatus = ModelEnums.TripStatus.Completed;
                trip.DropoffTime = DateTime.UtcNow;
                trip.ActualDistance = actualDistance;
                trip.ActualDuration = trip.PickupTime.HasValue
                    ? (int)(DateTime.UtcNow - trip.PickupTime.Value).TotalMinutes
                    : null;
                trip.ActualFare = FareCalculator.Calculate(
                    actualDistance,
                    trip.ActualDuration ?? trip.EstimatedDuration ?? 0,
                    (DriveOps.RealTime.Contracts.Enums.TripType)(int)trip.TripType);
                trip.PaymentStatus = ModelEnums.PaymentStatus.Completed;
                trip.UpdatedAt = DateTime.UtcNow;

                if (trip.DriverId.HasValue)
                {
                    var driver = await _driverRepository.GetByIdAsync(trip.DriverId.Value);
                    if (driver != null)
                    {
                        driver.Status = ModelEnums.DriverStatus.Active;
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
                        vehicle.Status = ModelEnums.VehicleStatus.Available;
                        vehicle.Mileage = (vehicle.Mileage ?? 0) + (int)actualDistance;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                    }
                }

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            var customerUserId = result?.Customer?.UserId;

            await _eventPublisher.PublishAsync("driveops.trips", "trip.completed",
                new TripCompletedEvent(
                    tripId, trip.CustomerId, trip.DriverId!.Value,
                    actualDistance, trip.ActualFare ?? 0, trip.DropoffTime ?? DateTime.UtcNow, customerUserId));

            return result!.ToDto();
        }

        public async Task<TripDto> CancelTripAsync(Guid tripId, string? reason)
        {
            var trip = await _tripRepository.GetByIdAsync(tripId)
                ?? throw new KeyNotFoundException($"Trip {tripId} not found.");

            if (trip.TripStatus == ModelEnums.TripStatus.Completed || trip.TripStatus == ModelEnums.TripStatus.Cancelled)
                throw new InvalidOperationException("Trip cannot be cancelled in its current state.");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                trip.TripStatus = ModelEnums.TripStatus.Cancelled;
                trip.CancellationReason = reason;
                trip.UpdatedAt = DateTime.UtcNow;

                if (trip.DriverId.HasValue)
                {
                    var driver = await _driverRepository.GetByIdAsync(trip.DriverId.Value);
                    if (driver != null)
                    {
                        driver.Status = ModelEnums.DriverStatus.Active;
                        driver.UpdatedAt = DateTime.UtcNow;
                    }
                }

                if (trip.VehicleId.HasValue)
                {
                    var vehicle = await _vehicleRepository.GetByIdAsync(trip.VehicleId.Value);
                    if (vehicle != null)
                    {
                        vehicle.Status = ModelEnums.VehicleStatus.Available;
                        vehicle.UpdatedAt = DateTime.UtcNow;
                    }
                }

                await _unitOfWork.SaveChangesAsync();
            });

            var result = await _tripRepository.GetWithDetailsAsync(tripId);
            var customerUserId = result?.Customer?.UserId;

            await _eventPublisher.PublishAsync("driveops.trips", "trip.cancelled",
                new TripCancelledEvent(
                    tripId, trip.CustomerId, trip.DriverId, reason, DateTime.UtcNow, customerUserId));

            return result!.ToDto();
        }

        public async Task<TripDto> RateTripAsync(RateTripDto dto)
        {
            var trip = await _tripRepository.GetByIdAsync(dto.TripId)
                ?? throw new KeyNotFoundException($"Trip {dto.TripId} not found.");

            if (trip.TripStatus != ModelEnums.TripStatus.Completed)
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
            await _unitOfWork.SaveChangesAsync();

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
                (DriveOps.RealTime.Contracts.Enums.TripType)(int)tripType);
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
            await _unitOfWork.SaveChangesAsync();

            await _eventPublisher.PublishAsync("driveops.location", "trip.route",
                new TripRouteUpdatedEvent(tripId,
                    points.Select(p => new RoutePointEvent(p.Latitude, p.Longitude, p.Timestamp ?? DateTime.UtcNow))));
        }
    }
}
