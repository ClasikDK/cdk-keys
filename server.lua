ESX.RegisterServerCallback("cdk-keys:server:hasKey", function(source, cb, plate)
  local xPlayer = ESX.GetPlayerFromId(source)
  local identifier = xPlayer.getIdentifier()

  MySQL.Async.fetchAll('SELECT owner = @owner FROM vehicle_keys WHERE plate = @plate', {
    ['@owner'] = identifier,
    ["@plate"] = plate
  }, function(result)
    if result[1] then
      cb(true)
    else
      cb(false)
    end
  end)
end)

ESX.RegisterServerCallback("cdk-keys:server:checkKeys", function(source, cb, plate, player)
  if player == nil then
    player = source
  end
  local xPlayer = ESX.GetPlayerFromId(player)
  local identifier = xPlayer.getIdentifier()
  MySQL.Async.fetchAll('SELECT owner = @owner FROM vehicle_keys WHERE plate = @plate', {
    ['@owner'] = identifier,
    ['@plate'] = plate
  }, function(result)
    if result[1] then
      TriggerClientEvent("ox_lib:notify", player, {
        type = "error",
        description = "You already have keys to (" .. plate .. ")"
      })
      cb(true)
    else
      cb(false)
    end
  end)
end)

ESX.RegisterServerCallback("cdk-keys:server:giveKeys", function(source, cb, plate, player)
  if player == nil then
    player = source
  end
  local xPlayer = ESX.GetPlayerFromId(player)
  local identifier = xPlayer.getIdentifier()

  MySQL.Async.fetchAll('INSERT INTO vehicle_keys VALUES (@owner, @plate)', {
    ['@owner'] = identifier,
    ['@plate'] = plate
  }, function(insert)
    if insert then
      TriggerClientEvent("ox_lib:notify", player, {
        type = "inform",
        description = "You have been given keys to (" .. plate .. ")"
      })
      cb(true)
    else
      cb(false)
    end
  end)
end)

ESX.RegisterServerCallback("cdk-keys:server:removeKeys", function(source, cb, plate)
  MySQL.Async.fetchAll('DELETE FROM vehicle_keys WHERE plate = @plate', {
    ['@plate'] = plate
  }, function(delete)
    if delete then
      cb(true)
    else
      cb(false)
    end
  end)
end)

ESX.RegisterServerCallback("cdk-keys:server:getPlayersInDistance", function(source, cb, distance)
  local xPlayer = ESX.GetPlayerFromId(source)

  local playerCoords = GetEntityCoords(GetPlayerPed(source))

  local nearbyPlayers = {}

  for _, playerId in ipairs(GetPlayers()) do
    local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
    local distanceToPlayer = #(playerCoords - targetCoords)

    local xTarget = ESX.GetPlayerFromId(playerId)
    local playerName = xTarget.getName()

    if distanceToPlayer <= distance then
      table.insert(nearbyPlayers, {
        value = playerId,
        label = playerName
      })
    end
  end

  cb(nearbyPlayers)
end)

ESX.RegisterServerCallback("cdk-keys:server:hasItem", function(source, cb, item)
  local xPlayer = ESX.GetPlayerFromId(source)
  local hasItem = xPlayer.getInventoryItem(item)
  local itemName = hasItem.name

  if hasItem.count > 0 then
    cb(true)
  else
    cb(itemName)
  end
end)

ESX.RegisterServerCallback("cdk-keys:server:remItem", function(source, cb, item)
  local xPlayer = ESX.GetPlayerFromId(source)
  xPlayer.removeInventoryItem(item, 1)
end)

AddEventHandler("playerDropped", function()
  local source = source
  local xPlayer = ESX.GetPlayerFromId(source)
  local identifier = xPlayer.getIdentifier()

  MySQL.Async.fetchAll('DELETE FROM vehicle_keys WHERE owner = @owner', {
    ['@owner'] = identifier
  })
end)

AddEventHandler('onResourceStart', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    MySQL.Async.execute('DELETE FROM vehicle_keys', {})
  end
end)
