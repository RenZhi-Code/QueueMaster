local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Queue Detection module for QueueMaster
-- Handles detection and monitoring of active queues

function QueueMaster:CheckForQueues()
    -- Main queue detection function called by the timer
    if not self.settings.enabled then
        return
    end
    
    self:UpdateQueues()
end

function QueueMaster:UpdateQueues(forceUpdate)
    if self.debugMode then
        self:Debug("UpdateQueues called" .. (forceUpdate and " (FORCED)" or ""))
    end
    if not self.queues then 
        self.queues = {}
        if self.debugMode then
            self:Debug("Initialized queues table")
        end
    end
    
    -- Debug current queue state
    if self.debugMode then
        local currentQueueCount = 0
        for queueID, _ in pairs(self.queues) do
            currentQueueCount = currentQueueCount + 1
            self:Debug("Existing queue: " .. tostring(queueID))
        end
        self:Debug("Current queue count: " .. currentQueueCount)
    end
    
    -- Prevent rapid duplicate updates but allow important updates
    local currentTime = GetTime()
    -- REMOVED THROTTLING: Allow frequent updates to ensure timer displays update every second
    -- if not forceUpdate and self.lastUpdateTime and (currentTime - self.lastUpdateTime) < 0.3 then
    --     self:Debug("Skipping update - too frequent (< 0.3 second)")
    --     return
    -- end
    self.lastUpdateTime = currentTime
    
    local foundActiveQueues = {}
    local hasAnyQueue = false
    
    -- CRITICAL FIX: Preserve existing proposal queues before detection
    -- This prevents bars from disappearing during proposal state
    for queueID, queue in pairs(self.queues) do
        if queue.isProposal then
            foundActiveQueues[queueID] = true
            if self.debugMode then
                self:Debug("Pre-preserving proposal queue: " .. queueID)
            end
        end
    end
    
    -- Skip generic minimap detection - rely on specific queue detection only
    -- This prevents creating fallback queues that conflict with real queue detection
    local foundSpecificQueues = false
    for _ in pairs(foundActiveQueues) do
        foundSpecificQueues = true
        break
    end
    
    -- Check individual categories as backup
    if self.debugMode then
        self:Debug("Checking all LFG categories for active queues")
    end
    self:CheckStandardLFGCategories(foundActiveQueues)
    
    -- Check for PvP queues
    self:CheckPvPQueues(foundActiveQueues)
    
    -- Determine if we have any queues
    hasAnyQueue = next(foundActiveQueues) ~= nil
    
    -- If no queues detected, use cleanup with grace period instead of immediate removal
    if not hasAnyQueue then
        if self.debugMode then
            self:Debug("No active queues detected - using grace period before removal")
        end
        -- CRITICAL FIX: Don't immediately remove all queues!
        -- Use the CleanupInactiveQueues function which has grace period logic
        self:CleanupInactiveQueues(foundActiveQueues)

        -- Only hide main frame if there are truly no queues after grace period
        if not next(self.queues) then
            if self.HideMainFrame then
                self:HideMainFrame()
            end
        end
        -- CRITICAL FIX: Don't return here! Continue to allow bar visibility checks
        -- This allows bars to be shown even if queue detection temporarily fails
        -- return
    else
        if self.debugMode then
            self:Debug("Found " .. (hasAnyQueue and "active" or "no") .. " queues")
        end
        -- Keep the Blizzard queue icon hidden when we have active queues
        if QueueStatusMinimapButton and QueueStatusMinimapButton:IsShown() then
            QueueStatusMinimapButton:Hide()
            if self.debugMode then
                self:Debug("Re-hidden Blizzard queue icon")
            end
        end
    end
    
    -- Remove queues that are no longer active
    self:CleanupInactiveQueues(foundActiveQueues)
end

function QueueMaster:CheckStandardLFGCategories(foundActiveQueues)
    -- CRITICAL FIX: Check MORE categories to catch all queue types
    -- Category 1 = Dungeon Finder, Category 2 = Raid Finder, etc.
    for category = 1, 10 do  -- Increased from 5 to 10 to catch all possible queues
        local mode, submode = self.SafeGetLFGMode(category)
        
        if self.debugMode then
            local categoryName = (self.QUEUE_CATEGORIES[category] and self.QUEUE_CATEGORIES[category].name) or "Unknown"
            self:Debug("Checking category " .. category .. " (" .. categoryName .. ")")
            self:Debug("Category " .. category .. " mode: " .. tostring(mode) .. ", submode: " .. tostring(submode))
        end
        
        -- REMOVED: Wasteful debug LFR loop that did 81 API calls per update
        -- The debug info provided no functional value and caused performance issues
        
        local queueState = self:GetQueueState(category)
        if self.debugMode then
            self:Debug("Category " .. category .. " queue state: " .. queueState)
        end
        if queueState == "QUEUED" or queueState == "PROPOSAL" or queueState == "ROLECHECK" then
            self:ProcessStandardCategory(category, foundActiveQueues, queueState)
        end
    end
end

function QueueMaster:ProcessStandardCategory(category, foundActiveQueues, queueState)
    if self.debugMode then
        self:Debug("ProcessStandardCategory called for category " .. category .. " with queueState: " .. tostring(queueState))
    end

    -- CRITICAL FIX: Try to enumerate all queued dungeons in this category
    -- GetLFGQueuedList returns a table with activeIDs as KEYS (not values!)
    local activeIDList = {}

    if GetLFGQueuedList then
        local queuedTable = GetLFGQueuedList(category)
        if self.debugMode then
            self:Debug("GetLFGQueuedList returned for category " .. category)
        end

        -- The API returns a table with activeIDs as keys, we need to convert to array
        if queuedTable and type(queuedTable) == "table" then
            for activeID, _ in pairs(queuedTable) do
                activeIDList[#activeIDList + 1] = activeID
                if self.debugMode then
                    self:Debug("Found activeID in queue: " .. tostring(activeID))
                end
            end
        end
    end

    -- FALLBACK: If GetLFGQueuedList doesn't work or returns empty, try without activeID
    -- This will return data for at least ONE queue in the category
    if #activeIDList == 0 then
        if self.debugMode then
            self:Debug("GetLFGQueuedList returned no activeIDs, trying GetLFGQueueStats without activeID")
        end
        activeIDList = {nil}  -- Will call GetLFGQueueStats(category) without activeID
    else
        if self.debugMode then
            self:Debug("Found " .. #activeIDList .. " activeIDs in category " .. category)
        end
    end

    -- Process each queued instance in this category
    local processedCount = 0
    for i, activeID in ipairs(activeIDList) do
        if self.debugMode then
            self:Debug("Processing queue " .. i .. " in category " .. category .. " with activeID: " .. tostring(activeID))
        end

        -- CRITICAL FIX: GetLFGQueueStats ignores the activeID parameter for LFR!
        -- Call it without activeID to get queue stats, then override with correct values
        local queueInfo = self.SafeGetLFGQueueStats(category, nil)

        -- Override activeID and get correct instance name
        if queueInfo and queueInfo.hasData and activeID then
            queueInfo.activeID = activeID

            -- Get correct instance name from GetLFGDungeonInfo
            if GetLFGDungeonInfo then
                local success, name = pcall(GetLFGDungeonInfo, activeID)
                if success and name and name ~= "" then
                    queueInfo.instanceName = name
                    if self.debugMode then
                        self:Debug("Got instance name from GetLFGDungeonInfo: " .. name)
                    end
                end
            elseif GetRFDungeonInfo then
                local success, name = pcall(GetRFDungeonInfo, activeID)
                if success and name and name ~= "" then
                    queueInfo.instanceName = name
                    if self.debugMode then
                        self:Debug("Got instance name from GetRFDungeonInfo: " .. name)
                    end
                end
            end
        end

        if self.debugMode then
            self:Debug("GetLFGQueueStats result - hasData: " .. tostring(queueInfo and queueInfo.hasData))
            if queueInfo and queueInfo.hasData then
                self:Debug("Queue info: " .. (queueInfo.instanceName or "no name") .. " activeID: " .. tostring(queueInfo.activeID))
            end
        end

        if queueInfo and queueInfo.hasData then
            processedCount = processedCount + 1

            -- Create stable queue ID using category and active ID to prevent duplicates
            local uniqueQueueID = string.format("QUEUE_%d_%d", category, queueInfo.activeID or activeID or 0)
            foundActiveQueues[uniqueQueueID] = true

            -- REMOVED: FindExistingQueueByInstance was causing different wings to merge
            -- The uniqueQueueID already includes the activeID, so duplicates are prevented
            -- local existingQueueID = self:FindExistingQueueByInstance(category, queueInfo.instanceName)
            -- if existingQueueID then
            --     self:MigrateQueueID(existingQueueID, uniqueQueueID)
            -- end

            -- Create or update queue
            if not self.queues[uniqueQueueID] then
                -- Log queue join to chat (helps with debugging display issues)
                print("|cff00ff00[QM]|r Joined: " .. (queueInfo.instanceName or "Unknown Queue"))

                -- Play subtle audio cue for queue join (if sound enabled)
                if self.settings and self.settings.soundEnabled then
                    PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_2)  -- Subtle notification sound
                end

                self:CreateNewQueue(uniqueQueueID, category, queueInfo, queueState)
            else
                self:UpdateExistingQueue(uniqueQueueID, queueInfo, queueState)
            end
        else
            if self.debugMode then
                self:Debug("No queue data for category " .. category .. " activeID " .. tostring(activeID))
            end
        end
    end

    if self.debugMode then
        self:Debug("ProcessStandardCategory complete - processed " .. processedCount .. " queues in category " .. category)
    end
end

function QueueMaster:CheckPvPQueues(foundActiveQueues)
    -- Check for PvP/Battleground queues
    for i = 1, GetMaxBattlefieldID() or 0 do
        local battlefieldStatus = self.SafeGetBattlefieldStatus(i)
        if battlefieldStatus then
            local pvpQueueID = "PVP_QUEUE_" .. i
            foundActiveQueues[pvpQueueID] = true
            
            if not self.queues[pvpQueueID] then
                local pvpCategory = self.QUEUE_CATEGORIES["pvp"]
                local startTime = GetTime()
                
                self.queues[pvpQueueID] = {
                    id = pvpQueueID,
                    category = "pvp",
                    categoryName = pvpCategory.name,
                    instanceName = battlefieldStatus.mapName,
                    type = battlefieldStatus.isArena and "Arena" or "Battleground",
                    queueCategory = "PvP",
                    startTime = startTime,
                    averageWait = battlefieldStatus.estimatedWaitTime or 600,
                    totalTanks = 0,
                    totalHealers = 0,
                    -- Ensure totalDPS is always a number, fallback to 10 for battlegrounds
                    totalDPS = type(battlefieldStatus.teamSize) == "number" and battlefieldStatus.teamSize or 10,
                    tankNeeds = 0,
                    healerNeeds = 0,
                    -- Ensure dpsNeeds is always a number, fallback to 10 for battlegrounds
                    dpsNeeds = type(battlefieldStatus.teamSize) == "number" and battlefieldStatus.teamSize or 10,
                    color = pvpCategory.color,
                    isProposal = (battlefieldStatus.status == "confirm"),
                    independent = true,
                    pvpIndex = i,
                    isArena = battlefieldStatus.isArena
                }
                
                self:SaveQueueStartTime(pvpQueueID, startTime)
                if self.debugMode then
                    self:Debug("Created PvP queue: " .. pvpQueueID .. " (" .. battlefieldStatus.mapName .. ")")
                end
                self:CreateQueueBar(pvpQueueID)
                self:UpdateQueueBarLayout() -- CRITICAL: Position bars after creation
                self:ShowMainFrame()
            else
                -- Update existing PvP queue
                local queue = self.queues[pvpQueueID]
                queue.isProposal = (battlefieldStatus.status == "confirm")
            end
        end
    end
end

function QueueMaster:FindExistingQueueByInstance(category, instanceName, activeID)
    -- CRITICAL FIX: Match by activeID if available, not just instance name
    -- Multiple LFR wings can have similar/same names but different activeIDs
    for queueID, queue in pairs(self.queues) do
        if queue.category == category then
            -- If we have activeIDs, match by activeID (most accurate)
            if activeID and queue.activeID and queue.activeID == activeID then
                return queueID
            -- Otherwise fall back to instance name matching
            elseif not activeID and queue.instanceName == instanceName then
                return queueID
            end
        end
    end
    return nil
end

function QueueMaster:MigrateQueueID(oldQueueID, newQueueID)
    if oldQueueID ~= newQueueID and not string.match(oldQueueID, "^QUEUE_") then
        -- Migrate old queue ID
        self.queues[newQueueID] = self.queues[oldQueueID]
        self.queues[oldQueueID] = nil
        if self.queueBars[oldQueueID] then
            self.queueBars[newQueueID] = self.queueBars[oldQueueID]
            self.queueBars[oldQueueID] = nil
            self.queueBars[newQueueID].queueID = newQueueID
        end
    end
end

function QueueMaster:CreateNewQueue(uniqueQueueID, category, queueInfo, queueState)
    local categoryInfo = self.QUEUE_CATEGORIES[category] or {name = "Unknown Queue", color = {0.5, 0.5, 0.5}}
    
    -- Check if we have a saved start time from previous sessions
    local savedStartTime = self:GetSavedQueueStartTime(uniqueQueueID)
    local calculatedStartTime
    
    if savedStartTime and savedStartTime > 0 then
        calculatedStartTime = savedStartTime
        if self.debugMode then
            self:Debug("Queue Creation Debug - " .. uniqueQueueID .. " using saved startTime: " .. calculatedStartTime)
        end
    else
        calculatedStartTime = GetTime()
        if self.debugMode then
            self:Debug("Queue Creation Debug - " .. uniqueQueueID .. " new startTime: " .. calculatedStartTime)
        end
        self:SaveQueueStartTime(uniqueQueueID, calculatedStartTime)
    end
    
    self.queues[uniqueQueueID] = {
        id = uniqueQueueID,
        category = category,
        categoryName = categoryInfo.name,
        instanceName = queueInfo.instanceName or categoryInfo.name,
        type = categoryInfo.name,
        queueCategory = categoryInfo.name,
        startTime = calculatedStartTime,
        averageWait = (queueInfo.averageWait or 0) / 60, -- Convert to minutes
        totalTanks = queueInfo.totalTanks or 1,
        totalHealers = queueInfo.totalHealers or 1,
        totalDPS = queueInfo.totalDPS or 3,
        tankNeeds = queueInfo.tankNeeds or 0,
        healerNeeds = queueInfo.healerNeeds or 0,
        dpsNeeds = queueInfo.dpsNeeds or 0,
        color = categoryInfo.color,
        isProposal = (queueState == "PROPOSAL"),
        independent = true,
        activeID = queueInfo.activeID
    }
    
    -- Save start time persistently for reload protection
    self:SaveQueueStartTime(uniqueQueueID, self.queues[uniqueQueueID].startTime)

    self:CreateQueueBar(uniqueQueueID)
    self:UpdateQueueBarLayout() -- CRITICAL: Position bars after creation

    -- CRITICAL FIX: Force bar to be visible immediately after creation and layout
    if self.queueBars and self.queueBars[uniqueQueueID] then
        local bar = self.queueBars[uniqueQueueID]
        bar:Show()
        self:Debug("FORCED bar visible after creation: " .. uniqueQueueID)

        -- EXTRA FIX: Force a second layout update after a tiny delay to ensure proper visibility
        -- This handles any race conditions between bar creation and layout system
        C_Timer.After(0.05, function()
            if bar and bar.Show then
                bar:Show()
                self:Debug("DOUBLE-CHECK: Bar forced visible (delayed): " .. uniqueQueueID)
            end
        end)
    end

    self:ShowMainFrame()
end

function QueueMaster:UpdateExistingQueue(uniqueQueueID, queueInfo, queueState)
    local queue = self.queues[uniqueQueueID]
    queue.averageWait = (queueInfo.averageWait or 0) / 60
    queue.totalTanks = queueInfo.totalTanks or queue.totalTanks
    queue.totalHealers = queueInfo.totalHealers or queue.totalHealers
    queue.totalDPS = queueInfo.totalDPS or queue.totalDPS
    queue.tankNeeds = queueInfo.tankNeeds or 0
    queue.healerNeeds = queueInfo.healerNeeds or 0
    queue.dpsNeeds = queueInfo.dpsNeeds or 0
    queue.isProposal = (queueState == "PROPOSAL")
    queue.activeID = queueInfo.activeID
end

function QueueMaster:CleanupInactiveQueues(foundActiveQueues)
    local currentTime = GetTime()
    
    for queueID in pairs(self.queues) do
        if not foundActiveQueues[queueID] and not string.find(queueID, "TEST_QUEUE_") then
            -- CRITICAL FIX: Don't remove queues during proposal state
            -- The queue is still active, just in proposal mode
            local queue = self.queues[queueID]
            if queue and queue.isProposal then
                if self.debugMode then
                    self:Debug("Preserving proposal queue during cleanup: " .. queueID)
                end
                -- Keep the queue but ensure it's marked as active
                foundActiveQueues[queueID] = true
            else
                -- GRACE PERIOD: Don't immediately remove queues to handle brief API lag
                -- Use shorter grace period for faster leave detection
                local gracePeriod = 2 -- Reduced from 10 to 2 seconds for faster queue leave detection
                if queue and queue.category == 3 then
                    gracePeriod = 3 -- LFR gets slightly longer - 3 seconds grace period
                end
                
                if not queue.lastSeenTime then
                    queue.lastSeenTime = currentTime
                    if self.debugMode then
                        self:Debug("Queue not detected, starting grace period (" .. gracePeriod .. "s): " .. queueID)
                    end
                elseif (currentTime - queue.lastSeenTime) > gracePeriod then
                    -- Grace period expired, verify queue is truly gone before removing
                    if self.debugMode then
                        self:Debug("Grace period expired for " .. queueID .. ", verifying queue status")
                    end

                    -- Double-check: Try one more time to detect the queue before removing
                    local stillQueued = false
                    if queue.category and queue.category ~= "pvp" then
                        local mode = self.SafeGetLFGMode(queue.category)
                        if mode == "queued" or mode == "proposal" or mode == "rolecheck" then
                            stillQueued = true
                            if self.debugMode then
                                self:Debug("Queue " .. queueID .. " still active per LFGMode, resetting grace period")
                            end
                        end
                    end

                    if stillQueued then
                        -- Reset grace period, queue is still active
                        queue.lastSeenTime = currentTime
                    else
                        -- Truly left the queue
                        print("|cffff0000[QM]|r Left queue: " .. (queue.instanceName or "Unknown"))
                        self:RemoveQueue(queueID)
                    end
                else
                    if self.debugMode then
                        self:Debug("Queue in grace period (" .. math.floor(currentTime - queue.lastSeenTime) .. "s/" .. gracePeriod .. "s): " .. queueID)
                    end
                end
            end
        else
            -- Queue was found, reset grace period
            local queue = self.queues[queueID]
            if queue then
                queue.lastSeenTime = currentTime
            end
        end
    end
end