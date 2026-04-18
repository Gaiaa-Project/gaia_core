fx_version 'cerulean'
game 'gta5'

author 'Chaos Studio'
description 'Gaia Core Roleplay - Framework RP'
version '0.0.1'

name 'gaia_core'

lua54 'yes'

shared_scripts {
    'shared/init.lua',
    'config/*.lua',
    'shared/lib/logs/print.lua',
    'shared/lib/timers/interval.lua',
    'shared/lib/callback/callback.lua',
}

shared_scripts {
    'shared/lib/**/*.lua',
}

client_script 'client/lib/callback/callback.lua'
server_script 'server/lib/callback/callback.lua'

client_scripts {
    'client/lib/spatial/tick.lua',
    'client/lib/streaming/streamingRequest.lua',
}

client_scripts {
    'client/lib/**/*.lua',
    'client/modules/**/*.lua',
    'client/temp_spawn.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/lib/**/*.lua',

    'server/modules/migration/sqlGenerator.lua',
    'server/modules/migration/inspector.lua',
    'server/modules/migration/main.lua',

    'server/modules/permissions/wildcards.lua',
    'server/modules/permissions/cache.lua',
    'server/modules/permissions/seed.lua',
    'server/modules/permissions/main.lua',

    'server/modules/**/*.lua',

    'server/init.lua',
}

files {
    'init.lua',
}

dependencies {
    'oxmysql',
}
