CreateThread(function()
    lib.requestAnimDict(Config.LockpickAnim.Dict)
    lib.requestAnimDict(Config.HotwireAnim.Dict)
    lib.requestAnimDict("anim@mp_player_intmenu@key_fob@")

    lib.registerRadial({
        id = "vehicle-options",
        items = {
            {
                icon = "fas fa-key",
                label = "Give Keys",
                onSelect = function()
                    TriggerEvent("cdk-keys:client:giveKeys")
                end
            },
            {
                icon = "fas fa-microchip",
                label = "Hotwire",
                onSelect = function()
                    hotwireVehicle()
                end
            }
        }
    })

    lib.addRadialItem({
        {
            id = 'vehicle-options',
            label = 'Vehicle Options',
            icon = 'car',
            menu = 'vehicle-options'
        },
    })

    exports.ox_target:addGlobalVehicle({
        icon = "fas fa-key",
        label = "Lockpick Vehicle",
        onSelect = function(data)
            lockpickVehicle(data.entity)
        end
    })

    while true do
        Wait(300)

        local playerPed = PlayerPedId()
        local enteringVeh = GetVehiclePedIsEntering(playerPed)

        if DoesEntityExist(enteringVeh) then
            SetVehicleNeedsToBeHotwired(enteringVeh, false)
        end

        if IsPedInAnyVehicle(playerPed, true) then
            local veh = GetVehiclePedIsIn(playerPed, false)
            local driver = GetPedInVehicleSeat(veh, -1)

            if driver == playerPed then
                ESX.TriggerServerCallback("cdk-keys:server:hasKey", function(hasKey)
                    if not hasKey then
                        SetVehicleEngineOn(veh, false, true, true)
                    end
                end, GetVehicleNumberPlateText(veh))
            end
        end
    end
end)

RegisterNetEvent("cdk-keys:client:giveKeys")
AddEventHandler("cdk-keys:client:giveKeys", function(plate)
    ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
        if not cb then
            ESX.TriggerServerCallback("cdk-keys:server:giveKeys", function(cb)
            end, plate)
        end
    end, plate)
end)

RegisterNetEvent("cdk-keys:client:shareKeys")
AddEventHandler("cdk-keys:client:shareKeys", function(source, input)
    local ped = PlayerPedId()
    local closestVeh = GetClosestVehicle(GetEntityCoords(ped), 3.0, 0, 70)
    local plate = GetVehicleNumberPlateText(closestVeh)

    if IsPedInAnyVehicle(ped, false) then
        plate = GetVehicleNumberPlateText(GetVehiclePedIsIn(ped, false))
    elseif closestVeh == 0 then
        lib.notify({
            type = "error",
            description = "No vehicle nearby"
        })
        return
    end

    ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
        if cb then
            ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
                if not cb then
                    ESX.TriggerServerCallback("cdk-keys:server:giveKeys", function(cb)
                        if cb then
                            lib.notify({
                                type = "inform",
                                description = "You gave keys out to (" .. plate .. ")"
                            })
                        end
                    end, plate, target)
                else
                    lib.notify({
                        type = "error",
                        description = "Player already have keys to (" .. plate .. ")"
                    })
                end
            end, plate, target)
        else
            lib.notify({
                type = "error",
                description = "You do not have keys to (" .. plate .. ") to share"
            })
        end
    end, plate)
end)

RegisterCommand("givekeys", function(source)
    ESX.TriggerServerCallback("cdk-keys:server:getPlayersInDistance", function(players)
        if #players == 0 then
            lib.notify({
                type = "error",
                description = "No players nearby"
            })
            return
        end

        local input = lib.inputDialog("Give Keys", {
            { type = "select", label = "Player", options = players }
        })
        if input then
            print(input[1])
            TriggerEvent("cdk-keys:client:shareKeys", input[1])
        end
    end, 50.0)
end)

if Config.Debug then
    RegisterCommand("unlock", function()
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local closestVeh = GetClosestVehicle(pedCoords.x, pedCoords.y, pedCoords.z, 3.0, 0, 70)

        if not DoesEntityExist(closestVeh) then
            TriggerEvent('chat:addMessage', {
                args = { "No vehicle nearby" }
            })
            return
        end

        SetVehicleDoorsLocked(closestVeh, 0)
        TriggerEvent('chat:addMessage', {
            args = { "Vehicle unlocked" }
        })
    end, false)
end


RegisterNetEvent("cdk-keys:client:spawnKeys")
AddEventHandler("cdk-keys:client:spawnKeys", function(plate)
    print(plate)
    ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
        if not cb then
            ESX.TriggerServerCallback("cdk-keys:server:giveKeys", function(cb)
            end, plate)
        end
    end, plate)
end)

RegisterNetEvent("cdk-keys:client:removeKeys", function(plate)
    ESX.TriggerServerCallback("cdk-keys:server:removeKeys", function(cb)
        if cb then
            if Config.Debug then
                lib.notify({
                    type = "inform",
                    description = "All keys to (" .. plate .. ") have been removed"
                })
            end
        end
    end, plate)
end)


function lockpickVehicle(veh)
    if GetVehicleDoorLockStatus(veh) <= 1 then
        lib.notify({
            type = "error",
            description = "Vehicle is already unlocked"
        })
        return
    end

    ESX.TriggerServerCallback("cdk-keys:server:hasItem", function(cb)
        if cb == true then
            ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
                if not cb then
                    TaskPlayAnim(PlayerPedId(), Config.LockpickAnim.Dict, Config.LockpickAnim.Name, 8.0, 8.0, -1,
                        Config.LockpickAnim.Flags, 0, false, false, false)
                    local success = lib.skillCheck(Config.LockpickDifficulty, { '1', '2', '3', '4' })
                    if success then
                        ClearPedTasksImmediately(PlayerPedId())
                        SetVehicleDoorsLocked(veh, 1)
                        lib.notify({
                            type = "success",
                            description = "You lockpicked the vehicle"
                        })
                    else
                        local randomNumber = math.random(1, 100)
                        ClearPedTasksImmediately(PlayerPedId())
                        lib.notify({
                            type = "error",
                            description = "Lockpick failed"
                        })
                        if randomNumber <= Config.LockpickDestroyChance then
                            ESX.TriggerServerCallback("cdk-keys:server:remItem", function(cb)
                            end, Config.LockpickItem)
                        end
                    end
                end
            end, plate)
        else
            lib.notify({
                type = "error",
                description = "You need a " .. cb
            })
        end
    end, Config.LockpickItem)
end

function hotwireVehicle()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        ESX.TriggerServerCallback("cdk-keys:server:checkKeys", function(cb)
            if not cb then
                TaskPlayAnim(PlayerPedId(), Config.HotwireAnim.Dict, Config.HotwireAnim.Name, 8.0, 8.0, -1,
                    Config.HotwireAnim.Flags, 0, false, false, false)
                local success1 = lib.skillCheck(Config.HotwireDifficulty[1], { '1', '2', '3', '4' })
                if success1 then
                    if lib.progressCircle({
                            duration = Config.HotwireTime,
                            label = "Hotwiring"
                        }) then
                        local success2 = lib.skillCheck(Config.HotwireDifficulty[2], { '1', '2', '3', '4' })
                        if success2 then
                            if lib.progressCircle({
                                    duration = Config.HotwireTime,
                                    label = "Hotwiring"
                                }) then
                                local success3 = lib.skillCheck(Config.HotwireDifficulty[3], { '1', '2', '3', '4' })
                                if success3 then
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    ClearPedTasks(PlayerPedId())
                                    TriggerEvent("cdk-keys:client:giveKeys", GetVehicleNumberPlateText(vehicle))
                                else
                                    ClearPedTasks(PlayerPedId())
                                    lib.notify({
                                        type = "error",
                                        description = "Hotwire failed"
                                    })
                                end
                            else
                                ClearPedTasks(PlayerPedId())
                                lib.notify({
                                    type = "error",
                                    description = "Hotwire failed"
                                })
                            end
                        else
                            ClearPedTasks(PlayerPedId())
                            lib.notify({
                                type = "error",
                                description = "Hotwire failed"
                            })
                        end
                    else
                        ClearPedTasks(PlayerPedId())
                        lib.notify({
                            type = "error",
                            description = "Hotwire failed"
                        })
                    end
                else
                    ClearPedTasks(PlayerPedId())
                    lib.notify({
                        type = "error",
                        description = "Hotwire failed"
                    })
                end
            end
        end, GetVehicleNumberPlateText(vehicle))
    else
        lib.notify({
            type = "error",
            description = "You are not in a vehicle"
        })
    end
end

function toggleLock(veh)
    local vehPlate = GetVehicleNumberPlateText(veh)
    print("Plate: " .. vehPlate)
    local lockStatus = GetVehicleDoorLockStatus(veh)
    print("Lock status: " .. lockStatus)

    ESX.TriggerServerCallback("cdk-keys:server:hasKey", function(cb)
        if cb then
            if lockStatus <= 1 then
                SetVehicleDoorsLocked(veh, 2)
                SetVehicleDoorsShut(veh, false)
                TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 12.0, 12.0, -1, 48, 1,
                    false,
                    false,
                    false)
                PlaySoundFromEntity(-1, "Remote_Control_Open", veh, "PI_Menu_Sounds", 1, 0)
                lib.notify({
                    type = "inform",
                    description = "Vehicle locked"
                })
            elseif lockStatus == 2 then
                SetVehicleDoorsLocked(veh, 1)
                TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 12.0, 12.0, -1, 48, 1,
                    false,
                    false,
                    false)
                PlaySoundFromEntity(-1, "Remote_Control_Close", veh, "PI_Menu_Sounds", 1, 0)
                lib.notify({
                    type = "inform",
                    description = "Vehicle unlocked"
                })
            end
        else
            lib.notify({
                type = "error",
                description = "You do not have keys to this vehicle"
            })
        end
    end, vehPlate)
end

RegisterCommand("lock", function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        toggleLock(GetVehiclePedIsIn(PlayerPedId(), false))
    else
        local playerPed = PlayerPedId()
        local veh = GetClosestVehicle(GetEntityCoords(playerPed), 6.0, 0, 70)
        local policeVeh = GetClosestVehicle(GetEntityCoords(playerPed), 6.0, 0, 127)

        if DoesEntityExist(veh) then
            toggleLock(veh)
        else
            if DoesEntityExist(policeVeh) then
                toggleLock(policeVeh)
            else
                lib.notify({
                    type = "error",
                    description = "No vehicle nearby"
                })
            end
        end
    end
end)

RegisterKeyMapping("lock", "Lock/Unlock Vehicle", "keyboard", "L")

RegisterCommand("engine", function()
    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, false)

    if veh and veh ~= 0 then
        local isVehRunning = GetIsVehicleEngineRunning(veh)

        if isVehRunning then
            SetVehicleEngineOn(veh, false, false, true)
            lib.notify({
                type = "inform",
                description = "Vehicle engine stopped"
            })
        else
            ESX.TriggerServerCallback("cdk-keys:server:hasKey", function(hasKey)
                if hasKey then
                    SetVehicleEngineOn(veh, true, false, true)
                    lib.notify({
                        type = "inform",
                        description = "Vehicle engine started"
                    })
                else
                    lib.notify({
                        type = "error",
                        description = "You do not have keys to this vehicle"
                    })
                end
            end, GetVehicleNumberPlateText(veh))
        end
    else
        lib.notify({
            type = "error",
            description = "You are not in a vehicle"
        })
    end
end)

RegisterKeyMapping("engine", "Turn on/of Engine", "keyboard", "K")
