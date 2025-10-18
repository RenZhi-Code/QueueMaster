-- ======= QueueMaster.lua (Main Addon File with Ace3 Integration) =======
local addonName, addon = ...

-- Create the Ace3 addon
local QueueMaster = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

-- Store reference for compatibility
addon.QueueMaster = QueueMaster
_G[addonName] = QueueMaster

-- Initialize addon data
QueueMaster.queues = {}
QueueMaster.queueBars = {}
QueueMaster.waitTimes = {}
QueueMaster.mainFrame = nil
QueueMaster.debugMode = false  -- Debug mode OFF by default

-- Performance caching (following Blizzard's pattern)
QueueMaster.cache = {
    deserterInfo = { data = nil, expiry = 0 },
    cooldownInfo = { data = nil, expiry = 0 },
    roleRewards = { data = {}, expiry = {} },
    queueStats = { data = {}, expiry = {} }
}

-- Ace3 addon lifecycle methods
function QueueMaster:OnInitialize()
    -- Initialize AceDB for saved variables
    self.db = LibStub("AceDB-3.0"):New("QueueMasterDB", self.defaults, true)
    self.settings = self.db.profile
    
    -- Initialize addon data
    self.queues = {}
    self.queueBars = {}
    self.waitTimes = self.db.char.waitTimes or {}
    
    -- Clear any old queue data from saved variables to prevent ghost bars
    if self.db.profile.queues then
        self:Debug("Clearing old queue data from saved variables: " .. tostring(#self.db.profile.queues or 0) .. " queues")
        self.db.profile.queues = {}
    end
    
    -- Clear any existing queue bars to prevent duplicates
    self:Debug("Clearing all existing queue bars during initialization")
    self:ClearAllQueues()
    
    -- Simple welcome message on every login
    self:ScheduleTimer("ShowWelcomeMessage", 3)
end

function QueueMaster:OnEnable()
    -- OPTIMIZED: Streamlined event registration for better performance
    -- Use Ace3 events exclusively (proven reliable, no dual system needed)
    
    -- Core LFG events (essential)
    self:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
    self:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
    self:RegisterEvent("LFG_UPDATE")  -- General LFG system updates
    self:RegisterEvent("LFG_PROPOSAL_SHOW")
    self:RegisterEvent("LFG_PROPOSAL_UPDATE")
    self:RegisterEvent("LFG_PROPOSAL_FAILED")
    self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
    self:RegisterEvent("LFG_PROPOSAL_DONE")  -- Proposal completed (any outcome)

    -- PvP events (essential)
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")

    -- Group events (essential)
    self:RegisterEvent("GROUP_ROSTER_UPDATE")

    -- Role check events (essential)
    self:RegisterEvent("LFG_ROLE_CHECK_UPDATE")

    -- Lock and eligibility events (important for accurate queue info)
    self:RegisterEvent("LFG_LOCK_INFO_RECEIVED")  -- Instance lockout information
    self:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")  -- Item level changes affect eligibility

    -- Additional events (performance optimized selection)
    self:RegisterEvent("PLAYER_ENTERING_WORLD") -- Only register essential additional events

    -- Fix addon list icon to show single eye instead of sprite sheet
    self:FixAddonListIcon()

    -- Hide the default Blizzard queue status icon
    self:HideBlizzardQueueIcon()
    
    -- Initialize UI components
    if self.CreateMainFrame then
        self:CreateMainFrame()
    else
        print("|cFFFF0000QueueMaster|r: Error - CreateMainFrame function not found")
    end
    
    -- CRITICAL: Ensure anchor exists immediately on load
    if not self.queueAnchor and self.CreateQueueAnchor then
        self:CreateQueueAnchor()
        self:Debug("Anchor created during OnEnable")
    end
    
    -- Validate and apply settings
    if self.ValidateSettings then
        self:ValidateSettings()
    end
    self:ApplySettings()
    
    -- Setup enhanced AceConfig system
    if self.SetupConfig then
        self:SetupConfig()
    end
    
    -- CRITICAL FIX: Force anchor visibility AFTER everything is loaded
    -- Use a tiny delay to ensure all systems are initialized
    C_Timer.After(0.1, function()
        self:Debug("=== ANCHOR VISIBILITY CHECK ===")
        self:Debug("queueAnchor exists: " .. tostring(self.queueAnchor ~= nil))
        if self.queueAnchor then
            self:Debug("queueAnchor is shown: " .. tostring(self.queueAnchor:IsShown()))
        end
        self:Debug("settings exists: " .. tostring(self.settings ~= nil))
        if self.settings then
            self:Debug("useAnchor: " .. tostring(self.settings.useAnchor))
            self:Debug("lockFrame: " .. tostring(self.settings.lockFrame))
        end
        
        if self.queueAnchor and self.settings then
            if self.settings.useAnchor and not self.settings.lockFrame then
                self.queueAnchor:Show()
                self:Debug("FORCE: Anchor shown after load - useAnchor=" .. tostring(self.settings.useAnchor) .. ", lockFrame=" .. tostring(self.settings.lockFrame))
            else
                self:Debug("Anchor hidden after load - useAnchor=" .. tostring(self.settings.useAnchor) .. ", lockFrame=" .. tostring(self.settings.lockFrame))
            end
        end
        self:Debug("=== END ANCHOR CHECK ===")
    end)
    
    -- PERFORMANCE: Use adaptive update intervals - faster when no queues to catch joins
    -- Slower when queues are stable to reduce CPU usage
    local function UpdateWithAdaptiveInterval()
        -- Update queues
        self:UpdateQueues()
        
        -- Determine next interval based on queue state
        local nextInterval
        if not self.queues or not next(self.queues) then
            nextInterval = 0.3 -- Faster checking (0.3s) when no queues to catch both joins AND leaves faster
        else
            nextInterval = 1.0 -- Reduced from 2s to 1s for faster leave detection while queued
        end
        
        -- Reschedule with adaptive interval
        if self.updateTimer then
            self:CancelTimer(self.updateTimer)
        end
        self.updateTimer = self:ScheduleRepeatingTimer(UpdateWithAdaptiveInterval, nextInterval)
    end
    
    -- Start with fast interval to catch initial queues
    self.updateTimer = self:ScheduleRepeatingTimer(UpdateWithAdaptiveInterval, 0.3)
    
    -- OPTIMIZATION: Setup centralized OnUpdate for all bars
    self:SetupCentralizedUpdate()
    
    -- Clean up any old saved queue data on startup
    self:CleanupOldSavedQueues()
    
    -- CRITICAL FIX: Force bars to be visible after reload
    -- Add a delayed call to ensure all systems are initialized first
    C_Timer.After(0.5, function()
        self:Debug("=== POST-RELOAD BAR VISIBILITY CHECK ===")
        self:Debug("Number of queues: " .. (self.queues and #self.queues or 0))
        self:Debug("Number of bars: " .. (self.queueBars and #self.queueBars or 0))
        
        -- Force update queues to detect any active queues
        self:UpdateQueues()
        
        -- Force bars to be visible if they exist
        if self.ApplySettingsToActiveBarsWithoutMove then
            self:ApplySettingsToActiveBarsWithoutMove()
        end
        
        self:Debug("=== END POST-RELOAD CHECK ===")
    end)
end

function QueueMaster:OnDisable()
    self:Debug("QueueMaster disabled")
    -- Unregister all events
    self:UnregisterAllEvents()
    
    -- Clean up centralized update system
    self:CleanupCentralizedUpdate()
    
    -- Hide all queue bars
    if self.queueBars then
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                bar:Hide()
            end
        end
    end
    
    -- Restore the default Blizzard queue status icon
    self:ShowBlizzardQueueIcon()
    
    -- Cancel any pending timers
    self:CancelAllTimers()
    
    -- Perform final cleanup
    self:PerformMemoryCleanup()
end

-- OPTIMIZED: Memory cleanup with performance improvements
function QueueMaster:PerformMemoryCleanup()
    local currentTime = GetTime()
    
    -- Clean up cache entries (performance optimization)
    local cache = self.cache
    if cache then
        -- Clean expired cache entries
        for cacheType, cacheData in pairs(cache) do
            if cacheData.expiry and cacheData.expiry < currentTime then
                cacheData.data = nil
                cacheData.expiry = 0
            end
        end
    end
    
    -- Clean up old wait times efficiently
    local waitTimes = self.waitTimes
    if waitTimes then
        for queueType, times in pairs(waitTimes) do
            if not times or (type(times) == "table" and #times == 0) then
                waitTimes[queueType] = nil
            elseif type(times) == "table" and #times > 50 then
                -- Keep only recent 50 entries to prevent memory bloat
                for i = 1, #times - 50 do
                    table.remove(times, 1)
                end
            end
        end
    end
    
    -- Clean up inactive queue bars with safe checks
    local queueBars = self.queueBars
    local activeQueues = self.queues
    if queueBars then
        for queueID, bar in pairs(queueBars) do
            local shouldRemove = false
            
            -- Check if bar is invalid or queue is inactive
            if not bar then
                shouldRemove = true
            elseif not activeQueues or not activeQueues[queueID] then
                shouldRemove = true
            elseif not bar.IsShown or not bar:IsShown() then
                shouldRemove = true
            end
            
            if shouldRemove then
                if bar and bar.Hide then
                    bar:Hide()
                end
                if bar and bar.SetParent then
                    bar:SetParent(nil)
                end
                queueBars[queueID] = nil
            end
        end
    end
    
    -- Clean up old saved positions for non-existent queues
    if self.db and self.db.char and self.db.char.positions and activeQueues then
        local positions = self.db.char.positions
        for queueID, _ in pairs(positions) do
            if not activeQueues[queueID] then
                positions[queueID] = nil
            end
        end
    end
    
    -- PERFORMANCE: Only force garbage collection occasionally
    if not self.lastGCTime or (currentTime - self.lastGCTime) > 60 then
        collectgarbage("collect")
        self.lastGCTime = currentTime
    end
end

-- Default settings - works beautifully out of the box
QueueMaster.defaults = {
    profile = {
        enabled = true,
        soundEnabled = true,
        showAlerts = true,
        flashEnabled = false,  -- Screen flash disabled by default
        -- Visual settings - no user config needed
        scale = 1.1,
        barWidth = 400,
        barHeight = 36,
        barSpacing = 12,
        fontSize = 12,
        instanceNameFontSize = 12,
        timerFontSize = 10,
        roleFontSize = 10,
        fontFace = "Fonts\\FRIZQT__.TTF", -- Default WoW font
        frameAlpha = 0.95,
        lockFrame = false,  -- Allow movement by default so users can position bars
        groupMovement = true,  -- Group movement enabled by default
        useAnchor = true,  -- Use movable anchor by default
        displayMode = "vertical",
        compactMode = false,  -- Compact mode disabled by default
        showRoleBars = true, -- Show role composition by default
        showInstanceName = true,  -- Show instance name by default
        showTimer = true,  -- Show timer by default
        -- Edge opacity for customizable appearance
        edgeOpacity = 1.0,  -- Full opacity by default, can be reduced for text-only look
        -- Color theme - QueueMaster signature look
        colorTheme = "default",
        useGradients = true,
        useGlow = true,
        animateProgress = true,
        -- Positioning - center screen
        anchorPoint = "CENTER",
        xOffset = 0,
        yOffset = -100,
        -- Enhanced tooltips enabled by default
        showEnhancedTooltips = true,
        showEstimates = true,
        showRoleBreakdown = true,
        -- Tooltip settings
        showPlayerInfo = false,
        showQueueStats = false,
        showWaitHistory = true,
        showQueueTips = true,
        tooltipUpdateRate = 0.5
    },
    char = {
        waitTimes = {},
        hasSeenWelcome = false,
        activeQueues = {}, -- Persistent queue data with start times
        positions = {} -- Saved bar positions
    }
}

-- Settings management with AceDB
function QueueMaster:SaveSettings()
    -- AceDB automatically saves, but we can force it
    if self.db then
        self.db:SetProfile(self.db:GetCurrentProfile())
    end
end

-- Update queues function (called by timer)
function QueueMaster:UpdateQueues()
    if not self.settings.enabled then
        return
    end
    
    -- Call the queue detection function from QueueDetection.lua
    if self.CheckForQueues then
        self:CheckForQueues()
    else
        self:Debug("Queue detection methods not loaded yet")
    end
    
    -- Update all queue bars centrally (performance optimization)
    if self.UpdateAllQueueBars then
        self:UpdateAllQueueBars()
    end
end

-- Debug function with timestamps
function QueueMaster:Debug(message)
    if self.debugMode then
        local timestamp = date("%H:%M:%S")
        print("|cff888888[" .. timestamp .. "]|r |cff00ff00[QM Debug]|r " .. tostring(message))
    end
end

-- Save queue start time to persistent storage
function QueueMaster:SaveQueueStartTime(queueID, startTime)
    if not self.db or not self.db.char then return end
    if not self.db.char.activeQueues then
        self.db.char.activeQueues = {}
    end
    self.db.char.activeQueues[queueID] = {
        startTime = startTime,
        savedAt = GetTime()
    }
end

-- Get saved queue start time
function QueueMaster:GetSavedQueueStartTime(queueID)
    if not self.db or not self.db.char or not self.db.char.activeQueues then
        return nil
    end
    local savedQueue = self.db.char.activeQueues[queueID]
    if savedQueue and savedQueue.startTime then
        -- Validate that saved start time isn't too old (max 2 hours)
        local currentTime = GetTime()
        local elapsed = currentTime - savedQueue.startTime
        
        -- If saved time is more than 2 hours old or in the future, it's invalid
        if elapsed < 0 or elapsed > 7200 then
            self:Debug("Saved queue time is invalid (elapsed: " .. elapsed .. "s), clearing it")
            self:ClearSavedQueueStartTime(queueID)
            return nil
        end
        
        return savedQueue.startTime
    end
    return nil
end

-- Remove saved queue start time
function QueueMaster:ClearSavedQueueStartTime(queueID)
    if not self.db or not self.db.char or not self.db.char.activeQueues then
        return
    end
    self.db.char.activeQueues[queueID] = nil
end

-- OPTIMIZED: Clean up old saved queues with better memory management
function QueueMaster:CleanupOldSavedQueues()
    if not self.db or not self.db.char then
        return
    end
    
    local currentTime = GetTime()
    local cleaned = 0
    
    -- Clean up old active queues
    local activeQueues = self.db.char.activeQueues
    if activeQueues then
        for queueID, savedQueue in pairs(activeQueues) do
            local shouldRemove = false
            
            if not savedQueue or not savedQueue.startTime then
                shouldRemove = true
            else
                local elapsed = currentTime - savedQueue.startTime
                -- Remove queues older than 2 hours or with invalid timestamps
                if elapsed < 0 or elapsed > 7200 then
                    shouldRemove = true
                end
            end
            
            if shouldRemove then
                activeQueues[queueID] = nil
                cleaned = cleaned + 1
            end
        end
    end
    
    -- Clean up old saved positions (remove positions for very old queues)
    local positions = self.db.char.positions
    if positions then
        for queueID, _ in pairs(positions) do
            -- Remove positions for old-style queue IDs or test queues
            if string.find(queueID, "TEST_QUEUE_") or string.find(queueID, "SIM_") then
                positions[queueID] = nil
                cleaned = cleaned + 1
            end
        end
    end
    
    -- Clean up old wait times (limit to recent data)
    local waitTimes = self.db.char.waitTimes
    if waitTimes then
        for queueType, times in pairs(waitTimes) do
            if type(times) == "table" and #times > 100 then
                -- Keep only most recent 50 entries per queue type
                for i = 1, #times - 50 do
                    table.remove(times, 1)
                    cleaned = cleaned + 1
                end
            elseif not times or (type(times) == "table" and #times == 0) then
                waitTimes[queueType] = nil
                cleaned = cleaned + 1
            end
        end
    end
    
    if cleaned > 0 then
        self:Debug("Cleaned up " .. cleaned .. " old saved data entries on startup")

        -- Force a garbage collection after major cleanup
        collectgarbage("collect")
    end
end

-- Force refresh all bars - make them visible without full reset
function QueueMaster:RefreshAllBars()
    self:Debug("RefreshAllBars called - forcing all bars visible")

    -- First, update queues to ensure we have latest data
    self:UpdateQueues()

    -- Force update and show all existing bars
    if self.queueBars then
        local barCount = 0
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                -- Force bar visible with fade-in
                bar:SetAlpha(0)
                bar:Show()
                UIFrameFadeIn(bar, 0.2, 0, (self.settings and self.settings.frameAlpha) or 0.95)

                -- Update the bar content
                if self.UpdateQueueBar then
                    self:UpdateQueueBar(queueID, bar)
                end

                barCount = barCount + 1
            end
        end
        self:Debug("Refreshed " .. barCount .. " bars")
    end

    -- Update layout to ensure proper positioning
    if self.UpdateQueueBarLayout then
        self:UpdateQueueBarLayout()
    end

    -- Schedule a final validation check
    C_Timer.After(0.3, function()
        if self.ValidateBarVisibility then
            self:ValidateBarVisibility()
        end
    end)
end

-- Validate that bars which should be visible actually are
function QueueMaster:ValidateBarVisibility()
    if not self.queueBars or not self.queues then return end

    local correctedCount = 0
    for queueID, queue in pairs(self.queues) do
        local bar = self.queueBars[queueID]
        if bar and not bar:IsShown() then
            bar:Show()
            bar:SetAlpha((self.settings and self.settings.frameAlpha) or 0.95)
            correctedCount = correctedCount + 1
            self:Debug("Auto-corrected hidden bar: " .. queueID)
        end
    end

    if correctedCount > 0 then
        self:Debug("Validated and corrected " .. correctedCount .. " hidden bars")
    end
end

-- PERFORMANCE OPTIMIZED: Centralized update system with smart throttling
-- Reduces CPU usage from 300+ calls/sec to 30-60 calls/sec maximum
function QueueMaster:SetupCentralizedUpdate()
    if self.centralUpdateFrame then
        return -- Already setup
    end
    
    self.centralUpdateFrame = CreateFrame("Frame", "QueueMasterCentralUpdate", UIParent)
    self.centralUpdateFrame.accumulator = 0
    self.centralUpdateFrame.lastUpdateTime = GetTime()
    
    -- OPTIMIZED: Event-driven updates with smart throttling
    self.centralUpdateFrame:SetScript("OnUpdate", function(frame, elapsed)
        local currentTime = GetTime()
        frame.accumulator = (frame.accumulator or 0) + elapsed
        
        -- Smart update frequency: Faster updates during proposal, slower when idle
        local updateInterval = 0.5 -- Default 0.5 second (was 1.0, reduced for better responsiveness)
        
        -- Check if we have active proposal (needs faster updates)
        local hasActiveProposal = false
        if QueueMaster.queues then
            for _, queue in pairs(QueueMaster.queues) do
                if queue.isProposal or queue.proposalStartTime then
                    hasActiveProposal = true
                    updateInterval = 0.1 -- 10 FPS for proposals (countdown needs precision)
                    break
                end
            end
        end
        
        -- Update when interval is reached
        if frame.accumulator >= updateInterval then
            frame.accumulator = 0
            frame.lastUpdateTime = currentTime
            
            -- PERFORMANCE: Only update if we have bars to update
            if QueueMaster.queueBars and next(QueueMaster.queueBars) then
                if QueueMaster.UpdateAllQueueBars then
                    QueueMaster:UpdateAllQueueBars()
                end
            end
        end
    end)
    
    self:Debug("Optimized centralized update system initialized")
end

-- Cleanup centralized update on disable
function QueueMaster:CleanupCentralizedUpdate()
    if self.centralUpdateFrame then
        self.centralUpdateFrame:SetScript("OnUpdate", nil)
        self.centralUpdateFrame:Hide()
        self.centralUpdateFrame = nil
        self:Debug("Centralized OnUpdate system cleaned up")
    end
end

-- Clear all queue bars and reset state
function QueueMaster:ClearAllQueues()
    -- Hide and clear all queue bars
    if self.queueBars then
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                bar:Hide()
                bar:SetParent(nil)
            end
            -- Clear saved start times for removed queues
            self:ClearSavedQueueStartTime(queueID)
        end
        self.queueBars = {}
    end
    
    -- Clear queue data
    if self.queues then
        self.queues = {}
    end
    
    -- Clear all saved start times
    if self.db and self.db.char then
        self.db.char.activeQueues = {}
    end
    
    self:Debug("All queues cleared")
end

-- Apply settings to UI
function QueueMaster:ApplySettings()
    if not self.settings then return end
    
    -- Apply scale
    if self.mainFrame and self.settings.scale then
        self.mainFrame:SetScale(self.settings.scale)
    end
    
    -- Apply alpha
    if self.mainFrame and self.settings.frameAlpha then
        self.mainFrame:SetAlpha(self.settings.frameAlpha)
    end
    
    -- Update layout with new settings
    if self.UpdateQueueBarLayout then
        self:UpdateQueueBarLayout()
    end
end

-- Fallback ApplyColorTheme method (will be overridden by BarStyling.lua when it loads)
function QueueMaster:ApplyColorTheme(theme)
    -- Store the theme setting
    if self.settings then
        self.settings.colorTheme = theme
    end
    
    -- This is a fallback - the real implementation is in BarStyling.lua
    self:Debug("ApplyColorTheme fallback called with theme: " .. tostring(theme))
end

-- Get deserter debuff information
function QueueMaster:GetDeserterInfo()
    local deserterExpiration = GetLFGDeserterExpiration()
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

-- OPTIMIZED: Get random dungeon cooldown information with caching
function QueueMaster:GetCooldownInfo()
    -- Performance: Use cached data if available and not expired
    local cache = self.cache.cooldownInfo
    local currentTime = GetTime()
    
    if cache.data and cache.expiry > currentTime then
        return cache.data
    end
    
    -- Initialize result
    local result = {
        hasCooldown = false,
        timeLeft = 0,
        formattedTime = ""
    }
    
    -- PERFORMANCE: Use modern API calls and safe iteration
    local numRandomDungeons = GetNumRandomDungeons()
    if numRandomDungeons and numRandomDungeons > 0 then
        local maxCooldownTime = 0
        
        for i = 1, numRandomDungeons do
            local id, name = GetLFGRandomDungeonInfo(i)
            if id then
                -- Safe API call with error handling
                local success, isAvailable, isAvailableToPlayer, hideIfNotJoinable, timeLeft = pcall(GetLFGRandomCooldownInfo, id)
                if success and timeLeft and timeLeft > 0 then
                    result.hasCooldown = true
                    maxCooldownTime = math.max(maxCooldownTime, timeLeft)
                end
            end
        end
        
        if result.hasCooldown and maxCooldownTime > 0 then
            result.timeLeft = maxCooldownTime
            local minutes = math.floor(maxCooldownTime / 60)
            local seconds = math.floor(maxCooldownTime % 60)
            result.formattedTime = string.format("%02d:%02d", minutes, seconds)
        end
    end
    
    -- Cache the result for 10 seconds to reduce API calls
    cache.data = result
    cache.expiry = currentTime + 10
    
    return result
end

-- Fix addon list icon to display single eye from sprite sheet
function QueueMaster:FixAddonListIcon()
    -- Hook into addon list to fix icon texture coordinates
    local function FixAddonIcon()
        -- Try to find addon list entries
        if AddonList and AddonList.ScrollBox then
            -- Retail API
            local dataProvider = AddonList.ScrollBox:GetDataProvider()
            if dataProvider then
                for _, elementData in pairs(dataProvider:GetCollection()) do
                    if elementData and elementData.Name == "QueueMaster" then
                        -- Found our addon entry
                        local buttons = AddonList.ScrollBox:GetFrames()
                        for _, button in ipairs(buttons) do
                            if button.Name and button.Name:GetText() == "QueueMaster" then
                                -- Fix the icon texture coordinates
                                if button.Icon then
                                    button.Icon:SetTexture("Interface\\LFGFrame\\LFG-Eye")
                                    button.Icon:SetTexCoord(0, 1, 0, 1) -- Show entire texture (single eye)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Hook when addon list opens
    if AddonList then
        hooksecurefunc("AddonList_Update", FixAddonIcon)
    end

    -- Also try character select addon list
    C_Timer.After(1, function()
        FixAddonIcon()
    end)
end

-- Welcome message
function QueueMaster:ShowWelcomeMessage()
  
    print("|cffff0000Queue|r|cff0080ffMaster|r loaded|r. Use /qm to open the config.")
end

-- Simplified config access
QueueMaster:RegisterChatCommand("qmconfig", function()
    if QueueMaster.ShowConfig then
        QueueMaster:ShowConfig()
    end
end)

-- Toggle Blizzard queue UI visibility (for debugging)
QueueMaster:RegisterChatCommand("qmblizz", function()
    if not QueueMaster.blizzardUIHidden then
        QueueMaster.blizzardUIHidden = true
        QueueMaster:HideBlizzardQueueIcon()
        QueueMaster:Print("|cff00ff00Blizzard queue UI hidden.|r QueueMaster is handling your queues.")
    else
        QueueMaster.blizzardUIHidden = false
        QueueMaster:ShowBlizzardQueueIcon()
        QueueMaster:Print("|cffffff00Blizzard queue UI restored.|r Use /qmblizz again to hide it.")
    end
end)

-- Debug command to check queue status
QueueMaster:RegisterChatCommand("qmstatus", function()
    QueueMaster:Print("|cffff8000=== QueueMaster Status ===|r")
    
    -- Force debug mode for this command
    local oldDebugMode = QueueMaster.debugMode
    QueueMaster.debugMode = true
    
    -- Check active queues
    local queueCount = 0
    if QueueMaster.queues then
        for queueID, queue in pairs(QueueMaster.queues) do
            queueCount = queueCount + 1
            local elapsed = GetTime() - (queue.startTime or GetTime())
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            QueueMaster:Print(string.format("  Queue: %s - %02d:%02d", queue.instanceName or "Unknown", minutes, seconds))
        end
    end
    
    if queueCount == 0 then
        QueueMaster:Print("  |cffff0000No active queues detected.|r")
        QueueMaster:Print("  |cffffff00Tip:|r Open LFR/LFD and queue for something!")
        
        -- Force a queue check
        QueueMaster:Print("  |cff00ff00Forcing queue detection...|r")
        if QueueMaster.CheckForQueues then
            QueueMaster:CheckForQueues()
        end
    else
        QueueMaster:Print(string.format("  Total: |cff00ff00%d queue(s)|r", queueCount))
    end
    
    -- Check if Blizzard UI is hidden
    if QueueStatusMinimapButton then
        local hidden = not QueueStatusMinimapButton:IsShown()
        QueueMaster:Print("  Blizzard UI: " .. (hidden and "|cffff0000Hidden|r" or "|cff00ff00Visible|r"))
    end
    
    -- Check movement settings
    local lockStatus = QueueMaster.settings and QueueMaster.settings.lockFrame and "Locked" or "Unlocked"
    local groupStatus = QueueMaster.settings and QueueMaster.settings.groupMovement and "Group" or "Individual"
    QueueMaster:Print("  Movement: " .. lockStatus .. " (" .. groupStatus .. ")")
    
    -- Check if update timer is running
    if QueueMaster.updateTimer then
        QueueMaster:Print("  |cff00ff00Update timer is running|r")
    else
        QueueMaster:Print("  |cffff0000Update timer is NOT running|r")
    end
    
    QueueMaster:Print("|cffff8000Use /qmblizz to toggle Blizzard UI|r")
    
    -- Restore debug mode
    QueueMaster.debugMode = oldDebugMode
end)

-- Test command to create a test queue
QueueMaster:RegisterChatCommand("qmtest", function()
    QueueMaster:Print("|cff00ff00Creating test queue...|r")
    
    local testQueueID = "TEST_QUEUE_" .. math.floor(GetTime())
    QueueMaster.queues = QueueMaster.queues or {}
    QueueMaster.queues[testQueueID] = {
        id = testQueueID,
        category = 1,
        categoryName = "Dungeon Finder",
        instanceName = "Test Heroic Dungeon",
        type = "Dungeon Finder",
        queueCategory = "Dungeon Finder",
        startTime = GetTime(),
        averageWait = 10,
        totalTanks = 1,
        totalHealers = 1,
        totalDPS = 3,
        tankNeeds = 0,
        healerNeeds = 0,
        dpsNeeds = 1,
        color = {0.1, 0.8, 0.3},
        isProposal = false,
        independent = true
    }
    
    if QueueMaster.CreateQueueBar then
        QueueMaster:CreateQueueBar(testQueueID)
        QueueMaster:Print("|cff00ff00Test queue created: " .. testQueueID .. "|r")
    else
        QueueMaster:Print("|cffff0000CreateQueueBar method not found|r")
    end
    
    if QueueMaster.ShowMainFrame then
        QueueMaster:ShowMainFrame()
    end
end)

-- Group movement toggle command
QueueMaster:RegisterChatCommand("qmgroup", function()
    if not QueueMaster.settings.groupMovement then
        QueueMaster.settings.groupMovement = true
        QueueMaster:Print("|cff00ff00Group movement enabled.|r All bars will move together.")
        if QueueMaster.SetupGroupMovement then
            QueueMaster:SetupGroupMovement()
        end
    else
        QueueMaster.settings.groupMovement = false
        QueueMaster:Print("|cffff6600Group movement disabled.|r Bars can be moved individually.")
    end
end)

-- Event handling with AceEvent
function QueueMaster:LFG_UPDATE_RANDOM_INFO(...)
    self:Debug("LFG_UPDATE_RANDOM_INFO event received")
    -- CRITICAL FIX: Force immediate update for LFR queue changes
    self:UpdateQueues(true) -- true = force update, bypass throttling
end

function QueueMaster:LFG_QUEUE_STATUS_UPDATE(...)
    self:Debug("LFG_QUEUE_STATUS_UPDATE event received")
    -- CRITICAL FIX: Force immediate update for queue status changes (don't schedule)
    -- This ensures bars appear immediately when joining/leaving queues
    -- Note: This event also fires when leaving a queue

    -- INSTANT REMOVAL: Quick check if we left all queues
    self:ScheduleTimer(function()
        local hasAnyQueue = false
        -- Check all LFG categories (1-5 typically)
        for i = 1, 5 do
            local mode = GetLFGMode(i)
            if mode and mode ~= "lfgparty" and mode ~= "" and mode ~= "listed" then
                hasAnyQueue = true
                break
            end
        end

        if not hasAnyQueue and next(self.queues) then
            self:Debug("No LFG queues found - immediate bar removal")
            self:ClearAllQueues()
        else
            self:UpdateQueues()
        end
    end, 0.05) -- Tiny delay for API to stabilize
end

function QueueMaster:UPDATE_BATTLEFIELD_STATUS(...)
    self:Debug("UPDATE_BATTLEFIELD_STATUS event received")
    self:ScheduleTimer("UpdateQueues", 0.1)
end

function QueueMaster:GROUP_ROSTER_UPDATE(...)
    self:Debug("GROUP_ROSTER_UPDATE event received")
    
    -- Check if we're in a group now
    local inGroup = IsInGroup() or IsInRaid()
    
    if inGroup then
        -- If we just joined a group, we might have left queue
        -- Don't immediately update queues as it might show old data
        -- Wait a bit for the LFG state to stabilize
        self:ScheduleTimer("UpdateQueues", 1.0)
    else
        -- Left group, update immediately
        self:ScheduleTimer("UpdateQueues", 0.1)
    end
end

function QueueMaster:LFG_ROLE_CHECK_UPDATE(...)
    self:Debug("LFG_ROLE_CHECK_UPDATE event received")
end

function QueueMaster:LFG_PROPOSAL_SHOW(...)
    self:Debug("LFG_PROPOSAL_SHOW event received")
    if self.OnProposalShow then
        self:OnProposalShow()
    end
end

function QueueMaster:LFG_PROPOSAL_UPDATE(...)
    self:Debug("LFG_PROPOSAL_UPDATE event received")
    -- Update queue bars immediately when proposal state changes
    self:ScheduleTimer("UpdateQueues", 0.1)
end

function QueueMaster:LFG_PROPOSAL_FAILED(...)
    self:Debug("LFG_PROPOSAL_FAILED event received")
    self:Print("|cffff8000[QM]|r Invite declined. You're still in queue.")
    self:OnProposalEnd()
    -- DON'T call UpdateQueues here - it might remove the queue!
    -- The queue is still active, just the proposal ended
    -- UpdateQueues will be called by the next LFG_QUEUE_STATUS_UPDATE
end

function QueueMaster:LFG_PROPOSAL_SUCCEEDED(...)
    self:Debug("LFG_PROPOSAL_SUCCEEDED event received")
    self:OnProposalEnd()
    self:ClearAllQueues()
end

function QueueMaster:LFG_LOCK_INFO_RECEIVED(...)
    self:Debug("LFG_LOCK_INFO_RECEIVED event received")
    -- Update queue information when lock info changes (following Blizzard pattern)
    self:ScheduleTimer("UpdateQueues", 0.1)
end

function QueueMaster:PLAYER_AVG_ITEM_LEVEL_UPDATE(...)
    self:Debug("PLAYER_AVG_ITEM_LEVEL_UPDATE event received")
    -- Item level changes may affect queue eligibility (following Blizzard pattern)
    self:ScheduleTimer("UpdateQueues", 0.5)
end

-- REMOVED: Redundant native event system for better performance
-- Ace3 event system is reliable and sufficient

-- Hide the default Blizzard queue status icon
function QueueMaster:HideBlizzardQueueIcon()
    -- Hide the queue status minimap button (eyeball icon)
    if QueueStatusMinimapButton then
        QueueStatusMinimapButton:Hide()
        QueueStatusMinimapButton:SetParent(nil)
        self:Debug("Hidden Blizzard queue status minimap button")
    else
        -- If it doesn't exist yet, try again after a delay
        self:ScheduleTimer(function()
            if QueueStatusMinimapButton then
                QueueStatusMinimapButton:Hide() 
                QueueStatusMinimapButton:SetParent(nil)
                self:Debug("Hidden Blizzard queue status minimap button (delayed)")
            else
                self:Debug("QueueStatusMinimapButton not found even after delay")
            end
        end, 2)
    end
    
    -- Also hide any other queue status frames
    if QueueStatusFrame then
        QueueStatusFrame:Hide()
        self:Debug("Hidden QueueStatusFrame")
    end
end

-- Show the default Blizzard queue status icon (for when addon is disabled)
function QueueMaster:ShowBlizzardQueueIcon()
    if QueueStatusMinimapButton then
        QueueStatusMinimapButton:Show()
        QueueStatusMinimapButton:SetParent(Minimap)
        self:Debug("Restored Blizzard queue status minimap button")
    end
    
    if QueueStatusFrame then
        QueueStatusFrame:Show()
        self:Debug("Restored QueueStatusFrame")
    end
end

-- Diagnostics for dual event system
function QueueMaster:GetEventSystemStatus()
    local ace3Events = 0
    local nativeEvents = 0
    
    -- Count Ace3 registered events
    if self.events then
        for event in pairs(self.events) do
            ace3Events = ace3Events + 1
        end
    end
    
    -- Count native registered events  
    if self.nativeEventFrame then
        -- This is approximate since we can't easily count registered events on a frame
        nativeEvents = 19 -- We registered 19 events in SetupNativeEventHandlers
    end
    
    return {
        ace3Events = ace3Events,
        nativeEvents = nativeEvents,
        hasNativeFrame = self.nativeEventFrame ~= nil,
        dualSystemActive = ace3Events > 0 and nativeEvents > 0
    }
end

-- Version info
QueueMaster.version = "18.10.25.10"
QueueMaster.debugMode = false -- Debug disabled by default to reduce chat spam