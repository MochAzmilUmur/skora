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
	"backend/internal/repositories"
	"backend/internal/usecase"
)

func SetupRoutes(db *gorm.DB, hub *socket.Hub) *gin.Engine {
	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	r.Static("/uploads", "./storage/uploads")

	// Wire: repository → usecase → handler
	sesiRepo := repositories.NewSesiUjianRepository(db)
	hasilRepo := repositories.NewHasilUjianRepository(db)
	answerRepo := repositories.NewAnswerRepository(db)

	sesiUC := usecase.NewSesiUjianUsecase(sesiRepo, db, hub)
	hasilUC := usecase.NewHasilUjianUsecase(hasilRepo, db)
	answerUC := usecase.NewAnswerUsecase(answerRepo, db)

	authHandler := handlers.NewAuthHandler(db)
	userHandler := handlers.NewUserHandler(db, hub)
	roomHandler := handlers.NewRoomHandler(db, hub)
	pertanyaanHandler := handlers.NewPertanyaanHandler(db)
	sesiUjianHandler := handlers.NewSesiUjianHandler(sesiUC)
	answerHandler := handlers.NewAnswerHandler(answerUC)
	hasilUjianHandler := handlers.NewHasilUjianHandler(hasilUC)
	feedbackHandler := handlers.NewFeedbackHandler(db, hub)
	uploadHandler := handlers.NewUploadHandler()

	r.GET("/ws", ws.Handler(hub))

	api := r.Group("/api")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
		}

		protected := api.Group("")
		protected.Use(middleware.JWTAuth())

		protected.POST("/upload", uploadHandler.UploadFile)

		users := protected.Group("/users")
		{
			users.POST("", userHandler.CreateUser)
			users.GET("", userHandler.GetUsers)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.POST("/:id/change-password", userHandler.ChangePassword)
			users.PUT("/:id/role", userHandler.UpdateRole)
			users.POST("/:id/avatar", userHandler.UploadAvatar)
			users.DELETE("/:id", userHandler.DeleteUser)
		}

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
			rooms.POST("/:id/remidi", roomHandler.RequestRemidi)
			rooms.PATCH("/:id/participants/:user_id/remidi", roomHandler.ReviewRemidi)
			rooms.GET("/:id/pertanyaans", pertanyaanHandler.GetPertanyaansByRoom)
			rooms.POST("/:id/import-excel", pertanyaanHandler.ImportExcel)
			rooms.GET("/:id/hasil", hasilUjianHandler.GetHasilByRoom)
		}

		pertanyaans := protected.Group("/pertanyaans")
		{
			pertanyaans.POST("", pertanyaanHandler.CreatePertanyaan)
			pertanyaans.GET("", pertanyaanHandler.GetPertanyaans)
			pertanyaans.GET("/:id", pertanyaanHandler.GetPertanyaan)
			pertanyaans.PUT("/:id", pertanyaanHandler.UpdatePertanyaan)
			pertanyaans.DELETE("/:id", pertanyaanHandler.DeletePertanyaan)
		}

		sesiUjians := protected.Group("/sesi-ujians")
		{
			sesiUjians.POST("", sesiUjianHandler.CreateSesiUjian)
			sesiUjians.GET("", sesiUjianHandler.GetSesiUjians)
			sesiUjians.GET("/:id", sesiUjianHandler.GetSesiUjian)
			sesiUjians.PUT("/:id", sesiUjianHandler.UpdateSesiUjian)
			sesiUjians.DELETE("/:id", sesiUjianHandler.DeleteSesiUjian)
		}

		answers := protected.Group("/answers")
		{
			answers.POST("", answerHandler.CreateAnswer)
			answers.GET("", answerHandler.GetAnswers)
			answers.GET("/:id", answerHandler.GetAnswer)
			answers.PUT("/:id", answerHandler.UpdateAnswer)
			answers.DELETE("/:id", answerHandler.DeleteAnswer)
		}

		hasilUjians := protected.Group("/hasil-ujians")
		{
			hasilUjians.POST("", hasilUjianHandler.CreateHasilUjian)
			hasilUjians.GET("", hasilUjianHandler.GetHasilUjians)
			hasilUjians.GET("/:id", hasilUjianHandler.GetHasilUjian)
			hasilUjians.PUT("/:id", hasilUjianHandler.UpdateHasilUjian)
			hasilUjians.DELETE("/:id", hasilUjianHandler.DeleteHasilUjian)
		}

		protected.POST("/feedback", feedbackHandler.SendFeedback)
		protected.GET("/feedback", feedbackHandler.GetFeedbackByHasil)
		protected.DELETE("/feedback/:id", feedbackHandler.DeleteFeedback)
	}

	return r
}
