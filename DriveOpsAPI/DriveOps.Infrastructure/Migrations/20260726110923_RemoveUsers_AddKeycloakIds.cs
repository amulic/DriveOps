using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DriveOps.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveUsers_AddKeycloakIds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers'
                      AND INDEX_NAME = 'UQ__Drivers__KeycloakId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `UQ__Drivers__KeycloakId` ON `Drivers`', 'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customers'
                      AND INDEX_NAME = 'UQ__Customer__KeycloakId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `UQ__Customer__KeycloakId` ON `Customers`', 'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            // Backfill duplicate zero-Guid KeycloakId values so the unique index can be re-applied
            // (one keeper row is left as-is, the rest get fresh unique UUIDs).
            migrationBuilder.Sql(@"
                UPDATE `Customers`
                SET `KeycloakId` = UUID()
                WHERE `KeycloakId` = '00000000-0000-0000-0000-000000000000'
                  AND `Id` <> (
                      SELECT * FROM (
                          SELECT MIN(`Id`)
                          FROM `Customers`
                          WHERE `KeycloakId` = '00000000-0000-0000-0000-000000000000'
                      ) AS keeper
                  );
            ");

            migrationBuilder.Sql(@"
                UPDATE `Drivers`
                SET `KeycloakId` = UUID()
                WHERE `KeycloakId` = '00000000-0000-0000-0000-000000000000'
                  AND `Id` <> (
                      SELECT * FROM (
                          SELECT MIN(`Id`)
                          FROM `Drivers`
                          WHERE `KeycloakId` = '00000000-0000-0000-0000-000000000000'
                      ) AS keeper
                  );
            ");

            // Drop FKs if they exist (guarded for MySQL where dropping a non-existent FK throws)
            migrationBuilder.Sql(@"
                SET @fk_exists = (
                    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                    WHERE CONSTRAINT_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Customers'
                      AND CONSTRAINT_NAME = 'FK__Customers__UserI__5535A963'
                );
                SET @sql = IF(@fk_exists > 0,
                    'ALTER TABLE `Customers` DROP FOREIGN KEY `FK__Customers__UserI__5535A963`',
                    'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @fk_exists = (
                    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                    WHERE CONSTRAINT_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Drivers'
                      AND CONSTRAINT_NAME = 'FK__Drivers__UserId__403A8C7D'
                );
                SET @sql = IF(@fk_exists > 0,
                    'ALTER TABLE `Drivers` DROP FOREIGN KEY `FK__Drivers__UserId__403A8C7D`',
                    'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // Drop the Users table only if it exists
            migrationBuilder.Sql(@"
                SET @tbl_exists = (
                    SELECT COUNT(*) FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Users'
                );
                SET @sql = IF(@tbl_exists > 0, 'DROP TABLE `Users`', 'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // Drop indexes on UserId if they still exist
            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Drivers'
                      AND INDEX_NAME = 'IX_Drivers_UserId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `IX_Drivers_UserId` ON `Drivers`', 'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Customers'
                      AND INDEX_NAME = 'IX_Customers_UserId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `IX_Customers_UserId` ON `Customers`', 'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // Drop UserId column on Customers only if it still exists
            migrationBuilder.Sql(@"
                SET @col_exists = (
                    SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Customers'
                      AND COLUMN_NAME = 'UserId'
                );
                SET @sql = IF(@col_exists > 0,
                    'ALTER TABLE `Customers` DROP COLUMN `UserId`',
                    'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // Rename Drivers.UserId -> Drivers.KeycloakId only if UserId still exists
            migrationBuilder.Sql(@"
                SET @col_exists = (
                    SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Drivers'
                      AND COLUMN_NAME = 'UserId'
                );
                SET @sql = IF(@col_exists > 0,
                    'ALTER TABLE `Drivers` CHANGE COLUMN `UserId` `KeycloakId` char(36) NOT NULL',
                    'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // If KeycloakId is missing entirely, add it
            migrationBuilder.Sql(@"
                SET @col_exists = (
                    SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'Drivers'
                      AND COLUMN_NAME = 'KeycloakId'
                );
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Drivers` ADD COLUMN `KeycloakId` char(36) NOT NULL',
                    'SELECT 1');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            ");

            // Add profile columns to Drivers only if missing
            migrationBuilder.Sql(@"
                SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'Email');
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Drivers` ADD COLUMN `Email` varchar(255) CHARACTER SET utf8mb4 NOT NULL DEFAULT """"',
                    'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'FirstName');
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Drivers` ADD COLUMN `FirstName` varchar(100) CHARACTER SET utf8mb4 NOT NULL DEFAULT """"',
                    'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'LastName');
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Drivers` ADD COLUMN `LastName` varchar(100) CHARACTER SET utf8mb4 NOT NULL DEFAULT """"',
                    'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers' AND COLUMN_NAME = 'PhoneNumber');
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Drivers` ADD COLUMN `PhoneNumber` varchar(20) CHARACTER SET utf8mb4 NOT NULL DEFAULT """"',
                    'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            // Add KeycloakId to Customers if missing
            migrationBuilder.Sql(@"
                SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customers' AND COLUMN_NAME = 'KeycloakId');
                SET @sql = IF(@col_exists = 0,
                    'ALTER TABLE `Customers` ADD COLUMN `KeycloakId` char(36) NOT NULL DEFAULT ""00000000-0000-0000-0000-000000000000""',
                    'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            // Create unique indexes
            migrationBuilder.Sql(@"CREATE UNIQUE INDEX `UQ__Drivers__KeycloakId` ON `Drivers` (`KeycloakId`);");
            migrationBuilder.Sql(@"CREATE UNIQUE INDEX `UQ__Customer__KeycloakId` ON `Customers` (`KeycloakId`);");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Drivers'
                      AND INDEX_NAME = 'UQ__Drivers__KeycloakId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `UQ__Drivers__KeycloakId` ON `Drivers`', 'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"
                SET @idx_exists = (
                    SELECT COUNT(*) FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Customers'
                      AND INDEX_NAME = 'UQ__Customer__KeycloakId'
                );
                SET @sql = IF(@idx_exists > 0, 'DROP INDEX `UQ__Customer__KeycloakId` ON `Customers`', 'SELECT 1');
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
            ");

            migrationBuilder.Sql(@"ALTER TABLE `Drivers` DROP COLUMN IF EXISTS `Email`;");
            migrationBuilder.Sql(@"ALTER TABLE `Drivers` DROP COLUMN IF EXISTS `FirstName`;");
            migrationBuilder.Sql(@"ALTER TABLE `Drivers` DROP COLUMN IF EXISTS `LastName`;");
            migrationBuilder.Sql(@"ALTER TABLE `Drivers` DROP COLUMN IF EXISTS `PhoneNumber`;");
            migrationBuilder.Sql(@"ALTER TABLE `Customers` DROP COLUMN IF EXISTS `KeycloakId`;");

            migrationBuilder.Sql(@"ALTER TABLE `Drivers` CHANGE COLUMN `KeycloakId` `UserId` char(36) NOT NULL;");
            migrationBuilder.Sql(@"ALTER TABLE `Customers` ADD COLUMN `UserId` char(36) NULL;");

            migrationBuilder.Sql(@"
                CREATE TABLE `Users` (
                    `Id` char(36) NOT NULL DEFAULT (UUID()),
                    `Address` varchar(500) CHARACTER SET utf8mb4 NULL,
                    `CreatedAt` datetime(6) NULL DEFAULT CURRENT_TIMESTAMP(6),
                    `DateOfBirth` date NULL,
                    `Email` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
                    `FirstName` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
                    `HireDate` date NULL,
                    `IsActive` tinyint(1) NULL DEFAULT 1,
                    `KeycloakId` longtext CHARACTER SET utf8mb4 NULL,
                    `LastLoginAt` datetime(6) NULL,
                    `LastName` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
                    `PasswordHash` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
                    `PhoneNumber` varchar(20) CHARACTER SET utf8mb4 NOT NULL,
                    `ProfileImageUrl` varchar(500) CHARACTER SET utf8mb4 NULL,
                    `UpdatedAt` datetime(6) NULL DEFAULT CURRENT_TIMESTAMP(6),
                    `UserType` int NOT NULL,
                    PRIMARY KEY (`Id`)
                ) CHARACTER SET=utf8mb4;
            ");

            migrationBuilder.Sql(@"CREATE INDEX `IX_Drivers_UserId` ON `Drivers` (`UserId`);");
            migrationBuilder.Sql(@"CREATE INDEX `IX_Customers_UserId` ON `Customers` (`UserId`);");
            migrationBuilder.Sql(@"CREATE UNIQUE INDEX `UQ__Users__A9D105348F0D93ED` ON `Users` (`Email`);");

            migrationBuilder.Sql(@"ALTER TABLE `Customers` ADD CONSTRAINT `FK__Customers__UserI__5535A963` FOREIGN KEY (`UserId`) REFERENCES `Users` (`Id`);");
            migrationBuilder.Sql(@"ALTER TABLE `Drivers` ADD CONSTRAINT `FK__Drivers__UserId__403A8C7D` FOREIGN KEY (`UserId`) REFERENCES `Users` (`Id`);");
        }
    }
}
