package handlers

import (
	"errors"
	"net/http"
	"strconv"

	"backend/internal/apperrors"
	"backend/internal/usecase"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
)

type SesiUjianHandler struct {
	uc *usecase.SesiUjianUsecase
}

func NewSesiUjianHandler(uc *usecase.SesiUjianUsecase) *SesiUjianHandler {
	return &SesiUjianHandler{uc}
}

func (h *SesiUjianHandler) CreateSesiUjian(c *gin.Context) {
	var req validator.CreateSesiUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	sesi, err := h.uc.Create(usecase.CreateSesiInput{RoomID: req.RoomID, UserID: req.UserID})
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, sesi)
}

func (h *SesiUjianHandler) GetSesiUjians(c *gin.Context) {
	userID := 0
	if raw := c.Query("user_id"); raw != "" {
		uid, err := strconv.Atoi(raw)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id harus berupa angka"})
			return
		}
		userID = uid
	}
	sesis, err := h.uc.GetAll(userID)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, sesis)
}

func (h *SesiUjianHandler) GetSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	sesi, err := h.uc.GetByID(id)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, sesi)
}

func (h *SesiUjianHandler) UpdateSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	var req validator.UpdateSesiUjianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	sesi, err := h.uc.Update(usecase.UpdateSesiInput{ID: id, Status: req.Status})
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, sesi)
}

func (h *SesiUjianHandler) DeleteSesiUjian(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID harus berupa angka"})
		return
	}
	if err := h.uc.Delete(id); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Sesi ujian berhasil dihapus"})
}

// respondError maps apperrors domain errors to HTTP status codes.
// Shared by all handlers in this package.
func respondError(c *gin.Context, err error) {
	var appErr *apperrors.AppError
	if errors.As(err, &appErr) {
		switch {
		case errors.Is(appErr.Code, apperrors.ErrNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": appErr.Message})
		case errors.Is(appErr.Code, apperrors.ErrConflict):
			c.JSON(http.StatusConflict, gin.H{"error": appErr.Message})
		case errors.Is(appErr.Code, apperrors.ErrBadRequest):
			c.JSON(http.StatusBadRequest, gin.H{"error": appErr.Message})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": appErr.Message})
		}
		return
	}
	c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
}
