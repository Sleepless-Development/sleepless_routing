fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'sleepless_routing'
author 'DemiAutomatic'
description 'Named routing buckets and replicated player bucket state'
version '1.0.1'

server_only 'yes'

server_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'server/version.lua',
    'server/main.lua',
}

dependency 'ox_lib'
