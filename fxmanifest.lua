fx_version 'cerulean'
game 'gta5'
version "0.0.2"
author "Stoic-Bear"
description " Stoic-D.A.R.T system"
lua54 'yes'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}

client_script 'source/client.lua'
server_script 'source/server.lua'
