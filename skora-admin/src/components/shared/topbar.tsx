"use client";

import { usePathname } from "next/navigation";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";

const pageTitles: Record<string, string> = {
  "/dashboard": "Dashboard",
  "/users": "Manajemen Users",
  "/rooms": "Manajemen Rooms",
};

export function Topbar() {
  const pathname = usePathname();
  const title = pageTitles[pathname] ?? "Skora Admin";

  return (
    <header className="flex h-16 items-center justify-between border-b border-border bg-card px-6">
      <h1 className="text-lg font-semibold text-foreground">{title}</h1>
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="icon">
          <Bell size={18} />
        </Button>
      </div>
    </header>
  );
}
