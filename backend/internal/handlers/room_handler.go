package handlers

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// RoomHandler handles room CRUD and participant endpoints.
type RoomHandler struct {
	DB  *gorm.DB
	Hub *socket.Hub
}

// NewRoomHandler creates a new RoomHandler.
func NewRoomHandler(db *gorm.DB, hub *socket.Hub) *RoomHandler {
	return &RoomHandler{DB: db, Hub: hub}
}

func generateRoomCode() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%03d-%03d", r.Intn(1000), r.Intn(1000))
}

// roomParticipantUserIDs returns all participant userIDs for a room (excluding the caller).
func (h *RoomHandler) roomParticipantUserIDs(roomID uuid.UUID, excludeUserID int) []int {
	var participants []models.RoomParticipant
	h.DB.Where("room_id = ?", roomID).Find(&participants)
	ids := make([]int, 0, len(participants))
	for _, p := range participants {
		if p.UserID != excludeUserID {
			ids = append(ids, p.UserID)
		}
	}
	return ids
}

// CreateRoom handles POST /api/rooms.
func (h *RoomHandler) CreateRoom(c *gin.Context) {
	var req validator.CreateRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	room := models.Room{
		IDRoom:      uuid.Must(uuid.NewV7()),
		RoomName:    req.RoomName,
		Description: req.Description,
		Durasi:      req.Durasi,
		RoomType:    req.RoomType,
		ShuffleQ:    req.ShuffleQ,
		CreatedBy:   req.CreatedBy,
		CreatedAt:   time.Now(),
	}

	// Parse start_date if provided
	if req.StartDate != "" {
		t, err := time.Parse(time.RFC3339, req.StartDate)
		if err != nil {
			validator.AbortWithValidationErrors(c, []validator.FieldError{
				{Field: "start_date", Message: "must be in RFC3339 format (e.g. 2026-01-01T00:00:00Z)"},
			})
			return
		}
		room.StartDate = &t
	}

	// Generate unique room code
	for {
		code := generateRoomCode()
		var existing models.Room
		if h.DB.Where("room_code = ?", code).First(&existing).Error != nil {
			room.RoomCode = code
			break
		}
	}

	if err := h.DB.Create(&room).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("User").First(&room, "id_room = ?", room.IDRoom)
	c.JSON(http.StatusCreated, room)
}

// GetRooms handles GET /api/rooms.
func (h *RoomHandler) GetRooms(c *gin.Context) {
	var rooms []models.Room
	if err := h.DB.Preload("User").Find(&rooms).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rooms)
}

// GetRoom handles GET /api/rooms/:id (by UUID).
func (h *RoomHandler) GetRoom(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room UUID"})
		return
	}

	var room models.Room
	if err := h.DB.Preload("User").First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}
	c.JSON(http.StatusOK, room)
}

// GetRoomsByUser handles GET /api/rooms/user/:user_id.
// Returns all rooms where the user is the creator OR a participant.
func (h *RoomHandler) GetRoomsByUser(c *gin.Context) {
	userID, err := strconv.Atoi(c.Param("user_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID: must be a number"})
		return
	}

	var rooms []models.Room
	if err := h.DB.Preload("User").
		Where(
			"id_room IN (SELECT room_id FROM room_participants WHERE user_id = ?) OR created_by = ?",
			userID, userID,
		).
		Find(&rooms).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rooms)
}

// GetRoomByCode handles GET /api/rooms/code/:code.
func (h *RoomHandler) GetRoomByCode(c *gin.Context) {
	code := c.Param("code")

	var room models.Room
	if err := h.DB.Preload("User").Where("room_code = ?", code).First(&room).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}
	c.JSON(http.StatusOK, room)
}

// UpdateRoom handles PUT /api/rooms/:id.
func (h *RoomHandler) UpdateRoom(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	var req validator.UpdateRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	updates := map[string]interface{}{}
	if req.RoomName != "" {
		updates["room_name"] = req.RoomName
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.Durasi > 0 {
		updates["durasi"] = req.Durasi
	}
	if req.RoomType != "" {
		updates["room_type"] = req.RoomType
	}
	if req.ShuffleQ != nil {
		updates["shuffle_questions"] = *req.ShuffleQ
	}
	if req.StartDate != "" {
		t, parseErr := time.Parse(time.RFC3339, req.StartDate)
		if parseErr != nil {
			validator.AbortWithValidationErrors(c, []validator.FieldError{
				{Field: "start_date", Message: "must be in RFC3339 format"},
			})
			return
		}
		updates["start_date"] = t
	}

	if len(updates) > 0 {
		if err := h.DB.Model(&room).Updates(updates).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	h.DB.Preload("User").First(&room, "id_room = ?", roomID)
	c.JSON(http.StatusOK, room)
}

// DeleteRoom handles DELETE /api/rooms/:id.
func (h *RoomHandler) DeleteRoom(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	// Verify room exists
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	if err := h.DB.Delete(&models.Room{}, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Room deleted successfully"})
}

// --- Participants ---

// GetParticipants handles GET /api/rooms/:id/participants.
func (h *RoomHandler) GetParticipants(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	var participants []models.RoomParticipant
	if err := h.DB.Preload("User").Where("room_id = ?", roomID).Find(&participants).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, participants)
}

// JoinRoom handles POST /api/rooms/join.
// Broadcasts "participant_joined" to the room creator via WebSocket.
func (h *RoomHandler) JoinRoom(c *gin.Context) {
	var req validator.JoinRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	if req.Role == "" {
		req.Role = "pelajar"
	}

	var room models.Room
	if err := h.DB.Preload("User").Where("room_code = ?", req.RoomCode).First(&room).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	// Check if already joined
	var existing models.RoomParticipant
	if h.DB.Where("room_id = ? AND user_id = ?", room.IDRoom, req.UserID).First(&existing).Error == nil {
		h.DB.Preload("User").First(&existing, existing.ID)
		c.JSON(http.StatusOK, gin.H{"message": "Already joined", "room": room, "participant": existing})
		return
	}

	participant := models.RoomParticipant{
		RoomID:   room.IDRoom,
		UserID:   req.UserID,
		Role:     req.Role,
		JoinedAt: time.Now(),
	}
	if err := h.DB.Create(&participant).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("User").First(&participant, participant.ID)

	// Real-time: notify room creator that a participant joined
	var joinerUser models.User
	h.DB.First(&joinerUser, req.UserID)
	go h.broadcastParticipantJoined(room, joinerUser)

	c.JSON(http.StatusCreated, gin.H{"room": room, "participant": participant})
}

func (h *RoomHandler) broadcastParticipantJoined(room models.Room, joiner models.User) {
	payload, _ := json.Marshal(map[string]any{
		"type":      "participant_joined",
		"room_id":   room.IDRoom.String(),
		"room_name": room.RoomName,
		"user_id":   joiner.IDUsers,
		"user_name": joiner.Nama,
		"joined_at": time.Now(),
	})
	// Notify room creator
	h.Hub.SendToUser(room.CreatedBy, payload)
}

// AddParticipant handles POST /api/rooms/:id/participants.
func (h *RoomHandler) AddParticipant(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	// Verify room exists
	var room models.Room
	if err := h.DB.First(&room, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	var req validator.AddParticipantRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}
	if req.Role == "" {
		req.Role = "pelajar"
	}

	// Verify user exists
	var user models.User
	if err := h.DB.First(&user, req.UserID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	participant := models.RoomParticipant{
		RoomID:   roomID,
		UserID:   req.UserID,
		Role:     req.Role,
		JoinedAt: time.Now(),
	}
	if err := h.DB.Create(&participant).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("User").First(&participant, participant.ID)
	c.JSON(http.StatusCreated, participant)
}

// RemoveParticipant handles DELETE /api/rooms/:id/participants/:participant_id.
func (h *RoomHandler) RemoveParticipant(c *gin.Context) {
	participantID, err := strconv.Atoi(c.Param("participant_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid participant ID: must be a number"})
		return
	}

	// Verify participant exists
	var participant models.RoomParticipant
	if err := h.DB.First(&participant, participantID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Participant not found"})
		return
	}

	if err := h.DB.Delete(&models.RoomParticipant{}, participantID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Participant removed"})
}
