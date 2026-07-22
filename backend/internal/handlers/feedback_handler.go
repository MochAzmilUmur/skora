package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/usecase"
)

type FeedbackHandler struct {
	db *gorm.DB
	uc *usecase.FeedbackUsecase
}

func NewFeedbackHandler(db *gorm.DB, hub *socket.Hub) *FeedbackHandler {
	return &FeedbackHandler{
		db: db,
		uc: usecase.NewFeedbackUsecase(db, hub),
	}
}

// SendFeedback — POST /api/feedback
func (h *FeedbackHandler) SendFeedback(c *gin.Context) {
	var input usecase.SendFeedbackInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
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

// GetFeedbackByHasil — GET /api/feedback?hasil_id=X
func (h *FeedbackHandler) GetFeedbackByHasil(c *gin.Context) {
	hasilIDStr := c.Query("hasil_id")
	if hasilIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "hasil_id required"})
		return
	}
	hasilID, err := strconv.Atoi(hasilIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid hasil_id"})
		return
	}

	var feedbacks []models.Feedback
	if err := h.db.Preload("Asesor").Where("hasil_id = ?", hasilID).Find(&feedbacks).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, feedbacks)
}

// DeleteFeedback — DELETE /api/feedback/:id
func (h *FeedbackHandler) DeleteFeedback(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	callerID := c.GetInt("user_id")
	var fb models.Feedback
	if err := h.db.First(&fb, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "feedback not found"})
		return
	}
	if fb.AsesorID != callerID {
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
		return
	}

	h.db.Delete(&fb)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}
