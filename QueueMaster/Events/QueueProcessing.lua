local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Queue Processing module for QueueMaster
-- Handles queue management, proposal handling, and queue state changes

function QueueMaster:ProcessSpecificQueue(uniqueQueueID, category, activityInfo, categoryInfo)
    local foundActiveQueues = {}
    foundActiveQueues[uniqueQueueID] = true
    
    -- Get queue information for this specific activity
    local queueInfo = self.SafeGetLFGQueueStats(category)
    if not queueInfo or not queueInfo.hasData then
        return foundActiveQueues
    end
    
    local queueType = activityInfo.fullName or "LFR Queue"
    local finalInstanceName = activityInfo.fullName or "Unknown LFR"
    
    -- Get role information
    local roleInfo = self:GetAccurateRoleInfo(uniqueQueueID, category)
    
    if not self.queues[uniqueQueueID] then
        -- New LFR queue detected
        
        -- Check if we have a saved start time from previous sessions
        local savedStartTime = self:GetSavedQueueStartTime(uniqueQueueID)
        local calculatedStartTime
        
        if savedStartTime and savedStartTime > 0 then
            -- Use saved start time to maintain timer across reloads
            calculatedStartTime = savedStartTime
            self:Debug("ProcessLFRQueues - " .. uniqueQueueID .. " using saved startTime: " .. calculatedStartTime)
        else
            -- Use current time for new queue detection
            calculatedStartTime = GetTime()
            self:Debug("ProcessLFRQueues - " .. uniqueQueueID .. " new startTime: " .. calculatedStartTime)
            -- Save this start time for persistence
            self:SaveQueueStartTime(uniqueQueueID, calculatedStartTime)
        end
        
        -- Joined LFR queue
        self.queues[uniqueQueueID] = {
            id = uniqueQueueID,
            lfgID = category,
            category = category,
            categoryName = categoryInfo.name,
            instanceName = finalInstanceName,
            type = queueType,
            queueCategory = "LFR",
            startTime = calculatedStartTime,  -- FIXED: Use calculated/saved start time instead of GetTime()
            tankNeeds = roleInfo.tankNeeds,
            healerNeeds = roleInfo.healerNeeds,
            dpsNeeds = roleInfo.dpsNeeds,
            totalTanks = roleInfo.tanks,
            totalHealers = roleInfo.healers,
            totalDPS = roleInfo.dps,
            averageWait = math.max(queueInfo.averageWait or 0, 0), -- Ensure positive
            maxWait = math.max(queueInfo.averageWait or 0, 0),
            rollingAverage = self:GetRollingAverageWait(queueType),
            color = categoryInfo.color,
            isProposal = false,
            updateCount = 1,
            lastUpdateTime = GetTime(),
            independent = true
        }
        self:SaveQueueStartTime(uniqueQueueID, self.queues[uniqueQueueID].startTime)
        
        self:CreateQueueBar(uniqueQueueID)
        self:ShowMainFrame()
        
        -- CRITICAL: Update layout to show anchor after bar creation
        self:UpdateQueueBarLayout()
        
        if self.settings and self.settings.alerts then
            self:ShowQueueJoinedAlert(finalInstanceName, queueType)
        end
        
        if queueInfo.averageWait and queueInfo.averageWait > 0 then
            self:StoreWaitTime(queueType, queueInfo.averageWait)
        end
    else
        -- Update existing LFR queue
        local queue = self.queues[uniqueQueueID]
        local oldAverageWait = queue.averageWait
        
        queue.tankNeeds = roleInfo.tankNeeds
        queue.healerNeeds = roleInfo.healerNeeds
        queue.dpsNeeds = roleInfo.dpsNeeds
        queue.totalTanks = roleInfo.tanks
        queue.totalHealers = roleInfo.healers
        queue.totalDPS = roleInfo.dps
        queue.averageWait = queueInfo.averageWait
        queue.maxWait = math.max(queue.maxWait or 0, queueInfo.averageWait or 0)
        queue.rollingAverage = self:GetRollingAverageWait(queueType)
        queue.updateCount = (queue.updateCount or 0) + 1
        queue.lastUpdateTime = GetTime()
        
        if queueInfo.averageWait and queueInfo.averageWait > 0 and math.abs((queueInfo.averageWait or 0) - (oldAverageWait or 0)) > 5 then
            self:StoreWaitTime(queueType, queueInfo.averageWait)
        end
    end
    
    return foundActiveQueues
end

function QueueMaster:ProcessSingleQueue(uniqueQueueID, category, queueInfo, categoryInfo, mode)
    local queueState = self:GetQueueState(category)
    -- Extract activeID from uniqueQueueID (format: QUEUE_3_2780)
    local activeID = tonumber(string.match(uniqueQueueID, "QUEUE_%d+_(%d+)")) or queueInfo.activeID
    
    -- Get enhanced queue type information
    local queueType, queueCategory, detectedInstanceName = self:GetQueueTypeInfo(category, activeID)
    local finalInstanceName = queueInfo.instanceName or detectedInstanceName or "Unknown Queue"
    
    -- Get accurate role information
    local roleInfo = self:GetAccurateRoleInfo(uniqueQueueID, category)
    
    if not self.queues[uniqueQueueID] then
        -- New queue detected with independent tracking and persistent start time
        
        -- Check if we have a saved start time from previous sessions
        local savedStartTime = self:GetSavedQueueStartTime(uniqueQueueID)
        local calculatedStartTime
        
        if savedStartTime and savedStartTime > 0 then
            -- Use saved start time to maintain timer across reloads
            calculatedStartTime = savedStartTime
            self:Debug("ProcessSingleQueue - " .. uniqueQueueID .. " using saved startTime: " .. calculatedStartTime)
        else
            -- Use current time for new queue detection
            calculatedStartTime = GetTime()
            self:Debug("ProcessSingleQueue - " .. uniqueQueueID .. " new startTime: " .. calculatedStartTime)
            -- Save this start time for persistence
            self:SaveQueueStartTime(uniqueQueueID, calculatedStartTime)
        end
        
        self.queues[uniqueQueueID] = {
            id = uniqueQueueID,
            lfgID = category,
            category = category,
            categoryName = categoryInfo.name,
            instanceName = finalInstanceName,
            type = queueType,
            queueCategory = queueCategory,
            activeID = activeID, -- IMPORTANT: Set the activeID properly
            startTime = calculatedStartTime, -- Use persistent start time
            tankNeeds = roleInfo.tankNeeds,
            healerNeeds = roleInfo.healerNeeds,
            dpsNeeds = roleInfo.dpsNeeds,
            totalTanks = roleInfo.tanks,
            totalHealers = roleInfo.healers,
            totalDPS = roleInfo.dps,
            averageWait = math.max(queueInfo.averageWait or 0, 0), -- Ensure positive
            maxWait = math.max(queueInfo.averageWait or 0, 0),
            rollingAverage = self:GetRollingAverageWait(queueType),
            color = categoryInfo.color,
            isProposal = (queueState == "PROPOSAL"),
            updateCount = 1,
            lastUpdateTime = GetTime(),
            independent = true -- Flag for independent queue tracking
        }
        
        -- Save start time persistently for reload protection
        self:SaveQueueStartTime(uniqueQueueID, self.queues[uniqueQueueID].startTime)
        
        self:CreateQueueBar(uniqueQueueID)
        self:ShowMainFrame()
        
        -- CRITICAL: Update layout to show anchor after bar creation
        self:UpdateQueueBarLayout()
        
        -- Show alert for new queue
        if self.settings and self.settings.alerts then
            self:ShowQueueJoinedAlert(queueInfo.instanceName or "Queue", queueType)
        end
        
        -- Store initial wait time
        if queueInfo.averageWait and queueInfo.averageWait > 0 then
            self:StoreWaitTime(queueType, queueInfo.averageWait)
        end
    else
        -- Update existing queue with enhanced data (independent tracking)
        local queue = self.queues[uniqueQueueID]
        local oldAverageWait = queue.averageWait
        
        -- Preserve independent timer by not overwriting startTime
        queue.tankNeeds = roleInfo.tankNeeds
        queue.healerNeeds = roleInfo.healerNeeds
        queue.dpsNeeds = roleInfo.dpsNeeds
        queue.totalTanks = roleInfo.tanks
        queue.totalHealers = roleInfo.healers
        queue.totalDPS = roleInfo.dps
        queue.averageWait = queueInfo.averageWait
        queue.maxWait = math.max(queue.maxWait or 0, queueInfo.averageWait or 0)
        queue.rollingAverage = self:GetRollingAverageWait(queueType)
        queue.isProposal = (queueState == "PROPOSAL")
        queue.updateCount = (queue.updateCount or 0) + 1
        queue.lastUpdateTime = GetTime()
        
        -- Update instance name with enhanced detection
        queue.instanceName = finalInstanceName
        queue.type = queueType
        queue.queueCategory = queueCategory
        
        -- Store wait time if it changed significantly
        if queueInfo.averageWait and queueInfo.averageWait > 0 and math.abs((queueInfo.averageWait or 0) - (oldAverageWait or 0)) > 5 then
            self:StoreWaitTime(queueType, queueInfo.averageWait)
        end
    end
end

function QueueMaster:OnProposalShow()
    self:Print("\124cffff8000[QM]\124r LFG Invite Ready! Accept now!")
    local proposalStartTime = GetTime()
    
    -- CRITICAL FIX: Don't call UpdateQueues during proposal!
    -- This prevents the cleanup logic from removing the proposal queue
    -- Instead, just mark existing queues as proposals
    
    -- Mark all active queues as having a proposal and track proposal start time
    local queueCount = 0
    for queueID, queue in pairs(self.queues) do
        queueCount = queueCount + 1
        queue.isProposal = true
        queue.proposalStartTime = proposalStartTime
        queue.proposalTimeout = 40 -- LFR invites typically timeout after 40 seconds
        
        -- CRITICAL FIX: Pause timer during proposal
        -- Save elapsed time when proposal starts so timer can resume correctly
        if queue.startTime then
            queue.pausedElapsed = proposalStartTime - queue.startTime
            queue.timerPaused = true
            self:Debug("Timer paused at: " .. queue.pausedElapsed .. "s for queue: " .. queueID)
        end
        
        -- CRITICAL: Ensure bar exists and is visible
        if not self.queueBars[queueID] then
            self:CreateQueueBar(queueID)
            -- Update layout to show anchor after bar creation
            self:UpdateQueueBarLayout()
        end
        
        local bar = self.queueBars[queueID]
        if bar then
            -- Force bar to show
            bar:Show()
            -- Update bar with proposal state
            self:UpdateQueueBar(queueID, bar)
        end
    end
    
    if queueCount == 0 then
        self:Print("|cffff0000[QM Warning]|r No active queues found when invite showed! Trying to restore queue...")
        -- Only NOW try to update queues if we have no existing ones
        self:ScheduleTimer("UpdateQueues", 0.1, true)
    end
    
    -- Play alert sound if enabled
    if self.settings and self.settings.soundEnabled then
        self:Debug("Playing proposal sound")
        PlaySound(8960) -- Queue pop sound
    else
        self:Debug("Sound notifications disabled")
    end

    -- CRITICAL: Force immediate centralized update to show proposal UI
    -- Reset the accumulator so the next update happens instantly
    if self.centralUpdateFrame then
        self.centralUpdateFrame.accumulator = 999 -- Force immediate update on next frame
        self:Debug("Forced immediate centralized update for proposal display")
    end
end

function QueueMaster:OnProposalEnd()
    self:Print("|cff00ff00[QM]|r Clearing proposal state, returning to normal queue display")
    -- Remove proposal state and countdown data from all queues
    for queueID, queue in pairs(self.queues) do
        queue.isProposal = false
        queue.proposalStartTime = nil
        queue.proposalTimeout = nil
        
        -- CRITICAL FIX: Resume timer from where it was paused
        if queue.timerPaused and queue.pausedElapsed then
            queue.startTime = GetTime() - queue.pausedElapsed
            queue.timerPaused = false
            queue.pausedElapsed = nil
            self:Debug("Timer resumed for queue: " .. queueID .. ", new startTime: " .. queue.startTime)
        end
        
        if self.queueBars[queueID] then
            self:UpdateQueueBar(queueID)
        end
    end
    
    -- DO NOT call UpdateQueues here!
    -- The queue is still active, we just need to clear the proposal state
    -- UpdateQueues might remove the queue if called at the wrong time
    -- Next regular update will handle any necessary queue changes

    -- CRITICAL: Force immediate centralized update to restore normal UI
    -- Reset the accumulator so the next update happens instantly
    if self.centralUpdateFrame then
        self.centralUpdateFrame.accumulator = 999 -- Force immediate update on next frame
        self:Debug("Forced immediate centralized update to restore normal display")
    end
end

function QueueMaster:OnQueueLeft()
    self:Debug("Handling queue left event")
    -- Use throttled update to prevent spam
    self.ThrottledUpdate(self, "QUEUE_LEFT", 1)
    
    -- Schedule cleanup check after a delay
    self:ScheduleTimer(function()
        if not next(self.queues) then
            self:Debug("No active queues detected, clearing all bars")
            if self.ClearAllQueues then
                self:ClearAllQueues()
            else
                -- Fallback: clear manually
                for queueID, bar in pairs(self.queueBars or {}) do
                    if bar then
                        bar:Hide()
                        bar:SetParent(nil)
                    end
                end
                self.queues = {}
                self.queueBars = {}
            end
        else
            self:Debug("Still have active queues, keeping bars")
        end
    end, 1)
end

function QueueMaster:RemoveQueue(queueID)
    if self.queueBars[queueID] then
        self.queueBars[queueID]:Hide()
        self.queueBars[queueID] = nil
    end
    
    self.queues[queueID] = nil
    self:UpdateQueueBarLayout()
end

-- Enhanced queue state detection following Blizzard's pattern
function QueueMaster:GetQueueState(category)
    -- Check for deserter debuff first (following Blizzard's pattern)
    local deserterExpiration = GetLFGDeserterExpiration and GetLFGDeserterExpiration() or nil
    if deserterExpiration and deserterExpiration > GetTime() then
        return "DESERTER"
    end
    
    -- Check for random cooldown
    local randomCooldownExpiration = GetLFGRandomCooldownExpiration and GetLFGRandomCooldownExpiration() or nil
    if randomCooldownExpiration and randomCooldownExpiration > GetTime() then
        return "COOLDOWN"
    end
    
    local mode, submode = self.SafeGetLFGMode(category)
    if mode then
        -- Following Blizzard's state detection pattern
        if mode == "queued" then
            return "QUEUED"
        elseif mode == "rolecheck" then
            return "ROLECHECK" 
        elseif mode == "proposal" then
            return "PROPOSAL"
        elseif mode == "suspended" then
            return "SUSPENDED"
        end
    end
    
    return "NONE"
end

-- Queue management utilities
function QueueMaster:ClearAllQueues()
    self:Debug("Clearing all queues and bars")
    
    -- Clear all queue bars
    if self.queueBars then
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                bar:Hide()
                bar:SetParent(nil)
            end
        end
        self.queueBars = {}
    end
    
    -- Clear all queues
    if self.queues then
        self.queues = {}
    end
    
    -- Hide main frame
    if self.HideMainFrame then
        self:HideMainFrame()
    end
    
    self:Debug("All queues and bars cleared")
end

function QueueMaster:RefreshQueues()
    self:Debug("Refreshing all queue data")
    self:UpdateQueues(true) -- Force update
end