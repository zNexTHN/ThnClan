activeZones = {
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
