using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DriveOps.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialMySql : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    KeycloakId = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Email = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PasswordHash = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FirstName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    LastName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PhoneNumber = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UserType = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "tinyint(1)", nullable: true, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    LastLoginAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    ProfileImageUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Address = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: true),
                    HireDate = table.Column<DateOnly>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Users__3214EC075B658B41", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Customers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    UserId = table.Column<Guid>(type: "char(36)", nullable: true, collation: "ascii_general_ci"),
                    Name = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PhoneNumber = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Email = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Rating = table.Column<decimal>(type: "decimal(3,2)", nullable: true, defaultValue: 5.00m),
                    TotalTrips = table.Column<int>(type: "int", nullable: true, defaultValue: 0),
                    PreferredPaymentMethod = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Customer__3214EC074429FDDF", x => x.Id);
                    table.ForeignKey(
                        name: "FK__Customers__UserI__5535A963",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Drivers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    UserId = table.Column<Guid>(type: "char(36)", nullable: false, collation: "ascii_general_ci"),
                    LicenseNumber = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    LicenseExpiryDate = table.Column<DateOnly>(type: "date", nullable: false),
                    EmergencyContactName = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    EmergencyContactPhone = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Status = table.Column<int>(type: "int", nullable: true, defaultValue: 1),
                    Rating = table.Column<decimal>(type: "decimal(3,2)", nullable: true, defaultValue: 5.00m),
                    TotalTrips = table.Column<int>(type: "int", nullable: true, defaultValue: 0),
                    TotalRevenue = table.Column<decimal>(type: "decimal(10,2)", nullable: true, defaultValue: 0m),
                    CurrentLatitude = table.Column<decimal>(type: "decimal(10,8)", nullable: true),
                    CurrentLongitude = table.Column<decimal>(type: "decimal(11,8)", nullable: true),
                    LastLocationUpdate = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    IsOnline = table.Column<bool>(type: "tinyint(1)", nullable: true, defaultValue: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Drivers__3214EC07B4817E92", x => x.Id);
                    table.ForeignKey(
                        name: "FK__Drivers__UserId__403A8C7D",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Vehicles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    LicensePlate = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Make = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Model = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Year = table.Column<int>(type: "int", nullable: false),
                    Color = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    VIN = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    InsurancePolicyNumber = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    InsuranceExpiryDate = table.Column<DateOnly>(type: "date", nullable: false),
                    RegistrationExpiryDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: true, defaultValue: 1),
                    Mileage = table.Column<int>(type: "int", nullable: true, defaultValue: 0),
                    FuelType = table.Column<int>(type: "int", nullable: false),
                    SeatingCapacity = table.Column<int>(type: "int", nullable: true, defaultValue: 4),
                    AssignedDriverId = table.Column<Guid>(type: "char(36)", nullable: true, collation: "ascii_general_ci"),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Vehicles__3214EC076C52E23F", x => x.Id);
                    table.ForeignKey(
                        name: "FK__Vehicles__Assign__4F7CD00D",
                        column: x => x.AssignedDriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Trips",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    CustomerId = table.Column<Guid>(type: "char(36)", nullable: false, collation: "ascii_general_ci"),
                    DriverId = table.Column<Guid>(type: "char(36)", nullable: true, collation: "ascii_general_ci"),
                    VehicleId = table.Column<Guid>(type: "char(36)", nullable: true, collation: "ascii_general_ci"),
                    TripStatus = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    TripType = table.Column<int>(type: "int", nullable: false, defaultValue: 1),
                    PickupLatitude = table.Column<decimal>(type: "decimal(10,8)", nullable: false),
                    PickupLongitude = table.Column<decimal>(type: "decimal(11,8)", nullable: false),
                    PickupAddress = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DropoffLatitude = table.Column<decimal>(type: "decimal(10,8)", nullable: false),
                    DropoffLongitude = table.Column<decimal>(type: "decimal(11,8)", nullable: false),
                    DropoffAddress = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    RequestedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    ScheduledAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    AssignedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    PickupTime = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    DropoffTime = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    EstimatedDistance = table.Column<decimal>(type: "decimal(8,2)", nullable: true),
                    ActualDistance = table.Column<decimal>(type: "decimal(8,2)", nullable: true),
                    EstimatedDuration = table.Column<int>(type: "int", nullable: true),
                    ActualDuration = table.Column<int>(type: "int", nullable: true),
                    EstimatedFare = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    ActualFare = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    PaymentMethod = table.Column<int>(type: "int", nullable: true),
                    PaymentStatus = table.Column<int>(type: "int", nullable: true, defaultValue: 1),
                    CustomerRating = table.Column<int>(type: "int", nullable: true),
                    DriverRating = table.Column<int>(type: "int", nullable: true),
                    CustomerFeedback = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    DriverFeedback = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    SpecialInstructions = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CancellationReason = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Trips__3214EC075F28D6FF", x => x.Id);
                    table.ForeignKey(
                        name: "FK__Trips__CustomerI__5CD6CB2B",
                        column: x => x.CustomerId,
                        principalTable: "Customers",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK__Trips__DriverId__5DCAEF64",
                        column: x => x.DriverId,
                        principalTable: "Drivers",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK__Trips__VehicleId__5EBF139D",
                        column: x => x.VehicleId,
                        principalTable: "Vehicles",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "TripRoutes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    TripId = table.Column<Guid>(type: "char(36)", nullable: false, collation: "ascii_general_ci"),
                    Latitude = table.Column<decimal>(type: "decimal(10,8)", nullable: false),
                    Longitude = table.Column<decimal>(type: "decimal(11,8)", nullable: false),
                    Timestamp = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__TripRout__3214EC077D385975", x => x.Id);
                    table.ForeignKey(
                        name: "FK__TripRoute__TripI__68487DD7",
                        column: x => x.TripId,
                        principalTable: "Trips",
                        principalColumn: "Id");
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_UserId",
                table: "Customers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Drivers_UserId",
                table: "Drivers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "UQ__Drivers__E88901666371942D",
                table: "Drivers",
                column: "LicenseNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TripRoutes_TripId",
                table: "TripRoutes",
                column: "TripId");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_CustomerId",
                table: "Trips",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_DriverId",
                table: "Trips",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_Trips_VehicleId",
                table: "Trips",
                column: "VehicleId");

            migrationBuilder.CreateIndex(
                name: "UQ__Users__A9D105348F0D93ED",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Vehicles_AssignedDriverId",
                table: "Vehicles",
                column: "AssignedDriverId");

            migrationBuilder.CreateIndex(
                name: "UQ__Vehicles__026BC15CA221806E",
                table: "Vehicles",
                column: "LicensePlate",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ__Vehicles__C5DF234CE959122A",
                table: "Vehicles",
                column: "VIN",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TripRoutes");

            migrationBuilder.DropTable(
                name: "Trips");

            migrationBuilder.DropTable(
                name: "Customers");

            migrationBuilder.DropTable(
                name: "Vehicles");

            migrationBuilder.DropTable(
                name: "Drivers");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
