zonesConfig = {
    settings = {
        debug = false,
        minAttackersNeutral = 4,
        neutralCaptureTime = 60,
        hostileCaptureTime = 150,
        cooldownMinutes = 30,
        warTime = { enabled = false, startHour = 18, endHour = 23 }
    },
    clanDefaults = {
        announcementDefault = 'Seja bem-vindo, este é o seu clãn! Faça todas as alterações necessárias',
        roles = {
            {
                name = "Líder",
                color = "#06b6d4",
                permissions = { manage_members = true, manage_roles = true, manage_clan = true, invite = true, kick = true },
                isLeader = true
            },
            {
                name = "Vice-Líder",
                color = "#8b5cf6",
                permissions = { manage_members = true, manage_roles = false, manage_clan = false, invite = true, kick = true }
            },
            {
                name = "Membro",
                color = "#64748b",
                permissions = { manage_members = false, manage_roles = false, manage_clan = false, invite = false, kick = false }
            }
        }
    },
    mapBlips = {
        sprite = 161,
        scale = 1.2,
        showDurationMs = 25000,
        neutralColour = 2,
        dominatedColour = 1
    },
    zones = {
        { index = "Area 01", coords = vector3(1440.15, 1108.33, 171.14), radius = 171.14 }
    }
}

activeZones = {}

for _, z in ipairs(zonesConfig.zones) do
    local name = z.index
    activeZones[name] = {
        coords = z.coords,
        radius = z.radius,
        owner = nil,
        occupants = {},
        capturing = false,
        mortos = {},
        timer = 0,
        attackerClan = nil,
        type = nil,
        cooldownByClan = {},
        cooldownNotified = {}
    }
end
