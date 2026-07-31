package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// SesiUjianHandler handles exam session CRUD endpoints.
type SesiUjianHandler struct {
	DB  *gorm.DB
	Hub *socket.Hub
}

// NewSesiUjianHandler creates a new SesiUjianHandler.
func NewSesiUjianHandler(db *gorm.DB, hub *socket.Hub) *SesiUjianHandler {
	return &SesiUjianHandler{DB: db, Hub: hub}
}

// broadcastExamStarted notifies room creator that a student started the exam.
func (h *SesiUjianHandler) broadcastExamStarted(sesi models.SesiUjian) {
	payload, _ := json.Marshal(map[string]any{
		"type":       "exam_started",
		"session_id": sesi.ID,
		"room_id":    sesi.RoomID.String(),
		"room_name":  sesi.Room.RoomName,
		"user_id":    sesi.UserID,
		"user_name":  sesi.User.Nama,
		"started_at": sesi.StartTime,
	})
	// Notify room creator
	h.Hub.SendToUser(sesi.Room.CreatedBy, payload)
}

// CreateSesiUjian handles POST /api/sesi-ujians.
func (h *SesiUjianHandler) CreateSesiUjian(c *gin.Context) {
	var req validator.CreateSesiUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	// Validate UUID format
	if ferr := validator.ValidateUUID("room_id", req.RoomID); ferr != nil {
		validator.AbortWithValidationErrors(c, []validator.FieldError{*ferr})
		return
	}

	roomID, _ := uuid.Parse(req.RoomID)

	// Verify room exists
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	// Verify user exists
	var user models.User
	if err := h.DB.First(&user, req.UserID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	sesi := models.SesiUjian{
		RoomID:    roomID,
		UserID:    req.UserID,
		StartTime: time.Now(),
		Status:    "ongoing",
	}

	if err := h.DB.Create(&sesi).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("Room").Preload("User").First(&sesi, sesi.ID)
	go h.broadcastExamStarted(sesi)

	c.JSON(http.StatusCreated, sesi)
}

// GetSesiUjians handles GET /api/sesi-ujians.
func (h *SesiUjianHandler) GetSesiUjians(c *gin.Context) {
	userID := c.Query("user_id")

	var sesis []models.SesiUjian
	query := h.DB.Preload("Room").Preload("User")

	if userID != "" {
		uid, err := strconv.Atoi(userID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id: must be a number"})
			return
		}
		query = query.Where("user_id = ?", uid)
	}

	if err := query.Find(&sesis).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sesis)
}

// GetSesiUjian handles GET /api/sesi-ujians/:id.
func (h *SesiUjianHandler) GetSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var sesi models.SesiUjian
	if err := h.DB.Preload("Room").Preload("User").First(&sesi, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sesi ujian not found"})
		return
	}

	c.JSON(http.StatusOK, sesi)
}

// UpdateSesiUjian handles PUT /api/sesi-ujians/:id.
func (h *SesiUjianHandler) UpdateSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var sesi models.SesiUjian
	if err := h.DB.First(&sesi, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sesi ujian not found"})
		return
	}

	var req validator.UpdateSesiUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	updates := map[string]interface{}{"status": req.Status}
	if req.Status == "completed" || req.Status == "timeout" {
		now := time.Now()
		updates["end_time"] = now
	}

	if err := h.DB.Model(&sesi).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("Room").Preload("User").First(&sesi, id)
	c.JSON(http.StatusOK, sesi)
}

// DeleteSesiUjian handles DELETE /api/sesi-ujians/:id.
func (h *SesiUjianHandler) DeleteSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	// Verify exists
	var sesi models.SesiUjian
	if err := h.DB.First(&sesi, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sesi ujian not found"})
		return
	}

	if err := h.DB.Delete(&models.SesiUjian{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Sesi ujian deleted successfully"})
}
