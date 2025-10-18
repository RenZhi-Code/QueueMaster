-- ======= Core/UI/BarPositioning.lua =======
-- Optimized bar positioning, movement, anchoring, and layout management
-- Consolidated all layout functions for performance and maintainability
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Performance: Cache frequently accessed values
local UIParent = UIParent
local pairs = pairs
local GetTime = GetTime

-- Make a bar movable with drag functionality
function QueueMaster:MakeBarMovable(bar)
    if not bar then 
        self:Debug("MakeBarMovable called with nil bar")
        return 
    end
    
    self:Debug("Making bar movable: " .. (bar.queueID or "unknown"))

    -- Enable mouse interactions
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    
    -- Determine positioning strategy
    -- Priority: saved position > anchor positioning > auto-positioning
    local savedPos -- CRITICAL: Declare as local to avoid global variable contamination
    local useAutoPosition = true -- CRITICAL: Initialize default value
    
    if self.db and self.db.char and self.db.char.positions and bar.queueID then
        savedPos = self.db.char.positions[bar.queueID]
        -- Only use saved position if it exists for THIS specific queue AND is on-screen
        if savedPos and savedPos.x and savedPos.y then
            -- Validate position is on-screen (within screen bounds)
            local screenWidth = UIParent:GetWidth()
            local screenHeight = UIParent:GetHeight()

            -- Check if position would place bar completely off-screen
            local isOffScreen = savedPos.x < -screenWidth or savedPos.x > screenWidth or
                                savedPos.y < -screenHeight or savedPos.y > screenHeight

            if not isOffScreen then
                useAutoPosition = false
                bar:ClearAllPoints()
                bar:SetPoint(savedPos.anchor or "CENTER", UIParent, savedPos.relativeAnchor or "CENTER", savedPos.x, savedPos.y)
                if self.debugMode then
                    self:Debug("Loaded saved position for " .. bar.queueID .. ": x=" .. savedPos.x .. ", y=" .. savedPos.y)
                end
            else
                -- Clear invalid saved position
                self.db.char.positions[bar.queueID] = nil
                print("|cffff8000[QM]|r Cleared invalid saved position for " .. bar.queueID .. " (was off-screen)")
            end
        end
    end
    
    -- If no saved position, use anchor-relative positioning if anchor exists
    if useAutoPosition and self.settings and self.settings.useAnchor and self.queueAnchor then
        -- CRITICAL: Force anchor to show if settings allow it (before positioning bars relative to it)
        if self.settings.useAnchor and not self.settings.lockFrame then
            self.queueAnchor:Show()
            self:Debug("Force showing anchor before bar positioning")
        end
        
        -- Position relative to anchor using SetPoint (simpler and more reliable)
        -- Get current bar settings
        local barHeight = (self.settings and self.settings.barHeight) or 36
        local barSpacing = (self.settings and self.settings.barSpacing) or 8
        local totalHeight = barHeight + barSpacing
        
        -- Count how many visible bars we have (excluding this one)
        local barCount = 0
        if self.queueBars then
            for queueID, existingBar in pairs(self.queueBars) do
                if existingBar and existingBar:IsVisible() and existingBar ~= bar then
                    barCount = barCount + 1
                end
            end
        end
        
        -- Position below anchor using simple anchor point
        local yOffset = -10 - (barCount * totalHeight)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.queueAnchor, "BOTTOMLEFT", 0, yOffset)
        self:Debug("Positioned bar relative to anchor: bar #" .. (barCount + 1) .. " at yOffset " .. yOffset)
        useAutoPosition = false
    end
    
    -- Use smart auto-positioning for new bars without saved positions and no anchor
    if useAutoPosition then
        self:PositionNewBar(bar)
        self:Debug("Using auto-position for new bar: " .. (bar.queueID or "unknown"))
    end
    
    -- Drag start handler
    bar:SetScript("OnDragStart", function(self)
        -- Allow dragging unless explicitly locked
        local isLocked = QueueMaster.settings and QueueMaster.settings.lockFrame
        if not isLocked then
            -- Check if group movement is enabled
            if QueueMaster.settings and QueueMaster.settings.groupMovement then
                -- Use group movement anchor instead of individual bar movement
                if QueueMaster.groupAnchor and QueueMaster.groupAnchor.GetScript and QueueMaster.groupAnchor:GetScript("OnDragStart") then
                    QueueMaster.groupAnchor:GetScript("OnDragStart")(QueueMaster.groupAnchor)
                end
            else
                -- Individual bar movement
                self:StartMoving()
                QueueMaster:Debug("Started dragging bar: " .. (self.queueID or "unknown"))
            end
        end
    end)
    
    -- Drag stop handler - save position
    bar:SetScript("OnDragStop", function(self)
        -- Check if group movement was used
        if QueueMaster.settings and QueueMaster.settings.groupMovement then
            -- Use group movement anchor instead
            if QueueMaster.groupAnchor and QueueMaster.groupAnchor.GetScript and QueueMaster.groupAnchor:GetScript("OnDragStop") then
                QueueMaster.groupAnchor:GetScript("OnDragStop")(QueueMaster.groupAnchor)
            end
        else
            -- Individual bar movement
            self:StopMovingOrSizing()
            QueueMaster:Debug("Stopped dragging bar: " .. (self.queueID or "unknown"))
            
            -- Save the new position
            local anchor, _, relativeAnchor, x, y = self:GetPoint()
            if QueueMaster.db and QueueMaster.db.char then
                if not QueueMaster.db.char.positions then
                    QueueMaster.db.char.positions = {}
                end
                QueueMaster.db.char.positions[self.queueID] = {
                    anchor = anchor,
                    relativeAnchor = relativeAnchor,
                    x = x,
                    y = y
                }
            end
            
            QueueMaster:Debug("Saved position for queue " .. self.queueID .. ": " .. (anchor or "nil") .. ", " .. (x or 0) .. ", " .. (y or 0))
        end
    end)
    
    -- NOTE: Tooltip and hover effects are handled by the button overlay in CreateQueueBar
    -- to ensure proper mouse event handling
end

-- Reset all bar positions to default
function QueueMaster:ResetBarPositions()
    -- Clear saved positions
    if self.db and self.db.char then
        self.db.char.positions = {}
    end
    
    self:Debug("Cleared all saved bar positions")
    
    -- CRITICAL FIX: Recalculate proper spacing instead of stacking all bars on top of each other
    if self.queueBars then
        local barHeight = (self.settings and self.settings.barHeight) or 36
        local barSpacing = (self.settings and self.settings.barSpacing) or 8
        local totalHeight = barHeight + barSpacing
        local barIndex = 0
        
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                bar:ClearAllPoints()
                -- Stack bars vertically with proper spacing
                local yOffset = -100 - (barIndex * totalHeight)
                bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, yOffset)
                barIndex = barIndex + 1
                
                self:Debug("Reset bar " .. queueID .. " to position: 100, " .. yOffset)
            end
        end
    end
    
    -- Force layout update to ensure proper positioning
    if self.UpdateQueueBarLayout then
        self:UpdateQueueBarLayout()
    end
    
    print("|cff00ff00[QM]|r Bar positions reset - bars properly spaced")
    self:Debug("All bar positions reset with proper spacing")
end

-- Smart positioning for new bars to prevent overlap
function QueueMaster:PositionNewBar(bar)
    if not bar then return end
    
    -- Get current bar settings
    local barHeight = (self.settings and self.settings.barHeight) or 36
    local barSpacing = (self.settings and self.settings.barSpacing) or 8
    local totalHeight = barHeight + barSpacing
    
    -- Count how many visible bars we have (excluding this one)
    local barCount = 0
    if self.queueBars then
        for queueID, existingBar in pairs(self.queueBars) do
            if existingBar and existingBar:IsVisible() and existingBar ~= bar then
                barCount = barCount + 1
            end
        end
    end
    
    -- Stack bars vertically starting from top-left area to avoid center screen obstruction
    -- First bar at -100, second at -100 - (height+spacing), etc.
    -- X=100 to match anchor position (anchor is at TOPLEFT 100, -100)
    local yOffset = -100 - (barCount * totalHeight)
    
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, yOffset)
    
    self:Debug(string.format("Positioned new bar #%d at Y offset: %d", barCount + 1, yOffset))
end

-- Group movement feature - move all bars as a block
function QueueMaster:SetupGroupMovement()
    if not self.queueBars then return end
    
    -- Create invisible anchor frame for group movement
    if not self.groupAnchor then
        self.groupAnchor = CreateFrame("Frame", "QueueMasterGroupAnchor", UIParent)
        self.groupAnchor:SetSize(1, 1)
        self.groupAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
        self.groupAnchor:SetMovable(true)
        self.groupAnchor:EnableMouse(true)
        self.groupAnchor:RegisterForDrag("LeftButton")
        
        -- Store original relative positions when drag starts
        self.groupAnchor:SetScript("OnDragStart", function(frame)
            if self.settings and self.settings.lockFrame then return end
            
            -- Store each bar's relative position to the anchor
            self.barRelativePositions = {}
            local anchorX, anchorY = self.groupAnchor:GetCenter()
            
            for queueID, bar in pairs(self.queueBars) do
                if bar and bar:IsVisible() then
                    local barX, barY = bar:GetCenter()
                    self.barRelativePositions[queueID] = {
                        x = barX - anchorX,
                        y = barY - anchorY
                    }
                end
            end
            
            frame:StartMoving()
            self:Debug("Started group movement")
        end)
        
        -- Update all bar positions relative to anchor
        self.groupAnchor:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            
            if self.barRelativePositions then
                local anchorX, anchorY = frame:GetCenter()
                
                -- Move all bars to maintain relative positions
                for queueID, relPos in pairs(self.barRelativePositions) do
                    local bar = self.queueBars[queueID]
                    if bar and bar:IsVisible() then
                        bar:ClearAllPoints()
                        bar:SetPoint("CENTER", UIParent, "CENTER", 
                                   anchorX + relPos.x - (UIParent:GetWidth()/2), 
                                   anchorY + relPos.y - (UIParent:GetHeight()/2))
                        
                        -- Save individual bar position
                        local anchor, _, relativeAnchor, x, y = bar:GetPoint()
                        if self.db and self.db.char then
                            if not self.db.char.positions then
                                self.db.char.positions = {}
                            end
                            self.db.char.positions[queueID] = {
                                anchor = anchor,
                                relativeAnchor = relativeAnchor,
                                x = x,
                                y = y
                            }
                        end
                    end
                end
            end
            
            self:Debug("Completed group movement")
        end)
    end
end

-- Update group anchor position when bars are repositioned
function QueueMaster:UpdateGroupAnchor()
    if not self.groupAnchor or not self.queueBars then return end
    
    -- Find the center point of all visible bars
    local totalX, totalY, barCount = 0, 0, 0
    
    for queueID, bar in pairs(self.queueBars) do
        if bar and bar:IsVisible() then
            local barX, barY = bar:GetCenter()
            totalX = totalX + barX
            totalY = totalY + barY
            barCount = barCount + 1
        end
    end
    
    if barCount > 0 then
        local avgX = totalX / barCount
        local avgY = totalY / barCount
        
        self.groupAnchor:ClearAllPoints()
        self.groupAnchor:SetPoint("CENTER", UIParent, "CENTER", 
                               avgX - (UIParent:GetWidth()/2), 
                               avgY - (UIParent:GetHeight()/2))
    end
end

-- OPTIMIZED: Consolidated layout management function
function QueueMaster:UpdateQueueBarLayout()
    -- Performance: Cache settings access
    local settings = self.settings
    local displayMode = (settings and settings.displayMode) or "vertical"
    
    -- CRITICAL: ALWAYS ensure anchor exists before anything else
    if not self.queueAnchor then
        self:CreateQueueAnchor()
        self:Debug("Anchor created in UpdateQueueBarLayout")
    end
    
    -- Performance: Use direct table access instead of pairs iteration
    local barCount = 0
    local queueBars = self.queueBars
    if queueBars then
        for _ in pairs(queueBars) do
            barCount = barCount + 1
        end
    end
    
    self:Debug("UpdateQueueBarLayout - barCount: " .. barCount .. ", displayMode: " .. displayMode)
    
    -- CRITICAL FIX: Always handle anchor visibility based on settings
    -- Don't hide anchor just because there are no bars yet!
    -- Anchor should be visible if settings allow it (useAnchor=true AND lockFrame=false)
    if self.queueAnchor and settings then
        if settings.useAnchor and not settings.lockFrame then
            self.queueAnchor:Show()
            self:Debug("Anchor shown - useAnchor=" .. tostring(settings.useAnchor) .. ", lockFrame=" .. tostring(settings.lockFrame) .. " (barCount=" .. barCount .. ")")
        else
            self.queueAnchor:Hide()
            if settings.lockFrame then
                self:Debug("Anchor hidden - bars locked")
            else
                self:Debug("Anchor hidden - useAnchor disabled")
            end
        end
    end
    
    -- Early return if no bars (but anchor visibility already handled above)
    if barCount == 0 then
        self:Debug("No bars to layout - anchor visibility already set")
        return
    end
    
    -- Performance: Direct function calls instead of string comparisons
    if displayMode == "horizontal" then
        self:LayoutHorizontal()
    elseif displayMode == "textonly" then
        self:LayoutTextOnly()
    else
        -- Default to vertical (includes "vertical" and legacy modes)
        self:LayoutVertical()
    end
end

-- OPTIMIZED: Vertical layout with performance improvements
function QueueMaster:LayoutVertical()
    -- Performance: Cache all settings in one access
    local settings = self.settings
    local barHeight = (settings and settings.barHeight) or 32
    local barWidth = (settings and settings.barWidth) or 300
    local spacing = (settings and settings.barSpacing) or 8
    local useAnchor = settings and settings.useAnchor and self.queueAnchor
    
    -- Performance: Cache database access
    local db = self.db
    local savedPositions = db and db.char and db.char.positions
    
    local yOffset = 0
    local queueBars = self.queueBars
    
    -- Performance: Single loop with optimized positioning logic
    for queueID, bar in pairs(queueBars) do
        if bar then
            -- Check for saved position (optimized)
            local savedPos = savedPositions and savedPositions[queueID]
            if savedPos and savedPos.x and savedPos.y then
                -- Restore saved position efficiently
                bar:ClearAllPoints()
                bar:SetPoint(savedPos.anchor or "CENTER", UIParent, savedPos.relativeAnchor or "CENTER", savedPos.x, savedPos.y)
            elseif useAnchor then
                -- Position relative to anchor - optimized anchoring
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", self.queueAnchor, "BOTTOMLEFT", 0, -10 + yOffset)
                yOffset = yOffset - (barHeight + spacing)
            else
                -- Default positioning - X=100 to match anchor position
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100 + yOffset)
                yOffset = yOffset - (barHeight + spacing)
            end
            
            -- Performance: Single size and visibility call
            bar:SetSize(barWidth, barHeight)
            bar:Show()
        end
    end
end

-- OPTIMIZED: Horizontal layout with performance improvements
function QueueMaster:LayoutHorizontal()
    -- Performance: Cache all settings in one access
    local settings = self.settings
    local barWidth = (settings and settings.barWidth) or 200
    local barHeight = (settings and settings.barHeight) or 32
    local spacing = (settings and settings.barSpacing) or 8
    local useAnchor = settings and settings.useAnchor and self.queueAnchor
    
    -- Performance: Cache database access
    local db = self.db
    local savedPositions = db and db.char and db.char.positions
    
    local xOffset = 0
    local queueBars = self.queueBars
    
    -- Performance: Single loop with optimized positioning logic
    for queueID, bar in pairs(queueBars) do
        if bar then
            -- Check for saved position (optimized)
            local savedPos = savedPositions and savedPositions[queueID]
            if savedPos and savedPos.x and savedPos.y then
                -- Restore saved position efficiently
                bar:ClearAllPoints()
                bar:SetPoint(savedPos.anchor or "CENTER", UIParent, savedPos.relativeAnchor or "CENTER", savedPos.x, savedPos.y)
            elseif useAnchor then
                -- Position relative to anchor - optimized anchoring
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", self.queueAnchor, "TOPRIGHT", 10 + xOffset, 0)
                xOffset = xOffset + (barWidth + spacing)
            else
                -- Default positioning - X=100 to match anchor position
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100 + xOffset, -100)
                xOffset = xOffset + (barWidth + spacing)
            end
            
            -- Performance: Single size and visibility call
            bar:SetSize(barWidth, barHeight)
            bar:Show()
        end
    end
end

-- OPTIMIZED: Text-only layout with performance improvements
function QueueMaster:LayoutTextOnly()
    -- Performance: Cache settings and constants
    local settings = self.settings
    local barWidth = (settings and settings.barWidth) or 300
    local spacing = (settings and settings.barSpacing) or 8
    local textHeight = 18 -- Fixed height for text-only mode
    
    -- Performance: Cache database access
    local db = self.db
    local savedPositions = db and db.char and db.char.positions
    
    local index = 0
    local queueBars = self.queueBars
    
    for queueID, bar in pairs(queueBars) do
        if bar then
            -- PERFORMANCE: Batch hide all visual elements efficiently
            bar:SetStatusBarTexture("")
            bar:SetStatusBarColor(0, 0, 0, 0)
            
            -- Hide elements if they exist (safe checks)
            local bg = bar.bg
            if bg then 
                bg:Hide()
                bg:SetAlpha(0)
            end
            
            local border = bar.border
            if border then 
                border:Hide()
                border:SetAlpha(0)
            end
            
            local shadow = bar.shadow
            if shadow then 
                shadow:Hide()
                shadow:SetAlpha(0)
            end
            
            local highlight = bar.highlight
            if highlight then 
                highlight:Hide()
                highlight:SetAlpha(0)
            end
            
            -- Remove backdrop efficiently
            if bar.SetBackdrop then
                bar:SetBackdrop(nil)
            end
            
            -- Keep text visible
            bar:SetAlpha(1.0)
            
            -- Optimized positioning logic
            local savedPos = savedPositions and savedPositions[queueID]
            if savedPos and savedPos.x and savedPos.y then
                -- Restore saved position efficiently
                bar:ClearAllPoints()
                bar:SetPoint(savedPos.anchor or "CENTER", UIParent, savedPos.relativeAnchor or "CENTER", savedPos.x, savedPos.y)
            else
                -- Default text-only positioning
                bar:ClearAllPoints()
                bar:SetPoint("CENTER", UIParent, "CENTER", 0, 100 - (textHeight + spacing) * index)
            end
            
            -- Performance: Single size and visibility call
            bar:SetSize(barWidth, textHeight)
            bar:Show()
            
            -- Apply font sizing and update
            if self.ApplyIndividualFontSizes then
                self:ApplyIndividualFontSizes(bar)
            end
            
            -- Force update in text mode
            self:UpdateQueueBar(queueID, bar)
            
            index = index + 1
        end
    end
end