"use client";

import { useQueries } from "@tanstack/react-query";
import { usersService } from "@/services/users.service";
import { roomsService } from "@/services/rooms.service";
import { PageHeader } from "@/components/shared/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, DoorOpen, ClipboardList, TrendingUp, Loader2 } from "lucide-react";

export default function DashboardPage() {
  const [usersQ, roomsQ] = useQueries({
    queries: [
      { queryKey: ["users"], queryFn: usersService.getAll },
      { queryKey: ["rooms"], queryFn: roomsService.getAll },
    ],
  });

  const stats = [
    {
      title: "Total Users",
      value: usersQ.data?.length,
      loading: usersQ.isLoading,
      icon: Users,
      color: "text-blue-400",
    },
    {
      title: "Total Rooms",
      value: roomsQ.data?.length,
      loading: roomsQ.isLoading,
      icon: DoorOpen,
      color: "text-purple-400",
    },
    {
      title: "Asesor",
      value: usersQ.data?.filter((u) => u.role === "asesor").length,
      loading: usersQ.isLoading,
      icon: ClipboardList,
      color: "text-green-400",
    },
    {
      title: "Pelajar",
      value: usersQ.data?.filter((u) => u.role === "pelajar").length,
      loading: usersQ.isLoading,
      icon: TrendingUp,
      color: "text-yellow-400",
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Selamat datang di Skora Admin Panel"
      />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <Card key={s.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {s.title}
              </CardTitle>
              <s.icon size={18} className={s.color} />
            </CardHeader>
            <CardContent>
              {s.loading ? (
                <Loader2 size={20} className="animate-spin text-muted-foreground" />
              ) : (
                <p className="text-2xl font-bold">{s.value ?? "—"}</p>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
