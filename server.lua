local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)


local activeZones = {
    ['Area 01'] = { 
        coords = vector3(1440.15, 1108.33, 171.14), 
        radius = 171.14, 
        owner = nil, -- ID do clã dono (nil se neutro)
        occupants = {}, -- Lista de players dentro { source = clanId }
        capturing = false, -- Se está ocorrendo captura
        mortos = {},
        timer = 0,
        attackerClan = nil,
        type = nil -- "neutral" ou "hostile"
    }
}


vRP.prepare("clan/get_user_clan", "SELECT m.clan_id, m.role_id, c.name, c.logo, c.description, c.announcement, c.territories FROM clan_members m JOIN clans c ON m.clan_id = c.id WHERE m.user_id = @user_id")
vRP.prepare("clan/get_members", "SELECT m.user_id, m.role_id, r.name as role_name, m.joined_at FROM clan_members m JOIN clan_roles r ON m.role_id = r.id WHERE m.clan_id = @clan_id")
vRP.prepare("clan/get_roles", "SELECT * FROM clan_roles WHERE clan_id = @clan_id AND name = @name")
vRP.prepare("clan/get_role", "SELECT * FROM clan_roles WHERE clan_id = @clan_id")
vRP.prepare("clan/get_roleFromId", "SELECT * FROM clan_roles WHERE id = @role_id")
vRP.prepare("clan/get_role_permissions", "SELECT permissions FROM clan_roles WHERE id = @role_id")

vRP.prepare("clan/update_announcement", "UPDATE clans SET announcement = @announcement WHERE id = @clan_id")
vRP.prepare("clan/update_settings", "UPDATE clans SET logo = @logo, description = @desc WHERE id = @clan_id")
vRP.prepare("clan/update_role", "UPDATE clan_roles SET name = @name, color = @color, permissions = @permissions WHERE id = @role_id AND clan_id = @clan_id")
vRP.prepare("clan/add_member", "INSERT INTO clan_members (user_id, clan_id, role_id) VALUES (@user_id, @clan_id, @role_id)")
vRP.prepare("clan/remove_member", "DELETE FROM clan_members WHERE user_id = @target_id AND clan_id = @clan_id")
vRP.prepare("clan/update_member_role", "UPDATE clan_members SET role_id = @role_id WHERE user_id = @target_id AND clan_id = @clan_id")
vRP.prepare("clan/createClan", 'INSERT INTO clans (name, logo, description, announcement) VALUES (@nome,@logo,@descricao,@anuncio)')
vRP.prepare("clan/getClanId", 'SELECT id FROM clans WHERE name = @name')
vRP.prepare("clan/getClanById", 'SELECT * FROM clans WHERE id = @clan_id')
vRP.prepare('clan/createRole', 'INSERT INTO clan_roles (clan_id, name,color, permissions, is_leader) VALUES (@clan_id,@name,@color,@permissions,@is_leader)')





local function hasClanPermission(user_id, perm_name)
    local rows = vRP.query("clan/get_user_clan", { user_id = user_id })
    if #rows > 0 then
        local role_id = rows[1].role_id
        local role_rows = vRP.query("clan/get_role_permissions", { role_id = role_id })
        if #role_rows > 0 then
            local perms = json.decode(role_rows[1].permissions)
            return perms[perm_name] == true
        end
    end
    return false
end

local function getUserClanId(user_id)
    local rows = vRP.query("clan/get_user_clan", { user_id = user_id })
    if #rows > 0 then return rows[1].clan_id,rows[1].name end
    return nil
end

local function getRoleId(clan_id,name)
    local rows = {}
    if name then
        rows = vRP.query("clan/get_roles", { clan_id = clan_id, name = name })
    else 
        rows = vRP.query("clan/get_role", { clan_id = clan_id })
    end
    if #rows > 0 then
        return rows[1],rows
    end
end



local roles = {
    {
        id = "1",
        name = "Líder",
        color = "#06b6d4",
        permissions = {
            manage_members = true,
            manage_roles = true,
            manage_clan = true,
            invite = true,
            kick = true
        },
        isLeader = true
    },
    {
        id = "2",
        name = "Vice-Líder",
        color = "#8b5cf6",
        permissions = {
            manage_members = true,
            manage_roles = false,
            manage_clan = false,
            invite = true,
            kick = true
        }
    },
    {
        id = "3",
        name = "Membro",
        color = "#64748b",
        permissions = {
            manage_members = false,
            manage_roles = false,
            manage_clan = false,
            invite = false,
            kick = false
        }
    }
}

local createRole = function(clan_id,name,color,permissions,lider)
    local isSucess = vRP.execute("clan/createRole", { clan_id = clan_id, name = name,color = color, permissions = permissions, is_leader = lider })
    Citizen.Wait(50)
    local roleId = getRoleId(clan_id,name)
    return roleId
end


local defaultDescricao = 'Seja bem-vindo, este é o seu clãn! Faça todas as alterações necessárias'


local function getClanId(nome)
    local rows = vRP.query("clan/getClanId", { name = nome })
    if #rows > 0 then
        return rows[1]
    end 
    return false
end

src.createClan = function(data)
    local user_id = vRP.getUserId(source)
    if user_id then        
        if data.name and data.logo and data.description then
            if not getClanId(data.name) then                
                vRP.execute("clan/createClan", { nome = data.name, logo = data.logo, descricao = data.description, anuncio = defaultDescricao })
                Citizen.Wait(200)
                local clanId = getClanId(data.name)
                if clanId then
                    for k,info in pairs(roles) do 
                        local id = createRole(clanId.id,info.name,info.color,json.encode(info.permissions),info.isLeader or 0)
                        if info.isLeader then
                            vRP.execute('clan/add_member', {user_id = user_id, clan_id = clanId.id, role_id = id.id })
                        end
                    end
                    return true
                end
            end
        end
    end
    return false 
end




src.requestData = function()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    local rows = vRP.query("clan/get_user_clan", { user_id = user_id })
    
    if #rows > 0 then
        local clanData = {
            id = tostring(rows[1].clan_id),
            name = rows[1].name,
            logo = rows[1].logo,
            description = rows[1].description,
            territories = rows[1].territories,
            announcement = rows[1].announcement
        }
        return clanData
    else
        TriggerClientEvent("Notify", source, "negado", "Você não pertence a um clã.")
    end
end

src.requestMembers = function()
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)

    if clan_id then
        local db_members = vRP.query("clan/get_members", { clan_id = clan_id })
        local membersList = {}

        for _, m in pairs(db_members) do
            local m_source = vRP.getUserSource(m.user_id)
            local identity = vRP.getUserIdentity(m.user_id)
            local status = (m_source ~= nil) and "online" or "offline"
            local playerName = "Desconhecido"
            
            if identity then
                playerName = identity.name .. " " .. identity.firstname
            end

            table.insert(membersList, {
                id = tostring(m.user_id),
                name = playerName,
                avatar = "",
                role = m.role_name,
                status = status,
                lastLogin = "N/A"
            })
        end
        return membersList
    end
end

src.requestRoles = function()
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)

    if clan_id then
        local db_roles = vRP.query("clan/get_role", { clan_id = clan_id })
        local rolesList = {}

        for _, r in pairs(db_roles) do
            table.insert(rolesList, {
                id = tostring(r.id),
                name = r.name,
                color = r.color,
                permissions = json.decode(r.permissions)
            })
        end
        return rolesList
    end
end

src.updateAnnouncement = function(text)
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)

    if clan_id and hasClanPermission(user_id, "manage_clan") then 
        vRP.execute("clan/update_announcement", { announcement = text, clan_id = clan_id })
        TriggerClientEvent("Notify", source, "sucesso", "Mural atualizado.")
        return true
    end
    return false
end

local function getRole(role)
    local rows = vRP.query("clan/get_roleFromId", { role_id = role })
    if #rows > 0 then
        return rows[1]
    end
end

src.updateSettings =  function(logo, description, roles)
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)

    if clan_id and hasClanPermission(user_id, "manage_clan") then
        vRP.execute("clan/update_settings", { logo = logo, desc = description, clan_id = clan_id })

        for _, role in pairs(roles) do
            local permJson = json.encode(role.permissions)
            if getRole(role.id) then                
                vRP.execute("clan/update_role", { 
                    name = role.name, 
                    color = role.color, 
                    permissions = permJson,
                    role_id = tonumber(role.id),
                    clan_id = clan_id
                })
            else
                createRole(clan_id,role.name,permJson,0)
                TriggerClientEvent("Notify", source, "sucesso", "Novo grupo "..role.name..' criado!')
            end
        end
        
        TriggerClientEvent("Notify", source, "sucesso", "Configurações salvas.")
        return true 
    else
        TriggerClientEvent("Notify", source, "negado", "Sem permissão.")
    end
end


src.kickMember = function(targetMemberId)
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)
    local target_id = tonumber(targetMemberId)

    if clan_id and hasClanPermission(user_id, "kick") then
        if user_id == target_id then
            TriggerClientEvent("Notify", source, "negado", "Você não pode se expulsar.")
            return
        end

        vRP.execute("clan/remove_member", { target_id = target_id, clan_id = clan_id })

        for clanName,clanInfo in pairs(activeZones) do 
            if clanInfo.capturing then
                activeZones[clanName].occupants[source] = nil
                activeZones[clanName].deadPlayers[source] = nil
            end
        end

        TriggerClientEvent("Notify", source, "sucesso", "Membro expulso.")
        return true
    else
        TriggerClientEvent("Notify", source, "negado", "Sem permissão.")
    end
end

src.invitePlayer = function()
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id,clan_nome = getUserClanId(user_id)
    
    if clan_id and hasClanPermission(user_id, "invite") then
        local nplayer = vRPclient.getNearestPlayer(source,2)
        if nplayer then
            local nuser_id = vRP.getUserId(nplayer)
            local target_clan = getUserClanId(nuser_id)
            if target_clan then
                TriggerClientEvent("Notify", source, "negado", "Este jogador já tem um clã.")
                return false
            end
            SetTimeout(100, function()
                if vRP.request(nplayer,'Deseja entrar no clã '..clan_nome..' ?',30) then        
                    local role,roles = getRoleId(clan_id)  
                    local base_role = roles[#roles].id
        
                    vRP.execute("clan/add_member", { user_id = nuser_id, clan_id = clan_id, role_id = base_role })
                    TriggerClientEvent("Notify", source, "sucesso", "Jogador recrutado!")
                    TriggerClientEvent("Notify", nplayer, "sucesso", "Você entrou no clã!")
                else
                    TriggerClientEvent("Notify", source, "sucesso", "Jogador recusou o convite do clã!")
                end
            end)
            local identity = vRP.getUserIdentity(nuser_id)
            return identity.name..' '..identity.firstname

        end
    end
    return false
end




vRP.prepare('vRP/get_all_territories','SELECT * FROM clan_territories')

CreateThread(function()
    local rows = vRP.query("vRP/get_all_territories", {})
    for _, row in pairs(rows) do
        if activeZones[row.zone_name] then
            activeZones[row.zone_name].owner = row.clan_id
        end
    end
end)

local function isWarTime()
    local hours = os.date("*t").hour
    return true
end


RegisterNetEvent("clan:playerDiedInZone")
AddEventHandler("clan:playerDiedInZone", function(zoneName)
    local source = source
    if activeZones[zoneName] then
        activeZones[zoneName].deadPlayers[source] = true
        manageZoneLogic(zoneName, activeZones[zoneName])
    end
end)

RegisterNetEvent("clan:updateZonePresence")
AddEventHandler("clan:updateZonePresence", function(zoneName, entered)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id or not activeZones[zoneName] then return end

    local clanId, _ = getUserClanId(user_id)
    if not activeZones[zoneName].deadPlayers then
        activeZones[zoneName].deadPlayers = {}
    end 

    if activeZones[zoneName].capturing and entered then
        if activeZones[zoneName].mortos[user_id] then
            TriggerClientEvent('Notify', source, 'negado','Você não pode entrar nessa guerra de clã! Você já participou e morreu.')
            return;
        end
    end

    if entered then
        activeZones[zoneName].occupants[source] = clanId or 0
        activeZones[zoneName].deadPlayers[source] = nil
    else
        activeZones[zoneName].occupants[source] = nil
        activeZones[zoneName].deadPlayers[source] = nil
    end
    
    TriggerClientEvent("clan:syncBlip", source, zoneName, activeZones[zoneName].owner)
end)

CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isWarTime() then
            for zoneName, zoneData in pairs(activeZones) do
                manageZoneLogic(zoneName, zoneData)
            end
        else
            for zoneName, zoneData in pairs(activeZones) do
                if zoneData.capturing then
                    resetZone(zoneName)
                end
            end
        end
    end
end)

local sourceDropped = {}
AddEventHandler('onPlayerDropped', function(reason,resourceName,clientDropReason)
    local source = source 
    local user_id = vRP.getUserId(source)
    sourceDropped[source] = user_id
end)

local function getUserById(clan_id)
    local rows = vRP.query("clan/getClanById", { clan_id = clan_id })
    if #rows > 0 then
        return rows[1]
    end
    return false
end

src.requestZones = function()
    local user_id = vRP.getUserId(source)
    if user_id then
        local clan_id,clan_nome = getUserClanId(user_id)
        if clan_id then
            local zones = {}
            
            for nome,info in pairs(activeZones) do
                if info.owner == clan_id then                    
                    local attackerName = nil 
                    if info.capturing then
                        local clanInfo = getUserById(info.attackerClan)
                        if clanInfo then
                            attackerName = clanInfo.name
                        end
                    end
                    
    
                    local dadosZone = {
                        id = #zones + 1,
                        name = nome,
                        underAttack = info.capturing,
                        attackerName = attackerName
                    }
                    table.insert(zones,dadosZone)
                end
            end
            return zones
        end
    end
end

function manageZoneLogic(zoneName, zone)
    local clanCounts = {}
    local totalPlayers = 0
    
    for src, clanId in pairs(zone.occupants) do
        if clanId ~= 0 then
            clanCounts[clanId] = (clanCounts[clanId] or 0) + 1
        end
        totalPlayers = totalPlayers + 1
    end
    
    if zone.capturing then
        for source,clanID in pairs(zone.occupants) do 
            if GetEntityHealth(GetPlayerPed(source)) <= 101 then
                local user_id = vRP.getUserId(source)
                if user_id then
                    activeZones[zoneName].mortos[user_id] = true
                end
                activeZones[zoneName].occupants[source] = nil
                activeZones[zoneName].deadPlayers[source] = nil
                TriggerClientEvent('Notify', source, 'verde','Você morreu, não está mais contabilizando na guerra!')
            end
            if sourceDropped[source] then
                activeZones[zoneName].occupants[source] = nil
                activeZones[zoneName].deadPlayers[source] = nil
                SetTimeout(5000, function()
                    sourceDropped[source] = nil
                end)
            end
        end
    end


    if not zone.owner then
        if not zone.capturing then
            for clanId, count in pairs(clanCounts) do
                if count >= 1 then
                    startCapture(zoneName, clanId, "neutral")
                    break
                end
            end
        else
            local attackerCount = clanCounts[zone.attackerClan] or 0
            if attackerCount < 4 then
                resetZone(zoneName, "Quantidade insuficiente de membros!")
            else
                zone.timer = zone.timer - 1
                if zone.timer <= 0 then
                    finishCapture(zoneName, zone.attackerClan)
                else
                    notifyZonePlayers(zoneName, "Capturando: " .. zone.timer .. "s")
                end
            end
        end
    else
        if not zone.capturing then
            for clanId, count in pairs(clanCounts) do
                if clanId ~= zone.owner and count > 0 then
                    startCapture(zoneName, clanId, "hostile")
                    break
                end
            end
        else
            local attackers = clanCounts[zone.attackerClan] or 0
            local defenders = clanCounts[zone.owner] or 0

            if attackers == 0 then
                resetZone(zoneName, "Ataque repelido pelos defensores!")
                return
            end

            zone.timer = zone.timer - 1
            if zone.timer <= 0 then
                finishCapture(zoneName, zone.attackerClan)
            else
                 TriggerClientEvent("clan:updateWarHud", -1, zoneName, zone.timer, attackers, defenders)
            end
        end
    end
end

local guerrasId = 0

function startCapture(zoneName, attackerId, type)
    local zone = activeZones[zoneName]
    zone.capturing = true
    zone.attackerClan = attackerId
    zone.type = type
    zone.id = guerrasId + 1
    
    if type == "neutral" then
        zone.timer = 60 -- Exemplo: 60s para neutro
        notifyZonePlayers(zoneName, "Captura iniciada por um Clã!")
    else
        zone.timer = 150 
        notifyClan(zone.owner, "SEU TERRITÓRIO " ..zoneName:upper().." ESTÁ SOB ATAQUE!")
        notifyZonePlayers(zoneName, "Guerra iniciada! Defenda a zona.")
    end
end


vRP.prepare('vRP/update_territory_owner','UPDATE clan_territories SET clan_id = @clan_id WHERE zone_name = @zone_name')

function finishCapture(zoneName, winnerId)
    local zone = activeZones[zoneName]
    zone.owner = winnerId

    vRP.execute("vRP/update_territory_owner", { zone_name = zoneName, clan_id = winnerId })
    
    notifyZonePlayers(zoneName, "Território conquistado!")
    resetZone(zoneName)
    
    TriggerClientEvent("clan:syncBlipGlobal", -1, zoneName, winnerId)
end

function resetZone(zoneName, msg)
    if msg then notifyZonePlayers(zoneName, msg) end
    local zone = activeZones[zoneName]
    zone.capturing = false
    zone.timer = 0
    zone.attackerClan = nil
    zone.type = nil
    zone.mortos = nil 
    TriggerClientEvent("clan:hideWarHud", -1)
end

function notifyZonePlayers(zoneName, msg)
    for src, _ in pairs(activeZones[zoneName].occupants) do
        local user_id = vRP.getUserId(src)
        if user_id then
            local clan_id,clan_nome = getUserClanId(user_id)
            if clan_id then
                TriggerClientEvent("Notify", src, "sucesso", msg)
            end
        end
    end
end

local getUsersByClanId = function(clan_id)
    local db_members = vRP.query("clan/get_members", { clan_id = clan_id })
    local membersList = {}
    if #db_members > 0 then
        for _, m in pairs(db_members) do
            local m_source = vRP.getUserSource(m.user_id)
            if m_source then
                table.insert(membersList, m_source)
            end
        end
    end
    return membersList
end

function notifyClan(clanId, msg)
    local members = getUsersByClanId(clanId)
    for _, src in pairs(members) do
        TriggerClientEvent("Notify", src, "importante", msg)
    end
end