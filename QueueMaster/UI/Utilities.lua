-- ======= Core/UI/Utilities.lua =======
-- Utility functions for UI operations
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Smart text truncation based on available width
function QueueMaster:TruncateText(text, maxWidth, fontString)
    if not text or not fontString then return text end
    
    -- Set the text temporarily to measure width
    fontString:SetText(text)
    local textWidth = fontString:GetStringWidth()
    
    -- If text fits, return it as-is
    if textWidth <= maxWidth then
        return text
    end
    
    -- Text is too wide, need to truncate
    -- Binary search for optimal length
    local left = 1
    local right = #text
    local bestFit = text
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        local truncated = string.sub(text, 1, mid) .. "..."
        
        fontString:SetText(truncated)
        local truncatedWidth = fontString:GetStringWidth()
        
        if truncatedWidth <= maxWidth then
            -- This length fits, try longer
            bestFit = truncated
            left = mid + 1
        else
            -- Too long, try shorter
            right = mid - 1
        end
    end
    
    return bestFit
end

function QueueMaster:FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "00:00"
    end
    
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

function QueueMaster:GetBlizzardWaitTimeEstimates(queueID, queueData)
    -- This function extracts wait time estimates from Blizzard's queue system
    local estimates = {
        tank = 0,
        healer = 0,
        dps = 0,
        average = 0
    }
    
    -- Try to get wait times from LFG system if available
    if queueData and queueData.category and queueData.activeID then
        local success, hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, 
              totalTanks, totalHealers, totalDPS, instanceType, instanceSubType, 
              instanceName, averageWait, tankWait, healerWait, dpsWait, myWait, queuedTime = 
              pcall(GetLFGQueueStats, queueData.category, queueData.activeID)
        
        if success and hasData then
            estimates.tank = tankWait or 0
            estimates.healer = healerWait or 0
            estimates.dps = dpsWait or 0
            estimates.average = averageWait or 0
            
            self:Debug("Retrieved Blizzard wait estimates - Tank: " .. estimates.tank .. 
                      ", Healer: " .. estimates.healer .. ", DPS: " .. estimates.dps)
        end
    end
    
    return estimates
end

function QueueMaster:GetAccurateRoleData(queueID, queueData)
    -- Enhanced role data extraction from multiple sources
    local roleData = {
        tanks = 0,
        healers = 0,
        dps = 0,
        tankNeeds = 0,
        healerNeeds = 0,
        dpsNeeds = 0,
        hasRoleData = false
    }
    
    -- Primary source: LFG Queue Stats
    if queueData and queueData.category and queueData.activeID then
        local success, hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, 
              totalTanks, totalHealers, totalDPS = 
              pcall(GetLFGQueueStats, queueData.category, queueData.activeID)
        
        if success and hasData then
            roleData.tanks = totalTanks or 0
            roleData.healers = totalHealers or 0
            roleData.dps = totalDPS or 0
            roleData.tankNeeds = tankNeeds or 0
            roleData.healerNeeds = healerNeeds or 0
            roleData.dpsNeeds = dpsNeeds or 0
            roleData.hasRoleData = true
            
            self:Debug("Retrieved accurate role data from LFG system")
            return roleData
        end
    end
    
    -- Fallback: Use stored data from queue creation
    if queueData then
        -- Ensure role data are numbers, not strings (PvP queues may return strings)
        roleData.tanks = type(queueData.totalTanks or queueData.tanks) == "number" and (queueData.totalTanks or queueData.tanks) or 0
        roleData.healers = type(queueData.totalHealers or queueData.healers) == "number" and (queueData.totalHealers or queueData.healers) or 0
        roleData.dps = type(queueData.totalDPS or queueData.dps) == "number" and (queueData.totalDPS or queueData.dps) or 0
        roleData.tankNeeds = type(queueData.tankNeeds) == "number" and queueData.tankNeeds or 0
        roleData.healerNeeds = type(queueData.healerNeeds) == "number" and queueData.healerNeeds or 0
        roleData.dpsNeeds = type(queueData.dpsNeeds) == "number" and queueData.dpsNeeds or 0
        
        -- Check if we have valid numeric role data
        if roleData.tanks > 0 or roleData.healers > 0 or roleData.dps > 0 then
            roleData.hasRoleData = true
            self:Debug("Using stored role data as fallback")
        end
    end
    
    return roleData
end