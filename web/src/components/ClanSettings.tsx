import { useState, useEffect } from "react";
import {
  Save,
  ImageIcon,
  FileText,
  Shield,
  Plus,
  Trash2,
  GripVertical,
  AlertTriangle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { fetchNui, type ClanData, type Role } from "@/lib/nui";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

const permissionLabels: Record<string, string> = {
  manage_members: "Gerenciar Membros",
  manage_roles: "Gerenciar Cargos",
  manage_clan: "Configurar Clã",
  invite: "Convidar Jogadores",
  kick: "Expulsar Membros",
};

export function ClanSettings() {
  const [clan, setClan] = useState<ClanData | null>(null);
  const [roles, setRoles] = useState<Role[]>([]);
  const [logoUrl, setLogoUrl] = useState("");
  const [description, setDescription] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    const clanResponse = await fetchNui("getClanData");
    if (clanResponse.success) {
      setClan(clanResponse.clan);
      setLogoUrl(clanResponse.clan.logo);
      setDescription(clanResponse.clan.description);
    }

    const rolesResponse = await fetchNui("getRoles");
    if (rolesResponse.success) {
      setRoles(rolesResponse.roles);
    }
  };

  const handleSaveSettings = async () => {
    setSaving(true);
    const response = await fetchNui("updateClanSettings", {
      logo: logoUrl,
      description,
      roles,
    });
    setSaving(false);

    if (response.success) {
      toast.success("Configurações salvas com sucesso!");
    } else {
      toast.error(response.error || "Erro ao salvar configurações");
    }
  };

  const handleRoleChange = (
    roleId: string,
    field: string,
    value: string | boolean
  ) => {
    setRoles((prev) =>
      prev.map((role) => {
        if (role.id === roleId) {
          if (field === "name" || field === "color") {
            return { ...role, [field]: value };
          } else {
            return {
              ...role,
              permissions: { ...role.permissions, [field]: value },
            };
          }
        }
        return role;
      })
    );
  };

  const addNewRole = () => {
    const newRole: Role = {
      id: `role_${Date.now()}`,
      name: "Novo Cargo",
      color: "#64748b",
      permissions: {
        manage_members: false,
        manage_roles: false,
        manage_clan: false,
        invite: false,
        kick: false,
      },
    };
    setRoles((prev) => [...prev, newRole]);
  };

  const deleteRole = (roleId: string) => {
    setRoles((prev) => prev.filter((r) => r.id !== roleId));
  };

  if (!clan) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-pulse text-muted-foreground">Carregando...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Configurações do Clã</h2>
          <p className="text-muted-foreground text-sm mt-1">
            Personalize a identidade e estrutura do seu clã
          </p>
        </div>
        <Button
          variant="neon"
          onClick={handleSaveSettings}
          disabled={saving}
          className="self-start"
        >
          <Save className="w-4 h-4" />
          {saving ? "Salvando..." : "Salvar Alterações"}
        </Button>
      </div>

      {/* General Settings */}
      <div className="glass-card p-6">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center">
            <ImageIcon className="w-5 h-5 text-primary" />
          </div>
          <div>
            <h3 className="font-semibold text-foreground">Identidade Visual</h3>
            <p className="text-xs text-muted-foreground">Logo e descrição do clã</p>
          </div>
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          {/* Logo Preview & URL */}
          <div className="space-y-4">
            <Label className="text-muted-foreground">URL da Logo</Label>
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-xl overflow-hidden bg-secondary flex items-center justify-center neon-border">
                {logoUrl ? (
                  <img
                    src={logoUrl}
                    alt="Logo Preview"
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = "none";
                    }}
                  />
                ) : (
                  <ImageIcon className="w-8 h-8 text-muted-foreground" />
                )}
              </div>
              <div className="flex-1">
                <Input
                  placeholder="https://exemplo.com/logo.png"
                  value={logoUrl}
                  onChange={(e) => setLogoUrl(e.target.value)}
                  className="bg-secondary/50 border-border focus:border-primary"
                />
                <p className="text-xs text-muted-foreground mt-2">
                  Use uma URL de imagem direta (PNG, JPG)
                </p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div className="space-y-4">
            <Label className="text-muted-foreground">Descrição do Clã</Label>
            <Textarea
              placeholder="Descreva seu clã..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="min-h-[100px] bg-secondary/50 border-border focus:border-primary resize-none"
            />
            <p className="text-xs text-muted-foreground">
              {description.length}/500 caracteres
            </p>
          </div>
        </div>
      </div>

      {/* Roles Editor */}
      <div className="glass-card p-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-primary/20 flex items-center justify-center">
              <Shield className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 className="font-semibold text-foreground">Editor de Cargos</h3>
              <p className="text-xs text-muted-foreground">
                Configure cargos e permissões
              </p>
            </div>
          </div>
          <Button variant="outline" size="sm" onClick={addNewRole}>
            <Plus className="w-4 h-4" />
            Novo Cargo
          </Button>
        </div>

        <div className="space-y-4">
          {roles.map((role, index) => (
            <div
              key={role.id}
              className="bg-secondary/30 rounded-xl p-4 border border-border/50 hover:border-primary/30 transition-colors"
            >
              <div className="flex items-start gap-4">
                {/* Drag Handle */}
                <div className="pt-2 cursor-grab text-muted-foreground hover:text-foreground">
                  <GripVertical className="w-5 h-5" />
                </div>

                {/* Role Settings */}
                <div className="flex-1 space-y-4">
                  <div className="flex flex-wrap items-center gap-4">
                    {/* Role Name */}
                    <div className="flex-1 min-w-[200px]">
                      <Label className="text-xs text-muted-foreground mb-1.5 block">
                        Nome do Cargo
                      </Label>
                      <Input
                        value={role.name}
                        onChange={(e) =>
                          handleRoleChange(role.id, "name", e.target.value)
                        }
                        className="bg-secondary/50 border-border focus:border-primary"
                        disabled={index < 2} // Disable editing for Leader and Vice
                      />
                    </div>

                    {/* Role Color */}
                    <div className="w-32">
                      <Label className="text-xs text-muted-foreground mb-1.5 block">
                        Cor
                      </Label>
                      <div className="flex items-center gap-2">
                        <input
                          type="color"
                          value={role.color}
                          onChange={(e) =>
                            handleRoleChange(role.id, "color", e.target.value)
                          }
                          className="w-10 h-10 rounded-lg cursor-pointer bg-transparent border-0"
                        />
                        <Input
                          value={role.color}
                          onChange={(e) =>
                            handleRoleChange(role.id, "color", e.target.value)
                          }
                          className="bg-secondary/50 border-border focus:border-primary font-mono text-sm"
                        />
                      </div>
                    </div>

                    {/* Delete Button */}
                    {index >= 2 && (
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => deleteRole(role.id)}
                        className="text-destructive hover:text-destructive hover:bg-destructive/10 mt-6"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    )}
                  </div>

                  {/* Permissions */}
                  <div>
                    <Label className="text-xs text-muted-foreground mb-3 block">
                      Permissões
                    </Label>
                    <div className="flex flex-wrap gap-4">
                      {Object.entries(role.permissions).map(([key, value]) => (
                        <div key={key} className="flex items-center gap-2">
                          <Checkbox
                            id={`${role.id}-${key}`}
                            checked={value}
                            onCheckedChange={(checked) =>
                              handleRoleChange(role.id, key, !!checked)
                            }
                            disabled={index === 0} // Leader has all permissions
                            className="border-border data-[state=checked]:bg-primary data-[state=checked]:border-primary"
                          />
                          <Label
                            htmlFor={`${role.id}-${key}`}
                            className="text-sm text-foreground cursor-pointer"
                          >
                            {permissionLabels[key]}
                          </Label>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Role Order Info */}
        <div className="mt-4 p-3 bg-primary/5 rounded-lg border border-primary/20">
          <p className="text-xs text-muted-foreground">
            <strong className="text-primary">Dica:</strong> A ordem dos cargos define
            a hierarquia. O cargo no topo é o mais alto. Arraste os cargos para
            reorganizar.
          </p>
        </div>
      </div>

      {/* Danger Zone - Delete Clan */}
      <div className="glass-card p-6 border-destructive/30">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-lg bg-destructive/20 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-destructive" />
          </div>
          <div>
            <h3 className="font-semibold text-destructive">Zona de Perigo</h3>
            <p className="text-xs text-muted-foreground">Ações irreversíveis</p>
          </div>
        </div>

        <div className="flex items-center justify-between p-4 bg-destructive/5 rounded-lg border border-destructive/20">
          <div>
            <p className="text-foreground font-medium">Deletar Clã</p>
            <p className="text-xs text-muted-foreground mt-1">
              Esta ação é permanente e não pode ser desfeita. Todos os dados serão perdidos.
            </p>
          </div>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" size="sm">
                <Trash2 className="w-4 h-4" />
                Deletar Clã
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent className="bg-background border-border">
              <AlertDialogHeader>
                <AlertDialogTitle className="text-foreground">Tem certeza absoluta?</AlertDialogTitle>
                <AlertDialogDescription className="text-muted-foreground">
                  Esta ação não pode ser desfeita. Isso irá deletar permanentemente o clã{" "}
                  <strong className="text-foreground">{clan.name}</strong>, todos os membros serão removidos
                  e todos os territórios serão perdidos.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel className="bg-secondary text-foreground border-border hover:bg-secondary/80">
                  Cancelar
                </AlertDialogCancel>
                <AlertDialogAction
                  className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                  onClick={async () => {
                    const response = await fetchNui("deleteClan", { clanId: clan.id });
                    if (response.success) {
                      toast.success("Clã deletado com sucesso!");
                    } else {
                      toast.error(response.error || "Erro ao deletar clã");
                    }
                  }}
                >
                  Sim, deletar clã
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </div>
    </div>
  );
}
