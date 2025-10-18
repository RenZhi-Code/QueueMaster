-- ======= Core/UI/BarStyling.lua =======
-- Bar styling, fonts, colors, and theme management
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Apply red/blue coloring to UI elements
function QueueMaster:ApplyBrandColors()
    -- This function can be called to apply the red/blue QueueMaster branding
    -- to various UI elements throughout the addon
end

-- Apply settings to active bars WITHOUT changing their positions (fix for issue #2)
function QueueMaster:ApplySettingsToActiveBarsWithoutMove()
    if not self.queueBars then return end
    
    local barCount = 0
    for queueID, bar in pairs(self.queueBars) do
        if bar then
            barCount = barCount + 1
            
            -- Update bar size
            local barWidth = self.settings.barWidth or 400
            local barHeight = self.settings.barHeight or 36
            bar:SetSize(barWidth, barHeight)
            
            -- Update scale on individual bars (critical for proper sizing)
            if self.settings.scale then
                bar:SetScale(self.settings.scale)
            end
            
            -- Update font sizes and font face - CRITICAL: Force font refresh
            self:UpdateBarFontSizes(bar, barWidth, barHeight)
            
            -- Update alpha - CRITICAL: Force redraw by hiding/showing
            local frameAlpha = self.settings.frameAlpha or 1.0
            bar:SetAlpha(frameAlpha)
            
            -- Apply edge opacity to all visual elements
            local edgeOpacity = self.settings.edgeOpacity or 1.0
            if bar.border then
                bar.border:SetAlpha(edgeOpacity)
            end
            if bar.bg then
                bar.bg:SetAlpha(edgeOpacity * 0.6) -- Background slightly more transparent
            end
            if bar.shadow then
                bar.shadow:SetAlpha(edgeOpacity * 0.4)
            end
            if bar.highlight then
                bar.highlight:SetAlpha(edgeOpacity * 0.3)
            end
            
            -- Update colors based on current theme
            self:ApplyBarColors(bar, queueID)
            
            -- CRITICAL: Force bar to stay visible - FIRST CHECK
            bar:Show()
            if self.debugMode then
                self:Debug("Showing bar in ApplySettingsToActiveBarsWithoutMove: " .. queueID .. " (visible: " .. tostring(bar:IsShown()) .. ")")
            end
            
            -- Force complete refresh by updating the queue data
            self:UpdateQueueBar(queueID, bar)
            
            -- CRITICAL: Force bar visible AGAIN after update - SECOND CHECK
            bar:Show()
            
            -- CRITICAL: Delayed force-show - THIRD CHECK (catches timing issues)
            C_Timer.After(0.1, function()
                if bar and bar.Show then
                    bar:Show()
                    if self.debugMode and QueueMaster then
                        QueueMaster:Debug("Delayed force-show after settings update: " .. queueID .. " (visible: " .. tostring(bar:IsShown()) .. ")")
                    end
                end
            end)
        end
    end
    
    -- Debug confirmation
    if self.debugMode then
        self:Debug("Applied settings to " .. barCount .. " active bars (font sizes updated)")
    end
    
    -- CRITICAL: Also ensure any queues in self.queues get their bars shown
    if self.queues then
        for queueID, queueData in pairs(self.queues) do
            local bar = self.queueBars and self.queueBars[queueID]
            if bar and not bar:IsShown() then
                bar:Show()
                self:Debug("Force-showed previously hidden bar: " .. queueID)
            elseif not bar then
                -- Queue exists but no bar - create it!
                self:Debug("Queue exists without bar, creating: " .. queueID)
                self:CreateQueueBar(queueID)
                if self.UpdateQueueBarLayout then
                    self:UpdateQueueBarLayout()
                end
            end
        end
    end
end

-- Apply settings to active bars WITH position updates (comprehensive update)
function QueueMaster:ApplySettingsToActiveBars()
    -- First apply visual settings without moving
    self:ApplySettingsToActiveBarsWithoutMove()
    
    -- Then update layout if needed
    if self.UpdateQueueBarLayout then
        self:UpdateQueueBarLayout()
    end
end

-- Apply color theme to all active bars
function QueueMaster:ApplyColorTheme(theme)
    -- Store the theme setting
    if self.settings then
        self.settings.colorTheme = theme
    end
    
    -- Apply theme to all active bars
    if self.queueBars then
        for queueID, bar in pairs(self.queueBars) do
            if bar then
                local color = self:GetQueueTypeColor(bar.queueType or bar.type or "Unknown")
                if color then
                    -- Apply main bar color
                    bar:SetStatusBarColor(color.r or 1, color.g or 0.2, color.b or 0.1, 0.85)
                    
                    -- Apply border color if it exists
                    if bar.border then
                        local edgeOpacity = (self.settings and self.settings.edgeOpacity) or 1.0
                        bar.border:SetBackdropBorderColor(color.r or 1, color.g or 0.2, color.b or 0.1, edgeOpacity)
                    end
                    
                    -- Apply background color if it exists
                    if bar.bg then
                        bar.bg:SetVertexColor(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.5)
                    end
                end
            end
        end
    end
    
    self:Debug("Applied color theme: " .. tostring(theme))
end

-- Dynamically update font sizes based on user settings (individual font sizes for each element)
function QueueMaster:UpdateBarFontSizes(bar, barWidth, barHeight)
    if not bar then return end
    
    -- Check if compact mode is enabled
    local isCompactMode = self.settings and self.settings.compactMode or false
    
    -- Get individual font sizes from settings, with fallbacks
    local instanceNameFontSize = self.settings.instanceNameFontSize or self.settings.fontSize or 12
    local timerFontSize = self.settings.timerFontSize or self.settings.fontSize or 12
    local roleFontSize = self.settings.roleFontSize or self.settings.fontSize or 11
    
    -- Apply compact mode font size limits
    if isCompactMode then
        instanceNameFontSize = math.min(instanceNameFontSize, 10)
        timerFontSize = math.min(timerFontSize, 10)
        roleFontSize = math.min(roleFontSize, 9)
    end
    
    -- Get selected font face from settings (default to Friz Quadrata)
    local fontFace = self.settings.fontFace or "Fonts\\FRIZQT__.TTF"
    
    -- Debug output
    if self.debugMode then
        self:Debug(string.format("UpdateBarFontSizes - Instance: %d, Timer: %d, Role: %d, Font: %s [%s mode]",
            instanceNameFontSize, timerFontSize, roleFontSize, fontFace, isCompactMode and "COMPACT" or "NORMAL"))
    end
    
    -- Apply individual font sizes to each text element
    if bar.text then
        bar.text:SetFont(fontFace, instanceNameFontSize, "OUTLINE")
        -- CRITICAL: Force text refresh by getting and resetting the text
        local currentText = bar.text:GetText()
        if currentText then
            bar.text:SetText(currentText)
        end
        if self.debugMode then
            self:Debug("Set bar.text font to size " .. instanceNameFontSize)
        end
    end
    
    if bar.roleText then
        bar.roleText:SetFont(fontFace, roleFontSize, "OUTLINE")
        -- CRITICAL: Force text refresh
        local currentText = bar.roleText:GetText()
        if currentText then
            bar.roleText:SetText(currentText)
        end
        if self.debugMode then
            self:Debug("Set bar.roleText font to size " .. roleFontSize)
        end
    end
    
    -- Update timer text if it exists (though timer is part of main text now)
    if bar.timerText then
        bar.timerText:SetFont(fontFace, timerFontSize, "OUTLINE")
        local currentText = bar.timerText:GetText()
        if currentText then
            bar.timerText:SetText(currentText)
        end
    end
    
    -- Update wait time text if it exists
    if bar.waitText then
        bar.waitText:SetFont(fontFace, timerFontSize - 2, "OUTLINE")
        local currentText = bar.waitText:GetText()
        if currentText then
            bar.waitText:SetText(currentText)
        end
    end
    
    -- Mark for text truncation if needed
    if barWidth < 400 and bar.text then
        bar.needsTextTruncation = true
    else
        bar.needsTextTruncation = false
    end
end

-- Apply individual font sizes without scaling (for text-only mode)
function QueueMaster:ApplyIndividualFontSizes(bar)
    if not bar then return end
    
    -- Get exact font sizes from settings without scaling
    local instanceFontSize = self.settings.fontSize or 12
    local timerFontSize = self.settings.timerFontSize or 10
    local roleFontSize = self.settings.roleFontSize or 10
    
    -- Get selected font face from settings
    local fontFace = self.settings.fontFace or "Fonts\\FRIZQT__.TTF"
    
    -- Apply exact font sizes for text-only mode
    if bar.text then
        bar.text:SetFont(fontFace, instanceFontSize, "OUTLINE")
    end
    
    if bar.roleText then
        bar.roleText:SetFont(fontFace, roleFontSize, "OUTLINE")
    end
    
    if bar.timerText then
        bar.timerText:SetFont(fontFace, timerFontSize, "OUTLINE")
    end
    
    if bar.waitText then
        bar.waitText:SetFont(fontFace, timerFontSize, "OUTLINE")
    end
end

function QueueMaster:GetQueueTypeColor(queueType)
    -- Check if class-colored bars are enabled or class theme is selected
    if self.settings and (self.settings.useClassColors or self.settings.colorTheme == "class") then
        return self:GetPlayerClassColor()
    end
    
    -- Use custom color if custom theme is selected
    if self.settings and self.settings.colorTheme == "custom" and self.settings.customBarColor then
        return {
            r = self.settings.customBarColor[1] or 0.3,
            g = self.settings.customBarColor[2] or 0.7,
            b = self.settings.customBarColor[3] or 0.3
        }
    end
    
    -- Default: Queue-type-specific colors matching Blizzard's chat colors
    local colors = {
        ["Dungeon Finder"] = {r = 0.67, g = 0.83, b = 1.0}, -- Party chat blue (lighter for visibility)
        ["Raid Finder"] = {r = 1.0, g = 0.49, b = 0.04},    -- Raid warning orange
        ["LFR"] = {r = 1.0, g = 0.49, b = 0.04},             -- Raid warning orange
        ["Scenarios"] = {r = 0.25, g = 0.78, b = 0.92},      -- Light blue (similar to system messages)
        ["Flexible Raid"] = {r = 1.0, g = 0.49, b = 0.04},   -- Raid warning orange
        ["PvP"] = {r = 0.75, g = 0.1, b = 0.1},              -- Blood red for PvP
        ["Battleground"] = {r = 0.75, g = 0.1, b = 0.1},     -- Blood red for BG
        ["Arena"] = {r = 1.0, g = 0.2, b = 0.2},             -- Bright red for Arena
    }

    return colors[queueType] or {r = 0.67, g = 0.83, b = 1.0} -- Default to party blue
end

function QueueMaster:GetPlayerClassColor()
    local _, playerClass = UnitClass("player")
    if not playerClass then 
        return {r = 0.5, g = 0.5, b = 0.5} -- Gray fallback
    end

    -- Try to get class color from RAID_CLASS_COLORS first
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass] then
        local classColor = RAID_CLASS_COLORS[playerClass]
        return {
            r = classColor.r or classColor[1] or 0.5,
            g = classColor.g or classColor[2] or 0.5,
            b = classColor.b or classColor[3] or 0.5
        }
    end
    
    -- Fallback colors if RAID_CLASS_COLORS is not available
    local fallbackColors = {
        ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},     -- Tan
        ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},     -- Pink
        ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},      -- Green
        ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},       -- Yellow
        ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},      -- White
        ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23}, -- Dark Red
        ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},      -- Blue
        ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92},        -- Light Blue
        ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93},     -- Purple
        ["MONK"] = {r = 0.00, g = 1.00, b = 0.59},        -- Green
        ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04},       -- Orange
        ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79}, -- Purple
        ["EVOKER"] = {r = 0.20, g = 0.58, b = 0.50}       -- Teal
    }
    
    return fallbackColors[playerClass] or {r = 0.5, g = 0.5, b = 0.5} -- Gray default
end

function QueueMaster:GetThemeColor()
    if not self.settings or not self.settings.colorTheme then
        return nil
    end
    
    local themeColors = {
        ["default"] = {r = 0.3, g = 0.7, b = 0.3},
        ["class"] = self:GetPlayerClassColor(),
        ["custom"] = {
            r = (self.settings.customBarColor and self.settings.customBarColor[1]) or 0.3,
            g = (self.settings.customBarColor and self.settings.customBarColor[2]) or 0.7,
            b = (self.settings.customBarColor and self.settings.customBarColor[3]) or 0.3
        }
    }
    
    return themeColors[self.settings.colorTheme]
end

function QueueMaster:GetProgressColor(progress)
    -- Green -> Yellow -> Red based on progress
    if progress < 0.5 then
        return {r = progress * 2, g = 1, b = 0}
    else
        return {r = 1, g = 2 - (progress * 2), b = 0}
    end
end

-- Apply colors to a bar based on current theme settings
function QueueMaster:ApplyBarColors(bar, queueID)
    if not bar then return end
    
    local queueData = self.queues and self.queues[queueID]
    if not queueData then return end
    
    -- Get the appropriate color based on settings
    local color = self:GetQueueTypeColor(queueData.type or queueData.queueType or queueData.categoryName or "Unknown")
    
    if not color then
        color = {r = 0.3, g = 0.7, b = 0.3} -- Fallback to default green
    end
    
    -- Get edge opacity setting
    local edgeOpacity = (self.settings and self.settings.edgeOpacity) or 1.0
    
    -- Apply status bar color
    if bar.SetStatusBarColor then
        bar:SetStatusBarColor(color.r or 0.3, color.g or 0.7, color.b or 0.3, 0.85)
    end
    
    -- Apply border color
    if bar.border and bar.border.SetBackdropBorderColor then
        bar.border:SetBackdropBorderColor(color.r or 0.3, color.g or 0.7, color.b or 0.3, edgeOpacity)
    end
    
    -- Apply background color (darker version)
    if bar.bg and bar.bg.SetVertexColor then
        bar.bg:SetVertexColor((color.r or 0.3) * 0.3, (color.g or 0.7) * 0.3, (color.b or 0.3) * 0.3, edgeOpacity * 0.6)
    end
end