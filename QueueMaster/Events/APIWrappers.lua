local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- API Wrappers module for QueueMaster
-- Safe wrapper functions for WoW API compatibility across different versions

-- PERFORMANCE: Frame-level API result caching to reduce redundant calls
local frameCache = {}
local frameCacheTime = 0

local function ClearFrameCache()
    local currentTime = GetTime()
    -- Cache expires every frame (0.016s at 60 FPS)
    if currentTime ~= frameCacheTime then
        frameCache = {}
        frameCacheTime = currentTime
    end
end

-- Safe API wrapper functions for 11.2 compatibility (optimized with caching)
local function SafeGetLFGQueueStats(category, activeID)
    -- PERFORMANCE: Clear cache if we're in a new frame
    ClearFrameCache()
    
    -- Check cache first
    local cacheKey = tostring(category) .. "_" .. tostring(activeID or "nil")
    if frameCache[cacheKey] then
        return frameCache[cacheKey]
    end
    
    local result
    
    -- Note: C_LFGInfo.GetAllEntriesForCategory doesn't exist in standard WoW API
    -- Use GetLFGQueueStats directly as the primary method
    
    -- Check API availability for performance
    local hasLegacyAPI = GetLFGQueueStats
    
    -- Use GetLFGQueueStats directly (this is the standard Blizzard API)
    if hasLegacyAPI then
        local success, hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, totalTanks, totalHealers, totalDPS, instanceType, instanceSubType, instanceName, averageWait, tankWait, healerWait, dpsWait, myWait, queuedTime, returnedActiveID = pcall(GetLFGQueueStats, category, activeID)
        
        if success and hasData then
            -- GetLFGQueueStats returned valid data
            result = {
                hasData = hasData,
                tankNeeds = tankNeeds or 0,
                healerNeeds = healerNeeds or 0,
                dpsNeeds = dpsNeeds or 0,
                totalTanks = totalTanks or 0,
                totalHealers = totalHealers or 0,
                totalDPS = totalDPS or 0,
                instanceName = instanceName or "Unknown",
                averageWait = averageWait or 0,
                queuedTime = queuedTime or 0,
                instanceType = instanceType or 1,
                activeID = returnedActiveID or activeID
            }
            -- Cache the result
            frameCache[cacheKey] = result
            return result
        end
    end
    
    -- Try alternative detection methods for active queues
    if C_LFGList and C_LFGList.GetNumApplications and C_LFGList.GetNumApplications() > 0 then
        -- Found LFG List queue
        result = {
            hasData = true,
            tankNeeds = 0,
            healerNeeds = 0, 
            dpsNeeds = 1,
            totalTanks = 1,
            totalHealers = 1,
            totalDPS = 3,
            instanceName = "LFG Queue",
            averageWait = 300,
            queuedTime = 0, -- No queue time available for LFG List
            instanceType = category,
            activeID = activeID
        }
        frameCache[cacheKey] = result
        return result
    end
    
    -- Return empty data structure
    result = {
        hasData = false,
        tankNeeds = 0,
        healerNeeds = 0,
        dpsNeeds = 0,
        totalTanks = 0,
        totalHealers = 0,
        totalDPS = 0,
        instanceName = "Unknown",
        averageWait = 0,
        queuedTime = 0, -- No queue time available in fallback
        instanceType = category or 1,
        activeID = activeID
    }
    
    frameCache[cacheKey] = result
    return result
end

-- Cached API availability for performance
local apiCache = {
    hasLegacyLFGMode = GetLFGMode,
    hasGetLFGQueueStats = GetLFGQueueStats,
    hasGetLFGDungeonInfo = GetLFGDungeonInfo
}

local function SafeGetLFGMode(category)
    if not category then
        return nil, nil
    end
    
    -- Use standard GetLFGMode API (this is the correct Blizzard API)
    if apiCache.hasLegacyLFGMode then
        local success, m, sm = pcall(GetLFGMode, category)
        if success and m then
            return m, sm
        end
    end
    
    -- Additional check for category 3 (LFR) using queue status verification
    if category == 3 then
        -- Check if we have actual queue data to verify we're really queued
        if apiCache.hasGetLFGQueueStats then
            local success, hasData = pcall(GetLFGQueueStats, category)
            if success and hasData then
                return "queued", nil
            end
        end
        
        -- Fallback: Check RaidFinderFrame visibility with verification
        if RaidFinderFrame and RaidFinderFrame:IsVisible() then
            -- Double-check that we're actually queued, not just browsing
            if apiCache.hasGetLFGQueueStats then
                local success, hasData = pcall(GetLFGQueueStats, category)
                if success and hasData then
                    return "queued", nil
                end
            end
        end
    end
    
    return nil, nil
end

-- Safe PvP/Battleground queue detection (new for PvP support)
local function SafeGetBattlefieldStatus(index)
    if not GetBattlefieldStatus then
        return nil
    end
    
    -- GetBattlefieldStatus returns: status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch, eligible, queueSuspended, queueType
    -- Note: timeInQueue is NOT returned by this API, we'll calculate it ourselves
    local success, status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch, eligible, queueSuspended = pcall(GetBattlefieldStatus, index)
    
    if not success or not status then
        return nil
    end
    
    -- Only return data if we're actually queued or have a proposal
    if status == "queued" or status == "confirm" or status == "active" then
        -- Determine if this is an arena based on team size
        local isArena = (teamSize and (teamSize == 2 or teamSize == 3 or teamSize == 5))
        
        return {
            status = status,
            mapName = mapName or "Unknown Battleground",
            teamSize = teamSize or 0,
            registeredMatch = registeredMatch or false,
            suspended = queueSuspended or false,
            queueType = "BATTLEGROUND",
            estimatedWaitTime = 600, -- Default 10 minute estimate (API doesn't provide this)
            timeInQueue = nil, -- Not available from API, we'll track it ourselves
            isArena = isArena,
            index = index
        }
    end
    
    return nil
end

-- Safe LFG dungeon info retrieval
local function SafeGetLFGDungeonInfo(dungeonID)
    if not apiCache.hasGetLFGDungeonInfo or not dungeonID then
        return nil
    end
    
    local success, type, name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday = pcall(GetLFGDungeonInfo, dungeonID)
    
    if success and name then
        return {
            type = type,
            name = name,
            typeID = typeID,
            subtypeID = subtypeID,
            minLevel = minLevel,
            maxLevel = maxLevel,
            recLevel = recLevel,
            minRecLevel = minRecLevel,
            maxRecLevel = maxRecLevel,
            expansionLevel = expansionLevel,
            groupID = groupID,
            textureFilename = textureFilename,
            difficulty = difficulty,
            maxPlayers = maxPlayers,
            description = description,
            isHoliday = isHoliday
        }
    end
    
    return nil
end

-- Safe role check info
local function SafeGetLFGRoleInfo(category)
    if not GetLFGRoleShortageRewards then
        return nil
    end
    
    local success, eligible, forTank, forHealer, forDamage, itemCount = pcall(GetLFGRoleShortageRewards, category, 0)
    
    if success and eligible then
        return {
            eligible = eligible,
            tankNeeded = forTank or false,
            healerNeeded = forHealer or false,
            dpsNeeded = forDamage or false,
            itemCount = itemCount or 0
        }
    end
    
    return nil
end

-- Queue categories (including PvP)
local QUEUE_CATEGORIES = {
    [1] = { name = "Dungeon Finder", color = {0.2, 0.8, 0.2} },
    [3] = { name = "Raid Finder", color = {0.8, 0.2, 0.2} },
    [4] = { name = "Scenarios", color = {0.2, 0.2, 0.8} },
    [5] = { name = "Flexible Raid", color = {0.8, 0.8, 0.2} },
    -- PvP doesn't have a traditional category number, handled separately
    ["pvp"] = { name = "Battleground", color = {0.9, 0.1, 0.9} } -- Neon purple for PvP
}

-- Export all API wrapper functions to QueueMaster
QueueMaster.SafeGetLFGQueueStats = SafeGetLFGQueueStats
QueueMaster.SafeGetLFGMode = SafeGetLFGMode  
QueueMaster.SafeGetBattlefieldStatus = SafeGetBattlefieldStatus
QueueMaster.SafeGetLFGDungeonInfo = SafeGetLFGDungeonInfo
QueueMaster.SafeGetLFGRoleInfo = SafeGetLFGRoleInfo
QueueMaster.QUEUE_CATEGORIES = QUEUE_CATEGORIES

-- API cache access for other modules
QueueMaster.APICache = apiCache