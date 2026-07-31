package handlers_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"backend/internal/handlers"
	"backend/internal/infrastructure/socket"
	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

const testJWTSecret = "test-secret-key-for-unit-tests"

func init() {
	gin.SetMode(gin.TestMode)
	os.Setenv("JWT_SECRET", testJWTSecret)
}

// setupTestDB creates an in-memory SQLite database with all tables migrated.
func setupTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("failed to open test db: %v", err)
	}

	err = db.AutoMigrate(
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
	)
	if err != nil {
		t.Fatalf("failed to migrate test db: %v", err)
	}

	return db
}

// setupRouter creates a gin engine with all routes registered for testing.
func setupRouter(db *gorm.DB) *gin.Engine {
	r := gin.New()
	hub := socket.NewHub()
	go hub.Run()

	authHandler := handlers.NewAuthHandler(db)
	userHandler := handlers.NewUserHandler(db)
	roomHandler := handlers.NewRoomHandler(db, hub)
	pertanyaanHandler := handlers.NewPertanyaanHandler(db)
	sesiUjianHandler := handlers.NewSesiUjianHandler(db, hub)
	answerHandler := handlers.NewAnswerHandler(db)
	hasilUjianHandler := handlers.NewHasilUjianHandler(db)
	feedbackHandler := handlers.NewFeedbackHandler(db, hub)
	uploadHandler := handlers.NewUploadHandler()

	api := r.Group("/api")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
		}

		// Protected routes — inject user_id from JWT for testing
		protected := api.Group("")
		protected.Use(testJWTMiddleware())

		protected.POST("/upload", uploadHandler.UploadFile)

		users := protected.Group("/users")
		{
			users.POST("", userHandler.CreateUser)
			users.GET("", userHandler.GetUsers)
			users.GET("/:id", userHandler.GetUser)
			users.PUT("/:id", userHandler.UpdateUser)
			users.POST("/:id/change-password", userHandler.ChangePassword)
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
			rooms.GET("/:id/pertanyaans", pertanyaanHandler.GetPertanyaansByRoom)
			rooms.POST("/:id/import-excel", pertanyaanHandler.ImportExcel)
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

		protected.GET("/rooms/:id/hasil", hasilUjianHandler.GetHasilByRoom)
	}

	return r
}

// testJWTMiddleware extracts user_id from JWT token in Authorization header.
func testJWTMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization"})
			return
		}
		tokenStr := authHeader[len("Bearer "):]
		token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
			return []byte(testJWTSecret), nil
		})
		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			return
		}
		claims := token.Claims.(jwt.MapClaims)
		c.Set("user_id", int(claims["user_id"].(float64)))
		c.Next()
	}
}

// generateTestJWT creates a JWT token for testing with the given user ID.
func generateTestJWT(userID int) string {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(1 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, _ := token.SignedString([]byte(testJWTSecret))
	return signed
}

// authHeader returns an Authorization header value for the given user ID.
func authHeader(userID int) string {
	return "Bearer " + generateTestJWT(userID)
}

// createTestUser creates a user in the test database and returns it.
func createTestUser(t *testing.T, db *gorm.DB, nama, email, password string) models.User {
	t.Helper()
	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	user := models.User{
		Nama:         nama,
		Email:        email,
		PasswordHash: string(hash),
		CreatedAt:    time.Now(),
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("failed to create test user: %v", err)
	}
	return user
}

// performRequest executes an HTTP request against the router and returns the response.
func performRequest(r *gin.Engine, method, path string, body interface{}, headers ...string) *httptest.ResponseRecorder {
	var reqBody *bytes.Buffer
	if body != nil {
		jsonBytes, _ := json.Marshal(body)
		reqBody = bytes.NewBuffer(jsonBytes)
	} else {
		reqBody = bytes.NewBuffer(nil)
	}

	req := httptest.NewRequest(method, path, reqBody)
	req.Header.Set("Content-Type", "application/json")

	// Headers come in key-value pairs
	for i := 0; i+1 < len(headers); i += 2 {
		req.Header.Set(headers[i], headers[i+1])
	}

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

// performAuthRequest is a convenience wrapper for authenticated requests.
func performAuthRequest(r *gin.Engine, method, path string, body interface{}, userID int) *httptest.ResponseRecorder {
	return performRequest(r, method, path, body, "Authorization", authHeader(userID))
}

// parseJSON unmarshals the response body into a map.
func parseJSON(t *testing.T, w *httptest.ResponseRecorder) map[string]interface{} {
	t.Helper()
	var result map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &result); err != nil {
		t.Fatalf("failed to parse JSON response: %v\nbody: %s", err, w.Body.String())
	}
	return result
}

// assertStatus checks that the response has the expected status code.
func assertStatus(t *testing.T, w *httptest.ResponseRecorder, expected int) {
	t.Helper()
	if w.Code != expected {
		t.Errorf("expected status %d, got %d\nbody: %s", expected, w.Code, w.Body.String())
	}
}

// assertJSONHasField checks that the response body contains the given field.
func assertJSONHasField(t *testing.T, body map[string]interface{}, field string) {
	t.Helper()
	if _, ok := body[field]; !ok {
		t.Errorf("expected JSON to have field %q, got: %v", field, body)
	}
}

// createTestRoom creates a room directly in the database for testing.
func createTestRoom(t *testing.T, db *gorm.DB, userID int) models.Room {
	t.Helper()
	room := models.Room{
		RoomName:  "Test Room",
		Durasi:    60,
		CreatedBy: userID,
		CreatedAt: time.Now(),
		RoomCode:  fmt.Sprintf("%03d-%03d", time.Now().UnixNano()%1000, time.Now().UnixNano()%997),
	}
	if err := db.Create(&room).Error; err != nil {
		t.Fatalf("failed to create test room: %v", err)
	}
	return room
}
