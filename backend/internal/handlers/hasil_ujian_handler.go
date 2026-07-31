package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// HasilUjianHandler handles exam result endpoints.
type HasilUjianHandler struct {
	DB *gorm.DB
}

// NewHasilUjianHandler creates a new HasilUjianHandler.
func NewHasilUjianHandler(db *gorm.DB) *HasilUjianHandler {
	return &HasilUjianHandler{DB: db}
}

// CreateHasilUjian auto-calculates score from answers in the session.
func (h *HasilUjianHandler) CreateHasilUjian(c *gin.Context) {
	var req validator.CreateHasilUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	// Verify session exists
	var sesi models.SesiUjian
	if err := h.DB.First(&sesi, req.SessionID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	// Prevent duplicate hasil
	var existing models.HasilUjian
	if err := h.DB.Where("session_id = ?", req.SessionID).First(&existing).Error; err == nil {
		c.JSON(http.StatusOK, existing)
		return
	}

	// Load all answers for this session with question options
	var answers []models.Answer
	if err := h.DB.Preload("Pertanyaan.QuestionOptions").Where("session_id = ?", req.SessionID).Find(&answers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	benar := 0
	for _, a := range answers {
		if a.SelectedOptionID != nil {
			for _, opt := range a.Pertanyaan.QuestionOptions {
				if opt.ID == *a.SelectedOptionID && opt.IsCorrect {
					benar++
					break
				}
			}
		}
	}

	total := len(answers)
	salah := total - benar
	skor := 0.0
	if total > 0 {
		skor = float64(benar) / float64(total) * 100
	}

	hasil := models.HasilUjian{
		SessionID:      req.SessionID,
		TotalQuestions: total,
		JawabanBenar:   benar,
		JawabanSalah:   salah,
		Skor:           skor,
	}

	if err := h.DB.Create(&hasil).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, hasil)
}

// GetHasilUjians handles GET /api/hasil-ujians.
func (h *HasilUjianHandler) GetHasilUjians(c *gin.Context) {
	sessionID := c.Query("session_id")

	query := h.DB.Preload("SesiUjian")
	if sessionID != "" {
		sid, err := strconv.Atoi(sessionID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session_id: must be a number"})
			return
		}
		query = query.Where("session_id = ?", sid)
	}

	var hasils []models.HasilUjian
	if err := query.Find(&hasils).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If filtering by session return first item or 404
	if sessionID != "" {
		if len(hasils) == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
			return
		}
		c.JSON(http.StatusOK, hasils[0])
		return
	}

	c.JSON(http.StatusOK, hasils)
}

// GetHasilUjian handles GET /api/hasil-ujians/:id.
func (h *HasilUjianHandler) GetHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var hasil models.HasilUjian
	if err := h.DB.Preload("SesiUjian").First(&hasil, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	c.JSON(http.StatusOK, hasil)
}

// UpdateHasilUjian handles PUT /api/hasil-ujians/:id.
func (h *HasilUjianHandler) UpdateHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var hasil models.HasilUjian
	if err := h.DB.First(&hasil, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	if err := c.ShouldBindJSON(&hasil); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	if err := h.DB.Save(&hasil).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, hasil)
}

// DeleteHasilUjian handles DELETE /api/hasil-ujians/:id.
func (h *HasilUjianHandler) DeleteHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	// Verify exists
	var hasil models.HasilUjian
	if err := h.DB.First(&hasil, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	if err := h.DB.Delete(&models.HasilUjian{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Hasil ujian deleted successfully"})
}

// GetHasilByRoom returns all exam results for a room (rekap nilai peserta).
func (h *HasilUjianHandler) GetHasilByRoom(c *gin.Context) {
	roomIDStr := c.Param("id")
	if roomIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Room ID is required"})
		return
	}

	// Validate UUID format
	if _, err := uuid.Parse(roomIDStr); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID: must be a valid UUID"})
		return
	}

	// Verify room exists
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomIDStr).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	// Join: hasil_ujian → sesi_ujian → room
	var hasils []models.HasilUjian
	if err := h.DB.
		Preload("SesiUjian.User").
		Preload("SesiUjian.Room").
		Joins("JOIN sesi_ujian ON sesi_ujian.id = hasil_ujian.session_id").
		Where("sesi_ujian.room_id = ?", roomIDStr).
		Find(&hasils).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, hasils)
}
