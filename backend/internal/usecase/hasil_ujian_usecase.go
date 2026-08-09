package usecase

import (
	"backend/internal/apperrors"
	"backend/internal/models"
	"backend/internal/repositories"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CreateHasilInput struct {
	SessionID int
}

type HasilUjianUsecase struct {
	repo     repositories.HasilUjianRepository
	db       *gorm.DB // untuk validasi session & room
}

func NewHasilUjianUsecase(repo repositories.HasilUjianRepository, db *gorm.DB) *HasilUjianUsecase {
	return &HasilUjianUsecase{repo: repo, db: db}
}

// Create calculates and persists the exam result.
// Idempotent: returns existing result if already calculated for this session.
func (uc *HasilUjianUsecase) Create(input CreateHasilInput) (*models.HasilUjian, error) {
	// Verify session exists
	var sesi models.SesiUjian
	if err := uc.db.First(&sesi, input.SessionID).Error; err != nil {
		return nil, apperrors.NotFound("sesi ujian tidak ditemukan")
	}

	hasil, _, err := uc.repo.CreateOrGet(input.SessionID)
	return hasil, err
}

func (uc *HasilUjianUsecase) GetByID(id int) (*models.HasilUjian, error) {
	hasil, err := uc.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if hasil == nil {
		return nil, apperrors.NotFound("hasil ujian tidak ditemukan")
	}
	return hasil, nil
}

func (uc *HasilUjianUsecase) GetAll(sessionID int) (any, error) {
	if sessionID > 0 {
		hasil, err := uc.repo.FindBySessionID(sessionID)
		if err != nil {
			return nil, err
		}
		if hasil == nil {
			return nil, apperrors.NotFound("hasil ujian tidak ditemukan")
		}
		return hasil, nil
	}
	return uc.repo.FindAll()
}

func (uc *HasilUjianUsecase) GetByRoom(roomIDStr string) ([]models.HasilUjian, error) {
	if _, err := uuid.Parse(roomIDStr); err != nil {
		return nil, apperrors.BadRequest("format room_id tidak valid")
	}
	var room models.Room
	if err := uc.db.First(&room, "id_room = ?", roomIDStr).Error; err != nil {
		return nil, apperrors.NotFound("room tidak ditemukan")
	}
	return uc.repo.FindByRoomID(roomIDStr)
}

func (uc *HasilUjianUsecase) Update(id int, hasil *models.HasilUjian) (*models.HasilUjian, error) {
	existing, err := uc.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, apperrors.NotFound("hasil ujian tidak ditemukan")
	}
	hasil.ID = id
	return uc.repo.Update(id, hasil)
}

func (uc *HasilUjianUsecase) Delete(id int) error {
	existing, err := uc.repo.FindByID(id)
	if err != nil {
		return err
	}
	if existing == nil {
		return apperrors.NotFound("hasil ujian tidak ditemukan")
	}
	return uc.repo.Delete(id)
}
