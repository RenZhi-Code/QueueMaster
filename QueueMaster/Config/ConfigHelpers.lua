local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Config helper functions module
local ConfigHelpers = {}

-- Enhanced validation functions for better UX and error handling
function ConfigHelpers:ValidateSettings()
    local settings = QueueMaster.settings
    local changed = false
    local errors = {}
    
    -- Validate scale
    if not settings.scale or type(settings.scale) ~= "number" or settings.scale < 0.5 or settings.scale > 2.0 then
        local oldValue = settings.scale
        settings.scale = 1.0
        changed = true
        table.insert(errors, string.format("Scale reset from %s to 1.0 (valid range: 0.5-2.0)", tostring(oldValue)))
    end
    
    -- Validate bar dimensions
    if not settings.barWidth or type(settings.barWidth) ~= "number" or settings.barWidth < 200 or settings.barWidth > 600 then
        local oldValue = settings.barWidth
        settings.barWidth = 300
        changed = true
        table.insert(errors, string.format("Bar width reset from %s to 300 (valid range: 200-600)", tostring(oldValue)))
    end
    
    if not settings.barHeight or type(settings.barHeight) ~= "number" or settings.barHeight < 20 or settings.barHeight > 60 then
        local oldValue = settings.barHeight
        settings.barHeight = 32
        changed = true
        table.insert(errors, string.format("Bar height reset from %s to 32 (valid range: 20-60)", tostring(oldValue)))
    end
    
    -- Validate spacing
    if not settings.barSpacing or type(settings.barSpacing) ~= "number" or settings.barSpacing < 0 or settings.barSpacing > 20 then
        local oldValue = settings.barSpacing
        settings.barSpacing = 8
        changed = true
        table.insert(errors, string.format("Bar spacing reset from %s to 8 (valid range: 0-20)", tostring(oldValue)))
    end
    
    -- Validate alpha
    if not settings.frameAlpha or type(settings.frameAlpha) ~= "number" or settings.frameAlpha < 0.1 or settings.frameAlpha > 1.0 then
        local oldValue = settings.frameAlpha
        settings.frameAlpha = 1.0
        changed = true
        table.insert(errors, string.format("Frame alpha reset from %s to 1.0 (valid range: 0.1-1.0)", tostring(oldValue)))
    end
    
    -- Validate font size
    if not settings.fontSize or type(settings.fontSize) ~= "number" or settings.fontSize < 8 or settings.fontSize > 18 then
        local oldValue = settings.fontSize
        settings.fontSize = 11
        changed = true
        table.insert(errors, string.format("Font size reset from %s to 11 (valid range: 8-18)", tostring(oldValue)))
    end
    
    -- Validate display mode
    local validModes = { vertical = true, horizontal = true, textonly = true }
    if not settings.displayMode or not validModes[settings.displayMode] then
        local oldValue = settings.displayMode
        settings.displayMode = "vertical"
        changed = true
        table.insert(errors, string.format("Display mode reset from %s to 'vertical'", tostring(oldValue)))
    end
    
    -- Validate color theme
    local validThemes = { default = true, class = true, custom = true }
    if not settings.colorTheme or not validThemes[settings.colorTheme] then
        local oldValue = settings.colorTheme
        settings.colorTheme = "default"
        changed = true
        table.insert(errors, string.format("Color theme reset from %s to 'default'", tostring(oldValue)))
    end
    
    -- Validate edge opacity
    if not settings.edgeOpacity or type(settings.edgeOpacity) ~= "number" or settings.edgeOpacity < 0.0 or settings.edgeOpacity > 1.0 then
        local oldValue = settings.edgeOpacity
        settings.edgeOpacity = 1.0
        changed = true
        table.insert(errors, string.format("Edge opacity reset from %s to 1.0 (valid range: 0.0-1.0)", tostring(oldValue)))
    end
    
    -- Validate custom colors
    if settings.customBarColor and type(settings.customBarColor) == "table" then
        local color = settings.customBarColor
        if #color ~= 3 or not ConfigHelpers:ValidateColorValues(color[1], color[2], color[3]) then
            settings.customBarColor = {0.3, 0.7, 0.3}
            changed = true
            table.insert(errors, "Custom bar color reset to default green")
        end
    end
    
    if settings.customBackgroundColor and type(settings.customBackgroundColor) == "table" then
        local color = settings.customBackgroundColor
        if #color ~= 4 or not ConfigHelpers:ValidateColorValues(color[1], color[2], color[3], color[4]) then
            settings.customBackgroundColor = {0.1, 0.1, 0.1, 0.8}
            changed = true
            table.insert(errors, "Custom background color reset to default dark")
        end
    end
    
    -- Validate anchor point
    local validAnchors = { TOP = true, BOTTOM = true, CENTER = true }
    if settings.anchorPoint and not validAnchors[settings.anchorPoint] then
        local oldValue = settings.anchorPoint
        settings.anchorPoint = "BOTTOM"
        changed = true
        table.insert(errors, string.format("Anchor point reset from %s to 'BOTTOM'", tostring(oldValue)))
    end
    
    -- Validate growth direction
    local validDirections = { DOWN = true, UP = true, LEFT = true, RIGHT = true }
    if settings.growDirection and not validDirections[settings.growDirection] then
        local oldValue = settings.growDirection
        settings.growDirection = "DOWN"
        changed = true
        table.insert(errors, string.format("Growth direction reset from %s to 'DOWN'", tostring(oldValue)))
    end
    
    -- Validate boolean settings
    local booleanSettings = {
        "enabled", "showMainFrame", "lockFrame", "useClassColors", "showAlerts", 
        "flashEnabled", "showPlayerInfo", "showQueueStats", "showWaitHistory", "showQueueTips"
    }
    for _, setting in ipairs(booleanSettings) do
        if settings[setting] ~= nil and type(settings[setting]) ~= "boolean" then
            local oldValue = settings[setting]
            settings[setting] = false
            changed = true
            table.insert(errors, string.format("%s reset from %s to false", setting, tostring(oldValue)))
        end
    end
    
    -- Validate tooltip update rate
    if settings.tooltipUpdateRate and (type(settings.tooltipUpdateRate) ~= "number" or settings.tooltipUpdateRate < 0.1 or settings.tooltipUpdateRate > 2.0) then
        local oldValue = settings.tooltipUpdateRate
        settings.tooltipUpdateRate = 0.5
        changed = true
        table.insert(errors, string.format("Tooltip update rate reset from %s to 0.5", tostring(oldValue)))
    end
    
    -- Force showMainFrame to be saved in the profile
    if not QueueMaster.db.profile.showMainFrame then
        QueueMaster.db.profile.showMainFrame = false
        changed = true
    end
    
    if changed then
        QueueMaster:Debug("Settings validation corrected invalid values")
        if #errors > 0 then
            QueueMaster:Print("|cFFFF6600Configuration validation:|r Fixed " .. #errors .. " invalid setting(s).")
            for i, error in ipairs(errors) do
                if i <= 3 then -- Limit displayed errors to avoid spam
                    QueueMaster:Debug("Validation: " .. error)
                end
            end
            if #errors > 3 then
                QueueMaster:Debug("Validation: ... and " .. (#errors - 3) .. " more issues fixed.")
            end
        end
        QueueMaster:ApplySettingsToActiveBars()
    end
    
    return not changed
end

-- Helper function to validate color values
function ConfigHelpers:ValidateColorValues(...)
    local values = {...}
    for _, value in ipairs(values) do
        if type(value) ~= "number" or value < 0 or value > 1 then
            return false
        end
    end
    return true
end

-- Enhanced settings application with validation
function ConfigHelpers:ApplySettingsEnhanced()
    -- Validate first
    ConfigHelpers:ValidateSettings()
    
    -- Apply the settings
    QueueMaster:ApplySettingsToActiveBars()
    
    -- Provide user feedback
    QueueMaster:Debug("Settings applied and validated successfully")
end

-- Show configuration window with improved UX
function ConfigHelpers:ShowConfig()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    -- Always open the standalone AceConfig dialog for better experience
    AceConfigDialog:Open("QueueMaster")
end

-- Legacy compatibility functions
function ConfigHelpers:HideConfig()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    -- Close any open config dialogs
    AceConfigDialog:Close("QueueMaster")
end

-- Apply settings to the addon (updated for Ace3)
function ConfigHelpers:ApplySettings()
    -- Use the comprehensive function for all settings application
    QueueMaster:ApplySettingsToActiveBars()
end

-- Export the module
QueueMaster.ConfigHelpers = ConfigHelpers