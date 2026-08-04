package database

import (
	"fmt"
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"backend/internal/models"
)

func InitDB() *gorm.DB {
	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		host, user, password, dbname, port)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// AutoMigrate syncs model definitions with database schema.
	// Only adds new columns/indexes — never drops existing ones.
	if err := db.AutoMigrate(
		&models.User{},
		&models.Room{},
		&models.RoomParticipant{},
		&models.Pertanyaan{},
		&models.QuestionOption{},
		&models.SesiUjian{},
		&models.Answer{},
		&models.HasilUjian{},
		&models.Feedback{},
		&models.ActivityLog{},
		&models.PasswordReset{},
	); err != nil {
		log.Printf("WARNING: AutoMigrate failed: %v", err)
	} else {
		log.Println("Database migration completed successfully")
	}

	// ponytail: explicit column additions for columns that may predate AutoMigrate.
	// These are idempotent — IF NOT EXISTS guards ensure safe re-runs.
	rawMigrations := []string{
		// answers.file_url — added in file_upload feature
		`ALTER TABLE answers ADD COLUMN IF NOT EXISTS file_url TEXT`,
		// hasil_ujian — jawaban_benar / jawaban_salah may not exist if table was created early
		`ALTER TABLE hasil_ujian ADD COLUMN IF NOT EXISTS jawaban_benar INTEGER NOT NULL DEFAULT 0`,
		`ALTER TABLE hasil_ujian ADD COLUMN IF NOT EXISTS jawaban_salah INTEGER NOT NULL DEFAULT 0`,
		// pertanyaan.deleted_at was added to model but column may not exist in older DBs
		`ALTER TABLE pertanyaan ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ`,
	}
	for _, sql := range rawMigrations {
		if err := db.Exec(sql).Error; err != nil {
			log.Printf("WARNING: migration statement failed: %v — SQL: %s", err, sql)
		}
	}

	return db
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
