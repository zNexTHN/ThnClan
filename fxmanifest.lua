shared_script "@ThnAC/natives.lua"
fx_version 'cerulean'
game 'gta5'

author 'zNex'
description 'Painel de Gestão de Clã'
version '1.0.0'

ui_page 'web/dist/index.html'


files {
    'web/dist/index.html',
    'web/dist/assets/**/*'
}

shared_script 'config_areas.lua'

client_scripts {
    "@vrp/lib/utils.lua",
    '@PolyZone/client.lua',
    '@PolyZone/CircleZone.lua',
    'client.lua',
}

server_scripts {
    "@vrp/lib/utils.lua",
    "server.lua"

}