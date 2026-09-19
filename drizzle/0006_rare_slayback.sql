CREATE TABLE `analytics_daily` (
	`day` text NOT NULL,
	`event` text NOT NULL,
	`count` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `analytics_day_event` ON `analytics_daily` (`day`,`event`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `facility_room` ON `facility_complaints` (`room`,`created_at`);--> statement-breakpoint
CREATE TABLE `forum_answers` (
	`id` text PRIMARY KEY NOT NULL,
	`question_id` text NOT NULL,
	`user_id` text NOT NULL,
	`body` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`question_id`) REFERENCES `forum_questions`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `answers_question` ON `forum_answers` (`question_id`);--> statement-breakpoint
CREATE TABLE `forum_questions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`title` text NOT NULL,
	`body` text NOT NULL,
	`course` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `forum_created` ON `forum_questions` (`created_at`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `parcel_complaints_parcel` ON `parcel_complaints` (`parcel_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `parcels_owner` ON `parcels` (`user_id`);--> statement-breakpoint
CREATE INDEX `parcels_courier` ON `parcels` (`courier_id`);--> statement-breakpoint
CREATE INDEX `parcels_status` ON `parcels` (`status`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE INDEX `planner_owner_time` ON `planner_items` (`user_id`,`starts_at`);--> statement-breakpoint
CREATE INDEX `planner_shared_room` ON `planner_items` (`shared`,`room`,`starts_at`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE UNIQUE INDEX `student_files_object_key_unique` ON `student_files` (`object_key`);--> statement-breakpoint
CREATE INDEX `student_files_owner` ON `student_files` (`user_id`);--> statement-breakpoint
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
--> statement-breakpoint
CREATE UNIQUE INDEX `student_profiles_registration_unique` ON `student_profiles` (`registration`);--> statement-breakpoint
CREATE TABLE `verification_challenges` (
	`user_id` text PRIMARY KEY NOT NULL,
	`code_hash` text NOT NULL,
	`expires_at` integer NOT NULL,
	`attempts` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
