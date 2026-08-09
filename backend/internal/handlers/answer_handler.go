package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/usecase"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
)

type AnswerHandler struct {
	uc *usecase.AnswerUsecase
}

func NewAnswerHandler(uc *usecase.AnswerUsecase) *AnswerHandler {
	return &AnswerHandler{uc}
}

func (h *AnswerHandler) CreateAnswer(c *gin.Context) {
	var req validator.CreateAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	answer, err := h.uc.Upsert(usecase.UpsertAnswerInput{
		SessionID:        req.SessionID,
		QuestionID:       req.QuestionID,
		AnswerText:       req.AnswerText,
		SelectedOptionID: req.SelectedOptionID,
		FileURL:          req.FileURL,
	})
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, answer)
}

func (h *AnswerHandler) GetAnswers(c *gin.Context) {
	sessionID := 0
	if raw := c.Query("session_id"); raw != "" {
		sid, err := strconv.Atoi(raw)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "session_id harus berupa angka"})
			return
		}
		sessionID = sid
	}
	var (
		answers any
		err     error
	)
	if sessionID > 0 {
		answers, err = h.uc.GetBySession(sessionID)
	} else {
		answers, err = h.uc.GetBySession(0)
	}
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, answers)
}

func (h *AnswerHandler) GetAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	answer, err := h.uc.GetByID(id)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, answer)
}

func (h *AnswerHandler) UpdateAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
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
	updates := map[string]any{
		"answer_text":        input.AnswerText,
		"selected_option_id": input.SelectedOptionID,
	}
	answer, err := h.uc.Update(id, updates)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, answer)
}

func (h *AnswerHandler) DeleteAnswer(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	if err := h.uc.Delete(id); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Jawaban berhasil dihapus"})
}
