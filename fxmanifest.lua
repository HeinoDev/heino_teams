fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Heino'
description 'Teams/Groups system'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/ui.lua',
    'client/main.lua',
}

server_scripts {
    'server/framework.lua',
    'server/teams.lua',
    'server/main.lua',
}

files {
    'config.lua',
    'web/build/index.html',
    'web/build/**/*',
    'locales/*.json',
}

dependencies {
    'ox_lib',
}
