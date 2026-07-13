package handlers

import (
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"time"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RoomHandler struct {
	DB *gorm.DB
}

func NewRoomHandler(db *gorm.DB) *RoomHandler {
	return &RoomHandler{DB: db}
}

func generateRoomCode() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%03d-%03d", r.Intn(1000), r.Intn(1000))
}

func (h *RoomHandler) CreateRoom(c *gin.Context) {
	var room models.Room
	if err := c.ShouldBindJSON(&room); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	room.IDRoom = uuid.Must(uuid.NewV7())
	room.CreatedAt = time.Now()

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

func (h *RoomHandler) GetRooms(c *gin.Context) {
	var rooms []models.Room
	if err := h.DB.Preload("User").Find(&rooms).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rooms)
}

// GetRoom — GET /api/rooms/:id (by UUID)
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

// GetRoomsByUser — GET /api/rooms/user/:user_id
func (h *RoomHandler) GetRoomsByUser(c *gin.Context) {
	userID, err := strconv.Atoi(c.Param("user_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var rooms []models.Room
	if err := h.DB.Preload("User").Where("created_by = ?", userID).Find(&rooms).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, rooms)
}

// GetRoomByCode — GET /api/rooms/code/:code
func (h *RoomHandler) GetRoomByCode(c *gin.Context) {
	code := c.Param("code")

	var room models.Room
	if err := h.DB.Preload("User").Where("room_code = ?", code).First(&room).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}
	c.JSON(http.StatusOK, room)
}

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

	if err := c.ShouldBindJSON(&room); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Jangan overwrite room_code dan created_at
	room.IDRoom = roomID
	if err := h.DB.Save(&room).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	h.DB.Preload("User").First(&room, "id_room = ?", roomID)
	c.JSON(http.StatusOK, room)
}

func (h *RoomHandler) DeleteRoom(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	if err := h.DB.Delete(&models.Room{}, "id_room = ?", roomID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Room deleted successfully"})
}

// --- Participants ---

// GetParticipants — GET /api/rooms/:id/participants
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

// JoinRoom — POST /api/rooms/join
func (h *RoomHandler) JoinRoom(c *gin.Context) {
	var req struct {
		RoomCode string `json:"room_code" binding:"required"`
		UserID   int    `json:"user_id" binding:"required"`
		Role     string `json:"role"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Role == "" {
		req.Role = "pelajar"
	}

	var room models.Room
	if err := h.DB.Where("room_code = ?", req.RoomCode).First(&room).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	// Cek sudah join sebelumnya
	var existing models.RoomParticipant
	if h.DB.Where("room_id = ? AND user_id = ?", room.IDRoom, req.UserID).First(&existing).Error == nil {
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
	c.JSON(http.StatusCreated, gin.H{"room": room, "participant": participant})
}

// AddParticipant — POST /api/rooms/:id/participants
func (h *RoomHandler) AddParticipant(c *gin.Context) {
	id := c.Param("id")
	roomID, err := uuid.Parse(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID"})
		return
	}

	var req struct {
		UserID int    `json:"user_id" binding:"required"`
		Role   string `json:"role"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Role == "" {
		req.Role = "pelajar"
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

// RemoveParticipant — DELETE /api/rooms/:id/participants/:participant_id
func (h *RoomHandler) RemoveParticipant(c *gin.Context) {
	participantID, err := strconv.Atoi(c.Param("participant_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid participant ID"})
		return
	}

	if err := h.DB.Delete(&models.RoomParticipant{}, participantID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Participant removed"})
}
