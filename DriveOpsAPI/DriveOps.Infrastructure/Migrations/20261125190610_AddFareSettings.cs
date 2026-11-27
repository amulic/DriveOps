using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DriveOps.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFareSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FareSettings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    BaseFare = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PerKmRate = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PerMinuteRate = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PremiumMultiplier = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SharedMultiplier = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpdatedBy = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__FareSettings__3214EC07", x => x.Id);
                })
                .Annotation("MySql:CharSet", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FareSettings");
        }
    }
}
