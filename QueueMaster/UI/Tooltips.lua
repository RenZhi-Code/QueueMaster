-- Tooltip Display for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

function QueueMaster:ShowQueueTooltip(frame, queueID)
    local queueData = self.queues[queueID]
    if not queueData then return end
    
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    
    -- Main header with queue name
    GameTooltip:SetText(queueData.instanceName or queueData.name or "Queue", 1, 1, 1, 1, true)
    
    -- Queue type and category
    local queueType = queueData.queueType or queueData.type or "Queue"
    GameTooltip:AddLine(queueType, 0.8, 0.8, 0.8)
    
    GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
    
    -- Check for deserter/cooldown status (priority)
    local deserterInfo = { hasDeserter = false, formattedTime = "" }
    local cooldownInfo = { hasCooldown = false, formattedTime = "" }
    
    -- Use local functions for tooltip to avoid method access issues
    local function GetDeserterInfoLocal()
        local deserterExpiration = 0
        if GetLFGDeserterExpiration then
            deserterExpiration = GetLFGDeserterExpiration() or 0
        end
        
        local hasDeserter = deserterExpiration and deserterExpiration > 0
        local formattedTime = ""
        
        if hasDeserter then
            local timeLeft = deserterExpiration - GetTime()
            if timeLeft > 0 then
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft % 60)
                formattedTime = string.format("%02d:%02d", minutes, seconds)
            else
                hasDeserter = false
            end
        end
        
        return {
            hasDeserter = hasDeserter,
            expiration = deserterExpiration,
            formattedTime = formattedTime
        }
    end
    
    local function GetCooldownInfoLocal()
        return { hasCooldown = false, timeLeft = 0, formattedTime = "" }
    end
    
    -- Get the information using local functions
    deserterInfo = GetDeserterInfoLocal()
    cooldownInfo = GetCooldownInfoLocal()
    
    if deserterInfo.hasDeserter then
        GameTooltip:AddLine("|cffff0000Deserter Debuff:|r " .. deserterInfo.formattedTime, 1, 0.3, 0.3)
        GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
    elseif cooldownInfo.hasCooldown then
        GameTooltip:AddLine("|cffffff00Random Dungeon Cooldown:|r " .. cooldownInfo.formattedTime, 1, 1, 0.3)
        GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
    end
    
    -- ============ ELAPSED TIME ============
    local elapsed = GetTime() - (queueData.startTime or GetTime())
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    GameTooltip:AddDoubleLine(
        "|cffffd700Elapsed Time:|r",
        string.format("|cffffff00%02d:%02d|r", minutes, seconds),
        0.8, 0.8, 1,
        1, 1, 0
    )
    
    -- ============ WAIT TIME ESTIMATES ============
    local category = queueData.category or 1
    local activeID = queueData.activeID
    
    if GetLFGQueueStats and category and activeID then
        local success, hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, 
              totalTanks, totalHealers, totalDPS, instanceType, instanceSubType, instanceName, 
              averageWait, tankWait, healerWait, dpsWait, myWait = pcall(GetLFGQueueStats, category, activeID)
        
        if success and hasData then
            -- Show personal estimate if available
            if myWait and myWait > 0 then
                local myWaitMin = math.floor(myWait / 60)
                GameTooltip:AddDoubleLine(
                    "|cff88aaffPersonal Estimate:|r",
                    string.format("|cff88aaff%d min|r", myWaitMin),
                    0.8, 0.8, 1,
                    0.5, 0.7, 1
                )
            end
            
            -- Show role-specific estimates
            if tankWait and tankWait > 0 then
                local tankWaitMin = math.floor(tankWait / 60)
                GameTooltip:AddDoubleLine(
                    "  Tank Wait:",
                    string.format("%d min", tankWaitMin),
                    0.7, 0.7, 0.7,
                    0.7, 0.7, 0.7
                )
            end
            
            if healerWait and healerWait > 0 then
                local healerWaitMin = math.floor(healerWait / 60)
                GameTooltip:AddDoubleLine(
                    "  Healer Wait:",
                    string.format("%d min", healerWaitMin),
                    0.7, 0.7, 0.7,
                    0.7, 0.7, 0.7
                )
            end
            
            if dpsWait and dpsWait > 0 then
                local dpsWaitMin = math.floor(dpsWait / 60)
                GameTooltip:AddDoubleLine(
                    "  DPS Wait:",
                    string.format("%d min", dpsWaitMin),
                    0.7, 0.7, 0.7,
                    0.7, 0.7, 0.7
                )
            end
            
            if averageWait and averageWait > 0 then
                local avgWaitMin = math.floor(averageWait / 60)
                GameTooltip:AddDoubleLine(
                    "  Average Wait:",
                    string.format("%d min", avgWaitMin),
                    0.7, 0.7, 0.7,
                    0.7, 0.7, 0.7
                )
            end
        end
    end
    
    -- Historical average if available
    if queueData.rollingAverage and queueData.rollingAverage > 0 then
        local histAvg = math.floor(queueData.rollingAverage)
        GameTooltip:AddDoubleLine(
            "  Historical Avg:",
            string.format("%d min", histAvg),
            0.6, 0.6, 0.6,
            0.6, 0.6, 0.6
        )
    end
    
    GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
    
    -- ============ ROLE COMPOSITION ============
    -- Only show role composition for LFG queues, not PvP
    if not queueData.isPvP then
        GameTooltip:AddLine("|cffffd700Role Composition:|r", 0.8, 0.8, 1)
        
        -- Get fresh Blizzard data for accurate people count
        local category = queueData.category or 1
        local activeID = queueData.activeID
        local freshTanks, freshHealers, freshDPS
        local freshTankNeeds, freshHealerNeeds, freshDpsNeeds
        
        -- Initialize from queueData first
        freshTanks = queueData.displayTanks or queueData.totalTanks or 0
        freshHealers = queueData.displayHealers or queueData.totalHealers or 0
        freshDPS = queueData.displayDPS or queueData.totalDPS or 0
        freshTankNeeds = queueData.displayTankNeeds or queueData.tankNeeds or 0
        freshHealerNeeds = queueData.displayHealerNeeds or queueData.healerNeeds or 0
        freshDpsNeeds = queueData.displayDpsNeeds or queueData.dpsNeeds or 0
        
        -- Try to get most up-to-date data from Blizzard API for LFG queues
        if GetLFGQueueStats and category and activeID and category ~= "pvp" then
            local success, hasData, leaderNeeds, apiTankNeeds, apiHealerNeeds, apiDpsNeeds, 
                  apiTotalTanks, apiTotalHealers, apiTotalDPS = pcall(GetLFGQueueStats, category, activeID)
            
            if success and hasData then
                -- Use fresh API data
                freshTanks = apiTotalTanks or freshTanks
                freshHealers = apiTotalHealers or freshHealers
                freshDPS = apiTotalDPS or freshDPS
                freshTankNeeds = apiTankNeeds or freshTankNeeds
                freshHealerNeeds = apiHealerNeeds or freshHealerNeeds
                freshDpsNeeds = apiDpsNeeds or freshDpsNeeds
            end
        end
    
        -- Calculate actual people who have joined
        local tanksFilled = freshTanks - freshTankNeeds
        local healersFilled = freshHealers - freshHealerNeeds
        local dpsFilled = freshDPS - freshDpsNeeds
        
        -- Role shortage rewards - using simple local structure (no method calls)
        -- This completely avoids any method access issues
        local rewards = {
            tank = { hasReward = false },
            healer = { hasReward = false },
            dps = { hasReward = false }
        }
        
        -- Optional: Could enhance this to check actual Blizzard reward APIs
        -- For now, keeping it simple to prevent errors
        
        -- Tank info with actual people count
        local tankColor = freshTankNeeds > 0 and {1, 0.8, 0.3} or {0.2, 1, 0.2}
        local tankStatus = string.format("%d/%d", tanksFilled, freshTanks)
        if freshTankNeeds > 0 then
            tankStatus = tankStatus .. string.format(" |cffff8000(%d needed)|r", freshTankNeeds)
        else
            tankStatus = tankStatus .. " |cff00ff00Ready|r"
        end
        if rewards.tank and rewards.tank.hasReward then
            tankStatus = tankStatus .. " |cffffcc00*|r"
        end
        GameTooltip:AddDoubleLine(
            "  Tanks:",
            tankStatus,
            tankColor[1], tankColor[2], tankColor[3],
            tankColor[1], tankColor[2], tankColor[3]
        )
        
        -- Healer info with actual people count
        local healerColor = freshHealerNeeds > 0 and {1, 0.8, 0.3} or {0.2, 1, 0.2}
        local healerStatus = string.format("%d/%d", healersFilled, freshHealers)
        if freshHealerNeeds > 0 then
            healerStatus = healerStatus .. string.format(" |cffff8000(%d needed)|r", freshHealerNeeds)
        else
            healerStatus = healerStatus .. " |cff00ff00Ready|r"
        end
        if rewards.healer and rewards.healer.hasReward then
            healerStatus = healerStatus .. " |cffffcc00*|r"
        end
        GameTooltip:AddDoubleLine(
            "  Healers:",
            healerStatus,
            healerColor[1], healerColor[2], healerColor[3],
            healerColor[1], healerColor[2], healerColor[3]
        )
        
        -- DPS info with actual people count
        local dpsColor = freshDpsNeeds > 0 and {1, 0.8, 0.3} or {0.2, 1, 0.2}
        local dpsStatus = string.format("%d/%d", dpsFilled, freshDPS)
        if freshDpsNeeds > 0 then
            dpsStatus = dpsStatus .. string.format(" |cffff8000(%d needed)|r", freshDpsNeeds)
        else
            dpsStatus = dpsStatus .. " |cff00ff00Ready|r"
        end
        if rewards.dps and rewards.dps.hasReward then
            dpsStatus = dpsStatus .. " |cffffcc00*|r"
        end
        GameTooltip:AddDoubleLine(
            "  DPS:",
            dpsStatus,
            dpsColor[1], dpsColor[2], dpsColor[3],
            dpsColor[1], dpsColor[2], dpsColor[3]
        )
    else
        -- For PvP queues, show different information
        GameTooltip:AddLine("|cffffd700Battleground Info:|r", 0.8, 0.8, 1)
        
        -- Show team size if available (handle both number and string formats)
        if queueData.teamSize then
            local teamSizeDisplay = queueData.teamSize
            -- If teamSize is a number and greater than 0, show it
            if type(teamSizeDisplay) == "number" and teamSizeDisplay > 0 then
                GameTooltip:AddDoubleLine(
                    "  Team Size:",
                    tostring(teamSizeDisplay),
                    0.7, 0.7, 0.7,
                    1, 1, 1
                )
            elseif type(teamSizeDisplay) == "string" and teamSizeDisplay ~= "" then
                -- Show the type (e.g., "BATTLEGROUND", "ARENA")
                local displayText = teamSizeDisplay:gsub("_", " "):lower()
                displayText = displayText:gsub("^%l", string.upper) -- Capitalize first letter
                GameTooltip:AddDoubleLine(
                    "  Type:",
                    displayText,
                    0.7, 0.7, 0.7,
                    1, 1, 1
                )
            end
        end
        
        -- Show status
        local bgStatus = "Waiting for match..."
        if queueData.isProposal then
            bgStatus = "|cff00ff00Ready to Enter!|r"
        end
        GameTooltip:AddDoubleLine(
            "  Status:",
            bgStatus,
            0.7, 0.7, 0.7,
            0.2, 1, 0.2
        )
    end
    
    -- Interaction hints
    GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
    GameTooltip:AddLine("|cff88ff88Shift+Click:|r Leave queue", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff88aaffRight-Click:|r Settings", 0.7, 0.7, 0.7)

    GameTooltip:Show()
end
