package usecase

import (
	"backend/internal/apperrors"
	"backend/internal/models"
	"backend/internal/repositories"

	"gorm.io/gorm"
)

type UpsertAnswerInput struct {
	SessionID        int
	QuestionID       int
	AnswerText       *string
	SelectedOptionID *int
	FileURL          *string
}

type AnswerUsecase struct {
	repo repositories.AnswerRepository
	db   *gorm.DB
}

func NewAnswerUsecase(repo repositories.AnswerRepository, db *gorm.DB) *AnswerUsecase {
	return &AnswerUsecase{repo: repo, db: db}
}

// Upsert validates business rules then delegates atomic upsert to repository.
func (uc *AnswerUsecase) Upsert(input UpsertAnswerInput) (*models.Answer, error) {
	var sesi models.SesiUjian
	if err := uc.db.First(&sesi, input.SessionID).Error; err != nil {
		return nil, apperrors.NotFound("sesi ujian tidak ditemukan")
	}

	var pertanyaan models.Pertanyaan
	if err := uc.db.First(&pertanyaan, input.QuestionID).Error; err != nil {
		return nil, apperrors.NotFound("pertanyaan tidak ditemukan")
	}

	switch pertanyaan.TypePertanyaan {
	case models.TypePertanyaanMultipleChoice:
		if input.SelectedOptionID == nil {
			return nil, apperrors.BadRequest("selected_option_id wajib diisi untuk soal pilihan ganda")
		}
		var option models.QuestionOption
		if err := uc.db.First(&option, *input.SelectedOptionID).Error; err != nil {
			return nil, apperrors.NotFound("pilihan jawaban tidak ditemukan")
		}
		if option.QuestionID != input.QuestionID {
			return nil, apperrors.BadRequest("pilihan jawaban tidak sesuai dengan pertanyaan ini")
		}
	case models.TypePertanyaanText:
		if input.AnswerText == nil || *input.AnswerText == "" {
			return nil, apperrors.BadRequest("answer_text wajib diisi untuk soal essay")
		}
	case models.TypePertanyaanFileUpload:
		if input.FileURL == nil || *input.FileURL == "" {
			return nil, apperrors.BadRequest("file_url wajib diisi untuk soal upload file")
		}
	}

	answer := &models.Answer{
		SessionID:        input.SessionID,
		QuestionID:       input.QuestionID,
		AnswerText:       input.AnswerText,
		SelectedOptionID: input.SelectedOptionID,
		FileURL:          input.FileURL,
	}
	if err := uc.repo.Upsert(answer); err != nil {
		return nil, err
	}
	return answer, nil
}

func (uc *AnswerUsecase) GetByID(id int) (*models.Answer, error) {
	answer, err := uc.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if answer == nil {
		return nil, apperrors.NotFound("jawaban tidak ditemukan")
	}
	return answer, nil
}

func (uc *AnswerUsecase) GetBySession(sessionID int) ([]models.Answer, error) {
	return uc.repo.FindBySession(sessionID)
}

func (uc *AnswerUsecase) Update(id int, updates map[string]any) (*models.Answer, error) {
	answer, err := uc.repo.FindByID(id)
	if err != nil {
		return nil, err
	}
	if answer == nil {
		return nil, apperrors.NotFound("jawaban tidak ditemukan")
	}
	if optID, ok := updates["selected_option_id"].(*int); ok && optID != nil {
		var option models.QuestionOption
		if err := uc.db.First(&option, *optID).Error; err != nil {
			return nil, apperrors.NotFound("pilihan jawaban tidak ditemukan")
		}
		if option.QuestionID != answer.QuestionID {
			return nil, apperrors.BadRequest("pilihan jawaban tidak sesuai dengan pertanyaan ini")
		}
	}
	return uc.repo.Update(id, updates)
}

func (uc *AnswerUsecase) Delete(id int) error {
	answer, err := uc.repo.FindByID(id)
	if err != nil {
		return err
	}
	if answer == nil {
		return apperrors.NotFound("jawaban tidak ditemukan")
	}
	return uc.repo.Delete(id)
}
