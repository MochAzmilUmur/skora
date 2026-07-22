package routes

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"backend/internal/delivery/ws"
	"backend/internal/handlers"
	"backend/internal/infrastructure/socket"
	"backend/internal/middleware"
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
	authHandler := handlers.NewAuthHandler(db)
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
		// Auth routes (public)
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
		}

		// Protected routes
		protected := api.Group("")
		protected.Use(middleware.JWTAuth())

		// User routes
		users := protected.Group("/users")
		{
			users.POST("", userHandler.CreateUser)
			users.GET("", userHandler.GetUsers)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.POST("/:id/change-password", userHandler.ChangePassword)
			users.DELETE("/:id", userHandler.DeleteUser)
		}

		// Room routes
		rooms := protected.Group("/rooms")
		{
			rooms.POST("", roomHandler.CreateRoom)
			rooms.GET("", roomHandler.GetRooms)
			rooms.POST("/join", roomHandler.JoinRoom)
			rooms.GET("/code/:code", roomHandler.GetRoomByCode)
			rooms.GET("/user/:user_id", roomHandler.GetRoomsByUser)
			rooms.GET("/:id", roomHandler.GetRoom)
			rooms.PUT("/:id", roomHandler.UpdateRoom)
			rooms.DELETE("/:id", roomHandler.DeleteRoom)
			rooms.GET("/:id/participants", roomHandler.GetParticipants)
			rooms.POST("/:id/participants", roomHandler.AddParticipant)
			rooms.DELETE("/:id/participants/:participant_id", roomHandler.RemoveParticipant)
			rooms.GET("/:id/pertanyaans", pertanyaanHandler.GetPertanyaansByRoom)
		}

		// Pertanyaan routes
		pertanyaans := protected.Group("/pertanyaans")
		{
			pertanyaans.POST("", pertanyaanHandler.CreatePertanyaan)
			pertanyaans.GET("", pertanyaanHandler.GetPertanyaans)
			pertanyaans.GET("/:id", pertanyaanHandler.GetPertanyaan)
			pertanyaans.PUT("/:id", pertanyaanHandler.UpdatePertanyaan)
			pertanyaans.DELETE("/:id", pertanyaanHandler.DeletePertanyaan)
		}

		// Sesi Ujian routes
		sesiUjians := protected.Group("/sesi-ujians")
		{
			sesiUjians.POST("", sesiUjianHandler.CreateSesiUjian)
			sesiUjians.GET("", sesiUjianHandler.GetSesiUjians)
			sesiUjians.GET("/:id", sesiUjianHandler.GetSesiUjian)
			sesiUjians.PUT("/:id", sesiUjianHandler.UpdateSesiUjian)
			sesiUjians.DELETE("/:id", sesiUjianHandler.DeleteSesiUjian)
		}

		// Answer routes
		answers := protected.Group("/answers")
		{
			answers.POST("", answerHandler.CreateAnswer)
			answers.GET("", answerHandler.GetAnswers)
			answers.GET("/:id", answerHandler.GetAnswer)
			answers.PUT("/:id", answerHandler.UpdateAnswer)
			answers.DELETE("/:id", answerHandler.DeleteAnswer)
		}

		// Hasil Ujian routes
		hasilUjians := protected.Group("/hasil-ujians")
		{
			hasilUjians.POST("", hasilUjianHandler.CreateHasilUjian)
			hasilUjians.GET("", hasilUjianHandler.GetHasilUjians)
			hasilUjians.GET("/:id", hasilUjianHandler.GetHasilUjian)
			hasilUjians.PUT("/:id", hasilUjianHandler.UpdateHasilUjian)
			hasilUjians.DELETE("/:id", hasilUjianHandler.DeleteHasilUjian)
		}

		// Feedback routes
		protected.POST("/feedback", feedbackHandler.SendFeedback)
		protected.GET("/feedback", feedbackHandler.GetFeedbackByHasil)
		protected.DELETE("/feedback/:id", feedbackHandler.DeleteFeedback)

		// Rekap nilai per room
		protected.GET("/rooms/:id/hasil", hasilUjianHandler.GetHasilByRoom)
	}

	return r
}
