package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PertanyaanHandler struct {
	DB *gorm.DB
}

func NewPertanyaanHandler(db *gorm.DB) *PertanyaanHandler {
	return &PertanyaanHandler{DB: db}
}

func (h *PertanyaanHandler) CreatePertanyaan(c *gin.Context) {
	var pertanyaan models.Pertanyaan
	if err := c.ShouldBindJSON(&pertanyaan); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.DB.Create(&pertanyaan).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Reload with options
	h.DB.Preload("QuestionOptions").First(&pertanyaan, pertanyaan.ID)
	c.JSON(http.StatusCreated, pertanyaan)
}

// GetPertanyaansByRoom returns paginated soal for a specific room.
// Query params: page (default 1), limit (default 20)
func (h *PertanyaanHandler) GetPertanyaansByRoom(c *gin.Context) {
	roomIDStr := c.Param("id")
	roomID, err := uuid.Parse(roomIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var total int64
	h.DB.Model(&models.Pertanyaan{}).Where("room_id = ?", roomID).Count(&total)

	var pertanyaans []models.Pertanyaan
	if err := h.DB.
		Preload("QuestionOptions").
		Where("room_id = ?", roomID).
		Limit(limit).Offset(offset).
		Find(&pertanyaans).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  pertanyaans,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetPertanyaans returns all soal (no soft-deleted). Supports optional ?room_id= filter.
func (h *PertanyaanHandler) GetPertanyaans(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	q := h.DB.Model(&models.Pertanyaan{})
	if roomID := c.Query("room_id"); roomID != "" {
		q = q.Where("room_id = ?", roomID)
	}

	var total int64
	q.Count(&total)

	var pertanyaans []models.Pertanyaan
	if err := q.Preload("QuestionOptions").Limit(limit).Offset(offset).Find(&pertanyaans).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  pertanyaans,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func (h *PertanyaanHandler) GetPertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var pertanyaan models.Pertanyaan
	if err := h.DB.Preload("QuestionOptions").First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	c.JSON(http.StatusOK, pertanyaan)
}

func (h *PertanyaanHandler) UpdatePertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var pertanyaan models.Pertanyaan
	if err := h.DB.First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	var input struct {
		PertanyaanText string `json:"pertanyaan_text"`
		TypePertanyaan string `json:"type_pertanyaan"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}
	if input.PertanyaanText != "" {
		updates["pertanyaan_text"] = input.PertanyaanText
	}
	if input.TypePertanyaan != "" {
		updates["type_pertanyaan"] = input.TypePertanyaan
	}

	if err := h.DB.Model(&pertanyaan).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("QuestionOptions").First(&pertanyaan, id)
	c.JSON(http.StatusOK, pertanyaan)
}

// DeletePertanyaan uses GORM soft delete (sets deleted_at).
func (h *PertanyaanHandler) DeletePertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	// Verify exists first
	var pertanyaan models.Pertanyaan
	if err := h.DB.First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	// Soft delete: GORM sets deleted_at automatically because model has gorm.DeletedAt
	if err := h.DB.Delete(&pertanyaan).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pertanyaan deleted"})
}
