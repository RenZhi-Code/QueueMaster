-- ======= Core/UI/BarCreation.lua =======
-- Queue bar creation and initialization
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Update main frame size based on number of queue bars
function QueueMaster:UpdateMainFrameSize()
    if not self.mainFrame or not self.contentFrame then return end
    
    local queueCount = 0
    for _ in pairs(self.queueBars or {}) do
        queueCount = queueCount + 1
    end
    
    if queueCount == 0 then
        -- Hide main frame when no queues
        self:HideMainFrame()
        return
    end
    
    -- Calculate required height
    local barHeight = (self.settings and self.settings.barHeight) or 36
    local spacing = 5
    local headerHeight = 35
    local padding = 20
    
    local contentHeight = queueCount * (barHeight + spacing) + spacing
    local totalHeight = headerHeight + contentHeight + padding
    
    -- Set main frame and content frame sizes
    self.mainFrame:SetSize(420, totalHeight)
    self.contentFrame:SetSize(400, contentHeight)
    
    self:Debug("Updated main frame size for " .. queueCount .. " queues")
end

function QueueMaster:CreateQueueBar(queueID)
    self:Debug("CreateQueueBar called for " .. tostring(queueID))
    if not queueID or not self.queues[queueID] then
        self:Debug("Invalid queueID or missing queue data")
        return
    end
    
    local queueData = self.queues[queueID]
    
    -- Enhanced duplicate prevention: check by queue ID and instance name
    if self.queueBars[queueID] then 
        self:Debug("Queue bar already exists for " .. tostring(queueID))
        return 
    end
    
    -- Additional check: prevent ACTUAL duplicates, allow DIFFERENT wings/difficulties
    for existingQueueID, existingBar in pairs(self.queueBars or {}) do
        local existingQueue = self.queues[existingQueueID]
        if existingQueue then
            -- CRITICAL: Only treat as duplicate if EXACT SAME activeID and category
            -- Different activeIDs = Different wings/difficulties = SEPARATE BARS!
            local bothHaveActiveID = existingQueue.activeID and queueData.activeID
            local exactSameActiveID = existingQueue.activeID == queueData.activeID
            local sameCategory = existingQueue.category == queueData.category
            
            if bothHaveActiveID and exactSameActiveID and sameCategory then
                -- TRUE DUPLICATE: Exact same wing/difficulty
                -- Update the existing queue ID to the new format if needed
                if existingQueueID ~= queueID then
                    self:Debug("TRUE DUPLICATE FOUND - Same activeID (" .. tostring(queueData.activeID) .. ") and category (" .. tostring(queueData.category) .. ") - Updating existing bar")
                    self.queueBars[queueID] = existingBar
                    self.queueBars[existingQueueID] = nil
                    self.queues[queueID] = existingQueue
                    self.queues[existingQueueID] = nil
                    existingBar.queueID = queueID
                else
                    self:Debug("Bar already exists for this exact queue: " .. queueID)
                end
                return
            end
            
            -- Legacy check: If one or both don't have activeID, check by instance name
            -- This handles old format queues that might not have activeID set
            if not bothHaveActiveID then
                local cleanExistingName = string.gsub(existingQueue.instanceName or "", "^%[?LFG%]? ?", "")
                local cleanNewName = string.gsub(queueData.instanceName or "", "^%[?LFG%]? ?", "")
                if cleanExistingName == cleanNewName and sameCategory then
                    -- Same instance name without activeID - might be duplicate
                    self:Debug("POSSIBLE DUPLICATE - Same instance name without activeID - Updating existing bar")
                    if existingQueueID ~= queueID then
                        self.queueBars[queueID] = existingBar
                        self.queueBars[existingQueueID] = nil
                        -- Update queue data with the new information
                        existingQueue.instanceName = queueData.instanceName
                        existingQueue.activeID = queueData.activeID
                        self.queues[queueID] = existingQueue
                        self.queues[existingQueueID] = nil
                        existingBar.queueID = queueID
                    end
                    return
                end
            end
            
            -- DIFFERENT activeIDs = DIFFERENT queues (e.g., different LFR wings)
            -- Let it continue to create a new bar
            if bothHaveActiveID and not exactSameActiveID and sameCategory then
                self:Debug("DIFFERENT QUEUE - Different activeID (existing: " .. tostring(existingQueue.activeID) .. " vs new: " .. tostring(queueData.activeID) .. ") - Creating separate bar")
            end
        end
    end
    
    -- Create independent queue bar (better UX - users can position each bar individually)
    self:Debug("Creating independent queue bar")
    local barName = "QueueMasterBar_" .. string.gsub(queueID, "[^%w]", "_")
    local bar = CreateFrame("StatusBar", barName, UIParent)
    
    -- Bar dimensions and positioning
    local barWidth = (self.settings and self.settings.barWidth) or 400
    local barHeight = (self.settings and self.settings.barHeight) or 36
    local barScale = (self.settings and self.settings.scale) or 1.0
    bar:SetSize(barWidth, barHeight)
    bar:SetScale(barScale)
    
    -- DON'T position here - let MakeBarMovable handle positioning to avoid conflicts!
    -- MakeBarMovable will either:
    -- 1. Load saved position if it exists
    -- 2. Call PositionNewBar for smart automatic positioning
    
    -- Status bar with smooth texture
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0.3)
    bar:SetFrameStrata("HIGH")
    bar:SetFrameLevel(100)
    bar:SetAlpha((self.settings and self.settings.frameAlpha) or 0.95)
    
    local edgeOpacity = (self.settings and self.settings.edgeOpacity) or 1.0
    
    -- Gradient background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(bar)
    bar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 1.0) -- Dark background
    bar.bg:SetAlpha(edgeOpacity)
    
    -- Shadow/depth effect
    bar.shadow = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.shadow:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
    bar.shadow:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
    bar.shadow:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    bar.shadow:SetBackdropColor(0, 0, 0, 0.8) -- Dark shadow
    bar.shadow:SetFrameLevel(bar:GetFrameLevel() - 1)
    bar.shadow:SetAlpha(edgeOpacity * 0.8)
    
    -- Apply colors using centralized color system
    local color
    if self.ApplyBarColors then
        self:ApplyBarColors(bar, queueID)
        -- Get color for border (fallback to default if ApplyBarColors doesn't set it)
        color = self:GetQueueTypeColor(queueData.queueType or queueData.type or queueData.categoryName)
    else
        -- Fallback color setup
        color = self:GetQueueTypeColor(queueData.queueType or queueData.type or queueData.categoryName)
        bar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
        bar.bg:SetVertexColor(color.r * 0.3, color.g * 0.3, color.b * 0.3, 1.0)
    end
    
    -- Main text with shadow
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    bar.text:SetPoint("LEFT", bar, "LEFT", 15, 1)
    -- Use selected font face from settings
    local fontFace = (self.settings and self.settings.fontFace) or "Fonts\\FRIZQT__.TTF"
    local instanceNameFontSize = (self.settings and self.settings.instanceNameFontSize) or (self.settings and self.settings.fontSize) or 12
    bar.text:SetFont(fontFace, instanceNameFontSize, "OUTLINE")
    bar.text:SetTextColor(1, 1, 1, 1)
    bar.text:SetShadowOffset(1, -1)
    bar.text:SetShadowColor(0, 0, 0, 1)
    
    -- Role text with gradient colors
    bar.roleText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.roleText:SetPoint("RIGHT", bar, "RIGHT", -15, 1)
    local roleFontSize = (self.settings and self.settings.roleFontSize) or ((self.settings and self.settings.fontSize) or 12) - 1
    bar.roleText:SetFont(fontFace, roleFontSize, "OUTLINE")
    bar.roleText:SetTextColor(0.9, 0.8, 0.1, 1) -- Gold color
    bar.roleText:SetShadowOffset(1, -1)
    bar.roleText:SetShadowColor(0, 0, 0, 0.8)

    -- Wait time text (for additional context) - positioned subtly
    bar.waitText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.waitText:SetPoint("LEFT", bar, "LEFT", 15, -15) -- 15 pixels below main text, smaller offset
    local waitTextFontSize = (self.settings and self.settings.fontSize) or 12
    bar.waitText:SetFont(fontFace, waitTextFontSize - 2, "OUTLINE") -- Smaller font
    bar.waitText:SetTextColor(0.7, 0.7, 0.8, 1) -- Subtle gray-blue for context info
    bar.waitText:SetShadowOffset(1, -1)
    bar.waitText:SetShadowColor(0, 0, 0, 0.8)
    
    
    -- Apply font settings using centralized text system
    if self.ApplyTextSettings then
        -- Apply to single bar by creating temporary table
        local tempBars = {[queueID] = bar}
        local originalBars = self.queueBars
        self.queueBars = tempBars
        self:ApplyTextSettings()
        self.queueBars = originalBars
    else
        -- Fallback font setup - use selected font face
        local fontFace = (self.settings and self.settings.fontFace) or "Fonts\\FRIZQT__.TTF"
        local fontSize = (self.settings and self.settings.fontSize) or 11
        bar.text:SetFont(fontFace, fontSize, "OUTLINE")
        bar.roleText:SetFont(fontFace, fontSize - 2, "OUTLINE")
    end
    
    -- Border with modern design
    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.border:SetAllPoints(bar)
    bar.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2
    })
    -- QueueMaster signature border colors
    bar.border:SetBackdropBorderColor(1.0, 0.2, 0.2, 1.0) -- Signature red
    bar.border:SetAlpha(edgeOpacity)
    
    -- Inner highlight effect
    bar.highlight = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.highlight:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    bar.highlight:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 1)
    bar.highlight:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    bar.highlight:SetBackdropBorderColor(0.0, 0.5, 1.0, 0.4) -- Blue inner highlight
    bar.highlight:SetAlpha(edgeOpacity * 0.4)
    
    -- Store queue reference for independent tracking
    bar.queueID = queueID
    bar.independent = true
    
    -- OPTIMIZATION: Cache parsed queueID data to avoid repeated string operations
    local category, activeID = string.match(queueID, "QUEUE_(%d+)_(%d+)")
    bar.cachedCategory = tonumber(category)
    bar.cachedActiveID = tonumber(activeID)
    
    self:Debug(string.format("Cached queueID data - category:%s, activeID:%s", 
        tostring(bar.cachedCategory), tostring(bar.cachedActiveID)))
    
    -- Make bars individually movable (better UX)
    self:MakeBarMovable(bar)
    
    -- Interaction handlers - create invisible button for mouse handling
    bar:EnableMouse(true)
    bar.button = CreateFrame("Button", nil, bar)
    bar.button:SetAllPoints(bar)
    bar.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- CRITICAL: Make button allow drag events to pass through to parent bar
    bar.button:RegisterForDrag("LeftButton")
    bar.button:SetScript("OnDragStart", function(self) 
        -- Pass drag event to parent bar
        bar:GetScript("OnDragStart")(bar)
    end)
    bar.button:SetScript("OnDragStop", function(self)
        -- Pass drag event to parent bar  
        bar:GetScript("OnDragStop")(bar)
    end)
    
    -- FIX: Set tooltip on the button instead of the bar since button captures mouse events
    bar.button:SetScript("OnEnter", function(self)
        QueueMaster:ShowQueueTooltip(bar, bar.queueID)
        -- Subtle highlight effect on hover
        if bar.highlight then
            bar.highlight:SetBackdropBorderColor(0.2, 0.8, 1.0, 0.6)
        end
    end)
    
    bar.button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        -- Restore normal highlight
        if bar.highlight then
            bar.highlight:SetBackdropBorderColor(0.0, 0.5, 1.0, 0.4)
        end
    end)
    
    -- Click handlers: Right-click for settings, Shift+Left-click to leave queue
    bar.button:SetScript("OnClick", function(self, button)
        if button == "LeftButton" and IsShiftKeyDown() then
            -- Shift+Left-click: Leave queue with confirmation
            local queueData = QueueMaster.queues[bar.queueID]
            if queueData then
                local instanceName = queueData.instanceName or "queue"
                StaticPopupDialogs["QUEUEMASTER_LEAVE_QUEUE"] = {
                    text = "Leave queue for |cffffd100" .. instanceName .. "|r?",
                    button1 = "Yes",
                    button2 = "No",
                    OnAccept = function()
                        -- Leave the appropriate queue type
                        if queueData.pvpIndex then
                            -- PvP queue
                            LeaveBattlefield(queueData.pvpIndex)
                        elseif queueData.category then
                            -- LFG queue
                            LeaveLFG(queueData.category)
                        end
                        QueueMaster:Print("Left queue: " .. instanceName)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("QUEUEMASTER_LEAVE_QUEUE")
            end
        elseif button == "RightButton" and QueueMaster.ShowConfig then
            QueueMaster:ShowConfig()
        end
    end)
    
    -- Store bar reference for centralized updates (using centralized OnUpdate system)
    bar.queueID = queueID
    bar.lastUpdate = 0
    
    -- OPTIMIZATION: No individual OnUpdate scripts - using centralized system
    -- This reduces from 300 calls/sec (60fps × 5 bars) to 60 calls/sec total
    
    -- Store the bar
    if not self.queueBars then
        self.queueBars = {}
        self:Debug("Initialized queueBars table")
    end
    self.queueBars[queueID] = bar
    
    -- CRITICAL: Ensure anchor is created (visibility controlled by UpdateQueueBarLayout)
    if not self.queueAnchor then
        self:CreateQueueAnchor()
        self:Debug("Anchor created in CreateQueueBar")
    end
    
    -- Apply dynamic font sizing based on initial bar size
    self:UpdateBarFontSizes(bar, barWidth, barHeight)
    
    -- Show the bar with smooth fade-in animation
    -- CRITICAL FIX: Store target alpha for visibility confirmation
    local targetAlpha = (self.settings and self.settings.frameAlpha) or 0.95
    bar.targetAlpha = targetAlpha

    bar:SetAlpha(0)
    bar:Show()
    UIFrameFadeIn(bar, 0.3, 0, targetAlpha)
    self:Debug("Bar shown with fade-in animation: " .. queueID)

    -- CRITICAL FIX: Multiple fallback timers to ensure visibility
    -- Timer 1: Quick check at 0.35s (after animation should complete)
    C_Timer.After(0.35, function()
        if bar and bar.Show then
            if not bar:IsShown() or bar:GetAlpha() < targetAlpha * 0.9 then
                bar:Show()
                bar:SetAlpha(targetAlpha)
                self:Debug("Bar visibility restored (timer 1): " .. queueID)
            end
        end
    end)

    -- Timer 2: Secondary check at 1.0s for delayed issues
    C_Timer.After(1.0, function()
        if bar and bar.Show then
            if not bar:IsShown() or bar:GetAlpha() < targetAlpha * 0.9 then
                bar:Show()
                bar:SetAlpha(targetAlpha)
                self:Debug("Bar visibility restored (timer 2): " .. queueID)
            end
        end
    end)
    
    -- Update the bar with current queue data immediately
    self:UpdateQueueBar(queueID, bar)
    
    -- NOTE: UpdateQueueBarLayout() is called by the caller (QueueProcessing.lua)
    -- to ensure proper timing after bar is fully stored and queue data is set
end