import { useState, useEffect } from "react";
import { ClanSidebar } from "./ClanSidebar";
import { Dashboard } from "./Dashboard";
import { MembersTable } from "./MembersTable";
import { ClanSettings } from "./ClanSettings";
import { Territories } from "./Territories";
import { CreateClan } from "./CreateClan";
import { fetchNui } from "@/lib/nui";

// Detecta se está no navegador (desenvolvimento) ou no FiveM
const isEnvBrowser = (): boolean => !(window as any).invokeNative;

type ViewState = "loading" | "create" | "panel";

export function ClanPanel() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [isVisible, setIsVisible] = useState(isEnvBrowser());
  const [viewState, setViewState] = useState<ViewState>("loading");

  // Check if player has a clan when panel becomes visible
  useEffect(() => {
    if (isVisible) {
      checkClanStatus();
    }
  }, [isVisible]);

  const checkClanStatus = async () => {
    setViewState("loading");
    try {
      const response = await fetchNui("getClanData");
      if (response && response.clan) {
        setViewState("panel");
      } else {
        setViewState("create");
      }
    } catch {
      setViewState("create");
    }
  };

  const handleClanCreated = () => {
    setViewState("panel");
    setActiveTab("dashboard");
  };

  // Listen for NUI visibility events from FiveM
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data || {};
      
      if (action === "setVisible") {
        console.log("[ClanPanel] Recebido setVisible:", data);
        setIsVisible(data?.visible ?? false);
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  // Handle escape key to close
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setIsVisible(false);
        fetch(`https://${(window as any).GetParentResourceName?.() || "clan-panel"}/closeNui`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({})
        }).catch(() => {});
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  if (!isVisible) return null;

  // Show loading state
  if (viewState === "loading") {
    return (
      <div className="fixed inset-0 flex items-center justify-center z-50">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Show create clan form
  if (viewState === "create") {
    return <CreateClan onClanCreated={handleClanCreated} />;
  }

  const renderContent = () => {
    switch (activeTab) {
      case "dashboard":
        return <Dashboard />;
      case "members":
        return <MembersTable />;
      case "territories":
        return <Territories />;
      case "settings":
        return <ClanSettings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center p-4 z-50">
      {/* Panel Container - Holographic Tablet Effect */}
      <div className="relative w-full max-w-6xl h-[85vh] flex rounded-2xl overflow-hidden holographic animate-scale-in">
        {/* Outer Glow */}
        <div className="absolute -inset-1 bg-gradient-to-r from-primary/20 via-neon-purple/20 to-primary/20 rounded-2xl blur-xl opacity-50 animate-pulse-slow" />

        {/* Panel Frame */}
        <div className="relative flex w-full h-full bg-card/80 backdrop-blur-xl rounded-2xl border border-border/50 overflow-hidden">
          {/* Corner Decorations */}
          <div className="absolute top-0 left-0 w-16 h-16 border-t-2 border-l-2 border-primary/50 rounded-tl-2xl" />
          <div className="absolute top-0 right-0 w-16 h-16 border-t-2 border-r-2 border-primary/50 rounded-tr-2xl" />
          <div className="absolute bottom-0 left-0 w-16 h-16 border-b-2 border-l-2 border-primary/50 rounded-bl-2xl" />
          <div className="absolute bottom-0 right-0 w-16 h-16 border-b-2 border-r-2 border-primary/50 rounded-br-2xl" />

          {/* Sidebar */}
          <ClanSidebar activeTab={activeTab} onTabChange={setActiveTab} />

          {/* Main Content */}
          <main className="flex-1 overflow-y-auto p-6 custom-scrollbar">
            {renderContent()}
          </main>
        </div>

        {/* Scanning Line Animation */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden rounded-2xl">
          <div className="absolute w-full h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent animate-shimmer" />
        </div>
      </div>
    </div>
  );
}
