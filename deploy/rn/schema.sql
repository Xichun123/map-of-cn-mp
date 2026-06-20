SET NAMES utf8mb4;
SET time_zone = '+08:00';

CREATE TABLE IF NOT EXISTS app_users (
  openid VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  nickname VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  avatar_url VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  is_admin TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (openid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS journeys (
  id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  openid VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  city VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  province VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  travel_date DATE NOT NULL,
  season VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  weather VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  landmark VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  latitude DECIMAL(10,6) NOT NULL DEFAULT 0,
  longitude DECIMAL(10,6) NOT NULL DEFAULT 0,
  cover_tone VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'tone-slate',
  title VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  intro TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_journeys_visible_order (is_visible, sort_order, travel_date),
  KEY idx_journeys_openid (openid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS journey_photos (
  id VARCHAR(96) COLLATE utf8mb4_unicode_ci NOT NULL,
  journey_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  title VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  subtitle VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  tone VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'tone-ink',
  image_url VARCHAR(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_journey_photos_journey (journey_id, sort_order),
  CONSTRAINT fk_journey_photos_journey FOREIGN KEY (journey_id) REFERENCES journeys (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS journey_notes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  journey_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  content TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_journey_notes_journey (journey_id, sort_order),
  CONSTRAINT fk_journey_notes_journey FOREIGN KEY (journey_id) REFERENCES journeys (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS journey_tags (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  journey_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  name VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_journey_tags_journey (journey_id, sort_order),
  CONSTRAINT fk_journey_tags_journey FOREIGN KEY (journey_id) REFERENCES journeys (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS anniversaries (
  id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  label VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  event_date DATE NOT NULL,
  city VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  repeat_yearly TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_anniversaries_order (sort_order, event_date),
  KEY idx_anniversaries_event_date (event_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS trip_plans (
  id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  title VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  cover_tone VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'tone-slate',
  plan_date DATE DEFAULT NULL,
  plan_date_end DATE DEFAULT NULL,
  cover_image_url VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  note TEXT COLLATE utf8mb4_unicode_ci,
  hotel_name VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  hotel_address VARCHAR(256) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  hotel_lat DECIMAL(10,6) DEFAULT NULL,
  hotel_lng DECIMAL(10,6) DEFAULT NULL,
  hotels TEXT COLLATE utf8mb4_unicode_ci,
  day_starts TEXT COLLATE utf8mb4_unicode_ci,
  sort_order INT NOT NULL DEFAULT 0,
  is_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_trip_plans_visible_order (is_visible, sort_order, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS plan_stops (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  plan_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  name VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  address VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  latitude DECIMAL(10,6) DEFAULT NULL,
  longitude DECIMAL(10,6) DEFAULT NULL,
  note TEXT COLLATE utf8mb4_unicode_ci,
  open_hours VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  ticket VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  booking_url VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  planned_time VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  stay_minutes INT NOT NULL DEFAULT 0,
  day INT NOT NULL DEFAULT 1,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_plan_stops_plan (plan_id, sort_order, id),
  CONSTRAINT fk_plan_stops_plan FOREIGN KEY (plan_id) REFERENCES trip_plans (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS desire_list (
  id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  openid VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  place_name VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  province VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  city VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  latitude DECIMAL(10,6) DEFAULT NULL,
  longitude DECIMAL(10,6) DEFAULT NULL,
  memo TEXT COLLATE utf8mb4_unicode_ci,
  done TINYINT(1) NOT NULL DEFAULT 0,
  completed_date DATE DEFAULT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_desire_order (done, sort_order, created_at),
  KEY idx_desire_openid (openid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS trip_expenses (
  id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  openid VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  plan_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  journey_id VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  city VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  category VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'other',
  amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  spend_date DATE NOT NULL,
  memo TEXT COLLATE utf8mb4_unicode_ci,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_expense_openid (openid),
  KEY idx_expense_plan (plan_id),
  KEY idx_expense_date (spend_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dish_categories (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cat_visible_order (is_visible, sort_order, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dishes (
  id INT NOT NULL AUTO_INCREMENT,
  category_id INT NOT NULL,
  name VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  description VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  price DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  image_url VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  is_available TINYINT(1) NOT NULL DEFAULT 1,
  is_recommended TINYINT(1) NOT NULL DEFAULT 0,
  spicy_level TINYINT NOT NULL DEFAULT 0,
  portion VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dish_cat (category_id, is_available, sort_order, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orders (
  id VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  user_openid VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  nickname VARCHAR(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  remark VARCHAR(512) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  item_count INT NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status VARCHAR(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_order_user (user_openid, created_at),
  KEY idx_order_status (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS order_items (
  id INT NOT NULL AUTO_INCREMENT,
  order_id VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  dish_id INT NOT NULL DEFAULT 0,
  dish_name VARCHAR(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  price DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  qty INT NOT NULL DEFAULT 1,
  remark VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  KEY idx_item_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS couple_messages (
  id VARCHAR(32) NOT NULL PRIMARY KEY,
  openid VARCHAR(64) NOT NULL DEFAULT '',
  nickname VARCHAR(64) NOT NULL DEFAULT '',
  avatar_url VARCHAR(512) NOT NULL DEFAULT '',
  content TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME DEFAULT NULL,
  INDEX idx_visible_created (deleted_at, created_at),
  INDEX idx_openid (openid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS moments (
  id VARCHAR(32) NOT NULL PRIMARY KEY,
  openid VARCHAR(64) NOT NULL DEFAULT '',
  image_url VARCHAR(512) NOT NULL,
  caption TEXT,
  tags JSON,
  ai_score TINYINT UNSIGNED DEFAULT 0,
  journey_id VARCHAR(32) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_openid (openid),
  INDEX idx_created (created_at),
  INDEX idx_score (ai_score DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

CREATE TABLE IF NOT EXISTS time_capsules (
  id VARCHAR(32) NOT NULL PRIMARY KEY,
  openid VARCHAR(64) NOT NULL,
  open_date DATE NOT NULL,
  title VARCHAR(128) NOT NULL DEFAULT '',
  message TEXT,
  photo_urls JSON,
  is_opened TINYINT UNSIGNED DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_openid (openid),
  INDEX idx_open_date (open_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS couple_logs (
  id VARCHAR(32) NOT NULL PRIMARY KEY,
  openid VARCHAR(64) NOT NULL DEFAULT '',
  category VARCHAR(32) NOT NULL DEFAULT 'other',
  title VARCHAR(256) NOT NULL DEFAULT '',
  log_date DATE NOT NULL,
  note TEXT,
  cover_image VARCHAR(512) DEFAULT '',
  rating TINYINT UNSIGNED DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_category (category),
  INDEX idx_date (log_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
