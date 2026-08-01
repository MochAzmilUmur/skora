package socket

import (
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second  // Batas waktu untuk write ke koneksi
	pongWait       = 60 * time.Second  // Batas waktu menunggu pong dari client
	pingPeriod     = (pongWait * 9) / 10 // Interval kirim ping (lebih pendek dari pongWait)
	maxMessageSize = 4096              // Batas ukuran pesan masuk (bytes)
)

// Client merepresentasikan satu koneksi WebSocket dari seorang user.
type Client struct {
	UserID int
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte // buffered channel untuk pesan keluar
}

func NewClient(userID int, hub *Hub, conn *websocket.Conn) *Client {
	return &Client{
		UserID: userID,
		hub:    hub,
		conn:   conn,
		send:   make(chan []byte, 256),
	}
}

// ReadPump membaca pesan dari koneksi WebSocket.
// Bertanggung jawab untuk menangani pong dan mendeteksi koneksi mati.
// Harus dijalankan sebagai goroutine.
func (c *Client) ReadPump() {
	defer func() {
		c.hub.Unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		// Reset deadline setiap kali pong diterima
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, _, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[WS] client %d disconnected unexpectedly: %v", c.UserID, err)
			}
			break
		}
		// Aplikasi ini server-push only: pesan dari client diabaikan
	}
}

// WritePump menulis pesan dari channel send ke koneksi WebSocket.
// Bertanggung jawab untuk mengirim ping secara berkala.
// Harus dijalankan sebagai goroutine.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Channel ditutup oleh Hub
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				log.Printf("[WS] write error for client %d: %v", c.UserID, err)
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("[WS] ping error for client %d: %v", c.UserID, err)
				return
			}
		}
	}
}

// close menutup channel send, yang akan memicu WritePump untuk berhenti.
func (c *Client) close() {
	close(c.send)
}
