package socket

import "sync"

// Hub adalah central registry untuk semua koneksi WebSocket aktif.
// Menggunakan sync.RWMutex untuk thread-safe read/write pada map clients.
type Hub struct {
	// clients menyimpan map[userID]*Client, satu user bisa punya satu koneksi aktif
	clients map[int]*Client
	mu      sync.RWMutex

	// channels untuk operasi register/unregister agar aman dari race condition
	Register   chan *Client
	Unregister chan *Client
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[int]*Client),
		Register:   make(chan *Client, 16),
		Unregister: make(chan *Client, 16),
	}
}

// Run menjalankan event loop Hub. Harus dipanggil sebagai goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			// Jika user sudah punya koneksi lama, tutup dulu
			if old, ok := h.clients[client.UserID]; ok {
				old.close()
			}
			h.clients[client.UserID] = client
			h.mu.Unlock()

		case client := <-h.Unregister:
			h.mu.Lock()
			if existing, ok := h.clients[client.UserID]; ok && existing == client {
				delete(h.clients, client.UserID)
			}
			h.mu.Unlock()
		}
	}
}

// SendToUser mengirim pesan ke koneksi WebSocket milik userID tertentu.
// Mengembalikan false jika user tidak sedang terhubung.
func (h *Hub) SendToUser(userID int, message []byte) bool {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return false
	}

	select {
	case client.send <- message:
		return true
	default:
		// Buffer penuh, koneksi dianggap lambat/mati
		go func() { h.Unregister <- client }()
		return false
	}
}

// IsOnline mengecek apakah user sedang terhubung.
func (h *Hub) IsOnline(userID int) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}
