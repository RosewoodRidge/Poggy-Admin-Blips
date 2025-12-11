--================================--
--        CONFIGURATION           --
--================================--

-- Debug: Set to true to enable debug logging
local DEBUG = false

-- Whitelist: Only these Steam Names (Display Names) can see blips
local ALLOWED_NAMES = {
    "Soup",
    "Poggy"
}

-- Blip appearance
local BLIP_STYLE = "BLIP_STYLE_ENEMY"           -- Style hash for creating the blip
local BLIP_SPRITE = "blip_ambient_companion"    -- Sprite/icon for the blip
local BLIP_MODIFIER = "BLIP_MODIFIER_DEBUG_GREEN" -- Color modifier (green)

-- Blip name format: Use {id} and {name} as placeholders
local BLIP_NAME_FORMAT = "{id} | {name}"

-- Hide own blip: Set to true to hide your own blip from yourself
local HIDE_OWN_BLIP = true

-- Initial wait time before registering (milliseconds)
local INIT_WAIT_TIME = 5000

--================================--
--      END CONFIGURATION         --
--================================--

local blips = {} -- [playerId] = {blip = blip, coords = coords}
local blipsEnabled = true -- Track if blips are enabled

local function debugLog(message)
    if DEBUG then
        TriggerServerEvent('vorp_admin_blips:clientDebug', message)
    end
end

local function formatBlipName(id, name)
    local result = BLIP_NAME_FORMAT
    result = result:gsub("{id}", tostring(id))
    result = result:gsub("{name}", name)
    return result
end

local function clearAllBlips()
    for playerId, blipData in pairs(blips) do
        if DoesBlipExist(blipData.blip) then
            RemoveBlip(blipData.blip)
        end
    end
    blips = {}
    debugLog("All blips cleared")
end

Citizen.CreateThread(function()
    -- Wait a bit for character to load
    Citizen.Wait(INIT_WAIT_TIME)
    
    local playerName = GetPlayerName(PlayerId())
    local isAllowed = false
    
    -- If ALLOWED_NAMES is empty, allow all (server will check admin groups)
    if #ALLOWED_NAMES == 0 then
        isAllowed = true
        debugLog("No whitelist configured, allowing server-side admin check")
    else
        -- Check if player is in the whitelist
        for _, name in ipairs(ALLOWED_NAMES) do
            if name == playerName then
                isAllowed = true
                break
            end
        end
    end
    
    if isAllowed then
        debugLog("Client initialized, registering as admin...")
        TriggerServerEvent('vorp_admin_blips:registerAdmin')
    else
        debugLog("Player " .. playerName .. " denied blip access (not in whitelist)")
    end
end)

-- Handle toggle blips event from server
RegisterNetEvent('vorp_admin_blips:toggleBlips')
AddEventHandler('vorp_admin_blips:toggleBlips', function(enabled)
    blipsEnabled = enabled
    if not enabled then
        clearAllBlips()
    end
    debugLog("Blips toggled: " .. tostring(enabled))
end)

RegisterNetEvent('vorp_admin_blips:updateBlips')
AddEventHandler('vorp_admin_blips:updateBlips', function(playerData)
    -- Don't process if blips are disabled
    if not blipsEnabled then
        return
    end

    debugLog("=== Received blip update with " .. #playerData .. " players ===")
    
    -- Track which playerIds are still valid
    local activePlayerIds = {}
    local blipsCreated = 0
    local blipsUpdated = 0
    local myServerId = GetPlayerServerId(PlayerId())
    
    for _, data in ipairs(playerData) do
        -- Skip local player if configured
        if HIDE_OWN_BLIP and data.id == myServerId then
            goto continue
        end

        if data.id and data.coords then
            activePlayerIds[data.id] = true
            
            -- Check if we already have a blip for this player
            if blips[data.id] then
                -- Update existing blip position
                SetBlipCoords(blips[data.id].blip, data.coords.x, data.coords.y, data.coords.z)
                
                -- Update name in case it changed
                local blipName = formatBlipName(data.id, data.name)
                Citizen.InvokeNative(0x9CB1A1623062F402, blips[data.id].blip, blipName)
                
                blips[data.id].coords = data.coords
                blipsUpdated = blipsUpdated + 1
                debugLog("Updated blip for player " .. data.id .. " (" .. data.name .. ")")
            else
                -- Create new coordinate-based blip
                local styleHash = GetHashKey(BLIP_STYLE)
                local spriteHash = GetHashKey(BLIP_SPRITE)
                
                debugLog("Creating blip for player " .. data.id .. " (" .. data.name .. ")")
                
                local blip = Citizen.InvokeNative(0x554D9D53F696D002, styleHash, data.coords.x, data.coords.y, data.coords.z) -- BLIP_ADD_FOR_COORDS
                
                if blip and blip ~= 0 then
                    debugLog("^2Blip created successfully (ID: " .. blip .. ")^7")
                    
                    -- Change the sprite to the desired icon
                    Citizen.InvokeNative(0x74F74D3207ED525C, blip, spriteHash, true) -- SET_BLIP_SPRITE
                    
                    -- Set Color
                    local blipModifier = GetHashKey(BLIP_MODIFIER)
                    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, blipModifier)
                    
                    -- Set Name
                    local blipName = formatBlipName(data.id, data.name)
                    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipName)
                    
                    blips[data.id] = {
                        blip = blip,
                        coords = data.coords
                    }
                    blipsCreated = blipsCreated + 1
                else
                    debugLog("^1FAILED to create blip with " .. BLIP_STYLE .. "^7")
                end
            end
        else
            debugLog("^3Skipping player data - missing ID or coords^7")
        end
        
        ::continue::
    end
    
    -- Remove blips for players who are no longer in the list
    local blipsRemoved = 0
    for playerId, blipData in pairs(blips) do
        if not activePlayerIds[playerId] then
            if DoesBlipExist(blipData.blip) then
                RemoveBlip(blipData.blip)
            end
            debugLog("Removed blip for player " .. playerId)
            blipsRemoved = blipsRemoved + 1
            blips[playerId] = nil
        end
    end
    
    local totalBlips = 0
    for _ in pairs(blips) do
        totalBlips = totalBlips + 1
    end
    
    debugLog("Update complete - Created: " .. blipsCreated .. " | Updated: " .. blipsUpdated .. 
             " | Removed: " .. blipsRemoved .. " | Total active: " .. totalBlips)
    debugLog("=== Blip update finished ===")
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        clearAllBlips()
    end
end)
