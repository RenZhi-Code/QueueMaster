-- ======= Core/UI/BarUpdate.lua =======
-- Queue bar updating and lifecycle management
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- CRITICAL: Ensure required methods exist before any other code runs
-- GetDeserterInfo method - checks for LFG deserter debuff
if not QueueMaster.GetDeserterInfo then
    function QueueMaster:GetDeserterInfo()
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
end

-- GetCooldownInfo method - checks for random dungeon cooldowns
if not QueueMaster.GetCooldownInfo then
    function QueueMaster:GetCooldownInfo()
        local hasCooldown = false
        local cooldownTime = 0
        local formattedTime = ""
        
        -- Simple implementation - check for any active cooldowns
        if GetNumRandomDungeons then
            for i = 1, GetNumRandomDungeons() do
                local id, name = GetLFGRandomDungeonInfo(i)
                if id and GetLFGRandomCooldownInfo then
                    local isAvailable, isAvailableToPlayer, hideIfNotJoinable, timeLeft = GetLFGRandomCooldownInfo(id)
                    if timeLeft and timeLeft > 0 then
                        hasCooldown = true
                        cooldownTime = math.max(cooldownTime, timeLeft)
                    end
                end
            end
        end
        
        if hasCooldown and cooldownTime > 0 then
            local minutes = math.floor(cooldownTime / 60)
            local seconds = math.floor(cooldownTime % 60)
            formattedTime = string.format("%02d:%02d", minutes, seconds)
        end
        
        return {
            hasCooldown = hasCooldown,
            timeLeft = cooldownTime,
            formattedTime = formattedTime
        }
    end
end

-- Optimized queue bar update with memory management
function QueueMaster:UpdateAllQueueBars()
    local queueBars = self.queueBars

    if not queueBars then
        self:Debug("UpdateAllQueueBars: No queueBars table")
        return
    end

    -- OPTIMIZATION: Single iteration for count + update + cleanup
    local currentTime = GetTime()
    local barCount = 0
    local toRemove = {}

    for queueID, bar in pairs(queueBars) do
        barCount = barCount + 1

        if not bar or not bar.queueID then
            toRemove[#toRemove + 1] = queueID
        else
            -- ALWAYS update timers every call to ensure they show immediately
            self:UpdateQueueBar(queueID, bar)
            bar.lastUpdate = currentTime

            -- CRITICAL FIX: Enhanced visibility enforcement
            -- Check both visibility state AND alpha transparency
            local targetAlpha = bar.targetAlpha or (self.settings and self.settings.frameAlpha) or 0.95

            if not bar:IsShown() then
                bar:Show()
                if self.debugMode then
                    self:Debug("Forced show for hidden bar: " .. queueID)
                end
            end

            -- Also check if alpha is too low (effectively invisible)
            local currentAlpha = bar:GetAlpha()
            if currentAlpha < targetAlpha * 0.8 then
                bar:SetAlpha(targetAlpha)
                if self.debugMode then
                    self:Debug("Restored alpha for bar " .. queueID .. " from " .. currentAlpha .. " to " .. targetAlpha)
                end
            end
        end
    end

    if self.debugMode then
        self:Debug("UpdateAllQueueBars: Found " .. barCount .. " bars to update")
    end

    -- Remove invalid bars
    for i = 1, #toRemove do
        local queueID = toRemove[i]
        if queueBars[queueID] then
            queueBars[queueID] = nil
        end
    end
end

function QueueMaster:UpdateQueueBar(queueID, bar)
    if self.debugMode then
        self:Debug("UpdateQueueBar called for " .. tostring(queueID))
    end
    -- Handle both direct queue data and queueID parameter
    local queueData
    if type(queueID) == "table" then
        -- First parameter is queue data
        queueData = queueID
        queueID = queueData.id
        bar = bar or (self.queueBars and self.queueBars[queueID])
    else
        -- First parameter is queueID
        queueData = self.queues and self.queues[queueID]
        bar = bar or (self.queueBars and self.queueBars[queueID])
    end
    
    if not queueData then
        return 
    end
    
    if not bar then
        return
    end
    
    -- OPTIMIZATION: Cache GetTime() for entire update cycle
    local currentTime = GetTime()
    if not bar.lastFrameTime or bar.lastFrameTime ~= currentTime then
        bar.lastFrameTime = currentTime
    end
    
    -- PERFORMANCE: Only build debug strings when debug mode is on
    if self.debugMode then
        self:Debug("Timer Debug - Queue: " .. queueID .. ", CurrentTime: " .. currentTime .. ", StartTime: " .. (queueData.startTime or "nil"))
    end
    
    -- CRITICAL: Ensure startTime is always valid and set
    if not queueData.startTime or queueData.startTime <= 0 or queueData.startTime > currentTime then
        -- Check if we have a saved start time from previous sessions
        local savedStartTime = self:GetSavedQueueStartTime(queueID)
        if savedStartTime and savedStartTime > 0 and savedStartTime <= currentTime then
            queueData.startTime = savedStartTime
            if self.debugMode then
                self:Debug("Restored saved startTime for queue " .. queueID .. ": " .. savedStartTime)
            end
        else
            -- FORCE set startTime to current time if missing or invalid
            queueData.startTime = currentTime
            queueData.timerStarted = true
            -- Save this start time persistently
            self:SaveQueueStartTime(queueID, queueData.startTime)
            if self.debugMode then
                self:Debug("FORCED new startTime for queue " .. queueID .. " to: " .. queueData.startTime)
            end
        end
    end
    
    -- Calculate elapsed time - prioritize API queuedTime if reliable
    local elapsed = 0
    local apiElapsed = nil
    
    -- OPTIMIZATION: Use cached category and activeID instead of parsing every time
    -- CHECK CACHE FIRST before parsing
    local category = bar.cachedCategory
    local activeID = bar.cachedActiveID
    
    -- Only parse if cache is missing (first time setup)
    if not category or not activeID then
        category, activeID = string.match(queueID, "QUEUE_(%d+)_(%d+)")
        if category and activeID then
            category = tonumber(category)
            activeID = tonumber(activeID)
            -- Cache for future updates
            bar.cachedCategory = category
            bar.cachedActiveID = activeID
            if self.debugMode then
                self:Debug("Cached queueID data - category: " .. tostring(category) .. ", activeID: " .. tostring(activeID))
            end
        end
    end
    
    -- Call GetLFGQueueStats to get current queuedTime if category and activeID are valid
    if category and activeID and GetLFGQueueStats then
        local success, hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, totalTanks, totalHealers, totalDPS, instanceType, instanceSubType, instanceName, averageWait, tankWait, healerWait, dpsWait, myWait, queuedTime = pcall(GetLFGQueueStats, category, activeID)
        if success and hasData and queuedTime and queuedTime > 0 then
            -- API provided queuedTime - but validate it's reasonable
            -- queuedTime should be the time when queue started (absolute time)
            local apiCalculatedElapsed = currentTime - queuedTime
            if apiCalculatedElapsed >= 0 and apiCalculatedElapsed < 86400 then -- Less than 24 hours
                apiElapsed = apiCalculatedElapsed
                if self.debugMode then
                    self:Debug("Timer Debug - Using API queuedTime: " .. queuedTime .. " (elapsed: " .. apiElapsed .. ")")
                end
                
                -- Update our stored startTime to match API if significantly different
                if math.abs(queueData.startTime - queuedTime) > 5 then
                    queueData.startTime = queuedTime
                    self:SaveQueueStartTime(queueID, queueData.startTime)
                    if self.debugMode then
                        self:Debug("Updated startTime to match API: " .. queuedTime)
                    end
                end
            else
                if self.debugMode then
                    self:Debug("Timer Debug - API queuedTime invalid (" .. (queuedTime or "nil") .. "), calculated elapsed: " .. (apiCalculatedElapsed or "nil"))
                end
            end
        else
            if self.debugMode then
                self:Debug("Timer Debug - API call failed or no queuedTime. success: " .. tostring(success) .. ", hasData: " .. tostring(hasData) .. ", queuedTime: " .. tostring(queuedTime))
            end
        end
    end
    
    -- Use API elapsed time if available and valid, otherwise use calculated
    if apiElapsed and apiElapsed >= 0 then
        elapsed = apiElapsed
        if self.debugMode then
            self:Debug("Timer Debug - Using API elapsed time: " .. elapsed)
        end
    else
        elapsed = currentTime - queueData.startTime
        if self.debugMode then
            self:Debug("Timer Debug - Using calculated elapsed: " .. currentTime .. " - " .. queueData.startTime .. " = " .. elapsed)
        end
        
        -- Ensure elapsed time is positive (prevent negative times)
        if elapsed < 0 then
            elapsed = 0
            if self.debugMode then
                self:Debug("Negative elapsed time detected, reset to 0")
            end
        end
    end
    
    -- Format timer based on duration (H:MM:SS for 60+ mins, MM:SS otherwise)
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    local timerText
    if hours > 0 then
        -- Format as H:MM:SS for times over 60 minutes
        timerText = string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        -- Format as MM:SS for times under 60 minutes
        timerText = string.format("%02d:%02d", minutes, seconds)
    end
    
    if self.debugMode then
        self:Debug("Timer Debug - Final: " .. timerText)
    end
    
    -- Check for deserter/cooldown status first (following Blizzard's pattern)
    local deserterInfo = { hasDeserter = false, formattedTime = "" }
    local cooldownInfo = { hasCooldown = false, formattedTime = "" }
    
    -- Use local functions to avoid method access issues
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
        local hasCooldown = false
        local cooldownTime = 0
        local formattedTime = ""
        
        if GetNumRandomDungeons then
            for i = 1, GetNumRandomDungeons() do
                local id, name = GetLFGRandomDungeonInfo(i)
                if id and GetLFGRandomCooldownInfo then
                    local isAvailable, isAvailableToPlayer, hideIfNotJoinable, timeLeft = GetLFGRandomCooldownInfo(id)
                    if timeLeft and timeLeft > 0 then
                        hasCooldown = true
                        cooldownTime = math.max(cooldownTime, timeLeft)
                    end
                end
            end
        end
        
        if hasCooldown and cooldownTime > 0 then
            local minutes = math.floor(cooldownTime / 60)
            local seconds = math.floor(cooldownTime % 60)
            formattedTime = string.format("%02d:%02d", minutes, seconds)
        end
        
        return {
            hasCooldown = hasCooldown,
            timeLeft = cooldownTime,
            formattedTime = formattedTime
        }
    end
    
    -- Get the information using local functions
    deserterInfo = GetDeserterInfoLocal()
    cooldownInfo = GetCooldownInfoLocal()
    
    -- Update main text with enhanced queue type display and independent tracking
    local queueName = queueData.instanceName or queueData.categoryName or queueData.name or "Unknown Queue"
    local queueTypeText = queueData.type or queueData.queueType or queueData.categoryName or "Queue"
    
    -- Enhanced display with wing/activeID differentiation for multiple queues of same raid
    local displayText = queueName
    if queueData.queueCategory and queueData.queueCategory ~= queueTypeText then
        displayText = string.format("[%s] %s", queueData.queueCategory, queueName)
    end
    
    -- Build the full text with timer
    local mainText
    
    -- Check user settings for what to display
    local showInstanceName = true
    local showTimer = true
    if self.settings then
        if self.settings.showInstanceName ~= nil then
            showInstanceName = self.settings.showInstanceName
        end
        if self.settings.showTimer ~= nil then
            showTimer = self.settings.showTimer
        end
    end
    
    -- Priority 1: Show deserter debuff (following Blizzard's pattern)
    if deserterInfo.hasDeserter then
        local deserterSuffix = string.format(" - |cffff0000DESERTER: %s|r", deserterInfo.formattedTime)
        
        -- SMART DYNAMIC TRUNCATION for deserter
        if bar.text then
            local barWidth = bar:GetWidth()
            local roleTextWidth = 0
            
            if bar.roleText and bar.roleText:IsVisible() then
                roleTextWidth = bar.roleText:GetStringWidth() + 30
            end
            
            local availableWidth = barWidth - 30 - roleTextWidth
            
            -- Measure deserter suffix width
            bar.text:SetText(deserterSuffix)
            local deserterWidth = bar.text:GetStringWidth()
            
            -- Available width for queue name
            local queueNameWidth = availableWidth - deserterWidth
            
            if queueNameWidth > 0 then
                displayText = self:TruncateText(displayText, queueNameWidth, bar.text)
            end
        end
        
        mainText = displayText .. deserterSuffix
    -- Priority 2: Show cooldown
    elseif cooldownInfo.hasCooldown then
        local cooldownSuffix = string.format(" - |cffffff00COOLDOWN: %s|r", cooldownInfo.formattedTime)
        
        -- SMART DYNAMIC TRUNCATION for cooldown
        if bar.text then
            local barWidth = bar:GetWidth()
            local roleTextWidth = 0
            
            if bar.roleText and bar.roleText:IsVisible() then
                roleTextWidth = bar.roleText:GetStringWidth() + 30
            end
            
            local availableWidth = barWidth - 30 - roleTextWidth
            
            -- Measure cooldown suffix width
            bar.text:SetText(cooldownSuffix)
            local cooldownWidth = bar.text:GetStringWidth()
            
            -- Available width for queue name
            local queueNameWidth = availableWidth - cooldownWidth
            
            if queueNameWidth > 0 then
                displayText = self:TruncateText(displayText, queueNameWidth, bar.text)
            end
        end
        
        mainText = displayText .. cooldownSuffix
    -- Priority 3: Check if we have an active proposal (invite) and show countdown
    elseif queueData.isProposal and queueData.proposalStartTime and queueData.proposalTimeout then
        -- Use cached currentTime instead of calling GetTime() again
        local proposalElapsed = currentTime - queueData.proposalStartTime
        local remainingTime = math.max(0, queueData.proposalTimeout - proposalElapsed)
        
        if remainingTime > 0 then
            -- CLEAN INVITE DISPLAY: Just "INVITE" + countdown timer
            local countdownSeconds = math.ceil(remainingTime)
            
            -- Dynamic color based on urgency (smooth gradient)
            local timeColor
            local barColor = {r = 0.1, g = 0.8, b = 0.3}  -- Default green
            
            if countdownSeconds > 20 then
                -- GREEN phase (plenty of time)
                timeColor = "|cff00ff00"
                barColor = {r = 0.1, g = 0.8, b = 0.3}
            elseif countdownSeconds > 5 then
                -- AMBER/ORANGE phase (getting close)
                timeColor = "|cffffa500"
                barColor = {r = 1.0, g = 0.65, b = 0.0}
            else
                -- RED phase (last 5 seconds - URGENT!)
                timeColor = "|cffff0000"
                barColor = {r = 1.0, g = 0.2, b = 0.1}
                
                -- Pulse effect for last 5 seconds
                local pulseCycle = math.sin(GetTime() * 6) * 0.5 + 0.5
                barColor.r = 0.7 + (pulseCycle * 0.3)
                barColor.g = 0.1 + (pulseCycle * 0.1)
            end
            
            -- Apply urgent bar coloring
            if bar.SetStatusBarColor then
                bar:SetStatusBarColor(barColor.r, barColor.g, barColor.b, 0.95)
            end
            if bar.border then
                bar.border:SetBackdropBorderColor(barColor.r, barColor.g, barColor.b, 1.0)
            end
            
            -- Simple, bold text: "INVITE - 38" (no "s" suffix for cleaner look)
            mainText = string.format("|cffffffff|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16:0:0|t INVITE|r %s%d|r", timeColor, countdownSeconds)
            
            -- Make bar clickable to accept invite
            if bar.button then
                bar.button:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" then
                        -- Accept the proposal
                        AcceptProposal()
                        QueueMaster:Print("Accepting invite...")
                    elseif button == "RightButton" then
                        -- Reject the proposal
                        RejectProposal()
                        QueueMaster:Print("Declined invite.")
                    end
                end)
                
                -- Update button registration to allow both clicks
                bar.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            end
        else
            -- Invite expired, remove proposal state
            queueData.isProposal = false
            queueData.proposalStartTime = nil
            queueData.proposalTimeout = nil
            
            -- Restore normal click behavior
            if bar.button then
                bar.button:SetScript("OnClick", function(self, button)
                    if button == "RightButton" and QueueMaster.ShowConfig then
                        QueueMaster:ShowConfig()
                    end
                end)
            end
            
            -- Use smart truncation for expired invite timer too
            local timerSuffix = string.format(" - |cffffff00%s|r", timerText)
            
            if bar.text then
                local barWidth = bar:GetWidth()
                local roleTextWidth = 0
                
                if bar.roleText and bar.roleText:IsVisible() then
                    roleTextWidth = bar.roleText:GetStringWidth() + 30
                end
                
                local availableWidth = barWidth - 30 - roleTextWidth
                
                -- Measure timer width
                bar.text:SetText(timerSuffix)
                local timerWidth = bar.text:GetStringWidth()
                
                -- Available width for queue name
                local queueNameWidth = availableWidth - timerWidth
                
                if queueNameWidth > 0 then
                    displayText = self:TruncateText(displayText, queueNameWidth, bar.text)
                end
            end
            
            mainText = displayText .. timerSuffix
        end
    else
        -- Clean, minimal timer display: "[LFR] Trial of Valor - 00:02" or "[LFR] Trial of Valor - 1:05:32"
        -- Build text based on user settings AND bar width
        local parts = {}
        
        -- SMART ADAPTIVE LAYOUT based on bar width
        local barWidth = bar:GetWidth()
        
        -- Check user preferences
        local userWantsInstanceName = true
        local userWantsTimer = true
        local userWantsRoles = true
        
        if self.settings then
            if self.settings.showInstanceName ~= nil then
                userWantsInstanceName = self.settings.showInstanceName
            end
            if self.settings.showTimer ~= nil then
                userWantsTimer = self.settings.showTimer
            end
            if self.settings.showRoleBars ~= nil then
                userWantsRoles = self.settings.showRoleBars
            end
        end
        
        -- PRIORITY SYSTEM based on bar width:
        -- COMPACT MODE: Show all elements down to 200px width with aggressive truncation
        -- NORMAL MODE:
        --   1. VERY NARROW (< 250px): TIMER ONLY (most critical info)
        --   2. NARROW (250-300px): Instance Name + Timer (truncated name)
        --   3. NORMAL (>= 300px): All 3 elements (with dynamic truncation)
        
        local showInstanceName = userWantsInstanceName
        local showTimer = userWantsTimer
        local showRoles = userWantsRoles
        
        -- Check if compact mode is enabled
        local isCompactMode = self.settings and self.settings.compactMode or false
        
        if isCompactMode then
            -- COMPACT MODE: Show everything user wants, let truncation handle fitting
            -- All elements visible down to minimum bar width (200px)
            showInstanceName = userWantsInstanceName
            showTimer = userWantsTimer
            showRoles = userWantsRoles
        else
            -- NORMAL MODE: Hide elements based on width
            if barWidth < 250 then
                -- VERY NARROW: Timer only for ultra-compact display
                showInstanceName = false
                showRoles = false
                showTimer = userWantsTimer  -- Respect user preference
            elseif barWidth < 300 then
                -- NARROW: Instance + Timer, hide roles to preserve space
                showInstanceName = userWantsInstanceName
                showTimer = userWantsTimer
                showRoles = false
            else
                -- NORMAL: Show everything user wants (dynamic truncation handles fit)
                showInstanceName = userWantsInstanceName
                showTimer = userWantsTimer
                showRoles = userWantsRoles
            end
        end
        
        -- Build main text components
        local instanceText = showInstanceName and displayText or nil
        local timerDisplayText = showTimer and string.format("|cffffff00%s|r", timerText) or nil
        
        -- IMPROVED DYNAMIC TRUNCATION - Account for ALL visible elements
        if showInstanceName and bar.text then
            -- Calculate available space for instance name
            local roleTextWidth = 0
            local timerTextWidth = 0
            local separatorWidth = 0
            
            -- Measure timer width if visible
            if showTimer and timerDisplayText then
                bar.text:SetText(timerDisplayText)
                timerTextWidth = bar.text:GetStringWidth()
                separatorWidth = 15  -- Approximate width of " - " separator
            end
            
            -- Account for role text width if it will be visible
            if showRoles and bar.roleText and bar.roleText:IsVisible() then
                roleTextWidth = bar.roleText:GetStringWidth() + 20
            end
            
            -- Calculate available width for instance name
            local padding = 30  -- Left and right padding
            
            -- COMPACT MODE: Use tighter padding for more space
            local isCompactMode = self.settings and self.settings.compactMode or false
            if isCompactMode then
                padding = 20  -- Reduced padding in compact mode
                separatorWidth = 10  -- Tighter separator in compact mode
            end
            
            local availableWidth = barWidth - padding - roleTextWidth - timerTextWidth - separatorWidth
            
            -- Ensure minimum space exists before truncating
            if availableWidth > 50 then
                -- Measure current instance name width
                bar.text:SetText(displayText)
                local instanceWidth = bar.text:GetStringWidth()
                
                -- Truncate if needed
                if instanceWidth > availableWidth then
                    instanceText = self:TruncateText(displayText, availableWidth, bar.text)
                    if self.debugMode then
                        self:Debug(string.format("Truncated instance name from %dpx to fit %dpx (bar:%dpx, timer:%dpx, role:%dpx) [%s mode]",
                            instanceWidth, availableWidth, barWidth, timerTextWidth, roleTextWidth, isCompactMode and "COMPACT" or "NORMAL"))
                    end
                end
            else
                -- Not enough room - use very short truncation
                if barWidth < 250 then
                    -- Super narrow - just show first few chars
                    instanceText = self:TruncateText(displayText, math.max(40, availableWidth), bar.text)
                else
                    instanceText = self:TruncateText(displayText, availableWidth, bar.text)
                end
            end
        end
        
        -- Determine queue type tag
        local queueTypeTag = nil
        local queueType = queueData.type or queueData.queueType or queueData.categoryName

        if queueType == "Raid Finder" or queueData.category == 3 then
            queueTypeTag = "LFR"
        elseif queueType == "Dungeon Finder" or queueData.category == 1 then
            queueTypeTag = "LFD"
        elseif queueType == "Battleground" or queueType == "PvP" then
            queueTypeTag = "BG"
        elseif queueType == "Arena" then
            queueTypeTag = "ARENA"
        elseif queueType == "Scenarios" then
            queueTypeTag = "SCENARIO"
        else
            queueTypeTag = "QUEUE"
        end

        -- Format the queue type tag with color
        local formattedTag = string.format("|cff00ff00[%s]|r", queueTypeTag)

        -- ORIGINAL WORKING DESIGN: Show instance name AND timer together on LEFT
        if instanceText and timerDisplayText then
            -- Both instance name and timer shown together
            mainText = instanceText .. " - " .. timerDisplayText
        elseif instanceText then
            -- Only instance name shown
            mainText = instanceText
        elseif timerDisplayText then
            -- Only timer shown - prepend queue type tag
            mainText = formattedTag .. " " .. timerDisplayText
        else
            -- Nothing shown - just show the tag
            mainText = formattedTag
        end
    end

    if self.debugMode then
        self:Debug("Timer Debug - Setting main text: " .. mainText)
    end

    -- Update text - instance name + timer on LEFT side
    if bar.text then
        bar.text:SetText(mainText)
    end

    if bar.textShadow then
        bar.textShadow:SetText(mainText)
    end

    -- Update role composition - check settings AND bar width to determine if we should show it
    if bar.roleText then
        -- HIDE roles during invite countdown for cleaner display
        if queueData.isProposal and queueData.proposalStartTime and queueData.proposalTimeout then
            local proposalElapsed = currentTime - queueData.proposalStartTime
            local remainingTime = math.max(0, queueData.proposalTimeout - proposalElapsed)

            if remainingTime > 0 then
                -- Hide roles during active invite
                bar.roleText:SetText("")
                bar.roleText:Hide()
                if bar.roleTextShadow then
                    bar.roleTextShadow:SetText("")
                    bar.roleTextShadow:Hide()
                end
            else
                -- Invite expired, show roles normally (fall through to normal logic)
            end
        end

        -- Normal role display (only if not in active invite)
        if not (queueData.isProposal and queueData.proposalStartTime and queueData.proposalTimeout and
                (queueData.proposalTimeout - (currentTime - queueData.proposalStartTime)) > 0) then
            -- Get REAL role data from Blizzard API
            local roleData = self:GetAccurateRoleData(queueID, queueData)

            -- Store role data in queueData for tooltip access
            queueData.displayTanks = roleData.tanks
            queueData.displayHealers = roleData.healers
            queueData.displayDPS = roleData.dps
            queueData.displayTankNeeds = roleData.tankNeeds
            queueData.displayHealerNeeds = roleData.healerNeeds
            queueData.displayDpsNeeds = roleData.dpsNeeds

            -- SMART ADAPTIVE LAYOUT: Check bar width and user preferences
            local barWidth = bar:GetWidth()
            local showRoleBars = true

            -- Check user preference first
            if self.settings and self.settings.showRoleBars ~= nil then
                showRoleBars = self.settings.showRoleBars
            end

            -- Check if compact mode is enabled
            local isCompactMode = self.settings and self.settings.compactMode or false

            if isCompactMode then
                -- COMPACT MODE: Show roles on all bars regardless of width
                -- Aggressive truncation will handle fitting
            else
                -- NORMAL MODE: Override based on bar width (priority system)
                -- Bars >= 300px can show roles with dynamic truncation
                if barWidth < 300 then
                    showRoleBars = false
                end
            end

            if showRoleBars then
                -- Show role composition on the bar (RIGHT side)
                local roleText = string.format("T:%d/%d H:%d/%d D:%d/%d",
                    roleData.tanks - roleData.tankNeeds, roleData.tanks,
                    roleData.healers - roleData.healerNeeds, roleData.healers,
                    roleData.dps - roleData.dpsNeeds, roleData.dps)
                bar.roleText:SetText(roleText)
                bar.roleText:Show()

                if bar.roleTextShadow then
                    bar.roleTextShadow:SetText(roleText)
                    bar.roleTextShadow:Show()
                end
            else
                -- Hide role text from bar - will show in tooltip instead
                bar.roleText:SetText("")
                bar.roleText:Hide()

                if bar.roleTextShadow then
                    bar.roleTextShadow:SetText("")
                    bar.roleTextShadow:Hide()
                end
            end
        end
    end

    -- Hide wait time text from bar - will show in tooltip instead
    if bar.waitText then
        bar.waitText:SetText("")
        bar.waitText:Hide()
        if bar.waitTextShadow then
            bar.waitTextShadow:SetText("")
            bar.waitTextShadow:Hide()
        end
    end
    
    -- Update progress bar based on reasonable expectations (no inaccurate API estimates)
    local referenceWait = queueData.rollingAverage or 30 -- Use rolling average or default 30 min
    
    -- Set different defaults based on queue type
    if not queueData.rollingAverage then
        local queueType = queueData.queueType or queueData.type or queueData.categoryName
        if queueType == "Raid Finder" or queueData.category == 3 then
            referenceWait = 20 -- LFR typically 10-30 minutes
        elseif queueType == "Dungeon Finder" or queueData.category == 1 then
            referenceWait = 10 -- Dungeons typically 5-15 minutes
        else
            referenceWait = 30 -- Default
        end
    end
    
    -- Ensure referenceWait is valid and positive to avoid division by zero
    if not referenceWait or referenceWait <= 0 then
        referenceWait = 20 -- Reasonable default
    end
    
    local progress = math.min(elapsed / (referenceWait * 60), 1.0)
    
    if self.debugMode then
        self:Debug("Progress Debug - Elapsed: " .. elapsed .. ", ReferenceWait: " .. referenceWait .. ", Progress: " .. progress)
    end
    
    -- Ensure progress is a valid finite number
    if not progress or progress ~= progress or progress == math.huge or progress == -math.huge then
        progress = 0 -- Default to 0 if invalid
        if self.debugMode then
            self:Debug("Progress Debug - Invalid progress, reset to 0")
        end
    end
    
    bar:SetValue(progress)
    if self.debugMode then
        self:Debug("Progress Debug - Set bar value to: " .. progress)
    end
    
    -- Apply colors using centralized color system
    local typeColor = self:GetQueueTypeColor(queueData.type or queueData.queueType or queueData.categoryName)
    
    -- Special coloring for active proposals (invites)
    if queueData.isProposal and queueData.proposalStartTime and queueData.proposalTimeout then
        local proposalElapsed = GetTime() - queueData.proposalStartTime
        local remainingTime = math.max(0, queueData.proposalTimeout - proposalElapsed)
        
        if remainingTime > 0 then
            -- Flash between orange and red for urgency
            local flashCycle = math.sin(GetTime() * 4) * 0.5 + 0.5 -- Oscillates between 0 and 1
            local r = 1.0
            local g = 0.5 + (flashCycle * 0.3) -- Varies between 0.5 and 0.8
            local b = 0.1
            
            bar:SetStatusBarColor(r, g, b, 0.9)
            
            if bar.border then
                bar.border:SetBackdropBorderColor(r, g, b, 1.0)
            end
        else
            -- Invite expired, use normal coloring
            if self.ApplyBarColors then
                self:ApplyBarColors(bar, queueID)
            else
                local color = self:GetProgressColor(progress)
                if color and color.r and color.g and color.b then
                    bar:SetStatusBarColor(color.r, color.g, color.b, 0.8)
                end
            end
        end
    else
        -- Normal queue coloring
        if self.ApplyBarColors then
            self:ApplyBarColors(bar, queueID)
        else
            local color = self:GetProgressColor(progress)
            if color and color.r and color.g and color.b then
                bar:SetStatusBarColor(color.r, color.g, color.b, 0.8)
                
                if bar.bg then
                    bar.bg:SetVertexColor(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.5)
                end
                
                if bar.border then
                    bar.border:SetBackdropBorderColor(color.r * 0.7, color.g * 0.7, color.b * 0.7, 0.8)
                end
            end
        end
    end
end