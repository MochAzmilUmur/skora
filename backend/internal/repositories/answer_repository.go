package repositories

import (
	"errors"
	"time"

	"backend/internal/models"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type AnswerRepository interface {
	// Upsert atomically inserts or updates an answer for (session_id, question_id).
	// Uses ON CONFLICT DO UPDATE — single round-trip, no race condition window.
	Upsert(answer *models.Answer) error
	FindByID(id int) (*models.Answer, error)
	FindBySession(sessionID int) ([]models.Answer, error)
	Update(id int, updates map[string]any) (*models.Answer, error)
	Delete(id int) error
}

type answerRepo struct{ db *gorm.DB }

func NewAnswerRepository(db *gorm.DB) AnswerRepository {
	return &answerRepo{db}
}

// Upsert uses PostgreSQL ON CONFLICT DO UPDATE to atomically insert or update.
// The UNIQUE constraint on (session_id, question_id) is the conflict target.
func (r *answerRepo) Upsert(answer *models.Answer) error {
	answer.AnsweredAt = time.Now()
	return r.db.Clauses(clause.OnConflict{
		Columns: []clause.Column{
			{Name: "session_id"},
			{Name: "question_id"},
		},
		DoUpdates: clause.AssignmentColumns([]string{
			"answer_text",
			"selected_option_id",
			"file_url",
			"answered_at",
		}),
	}).Create(answer).Error
}

func (r *answerRepo) FindByID(id int) (*models.Answer, error) {
	var answer models.Answer
	err := r.db.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption").
		First(&answer, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &answer, err
}

func (r *answerRepo) FindBySession(sessionID int) ([]models.Answer, error) {
	var answers []models.Answer
	err := r.db.Preload("SesiUjian").Preload("Pertanyaan").Preload("QuestionOption").
		Where("session_id = ?", sessionID).Find(&answers).Error
	return answers, err
}

func (r *answerRepo) Update(id int, updates map[string]any) (*models.Answer, error) {
	var answer models.Answer
	if err := r.db.First(&answer, id).Error; err != nil {
		return nil, err
	}
	if err := r.db.Model(&answer).Updates(updates).Error; err != nil {
		return nil, err
	}
	return &answer, nil
}

func (r *answerRepo) Delete(id int) error {
	return r.db.Delete(&models.Answer{}, id).Error
}
