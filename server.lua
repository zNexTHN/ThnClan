local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
src = {}
Tunnel.bindInterface(GetCurrentResourceName(),src)




local isSystemReady = promise.new()

vRP.prepare('clan/createDatabaseClans', [[
    CREATE TABLE IF NOT EXISTS `clans` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
        `logo` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
        `description` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
        `announcement` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
        `territories` INT(11) NULL DEFAULT '0',
        PRIMARY KEY (`id`) USING BTREE
    ) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
]])

vRP.prepare('clan/createDatabaseClanRoles', [[
    CREATE TABLE IF NOT EXISTS `clan_roles` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `clan_id` INT(11) NOT NULL,
        `name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
        `color` VARCHAR(20) NULL DEFAULT '#64748b' COLLATE 'utf8mb4_general_ci',
        `permissions` LONGTEXT NOT NULL COLLATE 'utf8mb4_general_ci',
        `is_leader` TINYINT(1) NULL DEFAULT '0',
        PRIMARY KEY (`id`) USING BTREE,
        INDEX `fk_clan_roles_clan` (`clan_id`) USING BTREE,
        CONSTRAINT `fk_clan_roles_ref_clan` FOREIGN KEY (`clan_id`) REFERENCES `clans` (`id`) ON UPDATE RESTRICT ON DELETE CASCADE,
        CONSTRAINT `chk_role_permissions` CHECK (json_valid(`permissions`))
    ) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
]])

vRP.prepare('clan/createDatabaseClanMembers', [[
    CREATE TABLE IF NOT EXISTS `clan_members` (
        `user_id` INT(11) NOT NULL,
        `clan_id` INT(11) NOT NULL,
        `role_id` INT(11) NOT NULL,
        `joined_at` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`user_id`) USING BTREE,
        INDEX `fk_clan_members_clan` (`clan_id`) USING BTREE,
        INDEX `fk_clan_members_role` (`role_id`) USING BTREE,
        CONSTRAINT `fk_clan_members_ref_clan` FOREIGN KEY (`clan_id`) REFERENCES `clans` (`id`) ON UPDATE RESTRICT ON DELETE CASCADE,
        CONSTRAINT `fk_clan_members_ref_role` FOREIGN KEY (`role_id`) REFERENCES `clan_roles` (`id`) ON UPDATE RESTRICT ON DELETE CASCADE
    ) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
]])

vRP.prepare('clan/createDatabaseClanTerritories', [[
    CREATE TABLE IF NOT EXISTS `clan_territories` (
        `zone_name` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
        `clan_id` INT(11) NULL DEFAULT NULL,
        `updated_at` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
        PRIMARY KEY (`zone_name`) USING BTREE
    ) COLLATE='utf8mb4_general_ci' ENGINE=InnoDB;
]])

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
vRP.prepare('clan/get_all_territories','SELECT * FROM clan_territories')
vRP.prepare('clan/createTerritories', 'INSERT INTO clan_territories (zone_name) VALUES (@zone_name)')
vRP.prepare('clan/selectTerritory', 'SELECT * FROM clan_territories WHERE zone_name  = @zone_name')


local function verifyTerritory(zone_name)
    local rows = vRP.query('clan/selectTerritory', {zone_name = zone_name})
    if #rows > 0 then
        return true 
    end
    return false
end

CreateThread(function()
    print("^3[CLAN SYSTEM] Iniciando verificação do banco de dados...^0")
    
    local createDatabases = {
        'createDatabaseClans',
        'createDatabaseClanRoles',
        'createDatabaseClanMembers', 
        'createDatabaseClanTerritories'
    }

    for _, queryName in ipairs(createDatabases) do 
        vRP.execute('clan/'..queryName)
        Citizen.Wait(200)
    end
    
    Citizen.Wait(1000)

    
    for nomeArea,v in pairs(activeZones) do 
        if not verifyTerritory(nomeArea) then
            print('^2[CLAN SYSTEM] ^0O territorio ^2'..nomeArea..' ^0foi criado com sucesso!')
            vRP.execute('clan/createTerritories', {zone_name = nomeArea})
        end
    end 

    local rows = vRP.query("clan/get_all_territories", {})
    if rows then
        for _, row in pairs(rows) do
            if activeZones and activeZones[row.zone_name] then
                activeZones[row.zone_name].owner = row.clan_id
            end
        end
    end
    
    local p = isSystemReady
    if p and type(p) ~= 'boolean' then
        p:resolve(true)
    end
    print("^2[CLAN SYSTEM] Banco de dados pronto! Sistema liberado.^0")
end)


local function hasClanPermission(user_id, perm_name)
    Citizen.Await(isSystemReady)
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

local function pushNotify(src, tipo, titulo, corpo, dur, opts)
    local d = dur or ((tipo == 'importante' or tipo == 'negado') and 8000 or 6000)
    TriggerClientEvent("Notify", src, tipo, titulo, d, corpo, opts)
end

local function buildWarNotify(zoneName, msg)
    if msg == "Território conquistado!" then
        return 'sucesso', 'Território Conquistado', 'A bandeira do clã agora tremula sobre '..zoneName..'.', {icon='flag', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'}
    end
    if string.find(msg, "Guerra iniciada!") then
        return 'importante', 'Guerra Iniciada', 'Defenda '..zoneName..' com toda a força.', {icon='shield', iconcolor='rgba(52, 152, 219, 1)', iconanimation='pulse'}
    end
    if string.find(msg, "Captura iniciada") then
        return 'importante', 'Captura Iniciada', 'Um clã iniciou uma captura em '..zoneName..'.', {icon='flag', iconcolor='rgba(241, 196, 15, 1)', iconanimation='pulse'}
    end
    if string.find(msg, "Quantidade insuficiente") then
        return 'negado', 'Força Insuficiente', 'Reúna mais membros para dominar '..zoneName..'.', {icon='users', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'}
    end
    if string.find(msg, "Ataque abandonado") then
        return 'aviso', 'Ataque Abandonado', 'Sem presença, a dominação em '..zoneName..' foi cancelada.', {icon='hourglass', iconcolor='rgba(241, 196, 15, 1)', iconanimation='pulse'}
    end
    return 'importante', zoneName, msg, {icon='info', iconcolor='rgba(255,255,255,1)', iconanimation='pulse'}
end
local function getUserClanId(user_id)
    Citizen.Await(isSystemReady)
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



local roles = (zonesConfig and zonesConfig.clanDefaults and zonesConfig.clanDefaults.roles) or {
    { name = "Líder", color = "#06b6d4", permissions = { manage_members = true, manage_roles = true, manage_clan = true, invite = true, kick = true }, isLeader = true },
    { name = "Vice-Líder", color = "#8b5cf6", permissions = { manage_members = true, manage_roles = false, manage_clan = false, invite = true, kick = true } },
    { name = "Membro", color = "#64748b", permissions = { manage_members = false, manage_roles = false, manage_clan = false, invite = false, kick = false } }
}

local createRole = function(clan_id,name,color,permissions,lider)
    local isSucess = vRP.execute("clan/createRole", { clan_id = clan_id, name = name,color = color, permissions = permissions, is_leader = lider })
    Citizen.Wait(50)
    local roleId = getRoleId(clan_id,name)
    return roleId
end


local defaultDescricao = (zonesConfig and zonesConfig.clanDefaults and zonesConfig.clanDefaults.announcementDefault) or 'Seja bem-vindo, este é o seu clãn! Faça todas as alterações necessárias'

local function getClanId(nome)
    local rows = vRP.query("clan/getClanId", { name = nome })
    if #rows > 0 then
        return rows[1]
    end 
    return false
end

src.createClan = function(data)
    local source = source
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
        pushNotify(source, 'negado', 'Sem Clã', 'Você não pertence a um clã.', nil, {icon='user-slash', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
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
        pushNotify(source, 'sucesso', 'Mural Atualizado', 'As mensagens do clã foram atualizadas.', nil, {icon='scroll', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
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
                pushNotify(source, 'sucesso', 'Cargo Criado', 'O cargo '..role.name..' foi criado.', nil, {icon='id-badge', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
            end
        end
        
        pushNotify(source, 'sucesso', 'Configurações Salvas', 'As configurações do clã foram atualizadas.', nil, {icon='cog', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
        return true 
    else
        pushNotify(source, 'negado', 'Acesso Negado', 'Você não possui permissões para esta ação.', nil, {icon='lock', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
    end
end


src.kickMember = function(targetMemberId)
    local source = source
    local user_id = vRP.getUserId(source)
    local clan_id = getUserClanId(user_id)
    local target_id = tonumber(targetMemberId)

    if clan_id and hasClanPermission(user_id, "kick") then
        if user_id == target_id then
            pushNotify(source, 'negado', 'Ação Inválida', 'Você não pode se expulsar do próprio clã.', nil, {icon='ban', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
            return
        end

        vRP.execute("clan/remove_member", { target_id = target_id, clan_id = clan_id })

        for clanName,clanInfo in pairs(activeZones) do 
            if clanInfo.capturing then
                activeZones[clanName].occupants[source] = nil
                activeZones[clanName].deadPlayers[source] = nil
            end
        end

        pushNotify(source, 'aviso', 'Expulsão Concluída', 'O membro foi removido do clã.', nil, {icon='user-minus', iconcolor='rgba(241, 196, 15, 1)', iconanimation='pulse'})
        return true
    else
        pushNotify(source, 'negado', 'Acesso Negado', 'Você não possui permissões para esta ação.', nil, {icon='lock', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
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
                pushNotify(source, 'negado', 'Convite Inválido', 'Este jogador já pertence a um clã.', nil, {icon='user-lock', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
                return false
            end
            SetTimeout(100, function()
                if vRP.request(nplayer,'Deseja entrar no clã '..clan_nome..' ?',30) then        
                    local role,roles = getRoleId(clan_id)  
                    local base_role = roles[#roles].id
        
                    vRP.execute("clan/add_member", { user_id = nuser_id, clan_id = clan_id, role_id = base_role })
                    pushNotify(source, 'sucesso', 'Recrutamento Concluído', 'O jogador foi adicionado ao clã.', nil, {icon='user-plus', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
                    pushNotify(nplayer, 'sucesso', 'Bem-vindo ao Clã', 'Você agora faz parte do clã.', nil, {icon='hands', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
                else
                    pushNotify(source, 'aviso', 'Convite Recusado', 'O jogador recusou o convite do clã.', nil, {icon='hand', iconcolor='rgba(241, 196, 15, 1)', iconanimation='pulse'})
                end
            end)
            local identity = vRP.getUserIdentity(nuser_id)
            return identity.name..' '..identity.firstname

        end
    end
    return false
end


local function isWarTime()
    local hours = os.date("*t").hour
    local wt = zonesConfig and zonesConfig.settings and zonesConfig.settings.warTime
    if wt and wt.enabled then
        return hours >= wt.startHour and hours < wt.endHour
    end
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
        if activeZones[zoneName].mortos and activeZones[zoneName].mortos[user_id] then
            TriggerClientEvent('Notify', source, 'negado','Você não pode entrar nessa guerra de clã! Você já participou e morreu.')
            return;
        end
    end

    if entered then
        activeZones[zoneName].occupants[source] = clanId or 0
        activeZones[zoneName].deadPlayers[source] = nil
        if clanId and activeZones[zoneName].cooldownByClan then
            local cd = activeZones[zoneName].cooldownByClan[clanId]
            if cd and os.time() < cd then
                local remaining = cd - os.time()
                local m = math.floor(remaining / 60)
                local s = remaining % 60
                TriggerClientEvent('Notify', source, 'aviso', 'Cooldown ativo: '..string.format('%dm %ds', m, s))
            end
        end
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

src.requestTerritoriesStatus = function()
    local territories = {}
    local user_id = vRP.getUserId(source)
    local clan_id = nil
    if user_id then
        clan_id = select(1, getUserClanId(user_id))
    end
    for nome, info in pairs(activeZones) do
        local cd = nil
        if clan_id and info.cooldownByClan then
            cd = info.cooldownByClan[clan_id]
        end
        table.insert(territories, {
            name = nome,
            owner = info.owner,
            cooldownUntil = cd
        })
    end
    return territories
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
            local health = GetEntityHealth(GetPlayerPed(source))
            if health <= 101 then
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
            local minAtt = ((zonesConfig and zonesConfig.settings and zonesConfig.settings.minAttackersNeutral) or 4)
            if (zonesConfig and zonesConfig.settings and zonesConfig.settings.debug) then minAtt = 0 end
            if attackerCount == 0 then
                resetZone(zoneName, "Ataque abandonado!")
            elseif attackerCount < minAtt then
                resetZone(zoneName, "Quantidade insuficiente de membros!")
            else
                zone.timer = zone.timer - 1
                if zone.timer <= 0 then
                    finishCapture(zoneName, zone.attackerClan)
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
    local now = os.time()
    local cdMin = (zonesConfig and zonesConfig.settings and zonesConfig.settings.cooldownMinutes) or 30
    if zone.cooldownByClan and zone.cooldownByClan[attackerId] and now < zone.cooldownByClan[attackerId] then
        return
    end
    zone.capturing = true
    zone.attackerClan = attackerId
    zone.type = type
    zone.id = guerrasId + 1
    
    if type == "neutral" then
        local tNeutral = ((zonesConfig and zonesConfig.settings and zonesConfig.settings.neutralCaptureTime) or 60)
        if (zonesConfig and zonesConfig.settings and zonesConfig.settings.debug) then tNeutral = 10 end
        zone.timer = tNeutral
        notifyZonePlayers(zoneName, "Captura iniciada por um Clã!")
        notifyZonePlayers(zoneName, "Capturando", zone.timer*1000, true)
    else
        local tHostile = ((zonesConfig and zonesConfig.settings and zonesConfig.settings.hostileCaptureTime) or 150)
        if (zonesConfig and zonesConfig.settings and zonesConfig.settings.debug) then tHostile = 15 end
        zone.timer = tHostile
        notifyClan(zone.owner, "SEU TERRITÓRIO " ..zoneName:upper().." ESTÁ SOB ATAQUE!")
        notifyZonePlayers(zoneName, "Guerra iniciada! Defenda a zona.")
    end
end

RegisterCommand('clan_reset_cooldown', function(source, args, raw)
    local isDebug = (zonesConfig and zonesConfig.settings and zonesConfig.settings.debug)
    if not isDebug then
    pushNotify(source, 'negado', 'Modo Debug Desativado', 'Ative o debug no config para usar este comando.', nil, {icon='bug', iconcolor='rgba(231, 76, 60, 1)', iconanimation='shake'})
        return
    end
    local target = args and args[1]
    local user_id = vRP.getUserId(source)
    local myClanId = nil
    if user_id then myClanId = select(1, getUserClanId(user_id)) end

    if target == 'all' or target == 'ALL' then
        for nome, info in pairs(activeZones) do
            info.cooldownByClan = {}
        end
        pushNotify(source, 'sucesso', 'Cooldown Resetado', 'Todos os cooldowns de todos os clãs foram resetados.', nil, {icon='clock', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
        return
    end

    local numClan = tonumber(target)
    if numClan then
        for nome, info in pairs(activeZones) do
            if info.cooldownByClan then
                info.cooldownByClan[numClan] = nil
            end
        end
        pushNotify(source, 'sucesso', 'Cooldown Resetado', 'Cooldown do clã #'..numClan..' resetado em todos os territórios.', nil, {icon='clock', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
        return
    end

    if target and activeZones[target] then
        local zone = activeZones[target]
        if zone.cooldownByClan and myClanId then
            zone.cooldownByClan[myClanId] = nil
            pushNotify(source, 'sucesso', 'Cooldown Resetado', 'Cooldown do seu clã em '..target..' foi resetado.', nil, {icon='clock', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
            return
        end
    end
    if myClanId then
        for nome, info in pairs(activeZones) do
            if info.cooldownByClan then info.cooldownByClan[myClanId] = nil end
        end
        pushNotify(source, 'sucesso', 'Cooldown Resetado', 'Cooldown do seu clã resetado em todos os territórios.', nil, {icon='clock', iconcolor='rgba(46, 204, 113, 1)', iconanimation='bounce'})
        return
    end
    pushNotify(source, 'aviso', 'Uso do Comando', "Informe 'all', um ID de clã, ou o nome exato da área.", nil, {icon='keyboard', iconcolor='rgba(241, 196, 15, 1)', iconanimation='pulse'})
end)


vRP.prepare('vRP/update_territory_owner','UPDATE clan_territories SET clan_id = @clan_id WHERE zone_name = @zone_name')

function finishCapture(zoneName, winnerId)
    local zone = activeZones[zoneName]
    zone.owner = winnerId

    vRP.execute("vRP/update_territory_owner", { zone_name = zoneName, clan_id = winnerId })
    
    notifyZonePlayers(zoneName, "Território conquistado!")
    resetZone(zoneName)
    local cdMin = (zonesConfig and zonesConfig.settings and zonesConfig.settings.cooldownMinutes) or 30
    zone.cooldownByClan = zone.cooldownByClan or {}
    zone.cooldownByClan[winnerId] = os.time() + (cdMin * 60)
    
    TriggerClientEvent("clan:syncBlipGlobal", -1, zoneName, winnerId)
end

function resetZone(zoneName, msg)
    if msg then notifyZonePlayers(zoneName, msg) end
    local zone = activeZones[zoneName]
    zone.capturing = false
    zone.timer = 0
    local attackerId = zone.attackerClan
    zone.attackerClan = nil
    zone.type = nil
    zone.mortos = {} 
    local cdMin = (zonesConfig and zonesConfig.settings and zonesConfig.settings.cooldownMinutes) or 30
    if attackerId then
        zone.cooldownByClan = zone.cooldownByClan or {}
        zone.cooldownByClan[attackerId] = os.time() + (cdMin * 60)
    end
    TriggerClientEvent("clan:hideWarHud", -1)
end

function notifyZonePlayers(zoneName, msg, time, isProgress)
    for src, _ in pairs(activeZones[zoneName].occupants) do
        local user_id = vRP.getUserId(src)
        if user_id then
            local clan_id,clan_nome = getUserClanId(user_id)
            if clan_id then
                if not isProgress then
                    local tipo, titulo, corpo, opts = buildWarNotify(zoneName, msg)
                    pushNotify(src, tipo, titulo, corpo, nil, opts)
                else
                    TriggerClientEvent("Progress", src, time, msg)
                end
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
        pushNotify(src, 'importante', 'Território Sob Ataque', msg, nil, {icon='shield', iconcolor='rgba(52, 152, 219, 1)', iconanimation='pulse'})
    end
end
