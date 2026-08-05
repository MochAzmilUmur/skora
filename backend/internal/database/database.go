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

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=require TimeZone=Asia/Jakarta",
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
		
	); err != nil {
		log.Printf("WARNING: AutoMigrate failed: %v", err)
	} else {
		log.Println("Database migration completed successfully")
	}



	return db
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
