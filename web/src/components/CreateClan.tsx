import { useState } from "react";
import { Shield, Image, FileText, Loader2, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { fetchNui } from "@/lib/nui";
import { toast } from "sonner";

interface CreateClanProps {
  onClanCreated: () => void;
}

export function CreateClan({ onClanCreated }: CreateClanProps) {
  const [name, setName] = useState("");
  const [logo, setLogo] = useState("");
  const [description, setDescription] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      toast.error("O nome do clã é obrigatório");
      return;
    }

    setIsLoading(true);
    try {
      const response = await fetchNui("createClan", {
        name: name.trim(),
        logo: logo.trim(),
        description: description.trim(),
      });

      if (response.success) {
        toast.success(response.message || "Clã criado com sucesso!");
        onClanCreated();
      } else {
        toast.error(response.error || "Erro ao criar clã");
      }
    } catch (error) {
      toast.error("Erro ao criar clã");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center p-4 z-50">
      <div className="relative w-full max-w-lg animate-scale-in">
        
        <div 
          className="relative p-8 rounded-2xl bg-zinc-950/95 border border-white/10 shadow-none"
          style={{ 
            clipPath: "inset(0 round 1rem)"
          }}
        >
          
          <div className="absolute top-0 left-0 w-12 h-12 border-t-2 border-l-2 border-primary/50 rounded-tl-2xl pointer-events-none" />
          <div className="absolute top-0 right-0 w-12 h-12 border-t-2 border-r-2 border-primary/50 rounded-tr-2xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 w-12 h-12 border-b-2 border-l-2 border-primary/50 rounded-bl-2xl pointer-events-none" />
          <div className="absolute bottom-0 right-0 w-12 h-12 border-b-2 border-r-2 border-primary/50 rounded-br-2xl pointer-events-none" />

          <div className="text-center mb-8 relative z-10">
            <div className="w-16 h-16 mx-auto mb-4 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20">
              <Shield className="w-8 h-8 text-primary" />
            </div>
            <h1 className="text-2xl font-bold text-foreground mb-2">Criar Novo Clã</h1>
            <p className="text-sm text-muted-foreground">
              Preencha as informações abaixo para criar seu clã
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6 relative z-10">
            <div className="space-y-2">
              <Label htmlFor="name" className="text-foreground flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-primary" />
                Nome do Clã
              </Label>
              <Input
                id="name"
                placeholder="Digite o nome do clã"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="bg-secondary/30 border-white/10 focus:border-primary text-foreground placeholder:text-muted-foreground/50"
                maxLength={32}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="logo" className="text-foreground flex items-center gap-2">
                <Image className="w-4 h-4 text-primary" />
                URL da Logo
              </Label>
              <div className="flex gap-3">
                <Input
                  id="logo"
                  placeholder="https://exemplo.com/logo.png"
                  value={logo}
                  onChange={(e) => setLogo(e.target.value)}
                  className="bg-secondary/30 border-white/10 focus:border-primary flex-1 text-foreground placeholder:text-muted-foreground/50"
                />
                <div className="w-12 h-12 rounded-lg bg-secondary/30 border border-white/10 flex items-center justify-center overflow-hidden flex-shrink-0">
                  {logo ? (
                    <img
                      src={logo}
                      alt="Preview"
                      className="w-full h-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = "none";
                      }}
                    />
                  ) : (
                    <Image className="w-5 h-5 text-muted-foreground" />
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="description" className="text-foreground flex items-center gap-2">
                <FileText className="w-4 h-4 text-primary" />
                Descrição
              </Label>
              <Textarea
                id="description"
                placeholder="Descreva seu clã..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="bg-secondary/30 border-white/10 focus:border-primary min-h-[100px] resize-none text-foreground placeholder:text-muted-foreground/50"
                maxLength={256}
              />
              <p className="text-xs text-muted-foreground text-right">
                {description.length}/256
              </p>
            </div>

            <Button
              type="submit"
              variant="default"
              className="w-full bg-primary hover:bg-primary/90 text-primary-foreground font-bold shadow-[0_0_20px_rgba(var(--primary),0.3)]"
              disabled={isLoading || !name.trim()}
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin mr-2" />
                  Criando...
                </>
              ) : (
                <>
                  <Shield className="w-4 h-4 mr-2" />
                  Criar Clã
                </>
              )}
            </Button>
          </form>

          <div className="absolute inset-0 pointer-events-none rounded-2xl overflow-hidden">
            <div className="absolute w-full h-px bg-gradient-to-r from-transparent via-primary/20 to-transparent animate-shimmer" />
          </div>
        </div>
      </div>
    </div>
  );
}