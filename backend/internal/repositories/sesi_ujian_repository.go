package repositories

import (
	"errors"
	"time"

	"backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SesiUjianRepository interface {
	FindOngoing(roomID uuid.UUID, userID int) (*models.SesiUjian, error)
	FindByID(id int) (*models.SesiUjian, error)
	FindAllByUserID(userID int) ([]models.SesiUjian, error)
	Create(sesi *models.SesiUjian) error
	Update(id int, updates map[string]any) (*models.SesiUjian, error)
	Delete(id int) error
}

type sesiUjianRepo struct{ db *gorm.DB }

func NewSesiUjianRepository(db *gorm.DB) SesiUjianRepository {
	return &sesiUjianRepo{db}
}

// FindOngoing returns the active (ongoing) session for a user in a room, if any.
func (r *sesiUjianRepo) FindOngoing(roomID uuid.UUID, userID int) (*models.SesiUjian, error) {
	var sesi models.SesiUjian
	err := r.db.Preload("Room").Preload("User").
		Where("room_id = ? AND user_id = ? AND status = ?", roomID, userID, models.StatusOngoing).
		First(&sesi).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil // tidak ada sesi aktif — bukan error
	}
	return &sesi, err
}

func (r *sesiUjianRepo) FindByID(id int) (*models.SesiUjian, error) {
	var sesi models.SesiUjian
	err := r.db.Preload("Room").Preload("User").First(&sesi, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &sesi, err
}

func (r *sesiUjianRepo) FindAllByUserID(userID int) ([]models.SesiUjian, error) {
	var sesis []models.SesiUjian
	err := r.db.Preload("Room").Preload("User").Where("user_id = ?", userID).Find(&sesis).Error
	return sesis, err
}

func (r *sesiUjianRepo) Create(sesi *models.SesiUjian) error {
	return r.db.Create(sesi).Error
}

func (r *sesiUjianRepo) Update(id int, updates map[string]any) (*models.SesiUjian, error) {
	var sesi models.SesiUjian
	if err := r.db.First(&sesi, id).Error; err != nil {
		return nil, err
	}
	if err := r.db.Model(&sesi).Updates(updates).Error; err != nil {
		return nil, err
	}
	// Mark participant completed when session ends
	if status, ok := updates["status"].(string); ok &&
		(status == models.StatusCompleted || status == models.StatusTimeout) {
		r.db.Model(&models.RoomParticipant{}).
			Where("room_id = ? AND user_id = ? AND status = 'active'", sesi.RoomID, sesi.UserID).
			Update("status", "completed")
		now := time.Now()
		updates["end_time"] = now
		r.db.Model(&sesi).Update("end_time", now)
	}
	r.db.Preload("Room").Preload("User").First(&sesi, id)
	return &sesi, nil
}

func (r *sesiUjianRepo) Delete(id int) error {
	return r.db.Delete(&models.SesiUjian{}, id).Error
}
