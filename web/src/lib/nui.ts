/**
 * =============================================================================
 * FiveM NUI Callback System
 * =============================================================================
 * 
 * Este módulo gerencia a comunicação entre a interface NUI (web) e o cliente FiveM.
 * 
 * CONFIGURAÇÃO NO FIVEM (Lua):
 * 
 * 1. No seu resource, crie os callbacks usando RegisterNUICallback:
 * 
 *    ```lua
 *    -- Callback para obter dados do clã
 *    RegisterNUICallback('getClanData', function(data, cb)
 *        local clanData = {
 *            id = "clan_001",
 *            name = "Nome do Clã",
 *            logo = "https://url-da-logo.png",
 *            description = "Descrição do clã",
 *            territories = 5,
 *            announcement = "Mensagem do dia"
 *        }
 *        cb({ success = true, clan = clanData })
 *    end)
 * 
 *    -- Callback para obter membros
 *    RegisterNUICallback('getMembers', function(data, cb)
 *        local members = {
 *            { id = "1", name = "Player1", avatar = "", role = "Líder", status = "online", lastLogin = "Agora" },
 *            { id = "2", name = "Player2", avatar = "", role = "Membro", status = "offline", lastLogin = "2h" }
 *        }
 *        cb({ success = true, members = members })
 *    end)
 * 
 *    -- Callback para obter cargos
 *    RegisterNUICallback('getRoles', function(data, cb)
 *        local roles = {
 *            { id = "1", name = "Líder", color = "#06b6d4", permissions = { manage_members = true, manage_roles = true, manage_clan = true, invite = true, kick = true } },
 *            { id = "2", name = "Membro", color = "#64748b", permissions = { manage_members = false, manage_roles = false, manage_clan = false, invite = false, kick = false } }
 *        }
 *        cb({ success = true, roles = roles })
 *    end)
 * 
 *    -- Callback para promover membro
 *    RegisterNUICallback('promoteMember', function(data, cb)
 *        local memberId = data.memberId
 *        -- Sua lógica de promoção aqui
 *        cb({ success = true, message = "Membro promovido!" })
 *    end)
 * 
 *    -- Callback para rebaixar membro
 *    RegisterNUICallback('demoteMember', function(data, cb)
 *        local memberId = data.memberId
 *        -- Sua lógica de rebaixamento aqui
 *        cb({ success = true, message = "Membro rebaixado!" })
 *    end)
 * 
 *    -- Callback para expulsar membro
 *    RegisterNUICallback('kickMember', function(data, cb)
 *        local memberId = data.memberId
 *        -- Sua lógica de expulsão aqui
 *        cb({ success = true, message = "Membro expulso!" })
 *    end)
 * 
 *    -- Callback para convidar jogador próximo
 *    RegisterNUICallback('invitePlayer', function(data, cb)
 *        -- Sua lógica para encontrar e convidar jogador próximo
 *        cb({ success = true, message = "Convite enviado!" })
 *    end)
 * 
 *    -- Callback para atualizar mural
 *    RegisterNUICallback('updateAnnouncement', function(data, cb)
 *        local announcement = data.announcement
 *        -- Salvar no banco de dados
 *        cb({ success = true, message = "Mural atualizado!" })
 *    end)
 * 
 *    -- Callback para atualizar configurações do clã
 *    RegisterNUICallback('updateClanSettings', function(data, cb)
 *        local logo = data.logo
 *        local description = data.description
 *        local roles = data.roles
 *        -- Salvar no banco de dados
 *        cb({ success = true, message = "Configurações salvas!" })
 *    end)
 * 
 *    -- Callback para fechar a NUI
 *    RegisterNUICallback('closeNui', function(data, cb)
 *        SetNuiFocus(false, false)
 *        SendNUIMessage({ action = 'setVisible', data = { visible = false } })
 *        cb('ok')
 *    end)
 *    ```
 * 
 * 2. Para abrir o painel do clã:
 * 
 *    ```lua
 *    RegisterCommand('clan', function()
 *        SetNuiFocus(true, true)
 *        SendNUIMessage({ action = 'setVisible', data = { visible = true } })
 *    end)
 *    ```
 * 
 * =============================================================================
 */

/**
 * Verifica se estamos rodando no navegador (desenvolvimento) ou no FiveM
 */
const isEnvBrowser = (): boolean => !(window as any).invokeNative;

/**
 * Envia uma requisição para o servidor FiveM
 * 
 * @param eventName - Nome do evento/callback registrado no Lua
 * @param data - Dados a serem enviados para o servidor
 * @returns Promise com a resposta do servidor
 * 
 * @example
 * ```typescript
 * // Obter dados do clã
 * const response = await fetchNui("getClanData");
 * if (response.success) {
 *   console.log(response.clan);
 * }
 * 
 * // Promover membro
 * const response = await fetchNui("promoteMember", { memberId: "123" });
 * ```
 */
export async function fetchNui<T = any>(
  eventName: string,
  data: Record<string, unknown> = {}
): Promise<T> {
  if (isEnvBrowser()) {
    // Respostas mock para desenvolvimento no navegador
    return mockNuiResponse(eventName, data) as T;
  }

  const options = {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  };

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "clan-panel";

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);
  return resp.json();
}

/**
 * Escuta mensagens enviadas do cliente FiveM (SendNUIMessage)
 * 
 * @param action - Nome da ação a escutar
 * @param handler - Função callback executada quando a ação é recebida
 * @returns Função de cleanup para remover o listener
 * 
 * @example
 * ```typescript
 * // No React component
 * useEffect(() => {
 *   const cleanup = useNuiEvent<{ visible: boolean }>("setVisible", (data) => {
 *     setIsVisible(data.visible);
 *   });
 *   return cleanup;
 * }, []);
 * ```
 * 
 * No Lua:
 * ```lua
 * SendNUIMessage({ action = 'setVisible', data = { visible = true } })
 * ```
 */
export function useNuiEvent<T = any>(
  action: string,
  handler: (data: T) => void
): () => void {
  const eventListener = (event: MessageEvent) => {
    const { action: eventAction, data } = event.data;
    if (eventAction === action) {
      handler(data);
    }
  };

  window.addEventListener("message", eventListener);
  return () => window.removeEventListener("message", eventListener);
}

/**
 * Fecha a interface NUI
 * Envia callback para o servidor que deve chamar SetNuiFocus(false, false)
 */
export function closeNui(): void {
  fetchNui("closeNui");
}

/**
 * Respostas mock para desenvolvimento no navegador
 * Remova ou modifique conforme necessário para testes
 */
function mockNuiResponse(eventName: string, data: any): any {
  console.log(`[NUI Mock] Event: ${eventName}`, data);

  const mockResponses: Record<string, any> = {
    getClanData: {
      success: true,
      clan: {
        id: "clan_001",
        name: "Los Santos Kings",
        logo: "https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?w=200&h=200&fit=crop",
        description: "Uma facção lendária dominando as ruas de Los Santos desde 2019. Lealdade, honra e família.",
        territories: 8,
        announcement: "Esta noite nós atacamos! Reunião no armazém às 21h. Presença obrigatória para todos os membros com cargo.",
      },
    },
    getMembers: {
      success: true,
      members: [
        { id: "1", name: "DarkPhoenix", avatar: "", role: "Líder", status: "online", lastLogin: "Agora" },
        { id: "2", name: "ShadowWolf", avatar: "", role: "Vice-Líder", status: "online", lastLogin: "Agora" },
        { id: "3", name: "NightRider", avatar: "", role: "Capitão", status: "online", lastLogin: "5 min" },
        { id: "4", name: "StormBreaker", avatar: "", role: "Membro", status: "offline", lastLogin: "2h" },
        { id: "5", name: "IceQueen", avatar: "", role: "Membro", status: "offline", lastLogin: "1 dia" },
        { id: "6", name: "FireStorm", avatar: "", role: "Recruta", status: "online", lastLogin: "Agora" },
        { id: "7", name: "ThunderBolt", avatar: "", role: "Membro", status: "offline", lastLogin: "3h" },
        { id: "8", name: "VenomStrike", avatar: "", role: "Recruta", status: "online", lastLogin: "10 min" },
      ],
    },
    getRoles: {
      success: true,
      roles: [
        { id: "1", name: "Líder", color: "#06b6d4", permissions: { manage_members: true, manage_roles: true, manage_clan: true, invite: true, kick: true } },
        { id: "2", name: "Vice-Líder", color: "#8b5cf6", permissions: { manage_members: true, manage_roles: false, manage_clan: false, invite: true, kick: true } },
        { id: "3", name: "Capitão", color: "#22c55e", permissions: { manage_members: false, manage_roles: false, manage_clan: false, invite: true, kick: false } },
        { id: "4", name: "Membro", color: "#64748b", permissions: { manage_members: false, manage_roles: false, manage_clan: false, invite: false, kick: false } },
        { id: "5", name: "Recruta", color: "#475569", permissions: { manage_members: false, manage_roles: false, manage_clan: false, invite: false, kick: false } },
      ],
    },
    getTerritories: {
      success: true,
      territories: [
        { id: "1", name: "Grove Street", underAttack: false, attackerName: null },
        { id: "2", name: "Vinewood Hills", underAttack: true, attackerName: "Ballas Gang" },
        { id: "3", name: "Del Perro Beach", underAttack: false, attackerName: null },
        { id: "4", name: "Rancho", underAttack: true, attackerName: "Vagos" },
        { id: "5", name: "Mirror Park", underAttack: false, attackerName: null },
      ],
    },
    goToTerritory: { success: true, message: "GPS definido para o território!" },
    dropTerritory: { success: true, message: "Território abandonado!" },
    promoteMember: { success: true, message: "Membro promovido com sucesso!" },
    demoteMember: { success: true, message: "Membro rebaixado com sucesso!" },
    kickMember: { success: true, message: "Membro expulso do clã!" },
    invitePlayer: { success: true, message: "Convite enviado!" },
    updateClanSettings: { success: true, message: "Configurações atualizadas!" },
    updateAnnouncement: { success: true, message: "Mural atualizado!" },
    deleteClan: { success: true, message: "Clã deletado com sucesso!" },
    createClan: { success: true, message: "Clã criado com sucesso!" },
    viewAvailableTerritories: { success: true, message: "Abrindo mapa de territórios..." },
    closeNui: { success: true },
  };

  return mockResponses[eventName] || { success: false, error: "Evento desconhecido" };
}

// =============================================================================
// TIPOS TYPESCRIPT
// =============================================================================

/**
 * Dados do Clã
 */
export interface ClanData {
  /** ID único do clã */
  id: string;
  /** Nome do clã */
  name: string;
  /** URL da logo do clã */
  logo: string;
  /** Descrição/bio do clã */
  description: string;
  /** Número de territórios dominados */
  territories: number;
  /** Mensagem do mural/aviso do dia */
  announcement: string;
}

/**
 * Dados de um Membro
 */
export interface Member {
  /** ID único do membro */
  id: string;
  /** Nome do jogador */
  name: string;
  /** URL do avatar (opcional) */
  avatar: string;
  /** Nome do cargo atual */
  role: string;
  /** Status de conexão */
  status: "online" | "offline";
  /** Último login (texto formatado) */
  lastLogin: string;
}

/**
 * Dados de um Cargo
 */
export interface Role {
  /** ID único do cargo */
  id: string;
  /** Nome do cargo */
  name: string;
  /** Cor hex do cargo */
  color: string;
  /** Permissões do cargo */
  permissions: RolePermissions;
}

/**
 * Permissões de um Cargo
 */
export interface RolePermissions {
  /** Pode gerenciar membros (promover/rebaixar) */
  manage_members: boolean;
  /** Pode gerenciar cargos */
  manage_roles: boolean;
  /** Pode configurar o clã */
  manage_clan: boolean;
  /** Pode convidar jogadores */
  invite: boolean;
  /** Pode expulsar membros */
  kick: boolean;
}

/**
 * Dados de um Território
 */
export interface Territory {
  /** ID único do território */
  id: string;
  /** Nome do território */
  name: string;
  /** Se o território está sob ataque */
  underAttack: boolean;
  /** Nome do atacante (se estiver sob ataque) */
  attackerName: string | null;
}

// =============================================================================
// LISTA DE CALLBACKS DISPONÍVEIS
// =============================================================================

/**
 * CALLBACKS QUE O LUA DEVE REGISTRAR:
 * 
 * | Callback            | Dados Recebidos                      | Resposta Esperada                    |
 * |---------------------|--------------------------------------|--------------------------------------|
 * | getClanData         | {}                                   | { success, clan: ClanData }          |
 * | getMembers          | {}                                   | { success, members: Member[] }       |
 * | getRoles            | {}                                   | { success, roles: Role[] }           |
 * | getTerritories      | {}                                   | { success, territories: Territory[] }|
 * | goToTerritory       | { territoryId: string }              | { success, message: string }         |
 * | dropTerritory       | { territoryId: string }              | { success, message: string }         |
 * | promoteMember       | { memberId: string }                 | { success, message: string }         |
 * | demoteMember        | { memberId: string }                 | { success, message: string }         |
 * | kickMember          | { memberId: string }                 | { success, message: string }         |
 * | invitePlayer        | {}                                   | { success, message: string }         |
 * | updateAnnouncement  | { announcement: string }             | { success, message: string }         |
 * | updateClanSettings  | { logo, description, roles }         | { success, message: string }         |
 * | closeNui            | {}                                   | qualquer                             |
 * 
 * MENSAGENS QUE O LUA PODE ENVIAR (SendNUIMessage):
 * 
 * | Action              | Dados                                | Descrição                            |
 * |---------------------|--------------------------------------|--------------------------------------|
 * | setVisible          | { visible: boolean }                 | Mostra/esconde o painel              |
 */
