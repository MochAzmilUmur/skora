package usecase

import (
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
)

// FeedbackUsecase menangani logika bisnis pengiriman feedback.
type FeedbackUsecase struct {
	db  *gorm.DB
	hub *socket.Hub
}

func NewFeedbackUsecase(db *gorm.DB, hub *socket.Hub) *FeedbackUsecase {
	return &FeedbackUsecase{db: db, hub: hub}
}

// SendFeedbackInput adalah input DTO dari REST handler.
type SendFeedbackInput struct {
	HasilID  int    `json:"hasil_id" binding:"required"`
	AsesorID int    `json:"asesor_id" binding:"required"`
	SenderID int    `json:"sender_id" binding:"required"`
	Komentar string `json:"komentar" binding:"required"`
}

// SendFeedbackResult adalah output DTO.
type SendFeedbackResult struct {
	Feedback    models.Feedback `json:"feedback"`
	Delivered   bool            `json:"delivered"` // true jika peserta sedang online
}

// wsPayload adalah struktur pesan yang dikirim ke WebSocket client.
type wsPayload struct {
	Type       string    `json:"type"`
	FeedbackID int       `json:"feedback_id"`
	HasilID    int       `json:"hasil_id"`
	AsesorID   int       `json:"asesor_id"`
	SenderID   int       `json:"sender_id"`
	Komentar   string    `json:"komentar"`
	CreatedAt  time.Time `json:"created_at"`
}

// Execute menyimpan feedback ke database lalu mengirimkannya secara real-time
// ke koneksi WebSocket peserta jika sedang aktif.
func (uc *FeedbackUsecase) Execute(input SendFeedbackInput) (*SendFeedbackResult, error) {
	// 1. Validasi HasilUjian dan ambil UserID peserta
	var hasil models.HasilUjian
	if err := uc.db.
		Preload("SesiUjian").
		First(&hasil, input.HasilID).Error; err != nil {
		return nil, fmt.Errorf("hasil ujian tidak ditemukan: %w", err)
	}

	pesertaID := hasil.SesiUjian.UserID

	// 2. Simpan feedback ke database
	feedback := models.Feedback{
		HasilID:   input.HasilID,
		AsesorID:  input.AsesorID,
		SenderID:  input.SenderID,
		Komentar:  input.Komentar,
		CreatedAt: time.Now(),
	}
	if err := uc.db.Create(&feedback).Error; err != nil {
		return nil, fmt.Errorf("gagal menyimpan feedback: %w", err)
	}

	// 3. Kirim real-time ke peserta via WebSocket jika sedang online
	payload := wsPayload{
		Type:       "feedback",
		FeedbackID: feedback.ID,
		HasilID:    feedback.HasilID,
		AsesorID:   feedback.AsesorID,
		SenderID:   feedback.SenderID,
		Komentar:   feedback.Komentar,
		CreatedAt:  feedback.CreatedAt,
	}
	msg, _ := json.Marshal(payload)

	// Kirim ke lawan bicara: jika sender adalah asesor → kirim ke peserta, dan sebaliknya
	targetID := pesertaID
	if input.SenderID == pesertaID {
		targetID = input.AsesorID
	}
	delivered := uc.hub.SendToUser(targetID, msg)

	return &SendFeedbackResult{
		Feedback:  feedback,
		Delivered: delivered,
	}, nil
}
