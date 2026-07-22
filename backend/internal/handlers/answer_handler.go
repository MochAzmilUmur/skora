package handlers

import (
	"net/http"
	"strconv"
	"time"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AnswerHandler struct {
	DB *gorm.DB
}

func NewAnswerHandler(db *gorm.DB) *AnswerHandler {
	return &AnswerHandler{DB: db}
}

func (h *AnswerHandler) CreateAnswer(c *gin.Context) {
	var answer models.Answer
	if err := c.ShouldBindJSON(&answer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	answer.AnsweredAt = time.Now()

	if err := h.DB.Create(&answer).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, answer)
}

func (h *AnswerHandler) GetAnswers(c *gin.Context) {
	sessionID := c.Query("session_id")

	query := h.DB.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption")
	if sessionID != "" {
		sid, err := strconv.Atoi(sessionID)
		if err == nil {
			query = query.Where("session_id = ?", sid)
		}
	}

	var answers []models.Answer
	if err := query.Find(&answers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, answers)
}

func (h *AnswerHandler) GetAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var answer models.Answer
	if err := h.DB.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption").First(&answer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Answer not found"})
		return
	}

	c.JSON(http.StatusOK, answer)
}

func (h *AnswerHandler) UpdateAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var answer models.Answer
	if err := h.DB.First(&answer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Answer not found"})
		return
	}

	if err := c.ShouldBindJSON(&answer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.DB.Save(&answer).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, answer)
}

func (h *AnswerHandler) DeleteAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	if err := h.DB.Delete(&models.Answer{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Answer deleted successfully"})
}
