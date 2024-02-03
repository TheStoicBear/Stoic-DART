-- Define initial variables
local dartSetup = false
local dartRange = 100.0
local inRange = false
local targetVehicle = nil
local lockedVehicle = nil
local dartTimer = 0
local vehicleId = nil
local dartBlips = {}
local DARTBlip = nil

-- Detect nearby police vehicles and synchronize blips
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local playerPed = GetPlayerPed(PlayerId())

        if IsPedInAnyPoliceVehicle(playerPed, false) then
            local emergencyVehicle = GetVehiclePedIsIn(playerPed, false)
            local vehicleInFront = GetVehicleInFrontOfEntity(emergencyVehicle)
            
            if vehicleInFront ~= nil then
                targetVehicle = vehicleInFront
                inRange = true
                -- Blip addition removed from here
            else
                targetVehicle = nil
                inRange = false
            end
        end
    end
end)



-- Decrease dart timer every minute
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        
        if dartTimer > 0 then
            dartTimer = dartTimer - 1
        end
    end
end)

-- Update DART blip based on timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if dartProp ~= nil and dartTimer ~= 0 then
            local propCoords = GetEntityCoords(dartProp)

            if DARTBlip ~= nil then
                RemoveBlip(DARTBlip)
            end
            
            DARTBlip = AddBlipForCoord(propCoords.x, propCoords.y, propCoords.z)
            SetBlipSprite(DARTBlip, 794)
            SetBlipDisplay(DARTBlip, 4)
            SetBlipNameToPlayerName(DARTBlip, dartProp)
            
            if dartTimer >= 3 then
                SetBlipColour(DARTBlip, Config.BlipColors.Blue)
            elseif dartTimer == 2 then
                SetBlipColour(DARTBlip, Config.BlipColors.Orange)
            else
                SetBlipColour(DARTBlip, Config.BlipColors.Red)
            end
        elseif DARTBlip ~= nil then
            RemoveBlip(DARTBlip)
            DARTBlip = nil
        end
    end
end)

-- Function to remove a dart prop and stop tracking blips for all players
function PlayerRemoveDart()
    -- Define the animation for the welding action
    local animation = {
        dict = 'amb@world_human_welding@male@idle_a',
        clip = 'idle_a',
        duration = 10000, -- 5 seconds
    }

    -- Start the progress bar
    if lib.progressBar({
        duration = 5000, -- 5 seconds
        label = 'Removing dart',
        useWhileDead = false,
        canCancel = true,
        anim = animation,
        prop = {
            model = `tr_prop_tr_grinder_01a`,
            bone = 57005, -- Right hand bone ID
            pos = vec3(0.20, 0.05, -0.01), -- Adjust position if needed
            rot = vec3(0.0, 0.0, -25.0) -- Adjust rotation if needed
        },
    }) then
        -- This block executes when the progress bar completes
        RemovePropsWithHashAroundPlayer(-66965919)
        -- Synchronize dart removal across all players
        TriggerServerEvent('dart:removedart')
        print("Removing props with hash -66965919 around the player...")

        lib.notify({
            title = "D.A.R.T System",
            description = "Dart removed from your vehicle.",
            duration = 5000, -- Notification duration in milliseconds (5 seconds)
            position = 'top-right', -- Notification position
            type = "success", -- Notification type
            style = { 
                backgroundColor = 'black', -- Background color
                color = 'red' -- Title color (red)
            },
            icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
            iconColor = 'white', -- Icon color
            iconAnimation = 'pulse', -- Icon animation
            alignIcon = 'top', -- Icon alignment
        })
    else
        -- This block executes when the progress bar is cancelled
        print('Dart removal cancelled')
    end
end

-- Function to remove props with a specific hash around the player
function RemovePropsWithHashAroundPlayer(hash)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local maxDistance = 5.0 -- Adjust the maximum distance as needed

    -- Get nearby objects and their coordinates
    local nearbyObjects = lib.getNearbyObjects(playerCoords, maxDistance)

    -- Iterate through the found objects
    for _, objectData in ipairs(nearbyObjects) do
        local objectHandle = objectData.object
        local objectHash = GetEntityModel(objectHandle)

        -- Check if the object hash matches the specified hash
        if objectHash == hash then
            -- Check if the object is attached to any entity
            if IsEntityAttached(objectHandle) then
                -- Detach the object from its entity
                DetachEntity(objectHandle, true, true)
            end

            -- Delete the object
            DeleteEntity(objectHandle)
        end
    end
end

-- Function to fire a dart and synchronize blips for all players in police vehicles
function FireDart()
    if targetVehicle ~= nil then
        if dartTimer == 0 then
            lockedVehicle = targetVehicle
            dartTimer = Config.DartTimer -- Timer in minutes
            local vehicleMake = GetDisplayNameFromVehicleModel(GetEntityModel(lockedVehicle))
            local vehicleModel = GetLabelText(vehicleMake)
            local vehiclePlate = GetVehicleNumberPlateText(lockedVehicle)
            -- Save the vehicleId to be sent to the server
            vehicleId = NetworkGetNetworkIdFromEntity(lockedVehicle)
            -- Play front-end sound when dart is fired
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)

            -- Spawn the prop at the vehicle's left taillight
            local vehicleCoords = GetEntityCoords(lockedVehicle)
            local boneIndex = GetEntityBoneIndexByName(lockedVehicle, "taillight_l")
            local prop = CreateObject(GetHashKey("prop_scn_police_torch"), vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, true, true, true)
            AttachEntityToEntity(prop, lockedVehicle, boneIndex, 0.18, -0.10, 0.01, 80.0, 0.0, 90.0, true, true, false, true, 1, true)

            -- Store the prop ID for tracking and removal
            dartProp = prop

            -- Add the prop to the target list for removal
            local netId = NetworkGetNetworkIdFromEntity(prop)
            exports.ox_target:addEntity(netId, {
                name = "openActionMenu",
                icon = "fa-solid fa-hand-holding-heart",
                label = "Remove Dart",
                coords = propCoords,
                radius = 2.0, -- Adjust radius as needed
                canInteract = function(entity, distance, coords, name)
                    -- You can define custom conditions here if needed
                    return true
                end,
                onSelect = function(data)
                    RemoveDart()
                end
            })

            -- Notify the player with vehicle information and additional options
            lib.notify({
                id = "DartFire", -- Unique ID to prevent duplicate notifications
                title = "D.A.R.T System",
                description = "Dart fired and attached to the target vehicle.\n\nMake: " .. vehicleMake .. "\n\nModel: " .. vehicleModel .. "\n\nLicense Plate: " .. vehiclePlate,
                duration = 5000, -- Notification duration in milliseconds (5 seconds)
                position = 'top-right', -- Notification position
                type = "success", -- Notification type
                style = { 
                    backgroundColor = 'black', -- Background color
                    color = 'red' -- Title color (red)
                },
                icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
                iconColor = 'white', -- Icon color
                iconAnimation = 'pulse', -- Icon animation
                alignIcon = 'top', -- Icon alignment
            })


            


            dartBlips[lockedVehicle] = dartBlip
        else
            lib.notify({
                id = "DartFireError", -- Unique ID to prevent duplicate notifications
                title = "D.A.R.T System",
                description = "Dart already fired and attached. Timer: " .. dartTimer .. " minutes.",
                duration = 5000, -- Notification duration in milliseconds (5 seconds)
                position = 'top-right', -- Notification position
                type = "success", -- Notification type
                style = { 
                    backgroundColor = 'black', -- Background color
                    color = 'red' -- Title color (red)
                },
                icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
                iconColor = 'white', -- Icon color
                iconAnimation = 'pulse', -- Icon animation
                alignIcon = 'top', -- Icon alignment
            })
        end
    end
end



-- Toggle DART system
function TrackDart()
    dartSetup = not dartSetup
    
    if dartSetup then
        keybindEnabled = false
        lib.notify({
            title = "D.A.R.T System",
            description = "D.A.R.T system activated. Scanning for vehicles in range.",
            duration = 5000, -- Notification duration in milliseconds (5 seconds)
            position = 'top-right', -- Notification position
            type = "success", -- Notification type
            style = { 
                backgroundColor = 'black', -- Background color
                color = 'red' -- Title color (red)
            },
            icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
            iconColor = 'white', -- Icon color
            iconAnimation = 'pulse', -- Icon animation
            alignIcon = 'top', -- Icon alignment
        })
    else
        keybindEnabled = true
        lib.notify({
            title = "D.A.R.T System",
            description = "D.A.R.T system deactivated.",
            duration = 5000, -- Notification duration in milliseconds (5 seconds)
            position = 'top-right', -- Notification position
            type = "success", -- Notification type
            style = { 
                backgroundColor = 'black', -- Background color
                color = 'red' -- Title color (red)
            },
            icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
            iconColor = 'white', -- Icon color
            iconAnimation = 'pulse', -- Icon animation
            alignIcon = 'top', -- Icon alignment
        })
    end
end

-- Stop DART system
function StopDart()
    dartSetup = false
    targetVehicle = nil
    inRange = false
    lockedVehicle = nil
    dartTimer = 0
    if DARTBlip ~= nil then
        RemoveBlip(DARTBlip)
        DARTBlip = nil
    end
    keybindEnabled = true
    lib.notify({
        title = "D.A.R.T System",
        description = "D.A.R.T system stopped.",
        duration = 5000, -- Notification duration in milliseconds (5 seconds)
        position = 'top-right', -- Notification position
        type = "success", -- Notification type
        style = { 
            backgroundColor = 'black', -- Background color
            color = 'red' -- Title color (red)
        },
        icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
        iconColor = 'white', -- Icon color
        iconAnimation = 'pulse', -- Icon animation
        alignIcon = 'top', -- Icon alignment
    })
end

-- Function to remove dart and blips
function RemoveDart()
    if dartProp ~= nil then
        RemoveEntity(dartProp)
        dartProp = nil
        dartTimer = 0
        if DARTBlip ~= nil then
            RemoveBlip(DARTBlip)
            DARTBlip = nil
        end
        -- Synchronize dart removal across all players
        TriggerServerEvent('dart:removedart')

        lib.notify({
            title = "D.A.R.T System",
            description = "Dart removed from your vehicle.",
            duration = 5000, -- Notification duration in milliseconds (5 seconds)
            position = 'top-right', -- Notification position
            type = "success", -- Notification type
            style = { 
                backgroundColor = 'black', -- Background color
                color = 'red' -- Title color (red)
            },
            icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
            iconColor = 'white', -- Icon color
            iconAnimation = 'pulse', -- Icon animation
            alignIcon = 'top', -- Icon alignment
        })
    end
end

-- Event handler to remove dart blips
RegisterNetEvent('dart:removeBlips')
AddEventHandler('dart:removeBlips', function(lockedVehicle)
    if dartBlips[lockedVehicle] ~= nil then
        RemoveBlip(dartBlips[lockedVehicle])
        dartBlips[lockedVehicle] = nil
    end
end)

-- Event handler to remove dart prop and synchronize across all clients
RegisterNetEvent('dart:dartRemoved')
AddEventHandler('dart:dartRemoved', function(lockedVehicle)
    if dartBlips[lockedVehicle] ~= nil then
        RemoveBlip(dartBlips[lockedVehicle])
        dartBlips[lockedVehicle] = nil
    end
end)

-- Event handler to synchronize dart firing
RegisterNetEvent('dart:dartFired')
AddEventHandler('dart:dartFired', function(propNetId)
    inRange = true
    -- Get the dart prop using its network ID
    local prop = NetworkGetEntityFromNetworkId(propNetId)
    if prop ~= nil then
        dartProp = prop

        -- Remove existing blip if it exists
        if DARTBlip ~= nil then
            RemoveBlip(DARTBlip)
            DARTBlip = nil
        end

        -- Create blip for the fired dart
        local propCoords = GetEntityCoords(dartProp)
        DARTBlip = AddBlipForCoord(propCoords.x, propCoords.y, propCoords.z)
        SetBlipSprite(DARTBlip, 794)
        SetBlipDisplay(DARTBlip, 4)
        SetBlipNameToPlayerName(DARTBlip, dartProp)
        SetBlipColour(DARTBlip, Config.BlipColors.Blue)

        lib.notify({
            title = "D.A.R.T System",
            description = "Dart fired and attached to the target vehicle.",
            duration = 5000, -- Notification duration in milliseconds (5 seconds)
            position = 'top-right', -- Notification position
            type = "success", -- Notification type
            style = { 
                backgroundColor = 'black', -- Background color
                color = 'red' -- Title color (red)
            },
            icon = "fa-solid fa-location-crosshairs", -- Font Awesome icon
            iconColor = 'white', -- Icon color
            iconAnimation = 'pulse', -- Icon animation
            alignIcon = 'top', -- Icon alignment
        })
    end
end)

-- Event handler to synchronize blips for all players
RegisterNetEvent('dart:updateBlips')
AddEventHandler('dart:updateBlips', function(propNetId, addBlip)
    local prop = NetworkGetEntityFromNetworkId(propNetId)
    if prop ~= nil then
        if addBlip then
            -- Add blip for the dart
            local propCoords = GetEntityCoords(prop)
            local blip = AddBlipForCoord(propCoords.x, propCoords.y, propCoords.z)
            SetBlipSprite(blip, 794)
            SetBlipDisplay(blip, 4)
            SetBlipNameToPlayerName(blip, prop)
            SetBlipColour(blip, Config.BlipColors.Blue)
            dartBlips[propNetId] = blip
        else
            -- Remove blip for the dart
            if dartBlips[propNetId] ~= nil then
                RemoveBlip(dartBlips[propNetId])
                dartBlips[propNetId] = nil
            end
        end
    end
end)







-- Detect the vehicle in front of an entity
function GetVehicleInFrontOfEntity(entity)
    local coords = GetEntityCoords(entity)
    local forwardVector = GetEntityForwardVector(entity)
    local rayStart = coords + forwardVector * 1.0
    local rayEnd = coords + forwardVector * dartRange

    local rayhandle = CastRayPointToPoint(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 10, entity, 0)
    local _, _, _, _, entityHit = GetRaycastResult(rayhandle)

    if entityHit > 0 and IsEntityAVehicle(entityHit) then
        return entityHit
    else
        return nil
    end
end

-- Export functions
exports('FireDart', FireDart)
exports('TrackDart', TrackDart)
exports('StopDart', StopDart)
exports('RemoveDart', RemoveDart)
exports("PlayerRemoveDart", PlayerRemoveDart)