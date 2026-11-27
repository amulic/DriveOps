using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DriveOps.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVehicleServiceRecordsAndMileagePrecision : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<decimal>(
                name: "Mileage",
                table: "Vehicles",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true,
                defaultValue: 0m,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true,
                oldDefaultValue: 0);

            migrationBuilder.CreateTable(
                name: "VehicleServiceRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "char(36)", nullable: false, defaultValueSql: "(UUID())", collation: "ascii_general_ci"),
                    VehicleId = table.Column<Guid>(type: "char(36)", nullable: false, collation: "ascii_general_ci"),
                    ServiceDate = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    ServiceType = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    PerformedBy = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    OdometerKm = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    Cost = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true, defaultValueSql: "CURRENT_TIMESTAMP(6)")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__VehicleServiceRecords__3214EC07", x => x.Id);
                    table.ForeignKey(
                        name: "FK__VehicleServiceRecords__VehicleId",
                        column: x => x.VehicleId,
                        principalTable: "Vehicles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleServiceRecords_VehicleId",
                table: "VehicleServiceRecords",
                column: "VehicleId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "VehicleServiceRecords");

            migrationBuilder.AlterColumn<int>(
                name: "Mileage",
                table: "Vehicles",
                type: "int",
                nullable: true,
                defaultValue: 0,
                oldClrType: typeof(decimal),
                oldType: "decimal(10,2)",
                oldPrecision: 10,
                oldScale: 2,
                oldNullable: true,
                oldDefaultValue: 0m);
        }
    }
}
