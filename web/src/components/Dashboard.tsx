import { useState, useEffect } from "react";
import { 
  Users, 
  MapPin, 
  Wifi, 
  WifiOff, 
  Megaphone,
  Edit3,
  Save,
  Crown
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { fetchNui, type ClanData, type Member } from "@/lib/nui";
import { toast } from "sonner";

export function Dashboard() {
  const [clan, setClan] = useState<ClanData | null>(null);
  const [members, setMembers] = useState<Member[]>([]);
  const [editingAnnouncement, setEditingAnnouncement] = useState(false);
  const [announcement, setAnnouncement] = useState("");

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    const clanResponse = await fetchNui("getClanData");
    if (clanResponse.success) {
      setClan(clanResponse.clan);
      setAnnouncement(clanResponse.clan.announcement);
    }

    const membersResponse = await fetchNui("getMembers");
    if (membersResponse.success) {
      setMembers(membersResponse.members);
    }
  };

  const saveAnnouncement = async () => {
    const response = await fetchNui("updateAnnouncement", { announcement });
    if (response.success) {
      toast.success("Mural atualizado com sucesso!");
      setEditingAnnouncement(false);
      if (clan) {
        setClan({ ...clan, announcement });
      }
    }
  };

  const onlineCount = members.filter((m) => m.status === "online").length;

  if (!clan) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-pulse text-muted-foreground">Carregando...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Clan Header Card */}
      <div className="glass-card p-6 holographic">
        <div className="flex items-center gap-6">
          {/* Clan Logo */}
          <div className="relative">
            <div className="w-24 h-24 rounded-full overflow-hidden neon-border animate-glow">
              <img
                src={clan.logo}
                alt={clan.name}
                className="w-full h-full object-cover"
              />
            </div>
            <div className="absolute -bottom-1 -right-1 bg-primary text-primary-foreground rounded-full p-1.5">
              <Crown className="w-4 h-4" />
            </div>
          </div>

          {/* Clan Info */}
          <div className="flex-1">
            <h2 className="text-2xl font-bold text-foreground neon-text">{clan.name}</h2>
            <p className="text-muted-foreground text-sm mt-1 max-w-md">{clan.description}</p>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Members Online */}
        <div className="glass-card-hover p-5">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-online/20 flex items-center justify-center">
              <Users className="w-6 h-6 text-online" />
            </div>
            <div>
              <p className="text-muted-foreground text-sm">Membros</p>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold text-foreground">{onlineCount}</span>
                <span className="text-muted-foreground text-sm">/ {members.length}</span>
              </div>
            </div>
          </div>
          <div className="mt-3 flex items-center gap-2 text-xs">
            <div className="flex items-center gap-1 text-online">
              <Wifi className="w-3 h-3" />
              <span>{onlineCount} online</span>
            </div>
            <span className="text-muted-foreground">•</span>
            <div className="flex items-center gap-1 text-muted-foreground">
              <WifiOff className="w-3 h-3" />
              <span>{members.length - onlineCount} offline</span>
            </div>
          </div>
        </div>

        {/* Territories */}
        <div className="glass-card-hover p-5">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-warning/20 flex items-center justify-center">
              <MapPin className="w-6 h-6 text-warning" />
            </div>
            <div>
              <p className="text-muted-foreground text-sm">Territórios</p>
              <span className="text-2xl font-bold text-foreground">{clan.territories}</span>
            </div>
          </div>
          <div className="mt-3 text-xs text-muted-foreground">
            Dominados atualmente
          </div>
        </div>
      </div>

      {/* Announcement Board */}
      <div className="glass-card p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center">
              <Megaphone className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-foreground">Mural de Avisos</h3>
              <p className="text-xs text-muted-foreground">Mensagem do líder para o clã</p>
            </div>
          </div>
          {editingAnnouncement ? (
            <Button variant="neon" size="sm" onClick={saveAnnouncement}>
              <Save className="w-4 h-4" />
              Salvar
            </Button>
          ) : (
            <Button variant="ghost" size="sm" onClick={() => setEditingAnnouncement(true)}>
              <Edit3 className="w-4 h-4" />
              Editar
            </Button>
          )}
        </div>

        {editingAnnouncement ? (
          <Textarea
            value={announcement}
            onChange={(e) => setAnnouncement(e.target.value)}
            placeholder="Escreva a mensagem do dia para o clã..."
            className="min-h-[100px] bg-secondary/50 border-border focus:border-primary"
          />
        ) : (
          <div className="bg-secondary/30 rounded-lg p-4 border border-border/50">
            <p className="text-foreground whitespace-pre-wrap">
              {clan.announcement || "Nenhum aviso no momento."}
            </p>
          </div>
        )}
      </div>

      {/* Online Members Preview */}
      <div className="glass-card p-6">
        <h3 className="font-semibold text-foreground mb-4 flex items-center gap-2">
          <Wifi className="w-4 h-4 text-online" />
          Membros Online
        </h3>
        <div className="flex flex-wrap gap-3">
          {members
            .filter((m) => m.status === "online")
            .slice(0, 8)
            .map((member) => (
              <div
                key={member.id}
                className="flex items-center gap-2 bg-secondary/50 rounded-full px-3 py-1.5"
              >
                <div className="w-2 h-2 rounded-full status-online animate-pulse" />
                <span className="text-sm text-foreground">{member.name}</span>
                <span className="text-xs text-muted-foreground">({member.role})</span>
              </div>
            ))}
          {onlineCount > 8 && (
            <div className="flex items-center px-3 py-1.5 text-sm text-muted-foreground">
              +{onlineCount - 8} mais
            </div>
          )}
          {onlineCount === 0 && (
            <p className="text-muted-foreground text-sm">Nenhum membro online no momento.</p>
          )}
        </div>
      </div>
    </div>
  );
}
