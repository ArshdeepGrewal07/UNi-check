-- Reference schema for a NEW EMPTY database only. Use versioned migrations for existing databases.

-- 0000_salty_frank_castle.sql
CREATE TABLE `announcements` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`body` text NOT NULL,
	`pinned` integer DEFAULT false NOT NULL,
	`created_at` integer NOT NULL
);

CREATE TABLE `auth_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`token` text NOT NULL,
	`user_id` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `auth_sessions_token_unique` ON `auth_sessions` (`token`);
CREATE INDEX `auth_sessions_token_idx` ON `auth_sessions` (`token`);
CREATE TABLE `blocks` (
	`id` text PRIMARY KEY NOT NULL,
	`blocker_id` text NOT NULL,
	`blocked_id` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`blocker_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`blocked_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `block_pair_idx` ON `blocks` (`blocker_id`,`blocked_id`);
CREATE TABLE `chat_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`initiator_id` text NOT NULL,
	`receiver_id` text NOT NULL,
	`status` text DEFAULT 'pending' NOT NULL,
	`media_unlocked` integer DEFAULT false NOT NULL,
	`created_at` integer NOT NULL,
	`timer_ends_at` integer NOT NULL,
	`accepted_at` integer,
	`expired_at` integer,
	`waived_at` integer,
	`initiator_last_read` integer,
	`receiver_last_read` integer,
	FOREIGN KEY (`initiator_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`receiver_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `chat_initiator_idx` ON `chat_sessions` (`initiator_id`);
CREATE INDEX `chat_receiver_idx` ON `chat_sessions` (`receiver_id`);
CREATE INDEX `chat_status_idx` ON `chat_sessions` (`status`);
CREATE TABLE `event_rsvps` (
	`id` text PRIMARY KEY NOT NULL,
	`event_id` text NOT NULL,
	`user_id` text NOT NULL,
	`wants_buddy` integer DEFAULT true NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`event_id`) REFERENCES `events`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `rsvp_unique_idx` ON `event_rsvps` (`event_id`,`user_id`);
CREATE TABLE `events` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`description` text DEFAULT '' NOT NULL,
	`location` text NOT NULL,
	`starts_at` integer NOT NULL,
	`tag` text DEFAULT 'meetup' NOT NULL,
	`image` text DEFAULT '' NOT NULL
);

CREATE TABLE `messages` (
	`id` text PRIMARY KEY NOT NULL,
	`session_id` text NOT NULL,
	`sender_id` text,
	`kind` text DEFAULT 'text' NOT NULL,
	`body` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`session_id`) REFERENCES `chat_sessions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null
);

CREATE INDEX `messages_session_idx` ON `messages` (`session_id`);
CREATE TABLE `otp_codes` (
	`id` text PRIMARY KEY NOT NULL,
	`identifier` text NOT NULL,
	`kind` text NOT NULL,
	`code` text NOT NULL,
	`used_at` integer,
	`expires_at` integer NOT NULL,
	`created_at` integer NOT NULL
);

CREATE INDEX `otp_identifier_idx` ON `otp_codes` (`identifier`);
CREATE TABLE `places` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`kind` text NOT NULL,
	`x` real NOT NULL,
	`y` real NOT NULL
);

CREATE TABLE `reports` (
	`id` text PRIMARY KEY NOT NULL,
	`reporter_id` text NOT NULL,
	`reported_id` text NOT NULL,
	`category` text NOT NULL,
	`details` text DEFAULT '' NOT NULL,
	`evidence_url` text NOT NULL,
	`status` text DEFAULT 'open' NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`reporter_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`reported_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `reports_reporter_idx` ON `reports` (`reporter_id`);
CREATE TABLE `reviews` (
	`id` text PRIMARY KEY NOT NULL,
	`vendor_id` text NOT NULL,
	`user_id` text NOT NULL,
	`rating` integer NOT NULL,
	`body` text DEFAULT '' NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`vendor_id`) REFERENCES `vendors`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `reviews_vendor_idx` ON `reviews` (`vendor_id`);
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`full_name` text NOT NULL,
	`reg_id` text NOT NULL,
	`email` text NOT NULL,
	`mobile` text NOT NULL,
	`gender` text NOT NULL,
	`course` text NOT NULL,
	`academic_year` integer NOT NULL,
	`interests` text DEFAULT '[]' NOT NULL,
	`looking_for` text,
	`avatar_hue` integer DEFAULT 140 NOT NULL,
	`visible` integer DEFAULT true NOT NULL,
	`is_demo` integer DEFAULT false NOT NULL,
	`is_restricted` integer DEFAULT false NOT NULL,
	`created_at` integer NOT NULL
);

CREATE UNIQUE INDEX `users_reg_id_unique` ON `users` (`reg_id`);
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);
CREATE UNIQUE INDEX `users_mobile_unique` ON `users` (`mobile`);
CREATE INDEX `users_email_idx` ON `users` (`email`);
CREATE TABLE `vendors` (
	`id` text PRIMARY KEY NOT NULL,
	`place_id` text,
	`name` text NOT NULL,
	`blurb` text DEFAULT '' NOT NULL,
	`is_open` integer DEFAULT true NOT NULL,
	`image` text DEFAULT '' NOT NULL,
	`top_dish` text,
	`x` real DEFAULT 50 NOT NULL,
	`y` real DEFAULT 50 NOT NULL,
	`menu` text DEFAULT '[]' NOT NULL,
	FOREIGN KEY (`place_id`) REFERENCES `places`(`id`) ON UPDATE no action ON DELETE set null
);

CREATE TABLE `community_interactions` (
	`id` text PRIMARY KEY NOT NULL,
	`record_id` text NOT NULL,
	`user_id` text NOT NULL,
	`action` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`record_id`) REFERENCES `community_records`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `community_interaction_unique` ON `community_interactions` (`record_id`,`user_id`,`action`);
CREATE INDEX `community_interaction_user_idx` ON `community_interactions` (`user_id`);
CREATE TABLE `community_records` (
	`id` text PRIMARY KEY NOT NULL,
	`kind` text NOT NULL,
	`owner_id` text,
	`data` text NOT NULL,
	`sample` integer DEFAULT false NOT NULL,
	`expires_at` integer,
	`version` integer DEFAULT 0 NOT NULL,
	`mutation_token` text,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `community_kind_expiry_idx` ON `community_records` (`kind`,`expires_at`);
CREATE INDEX `community_owner_idx` ON `community_records` (`owner_id`);
CREATE TABLE `media_files` (
	`id` text PRIMARY KEY NOT NULL,
	`owner_id` text NOT NULL,
	`session_id` text,
	`purpose` text NOT NULL,
	`object_key` text NOT NULL,
	`content_type` text NOT NULL,
	`bytes` integer NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `media_files_object_key_unique` ON `media_files` (`object_key`);
CREATE INDEX `media_owner_idx` ON `media_files` (`owner_id`);
CREATE INDEX `media_session_idx` ON `media_files` (`session_id`);
CREATE TABLE `seed_versions` (
	`id` text PRIMARY KEY NOT NULL,
	`applied_at` integer NOT NULL
);

CREATE TABLE `telemetry_readings` (
	`id` text PRIMARY KEY NOT NULL,
	`source` text NOT NULL,
	`data` text NOT NULL,
	`captured_at` integer NOT NULL
);

CREATE INDEX `telemetry_captured_idx` ON `telemetry_readings` (`captured_at`);
CREATE TABLE `user_preferences` (
	`user_id` text NOT NULL,
	`key` text NOT NULL,
	`value` text NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `user_preference_key` ON `user_preferences` (`user_id`,`key`);

-- 0001_lame_zaladane.sql
CREATE TABLE `guardian_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`route` text NOT NULL,
	`status` text NOT NULL,
	`deadline` integer NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `guardian_user_created_idx` ON `guardian_sessions` (`user_id`,`created_at`);

-- 0002_normal_skrulls.sql
CREATE TABLE `community_activity` (
	`id` text PRIMARY KEY NOT NULL,
	`record_id` text NOT NULL,
	`user_id` text NOT NULL,
	`action` text NOT NULL,
	`data` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`record_id`) REFERENCES `community_records`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `activity_record_created_idx` ON `community_activity` (`record_id`,`created_at`);
CREATE TABLE `focus_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`kind` text NOT NULL,
	`duration` integer NOT NULL,
	`remaining` integer NOT NULL,
	`deadline` integer NOT NULL,
	`status` text NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `focus_user_kind_created_idx` ON `focus_sessions` (`user_id`,`kind`,`created_at`);
CREATE TABLE `notifications` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`actor_id` text,
	`record_id` text,
	`body` text NOT NULL,
	`read_at` integer,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`actor_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null,
	FOREIGN KEY (`record_id`) REFERENCES `community_records`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `notifications_user_created_idx` ON `notifications` (`user_id`,`created_at`);

-- 0003_fantastic_franklin_richards.sql
CREATE TABLE `login_attempts` (
	`identifier` text PRIMARY KEY NOT NULL,
	`attempts` integer NOT NULL,
	`window_start` integer NOT NULL
);

CREATE TABLE `user_credentials` (
	`user_id` text PRIMARY KEY NOT NULL,
	`password_hash` text NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);


-- 0004_organic_post.sql
CREATE TABLE `career_applications` (
	`user_id` text NOT NULL,
	`opportunity_id` text NOT NULL,
	`note` text NOT NULL,
	`status` text NOT NULL,
	`created_at` integer NOT NULL,
	PRIMARY KEY(`user_id`, `opportunity_id`),
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`opportunity_id`) REFERENCES `career_catalog`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `career_app_opportunity_idx` ON `career_applications` (`opportunity_id`);
CREATE TABLE `career_attempts` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`kind` text NOT NULL,
	`target_id` text NOT NULL,
	`answer` text NOT NULL,
	`feedback` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`target_id`) REFERENCES `career_catalog`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `career_attempts_user_idx` ON `career_attempts` (`user_id`,`created_at`);
CREATE TABLE `career_catalog` (
	`id` text PRIMARY KEY NOT NULL,
	`kind` text NOT NULL,
	`owner_id` text,
	`data` text NOT NULL,
	`sample` integer DEFAULT 0 NOT NULL,
	`closed` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `career_kind_idx` ON `career_catalog` (`kind`,`closed`);
CREATE TABLE `career_profiles` (
	`user_id` text PRIMARY KEY NOT NULL,
	`data` text NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE TABLE `career_progress` (
	`user_id` text NOT NULL,
	`track_id` text NOT NULL,
	`completed` text NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`updated_at` integer NOT NULL,
	PRIMARY KEY(`user_id`, `track_id`),
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`track_id`) REFERENCES `career_catalog`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE TABLE `career_saved` (
	`user_id` text NOT NULL,
	`opportunity_id` text NOT NULL,
	PRIMARY KEY(`user_id`, `opportunity_id`),
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`opportunity_id`) REFERENCES `career_catalog`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE TABLE `skill_beacon_members` (
	`beacon_id` text NOT NULL,
	`user_id` text NOT NULL,
	`created_at` integer NOT NULL,
	PRIMARY KEY(`beacon_id`, `user_id`),
	FOREIGN KEY (`beacon_id`) REFERENCES `skill_beacons`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE TABLE `skill_beacons` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`kind` text NOT NULL,
	`title` text NOT NULL,
	`description` text NOT NULL,
	`location` text NOT NULL,
	`room` text NOT NULL,
	`reward` text NOT NULL,
	`x` integer NOT NULL,
	`y` integer NOT NULL,
	`expires_at` integer NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `skill_beacon_expiry_idx` ON `skill_beacons` (`expires_at`);

-- 0005_melted_morlun.sql
ALTER TABLE `users` ADD `phone_number` text;
CREATE UNIQUE INDEX `users_phone_number_unique` ON `users` (`phone_number`);

-- 0006_rare_slayback.sql
CREATE TABLE `analytics_daily` (
	`day` text NOT NULL,
	`event` text NOT NULL,
	`count` integer DEFAULT 0 NOT NULL
);

CREATE UNIQUE INDEX `analytics_day_event` ON `analytics_daily` (`day`,`event`);
CREATE TABLE `facility_complaints` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`room` text NOT NULL,
	`category` text NOT NULL,
	`body` text NOT NULL,
	`photo_id` text,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `facility_room` ON `facility_complaints` (`room`,`created_at`);
CREATE TABLE `forum_answers` (
	`id` text PRIMARY KEY NOT NULL,
	`question_id` text NOT NULL,
	`user_id` text NOT NULL,
	`body` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`question_id`) REFERENCES `forum_questions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `answers_question` ON `forum_answers` (`question_id`);
CREATE TABLE `forum_questions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`title` text NOT NULL,
	`body` text NOT NULL,
	`course` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `forum_created` ON `forum_questions` (`created_at`);
CREATE TABLE `parcel_complaints` (
	`id` text PRIMARY KEY NOT NULL,
	`parcel_id` text NOT NULL,
	`user_id` text NOT NULL,
	`category` text NOT NULL,
	`body` text NOT NULL,
	`photo_id` text,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`parcel_id`) REFERENCES `parcels`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `parcel_complaints_parcel` ON `parcel_complaints` (`parcel_id`);
CREATE TABLE `parcels` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`courier_id` text,
	`title` text NOT NULL,
	`pickup` text NOT NULL,
	`destination` text NOT NULL,
	`due_at` integer NOT NULL,
	`parcel_amount` integer NOT NULL,
	`fee` integer NOT NULL,
	`status` text DEFAULT 'open' NOT NULL,
	`parcel_photo` text,
	`qr_photo` text,
	`receipt_photo` text,
	`paid_at` integer,
	`delivered_at` integer,
	`version` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`courier_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null
);

CREATE INDEX `parcels_owner` ON `parcels` (`user_id`);
CREATE INDEX `parcels_courier` ON `parcels` (`courier_id`);
CREATE INDEX `parcels_status` ON `parcels` (`status`);
CREATE TABLE `planner_items` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`kind` text NOT NULL,
	`title` text NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`starts_at` integer NOT NULL,
	`ends_at` integer NOT NULL,
	`remind_at` integer NOT NULL,
	`room` text DEFAULT '' NOT NULL,
	`shared` integer DEFAULT 0 NOT NULL,
	`done` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE INDEX `planner_owner_time` ON `planner_items` (`user_id`,`starts_at`);
CREATE INDEX `planner_shared_room` ON `planner_items` (`shared`,`room`,`starts_at`);
CREATE TABLE `student_files` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`purpose` text NOT NULL,
	`name` text NOT NULL,
	`mime` text NOT NULL,
	`bytes` integer NOT NULL,
	`object_key` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `student_files_object_key_unique` ON `student_files` (`object_key`);
CREATE INDEX `student_files_owner` ON `student_files` (`user_id`);
CREATE TABLE `student_profiles` (
	`user_id` text PRIMARY KEY NOT NULL,
	`age` integer,
	`college` text DEFAULT 'LPU' NOT NULL,
	`registration` text,
	`bio` text DEFAULT '' NOT NULL,
	`availability` text DEFAULT 'student' NOT NULL,
	`photo_id` text,
	`resume_id` text,
	`email_verified_at` integer,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);

CREATE UNIQUE INDEX `student_profiles_registration_unique` ON `student_profiles` (`registration`);
CREATE TABLE `verification_challenges` (
	`user_id` text PRIMARY KEY NOT NULL,
	`code_hash` text NOT NULL,
	`expires_at` integer NOT NULL,
	`attempts` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);


-- 0007_chubby_blue_blade.sql
CREATE TABLE `chat_identity_keys` (
	`user_id` text PRIMARY KEY NOT NULL,
	`public_key` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
