package handlers_test

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestUploadFile_Success(t *testing.T) {
	db := setupTestDB(t)
	r := setupRouter(db)
	user := createTestUser(t, db, "Test", "test@example.com", "pass1234")

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "test_image.png")
	if err != nil {
		t.Fatalf("failed to create form file: %v", err)
	}
	// Dummy PNG header bytes
	part.Write([]byte("\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", authHeader(user.IDUsers))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assertStatus(t, w, http.StatusCreated)
	result := parseJSON(t, w)
	assertJSONHasField(t, result, "file_url")
}

func TestUploadFile_InvalidExtension(t *testing.T) {
	db := setupTestDB(t)
	r := setupRouter(db)
	user := createTestUser(t, db, "Test", "test@example.com", "pass1234")

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, _ := writer.CreateFormFile("file", "script.sh")
	part.Write([]byte("#!/bin/bash\necho hello"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", authHeader(user.IDUsers))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assertStatus(t, w, http.StatusBadRequest)
}

func TestUploadFile_NoFile(t *testing.T) {
	db := setupTestDB(t)
	r := setupRouter(db)
	user := createTestUser(t, db, "Test", "test@example.com", "pass1234")

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", authHeader(user.IDUsers))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assertStatus(t, w, http.StatusBadRequest)
}
