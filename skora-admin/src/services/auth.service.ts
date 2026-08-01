import api from "@/lib/axios";
import type { User } from "@/types";

interface LoginResponse {
  token: string;
  user: User;
}

export const authService = {
  login: (email: string, password: string) =>
    api.post<LoginResponse>("/auth/login", { email, password }).then((r) => r.data),

  register: (data: { nama: string; email: string; password: string; role?: string }) =>
    api.post<User>("/auth/register", data).then((r) => r.data),
};
