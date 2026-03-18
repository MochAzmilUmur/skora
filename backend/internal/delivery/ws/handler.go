package ws

import (
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"

	"backend/internal/infrastructure/socket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// CheckOrigin memvalidasi origin request untuk mencegah CSRF via WebSocket
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		allowed := os.Getenv("WS_ALLOWED_ORIGIN")
		if allowed == "" {
			// Fallback development: izinkan semua (jangan di production tanpa WS_ALLOWED_ORIGIN)
			return true
		}
		return origin == allowed
	},
}

// Handler menangani upgrade HTTP ke WebSocket.
// JWT divalidasi dari query param ?token=... sebelum upgrade dilakukan,
// sehingga header Authorization tidak bisa dipakai (limitasi WebSocket browser).
func Handler(hub *socket.Hub) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, err := authenticateWS(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized: " + err.Error()})
			return
		}

		conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			// Upgrader sudah menulis error response ke client
			return
		}

		client := socket.NewClient(userID, hub, conn)
		hub.Register <- client

		// Jalankan pump sebagai goroutine terpisah
		go client.WritePump()
		go client.ReadPump()
	}
}

// authenticateWS memvalidasi JWT dari query param ?token=...
// Mengembalikan userID dari claims jika valid.
func authenticateWS(c *gin.Context) (int, error) {
	tokenStr := c.Query("token")
	if tokenStr == "" {
		return 0, jwt.ErrTokenMalformed
	}

	secret := os.Getenv("JWT_SECRET")
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return 0, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return 0, jwt.ErrTokenInvalidClaims
	}

	// Ekspektasi claim "user_id" bertipe float64 (standar JSON number)
	rawID, ok := claims["user_id"]
	if !ok {
		return 0, jwt.ErrTokenInvalidClaims
	}

	switch v := rawID.(type) {
	case float64:
		return int(v), nil
	case string:
		id, err := strconv.Atoi(v)
		if err != nil {
			return 0, jwt.ErrTokenInvalidClaims
		}
		return id, nil
	default:
		return 0, jwt.ErrTokenInvalidClaims
	}
}
