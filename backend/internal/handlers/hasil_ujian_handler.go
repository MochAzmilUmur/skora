package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/usecase"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
)

type HasilUjianHandler struct {
	uc *usecase.HasilUjianUsecase
}

func NewHasilUjianHandler(uc *usecase.HasilUjianUsecase) *HasilUjianHandler {
	return &HasilUjianHandler{uc}
}

func (h *HasilUjianHandler) CreateHasilUjian(c *gin.Context) {
	var req validator.CreateHasilUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	hasil, err := h.uc.Create(usecase.CreateHasilInput{SessionID: req.SessionID})
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, hasil)
}

func (h *HasilUjianHandler) GetHasilUjians(c *gin.Context) {
	sessionID := 0
	if raw := c.Query("session_id"); raw != "" {
		sid, err := strconv.Atoi(raw)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "session_id harus berupa angka"})
			return
		}
		sessionID = sid
	}
	data, err := h.uc.GetAll(sessionID)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *HasilUjianHandler) GetHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	hasil, err := h.uc.GetByID(id)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, hasil)
}

func (h *HasilUjianHandler) UpdateHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	var req struct {
		JawabanBenar   *int     `json:"jawaban_benar"`
		JawabanSalah   *int     `json:"jawaban_salah"`
		TotalQuestions *int     `json:"total_questions"`
		Skor           *float64 `json:"skor"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	existing, err := h.uc.GetByID(id)
	if err != nil {
		respondError(c, err)
		return
	}
	if req.JawabanBenar != nil {
		existing.JawabanBenar = *req.JawabanBenar
	}
	if req.JawabanSalah != nil {
		existing.JawabanSalah = *req.JawabanSalah
	}
	if req.TotalQuestions != nil {
		existing.TotalQuestions = *req.TotalQuestions
	}
	if req.Skor != nil {
		existing.Skor = *req.Skor
	}
	hasil, err := h.uc.Update(id, existing)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, hasil)
}

func (h *HasilUjianHandler) DeleteHasilUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	if err := h.uc.Delete(id); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Hasil ujian berhasil dihapus"})
}

func (h *HasilUjianHandler) GetHasilByRoom(c *gin.Context) {
	roomIDStr := c.Param("id")
	hasils, err := h.uc.GetByRoom(roomIDStr)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, hasils)
}
