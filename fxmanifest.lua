fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_script {
  'client.lua'
}

server_scripts {
  'server.lua',
  '@oxmysql/lib/MySQL.lua',
}

shared_scripts {
  'config.lua',
  "@ox_lib/init.lua",
  '@es_extended/imports.lua',
}
