package usecase

import (
	"encoding/json"
	"time"

	"backend/internal/apperrors"
	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/repositories"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CreateSesiInput struct {
	RoomID string
	UserID int
}

type UpdateSesiInput struct {
	ID     int
	Status string
}

type SesiUjianUsecase struct {
	repo repositories.SesiUjianRepository
	db   *gorm.DB // hanya untuk lookup Room & User saat validasi
	hub  *socket.Hub
}

func NewSesiUjianUsecase(repo repositories.SesiUjianRepository, db *gorm.DB, hub *socket.Hub) *SesiUjianUsecase {
	return &SesiUjianUsecase{repo: repo, db: db, hub: hub}
}

// Create is idempotent: if an ongoing session already exists for (roomID, userID),
// it returns that session instead of creating a duplicate.
func (uc *SesiUjianUsecase) Create(input CreateSesiInput) (*models.SesiUjian, error) {
	roomID, err := uuid.Parse(input.RoomID)
	if err != nil {
		return nil, apperrors.BadRequest("format room_id tidak valid")
	}

	// Verify room exists
	var room models.Room
	if err := uc.db.First(&room, "id_room = ?", roomID).Error; err != nil {
		return nil, apperrors.NotFound("room tidak ditemukan")
	}

	// Verify user exists
	var user models.User
	if err := uc.db.First(&user, input.UserID).Error; err != nil {
		return nil, apperrors.NotFound("user tidak ditemukan")
	}

	// Idempotency: return existing ongoing session without error
	existing, err := uc.repo.FindOngoing(roomID, input.UserID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	sesi := &models.SesiUjian{
		RoomID:    roomID,
		UserID:    input.UserID,
		StartTime: time.Now(),
		Status:    models.StatusOngoing,
	}
	if err := uc.repo.Create(sesi); err != nil {
		return nil, err
	}

	// Reload associations for broadcast
	uc.db.Preload("Room").Preload("User").First(sesi, sesi.ID)
	go uc.broadcastExamStarted(*sesi)

	return sesi, nil
}

func (uc *SesiUjianUsecase) GetByID(id int) (*models.SesiUjian, error) {
	sesi, err := uc.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if sesi == nil {
		return nil, apperrors.NotFound("sesi ujian tidak ditemukan")
	}
	return sesi, nil
}

func (uc *SesiUjianUsecase) GetAll(userID int) ([]models.SesiUjian, error) {
	if userID > 0 {
		return uc.repo.FindAllByUserID(userID)
	}
	// ponytail: reuse FindAllByUserID with 0 means all — handled in repo via conditional
	var all []models.SesiUjian
	err := uc.db.Preload("Room").Preload("User").Find(&all).Error
	return all, err
}

func (uc *SesiUjianUsecase) Update(input UpdateSesiInput) (*models.SesiUjian, error) {
	sesi, err := uc.repo.FindByID(input.ID)
	if err != nil {
		return nil, err
	}
	if sesi == nil {
		return nil, apperrors.NotFound("sesi ujian tidak ditemukan")
	}

	updates := map[string]any{"status": input.Status}
	return uc.repo.Update(input.ID, updates)
}

func (uc *SesiUjianUsecase) Delete(id int) error {
	sesi, err := uc.repo.FindByID(id)
	if err != nil {
		return err
	}
	if sesi == nil {
		return apperrors.NotFound("sesi ujian tidak ditemukan")
	}
	return uc.repo.Delete(id)
}

func (uc *SesiUjianUsecase) broadcastExamStarted(sesi models.SesiUjian) {
	payload, _ := json.Marshal(map[string]any{
		"type":       "exam_started",
		"session_id": sesi.ID,
		"room_id":    sesi.RoomID.String(),
		"room_name":  sesi.Room.RoomName,
		"user_id":    sesi.UserID,
		"user_name":  sesi.User.Nama,
		"started_at": sesi.StartTime,
	})
	uc.hub.SendToUser(sesi.Room.CreatedBy, payload)
}
