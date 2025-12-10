import { ClanPanel } from "@/components/ClanPanel";

const Index = () => {
  return (
    // MUDANÇA: bg-background removido e trocado por bg-transparent
    <div className="min-h-screen bg-transparent">
      
      {/* Opcional: Se você quiser remover os pontilhados de fundo também, apague este bloco div abaixo */}
      {/* Background Pattern */}
      {/* <div className="fixed inset-0 opacity-5"> ... </div> */}

      {/* NUI Panel */}
      <ClanPanel />
    </div>
  );
};

export default Index;