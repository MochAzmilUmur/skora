package apperrors

import "errors"

// Sentinel errors — handler memetakan ini ke HTTP status code.
var (
	ErrNotFound   = errors.New("not found")
	ErrConflict   = errors.New("conflict")
	ErrBadRequest = errors.New("bad request")
)

// AppError membawa pesan yang aman untuk dikembalikan ke client.
type AppError struct {
	Code    error  // salah satu sentinel di atas
	Message string // pesan human-readable
}

func (e *AppError) Error() string { return e.Message }
func (e *AppError) Unwrap() error { return e.Code }

func NotFound(msg string) *AppError   { return &AppError{Code: ErrNotFound, Message: msg} }
func Conflict(msg string) *AppError   { return &AppError{Code: ErrConflict, Message: msg} }
func BadRequest(msg string) *AppError { return &AppError{Code: ErrBadRequest, Message: msg} }
