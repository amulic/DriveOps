# SignalR Microservice — Implementation Instructions

You are implementing a new .NET 8 SignalR microservice called **DriveOps.RealTime** that runs alongside the existing **DriveOps API**. These two services form a microservice backend communicating via **RabbitMQ**. The SignalR service handles all real-time features: live location tracking, chat (trip-scoped and general inbox), and push notifications for trip status changes.

---

## Existing DriveOps API Context

The existing API is a .NET 8 Web API with a layered architecture. You need to understand its domain model and service boundaries to design the event contracts and SignalR integration correctly.

### Entities & Key Properties

**User** — Base identity entity
- `Id` (Guid), `KeycloakId` (string?), `Email`, `FirstName`, `LastName`, `PhoneNumber`, `UserType` (int: Customer=0, Driver=1, Admin=2, Dispatcher=3), `IsActive` (bool?)

**Driver** — Service provider
- `Id` (Guid), `UserId` (Guid → User FK)
- Location: `CurrentLatitude` (decimal?), `CurrentLongitude` (decimal?), `LastLocationUpdate` (DateTime?), `IsOnline` (bool?)
- `Status` (DriverStatus?: Pending=0, Active=1, Inactive=2, Suspended=3, OnTrip=4)
- Nav: `Trips`, `Vehicles`, `User`

**Customer** — End user requesting trips
- `Id` (Guid), `UserId` (Guid? → User FK), `Name`, `Email`
- Nav: `Trips`, `User`

**Trip** — Core transaction entity
- `Id` (Guid), `CustomerId` (Guid), `DriverId` (Guid?), `VehicleId` (Guid?)
- `TripStatus` (Requested=1, Assigned=2, DriverEnRoute=3, InProgress=4, Completed=5, Cancelled=6, NoDriverAvailable=7)
- `TripType` (Standard=1, Premium=2, Shared=3, Scheduled=4)
- Location: `PickupLatitude/Longitude`, `DropoffLatitude/Longitude`, `PickupAddress`, `DropoffAddress`
- Timestamps: `RequestedAt`, `AssignedAt`, `PickupTime`, `DropoffTime`
- Metrics: `EstimatedDistance`, `ActualDistance`, `EstimatedFare`, `ActualFare`
- `PaymentStatus` (Pending=1, Completed=2, Failed=3, Refunded=4)

**TripRoute** — GPS breadcrumbs during a trip
- `Id` (Guid), `TripId` (Guid), `Latitude` (decimal), `Longitude` (decimal), `Timestamp` (DateTime)

### Trip Status Flow (critical for SignalR events)

```
Requested → Assigned → DriverEnRoute → InProgress → Completed
                                                  ↘ Cancelled
         ↘ NoDriverAvailable
```

Each transition is a moment where the SignalR service must push a real-time notification.

### Existing API Service Methods (relevant to events)

These are the existing API operations that should **publish RabbitMQ events** for the SignalR service to consume:

| API Method | Event to Publish |
|---|---|
| `RequestTripAsync(CreateTripDto)` | `TripRequested` |
| `AssignDriverAsync(tripId, driverId, vehicleId)` | `TripAssigned` |
| `StartTripAsync(tripId)` | `TripStarted` |
| `CompleteTripAsync(tripId, actualDistance)` | `TripCompleted` |
| `CancelTripAsync(tripId, reason)` | `TripCancelled` |
| `UpdateDriverLocationAsync(UpdateDriverLocationDto)` | `DriverLocationUpdated` |
| `SetDriverOnlineStatusAsync(driverId, isOnline)` | `DriverAvailabilityChanged` |
| `AddRoutePointsAsync(tripId, points)` | `TripRouteUpdated` |

### Existing Infrastructure

- **Database**: SQL Server via EF Core 9 (the API's own database — do NOT share it)
- **Auth**: Keycloak (JWT Bearer), realm `driveops-dev`, running on `http://localhost:8081`
- **Docker Compose** (existing): MySQL 8.0 (Keycloak backing store) + Keycloak 26.0.1
- **External**: OSRM routing service for route/fare estimates

### Existing Conventions (follow the same style)

- All methods async with `Async` suffix
- Constructor-based DI, services registered as Scoped
- DI registered via `IServiceCollection` extension methods (e.g., `AddApplication()`, `AddInfrastructure()`)
- DTOs mapped via manual extension methods (`ToDto()`, `ToEntity()`) — no AutoMapper
- Exceptions: `KeyNotFoundException` for missing entities, `InvalidOperationException` for business rule violations

---

## Architecture Overview

```
┌─────────────────────┐         RabbitMQ          ┌──────────────────────┐
│   DriveOps API      │ ──── publishes events ──→ │  DriveOps.RealTime   │
│   (REST, port 5001) │                           │  (SignalR, port 5002)│
│                     │ ←── publishes events ──── │                      │
│   SQL Server DB     │                           │  Own SQL Server DB   │
│   (DriveOpsDB)      │                           │  (DriveOpsRealTimeDB)│
└─────────────────────┘                           └──────────────────────┘
        ↑                                                  ↑
        │              Keycloak (JWT)                       │
        └──────────── shared auth ─────────────────────────┘
```

Both services validate JWT tokens from the same Keycloak realm. The SignalR service has its own database for chat messages, conversations, and location cache. All communication between services is asynchronous via RabbitMQ.

---

## Project Structure

Create a layered structure mirroring the existing API's conventions:

```
DriveOps.RealTime/                    ← Host project (Program.cs, Dockerfile)
DriveOps.RealTime.Hubs/               ← SignalR Hubs
DriveOps.RealTime.Services/           ← Business logic services
DriveOps.RealTime.Infrastructure/     ← DbContext, Repositories, RabbitMQ consumers
DriveOps.RealTime.Models/             ← Entities for chat, location cache
DriveOps.RealTime.Contracts/          ← Shared event contracts (DTOs for RabbitMQ messages)
```

The **Contracts** project should be referenceable by both the DriveOps API and the SignalR service (shared NuGet package or project reference), so both sides agree on event shapes.

---

## NuGet Packages

| Package | Purpose |
|---|---|
| `Microsoft.AspNetCore.SignalR` | SignalR server (included in ASP.NET Core SDK) |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | Keycloak JWT auth on hub connections |
| `Microsoft.EntityFrameworkCore` + `.SqlServer` | Own database |
| `RabbitMQ.Client` | RabbitMQ messaging |
| `Microsoft.Extensions.Hosting` | Background services for RabbitMQ consumers |

---

## 1. SignalR Hubs

### LocationHub (`/hubs/location`)

Handles real-time GPS streaming for drivers and customers tracking active trips.

**Server → Client methods:**
- `ReceiveDriverLocation(Guid driverId, decimal latitude, decimal longitude, DateTime timestamp)` — sent to customers tracking their driver during a trip
- `ReceiveNearbyDrivers(IEnumerable<DriverLocationDto> drivers)` — sent to customers looking for available drivers

**Client → Server methods:**
- `SendDriverLocation(decimal latitude, decimal longitude)` — driver sends GPS update; service caches location and publishes `DriverLocationUpdated` event to RabbitMQ for the API to persist
- `SubscribeToTripLocation(Guid tripId)` — customer joins a SignalR group for a specific trip's location stream
- `UnsubscribeFromTripLocation(Guid tripId)` — customer leaves the trip location group

**Groups:**
- `trip-location-{tripId}` — all clients tracking a specific trip's driver location

**RabbitMQ consumption:**
- Consumes `DriverLocationUpdated` events (from the API after persistence) to broadcast to relevant trip groups
- Consumes `TripRouteUpdated` events to push route breadcrumbs to tracking clients

### ChatHub (`/hubs/chat`)

Handles both trip-scoped chat and general inbox messaging.

**Server → Client methods:**
- `ReceiveMessage(ChatMessageDto message)` — new message received in any conversation
- `MessageSent(ChatMessageDto message)` — confirmation that a sent message was persisted
- `ConversationUpdated(ConversationDto conversation)` — conversation metadata changed (new message, read status)
- `UserTyping(Guid conversationId, Guid userId)` — typing indicator

**Client → Server methods:**
- `SendMessage(Guid conversationId, string content)` — send a message to a conversation
- `SendTripMessage(Guid tripId, string content)` — send a message in a trip-scoped conversation (auto-creates conversation if needed)
- `MarkAsRead(Guid conversationId)` — mark all messages in a conversation as read
- `StartTyping(Guid conversationId)` — notify other participants of typing
- `JoinConversation(Guid conversationId)` — join SignalR group for live updates
- `LeaveConversation(Guid conversationId)` — leave the group

**Groups:**
- `conversation-{conversationId}` — all participants in a conversation
- `user-inbox-{userId}` — user's personal notification channel for new conversations

**Trip-scoped chat logic:**
- When `SendTripMessage` is called, look up or create a `Conversation` with `TripId` set and participants = the trip's customer + driver
- Trip-scoped conversations are automatically closed when the trip completes (consume `TripCompleted` event)

### NotificationHub (`/hubs/notifications`)

Pushes trip lifecycle events and system notifications to connected clients.

**Server → Client methods:**
- `TripStatusChanged(TripStatusChangedDto dto)` — trip transitioned to a new status
- `TripAssigned(TripAssignedDto dto)` — driver + vehicle assigned (includes driver info, ETA)
- `NewTripRequest(TripRequestDto dto)` — broadcast to available drivers when a new trip is requested
- `SystemNotification(NotificationDto dto)` — generic notification (payment confirmation, rating received, etc.)

**Groups:**
- `user-{userId}` — personal notifications for a user
- `driver-{driverId}` — driver-specific notifications (new trip requests)
- `available-drivers` — all currently online, available drivers (for broadcasting new trip requests)

**RabbitMQ consumption:**
- Consumes `TripRequested` → broadcasts `NewTripRequest` to `available-drivers` group
- Consumes `TripAssigned` → sends `TripAssigned` to the customer's user group and `TripStatusChanged` to the driver
- Consumes `TripStarted` → sends `TripStatusChanged` to customer + driver groups
- Consumes `TripCompleted` → sends `TripStatusChanged` to customer + driver, triggers chat conversation close
- Consumes `TripCancelled` → sends `TripStatusChanged` to customer + driver groups

---

## 2. RabbitMQ Event Contracts

Define these in the **DriveOps.RealTime.Contracts** project so both services reference the same types.

### Events Published by DriveOps API → Consumed by SignalR Service

```csharp
public record TripRequestedEvent(
    Guid TripId,
    Guid CustomerId,
    TripStatus Status,
    TripType TripType,
    decimal PickupLatitude,
    decimal PickupLongitude,
    string PickupAddress,
    decimal DropoffLatitude,
    decimal DropoffLongitude,
    string DropoffAddress,
    decimal? EstimatedFare,
    int? EstimatedDuration,
    DateTime RequestedAt
);

public record TripAssignedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    Guid VehicleId,
    string DriverName,
    decimal DriverLatitude,
    decimal DriverLongitude,
    DateTime AssignedAt
);

public record TripStartedEvent(Guid TripId, Guid CustomerId, Guid DriverId, DateTime PickupTime);

public record TripCompletedEvent(
    Guid TripId,
    Guid CustomerId,
    Guid DriverId,
    decimal ActualDistance,
    decimal ActualFare,
    DateTime DropoffTime
);

public record TripCancelledEvent(Guid TripId, Guid CustomerId, Guid? DriverId, string? Reason, DateTime CancelledAt);

public record DriverLocationUpdatedEvent(
    Guid DriverId,
    decimal Latitude,
    decimal Longitude,
    DateTime Timestamp,
    Guid? ActiveTripId
);

public record DriverAvailabilityChangedEvent(Guid DriverId, bool IsOnline, DateTime Timestamp);

public record TripRouteUpdatedEvent(Guid TripId, IEnumerable<RoutePointEvent> Points);
public record RoutePointEvent(decimal Latitude, decimal Longitude, DateTime Timestamp);
```

### Events Published by SignalR Service → Consumed by DriveOps API

```csharp
// Driver location from SignalR client, needs to be persisted by the API
public record DriverLocationReceivedEvent(
    Guid DriverId,
    decimal Latitude,
    decimal Longitude,
    DateTime Timestamp
);
```

### RabbitMQ Exchanges & Queues

| Exchange | Type | Routing Key | Queue | Consumer |
|---|---|---|---|---|
| `driveops.trips` | topic | `trip.requested` | `realtime.trip.requested` | SignalR NotificationHub |
| `driveops.trips` | topic | `trip.assigned` | `realtime.trip.assigned` | SignalR NotificationHub |
| `driveops.trips` | topic | `trip.started` | `realtime.trip.started` | SignalR NotificationHub |
| `driveops.trips` | topic | `trip.completed` | `realtime.trip.completed` | SignalR NotificationHub + ChatHub |
| `driveops.trips` | topic | `trip.cancelled` | `realtime.trip.cancelled` | SignalR NotificationHub |
| `driveops.location` | topic | `driver.location` | `realtime.driver.location` | SignalR LocationHub |
| `driveops.location` | topic | `driver.availability` | `realtime.driver.availability` | SignalR LocationHub |
| `driveops.location` | topic | `trip.route` | `realtime.trip.route` | SignalR LocationHub |
| `driveops.realtime` | topic | `driver.location.received` | `api.driver.location` | DriveOps API (persist) |

---

## 3. Database Schema (DriveOpsRealTimeDB)

The SignalR service has its own SQL Server database. Use EF Core with the same conventions as the API (Guid PKs, `CreatedAt`/`UpdatedAt` timestamps).

### Entities

```csharp
public class Conversation
{
    public Guid Id { get; set; }
    public Guid? TripId { get; set; }              // null = general conversation, set = trip-scoped
    public bool IsActive { get; set; } = true;      // false when trip completes or manually closed
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<ConversationParticipant> Participants { get; set; }
    public ICollection<ChatMessage> Messages { get; set; }
}

public class ConversationParticipant
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid UserId { get; set; }
    public DateTime JoinedAt { get; set; }
    public DateTime? LastReadAt { get; set; }        // for unread message count

    public virtual Conversation Conversation { get; set; }
}

public class ChatMessage
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid SenderUserId { get; set; }
    public string Content { get; set; }
    public DateTime SentAt { get; set; }

    public virtual Conversation Conversation { get; set; }
}

public class DriverLocationCache
{
    public Guid DriverId { get; set; }              // PK, no auto-generate
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public bool IsOnline { get; set; }
    public Guid? ActiveTripId { get; set; }
    public DateTime LastUpdated { get; set; }
}

public class UserConnection
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ConnectionId { get; set; }         // SignalR connection ID
    public string HubName { get; set; }              // "location", "chat", "notifications"
    public DateTime ConnectedAt { get; set; }
}
```

---

## 4. Keycloak JWT Authentication on Hubs

Configure the same Keycloak realm as the API. SignalR sends the JWT as a query string parameter (WebSocket connections can't use Authorization headers).

```csharp
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.Authority = builder.Configuration["Keycloak:Authority"];
        options.Audience = builder.Configuration["Keycloak:Audience"];
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidateIssuer = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidAudience = builder.Configuration["Keycloak:Audience"],
            ValidIssuer = builder.Configuration["Keycloak:Authority"],
            ClockSkew = TimeSpan.Zero
        };

        // SignalR sends JWT via query string
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });
```

In hubs, get the authenticated user via:
```csharp
var keycloakId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
// or whatever claim Keycloak puts the subject in — check the token
```

Add `[Authorize]` attribute to all hub classes.

---

## 5. Connection Management

Implement a `ConnectionMappingService` (Scoped) that maintains user-to-connection mappings using the `UserConnection` database table.

**On hub connect (`OnConnectedAsync`):**
1. Extract userId from JWT claims
2. Store the mapping in `UserConnection` table
3. Add the connection to the `user-{userId}` SignalR group
4. If the user is a driver, check if they have an active trip → join `trip-location-{tripId}` group
5. If the user is a driver and online, join `available-drivers` group

**On hub disconnect (`OnDisconnectedAsync`):**
1. Remove from `UserConnection` table
2. Groups are cleaned up automatically by SignalR

---

## 6. RabbitMQ Consumer Architecture

Implement consumers as `BackgroundService` (hosted services) that listen on RabbitMQ queues and invoke hub methods via `IHubContext<T>`.

```csharp
public class TripEventConsumer : BackgroundService
{
    private readonly IHubContext<NotificationHub> _notificationHub;
    private readonly IHubContext<ChatHub> _chatHub;
    private readonly IConnection _rabbitConnection;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Set up channel, declare exchanges/queues, bind routing keys
        // On message received → deserialize → call appropriate hub method
    }
}
```

Create separate consumers for logical groupings:
- `TripEventConsumer` — handles all `trip.*` events → NotificationHub + ChatHub
- `LocationEventConsumer` — handles all `driver.*` and `trip.route` events → LocationHub

---

## 7. Docker Compose Addition

Add RabbitMQ and the SignalR service to the existing `docker-compose.yml`:

```yaml
  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    ports:
      - "5672:5672"     # AMQP
      - "15672:15672"   # Management UI
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    networks:
      - driveops-net
```

The existing services (mysql, keycloak) remain unchanged. Both the DriveOps API and SignalR service should depend on `rabbitmq`.

---

## 8. Changes Required in the Existing DriveOps API

The existing API needs to **publish events** to RabbitMQ when state changes occur. This requires:

1. Add `RabbitMQ.Client` NuGet package to `DriveOps.Infrastructure`
2. Add the shared `DriveOps.RealTime.Contracts` project reference
3. Create an `IEventPublisher` interface in `DriveOps.Application` and implement it in `DriveOps.Infrastructure`
4. Inject `IEventPublisher` into the existing services (TripService, DriverService) and publish events after successful database writes
5. Add a `DriverLocationReceivedEvent` consumer (BackgroundService) in the API that calls `UpdateDriverLocationAsync` when it receives location data from the SignalR service

**Do not break existing API behavior.** Event publishing is fire-and-forget — if RabbitMQ is down, the API operation should still succeed (log a warning, don't throw).

---

## 9. Implementation Order

1. **Contracts project** — define all event records first
2. **Models + DbContext** — entities, migrations, database creation
3. **Infrastructure** — RabbitMQ connection factory, publisher, consumer base class
4. **Connection management** — `ConnectionMappingService`, hub lifecycle hooks
5. **NotificationHub** — simplest hub, just pushes events to groups
6. **LocationHub** — driver location streaming + trip tracking groups
7. **ChatHub** — most complex, requires conversation CRUD + message persistence
8. **API integration** — add `IEventPublisher` to existing DriveOps API services
9. **Docker Compose** — add RabbitMQ, test end-to-end

---

## 10. Configuration (appsettings.json)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=DriveOpsRealTimeDB;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Keycloak": {
    "Authority": "http://localhost:8081/realms/driveops-dev",
    "Audience": "driveops-api"
  },
  "RabbitMQ": {
    "HostName": "localhost",
    "Port": 5672,
    "UserName": "guest",
    "Password": "guest"
  }
}
```

---

## Key Constraints

- Follow the same coding conventions as the existing API (async/await, manual DTO mappings, Scoped DI, extension methods for registration).
- The SignalR service must be independently deployable — no direct project references to the API's internal projects (only the shared Contracts project).
- All hub methods must be authenticated via `[Authorize]`.
- Handle RabbitMQ connection failures gracefully with retry logic.
- Use `decimal(10,8)` for latitude and `decimal(11,8)` for longitude in EF configurations, matching the existing API's column types.
