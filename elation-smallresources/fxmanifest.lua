fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'Elation'
description 'Various small code snippets compiled into one resource for ease of use'
version '1.4.0'

dependencies {
    'PolyZone',
    'qb-core',
    'progressbar'
}

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config/shared.lua',      -- Load shared config first
    'shared/config.lua',      -- Load main config
    'shared/consumables.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/ComboZone.lua',
    'bridge/target.lua',      -- Load target bridge first
    'client/*.lua'           -- Then load client scripts
}

server_scripts {
    'server/*.lua'
}

files {
    'config/*.lua',
    'bridge/*.lua',
    'relationships.dat',
    'events.meta',
    'popgroups.ymt'
}

data_file 'RELATIONSHIPS_FILE' 'relationships.dat'
data_file 'EVENTS_FILE' 'events.meta'
data_file 'FIVEM_LOVES_YOU_4B38E96CC036038F' 'events.meta'
data_file 'FIVEM_LOVES_YOU_341B23A2F0E0F131' 'popgroups.ymt'

conflict 'lusty94_consumables'
conflict 'qb-smallresources'