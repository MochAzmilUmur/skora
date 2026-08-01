import api from "@/lib/axios";
import type { Room, RoomParticipant } from "@/types";

export const roomsService = {
  getAll: () => api.get<Room[]>("/rooms").then((r) => r.data),

  getById: (id: string) => api.get<Room>(`/rooms/${id}`).then((r) => r.data),

  getByUser: (userId: number) =>
    api.get<Room[]>(`/rooms/user/${userId}`).then((r) => r.data),

  create: (data: Pick<Room, "room_name" | "description" | "durasi" | "created_by">) =>
    api.post<Room>("/rooms", data).then((r) => r.data),

  update: (id: string, data: Partial<Pick<Room, "room_name" | "description" | "durasi">>) =>
    api.put<Room>(`/rooms/${id}`, data).then((r) => r.data),

  delete: (id: string) => api.delete(`/rooms/${id}`),

  getParticipants: (id: string) =>
    api.get<RoomParticipant[]>(`/rooms/${id}/participants`).then((r) => r.data),
};
