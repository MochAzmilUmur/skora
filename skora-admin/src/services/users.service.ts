import api from "@/lib/axios";
import type { User } from "@/types";

export interface CreateUserPayload {
  nama: string;
  email: string;
  password: string;
  role: User["role"];
}

export const usersService = {
  getAll: () => api.get<User[]>("/users").then((r) => r.data),

  getById: (id: number) => api.get<User>(`/users/${id}`).then((r) => r.data),

  // Create via /auth/register, then patch role if not pelajar
  create: async (data: CreateUserPayload): Promise<User> => {
    const res = await api.post<{ user: User; token: string }>("/auth/register", {
      nama: data.nama,
      email: data.email,
      password: data.password,
    });
    const user = res.data.user;
    // Default role from register is "pelajar" — update if different
    if (data.role !== "pelajar") {
      return api
        .put<User>(`/users/${user.id_users}/role`, { role: data.role })
        .then((r) => r.data);
    }
    return user;
  },

  delete: (id: number) => api.delete(`/users/${id}`),

  updateRole: (id: number, role: "asesor" | "pelajar") =>
    api.put<User>(`/users/${id}/role`, { role }).then((r) => r.data),
};
