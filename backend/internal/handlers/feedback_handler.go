package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"backend/internal/infrastructure/socket"
	"backend/internal/usecase"
)

type FeedbackHandler struct {
	uc *usecase.FeedbackUsecase
}

func NewFeedbackHandler(db *gorm.DB, hub *socket.Hub) *FeedbackHandler {
	return &FeedbackHandler{
		uc: usecase.NewFeedbackUsecase(db, hub),
	}
}

// SendFeedback godoc
// POST /api/feedback
// Body: { "hasil_id": 1, "asesor_id": 2, "komentar": "..." }
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

	status := http.StatusCreated
	c.JSON(status, gin.H{
		"feedback":  result.Feedback,
		"delivered": result.Delivered,
	})
}
