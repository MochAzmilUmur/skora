package handlers

import (
	"net/http"
	"strconv"
	"time"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SesiUjianHandler struct {
	DB *gorm.DB
}

func NewSesiUjianHandler(db *gorm.DB) *SesiUjianHandler {
	return &SesiUjianHandler{DB: db}
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
