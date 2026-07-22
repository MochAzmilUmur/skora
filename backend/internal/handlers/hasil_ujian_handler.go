package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type HasilUjianHandler struct {
	DB *gorm.DB
}

func NewHasilUjianHandler(db *gorm.DB) *HasilUjianHandler {
	return &HasilUjianHandler{DB: db}
}

// CreateHasilUjian auto-calculates score from answers in the session.
func (h *HasilUjianHandler) CreateHasilUjian(c *gin.Context) {
	var input struct {
		SessionID int `json:"session_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Prevent duplicate hasil
	var existing models.HasilUjian
	if err := h.DB.Where("session_id = ?", input.SessionID).First(&existing).Error; err == nil {
		c.JSON(http.StatusOK, existing)
		return
	}

	// Load all answers for this session with question options
	var answers []models.Answer
	if err := h.DB.Preload("Pertanyaan.QuestionOptions").Where("session_id = ?", input.SessionID).Find(&answers).Error; err != nil {
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
		SessionID:      input.SessionID,
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

func (h *HasilUjianHandler) GetHasilUjians(c *gin.Context) {
	sessionID := c.Query("session_id")

	query := h.DB.Preload("SesiUjian")
	if sessionID != "" {
		sid, err := strconv.Atoi(sessionID)
		if err == nil {
			query = query.Where("session_id = ?", sid)
		}
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

func (h *HasilUjianHandler) GetHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var hasil models.HasilUjian
	if err := h.DB.Preload("SesiUjian").First(&hasil, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	c.JSON(http.StatusOK, hasil)
}

func (h *HasilUjianHandler) UpdateHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var hasil models.HasilUjian
	if err := h.DB.First(&hasil, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	if err := c.ShouldBindJSON(&hasil); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.DB.Save(&hasil).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, hasil)
}

func (h *HasilUjianHandler) DeleteHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	if err := h.DB.Delete(&models.HasilUjian{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Hasil ujian deleted successfully"})
}

// GetHasilByRoom returns all hasil ujian for a room (rekap nilai peserta).
func (h *HasilUjianHandler) GetHasilByRoom(c *gin.Context) {
	roomID := c.Param("id")
	if roomID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "room id required"})
		return
	}

	// Join: hasil_ujian → sesi_ujian → room
	var hasils []models.HasilUjian
	if err := h.DB.
		Preload("SesiUjian.User").
		Preload("SesiUjian.Room").
		Joins("JOIN sesi_ujian ON sesi_ujian.id = hasil_ujian.session_id").
		Where("sesi_ujian.room_id = ?", roomID).
		Find(&hasils).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, hasils)
}
