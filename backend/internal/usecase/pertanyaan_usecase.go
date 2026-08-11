package usecase

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"math/rand"

	"github.com/google/uuid"
	"backend/internal/models"
)

type PertanyaanUseCase interface {
	ShufflePertanyaans(roomID uuid.UUID, participantID int, questions []models.Pertanyaan) []models.Pertanyaan
}

type pertanyaanUseCase struct {
}

func NewPertanyaanUseCase() PertanyaanUseCase {
	return &pertanyaanUseCase{}
}

// ShufflePertanyaans shuffles questions deterministically.
func (u *pertanyaanUseCase) ShufflePertanyaans(roomID uuid.UUID, participantID int, questions []models.Pertanyaan) []models.Pertanyaan {
	if len(questions) == 0 {
		return questions
	}
	
	// Mekanisme Deterministic Random Seeding
	// Kita gabungkan roomID dan participantID menjadi satu string unik.
	// Kombinasi ini memastikan bahwa untuk Room dan Peserta yang sama, seed-nya akan selalu identik.
	uniqueString := fmt.Sprintf("R-%s-P-%d", roomID.String(), participantID)

	// Hash string unik tersebut menggunakan SHA-256 untuk mendapatkan distribusi bit yang merata dan menghindari collision.
	hash := sha256.Sum256([]byte(uniqueString))

	// Konversi 8 byte pertama dari hasil hash menjadi integer (int64) untuk digunakan sebagai seed.
	// Binary.BigEndian mengonversi array byte ke uint64 dengan aman.
	seed := int64(binary.BigEndian.Uint64(hash[:8]))

	// Inisialisasi local random generator (agar tidak mengganggu global seed math/rand)
	// Seed ini statis untuk tiap kombinasi Room dan Participant.
	r := rand.New(rand.NewSource(seed))

	// Lakukan pengacakan dengan algoritma Fisher-Yates (bawaan rand.Shuffle Go)
	// r.Shuffle akan mengacak urutan slice `questions` secara in-place.
	shuffled := make([]models.Pertanyaan, len(questions))
	copy(shuffled, questions)
	
	r.Shuffle(len(shuffled), func(i, j int) {
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	})

	return shuffled
}
