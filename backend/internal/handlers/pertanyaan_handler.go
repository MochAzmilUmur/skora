package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"backend/internal/models"
	"backend/internal/usecase"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/xuri/excelize/v2"
	"gorm.io/gorm"
)

// PertanyaanHandler handles question CRUD and Excel import endpoints.
type PertanyaanHandler struct {
	DB      *gorm.DB
	Usecase usecase.PertanyaanUseCase
}

// NewPertanyaanHandler creates a new PertanyaanHandler.
func NewPertanyaanHandler(db *gorm.DB) *PertanyaanHandler {
	return &PertanyaanHandler{
		DB:      db,
		Usecase: usecase.NewPertanyaanUseCase(),
	}
}

// CreatePertanyaan handles POST /api/pertanyaans.
func (h *PertanyaanHandler) CreatePertanyaan(c *gin.Context) {
	var req validator.CreatePertanyaanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	// Validate UUID format
	if ferr := validator.ValidateUUID("room_id", req.RoomID); ferr != nil {
		validator.AbortWithValidationErrors(c, []validator.FieldError{*ferr})
		return
	}

	// Validate options for multiple choice
	if optErrs := req.ValidateOptions(); len(optErrs) > 0 {
		validator.AbortWithValidationErrors(c, optErrs)
		return
	}

	// Verify room exists
	roomID, _ := uuid.Parse(req.RoomID)
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	// Enforce room_type ↔ type_pertanyaan contract
	switch room.RoomType {
	case "PRAKTIKUM":
		if req.TypePertanyaan != "file_upload" {
			validator.AbortWithValidationErrors(c, []validator.FieldError{
				{Field: "type_pertanyaan", Message: "room PRAKTIKUM hanya menerima soal tipe file_upload"},
			})
			return
		}
	case "PILIHAN_GANDA":
		if req.TypePertanyaan != "multiple_choice" {
			validator.AbortWithValidationErrors(c, []validator.FieldError{
				{Field: "type_pertanyaan", Message: "room PILIHAN_GANDA hanya menerima soal tipe multiple_choice"},
			})
			return
		}
	case "HYBRID":
		if req.TypePertanyaan != "multiple_choice" && req.TypePertanyaan != "text" {
			validator.AbortWithValidationErrors(c, []validator.FieldError{
				{Field: "type_pertanyaan", Message: "room HYBRID hanya menerima soal tipe multiple_choice atau text"},
			})
			return
		}
	}

	// Build question options
	options := make([]models.QuestionOption, len(req.QuestionOptions))
	for i, opt := range req.QuestionOptions {
		options[i] = models.QuestionOption{
			OptionText: opt.OptionText,
			IsCorrect:  opt.IsCorrect,
		}
	}

	pertanyaan := models.Pertanyaan{
		RoomID:          roomID,
		PertanyaanText:  req.PertanyaanText,
		GambarURL:       req.GambarURL,
		TypePertanyaan:  req.TypePertanyaan,
		CreatedAt:       time.Now(),
		QuestionOptions: options,
	}

	if err := h.DB.Create(&pertanyaan).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Reload with options
	h.DB.Preload("QuestionOptions").First(&pertanyaan, pertanyaan.ID)
	c.JSON(http.StatusCreated, pertanyaan)
}

// GetPertanyaansByRoom returns paginated questions for a specific room.
func (h *PertanyaanHandler) GetPertanyaansByRoom(c *gin.Context) {
	roomIDStr := c.Param("id")
	roomID, err := uuid.Parse(roomIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID: must be a valid UUID"})
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

	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	var total int64
	h.DB.Model(&models.Pertanyaan{}).Where("room_id = ?", roomID).Count(&total)

	var pertanyaans []models.Pertanyaan
	// Fetch all questions for this room to allow consistent shuffling across the entire set
	if err := h.DB.
		Preload("QuestionOptions").
		Where("room_id = ?", roomID).
		Find(&pertanyaans).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if room.ShuffleQ {
		userIDRaw, exists := c.Get("user_id")
		var participantID int
		if exists {
			participantID = userIDRaw.(int)
		}
		// Apabila bukan dari endpoint protected yang memiliki user_id, participantID akan 0. 
		// Karena ini CBT participant, asumsinya user login.
		pertanyaans = h.Usecase.ShufflePertanyaans(roomID, participantID, pertanyaans)
	}

	// In-memory pagination
	start := offset
	end := start + limit
	if start > len(pertanyaans) {
		start = len(pertanyaans)
	}
	if end > len(pertanyaans) {
		end = len(pertanyaans)
	}
	paginatedPertanyaans := pertanyaans[start:end]

	c.JSON(http.StatusOK, gin.H{
		"data":  paginatedPertanyaans,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetPertanyaans returns all questions. Supports optional ?room_id= filter.
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
		if ferr := validator.ValidateUUID("room_id", roomID); ferr != nil {
			validator.AbortWithValidationErrors(c, []validator.FieldError{*ferr})
			return
		}
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

// GetPertanyaan handles GET /api/pertanyaans/:id.
func (h *PertanyaanHandler) GetPertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var pertanyaan models.Pertanyaan
	if err := h.DB.Preload("QuestionOptions").First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	c.JSON(http.StatusOK, pertanyaan)
}

// UpdatePertanyaan handles PUT /api/pertanyaans/:id.
func (h *PertanyaanHandler) UpdatePertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var pertanyaan models.Pertanyaan
	if err := h.DB.First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	var req validator.UpdatePertanyaanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	updates := map[string]interface{}{}
	if req.PertanyaanText != "" {
		updates["pertanyaan_text"] = req.PertanyaanText
	}
	if req.GambarURL != "" {
		updates["gambar_url"] = req.GambarURL
	}
	if req.TypePertanyaan != "" {
		updates["type_pertanyaan"] = req.TypePertanyaan
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	if err := h.DB.Model(&pertanyaan).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("QuestionOptions").First(&pertanyaan, id)
	c.JSON(http.StatusOK, pertanyaan)
}

// DeletePertanyaan handles DELETE /api/pertanyaans/:id.
func (h *PertanyaanHandler) DeletePertanyaan(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var pertanyaan models.Pertanyaan
	if err := h.DB.First(&pertanyaan, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pertanyaan not found"})
		return
	}

	if err := h.DB.Delete(&pertanyaan).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pertanyaan deleted"})
}

// ImportExcel handles POST /api/rooms/:id/import-excel.
// Standard Excel Header format:
// Col 0: Pertanyaan
// Col 1: Tipe (multiple_choice / text)
// Col 2: Opsi A
// Col 3: Opsi B
// Col 4: Opsi C
// Col 5: Opsi D
// Col 6: Jawaban Benar (A/B/C/D atau Teks Opsi)
func (h *PertanyaanHandler) ImportExcel(c *gin.Context) {
	roomIDStr := c.Param("id")
	roomID, err := uuid.Parse(roomIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID: must be a valid UUID"})
		return
	}

	// Verify room exists
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded (field 'file' required)"})
		return
	}

	fileStream, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open uploaded file"})
		return
	}
	defer fileStream.Close()

	xlsx, err := excelize.OpenReader(fileStream)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Excel file format"})
		return
	}
	defer xlsx.Close()

	sheets := xlsx.GetSheetList()
	if len(sheets) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Excel file has no sheets"})
		return
	}

	rows, err := xlsx.GetRows(sheets[0])
	if err != nil || len(rows) <= 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Excel sheet is empty or missing data rows"})
		return
	}

	importedCount := 0

	err = h.DB.Transaction(func(tx *gorm.DB) error {
		for i, row := range rows {
			if i == 0 {
				continue // Skip header row
			}

			if len(row) == 0 || strings.TrimSpace(row[0]) == "" {
				continue // Skip empty questions
			}

			qText := strings.TrimSpace(row[0])
			qType := "multiple_choice"
			if len(row) > 1 && strings.TrimSpace(row[1]) != "" {
				qTypeStr := strings.ToLower(strings.TrimSpace(row[1]))
				if qTypeStr == "text" || qTypeStr == "essay" {
					qType = "text"
				}
			}

			var options []models.QuestionOption
			if qType == "multiple_choice" {
				var optTexts []string
				// Col 2..5 (A, B, C, D)
				for colIdx := 2; colIdx <= 5; colIdx++ {
					if len(row) > colIdx && strings.TrimSpace(row[colIdx]) != "" {
						optTexts = append(optTexts, strings.TrimSpace(row[colIdx]))
					}
				}

				correctKey := ""
				if len(row) > 6 {
					correctKey = strings.TrimSpace(row[6])
				}

				for idx, txt := range optTexts {
					isCorrect := false
					// Compare A, B, C, D or exact match
					label := fmt.Sprintf("%c", 'A'+idx) // "A", "B", "C", "D"
					if strings.EqualFold(correctKey, label) || strings.EqualFold(correctKey, txt) {
						isCorrect = true
					}

					options = append(options, models.QuestionOption{
						OptionText: txt,
						IsCorrect:  isCorrect,
					})
				}

				// If no option was marked correct but we have options, set first as correct as fallback
				if len(options) > 0 {
					hasCorrect := false
					for _, opt := range options {
						if opt.IsCorrect {
							hasCorrect = true
							break
						}
					}
					if !hasCorrect {
						options[0].IsCorrect = true
					}
				}
			}

			pertanyaan := models.Pertanyaan{
				RoomID:          roomID,
				PertanyaanText:  qText,
				TypePertanyaan:  qType,
				CreatedAt:       time.Now(),
				QuestionOptions: options,
			}

			if err := tx.Create(&pertanyaan).Error; err != nil {
				return err
			}
			importedCount++
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to import Excel rows: %v", err)})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":        "Excel imported successfully",
		"total_imported": importedCount,
	})
}
