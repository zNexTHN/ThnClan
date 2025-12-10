import { useState, useEffect } from "react";
import { ChevronDown, MapPin, Trash2, Swords, Eye } from "lucide-react";
import { fetchNui, Territory } from "@/lib/nui";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { toast } from "sonner";

export function Territories() {
  const [territories, setTerritories] = useState<Territory[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    async function loadTerritories() {
      const response = await fetchNui<{ success: boolean; territories: Territory[] }>("getTerritories");
      if (response.success) {
        setTerritories(response.territories);
      }
    }
    loadTerritories();
  }, []);

  const handleGoToTerritory = async (territory: Territory) => {
    const response = await fetchNui<{ success: boolean; message: string }>("goToTerritory", { 
      territoryId: territory.id 
    });
    if (response.success) {
      toast.success(response.message);
    } else {
      toast.error("Erro ao definir GPS");
    }
  };

  const handleDropTerritory = async (territory: Territory) => {
    const response = await fetchNui<{ success: boolean; message: string }>("dropTerritory", { 
      territoryId: territory.id 
    });
    if (response.success) {
      toast.success(response.message);
      setTerritories(prev => prev.filter(t => t.id !== territory.id));
    } else {
      toast.error("Erro ao largar território");
    }
  };

  const handleViewAvailableTerritories = async () => {
    const response = await fetchNui<{ success: boolean; message: string }>("viewAvailableTerritories");
    if (response.success) {
      toast.success(response.message);
    } else {
      toast.error("Erro ao visualizar territórios");
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Territórios</h2>
          <p className="text-muted-foreground">Gerencie os territórios do seu clã</p>
        </div>
        <div className="flex items-center gap-3">
          <Badge variant="outline" className="text-primary border-primary">
            {territories.length} Territórios
          </Badge>
          <Button variant="glass" onClick={handleViewAvailableTerritories}>
            <Eye className="w-4 h-4 mr-2" />
            Visualizar disponíveis
          </Button>
        </div>
      </div>

      {/* Territory Cards */}
      <div className="space-y-3">
        {territories.length === 0 ? (
          <div className="glass-card p-8 text-center">
            <p className="text-muted-foreground">Nenhum território conquistado</p>
          </div>
        ) : (
          territories.map((territory) => (
            <Collapsible
              key={territory.id}
              open={expandedId === territory.id}
              onOpenChange={(open) => setExpandedId(open ? territory.id : null)}
            >
              <div
                className={cn(
                  "glass-card overflow-hidden transition-all duration-300",
                  territory.underAttack && "border-destructive/50 bg-destructive/5"
                )}
              >
                <CollapsibleTrigger asChild>
                  <button className="w-full flex items-center justify-between p-4 hover:bg-secondary/30 transition-colors">
                    <div className="flex items-center gap-3">
                      {territory.underAttack && (
                        <Swords className="w-5 h-5 text-destructive animate-pulse" />
                      )}
                      <div className="text-left">
                        <h3 className={cn(
                          "font-semibold",
                          territory.underAttack ? "text-destructive" : "text-foreground"
                        )}>
                          {territory.name}
                        </h3>
                        {territory.underAttack && territory.attackerName && (
                          <Badge variant="destructive" className="mt-1 text-xs">
                            Sob ataque de {territory.attackerName}
                          </Badge>
                        )}
                      </div>
                    </div>
                    <ChevronDown 
                      className={cn(
                        "w-5 h-5 text-muted-foreground transition-transform duration-200",
                        expandedId === territory.id && "rotate-180"
                      )} 
                    />
                  </button>
                </CollapsibleTrigger>

                <CollapsibleContent>
                  <div className="px-4 pb-4 pt-2 border-t border-border/50">
                    <div className="flex gap-3">
                      <Button 
                        variant="glass" 
                        className="flex-1"
                        onClick={() => handleGoToTerritory(territory)}
                      >
                        <MapPin className="w-4 h-4 mr-2" />
                        Ir até o território
                      </Button>
                      <Button 
                        variant="outline"
                        className="flex-1 border-destructive/50 text-destructive hover:bg-destructive/10"
                        onClick={() => handleDropTerritory(territory)}
                      >
                        <Trash2 className="w-4 h-4 mr-2" />
                        Largar Território
                      </Button>
                    </div>
                  </div>
                </CollapsibleContent>
              </div>
            </Collapsible>
          ))
        )}
      </div>
    </div>
  );
}
