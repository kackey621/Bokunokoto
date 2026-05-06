CREATE DATABASE IF NOT EXISTS bokunokoto_development CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS bokunokoto_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS bokunokoto_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `bokunokoto_%`.* TO 'bokunokoto'@'%';
FLUSH PRIVILEGES;
