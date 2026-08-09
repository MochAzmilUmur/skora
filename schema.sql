-- Script DDL SQL untuk membuat ERD di dbdiagram.io
-- Berdasarkan file backend/internal/models/models.go

-- 1. Table: users
CREATE TABLE "users" (
  "id_users" SERIAL PRIMARY KEY,
  "nama" VARCHAR(255),
  "email" VARCHAR(255),
  "password_hash" VARCHAR(255),
  "role" VARCHAR(50) DEFAULT 'pelajar',
  "avatar_url" TEXT,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table: room
CREATE TABLE "room" (
  "id_room" UUID PRIMARY KEY,
  "room_name" VARCHAR(255),
  "description" TEXT,
  "durasi" INT,
  "start_date" TIMESTAMP,
  "room_type" VARCHAR(20) DEFAULT 'PILIHAN_GANDA',
  "shuffle_questions" BOOLEAN DEFAULT false,
  "room_code" VARCHAR(100) UNIQUE,
  "created_by" INT NOT NULL,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Table: room_participants
CREATE TABLE "room_participants" (
  "id" SERIAL PRIMARY KEY,
  "room_id" UUID NOT NULL,
  "user_id" INT NOT NULL,
  "role" VARCHAR(50),
  "status" VARCHAR(50) DEFAULT 'active',
  "joined_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Table: pertanyaan
CREATE TABLE "pertanyaan" (
  "id" SERIAL PRIMARY KEY,
  "room_id" UUID NOT NULL,
  "pertanyaan_text" TEXT,
  "gambar_url" TEXT,
  "type_pertanyaan" VARCHAR(20) DEFAULT 'multiple_choice',
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "deleted_at" TIMESTAMP
);

-- 5. Table: question_options
CREATE TABLE "question_options" (
  "id" SERIAL PRIMARY KEY,
  "question_id" INT NOT NULL,
  "option_text" TEXT,
  "is_correct" BOOLEAN DEFAULT false
);

-- 6. Table: sesi_ujian
CREATE TABLE "sesi_ujian" (
  "id" SERIAL PRIMARY KEY,
  "room_id" UUID NOT NULL,
  "user_id" INT NOT NULL,
  "start_time" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "end_time" TIMESTAMP,
  "status" VARCHAR(20) DEFAULT 'ongoing'
);

-- 7. Table: answers
CREATE TABLE "answers" (
  "id" SERIAL PRIMARY KEY,
  "session_id" INT NOT NULL,
  "question_id" INT NOT NULL,
  "answer_text" TEXT,
  "selected_option_id" INT,
  "file_url" TEXT,
  "answered_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Table: hasil_ujian
CREATE TABLE "hasil_ujian" (
  "id" SERIAL PRIMARY KEY,
  "session_id" INT NOT NULL,
  "total_questions" INT,
  "jawaban_benar" INT,
  "jawaban_salah" INT,
  "skor" DOUBLE PRECISION
);

-- 9. Table: feedbacks
CREATE TABLE "feedbacks" (
  "id" SERIAL PRIMARY KEY,
  "hasil_id" INT NOT NULL,
  "asesor_id" INT NOT NULL,
  "sender_id" INT NOT NULL,
  "komentar" TEXT,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Table: activity_logs
CREATE TABLE "activity_logs" (
  "id" SERIAL PRIMARY KEY,
  "session_id" INT NOT NULL,
  "activity_type" VARCHAR(100),
  "activity_time" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Table: password_reset
CREATE TABLE "password_reset" (
  "id" UUID PRIMARY KEY,
  "id_users" INT NOT NULL,
  "token" CHAR(64) NOT NULL,
  "expired_at" TIMESTAMP NOT NULL,
  "used_at" TIMESTAMP,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Foreign Key Constraints / Relations

ALTER TABLE "room" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id_users");

ALTER TABLE "room_participants" ADD FOREIGN KEY ("room_id") REFERENCES "room" ("id_room");
ALTER TABLE "room_participants" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id_users");

ALTER TABLE "pertanyaan" ADD FOREIGN KEY ("room_id") REFERENCES "room" ("id_room");

ALTER TABLE "question_options" ADD FOREIGN KEY ("question_id") REFERENCES "pertanyaan" ("id");

ALTER TABLE "sesi_ujian" ADD FOREIGN KEY ("room_id") REFERENCES "room" ("id_room");
ALTER TABLE "sesi_ujian" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id_users");

ALTER TABLE "answers" ADD FOREIGN KEY ("session_id") REFERENCES "sesi_ujian" ("id");
ALTER TABLE "answers" ADD FOREIGN KEY ("question_id") REFERENCES "pertanyaan" ("id");
ALTER TABLE "answers" ADD FOREIGN KEY ("selected_option_id") REFERENCES "question_options" ("id");

ALTER TABLE "hasil_ujian" ADD FOREIGN KEY ("session_id") REFERENCES "sesi_ujian" ("id");

ALTER TABLE "feedbacks" ADD FOREIGN KEY ("hasil_id") REFERENCES "hasil_ujian" ("id");
ALTER TABLE "feedbacks" ADD FOREIGN KEY ("asesor_id") REFERENCES "users" ("id_users");
ALTER TABLE "feedbacks" ADD FOREIGN KEY ("sender_id") REFERENCES "users" ("id_users");

ALTER TABLE "activity_logs" ADD FOREIGN KEY ("session_id") REFERENCES "sesi_ujian" ("id");

ALTER TABLE "password_reset" ADD FOREIGN KEY ("id_users") REFERENCES "users" ("id_users");
