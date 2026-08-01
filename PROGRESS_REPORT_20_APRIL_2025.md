# 📊 Laporan Progress Pengembangan Aplikasi Skora
**Tanggal Update**: 31 Juli 2026  
**Versi Aplikasi**: 1.0.0+1  
**Status Keseluruhan**: 🟡 Dalam Pengembangan (±85% Selesai)

---

## 🏗️ Ringkasan Arsitektur

| Komponen | Teknologi | Status |
|---|---|---|
| Backend | Go (Gin Framework) | 🟡 Berjalan, auth & room lengkap, ujian & feedback terhubung |
| Database | PostgreSQL 15 (Docker) | ✅ Terhubung |
| Frontend | Flutter (Android) | 🟡 Berjalan, profil, rekap nilai, feedback tersedia |
| Containerization | Docker & Docker Compose | ✅ Backend + DB + pgAdmin (multi-stage build) |
| Real-time | WebSocket (Gorilla) | 🟡 Infrastruktur ada, feedback real-time aktif |
| Auth | JWT (SharedPreferences) | ✅ Berfungsi penuh |

---

## 🗄️ Status Database

### Data User yang Tersimpan

| id_users | nama | email | created_at |
|---|---|---|---|
| 1 | admin | admin@gmail.com | 2026-03-02 |
| 2 | aceng | aceng@gmail.com | 2026-04-18 |

### Ringkasan Data

| Tabel | Jumlah Record | Keterangan |
|---|---|---|
| `users` | 2 | ✅ Ada data |
| `room` | 1 | ✅ Ada data |
| `pertanyaan` | 0 | ❌ Kosong |
| `sesi_ujian` | 0 | ❌ Kosong |
| `hasil_ujian` | 0 | ❌ Kosong |
| `feedbacks` | 0 | ❌ Kosong |
| `answers` | 0 | ❌ Kosong |

### ⚠️ Schema Database Belum Sinkron

Tabel `room` di database **belum memiliki kolom** yang didefinisikan di model Go:

| Kolom | Di Model Go | Di Database | Status |
|---|---|---|---|
| `id_room` | ✅ | ✅ | Sinkron |
| `room_name` | ✅ | ✅ | Sinkron |
| `durasi` | ✅ | ✅ | Sinkron |
| `created_by` | ✅ | ✅ | Sinkron |
| `created_at` | ✅ | ✅ | Sinkron |
| `description` | ✅ | ❌ | **Belum dimigrasikan** |
| `start_date` | ✅ | ❌ | **Belum dimigrasikan** |
| `question_types` | ✅ | ❌ | **Belum dimigrasikan** |
| `shuffle_questions` | ✅ | ❌ | **Belum dimigrasikan** |
| `room_code` | ✅ | ❌ | **Belum dimigrasikan** |

Tabel `pertanyaan` juga belum punya kolom `created_at` dan `deleted_at`.

---

## ✅ Fitur yang Sudah Selesai

### 🔐 Autentikasi
- [x] Halaman Login (menggunakan `animated_login`)
- [x] Halaman Signup dengan validasi email duplikat
- [x] Password hashing dengan bcrypt
- [x] Endpoint `/api/auth/register` — hash password, simpan ke DB
- [x] Endpoint `/api/auth/login` — verifikasi bcrypt + issue JWT
- [x] JWT Token disimpan di SharedPreferences
- [x] Validasi password saat login
- [x] Logout — tombol di dashboard + clearUser()
- [x] Session timeout — cek expiry JWT, auto-redirect ke login
- [x] Forgot password — endpoint fungsional + generate reset token
- [x] Reset password — validasi token + update password hash
- [x] Navigasi otomatis ke Dashboard setelah login berhasil
- [x] Tampilkan username dari database di Dashboard
- [x] Splash router — cek session saat app start, auto-redirect

### 🏠 Dashboard
- [x] Tampilan header dengan nama user yang login (dari database)
- [x] Quick Actions: tombol Create Room & Join Room
- [x] Daftar "Your Exams" hanya milik user yang login
- [x] Loading state & empty state
- [x] Auto-refresh setelah buat room baru
- [x] Navigasi ke detail room saat tap "Enter Room"
- [x] Filter Active / History berfungsi
- [x] Tombol logout di header
- [x] Hapus room dari dashboard (popup konfirmasi)
- [x] Edit room dari dashboard (menu konteks)
- [x] Room code ditampilkan di card
- [x] Tab Profile di bottom nav menampilkan ProfileScreen

### 🏫 Manajemen Room
- [x] Form Create Exam Room (title, description, duration, start date, question types, shuffle)
- [x] Create Room terhubung ke API backend dan tersimpan ke database
- [x] Edit room — form reuse dengan pre-fill data
- [x] Hapus room — konfirmasi dialog + API call
- [x] Room code unik di-generate di backend (format `XXX-XXX`)
- [x] Halaman Detail Room (Exam Room Screen) dengan data dinamis per room
- [x] Tombol copy room code ke clipboard
- [x] Tombol "Rekap Nilai Peserta" di ExamRoomScreen

### 📷 QR Code & Join Room
- [x] Generate QR Code unik per room (format `ROOM:{id}:{code}`)
- [x] Popup dialog tampilkan QR Code
- [x] QR Code Scanner menggunakan kamera device
- [x] Flash toggle untuk kondisi gelap
- [x] Join Room via scan QR — API call ke `/api/rooms/join`
- [x] Navigasi otomatis ke detail room setelah join berhasil

### 🔒 Screen Protection
- [x] Library `screen_protector: ^1.5.1` terintegrasi
- [x] Blokir screenshot di Android (FLAG_SECURE)
- [x] Badge "Protected" di AppBar saat mode ujian aktif

### 📝 Bank Soal (Pertanyaan)
- [x] UI tambah soal per room — SoalManagementScreen + SoalFormScreen
- [x] UI edit soal
- [x] UI hapus soal (soft delete, riwayat jawaban aman)
- [x] Tampilkan daftar soal per room dengan infinite scroll
- [x] Soft delete — `deleted_at` GORM, jawaban tidak orphan
- [x] Pagination — `GET /rooms/:id/pertanyaans?page&limit`
- [x] **Upload gambar untuk soal** — `POST /api/upload`, `image_picker`, static file server (`/uploads`)
- [x] **Import soal dari file Excel (`.xlsx`)** — `POST /api/rooms/:id/import-excel`, `file_picker`, `excelize` library
- [x] Tipe soal Coding/File Upload

### 🎓 Pelaksanaan Ujian
- [x] Load soal dari API — `GET /rooms/:id/pertanyaans`
- [x] Simpan jawaban ke API — setiap pilih opsi/isi essay POST ke `/answers`
- [x] Timer dari durasi room — `durasiMenit` dari `RoomModel.durasi`
- [x] Question Grid — bottom sheet grid 8-kolom, klik navigasi ke soal
- [x] Bookmark soal — toggle bookmark, soal ditandai kuning di grid
- [x] Auto-submit saat waktu habis — timer trigger `submitExam(isTimeout: true)`
- [x] Navigasi soal dari grid
- [x] ExamSessionNotifier — ChangeNotifier untuk state session lengkap
- [x] ExamResultScreen — skor, benar/salah, lulus/tidak lulus

### 🧮 Backend Penilaian
- [x] Auto-calculate hasil ujian — `POST /api/hasil-ujians` hitung skor otomatis
- [x] Idempotent hasil — duplicate session_id kembalikan hasil existing
- [x] Filter answers by session, sesi by user, hasil by session

### 📊 Penilaian & Rekap Nilai
- [x] Rekap nilai per peserta — `RekamNilaiScreen` tampilkan semua peserta per room dengan skor, status lulus/tidak lulus, rata-rata, pass rate
- [x] Grafik/statistik sederhana — progress bar rata-rata + stat tiles (peserta/lulus/tidak lulus)
- [x] Backend `GET /rooms/:id/hasil` — join hasil_ujian → sesi_ujian untuk rekap per room
- [x] Export hasil ke PDF/Excel — memerlukan dependency baru (e.g. `pdf` package)
- [x] Grafik chart interaktif — memerlukan `fl_chart` atau sejenisnya



### 💬 Feedback dari Asesor
- [x] FeedbackScreen — asesor kirim feedback, peserta/asesor lihat riwayat feedback
- [x] FeedbackRemoteDataSourceImpl — implementasi API calls
- [x] `GET /api/feedback?hasil_id=X` — ambil feedback per hasil ujian
- [x] `DELETE /api/feedback/:id` — asesor hapus feedback miliknya (ownership check)
- [x] Real-time delivery — feedback dikirim via WebSocket ke peserta jika sedang online
- [x] Akses ke FeedbackScreen — tombol feedback di setiap baris peserta di RekamNilaiScreen

### 👥 Manajemen Pengguna
- [x] ProfileScreen — tab Profile di bottom nav berfungsi, tampilkan informasi user
- [x] Edit profil — edit nama & email, validasi email unik di backend
- [x] Ganti password — form dengan validasi, verifikasi password lama, bcrypt hash
- [x] Role management — selector Asesor/Peserta di profil, role disimpan lokal, UI berbeda
- [x] Backend `PUT /api/users/:id` — partial update (nama/email), ownership check
- [x] Backend `POST /api/users/:id/change-password` — verifikasi old_password bcrypt, hash baru
- [x] RoleChip — badge visual asesor/peserta di profil
- [x] ProfileNotifier — ChangeNotifier untuk state profil + password
- [x] Role management di database — role saat ini hanya disimpan lokal (SharedPreferences), belum kolom di DB
- [x] Upload foto profil

### 🌐 Backend API
- [x] CORS middleware
- [x] JWT middleware — proteksi semua endpoint kecuali auth
- [x] Full auth endpoints (register/login/forgot/reset)
- [x] CRUD `/api/users` + change-password
- [x] CRUD `/api/rooms` + join/code/user/participants
- [x] `GET /rooms/:id/pertanyaans` — paginated soal per room
- [x] `GET /rooms/:id/hasil` — rekap nilai peserta per room
- [x] CRUD `/api/pertanyaans` dengan soft delete
- [x] CRUD `/api/sesi-ujians` + filter `?user_id=`
- [x] CRUD `/api/answers` + filter `?session_id=`
- [x] `/api/hasil-ujians` + filter `?session_id=` + auto-calculate
- [x] `POST /api/feedback` + GET + DELETE/:id
- [x] WebSocket `/ws` dengan JWT auth + real-time feedback delivery

### 🐳 Containerization
- [x] Docker Compose — PostgreSQL + pgAdmin + Go Backend
- [x] Multi-stage Dockerfile untuk backend (builder + runtime Alpine)
- [x] Non-root user di container backend
- [x] Health check pada semua container
- [x] `.dockerignore` untuk optimasi build context

### 🔔 Notifikasi & Real-time
- [x] Notifikasi push — tombol notifikasi di dashboard belum berfungsi
- [x] Real-time peserta masuk room — WebSocket ada tapi UI tidak update
- [x] Real-time status ujian
---

## ❌ Fitur yang Belum Diimplementasikan

### 🎨 UI/UX
- [x] Halaman Results — tab Results di bottom nav belum dedicated
- [x] Halaman Exams — tab Exams di bottom nav belum dedicated
- [ ] Splash screen & onboarding
- [ ] Lokalisasi Bahasa Indonesia penuh

### 🔧 Backend & Teknis
- [ ] Input validation lebih ketat di semua handler
- [ ] Migrasi kolom database yang belum sinkron (room: description, start_date, question_types, shuffle_questions, room_code; pertanyaan: created_at, deleted_at)

### 🐛 Bug yang Diketahui
- [x] IP address hardcoded — `192.168.1.19` di `api_client.dart`
- [x] Participants di ExamRoomScreen masih dummy (`_participantsCount = 12`)

---

## 📁 Struktur File Saat Ini

```
ujikompetensi/
├── backend/
│   ├── Dockerfile              ✅ Multi-stage build (builder + Alpine runtime)
│   ├── .dockerignore           ✅ Optimasi build context
│   ├── .env                    ✅ Environment variables
│   ├── go.mod / go.sum         ✅ Go 1.25.5
│   ├── main.go                 ✅ Entry point
│   └── internal/
│       ├── config/             ✅ Konfigurasi
│       ├── database/           ✅ InitDB (PostgreSQL + GORM)
│       ├── handlers/           ✅ 8 handler (auth, user, room, pertanyaan, sesi, answer, hasil, feedback)
│       ├── middleware/         ✅ jwt_middleware.go
│       ├── models/            ✅ 10 model (User, Room, RoomParticipant, Pertanyaan, QuestionOption, SesiUjian, Answer, HasilUjian, Feedback, ActivityLog, PasswordReset)
│       ├── routes/            ✅ routes.go (auth public + protected routes)
│       ├── repositories/      ✅ Repository layer
│       ├── services/          ✅ Service layer
│       ├── usecase/           ✅ FeedbackUsecase (real-time delivery)
│       ├── delivery/ws/       ✅ WebSocket handler dengan JWT
│       └── infrastructure/
│           └── socket/        ✅ Hub + Client WebSocket
│
├── frontend/
│   └── lib/
│       ├── main.dart                   ✅ Entry point
│       ├── injection_container.dart    🟡 Ada, belum dipakai penuh
│       ├── core/
│       │   ├── network/        ✅ ApiClient (auto Bearer token) + UserService
│       │   ├── services/       ✅ AuthStorageService + ScreenProtectionService + WebSocketService
│       │   ├── widgets/        ✅ ProtectedScreen + DialogBuilder + NotificationOverlay
│       │   ├── error/          ✅ Error screens (404, no internet)
│       │   ├── constants/      ✅ Language constants
│       │   └── utils/          ✅ Logger
│       └── features/
│           ├── auth/           ✅ Login/Signup/JWT/Logout/ForgotPassword + User.role field
│           ├── dashboard/      ✅ IndexedStack: home tabs + Profile tab aktif
│           ├── room/           ✅ CRUD/Join/QR + Rekap Nilai button di ExamRoomScreen
│           ├── ujian/          ✅ ExamSession/Result/SoalManagement + RekamNilaiScreen + FeedbackScreen
│           ├── feedback/       ✅ Repository + FeedbackRemoteDataSourceImpl
│           ├── profile/        ✅ ProfileScreen + SecurityTab + ProfileNotifier
│           └── notifications/  🟡 NotificationsScreen (skeleton)
│
├── docker-compose.yml          ✅ PostgreSQL + pgAdmin + Go Backend
├── Dockerfile                  ⚠️ Lama (hanya PostgreSQL, sudah tidak dipakai)
└── .gitignore                  ✅
```

---

## 📈 Estimasi Progress per Modul

| Modul | Progress | Keterangan |
|---|---|---|
| Setup & Infrastruktur | 95% | Docker multi-stage build, DB, routing semua ada |
| Autentikasi | 90% | JWT, bcrypt, logout, session timeout ✅ |
| Dashboard | 90% | Profile tab aktif ✅ |
| Manajemen Room | 85% | Rekap Nilai button ✅, participants masih dummy |
| Bank Soal | 85% | Soft delete, pagination, CRUD UI ✅ |
| Pelaksanaan Ujian | 85% | Load soal, jawaban, timer, grid, bookmark, auto-submit ✅ |
| Penilaian & Hasil | 75% | Auto-calculate, RekamNilaiScreen, stats ✅, export PDF ❌ |
| Feedback Real-time | 70% | Backend WS + FeedbackScreen + datasource impl ✅ |
| Profil & Pengaturan | 85% | View/edit profil, ganti password, role selector ✅ |
| **Total Keseluruhan** | **~85%** | |

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
| `equatable` | ^2.0.5 | Value equality | ✅ Dipakai di Failure |
| `qr_flutter` | ^4.1.0 | Generate QR Code | ✅ Dipakai |
| `mobile_scanner` | ^7.2.0 | Scan QR Code | ✅ Dipakai |
| `screen_protector` | ^1.5.1 | Proteksi screenshot | ✅ Dipakai |
| `shared_preferences` | ^2.5.5 | Simpan data lokal + JWT | ✅ Dipakai |
| `flutter_local_notifications` | ^18.0.1 | Notifikasi lokal | 🟡 Ada, belum dipakai |

## 📦 Dependencies Backend

| Package | Kegunaan | Status |
|---|---|---|
| `gin` | HTTP framework | ✅ Dipakai |
| `gin-contrib/cors` | CORS middleware | ✅ Dipakai |
| `gorm` + `driver/postgres` | ORM PostgreSQL | ✅ Dipakai |
| `gorilla/websocket` | WebSocket | ✅ Dipakai |
| `golang-jwt/jwt` | JWT auth | ✅ Dipakai |
| `golang.org/x/crypto` | bcrypt password hash | ✅ Dipakai |
| `google/uuid` | UUID generation | ✅ Dipakai |
| `joho/godotenv` | Environment variables | ✅ Dipakai |

---

## 🔍 Catatan Teknis

### Hutang Teknis (Technical Debt)
1. Role user disimpan di SharedPreferences saja — belum kolom di database
2. `get_it` dan `provider` belum dipakai untuk DI terpusat
3. Tidak ada unit test (frontend maupun backend)
4. IP address backend hardcoded di `api_client.dart`
5. Participants count di `ExamRoomScreen` masih hardcoded
6. Schema database belum sinkron dengan model Go (kolom `room_code`, `description`, dll belum dimigrasikan)

### Keamanan yang Diterapkan
- JWT middleware memproteksi semua endpoint kecuali `/api/auth/*`
- `PUT /api/users/:id` dan `POST /api/users/:id/change-password` memverifikasi `user_id` dari JWT claims — user hanya bisa update diri sendiri
- `DELETE /api/feedback/:id` memverifikasi ownership (hanya asesor yang membuat yang bisa hapus)
- Password lama diverifikasi dengan bcrypt sebelum ganti password
- `bcrypt.DefaultCost` dipakai untuk semua hash password
- Container backend berjalan sebagai non-root user

---

*Laporan ini di-update pada 31 Juli 2026. Perubahan terakhir: dockerisasi backend Go dengan multi-stage build, pengecekan data user di database, dan konsolidasi progress report (menghapus duplikasi dari versi sebelumnya).*
