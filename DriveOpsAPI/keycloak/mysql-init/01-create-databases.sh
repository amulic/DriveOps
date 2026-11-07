#!/bin/bash
# MySQL first-run init: creates the three databases and their users.
# Runs only on a fresh mysql_data volume. Credentials come from the container
# environment (.env -> docker compose), never from tracked files.
set -e

mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS keycloak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY '$KC_DB_PASSWORD';
GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';

CREATE DATABASE IF NOT EXISTS driveops_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'driveops_api'@'%' IDENTIFIED BY '$DRIVEOPS_API_DB_PASSWORD';
GRANT ALL PRIVILEGES ON driveops_api.* TO 'driveops_api'@'%';

CREATE DATABASE IF NOT EXISTS driveops_realtime CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'driveops_realtime'@'%' IDENTIFIED BY '$DRIVEOPS_REALTIME_DB_PASSWORD';
GRANT ALL PRIVILEGES ON driveops_realtime.* TO 'driveops_realtime'@'%';

FLUSH PRIVILEGES;
SQL
