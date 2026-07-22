# 📊 Laporan Progress Pengembangan Aplikasi Skora
**Tanggal Update**: 22 Juli 2026  
**Versi Aplikasi**: 1.0.0+1  
**Status Keseluruhan**: 🟡 Dalam Pengembangan (±75% Selesai)

---

## 🏗️ Ringkasan Arsitektur

| Komponen | Teknologi | Status |
|---|---|---|
| Backend | Go (Gin Framework) | 🟡 Berjalan, auth & room lengkap, ujian terhubung |
| Database | PostgreSQL | ✅ Terhubung |
| Frontend | Flutter (Android) | 🟡 Berjalan, auth & room lengkap |
| Containerization | Docker & Docker Compose | ✅ Tersedia |
| Real-time | WebSocket (Gorilla) | 🟡 Infrastruktur ada, belum dipakai UI |
| Auth | JWT (SharedPreferences) | ✅ Berfungsi penuh |

---

## ✅ Fitur yang Sudah Selesai

### 🔐 Autentikasi
- [x] Halaman Login (menggunakan `animated_login`)
- [x] Halaman Signup dengan validasi email duplikat
- [x] **Password hashing dengan bcrypt** *(baru)*
- [x] **Endpoint `/api/auth/register` — hash password, simpan ke DB** *(baru)*
- [x] **Endpoint `/api/auth/login` — verifikasi bcrypt + issue JWT** *(baru)*
- [x] **JWT Token disimpan di SharedPreferences** *(baru)*
- [x] **Validasi password saat login** *(baru)*
- [x] **Logout — tombol di dashboard + clearUser()** *(baru)*
- [x] **Session timeout — cek expiry JWT, auto-redirect ke login** *(baru)*
- [x] **Forgot password — endpoint fungsional + generate reset token** *(baru)*
- [x] **Reset password — validasi token + update password hash** *(baru)*
- [x] Navigasi otomatis ke Dashboard setelah login berhasil
- [x] Tampilkan username dari database di Dashboard
- [x] **Splash router — cek session saat app start, auto-redirect** *(baru)*

### 🏠 Dashboard
- [x] Tampilan header dengan nama user yang login (dari database)
- [x] Quick Actions: tombol Create Room & Join Room
- [x] **Daftar "Your Exams" hanya milik user yang login** *(diperbaiki)*
- [x] Loading state & empty state
- [x] Auto-refresh setelah buat room baru
- [x] Navigasi ke detail room saat tap "Enter Room"
- [x] **Filter Active / History berfungsi** *(baru)*
- [x] **Tombol logout di header** *(baru)*
- [x] **Hapus room dari dashboard (popup konfirmasi)** *(baru)*
- [x] **Edit room dari dashboard (menu konteks)** *(baru)*
- [x] **Room code ditampilkan di card** *(baru)*

### 🏫 Manajemen Room
- [x] Form Create Exam Room (title, description, duration, start date, question types, shuffle)
- [x] **Semua field form dikirim ke backend (description, start_date, question_types, shuffle)** *(diperbaiki)*
- [x] Create Room terhubung ke API backend dan tersimpan ke database
- [x] **Edit room — form reuse dengan pre-fill data** *(baru)*
- [x] **Hapus room — konfirmasi dialog + API call** *(baru)*
- [x] **Room code unik di-generate di backend (format `XXX-XXX`)** *(diperbaiki)*
- [x] Halaman Detail Room (Exam Room Screen) dengan data dinamis per room
- [x] Tombol copy room code ke clipboard
- [x] Statistik room: durasi, jumlah soal, pass rate

### 📷 QR Code & Join Room
- [x] Generate QR Code unik per room (format `ROOM:{id}:{code}`)
- [x] Popup dialog tampilkan QR Code
- [x] QR Code Scanner menggunakan kamera device
- [x] Custom overlay scanner dengan corner borders
- [x] Flash toggle untuk kondisi gelap
- [x] **Join Room via scan QR — API call ke `/api/rooms/join`** *(baru)*
- [x] **Navigasi otomatis ke detail room setelah join berhasil** *(baru)*

### 🔒 Screen Protection
- [x] Library `screen_protector: ^1.5.1` terintegrasi
- [x] Blokir screenshot di Android (FLAG_SECURE)
- [x] Deteksi screenshot di iOS
- [x] Badge "Protected" di AppBar saat mode ujian aktif
- [x] Auto-enable saat masuk screen ujian, auto-disable saat keluar
- [x] Lifecycle management (re-enable saat app resume)

### 🌐 Backend API
- [x] CORS middleware (semua origin diizinkan)
- [x] **JWT middleware — proteksi semua endpoint kecuali auth** *(baru)*
- [x] **POST `/api/auth/register`** *(baru)*
- [x] **POST `/api/auth/login`** *(baru)*
- [x] **POST `/api/auth/forgot-password`** *(baru)*
- [x] **POST `/api/auth/reset-password`** *(baru)*
- [x] CRUD endpoint `/api/users`
- [x] CRUD endpoint `/api/rooms`
- [x] **GET `/api/rooms/user/:user_id` — rooms by user** *(baru)*
- [x] **GET `/api/rooms/code/:code` — room by code** *(baru)*
- [x] **POST `/api/rooms/join` — join room via kode** *(baru)*
- [x] **GET/POST `/api/rooms/:id/participants`** *(baru)*
- [x] **DELETE `/api/rooms/:id/participants/:participant_id`** *(baru)*
- [x] CRUD endpoint `/api/pertanyaans`
- [x] CRUD endpoint `/api/sesi-ujians`
- [x] CRUD endpoint `/api/answers`
- [x] CRUD endpoint `/api/hasil-ujians`
- [x] POST endpoint `/api/feedback`
- [x] WebSocket endpoint `/ws` dengan JWT auth
- [x] WebSocket Hub & Client (ping-pong heartbeat)

### 🔌 Koneksi Frontend–Backend
- [x] `ApiClient` dengan platform detection (device fisik vs emulator)
- [x] **`ApiClient` otomatis kirim `Authorization: Bearer <token>`** *(baru)*
- [x] `RoomRemoteDataSourceImpl` untuk CRUD room
- [x] **`RoomRemoteDataSourceImpl` — joinRoom, getRoomByCode, getRoomsByUser** *(baru)*
- [x] `RoomRepositoryImpl` dengan Either pattern (dartz)
- [x] Error handling dengan `ServerFailure`

---

## ❌ Fitur yang Belum Diimplementasikan

### 🔐 Autentikasi & Keamanan
- [ ] **Social login** — Google/Facebook/LinkedIn hanya simulasi

### 📝 Bank Soal (Pertanyaan)
- [ ] **UI tambah soal** — tidak ada halaman untuk membuat soal
- [ ] **UI edit soal** — tidak ada halaman untuk edit soal
- [ ] **UI hapus soal** — tidak ada halaman untuk hapus soal
- [ ] **Tampilkan daftar soal per room** — belum ada
- [ ] **Upload gambar untuk soal** — belum ada
- [ ] **Tipe soal Essay/Short Answer** — belum ada UI
- [ ] **Tipe soal File Upload** — belum ada UI
- [ ] **Tipe soal Coding** — belum ada UI
- [ ] **Import soal dari file (CSV/Excel)** — belum ada

### 🎓 Pelaksanaan Ujian *(Diimplementasikan 22 Juli 2026)*
- [x] **Load soal dari API** — `ExamSessionScreen` load dari `GET /rooms/:id/pertanyaans`
- [x] **Simpan jawaban ke API** — setiap pilih opsi/isi essay langsung POST ke `/answers` (fire-and-forget)
- [x] **Timer dari durasi room** — `durasiMenit` diambil dari `RoomModel.durasi`, bukan hardcoded
- [x] **Question Grid** — bottom sheet dengan grid 8-kolom, klik navigasi ke soal
- [x] **Bookmark soal** — toggle bookmark, soal ditandai kuning di grid
- [x] **Auto-submit saat waktu habis** — timer trigger `submitExam(isTimeout: true)` saat `remainingSeconds == 0`
- [x] **Navigasi soal dari grid** — tap nomor di Question Grid, tutup sheet, pindah soal
- [x] **Tampilkan soal dari database** — PertanyaanModel dari API, multiple choice + essay
- [x] **ExamSessionNotifier** — ChangeNotifier: state session, soal, jawaban, timer, bookmark, grid nav
- [x] **ExamResultScreen** — tampilkan skor, benar/salah, lulus/tidak lulus, kembali dashboard

### 🧮 Backend Penilaian *(Diimplementasikan 22 Juli 2026)*
- [x] **Auto-calculate hasil ujian** — `POST /api/hasil-ujians` otomatis hitung skor dari jawaban di DB
- [x] **Idempotent hasil** — duplicate session_id mengembalikan hasil yang sudah ada (tidak duplikat)
- [x] **Soft delete soal** — `Pertanyaan` model punya `deleted_at` (GORM), hapus tidak rusak referensi jawaban
- [x] **Pagination soal per room** — `GET /rooms/:id/pertanyaans?page=1&limit=20`
- [x] **Filter answers by session** — `GET /answers?session_id=X`
- [x] **Filter sesi by user** — `GET /sesi-ujians?user_id=X`
- [x] **Filter hasil by session** — `GET /hasil-ujians?session_id=X`
- [x] **End session sets end_time** — update status completed/timeout sekaligus isi `end_time`

### 📊 Penilaian & Hasil Ujian
- [x] **Penilaian otomatis** — `POST /hasil-ujians` hitung skor dari correct answers di DB *(baru)*
- [x] **Halaman hasil ujian** — `ExamResultScreen` tampilkan skor, benar/salah, lulus/tidak *(baru)*
- [ ] **Rekap nilai per peserta** — tidak ada
- [ ] **Export hasil ke PDF/Excel** — tidak ada
- [ ] **Grafik/statistik hasil** — tidak ada
- [ ] **Feedback dari asesor** — WebSocket ada tapi UI belum terhubung

### 👥 Manajemen Pengguna
- [ ] **Halaman profil user** — tab Profile di bottom nav belum berfungsi
- [ ] **Edit profil** — tidak ada
- [ ] **Ganti password** — tidak ada
- [ ] **Role management** — tidak ada pembeda UI antara asesor dan peserta
- [ ] **Daftar semua user (admin)** — tidak ada halaman admin

### 🔔 Notifikasi & Real-time
- [ ] **Notifikasi push** — tombol notifikasi di dashboard belum berfungsi
- [ ] **Real-time peserta masuk room** — WebSocket ada tapi UI tidak update
- [ ] **Real-time status ujian** — belum ada
- [ ] **Feedback real-time dari asesor** — infrastruktur WebSocket ada, UI belum

### 🎨 UI/UX
- [ ] **Halaman Results** — tab Results di bottom nav belum berfungsi
- [ ] **Halaman Exams** — tab Exams di bottom nav belum berfungsi
- [ ] **Splash screen** — tidak ada
- [ ] **Onboarding screen** — tidak ada
- [ ] **Dark/Light mode toggle** — hanya dark mode
- [ ] **Lokalisasi Bahasa Indonesia** — teks masih campuran Inggris-Indonesia
- [ ] **Responsive layout untuk tablet** — belum dioptimasi

### 🔧 Backend
- [x] **Soft delete soal** — `deleted_at` di tabel `pertanyaan`, riwayat jawaban aman *(baru)*
- [x] **Pagination soal** — `GET /rooms/:id/pertanyaans?page&limit` *(baru)*
- [x] **Filter query params** — answers by session, sesi by user, hasil by session *(baru)*
- [ ] **Input validation** — validasi input di handler masih minimal
- [ ] **Unit test** — tidak ada test di backend

### 🐛 Bug yang Diketahui
- [ ] **IP address hardcoded** — `192.168.1.19` hardcoded di `api_client.dart`
- [ ] **Participants di ExamRoomScreen masih dummy** — `_participantsCount = 12` hardcoded

---

## 📁 Struktur File Saat Ini

```
ujikompetensi/
├── backend/
│   ├── internal/
│   │   ├── handlers/          ✅ 8 handler (+ auth_handler baru)
│   │   ├── middleware/        ✅ jwt_middleware.go (baru)
│   │   ├── models/            ✅ Room model diupdate (description, start_date, dll)
│   │   ├── routes/            ✅ Auth routes + protected routes dengan JWT
│   │   ├── infrastructure/
│   │   │   └── socket/        ✅ Hub + Client WebSocket
│   │   ├── delivery/ws/       ✅ WebSocket handler dengan JWT
│   │   └── usecase/           ✅ FeedbackUsecase
│   └── main.go                ✅ Server + Hub berjalan
│
└── frontend/
    └── lib/
        ├── core/
        │   ├── network/        ✅ ApiClient (auto Bearer token) + UserService
        │   ├── services/       ✅ AuthStorageService (JWT + expiry) + ScreenProtectionService
        │   ├── widgets/        ✅ ProtectedScreen + DialogBuilder
        │   └── error/          ✅ Error screens
        └── features/
            ├── auth/           ✅ Login/Signup/JWT/Logout/ForgotPassword
            ├── dashboard/      ✅ Filter user/Active/History, Edit/Delete room, Logout
            ├── room/           🟡 Create/Edit/Delete/Join ✅, Participants UI ❌
            ├── ujian/          🔴 UI skeleton ✅, semua data dummy, API ❌
            └── feedback/       🔴 Repository ada, UI ❌
```

---

## 🗺️ Prioritas Pengembangan Selanjutnya

### 🔴 Prioritas Tinggi (Harus Segera)
1. ~~**UI tambah/edit/hapus soal** — asesor perlu bisa kelola soal per room~~ ✅ Selesai
2. ~~**Load soal dari API di ExamSessionScreen**~~ ✅ Selesai
3. ~~**Simpan jawaban ke API**~~ ✅ Selesai
4. ~~**Timer dari durasi room**~~ ✅ Selesai
5. **Participants di ExamRoomScreen dari API** — ganti data dummy

### 🟡 Prioritas Sedang
6. **Penilaian otomatis** — setelah ujian selesai
7. **Halaman hasil ujian** — peserta perlu lihat nilai
8. **Role management** — beda UI asesor vs peserta
9. **Halaman profil user**

### 🟢 Prioritas Rendah
10. **Notifikasi real-time** — WebSocket sudah ada, tinggal hubungkan ke UI
11. **Export hasil** — PDF/Excel
12. **Lokalisasi Bahasa Indonesia**
13. **Splash screen & onboarding**
14. **Pagination endpoint backend**

---

## 📦 Dependencies Frontend

| Package | Versi | Kegunaan | Status |
|---|---|---|---|
| `flutter` | SDK | Framework utama | ✅ |
| `animated_login` | ^1.6.0 | UI Login/Signup | ✅ Dipakai |
| `http` | ^1.2.0 | HTTP requests | ✅ Dipakai |
| `dartz` | ^0.10.1 | Either pattern | ✅ Dipakai |
| `get_it` | ^7.6.0 | Dependency injection | 🟡 Ada, belum dipakai penuh |
| `provider` | ^6.1.1 | State management | 🟡 Ada, belum dipakai |
| `equatable` | ^2.0.5 | Value equality | 🟡 Ada, belum dipakai |
| `qr_flutter` | ^4.1.0 | Generate QR Code | ✅ Dipakai |
| `mobile_scanner` | ^7.2.0 | Scan QR Code | ✅ Dipakai |
| `screen_protector` | ^1.5.1 | Proteksi screenshot | ✅ Dipakai |
| `shared_preferences` | ^2.5.5 | Simpan data lokal + JWT | ✅ Dipakai |

---

## 📦 Dependencies Backend

| Package | Kegunaan | Status |
|---|---|---|
| `gin` | HTTP framework | ✅ Dipakai |
| `gin-contrib/cors` | CORS middleware | ✅ Dipakai |
| `gorm` | ORM PostgreSQL | ✅ Dipakai |
| `gorilla/websocket` | WebSocket | ✅ Infrastruktur ada |
| `golang-jwt/jwt` | JWT auth | ✅ Auth handler + WS handler + middleware |
| `golang.org/x/crypto` | bcrypt password hash | ✅ Dipakai |
| `google/uuid` | UUID generation | ✅ Dipakai |
| `joho/godotenv` | Environment variables | ✅ Dipakai |

---

## 📈 Estimasi Progress per Modul

| Modul | Progress | Keterangan |
|---|---|---|
| Setup & Infrastruktur | 90% | Docker, DB, routing semua ada |
| Autentikasi | 90% | JWT, bcrypt, logout, session timeout ✅ |
| Dashboard | 85% | Filter user/Active/History, edit/delete ✅ |
| Manajemen Room | 80% | Create/Edit/Delete/Join/Participants backend ✅ |
| Bank Soal | 85% | Soft delete, pagination, CRUD UI + datasource impl ✅ |
| Pelaksanaan Ujian | 80% | Load soal, jawaban, timer, grid, bookmark, auto-submit ✅ |
| Penilaian & Hasil | 60% | Auto-calculate backend, ExamResultScreen ✅ |
| Feedback Real-time | 20% | Backend WebSocket ada, UI belum |
| Profil & Pengaturan | 0% | Belum dimulai |
| **Total Keseluruhan** | **~75%** | |

---

## 🔍 Catatan Teknis

### Hutang Teknis (Technical Debt)
1. `get_it` dan `provider` sudah di-install tapi belum dipakai untuk dependency injection
2. `injection_container.dart` ada tapi kosong
3. Tidak ada unit test sama sekali (frontend maupun backend)
4. IP address backend masih hardcoded di `api_client.dart`
5. Participants count di `ExamRoomScreen` masih hardcoded (`_participantsCount = 12`)

### Perubahan Database yang Diperlukan
Kolom baru di tabel `room` yang perlu di-migrate:
- `description TEXT`
- `start_date TIMESTAMP`
- `question_types VARCHAR(255)`
- `shuffle_questions BOOLEAN DEFAULT FALSE`
- `room_code VARCHAR(7) UNIQUE`

---

*Laporan ini di-update pada 22 Juli 2026 setelah sesi pengerjaan fitur pelaksanaan ujian (ExamSessionScreen) dan penilaian otomatis.*
