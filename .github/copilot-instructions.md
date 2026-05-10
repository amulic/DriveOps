# Copilot Instructions for DriveOps

## Build & Run

```bash
# Restore and build (from DriveOpsAPI/)
dotnet restore DriveOpsAPI.sln
dotnet build DriveOpsAPI.sln

# Run the API (from DriveOpsAPI/DriveOps/)
dotnet run --project DriveOps/DriveOps.csproj

# Start infrastructure (MySQL + Keycloak) — from DriveOpsAPI/
docker compose up -d

# EF Core migrations (from DriveOpsAPI/)
dotnet ef migrations add <Name> --project DriveOps.Infrastructure --startup-project DriveOps
dotnet ef database update --project DriveOps.Infrastructure --startup-project DriveOps
```

No test projects exist yet.

## Architecture

.NET 8 Web API using a **layered architecture** with the **Repository + Unit of Work** pattern:

```
DriveOps (host)  →  DriveOps.API (controllers/DTOs)  →  DriveOps.Application (services)
                                                          ↓
                                                      DriveOps.Infrastructure (repos, DbContext, external services)
                                                          ↓
                                                      DriveOps.Model (entities, enums)
```

- **DriveOps** — Entry point. Program.cs wires up DI, auth, CORS, Swagger. No business logic here.
- **DriveOps.API** — Controllers, request/response DTOs, controller-level mapping extensions.
- **DriveOps.Application** — Service interfaces and implementations, application-level DTOs, entity↔DTO mappings.
- **DriveOps.Infrastructure** — `ApplicationDbContext` (EF Core + SQL Server), generic `Repository<T>`, entity-specific repositories, `UnitOfWork`, `OsrmRoutingService`.
- **DriveOps.Model** — Pure entity classes (`Customer`, `Driver`, `Trip`, `TripRoute`, `User`, `Vehicle`) and enums.
- **DriveOps.Services** — Utility services (currently `CarService`); not part of the main dependency chain.

### Infrastructure

- **Database**: SQL Server via EF Core 9. Connection string from `appsettings.json` key `ConnectionStrings:DefaultConnection`.
- **Auth**: Keycloak (JWT Bearer). Config in `appsettings.json` under `Keycloak:Authority` and `Keycloak:Audience`.
- **Docker Compose**: Runs MySQL 8.0 (for Keycloak's backing store) and Keycloak 26.0.1. Keycloak realm imports from `keycloak/realms/`.
- **External**: OSRM routing service (`http://router.project-osrm.org/`) via `HttpClient` in `OsrmRoutingService`.

## Conventions

### DI Registration

Each layer exposes an `IServiceCollection` extension method for its registrations:
- `builder.Services.AddApplication()` — registers services as Scoped.
- `builder.Services.AddInfrastructure(connectionString)` — registers DbContext, repositories, HttpClient-based services.

New services/repositories must be registered in the corresponding extension method (`ApplicationServiceExtensions.cs` or `InfrastructureServiceExtensions.cs`).

### Controller Pattern

- Route: `[Route("api/[controller]")]` with `[ApiController]`.
- One service injected per controller via constructor.
- Return `Ok(entity.ToResponse())`, `CreatedAtAction(...)`, `NotFound()`, or `NoContent()`.

### Service Pattern

- All methods are async (suffix `Async`).
- Throw `KeyNotFoundException` for missing entities, `InvalidOperationException` for business rule violations.
- Use `_unitOfWork.ExecuteInTransactionAsync(...)` for multi-entity writes with `SaveChangesAsync()` inside.

### Repository Pattern

- `Repository<T>` provides `GetByIdAsync`, `GetAllAsync`, `AddAsync`, `UpdateAsync`, `DeleteAsync`, `FirstOrDefaultAsync`, `CountAsync`.
- Entity-specific repositories add methods with `.Include()` for eager loading (e.g., `GetWithVehiclesAsync`).

### DTO Mapping

Manual extension methods — no AutoMapper. Two mapping layers:
- **Application layer**: `ToDto()` / `ToEntity()` for entity↔application DTO conversion.
- **API layer**: `ToApplicationDto()` / `ToResponse()` for request→application DTO and application DTO→response conversion.

### Naming

| Element | Pattern | Example |
|---|---|---|
| Controllers | `{Entity}Controller` | `DriverController` |
| Services | `{Entity}Service` / `I{Entity}Service` | `TripService` |
| Repositories | `{Entity}Repository` / `I{Entity}Repository` | `VehicleRepository` |
| Application DTOs | `{Entity}Dto`, `Create{Entity}Dto`, `Update{Entity}Dto` | `DriverDto` |
| Request/Response | `Create{Entity}Request`, `{Entity}Response` | `CreateDriverRequest` |
| Async methods | `{Verb}{Entity}Async` | `GetDriverByIdAsync` |

### Adding a New Entity

1. Add entity class to `DriveOps.Model`.
2. Add `DbSet<T>` and EF configuration in `DriveOps.Infrastructure`.
3. Create repository interface + implementation; register in `InfrastructureServiceExtensions`.
4. Create application DTOs + mappings + service interface/implementation; register in `ApplicationServiceExtensions`.
5. Create request/response DTOs + controller-level mappings + controller in `DriveOps.API`.
6. Generate and apply an EF migration.
