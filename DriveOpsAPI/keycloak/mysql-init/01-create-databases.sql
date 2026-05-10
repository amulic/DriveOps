CREATE DATABASE IF NOT EXISTS keycloak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'keycloak'@'%' IDENTIFIED BY 'keycloak';
GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';

CREATE DATABASE IF NOT EXISTS driveops_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'driveops_api'@'%' IDENTIFIED BY 'driveops_api';
GRANT ALL PRIVILEGES ON driveops_api.* TO 'driveops_api'@'%';

CREATE DATABASE IF NOT EXISTS driveops_realtime CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'driveops_realtime'@'%' IDENTIFIED BY 'driveops_realtime';
GRANT ALL PRIVILEGES ON driveops_realtime.* TO 'driveops_realtime'@'%';

FLUSH PRIVILEGES;
