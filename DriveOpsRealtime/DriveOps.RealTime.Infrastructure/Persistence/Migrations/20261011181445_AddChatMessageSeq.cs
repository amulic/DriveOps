using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DriveOps.RealTime.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddChatMessageSeq : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // MySQL rejects adding an AUTO_INCREMENT column without a key in the
            // same statement (error 1075), so the column and its unique index are
            // added in a single ALTER TABLE. Existing rows are backfilled with
            // sequence values automatically by MySQL.
            migrationBuilder.Sql(
                "ALTER TABLE `ChatMessages` ADD COLUMN `Seq` bigint NOT NULL AUTO_INCREMENT, ADD UNIQUE KEY `IX_ChatMessages_Seq` (`Seq`);");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChatMessages_Seq",
                table: "ChatMessages");

            migrationBuilder.DropColumn(
                name: "Seq",
                table: "ChatMessages");
        }
    }
}
