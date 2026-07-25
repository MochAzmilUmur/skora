package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SesiUjianHandler struct {
	DB  *gorm.DB
	Hub *socket.Hub
}

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

func (h *SesiUjianHandler) CreateSesiUjian(c *gin.Context) {
	var sesi models.SesiUjian
	if err := c.ShouldBindJSON(&sesi); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	sesi.StartTime = time.Now()
	sesi.Status = "ongoing"

	if err := h.DB.Create(&sesi).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("Room").Preload("User").First(&sesi, sesi.ID)
	go h.broadcastExamStarted(sesi)

	c.JSON(http.StatusCreated, sesi)
}

func (h *SesiUjianHandler) GetSesiUjians(c *gin.Context) {
	userID := c.Query("user_id")

	var sesis []models.SesiUjian
	query := h.DB.Preload("Room").Preload("User")

	if userID != "" {
		uid, err := strconv.Atoi(userID)
		if err == nil {
			query = query.Where("user_id = ?", uid)
		}
	}

	if err := query.Find(&sesis).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sesis)
}

func (h *SesiUjianHandler) GetSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var sesi models.SesiUjian
	if err := h.DB.Preload("Room").Preload("User").First(&sesi, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sesi ujian not found"})
		return
	}

	c.JSON(http.StatusOK, sesi)
}

func (h *SesiUjianHandler) UpdateSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var sesi models.SesiUjian
	if err := h.DB.First(&sesi, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Sesi ujian not found"})
		return
	}

	var input struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{"status": input.Status}
	if input.Status == "completed" || input.Status == "timeout" {
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

func (h *SesiUjianHandler) DeleteSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	if err := h.DB.Delete(&models.SesiUjian{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Sesi ujian deleted successfully"})
}
