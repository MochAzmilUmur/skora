package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"time"

	"backend/internal/infrastructure/socket"
	"backend/internal/models"
	"backend/internal/validator"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// UserHandler handles user CRUD endpoints.
type UserHandler struct {
	DB  *gorm.DB
	Hub *socket.Hub
}

// NewUserHandler creates a new UserHandler.
func NewUserHandler(db *gorm.DB, hub *socket.Hub) *UserHandler {
	return &UserHandler{DB: db, Hub: hub}
}

// CreateUser handles POST /api/users.
func (h *UserHandler) CreateUser(c *gin.Context) {
	var user models.User
	if err := c.ShouldBindJSON(&user); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	if err := h.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, user)
}

// GetUsers handles GET /api/users.
func (h *UserHandler) GetUsers(c *gin.Context) {
	var users []models.User
	if err := h.DB.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, users)
}

// GetUser handles GET /api/users/:id.
func (h *UserHandler) GetUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	var user models.User
	if err := h.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

// UpdateUser handles PUT /api/users/:id.
func (h *UserHandler) UpdateUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	// Only allow users to update their own profile
	callerID := c.GetInt("user_id")
	if callerID != id {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: you can only update your own profile"})
		return
	}

	var req validator.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	updates := map[string]interface{}{}
	if req.Nama != "" {
		updates["nama"] = req.Nama
	}
	if req.Email != "" {
		// Check email not taken by another user
		var existing models.User
		if err := h.DB.Where("email = ? AND id_users != ?", req.Email, id).First(&existing).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Email already taken"})
			return
		}
		updates["email"] = req.Email
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	if err := h.DB.Model(&models.User{}).Where("id_users = ?", id).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	h.DB.First(&user, id)
	c.JSON(http.StatusOK, user)
}

// ChangePassword handles POST /api/users/:id/change-password.
func (h *UserHandler) ChangePassword(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	callerID := c.GetInt("user_id")
	if callerID != id {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: you can only change your own password"})
		return
	}

	var req validator.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		validator.AbortWithValidationErrors(c, validator.FormatBindingErrors(err))
		return
	}

	var user models.User
	if err := h.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	h.DB.Model(&user).Update("password_hash", string(hash))
	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

// DeleteUser handles DELETE /api/users/:id.
func (h *UserHandler) DeleteUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID: must be a number"})
		return
	}

	// Verify user exists before deleting
	var user models.User
	if err := h.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if err := h.DB.Delete(&models.User{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User deleted successfully"})
}

// UpdateRole handles PUT /api/users/:id/role.
func (h *UserHandler) UpdateRole(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}
	var req struct {
		Role string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "role is required"})
		return
	}
	validRoles := map[string]bool{"asesor": true, "pelajar": true, "admin": true}
	if !validRoles[req.Role] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "role must be admin, asesor, or pelajar"})
		return
	}

	if err := h.DB.Model(&models.User{}).Where("id_users = ?", id).Update("role", req.Role).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	var user models.User
	h.DB.First(&user, id)

	// Broadcast role_changed ke user yang bersangkutan via WebSocket
	if h.Hub != nil {
		go func() {
			payload, _ := json.Marshal(map[string]any{
				"type":     "role_changed",
				"new_role": req.Role,
				"user_id":  id,
			})
			h.Hub.SendToUser(id, payload)
		}()
	}

	c.JSON(http.StatusOK, user)
}

// UploadAvatar handles POST /api/users/:id/avatar.
func (h *UserHandler) UploadAvatar(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}
	callerID := c.GetInt("user_id")
	if callerID != id {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden"})
		return
	}

	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "avatar file required"})
		return
	}
	defer file.Close()

	// Validate extension
	ext := filepath.Ext(header.Filename)
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true}
	if !allowed[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "only jpg/jpeg/png/webp allowed"})
		return
	}

	// Validate size ≤ 2 MB
	if header.Size > 2*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file too large (max 2 MB)"})
		return
	}

	filename := fmt.Sprintf("avatar_%d_%d%s", id, time.Now().UnixMilli(), ext)
	dst := "./storage/uploads/" + filename
	if err := c.SaveUploadedFile(header, dst); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save file"})
		return
	}

	avatarURL := "/uploads/" + filename
	if err := h.DB.Model(&models.User{}).Where("id_users = ?", id).Update("avatar_url", avatarURL).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	var user models.User
	h.DB.First(&user, id)
	c.JSON(http.StatusOK, user)
}
