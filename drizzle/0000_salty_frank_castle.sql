CREATE TABLE `announcements` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`body` text NOT NULL,
	`pinned` integer DEFAULT false NOT NULL,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `auth_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`token` text NOT NULL,
	`user_id` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `auth_sessions_token_unique` ON `auth_sessions` (`token`);--> statement-breakpoint
CREATE INDEX `auth_sessions_token_idx` ON `auth_sessions` (`token`);--> statement-breakpoint
CREATE TABLE `blocks` (
	`id` text PRIMARY KEY NOT NULL,
	`blocker_id` text NOT NULL,
	`blocked_id` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`blocker_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`blocked_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `block_pair_idx` ON `blocks` (`blocker_id`,`blocked_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `chat_initiator_idx` ON `chat_sessions` (`initiator_id`);--> statement-breakpoint
CREATE INDEX `chat_receiver_idx` ON `chat_sessions` (`receiver_id`);--> statement-breakpoint
CREATE INDEX `chat_status_idx` ON `chat_sessions` (`status`);--> statement-breakpoint
CREATE TABLE `event_rsvps` (
	`id` text PRIMARY KEY NOT NULL,
	`event_id` text NOT NULL,
	`user_id` text NOT NULL,
	`wants_buddy` integer DEFAULT true NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`event_id`) REFERENCES `events`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `rsvp_unique_idx` ON `event_rsvps` (`event_id`,`user_id`);--> statement-breakpoint
CREATE TABLE `events` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`description` text DEFAULT '' NOT NULL,
	`location` text NOT NULL,
	`starts_at` integer NOT NULL,
	`tag` text DEFAULT 'meetup' NOT NULL,
	`image` text DEFAULT '' NOT NULL
);
--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `messages_session_idx` ON `messages` (`session_id`);--> statement-breakpoint
CREATE TABLE `otp_codes` (
	`id` text PRIMARY KEY NOT NULL,
	`identifier` text NOT NULL,
	`kind` text NOT NULL,
	`code` text NOT NULL,
	`used_at` integer,
	`expires_at` integer NOT NULL,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `otp_identifier_idx` ON `otp_codes` (`identifier`);--> statement-breakpoint
CREATE TABLE `places` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`kind` text NOT NULL,
	`x` real NOT NULL,
	`y` real NOT NULL
);
--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `reports_reporter_idx` ON `reports` (`reporter_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `reviews_vendor_idx` ON `reviews` (`vendor_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE UNIQUE INDEX `users_reg_id_unique` ON `users` (`reg_id`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_mobile_unique` ON `users` (`mobile`);--> statement-breakpoint
CREATE INDEX `users_email_idx` ON `users` (`email`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE TABLE `community_interactions` (
	`id` text PRIMARY KEY NOT NULL,
	`record_id` text NOT NULL,
	`user_id` text NOT NULL,
	`action` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`record_id`) REFERENCES `community_records`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `community_interaction_unique` ON `community_interactions` (`record_id`,`user_id`,`action`);--> statement-breakpoint
CREATE INDEX `community_interaction_user_idx` ON `community_interactions` (`user_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `community_kind_expiry_idx` ON `community_records` (`kind`,`expires_at`);--> statement-breakpoint
CREATE INDEX `community_owner_idx` ON `community_records` (`owner_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE UNIQUE INDEX `media_files_object_key_unique` ON `media_files` (`object_key`);--> statement-breakpoint
CREATE INDEX `media_owner_idx` ON `media_files` (`owner_id`);--> statement-breakpoint
CREATE INDEX `media_session_idx` ON `media_files` (`session_id`);--> statement-breakpoint
CREATE TABLE `seed_versions` (
	`id` text PRIMARY KEY NOT NULL,
	`applied_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `telemetry_readings` (
	`id` text PRIMARY KEY NOT NULL,
	`source` text NOT NULL,
	`data` text NOT NULL,
	`captured_at` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `telemetry_captured_idx` ON `telemetry_readings` (`captured_at`);--> statement-breakpoint
CREATE TABLE `user_preferences` (
	`user_id` text NOT NULL,
	`key` text NOT NULL,
	`value` text NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`updated_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `user_preference_key` ON `user_preferences` (`user_id`,`key`);