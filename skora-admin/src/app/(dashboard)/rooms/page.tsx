"use client";

import { useQuery } from "@tanstack/react-query";
import { roomsService } from "@/services/rooms.service";
import { PageHeader } from "@/components/shared/page-header";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Plus, Loader2, Clock } from "lucide-react";

export default function RoomsPage() {
  const { data: rooms, isLoading, isError } = useQuery({
    queryKey: ["rooms"],
    queryFn: roomsService.getAll,
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Manajemen Rooms"
        description="Kelola semua ruang ujian"
        action={
          <Button size="sm">
            <Plus size={16} className="mr-2" />
            Buat Room
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
                <TableHead>Nama Room</TableHead>
                <TableHead>Kode</TableHead>
                <TableHead>Durasi</TableHead>
                <TableHead>Dibuat Oleh</TableHead>
                <TableHead>Tanggal</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rooms?.map((room) => (
                <TableRow key={room.id_room}>
                  <TableCell className="font-medium">{room.room_name}</TableCell>
                  <TableCell>
                    <Badge variant="outline" className="font-mono tracking-widest">
                      {room.room_code}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <span className="flex items-center gap-1 text-muted-foreground">
                      <Clock size={14} />
                      {room.durasi}m
                    </span>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {room.user?.nama ?? `#${room.created_by}`}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(room.created_at).toLocaleDateString("id-ID")}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}
