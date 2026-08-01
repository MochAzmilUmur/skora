"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { usersService, type CreateUserPayload } from "@/services/users.service";
import { PageHeader } from "@/components/shared/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";
import { Plus, Loader2, Trash2, RefreshCw } from "lucide-react";
import { toast } from "sonner";
import type { User } from "@/types";

// ── Role badge ───────────────────────────────────────────────────────────────
const roleStyle: Record<User["role"], string> = {
  admin:   "bg-blue-500/20 text-blue-400 border border-blue-500/30",
  asesor:  "bg-purple-500/20 text-purple-400 border border-purple-500/30",
  pelajar: "bg-slate-500/20 text-slate-400 border border-slate-500/30",
};

function RoleBadge({ role }: { role: User["role"] }) {
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${roleStyle[role] ?? roleStyle.pelajar}`}>
      {role}
    </span>
  );
}

// ── Change Role Dialog ───────────────────────────────────────────────────────
function ChangeRoleDialog({
  user,
  onClose,
}: {
  user: User | null;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  // Target role adalah kebalikan dari role saat ini
  const targetRole = user?.role === "asesor" ? "pelajar" : "asesor";

  const mutation = useMutation({
    mutationFn: () => usersService.updateRole(user!.id_users, targetRole),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success(
        `${user?.nama} berhasil diubah menjadi ${targetRole}`
      );
      onClose();
    },
    onError: () => toast.error("Gagal mengubah role. Coba lagi."),
  });

  if (!user) return null;

  return (
    <Dialog open={!!user} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Ubah Role User</DialogTitle>
          <DialogDescription>
            Tindakan ini akan mengubah hak akses pengguna di sistem.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Info user */}
          <div className="rounded-lg border border-border bg-muted/30 p-4 space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Nama</span>
              <span className="font-medium">{user.nama}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Email</span>
              <span className="text-muted-foreground">{user.email}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Role saat ini</span>
              <RoleBadge role={user.role} />
            </div>
          </div>

          {/* Perubahan yang akan terjadi */}
          <div className="flex items-center justify-center gap-3 py-2">
            <RoleBadge role={user.role} />
            <RefreshCw size={16} className="text-muted-foreground" />
            <RoleBadge role={targetRole} />
          </div>

          <p className="text-center text-sm text-muted-foreground">
            Apakah Anda yakin ingin mengubah role{" "}
            <span className="font-semibold text-foreground">{user.nama}</span>{" "}
            menjadi <span className="font-semibold text-foreground capitalize">{targetRole}</span>?
          </p>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={mutation.isPending}>
            Tidak
          </Button>
          <Button onClick={() => mutation.mutate()} disabled={mutation.isPending}>
            {mutation.isPending && <Loader2 size={14} className="mr-2 animate-spin" />}
            Ya, Ubah
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ── Create User Dialog ───────────────────────────────────────────────────────
const ROLES: User["role"][] = ["pelajar", "asesor", "admin"];

function CreateUserDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const qc = useQueryClient();
  const [form, setForm] = useState<CreateUserPayload>({
    nama: "", email: "", password: "", role: "pelajar",
  });

  const mutation = useMutation({
    mutationFn: usersService.create,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success("User berhasil dibuat");
      onClose();
      setForm({ nama: "", email: "", password: "", role: "pelajar" });
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { error?: string } } })
        ?.response?.data?.error ?? "Gagal membuat user";
      toast.error(msg);
    },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    mutation.mutate(form);
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Tambah User Baru</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <label className="text-sm font-medium">Nama</label>
            <Input
              placeholder="Nama lengkap"
              value={form.nama}
              onChange={(e) => setForm((f) => ({ ...f, nama: e.target.value }))}
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Email</label>
            <Input
              type="email"
              placeholder="email@skora.id"
              value={form.email}
              onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Password</label>
            <Input
              type="password"
              placeholder="Min. 6 karakter"
              value={form.password}
              onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
              minLength={6}
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium">Role</label>
            <select
              value={form.role}
              onChange={(e) => setForm((f) => ({ ...f, role: e.target.value as User["role"] }))}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            >
              {ROLES.map((r) => (
                <option key={r} value={r} className="capitalize">{r}</option>
              ))}
            </select>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Batal
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending && <Loader2 size={14} className="mr-2 animate-spin" />}
              Buat User
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ── Delete Confirm Dialog ────────────────────────────────────────────────────
function DeleteDialog({ user, onClose }: { user: User | null; onClose: () => void }) {
  const qc = useQueryClient();

  const mutation = useMutation({
    mutationFn: () => usersService.delete(user!.id_users),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success(`User "${user?.nama}" berhasil dihapus`);
      onClose();
    },
    onError: () => toast.error("Gagal menghapus user"),
  });

  return (
    <Dialog open={!!user} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Hapus User</DialogTitle>
          <DialogDescription>
            Tindakan ini tidak dapat dibatalkan.
          </DialogDescription>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">
          Apakah Anda yakin ingin menghapus{" "}
          <span className="font-semibold text-foreground">{user?.nama}</span>?
        </p>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Tidak
          </Button>
          <Button
            variant="destructive"
            onClick={() => mutation.mutate()}
            disabled={mutation.isPending}
          >
            {mutation.isPending && <Loader2 size={14} className="mr-2 animate-spin" />}
            Ya, Hapus
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

// ── Main Page ────────────────────────────────────────────────────────────────
export default function UsersPage() {
  const [createOpen, setCreateOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);
  const [roleTarget, setRoleTarget] = useState<User | null>(null);

  const { data: users, isLoading, isError } = useQuery({
    queryKey: ["users"],
    queryFn: usersService.getAll,
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Manajemen Users"
        description="Kelola semua pengguna sistem Skora"
        action={
          <Button size="sm" onClick={() => setCreateOpen(true)}>
            <Plus size={16} className="mr-2" />
            Tambah User
          </Button>
        }
      />

      <div className="rounded-lg border border-border bg-card">
        {isLoading ? (
          <div className="flex h-48 items-center justify-center">
            <Loader2 size={24} className="animate-spin text-muted-foreground" />
          </div>
        ) : isError ? (
          <div className="flex h-48 items-center justify-center text-sm text-destructive">
            Gagal memuat data. Pastikan backend berjalan.
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-16">ID</TableHead>
                <TableHead>Nama</TableHead>
                <TableHead>Email</TableHead>
                <TableHead className="w-28">Role</TableHead>
                <TableHead className="w-32">Bergabung</TableHead>
                <TableHead className="w-32 text-right">Aksi</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users?.map((user) => (
                <TableRow key={user.id_users}>
                  <TableCell className="text-muted-foreground">
                    #{user.id_users}
                  </TableCell>
                  <TableCell className="font-medium">{user.nama}</TableCell>
                  <TableCell className="text-muted-foreground">
                    {user.email}
                  </TableCell>
                  <TableCell>
                    <RoleBadge role={user.role} />
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(user.created_at).toLocaleDateString("id-ID")}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      {/* Tombol ubah role — hanya untuk pelajar dan asesor, bukan admin */}
                      {user.role !== "admin" && (
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-primary"
                          title={user.role === "asesor" ? "Jadikan Pelajar" : "Jadikan Asesor"}
                          onClick={() => setRoleTarget(user)}
                        >
                          <RefreshCw size={15} />
                        </Button>
                      )}
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-muted-foreground hover:text-destructive"
                        title="Hapus user"
                        onClick={() => setDeleteTarget(user)}
                      >
                        <Trash2 size={15} />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>

      <CreateUserDialog open={createOpen} onClose={() => setCreateOpen(false)} />
      <DeleteDialog user={deleteTarget} onClose={() => setDeleteTarget(null)} />
      <ChangeRoleDialog user={roleTarget} onClose={() => setRoleTarget(null)} />
    </div>
  );
}
