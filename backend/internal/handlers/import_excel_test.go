package handlers_test

import (
	"bytes"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/xuri/excelize/v2"
)

func TestImportExcel_Success(t *testing.T) {
	db := setupTestDB(t)
	r := setupRouter(db)
	user := createTestUser(t, db, "Asesor", "asesor@example.com", "pass1234")
	room := createTestRoom(t, db, user.IDUsers)

	// Create an in-memory Excel file using excelize
	f := excelize.NewFile()
	sheetName := f.GetSheetName(0)

	// Headers
	f.SetCellValue(sheetName, "A1", "Pertanyaan")
	f.SetCellValue(sheetName, "B1", "Tipe")
	f.SetCellValue(sheetName, "C1", "Opsi A")
	f.SetCellValue(sheetName, "D1", "Opsi B")
	f.SetCellValue(sheetName, "E1", "Opsi C")
	f.SetCellValue(sheetName, "F1", "Opsi D")
	f.SetCellValue(sheetName, "G1", "Jawaban Benar")

	// Row 2: MC Question
	f.SetCellValue(sheetName, "A2", "Berapa 2 + 2?")
	f.SetCellValue(sheetName, "B2", "multiple_choice")
	f.SetCellValue(sheetName, "C2", "3")
	f.SetCellValue(sheetName, "D2", "4")
	f.SetCellValue(sheetName, "E2", "5")
	f.SetCellValue(sheetName, "F2", "6")
	f.SetCellValue(sheetName, "G2", "B")

	// Row 3: Essay Question
	f.SetCellValue(sheetName, "A3", "Jelaskan tentang Fotosintesis!")
	f.SetCellValue(sheetName, "B3", "text")

	buf, err := f.WriteToBuffer()
	if err != nil {
		t.Fatalf("failed to write excel buffer: %v", err)
	}

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "questions.xlsx")
	if err != nil {
		t.Fatalf("failed to create form file: %v", err)
	}
	part.Write(buf.Bytes())
	writer.Close()

	reqPath := fmt.Sprintf("/api/rooms/%s/import-excel", room.IDRoom.String())
	req := httptest.NewRequest(http.MethodPost, reqPath, body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", authHeader(user.IDUsers))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assertStatus(t, w, http.StatusCreated)
	result := parseJSON(t, w)
	assertJSONHasField(t, result, "total_imported")

	if count, ok := result["total_imported"].(float64); !ok || count != 2 {
		t.Errorf("expected total_imported to be 2, got %v", result["total_imported"])
	}
}

func TestImportExcel_RoomNotFound(t *testing.T) {
	db := setupTestDB(t)
	r := setupRouter(db)
	user := createTestUser(t, db, "Asesor", "asesor@example.com", "pass1234")

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	writer.Close()

	reqPath := "/api/rooms/00000000-0000-0000-0000-000000000000/import-excel"
	req := httptest.NewRequest(http.MethodPost, reqPath, body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", authHeader(user.IDUsers))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assertStatus(t, w, http.StatusNotFound)
}
