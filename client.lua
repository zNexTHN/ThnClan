local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
src = Tunnel.getInterface(GetCurrentResourceName(),src)
local isNuiOpen = false

local isNuiOpen = false


local clanData = nil

local function closeUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible', data = { visible = false } })
    isNuiOpen = false
end

RegisterCommand('clan', function(source,args,rawCommand)
    local dataInfo = src.requestData()
    if dataInfo then
        clanData = dataInfo
    end
    if not isNuiOpen then        
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'setVisible', data = { visible = true } })
    else 
        closeUI()
    end
end)

RegisterNUICallback('closeNui', function(data, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('createClan', function(data,cb)
    local isCreated = src.createClan(data)
    if isCreated then
        cb({success = isCreated, message = 'O clan '..data.name..' foi criado!'})
        closeUI()
        return;
    end
    cb({success = false, message = 'Não foi possivel criar o Clã'})
end)


RegisterNUICallback('viewAvailableTerritories', function(data,cb)
    ExecuteCommand('territorios')
    cb({ success = true, message = "Territórios sendo mostrados" })
end)

RegisterNUICallback('getClanData', function(data, cb)
    if clanData then
        cb({ success = true, clan = clanData })
        return;
    end
    cb({ success = true })
end)

RegisterNUICallback('getMembers', function(data, cb)
    local members = src.requestMembers()
    if members then
        cb({ success = true, members = members })
        return;
    end
    cb({ success = false, members = {} })
end)

RegisterNUICallback('getRoles', function(data, cb)
    local roles = src.requestRoles()
    if roles then
        cb({ success = true, roles = roles })
        return 
    end
    
    cb({ success = false, roles = {} })
end)

local areasDominacao = {
    ['Area 01'] = { coords = vector3(1440.15, 1108.33, 171.14), radius = 171.14, dominada = false }
}


RegisterNUICallback('getTerritories', function(data, cb)
    local territories = src.requestZones()
    cb({ success = true, territories = territories or {} })
end)

RegisterNUICallback('goToTerritory', function(data, cb)
    local territoryId = data.territoryId
    
    local territoryCoords = {
        ["1"] = { x = 100.0, y = 200.0 },
        ["2"] = { x = 300.0, y = 400.0 },
        ["3"] = { x = 500.0, y = 600.0 }
    }
    
    local coords = territoryCoords[territoryId]
    if coords then
        SetNewWaypoint(coords.x, coords.y)
        cb({ success = true, message = "GPS definido para o território!" })
    else
        cb({ success = false, message = "Território não encontrado!" })
    end
end)

RegisterNUICallback('dropTerritory', function(data, cb)
    local territoryId = data.territoryId
    
    cb({ success = true, message = "Território abandonado!" })
end)



RegisterNUICallback('promoteMember', function(data, cb)
    local memberId = data.memberId
    cb({ success = true, message = "Membro promovido com sucesso!" })
end)

RegisterNUICallback('demoteMember', function(data, cb)
    local memberId = data.memberId
    cb({ success = true, message = "Membro rebaixado!" })
end)

RegisterNUICallback('kickMember', function(data, cb)
    local memberId = data.memberId
    local expulso = src.kickMember(memberId)
    if expulso then
        cb({ success = true, message = "Membro expulso do clã!" })
        return;
    end
    cb({ success = false, message = "Não foi possível expulsar este membro" })
end)

RegisterNUICallback('invitePlayer', function(data, cb)
    local invited = src.invitePlayer()
    
    if invited then
        cb({ success = true, message = "Convite enviado para " ..invited.."!" })
    else
        cb({ success = false, error = "Nenhum jogador próximo encontrado!" })
    end
end)

RegisterNUICallback('updateAnnouncement', function(data, cb)
    local announcement = data.announcement
    local updateAnnuncio = src.updateAnnouncement(announcement)

    if updateAnnuncio then
        cb({ success = true, message = "Mural atualizado!" })
        return
    end
    cb({ success = false, message = '' })
end)

RegisterNUICallback('updateClanSettings', function(data, cb)
    local logo = data.logo
    local description = data.description
    local roles = data.roles
    
    local updateSettings = src.updateSettings(logo,description,roles)
    if updateSettings then
        cb({ success = true, message = "Configurações salvas!" })
        return;
    end

    cb({ success = false, message = "" })
end)



local inZone = false
local currentZone = nil

CreateThread(function()
    for nome, info in pairs(activeZones) do 
        local zone = CircleZone:Create(info.coords, info.radius, {
            name = nome,
            debugPoly = false
        })

        zone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                if GetEntityHealth(PlayerPedId()) > 101 then                    
                    inZone = true
                    currentZone = nome
                    TriggerServerEvent("clan:updateZonePresence", nome, true)
                    print("Entrou em " .. nome)
                end
            else
                inZone = false
                currentZone = nil
                TriggerServerEvent("clan:updateZonePresence", nome, false)
                TriggerEvent("clan:hideWarHud")
                print("Saiu de " .. nome)
            end
        end)
    end
end)


local isDeadInZone = false

CreateThread(function()
    while true do
        local time = 1000
        if inZone and currentZone then
            time = 500
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)

            if health <= 101 and not isDeadInZone then
                isDeadInZone = true
                TriggerServerEvent("clan:playerDiedInZone", currentZone)
                TriggerEvent("Notify", "aviso", "Você foi abatido e não conta mais para a disputa!")
        
            -- elseif health > 101 and isDeadInZone then
            --    isDeadInZone = false
            --    TriggerServerEvent("clan:playerRevivedInZone", currentZone)
            end
        else
            isDeadInZone = false
        end
        Citizen.Wait(time)
    end
end)

local lastUpdated = nil 
local text = ''
RegisterNetEvent("clan:updateWarHud")
AddEventHandler("clan:updateWarHud", function(zoneName, time, attackers, defenders)
    if currentZone == zoneName then
        text = "~r~EM GUERRA: " .. time .. "s~n~Atacantes: " .. attackers .. " vs Defensores: " .. defenders
        if not lastUpdated then
            lastUpdated = GetGameTimer()
            Citizen.CreateThread(function()
                while lastUpdated do 
                    Citizen.Wait(5)
                    if (GetGameTimer() - lastUpdated) > 3500 then 
                        lastUpdated = nil 
                        text = ''
                        break;
                    end
                    DrawText2D(0.5, 0.15, text)
                end 
            end)
        end
    end
end)




RegisterNetEvent("clan:hideWarHud")
AddEventHandler("clan:hideWarHud", function()

end)

function DrawText2D(x, y, text)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end


local mostrando = false 

local blipList = {}
RegisterCommand('territorios', function()
    if not mostrando then        
        for nome,info in pairs(areasDominacao) do 
            blipList[nome] = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z)
            
            SetBlipSprite(blipList[nome], 161)
            SetBlipScale(blipList[nome], 1.2)

            if info.dominada then
                SetBlipColour(blipList[nome], 1) 
            else 
                SetBlipColour(blipList[nome], 2) 
            end
            SetBlipAsShortRange(blipList[nome], true)
            
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(nome)
            EndTextCommandSetBlipName(blipList[nome])
            mostrando = true 

            SetTimeout(25000, function()
                RemoveBlip(blipList[nome])
                TriggerEvent('Notify', 'aviso','Territórios sendo ocultos no mapa')
                mostrando = false
            end)
        end
    end
end)