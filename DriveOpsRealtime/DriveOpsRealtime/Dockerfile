# Build context is the repository root (see DriveOpsAPI/docker-compose.yml).
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY DriveOpsRealtime/DriveOpsRealtime/DriveOpsRealtime.csproj DriveOpsRealtime/DriveOpsRealtime/
COPY DriveOpsRealtime/DriveOps.RealTime.Hubs/DriveOps.RealTime.Hubs.csproj DriveOpsRealtime/DriveOps.RealTime.Hubs/
COPY DriveOpsRealtime/DriveOps.RealTime.Services/DriveOps.RealTime.Services.csproj DriveOpsRealtime/DriveOps.RealTime.Services/
COPY DriveOpsRealtime/DriveOps.RealTime.Infrastructure/DriveOps.RealTime.Infrastructure.csproj DriveOpsRealtime/DriveOps.RealTime.Infrastructure/
COPY DriveOpsRealtime/DriveOps.RealTime.Models/DriveOps.RealTime.Models.csproj DriveOpsRealtime/DriveOps.RealTime.Models/
COPY DriveOpsRealtime/DriveOps.RealTime.Contracts/DriveOps.RealTime.Contracts.csproj DriveOpsRealtime/DriveOps.RealTime.Contracts/
RUN dotnet restore DriveOpsRealtime/DriveOpsRealtime/DriveOpsRealtime.csproj

COPY DriveOpsRealtime/ DriveOpsRealtime/
RUN dotnet publish DriveOpsRealtime/DriveOpsRealtime/DriveOpsRealtime.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DriveOpsRealtime.dll"]
