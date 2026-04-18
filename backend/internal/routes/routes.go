package routes

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"time"
	"backend/internal/delivery/ws"
	"backend/internal/handlers"
	"backend/internal/infrastructure/socket"
)

func SetupRoutes(db *gorm.DB, hub *socket.Hub) *gin.Engine {
	r := gin.Default()

	// CORS middleware
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Initialize handlers
	userHandler := handlers.NewUserHandler(db)
	roomHandler := handlers.NewRoomHandler(db)
	pertanyaanHandler := handlers.NewPertanyaanHandler(db)
	sesiUjianHandler := handlers.NewSesiUjianHandler(db)
	answerHandler := handlers.NewAnswerHandler(db)
	hasilUjianHandler := handlers.NewHasilUjianHandler(db)
	feedbackHandler := handlers.NewFeedbackHandler(db, hub)

	// WebSocket endpoint: ws://host/ws?token=<jwt>
	r.GET("/ws", ws.Handler(hub))

	api := r.Group("/api")
	{
		// User routes
		users := api.Group("/users")
		{
			users.POST("", userHandler.CreateUser)
			users.GET("", userHandler.GetUsers)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.DELETE("/:id", userHandler.DeleteUser)
		}

		// Room routes
		rooms := api.Group("/rooms")
		{
			rooms.POST("", roomHandler.CreateRoom)
			rooms.GET("", roomHandler.GetRooms)
			rooms.GET("/:id", roomHandler.GetRoom)
			rooms.PUT("/:id", roomHandler.UpdateRoom)
			rooms.DELETE("/:id", roomHandler.DeleteRoom)
		}

		// Pertanyaan routes
		pertanyaans := api.Group("/pertanyaans")
		{
			pertanyaans.POST("", pertanyaanHandler.CreatePertanyaan)
			pertanyaans.GET("", pertanyaanHandler.GetPertanyaans)
			pertanyaans.GET("/:id", pertanyaanHandler.GetPertanyaan)
			pertanyaans.PUT("/:id", pertanyaanHandler.UpdatePertanyaan)
			pertanyaans.DELETE("/:id", pertanyaanHandler.DeletePertanyaan)
		}

		// Sesi Ujian routes
		sesiUjians := api.Group("/sesi-ujians")
		{
			sesiUjians.POST("", sesiUjianHandler.CreateSesiUjian)
			sesiUjians.GET("", sesiUjianHandler.GetSesiUjians)
			sesiUjians.GET("/:id", sesiUjianHandler.GetSesiUjian)
			sesiUjians.PUT("/:id", sesiUjianHandler.UpdateSesiUjian)
			sesiUjians.DELETE("/:id", sesiUjianHandler.DeleteSesiUjian)
		}

		// Answer routes
		answers := api.Group("/answers")
		{
			answers.POST("", answerHandler.CreateAnswer)
			answers.GET("", answerHandler.GetAnswers)
			answers.GET("/:id", answerHandler.GetAnswer)
			answers.PUT("/:id", answerHandler.UpdateAnswer)
			answers.DELETE("/:id", answerHandler.DeleteAnswer)
		}

		// Hasil Ujian routes
		hasilUjians := api.Group("/hasil-ujians")
		{
			hasilUjians.POST("", hasilUjianHandler.CreateHasilUjian)
			hasilUjians.GET("", hasilUjianHandler.GetHasilUjians)
			hasilUjians.GET("/:id", hasilUjianHandler.GetHasilUjian)
			hasilUjians.PUT("/:id", hasilUjianHandler.UpdateHasilUjian)
			hasilUjians.DELETE("/:id", hasilUjianHandler.DeleteHasilUjian)
		}

		// Feedback routes
		api.POST("/feedback", feedbackHandler.SendFeedback)
	}

	return r
}