CREATE TABLE IF NOT EXISTS photo_backup_jobs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  display_url VARCHAR(512) NOT NULL,
  local_original_path VARCHAR(512) NOT NULL,
  local_display_path VARCHAR(512) NOT NULL DEFAULT '',
  remote_path VARCHAR(512) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'pending',
  attempts INT NOT NULL DEFAULT 0,
  last_error TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  completed_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_status_attempts (status, attempts, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
