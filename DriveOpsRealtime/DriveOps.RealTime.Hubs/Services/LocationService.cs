

using DriveOps.RealTime.Contracts.DTOs;
using DriveOps.RealTime.Contracts.Events;
using DriveOps.RealTime.Contracts.Interfaces;
using DriveOps.RealTime.Infrastructure.Persistence;
using DriveOps.RealTime.Infrastructure.RabbitMQ;
using DriveOps.RealTime.Models.Entities;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DriveOps.RealTime.Hubs.Services;

    public class LocationService : ILocationService
    {
        private readonly RealTimeDbContext _dbContext;
        private readonly IHubContext<LocationHub> _locationHub;
        private readonly IEventPublisher _eventPublisher;
        private readonly ILogger<LocationService> _logger;

        public LocationService(
            RealTimeDbContext dbContext,
            IHubContext<LocationHub> locationHub,
            IEventPublisher eventPublisher,
            ILogger<LocationService> logger)
        {
            _dbContext = dbContext;
            _locationHub = locationHub;
            _eventPublisher = eventPublisher;
            _logger = logger;
        }

        public async Task HandleDriverLocationUpdatedAsync(DriverLocationUpdatedEvent locationEvent)
        {
            var cache = await _dbContext.DriverLocationCaches.FindAsync(locationEvent.DriverId);
            if (cache == null)
            {
                cache = new DriverLocationCache
                {
                    DriverId = locationEvent.DriverId,
                    Latitude = locationEvent.Latitude,
                    Longitude = locationEvent.Longitude,
                    ActiveTripId = locationEvent.ActiveTripId,
                    LastUpdated = locationEvent.Timestamp
                };
                _dbContext.DriverLocationCaches.Add(cache);
            }
            else
            {
                cache.Latitude = locationEvent.Latitude;
                cache.Longitude = locationEvent.Longitude;
                cache.ActiveTripId = locationEvent.ActiveTripId;
                cache.LastUpdated = locationEvent.Timestamp;
            }
            await _dbContext.SaveChangesAsync();

            if (locationEvent.ActiveTripId.HasValue)
            {
                await _locationHub.Clients
                    .Group($"trip-location-{locationEvent.ActiveTripId.Value}")
                    .SendAsync("ReceiveDriverLocation",
                        locationEvent.DriverId,
                        locationEvent.Latitude,
                        locationEvent.Longitude,
                        locationEvent.Timestamp);
            }
        }

        public async Task HandleDriverAvailabilityChangedAsync(DriverAvailabilityChangedEvent availabilityEvent)
        {
            var cache = await _dbContext.DriverLocationCaches.FindAsync(availabilityEvent.DriverId);
            if (cache != null)
            {
                cache.IsOnline = availabilityEvent.IsOnline;
                cache.LastUpdated = availabilityEvent.Timestamp;
                await _dbContext.SaveChangesAsync();
            }
        }

        public async Task HandleTripRouteUpdatedAsync(TripRouteUpdatedEvent routeEvent)
        {
            await _locationHub.Clients
                .Group($"trip-location-{routeEvent.TripId}")
                .SendAsync("ReceiveTripRoute", routeEvent.TripId, routeEvent.Points);
        }

        public async Task UpdateDriverLocationFromClientAsync(Guid driverId, decimal latitude, decimal longitude)
        {
            var cache = await _dbContext.DriverLocationCaches.FindAsync(driverId);
            if (cache == null)
            {
                cache = new DriverLocationCache
                {
                    DriverId = driverId,
                    Latitude = latitude,
                    Longitude = longitude,
                    IsOnline = true,
                    LastUpdated = DateTime.UtcNow
                };
                _dbContext.DriverLocationCaches.Add(cache);
            }
            else
            {
                cache.Latitude = latitude;
                cache.Longitude = longitude;
                cache.LastUpdated = DateTime.UtcNow;
            }
            await _dbContext.SaveChangesAsync();

            if (cache.ActiveTripId.HasValue)
            {
                await _locationHub.Clients
                    .Group($"trip-location-{cache.ActiveTripId.Value}")
                    .SendAsync("ReceiveDriverLocation", driverId, latitude, longitude, DateTime.UtcNow);
            }

            await _eventPublisher.PublishAsync("driveops.realtime", "driver.location.received",
                new DriverLocationReceivedEvent(driverId, latitude, longitude, DateTime.UtcNow));
        }

        public async Task<IEnumerable<DriverLocationDto>> GetNearbyDriversAsync(decimal latitude, decimal longitude, decimal radiusKm)
        {
            var drivers = await _dbContext.DriverLocationCaches
                .Where(d => d.IsOnline)
                .ToListAsync();

            return drivers
                .Where(d => CalculateDistanceKm(latitude, longitude, d.Latitude, d.Longitude) <= (double)radiusKm)
                .Select(d => new DriverLocationDto(d.DriverId, d.Latitude, d.Longitude, d.IsOnline, d.LastUpdated));
        }

        private static double CalculateDistanceKm(decimal lat1, decimal lon1, decimal lat2, decimal lon2)
        {
            const double R = 6371;
            var dLat = ToRadians((double)(lat2 - lat1));
            var dLon = ToRadians((double)(lon2 - lon1));
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians((double)lat1)) * Math.Cos(ToRadians((double)lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        }

        private static double ToRadians(double deg) => deg * (Math.PI / 180);
    }

