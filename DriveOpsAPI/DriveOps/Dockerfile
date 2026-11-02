# Build context is the repository root (see DriveOpsAPI/docker-compose.yml).
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY DriveOpsAPI/DriveOps/DriveOps.csproj DriveOpsAPI/DriveOps/
COPY DriveOpsAPI/DriveOps.API/DriveOps.API.csproj DriveOpsAPI/DriveOps.API/
COPY DriveOpsAPI/DriveOps.Application/DriveOps.Application.csproj DriveOpsAPI/DriveOps.Application/
COPY DriveOpsAPI/DriveOps.Infrastructure/DriveOps.Infrastructure.csproj DriveOpsAPI/DriveOps.Infrastructure/
COPY DriveOpsAPI/DriveOps.Model/DriveOps.Model.csproj DriveOpsAPI/DriveOps.Model/
COPY DriveOpsRealtime/DriveOps.RealTime.Contracts/DriveOps.RealTime.Contracts.csproj DriveOpsRealtime/DriveOps.RealTime.Contracts/
RUN dotnet restore DriveOpsAPI/DriveOps/DriveOps.csproj

COPY DriveOpsAPI/ DriveOpsAPI/
COPY DriveOpsRealtime/DriveOps.RealTime.Contracts/ DriveOpsRealtime/DriveOps.RealTime.Contracts/
RUN dotnet publish DriveOpsAPI/DriveOps/DriveOps.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DriveOps.dll"]
