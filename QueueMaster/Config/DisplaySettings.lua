local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Display settings configuration module
local DisplaySettings = {}

function DisplaySettings:GetOptions()
    return {
        name = "|cff0080ffDISPLAY|r",
        type = "group",
        order = 2,
        args = {
            displayModeHeader = {
                name = "|cFFFFD700Bar Customization|r",
                type = "header",
                order = 1
            },
            displayMode = {
                name = "Bar Layout Mode",
                desc = "Choose how queue timer bars are arranged on your screen",
                type = "select",
                width = "full",
                values = {
                    vertical = "|cff00ff00Vertical|r - Stack bars vertically (one above another)",
                    horizontal = "|cffffff00Horizontal|r - Arrange bars horizontally (side by side)"
                },
                get = function() return QueueMaster.settings.displayMode or "vertical" end,
                set = function(info, val)
                    QueueMaster.settings.displayMode = val
                    QueueMaster:UpdateQueueBarLayout()
                    if val == "vertical" then
                        QueueMaster:Print("Layout changed to |cff00ff00Vertical|r - bars will stack vertically.")
                    elseif val == "horizontal" then
                        QueueMaster:Print("Layout changed to |cffffff00Horizontal|r - bars will arrange side by side.")
                    end
                end,
                order = 1.5
            },
            compactMode = {
                name = "Compact Mode",
                desc = "Use smaller fonts and tighter spacing to fit all information on narrow bars. Shows all elements (instance name, timer, roles) even on bars < 300px width.",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.settings.compactMode or false end,
                set = function(info, val)
                    QueueMaster.settings.compactMode = val
                    if val then
                        QueueMaster:Print("Compact mode |cFF00FF00enabled|r - all elements visible on narrow bars with smaller fonts.")
                    else
                        QueueMaster:Print("Compact mode |cFFFF6600disabled|r - using width-based element hiding.")
                    end
                    -- Force immediate refresh of all bars
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    end
                    -- Force layout update to apply new visibility rules
                    if QueueMaster.UpdateAllQueueBars then
                        QueueMaster:UpdateAllQueueBars()
                    end
                end,
                order = 1.6
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 2
            },
            positioningHeader = {
                name = "|cFFFFD700Positioning & Layout|r",
                type = "header",
                order = 5
            },
            positioningDesc = {
                name = "Configure how queue bars are positioned and moved around your screen.",
                type = "description",
                fontSize = "medium",
                order = 6
            },
            spacer_pos = {
                name = "",
                type = "description",
                order = 7
            },
            lockFrame = {
                name = "Lock Bar Positions",
                desc = "Prevent timer bars from being moved by dragging. When unlocked, you'll see a movable anchor to position all bars.",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.settings.lockFrame end,
                set = function(info, val) 
                    QueueMaster.settings.lockFrame = val
                    if val then
                        QueueMaster:Print("Timer bars are now |cFFFF6600locked|r in position.")
                        -- Hide anchor when locked
                        if QueueMaster.queueAnchor then
                            QueueMaster.queueAnchor:Hide()
                        end
                    else
                        QueueMaster:Print("Timer bars can now be |cFF00FF00moved|r by dragging. Look for the red anchor box!")
                        -- Show anchor when unlocked
                        QueueMaster:UpdateQueueBarLayout()
                    end
                end,
                order = 8
            },
            groupMovement = {
                name = "Group Movement Mode",
                desc = "When enabled, moving one bar moves all bars together as a group. When disabled, each bar can be positioned individually.",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.settings.groupMovement end,
                set = function(info, val) 
                    QueueMaster.settings.groupMovement = val
                    if val then
                        QueueMaster:Print("Group movement |cFF00FF00enabled|r - all bars will move together.")
                    else
                        QueueMaster:Print("Individual movement |cFF00FF00enabled|r - each bar can be moved separately.")
                    end
                end,
                order = 9
            },
            useAnchor = {
                name = "Use Movable Anchor",
                desc = "Show a movable anchor point that controls the position of all timer bars",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.settings.useAnchor end,
                set = function(info, val) 
                    QueueMaster.settings.useAnchor = val
                    if val then
                        QueueMaster:ShowGroupAnchor()
                        QueueMaster:Print("Movable anchor |cFF00FF00enabled|r. Drag the anchor to reposition all bars.")
                    else
                        QueueMaster:HideGroupAnchor()
                        QueueMaster:Print("Movable anchor |cFFFF6600disabled|r.")
                    end
                end,
                order = 10
            },
            resetPositions = {
                name = "Reset Bar Positions",
                desc = "Reset all timer bar positions to their default top-left location",
                type = "execute",
                width = "full",
                func = function()
                    QueueMaster:ResetBarPositions()
                    QueueMaster:Print("All timer bar positions have been |cFF00FF00reset|r to top-left.")
                end,
                order = 11
            },
            spacer2 = {
                name = "",
                type = "description",
                order = 12
            },
            layoutHeader = {
                name = "|cFFFFD700Bar Layout|r",
                type = "header",
                order = 13
            },
            scale = {
                name = "UI Scale",
                desc = "Scale all queue bars (larger or smaller). Default is 1.0 (100%)",
                type = "range",
                min = 0.5,
                max = 2.0,
                step = 0.05,
                bigStep = 0.1,
                isPercent = true,
                get = function() return QueueMaster.settings.scale or 1.0 end,
                set = function(info, val) 
                    QueueMaster.settings.scale = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                end,
                order = 13.5
            },
            barHeight = {
                name = "Bar Height",
                desc = "Height of each queue timer bar in pixels",
                type = "range",
                min = 20,
                max = 60,
                step = 2,
                bigStep = 4,
                get = function() return QueueMaster.settings.barHeight end,
                set = function(info, val) 
                    QueueMaster.settings.barHeight = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                end,
                order = 14
            },
            barWidth = {
                name = "Bar Width",
                desc = "Width of each queue timer bar in pixels",
                type = "range",
                min = 200,
                max = 600,
                step = 10,
                bigStep = 50,
                get = function() return QueueMaster.settings.barWidth or 400 end,
                set = function(info, val) 
                    QueueMaster.settings.barWidth = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                end,
                order = 14.5
            },
            barSpacing = {
                name = "Bar Spacing",
                desc = "Spacing between multiple queue bars (vertical or horizontal depending on layout mode)",
                type = "range",
                min = 0,
                max = 20,
                step = 1,
                bigStep = 2,
                get = function() return QueueMaster.settings.barSpacing end,
                set = function(info, val) 
                    QueueMaster.settings.barSpacing = val
                    -- CRITICAL FIX: Only refresh the current layout mode, don't change it!
                    -- Re-apply the current displayMode to update spacing
                    local currentMode = QueueMaster.settings.displayMode or "vertical"
                    if currentMode == "vertical" and QueueMaster.LayoutVertical then
                        QueueMaster:LayoutVertical()
                    elseif currentMode == "horizontal" and QueueMaster.LayoutHorizontal then
                        QueueMaster:LayoutHorizontal()
                    elseif currentMode == "textonly" and QueueMaster.LayoutTextOnly then
                        QueueMaster:LayoutTextOnly()
                    end
                end,
                order = 15
            }
        }
    }
end

-- Export the module
QueueMaster.DisplaySettings = DisplaySettings