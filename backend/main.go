package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"backend/internal/database"
	"backend/internal/infrastructure/socket"
	"backend/internal/routes"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize database
	db := database.InitDB()

	// Initialize WebSocket Hub dan jalankan event loop-nya
	hub := socket.NewHub()
	go hub.Run()

	// Setup routes
	r := routes.SetupRoutes(db, hub)

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	r.Run(":" + port)
}
