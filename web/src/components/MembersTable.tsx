import { useState, useEffect } from "react";
import {
  Search,
  UserPlus,
  MoreVertical,
  ChevronUp,
  ChevronDown,
  UserX,
  Wifi,
  WifiOff,
  Filter,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { fetchNui, type Member, type Role } from "@/lib/nui";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

export function MembersTable() {
  const [members, setMembers] = useState<Member[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    type: "promote" | "demote" | "kick";
    member: Member | null;
  }>({ open: false, type: "kick", member: null });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    const membersResponse = await fetchNui("getMembers");
    if (membersResponse.success) {
      setMembers(membersResponse.members);
    }

    const rolesResponse = await fetchNui("getRoles");
    if (rolesResponse.success) {
      setRoles(rolesResponse.roles);
    }
  };

  const handleAction = async (type: "promote" | "demote" | "kick", member: Member) => {
    const eventMap = {
      promote: "promoteMember",
      demote: "demoteMember",
      kick: "kickMember",
    };

    const response = await fetchNui(eventMap[type], { memberId: member.id });
    if (response.success) {
      toast.success(response.message);
      loadData();
    } else {
      toast.error(response.error || "Erro ao executar ação");
    }
    setConfirmDialog({ open: false, type: "kick", member: null });
  };

  const handleInvite = async () => {
    const response = await fetchNui("invitePlayer");
    if (response.success) {
      toast.success(response.message);
    } else {
      toast.error(response.error || "Nenhum jogador próximo encontrado");
    }
  };

  const getRoleColor = (roleName: string) => {
    const role = roles.find((r) => r.name === roleName);
    return role?.color || "#64748b";
  };

  const filteredMembers = members.filter((member) => {
    const matchesSearch = member.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesRole = roleFilter === "all" || member.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  const uniqueRoles = [...new Set(members.map((m) => m.role))];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Membros do Clã</h2>
          <p className="text-muted-foreground text-sm mt-1">
            Gerencie os membros e suas funções
          </p>
        </div>
        <Button variant="neon" onClick={handleInvite} className="self-start">
          <UserPlus className="w-4 h-4" />
          Convidar Jogador Próximo
        </Button>
      </div>

      {/* Filters */}
      <div className="glass-card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por nome..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 bg-secondary/50 border-border focus:border-primary"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-muted-foreground" />
            <Select value={roleFilter} onValueChange={setRoleFilter}>
              <SelectTrigger className="w-[180px] bg-secondary/50 border-border">
                <SelectValue placeholder="Filtrar por cargo" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos os cargos</SelectItem>
                {uniqueRoles.map((role) => (
                  <SelectItem key={role} value={role}>
                    {role}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="glass-card overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="border-border/50 hover:bg-transparent">
              <TableHead className="text-muted-foreground">Jogador</TableHead>
              <TableHead className="text-muted-foreground">Cargo</TableHead>
              <TableHead className="text-muted-foreground">Status</TableHead>
              <TableHead className="text-muted-foreground">Último Login</TableHead>
              <TableHead className="text-muted-foreground text-right">Ações</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredMembers.map((member, index) => (
              <TableRow
                key={member.id}
                className="border-border/30 hover:bg-secondary/30 transition-colors"
                style={{ animationDelay: `${index * 50}ms` }}
              >
                <TableCell>
                  <div className="flex items-center gap-3">
                    <div className="relative">
                      <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center text-foreground font-medium">
                        {member.avatar ? (
                          <img
                            src={member.avatar}
                            alt={member.name}
                            className="w-full h-full rounded-full object-cover"
                          />
                        ) : (
                          member.name.charAt(0).toUpperCase()
                        )}
                      </div>
                      <div
                        className={cn(
                          "absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-card",
                          member.status === "online" ? "status-online" : "status-offline"
                        )}
                      />
                    </div>
                    <span className="font-medium text-foreground">{member.name}</span>
                  </div>
                </TableCell>
                <TableCell>
                  <span
                    className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium"
                    style={{
                      backgroundColor: `${getRoleColor(member.role)}20`,
                      color: getRoleColor(member.role),
                      border: `1px solid ${getRoleColor(member.role)}40`,
                    }}
                  >
                    {member.role}
                  </span>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-2">
                    {member.status === "online" ? (
                      <>
                        <Wifi className="w-4 h-4 text-online" />
                        <span className="text-online text-sm">Online</span>
                      </>
                    ) : (
                      <>
                        <WifiOff className="w-4 h-4 text-muted-foreground" />
                        <span className="text-muted-foreground text-sm">Offline</span>
                      </>
                    )}
                  </div>
                </TableCell>
                <TableCell className="text-muted-foreground text-sm">
                  {member.lastLogin}
                </TableCell>
                <TableCell className="text-right">
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon" className="h-8 w-8">
                        <MoreVertical className="w-4 h-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end" className="w-48">
                      <DropdownMenuItem
                        onClick={() =>
                          setConfirmDialog({ open: true, type: "promote", member })
                        }
                        className="text-success"
                      >
                        <ChevronUp className="w-4 h-4 mr-2" />
                        Promover
                      </DropdownMenuItem>
                      <DropdownMenuItem
                        onClick={() =>
                          setConfirmDialog({ open: true, type: "demote", member })
                        }
                        className="text-warning"
                      >
                        <ChevronDown className="w-4 h-4 mr-2" />
                        Rebaixar
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        onClick={() =>
                          setConfirmDialog({ open: true, type: "kick", member })
                        }
                        className="text-destructive"
                      >
                        <UserX className="w-4 h-4 mr-2" />
                        Expulsar
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {filteredMembers.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">
            Nenhum membro encontrado com os filtros aplicados.
          </div>
        )}
      </div>

      {/* Members Count */}
      <div className="text-sm text-muted-foreground text-center">
        Mostrando {filteredMembers.length} de {members.length} membros
      </div>

      {/* Confirmation Dialog */}
      <Dialog
        open={confirmDialog.open}
        onOpenChange={(open) =>
          setConfirmDialog({ ...confirmDialog, open })
        }
      >
        <DialogContent className="glass-card border-border">
          <DialogHeader>
            <DialogTitle className="text-foreground">
              {confirmDialog.type === "promote" && "Promover Membro"}
              {confirmDialog.type === "demote" && "Rebaixar Membro"}
              {confirmDialog.type === "kick" && "Expulsar Membro"}
            </DialogTitle>
            <DialogDescription>
              {confirmDialog.type === "promote" &&
                `Deseja promover ${confirmDialog.member?.name} para o próximo cargo?`}
              {confirmDialog.type === "demote" &&
                `Deseja rebaixar ${confirmDialog.member?.name} para o cargo anterior?`}
              {confirmDialog.type === "kick" &&
                `Tem certeza que deseja expulsar ${confirmDialog.member?.name} do clã? Esta ação não pode ser desfeita.`}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2">
            <Button
              variant="outline"
              onClick={() =>
                setConfirmDialog({ open: false, type: "kick", member: null })
              }
            >
              Cancelar
            </Button>
            <Button
              variant={confirmDialog.type === "kick" ? "destructive" : "default"}
              onClick={() =>
                confirmDialog.member &&
                handleAction(confirmDialog.type, confirmDialog.member)
              }
            >
              Confirmar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
