// Mirror dari backend/internal/models/models.go

export interface User {
  id_users: number;
  nama: string;
  email: string;
  role: "asesor" | "pelajar" | "admin";
  avatar_url: string;
  created_at: string;
}

export interface Room {
  id_room: string;
  room_name: string;
  description: string;
  durasi: number;
  start_date: string | null;
  question_types: string;
  shuffle_questions: boolean;
  room_code: string;
  created_by: number;
  created_at: string;
  user: User;
}

export interface RoomParticipant {
  id: number;
  room_id: string;
  user_id: number;
  role: "asesor" | "pelajar";
  joined_at: string;
  user: User;
}

export interface Pertanyaan {
  id: number;
  room_id: string;
  pertanyaan_text: string;
  gambar_url?: string;
  type_pertanyaan: "multiple_choice" | "text";
  created_at: string;
  question_options: QuestionOption[];
}

export interface QuestionOption {
  id: number;
  question_id: number;
  option_text: string;
  is_correct: boolean;
}

export interface SesiUjian {
  id: number;
  room_id: string;
  user_id: number;
  start_time: string;
  end_time: string | null;
  status: "ongoing" | "completed" | "timeout";
  room: Room;
  user: User;
}

export interface HasilUjian {
  id: number;
  session_id: number;
  total_questions: number;
  jawaban_benar: number;
  jawaban_salah: number;
  skor: number;
  sesi_ujian: SesiUjian;
}

export interface Feedback {
  id: number;
  hasil_id: number;
  asesor_id: number;
  komentar: string;
  created_at: string;
  asesor: User;
}

// Generic API response wrapper
export interface ApiError {
  error: string;
  details?: Record<string, string>;
}

export type PaginatedResponse<T> = {
  data: T[];
  total: number;
  page: number;
  per_page: number;
};
