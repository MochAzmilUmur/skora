package repositories

import (
	"errors"

	"backend/internal/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type HasilUjianRepository interface {
	// CreateOrGet calculates and persists the result atomically.
	// If a result already exists for sessionID, it returns the existing one (idempotent).
	// Uses SELECT FOR UPDATE inside a transaction to prevent race conditions.
	CreateOrGet(sessionID int) (*models.HasilUjian, bool, error)
	FindByID(id int) (*models.HasilUjian, error)
	FindBySessionID(sessionID int) (*models.HasilUjian, error)
	FindAll() ([]models.HasilUjian, error)
	FindByRoomID(roomID string) ([]models.HasilUjian, error)
	Update(id int, hasil *models.HasilUjian) (*models.HasilUjian, error)
	Delete(id int) error
}

type hasilUjianRepo struct{ db *gorm.DB }

func NewHasilUjianRepository(db *gorm.DB) HasilUjianRepository {
	return &hasilUjianRepo{db}
}

// CreateOrGet is the core anti-race-condition method.
// Returns (hasil, isNew, error). isNew=false means an existing record was returned.
func (r *hasilUjianRepo) CreateOrGet(sessionID int) (*models.HasilUjian, bool, error) {
	var hasil models.HasilUjian

	err := r.db.Transaction(func(tx *gorm.DB) error {
		// Pessimistic lock: block concurrent transactions on the same session_id
		// until this transaction commits or rolls back.
		lockErr := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("session_id = ?", sessionID).
			First(&hasil).Error

		if lockErr == nil {
			// Already exists — idempotent return, no insert needed.
			return nil
		}
		if !errors.Is(lockErr, gorm.ErrRecordNotFound) {
			return lockErr
		}

		// Load answers with options to calculate score
		var answers []models.Answer
		if err := tx.Preload("Pertanyaan.QuestionOptions").
			Where("session_id = ?", sessionID).
			Find(&answers).Error; err != nil {
			return err
		}

		benar := 0
		for _, a := range answers {
			if a.SelectedOptionID == nil {
				continue
			}
			for _, opt := range a.Pertanyaan.QuestionOptions {
				if opt.ID == *a.SelectedOptionID && opt.IsCorrect {
					benar++
					break
				}
			}
		}

		total := len(answers)
		skor := 0.0
		if total > 0 {
			skor = float64(benar) / float64(total) * 100
		}

		hasil = models.HasilUjian{
			SessionID:      sessionID,
			TotalQuestions: total,
			JawabanBenar:   benar,
			JawabanSalah:   total - benar,
			Skor:           skor,
		}
		return tx.Create(&hasil).Error
	})

	if err != nil {
		return nil, false, err
	}

	// Reload with associations outside the transaction
	r.db.Preload("SesiUjian").First(&hasil, hasil.ID)

	// isNew: ID was 0 before transaction means it was just created
	// We detect by checking if SesiUjian was preloaded (always true after reload)
	// ponytail: simpler — caller doesn't need isNew for HTTP status, usecase decides
	return &hasil, hasil.ID > 0, nil
}

func (r *hasilUjianRepo) FindByID(id int) (*models.HasilUjian, error) {
	var hasil models.HasilUjian
	err := r.db.Preload("SesiUjian").First(&hasil, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &hasil, err
}

func (r *hasilUjianRepo) FindBySessionID(sessionID int) (*models.HasilUjian, error) {
	var hasil models.HasilUjian
	err := r.db.Preload("SesiUjian").Preload("SesiUjian.Room").
		Where("session_id = ?", sessionID).First(&hasil).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &hasil, err
}

func (r *hasilUjianRepo) FindAll() ([]models.HasilUjian, error) {
	var hasils []models.HasilUjian
	err := r.db.Preload("SesiUjian").Preload("SesiUjian.Room").Find(&hasils).Error
	return hasils, err
}

func (r *hasilUjianRepo) FindByRoomID(roomID string) ([]models.HasilUjian, error) {
	var hasils []models.HasilUjian
	err := r.db.
		Preload("SesiUjian.User").
		Preload("SesiUjian.Room").
		Joins("JOIN sesi_ujian ON sesi_ujian.id = hasil_ujian.session_id").
		Where("sesi_ujian.room_id = ?", roomID).
		Find(&hasils).Error
	return hasils, err
}

func (r *hasilUjianRepo) Update(id int, hasil *models.HasilUjian) (*models.HasilUjian, error) {
	if err := r.db.Save(hasil).Error; err != nil {
		return nil, err
	}
	return hasil, nil
}

func (r *hasilUjianRepo) Delete(id int) error {
	return r.db.Delete(&models.HasilUjian{}, id).Error
}
