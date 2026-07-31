package handlers

import (
	"net/http"
	"strconv"
	"time"

	"backend/internal/models"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AnswerHandler handles answer CRUD endpoints.
type AnswerHandler struct {
	DB *gorm.DB
}

// NewAnswerHandler creates a new AnswerHandler.
func NewAnswerHandler(db *gorm.DB) *AnswerHandler {
	return &AnswerHandler{DB: db}
}

// CreateAnswer handles POST /api/answers.
func (h *AnswerHandler) CreateAnswer(c *gin.Context) {
	var req validator.CreateAnswerRequest
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

	// Verify question exists
	var pertanyaan models.Pertanyaan
	if err := h.DB.First(&pertanyaan, req.QuestionID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Question not found"})
		return
	}

	// Validate selected_option_id if provided
	if req.SelectedOptionID != nil {
		var option models.QuestionOption
		if err := h.DB.First(&option, *req.SelectedOptionID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Selected option not found"})
			return
		}
		// Verify option belongs to the question
		if option.QuestionID != req.QuestionID {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Selected option does not belong to this question"})
			return
		}
	}

	answer := models.Answer{
		SessionID:        req.SessionID,
		QuestionID:       req.QuestionID,
		AnswerText:       req.AnswerText,
		SelectedOptionID: req.SelectedOptionID,
		AnsweredAt:       time.Now(),
	}

	if err := h.DB.Create(&answer).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, answer)
}

// GetAnswers handles GET /api/answers.
func (h *AnswerHandler) GetAnswers(c *gin.Context) {
	sessionID := c.Query("session_id")

	query := h.DB.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption")
	if sessionID != "" {
		sid, err := strconv.Atoi(sessionID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid session_id: must be a number"})
			return
		}
		query = query.Where("session_id = ?", sid)
	}

	var answers []models.Answer
	if err := query.Find(&answers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, answers)
}

// GetAnswer handles GET /api/answers/:id.
func (h *AnswerHandler) GetAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var answer models.Answer
	if err := h.DB.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption").First(&answer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Answer not found"})
		return
	}

	c.JSON(http.StatusOK, answer)
}

// UpdateAnswer handles PUT /api/answers/:id.
func (h *AnswerHandler) UpdateAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var answer models.Answer
	if err := h.DB.First(&answer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Answer not found"})
		return
	}

	var input struct {
		AnswerText       *string `json:"answer_text"`
		SelectedOptionID *int    `json:"selected_option_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	updates := map[string]interface{}{}
	if input.AnswerText != nil {
		updates["answer_text"] = *input.AnswerText
	}
	if input.SelectedOptionID != nil {
		// Verify option exists and belongs to the question
		var option models.QuestionOption
		if err := h.DB.First(&option, *input.SelectedOptionID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Selected option not found"})
			return
		}
		if option.QuestionID != answer.QuestionID {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Selected option does not belong to this question"})
			return
		}
		updates["selected_option_id"] = *input.SelectedOptionID
	}

	if err := h.DB.Model(&answer).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, answer)
}

// DeleteAnswer handles DELETE /api/answers/:id.
func (h *AnswerHandler) DeleteAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	// Verify exists
	var answer models.Answer
	if err := h.DB.First(&answer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Answer not found"})
		return
	}

	if err := h.DB.Delete(&models.Answer{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Answer deleted successfully"})
}
