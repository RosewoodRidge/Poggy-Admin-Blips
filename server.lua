local Core = exports.vorp_core:GetCore()
local admins = {}
local adminBlipsHidden = {} -- Track which admins have hidden their blips
local pendingPlayers = {} -- Players waiting for character data to load

--================================--
--        CONFIGURATION           --
--================================--

-- Debug: Set to true to enable debug logging
local DEBUG = false

-- Update interval: How often to send blip updates to admins (milliseconds)
local UPDATE_INTERVAL = 500

-- Pending player retry interval (milliseconds)
local PENDING_RETRY_INTERVAL = 5000

-- Admin groups: Which groups can see blips
local ADMIN_GROUPS = (Config and Config.ADMIN_GROUPS) or {
    "admin",
    "superadmin"
}

--================================--
--      END CONFIGURATION         --
--================================--

local function debugLog(message)
    if DEBUG then
        print("^3[ADMIN BLIPS DEBUG]^7 " .. message)
    end
end

RegisterServerEvent('vorp_admin_blips:registerAdmin')
AddEventHandler('vorp_admin_blips:registerAdmin', function()
    local _source = source
    debugLog("Player " .. _source .. " attempting to register as admin")
    
    local User = Core.getUser(_source)
    if User then
        local userGroup = User.getGroup
        local charGroup = nil
        
        local Character = User.getUsedCharacter
        if Character then
            charGroup = Character.group
        end

        debugLog("Player " .. _source .. " has User group: " .. tostring(userGroup) .. " | Char group: " .. tostring(charGroup))
        
        -- Check if player's group is in the admin groups list
        local isAdmin = false
        for _, adminGroup in ipairs(ADMIN_GROUPS) do
            if userGroup == adminGroup or charGroup == adminGroup then
                isAdmin = true
                break
            end
        end
        
        if isAdmin then
            admins[_source] = true
            adminBlipsHidden[_source] = false
            debugLog("^2Player " .. _source .. " registered as admin^7")
        else
            debugLog("^1Player " .. _source .. " is not admin (User: " .. tostring(userGroup) .. ", Char: " .. tostring(charGroup) .. ")^7")
        end
    else
        debugLog("^1Failed to get User object for player " .. _source .. "^7")
    end
end)

AddEventHandler('playerDropped', function()
    if admins[source] then
        debugLog("Admin player " .. source .. " disconnected")
    end
    admins[source] = nil
    adminBlipsHidden[source] = nil
    pendingPlayers[source] = nil
end)

-- Toggle blips command for admins
RegisterCommand('ahb', function(source, args, rawCommand)
    local _source = source
    
    if not admins[_source] then
        -- Check if they're an admin but haven't registered yet
        local User = Core.getUser(_source)
        if User then
            local userGroup = User.getGroup
            local charGroup = nil
            local Character = User.getUsedCharacter
            if Character then
                charGroup = Character.group
            end

            local isAdmin = false
            for _, adminGroup in ipairs(ADMIN_GROUPS) do
                if userGroup == adminGroup or charGroup == adminGroup then
                    isAdmin = true
                    break
                end
            end
            
            if not isAdmin then
                TriggerClientEvent('vorp:TipRight', _source, "You don't have permission to use this command.", 4000)
                return
            end
        else
            TriggerClientEvent('vorp:TipRight', _source, "You don't have permission to use this command.", 4000)
            return
        end
    end
    
    -- Toggle the hidden state
    if adminBlipsHidden[_source] then
        adminBlipsHidden[_source] = false
        TriggerClientEvent('vorp_admin_blips:toggleBlips', _source, true)
        TriggerClientEvent('vorp:TipRight', _source, "Admin blips are now visible.", 4000)
        debugLog("Admin " .. _source .. " enabled blips")
    else
        adminBlipsHidden[_source] = true
        TriggerClientEvent('vorp_admin_blips:toggleBlips', _source, false)
        TriggerClientEvent('vorp:TipRight', _source, "Admin blips are now hidden.", 4000)
        debugLog("Admin " .. _source .. " disabled blips")
    end
end, false)

-- Helper function to safely get character name
local function getCharacterName(playerId)
    local success, result = pcall(function()
        local User = Core.getUser(playerId)
        if User then
            local Character = User.getUsedCharacter
            if Character and Character.firstname and Character.lastname then
                return Character.firstname .. " " .. Character.lastname
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    return nil
end

-- Helper function to check if player is fully loaded
local function isPlayerReady(playerId)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then
        debugLog("Player " .. playerId .. " - No ped found")
        return false
    end
    
    local coords = GetEntityCoords(ped)
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        debugLog("Player " .. playerId .. " - Coordinates are 0,0,0")
        return false
    end
    
    local charName = getCharacterName(playerId)
    if not charName then
        debugLog("Player " .. playerId .. " - No character name available")
        return false
    end
    
    return true
end

RegisterServerEvent('vorp_admin_blips:clientDebug')
AddEventHandler('vorp_admin_blips:clientDebug', function(message)
    local _source = source
    debugLog("^5[CLIENT " .. _source .. "]^7 " .. message)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(UPDATE_INTERVAL)
        
        local adminCount = 0
        for _ in pairs(admins) do
            adminCount = adminCount + 1
        end
        
        debugLog("=== Update Cycle Start (Admins online: " .. adminCount .. ") ===")
        
        local players = GetPlayers()
        local playerData = {}
        local readyCount = 0
        local pendingCount = 0
        
        debugLog("Total players on server: " .. #players)
        
        for _, playerId in ipairs(players) do
            playerId = tonumber(playerId)
            
            -- Check if player is ready
            if not isPlayerReady(playerId) then
                -- Mark as pending if not already
                if not pendingPlayers[playerId] then
                    pendingPlayers[playerId] = true
                    debugLog("^3Player " .. playerId .. " marked as pending^7")
                end
                pendingCount = pendingCount + 1
                -- Skip this player for now
                goto continue
            end
            
            -- Player is ready, remove from pending
            if pendingPlayers[playerId] then
                debugLog("^2Player " .. playerId .. " is now ready^7")
            end
            pendingPlayers[playerId] = nil
            
            local ped = GetPlayerPed(playerId)
            local coords = GetEntityCoords(ped)
            local charName = getCharacterName(playerId) or GetPlayerName(playerId)

            table.insert(playerData, {
                id = playerId,
                name = charName,
                coords = coords
            })
            
            readyCount = readyCount + 1
            debugLog("Added player " .. playerId .. " (" .. charName .. ") at coords: " .. 
                     string.format("%.2f, %.2f, %.2f", coords.x, coords.y, coords.z))
            
            ::continue::
        end

        debugLog("Ready players: " .. readyCount .. " | Pending players: " .. pendingCount)
        debugLog("Sending " .. #playerData .. " player blips to " .. adminCount .. " admins")
        
        -- Broadcast to all admins who haven't hidden blips
        for adminId, _ in pairs(admins) do
            if not adminBlipsHidden[adminId] then
                debugLog("Broadcasting to admin ID: " .. adminId)
                TriggerClientEvent('vorp_admin_blips:updateBlips', adminId, playerData)
            else
                debugLog("Skipping admin ID: " .. adminId .. " (blips hidden)")
            end
        end
        
        debugLog("=== Update Cycle End ===")
    end
end)

-- Retry pending players
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(PENDING_RETRY_INTERVAL)
        
        for playerId, _ in pairs(pendingPlayers) do
            if isPlayerReady(playerId) then
                pendingPlayers[playerId] = nil
            end
        end
    end
end)
