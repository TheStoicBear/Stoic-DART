QBCore.Functions.CreateUseableItem('dart_item', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.RemoveItem(item.name, 1, item.slot) then
    TriggerClientEvent('dart:useDart', source)
end)

QBCore.Functions.CreateUseableItem('angle_grinder_item', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.RemoveItem(item.name, 1, item.slot) then
    TriggerClientEvent('dart:useAngleGrinder', source)
end)


RegisterServerEvent('dart:firedart')
AddEventHandler('dart:firedart', function(vehicleId)
    local source = source
    -- Add logic to fire the dart and synchronize it across all players
    if vehicleId ~= nil then
        if dartTimer == 0 then
            -- Set the locked vehicle and start the timer
            local vehicle = NetworkGetEntityFromNetworkId(vehicleId)
            if vehicle ~= nil then
                lockedVehicle = vehicle
                dartTimer = Config.DartTimer -- Timer in minutes
                -- Trigger the event for all clients
                TriggerClientEvent('dart:dartFired', -1, propNetId)
            else
                -- Send error notification to the player who tried to fire the dart
                TriggerClientEvent('dart:notifyError', source, "Invalid vehicle ID.")
            end
        else
            -- Send error notification to the player who tried to fire the dart
            TriggerClientEvent('dart:notifyError', source, "Dart already fired and attached. Timer: " .. Config.DartTimer .. " minutes.")
        end
    end
end)

-- Event to synchronize blips for all players
RegisterServerEvent('dart:updateBlips')
AddEventHandler('dart:updateBlips', function(propNetId, addBlip)
    local source = source
    local prop = NetworkGetEntityFromNetworkId(propNetId)
    if prop ~= nil then
        if addBlip then
            -- Add blip for the dart
            TriggerClientEvent('dart:updateBlips', -1, propNetId, true)
        else
            -- Remove blip for the dart
            TriggerClientEvent('dart:updateBlips', -1, propNetId, false)
        end
    end
end)

RegisterServerEvent('dart:removedart')
AddEventHandler('dart:removedart', function()
    local source = source
    -- Add logic to remove the dart and synchronize it across all players
    if dartProp ~= nil then
        -- Reset the dart prop and dart timer
        local propToRemove = dartProp
        dartProp = nil
        dartTimer = 0

        -- Trigger the event for all clients to remove the dart and blips
        TriggerClientEvent('dart:dartRemoved', -1, NetworkGetNetworkIdFromEntity(propToRemove))
        TriggerClientEvent('dart:updateBlips', -1, NetworkGetNetworkIdFromEntity(propToRemove), false)
    end
end)
