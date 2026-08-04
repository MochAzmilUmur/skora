package validator

import (
	"fmt"
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ──────────────────────────────────────────────
// Structured error response
// ──────────────────────────────────────────────

// FieldError represents a single validation error on a specific field.
type FieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// ValidationError is the standardized error response for validation failures.
type ValidationError struct {
	Error   string       `json:"error"`
	Details []FieldError `json:"details"`
}

// AbortWithValidationErrors writes a 400 response with structured field errors.
func AbortWithValidationErrors(c *gin.Context, errors []FieldError) {
	c.AbortWithStatusJSON(http.StatusBadRequest, ValidationError{
		Error:   "Validation failed",
		Details: errors,
	})
}

// ──────────────────────────────────────────────
// Auth request structs
// ──────────────────────────────────────────────

// RegisterRequest validates the POST /api/auth/register payload.
type RegisterRequest struct {
	Nama     string `json:"nama" binding:"required,min=2,max=100"`
	Email    string `json:"email" binding:"required,email,max=255"`
	Password string `json:"password" binding:"required,min=8,max=72"`
}

// LoginRequest validates the POST /api/auth/login payload.
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// ForgotPasswordRequest validates the POST /api/auth/forgot-password payload.
type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

// ResetPasswordRequest validates the POST /api/auth/reset-password payload.
type ResetPasswordRequest struct {
	Token    string `json:"token" binding:"required,min=1"`
	Password string `json:"password" binding:"required,min=8,max=72"`
}

// ──────────────────────────────────────────────
// User request structs
// ──────────────────────────────────────────────

// UpdateUserRequest validates the PUT /api/users/:id payload.
type UpdateUserRequest struct {
	Nama  string `json:"nama" binding:"omitempty,min=2,max=100"`
	Email string `json:"email" binding:"omitempty,email,max=255"`
}

// ChangePasswordRequest validates the POST /api/users/:id/change-password payload.
type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8,max=72"`
}

// ──────────────────────────────────────────────
// Room request structs
// ──────────────────────────────────────────────

// CreateRoomRequest validates the POST /api/rooms payload.
type CreateRoomRequest struct {
	RoomName    string `json:"room_name" binding:"required,min=3,max=200"`
	Description string `json:"description" binding:"omitempty,max=1000"`
	Durasi      int    `json:"durasi" binding:"required,min=1,max=480"`
	StartDate   string `json:"start_date" binding:"omitempty"`
	RoomType    string `json:"room_type" binding:"required,oneof=PRAKTIKUM PILIHAN_GANDA HYBRID"`
	ShuffleQ    bool   `json:"shuffle_questions"`
	CreatedBy   int    `json:"created_by" binding:"required,min=1"`
}

// UpdateRoomRequest validates the PUT /api/rooms/:id payload.
type UpdateRoomRequest struct {
	RoomName    string `json:"room_name" binding:"omitempty,min=3,max=200"`
	Description string `json:"description" binding:"omitempty,max=1000"`
	Durasi      int    `json:"durasi" binding:"omitempty,min=1,max=480"`
	StartDate   string `json:"start_date" binding:"omitempty"`
	RoomType    string `json:"room_type" binding:"omitempty,oneof=PRAKTIKUM PILIHAN_GANDA HYBRID"`
	ShuffleQ    *bool  `json:"shuffle_questions"`
}

// JoinRoomRequest validates the POST /api/rooms/join payload.
type JoinRoomRequest struct {
	RoomCode string `json:"room_code" binding:"required"`
	UserID   int    `json:"user_id" binding:"required,min=1"`
	Role     string `json:"role" binding:"omitempty,oneof=asesor pelajar"`
}

// AddParticipantRequest validates the POST /api/rooms/:id/participants payload.
type AddParticipantRequest struct {
	UserID int    `json:"user_id" binding:"required,min=1"`
	Role   string `json:"role" binding:"omitempty,oneof=asesor pelajar"`
}

// ──────────────────────────────────────────────
// Pertanyaan request structs
// ──────────────────────────────────────────────

// CreatePertanyaanOptionRequest validates a single question option.
type CreatePertanyaanOptionRequest struct {
	OptionText string `json:"option_text" binding:"required,min=1,max=500"`
	IsCorrect  bool   `json:"is_correct"`
}

// CreatePertanyaanRequest validates the POST /api/pertanyaans payload.
type CreatePertanyaanRequest struct {
	RoomID          string                          `json:"room_id" binding:"required"`
	PertanyaanText  string                          `json:"pertanyaan_text" binding:"required,min=5,max=5000"`
	GambarURL       string                          `json:"gambar_url" binding:"omitempty"`
	TypePertanyaan  string                          `json:"type_pertanyaan" binding:"required,oneof=multiple_choice text file_upload"`
	QuestionOptions []CreatePertanyaanOptionRequest `json:"question_options" binding:"omitempty"`
}

// ValidateOptions checks that multiple_choice has at least 2 options and exactly 1 correct answer.
func (r *CreatePertanyaanRequest) ValidateOptions() []FieldError {
	var errs []FieldError
	if r.TypePertanyaan == "multiple_choice" {
		if len(r.QuestionOptions) < 2 {
			errs = append(errs, FieldError{
				Field:   "question_options",
				Message: "multiple choice questions must have at least 2 options",
			})
		}
		correctCount := 0
		for _, opt := range r.QuestionOptions {
			if opt.IsCorrect {
				correctCount++
			}
		}
		if correctCount == 0 {
			errs = append(errs, FieldError{
				Field:   "question_options",
				Message: "multiple choice questions must have at least 1 correct answer",
			})
		}
	}
	return errs
}

// UpdatePertanyaanRequest validates the PUT /api/pertanyaans/:id payload.
type UpdatePertanyaanRequest struct {
	PertanyaanText string `json:"pertanyaan_text" binding:"omitempty,min=5,max=5000"`
	GambarURL      string `json:"gambar_url" binding:"omitempty"`
	TypePertanyaan string `json:"type_pertanyaan" binding:"omitempty,oneof=multiple_choice text file_upload"`
}

// ──────────────────────────────────────────────
// Sesi Ujian request structs
// ──────────────────────────────────────────────

// CreateSesiUjianRequest validates the POST /api/sesi-ujians payload.
type CreateSesiUjianRequest struct {
	RoomID string `json:"room_id" binding:"required"`
	UserID int    `json:"user_id" binding:"required,min=1"`
}

// UpdateSesiUjianRequest validates the PUT /api/sesi-ujians/:id payload.
type UpdateSesiUjianRequest struct {
	Status string `json:"status" binding:"required,oneof=ongoing completed timeout"`
}

// ──────────────────────────────────────────────
// Answer request structs
// ──────────────────────────────────────────────

// CreateAnswerRequest validates the POST /api/answers payload.
type CreateAnswerRequest struct {
	SessionID        int     `json:"session_id" binding:"required,min=1"`
	QuestionID       int     `json:"question_id" binding:"required,min=1"`
	AnswerText       *string `json:"answer_text"`
	SelectedOptionID *int    `json:"selected_option_id"`
	FileURL          *string `json:"file_url"`
}

// ──────────────────────────────────────────────
// Hasil Ujian request structs
// ──────────────────────────────────────────────

// CreateHasilUjianRequest validates the POST /api/hasil-ujians payload.
type CreateHasilUjianRequest struct {
	SessionID int `json:"session_id" binding:"required,min=1"`
}

// ──────────────────────────────────────────────
// Feedback request structs
// ──────────────────────────────────────────────

// SendFeedbackRequest validates the POST /api/feedback payload.
type SendFeedbackRequest struct {
	HasilID  int    `json:"hasil_id" binding:"required,min=1"`
	AsesorID int    `json:"asesor_id" binding:"required,min=1"`
	SenderID int    `json:"sender_id" binding:"required,min=1"`
	Komentar string `json:"komentar" binding:"required,min=1,max=2000"`
}

// ──────────────────────────────────────────────
// Validation helpers
// ──────────────────────────────────────────────

// roomCodeRegex matches the XXX-XXX format (digits).
var roomCodeRegex = regexp.MustCompile(`^\d{3}-\d{3}$`)

// ValidateRoomCode checks the room code format.
func ValidateRoomCode(code string) *FieldError {
	if !roomCodeRegex.MatchString(code) {
		return &FieldError{
			Field:   "room_code",
			Message: "must be in format XXX-XXX (e.g. 123-456)",
		}
	}
	return nil
}

// ValidateUUID checks that a string is a valid UUID.
func ValidateUUID(field, value string) *FieldError {
	if _, err := uuid.Parse(value); err != nil {
		return &FieldError{
			Field:   field,
			Message: "must be a valid UUID",
		}
	}
	return nil
}

// FormatBindingErrors converts gin binding errors into structured FieldErrors.
func FormatBindingErrors(err error) []FieldError {
	var errors []FieldError

	errMsg := err.Error()

	// Parse gin's validation error messages
	// Format: "Key: 'StructName.Field' Error:Field validation for 'Field' failed on the 'tag' tag"
	parts := strings.Split(errMsg, "\n")
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}

		fe := FieldError{}

		// Extract field name
		if keyIdx := strings.Index(part, "Key: '"); keyIdx != -1 {
			endIdx := strings.Index(part[keyIdx+6:], "'")
			if endIdx != -1 {
				fullKey := part[keyIdx+6 : keyIdx+6+endIdx]
				// Get the last part after the dot
				dotParts := strings.Split(fullKey, ".")
				fe.Field = strings.ToLower(dotParts[len(dotParts)-1])
			}
		}

		// Extract tag for a human-readable message
		fe.Message = formatTagMessage(part)
		if fe.Field == "" {
			fe.Field = "unknown"
			fe.Message = part
		}

		errors = append(errors, fe)
	}

	if len(errors) == 0 {
		errors = append(errors, FieldError{
			Field:   "request",
			Message: errMsg,
		})
	}

	return errors
}

// formatTagMessage converts a gin binding error into a human-readable message.
func formatTagMessage(errStr string) string {
	tagMap := map[string]string{
		"'required'": "is required",
		"'email'":    "must be a valid email address",
		"'min'":      "is too short",
		"'max'":      "is too long",
		"'oneof'":    "must be one of the allowed values",
		"'uuid'":     "must be a valid UUID",
	}

	for tag, msg := range tagMap {
		if strings.Contains(errStr, tag) {
			// Try to extract min/max values
			if strings.Contains(errStr, "'min'") {
				return fmt.Sprintf("%s (minimum length not met)", msg)
			}
			if strings.Contains(errStr, "'max'") {
				return fmt.Sprintf("%s (maximum length exceeded)", msg)
			}
			return msg
		}
	}

	return "is invalid"
}
