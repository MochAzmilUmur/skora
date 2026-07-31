package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/usecase"
	"backend/internal/validator"
)

// FeedbackHandler handles feedback endpoints.
type FeedbackHandler struct {
	db *gorm.DB
	uc *usecase.FeedbackUsecase
}

// NewFeedbackHandler creates a new FeedbackHandler.
func NewFeedbackHandler(db *gorm.DB, hub *socket.Hub) *FeedbackHandler {
	return &FeedbackHandler{
		db: db,
		uc: usecase.NewFeedbackUsecase(db, hub),
	}
}

// SendFeedback handles POST /api/feedback.
func (h *FeedbackHandler) SendFeedback(c *gin.Context) {
	var req validator.SendFeedbackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	// Convert to usecase input
	input := usecase.SendFeedbackInput{
		HasilID:  req.HasilID,
		AsesorID: req.AsesorID,
		Komentar: req.Komentar,
	}

	result, err := h.uc.Execute(input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"feedback":  result.Feedback,
		"delivered": result.Delivered,
	})
}

// GetFeedbackByHasil handles GET /api/feedback?hasil_id=X.
func (h *FeedbackHandler) GetFeedbackByHasil(c *gin.Context) {
	hasilIDStr := c.Query("hasil_id")
	if hasilIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "hasil_id query parameter is required"})
		return
	}
	hasilID, err := strconv.Atoi(hasilIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid hasil_id: must be a number"})
		return
	}

	// Verify hasil ujian exists
	var hasil models.HasilUjian
	if err := h.db.First(&hasil, hasilID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hasil ujian not found"})
		return
	}

	var feedbacks []models.Feedback
	if err := h.db.Preload("Asesor").Where("hasil_id = ?", hasilID).Find(&feedbacks).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, feedbacks)
}

// DeleteFeedback handles DELETE /api/feedback/:id.
func (h *FeedbackHandler) DeleteFeedback(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	callerID := c.GetInt("user_id")
	var fb models.Feedback
	if err := h.db.First(&fb, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Feedback not found"})
		return
	}
	if fb.AsesorID != callerID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: you can only delete your own feedback"})
		return
	}

	h.db.Delete(&fb)
	c.JSON(http.StatusOK, gin.H{"message": "Feedback deleted successfully"})
}
