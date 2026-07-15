package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	IDUsers      int       `json:"id_users" gorm:"primaryKey;autoIncrement;column:id_users"`
	Nama         string    `json:"nama" gorm:"column:nama"`
	Email        string    `json:"email" gorm:"column:email"`
	PasswordHash string    `json:"-" gorm:"column:password_hash"`
	CreatedAt    time.Time `json:"created_at" gorm:"column:created_at"`
}

func (User) TableName() string {
	return "users"
}

type Room struct {
	IDRoom        uuid.UUID  `json:"id_room" gorm:"primaryKey;type:uuid;column:id_room"`
	RoomName      string     `json:"room_name" gorm:"column:room_name"`
	Description   string     `json:"description" gorm:"column:description"`
	Durasi        int        `json:"durasi" gorm:"column:durasi"`
	StartDate     *time.Time `json:"start_date" gorm:"column:start_date"`
	QuestionTypes string     `json:"question_types" gorm:"column:question_types"`
	ShuffleQ      bool       `json:"shuffle_questions" gorm:"column:shuffle_questions"`
	RoomCode      string     `json:"room_code" gorm:"column:room_code;uniqueIndex"`
	CreatedBy     int        `json:"created_by" gorm:"column:created_by"`
	CreatedAt     time.Time  `json:"created_at" gorm:"column:created_at"`
	User          User       `json:"user" gorm:"foreignKey:CreatedBy;references:IDUsers"`
}

func (Room) TableName() string {
	return "room"
}

type RoomParticipant struct {
	ID       int       `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	RoomID   uuid.UUID `json:"room_id" gorm:"type:uuid;column:room_id"`
	UserID   int       `json:"user_id" gorm:"column:user_id"`
	Role     string    `json:"role" gorm:"column:role"`
	JoinedAt time.Time `json:"joined_at" gorm:"column:joined_at"`
	Room     Room      `json:"room" gorm:"foreignKey:RoomID;references:IDRoom"`
	User     User      `json:"user" gorm:"foreignKey:UserID;references:IDUsers"`
}

func (RoomParticipant) TableName() string {
	return "room_participants"
}

type Pertanyaan struct {
	ID              int              `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	RoomID          uuid.UUID        `json:"room_id" gorm:"type:uuid;column:room_id"`
	PertanyaanText  string           `json:"pertanyaan_text" gorm:"type:text;column:pertanyaan_text"`
	TypePertanyaan  string           `json:"type_pertanyaan" gorm:"type:enum('multiple_choice','text');column:type_pertanyaan"`
	CreatedAt       time.Time        `json:"created_at" gorm:"column:created_at"`
	DeletedAt       gorm.DeletedAt   `json:"deleted_at,omitempty" gorm:"index;column:deleted_at"`
	Room            Room             `json:"room,omitempty" gorm:"foreignKey:RoomID;references:IDRoom"`
	QuestionOptions []QuestionOption `json:"question_options" gorm:"foreignKey:QuestionID;references:ID"`
}

func (Pertanyaan) TableName() string {
	return "pertanyaan"
}

type QuestionOption struct {
	ID         int        `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	QuestionID int        `json:"question_id" gorm:"column:question_id"`
	OptionText string     `json:"option_text" gorm:"column:option_text"`
	IsCorrect  bool       `json:"is_correct" gorm:"column:is_correct"`
	Pertanyaan Pertanyaan `json:"pertanyaan" gorm:"foreignKey:QuestionID;references:ID"`
}

func (QuestionOption) TableName() string {
	return "question_options"
}

type SesiUjian struct {
	ID        int        `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	RoomID    uuid.UUID  `json:"room_id" gorm:"type:uuid;column:room_id"`
	UserID    int        `json:"user_id" gorm:"column:user_id"`
	StartTime time.Time  `json:"start_time" gorm:"column:start_time"`
	EndTime   *time.Time `json:"end_time" gorm:"column:end_time"`
	Status    string     `json:"status" gorm:"type:enum('ongoing','completed','timeout');column:status"`
	Room      Room       `json:"room" gorm:"foreignKey:RoomID;references:IDRoom"`
	User      User       `json:"user" gorm:"foreignKey:UserID;references:IDUsers"`
}

func (SesiUjian) TableName() string {
	return "sesi_ujian"
}

type Answer struct {
	ID               int             `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	SessionID        int             `json:"session_id" gorm:"column:session_id"`
	QuestionID       int             `json:"question_id" gorm:"column:question_id"`
	AnswerText       *string         `json:"answer_text" gorm:"type:text;column:answer_text"`
	SelectedOptionID *int            `json:"selected_option_id" gorm:"column:selected_option_id"`
	AnsweredAt       time.Time       `json:"answered_at" gorm:"column:answered_at"`
	SesiUjian        SesiUjian       `json:"sesi_ujian" gorm:"foreignKey:SessionID;references:ID"`
	Pertanyaan       Pertanyaan      `json:"pertanyaan" gorm:"foreignKey:QuestionID;references:ID"`
	QuestionOption   *QuestionOption `json:"question_option" gorm:"foreignKey:SelectedOptionID;references:ID"`
}

func (Answer) TableName() string {
	return "answers"
}

type HasilUjian struct {
	ID             int       `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	SessionID      int       `json:"session_id" gorm:"column:session_id"`
	TotalQuestions int       `json:"total_questions" gorm:"column:total_questions"`
	JawabanBenar   int       `json:"jawaban_benar" gorm:"column:jawaban_benar"`
	JawabanSalah   int       `json:"jawaban_salah" gorm:"column:jawaban_salah"`
	Skor           float64   `json:"skor" gorm:"column:skor"`
	SesiUjian      SesiUjian `json:"sesi_ujian" gorm:"foreignKey:SessionID;references:ID"`
}

func (HasilUjian) TableName() string {
	return "hasil_ujian"
}

type Feedback struct {
	ID         int        `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	HasilID    int        `json:"hasil_id" gorm:"column:hasil_id"`
	AsesorID   int        `json:"asesor_id" gorm:"column:asesor_id"`
	Komentar   string     `json:"komentar" gorm:"type:text;column:komentar"`
	CreatedAt  time.Time  `json:"created_at" gorm:"column:created_at"`
	HasilUjian HasilUjian `json:"hasil_ujian" gorm:"foreignKey:HasilID;references:ID"`
	Asesor     User       `json:"asesor" gorm:"foreignKey:AsesorID;references:IDUsers"`
}

func (Feedback) TableName() string {
	return "feedbacks"
}

type ActivityLog struct {
	ID           int       `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	SessionID    int       `json:"session_id" gorm:"column:session_id"`
	ActivityType string    `json:"activity_type" gorm:"column:activity_type"`
	ActivityTime time.Time `json:"activity_time" gorm:"column:activity_time"`
	SesiUjian    SesiUjian `json:"sesi_ujian" gorm:"foreignKey:SessionID;references:ID"`
}

func (ActivityLog) TableName() string {
	return "activity_logs"
}

type PasswordReset struct {
	ID        uuid.UUID  `json:"id" gorm:"primaryKey;type:uuid;column:id"`
	IDUsers   int        `json:"id_users" gorm:"not null;column:id_users"`
	Token     string     `json:"token" gorm:"type:char(64);not null;column:token;index"`
	ExpiredAt time.Time  `json:"expired_at" gorm:"not null;column:expired_at"`
	UsedAt    *time.Time `json:"used_at" gorm:"column:used_at"`
	CreatedAt time.Time  `json:"created_at" gorm:"default:now();column:created_at;index"`
	User      User       `json:"user" gorm:"foreignKey:IDUsers;references:IDUsers"`
}

func (PasswordReset) TableName() string {
	return "password_reset"
}
