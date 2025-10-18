local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Try to load LibSharedMedia for extended font support
local LSM = LibStub("LibSharedMedia-3.0", true)

-- Appearance settings configuration module
local AppearanceSettings = {}

-- Helper function to get available fonts
local function GetAvailableFonts()
    if LSM then
        -- Use LibSharedMedia fonts if available
        local fonts = LSM:List("font")
        local fontTable = {}
        for _, fontName in pairs(fonts) do
            fontTable[fontName] = fontName
        end
        return fontTable
    else
        -- Fall back to hardcoded WoW fonts
        return {
            ["Fonts\\FRIZQT__.TTF"] = "Friz Quadrata - Default WoW font",
            ["Fonts\\ARIALN.TTF"] = "Arial Narrow - Clean and modern",
            ["Fonts\\skurri.TTF"] = "Skurri - Bold and clear",
            ["Fonts\\MORPHEUS.TTF"] = "Morpheus - Decorative style",
            ["Fonts\\FRIENDS.TTF"] = "Friends - Friendly rounded font",
            ["Fonts\\2002.TTF"] = "2002 - Bold and wide",
            ["Fonts\\ARHei.ttf"] = "AR Hei - Modern sans-serif",
            ["Fonts\\ARKAI_T.ttf"] = "AR Kai - Traditional style",
        }
    end
end

-- Helper function to get font path from name
local function GetFontPath(fontName)
    if LSM then
        return LSM:Fetch("font", fontName)
    else
        return fontName
    end
end

function AppearanceSettings:GetOptions()
    return {
        name = "|cffffff00APPEARANCE|r",
        type = "group",
        order = 3,
        args = {
            visualHeader = {
                name = "|cFFFFD700Visual Customization|r",
                type = "header",
                order = 1
            },
            visualDesc = {
                name = "Customize the visual appearance of queue timer bars and frames.",
                type = "description",
                fontSize = "medium",
                order = 2
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 3
            },
            frameAlpha = {
                name = "Frame Transparency",
                desc = "Adjust the transparency of queue frames (higher = more opaque)",
                type = "range",
                min = 0.1,
                max = 1.0,
                step = 0.05,
                bigStep = 0.1,
                isPercent = true,
                get = function() return QueueMaster.settings.frameAlpha end,
                set = function(info, val) 
                    QueueMaster.settings.frameAlpha = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                    if QueueMaster.UpdatePreview then
                        QueueMaster:UpdatePreview()
                    end
                end,
                order = 4
            },
            edgeOpacity = {
                name = "Edge Opacity",
                desc = "Adjust the opacity of bar edges and backgrounds. Lower values create a text-only appearance.",
                type = "range",
                min = 0.0,
                max = 1.0,
                step = 0.05,
                bigStep = 0.1,
                isPercent = true,
                get = function() return QueueMaster.settings.edgeOpacity or 1.0 end,
                set = function(info, val) 
                    QueueMaster.settings.edgeOpacity = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                    -- Force UI redraw for alpha changes
                    if QueueMaster.UpdatePreview then
                        QueueMaster:UpdatePreview()
                    end
                end,
                order = 4.5
            },
            fontFace = {
                name = "Font Style",
                desc = LSM and "Choose from all available fonts (via LibSharedMedia)" or "Choose the font style for all text in queue timer bars",
                type = "select",
                width = "full",
                -- Note: dialogControl = "LSM30_Font" requires AceGUISharedMediaWidgets library
                -- Using standard select dropdown works fine with LSM
                values = GetAvailableFonts,
                get = function()
                    if LSM then
                        -- For LSM, we store the font name, not the path
                        local fontPath = QueueMaster.settings.fontFace or "Fonts\\FRIZQT__.TTF"
                        -- Try to find the font name from the path
                        local fonts = LSM:List("font")
                        for _, fontName in pairs(fonts) do
                            if LSM:Fetch("font", fontName) == fontPath then
                                return fontName
                            end
                        end
                        -- If not found in LSM, return the first font as default
                        return fonts[1] or "Friz Quadrata TT"
                    else
                        return QueueMaster.settings.fontFace or "Fonts\\FRIZQT__.TTF"
                    end
                end,
                set = function(info, val)
                    -- Convert font name to path if using LSM
                    local fontPath = GetFontPath(val)
                    QueueMaster.settings.fontFace = fontPath
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    else
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                    if QueueMaster.UpdatePreview then
                        QueueMaster:UpdatePreview()
                    end
                end,
                order = 5
            },
            spacer2 = {
                name = "",
                type = "description",
                order = 6
            },
            displayElementsHeader = {
                name = "|cFFFFD700Display Elements|r",
                type = "header",
                order = 6.5
            },
            displayElementsDesc = {
                name = "Choose which elements to show on queue bars and customize their font sizes.",
                type = "description",
                fontSize = "medium",
                order = 6.6
            },
            showInstanceName = {
                name = "Show Instance Name",
                desc = "Display the dungeon/raid name on the bar",
                type = "toggle",
                width = 0.5,
                get = function()
                    if QueueMaster.settings.showInstanceName == nil then
                        return true -- Default to shown
                    end
                    return QueueMaster.settings.showInstanceName
                end,
                set = function(info, val)
                    QueueMaster.settings.showInstanceName = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    end
                end,
                order = 6.7
            },
            showTimer = {
                name = "Show Timer",
                desc = "Display the elapsed queue time on the bar",
                type = "toggle",
                width = 0.5,
                get = function()
                    if QueueMaster.settings.showTimer == nil then
                        return true -- Default to shown
                    end
                    return QueueMaster.settings.showTimer
                end,
                set = function(info, val)
                    QueueMaster.settings.showTimer = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    end
                end,
                order = 6.72
            },
            instanceNameFontSize = {
                name = "Font Size",
                desc = "Font size for instance/dungeon names and timer",
                type = "range",
                width = 1.0,
                min = 8,
                max = 20,
                step = 1,
                bigStep = 2,
                disabled = function()
                    return not (QueueMaster.settings.showInstanceName ~= false)
                end,
                get = function() return QueueMaster.settings.instanceNameFontSize or 12 end,
                set = function(info, val)
                    QueueMaster.settings.instanceNameFontSize = val
                    -- Update fonts on all active bars
                    if QueueMaster.queueBars then
                        for queueID, bar in pairs(QueueMaster.queueBars) do
                            if bar then
                                QueueMaster:UpdateBarFontSizes(bar, bar:GetWidth(), bar:GetHeight())
                                -- Force text update to show font change immediately
                                QueueMaster:UpdateQueueBar(queueID, bar)
                            end
                        end
                    end
                end,
                order = 6.74
            },
            lineBreak2 = {
                name = "",
                type = "description",
                width = "full",
                order = 6.77
            },
            showRoleComposition = {
                name = "Show Role Composition",
                desc = "Display tank/healer/DPS role counts (T:1/1 H:1/1 D:3/3)",
                type = "toggle",
                width = 1.0,
                get = function() 
                    if QueueMaster.settings.showRoleBars == nil then
                        return true -- Default to shown
                    end
                    return QueueMaster.settings.showRoleBars
                end,
                set = function(info, val) 
                    QueueMaster.settings.showRoleBars = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    end
                end,
                order = 6.9
            },
            roleFontSize = {
                name = "Font Size",
                desc = "Font size for role composition (T/H/D counts)",
                type = "range",
                width = 1.0,
                min = 8,
                max = 20,
                step = 1,
                bigStep = 2,
                disabled = function() 
                    return not (QueueMaster.settings.showRoleBars ~= false)
                end,
                get = function() return QueueMaster.settings.roleFontSize or 11 end,
                set = function(info, val) 
                    QueueMaster.settings.roleFontSize = val
                    -- Update fonts on all active bars
                    if QueueMaster.queueBars then
                        for queueID, bar in pairs(QueueMaster.queueBars) do
                            if bar then
                                QueueMaster:UpdateBarFontSizes(bar, bar:GetWidth(), bar:GetHeight())
                                -- Force text update to show font change immediately
                                QueueMaster:UpdateQueueBar(queueID, bar)
                            end
                        end
                    end
                end,
                order = 6.95
            },
            spacer3 = {
                name = "",
                type = "description",
                order = 7
            },
            colorHeader = {
                name = "|cFFFFD700Color Themes|r",
                type = "header",
                order = 7.5
            },
            colorTheme = {
                name = "Color Theme",
                desc = "Choose a color scheme for queue bars",
                type = "select",
                width = "full",
                values = {
                    default = "|cFF4CAF50Default|r - Queue-type colors (LFD=Blue, LFR=Orange, BG=Red)",
                    class = "|cFFFFD700Class Colors|r - Use your character's class colors",
                    custom = "|cFFFF6600Custom|r - Choose your own color"
                },
                get = function() return QueueMaster.settings.colorTheme or "default" end,
                set = function(info, val)
                    QueueMaster.settings.colorTheme = val
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    end
                end,
                order = 8
            },
            customBarColor = {
                name = "Custom Bar Color",
                desc = "Select a custom color for all queue bars (only applies when Custom theme is selected)",
                type = "color",
                hasAlpha = false,
                width = "full",
                disabled = function()
                    return QueueMaster.settings.colorTheme ~= "custom"
                end,
                get = function()
                    if not QueueMaster.settings.customBarColor then
                        QueueMaster.settings.customBarColor = {0.3, 0.7, 0.3}
                    end
                    local color = QueueMaster.settings.customBarColor
                    return color[1] or 0.3, color[2] or 0.7, color[3] or 0.3
                end,
                set = function(info, r, g, b)
                    QueueMaster.settings.customBarColor = {r, g, b}
                    -- Force immediate color update
                    if QueueMaster.ApplySettingsToActiveBarsWithoutMove then
                        QueueMaster:ApplySettingsToActiveBarsWithoutMove()
                    elseif QueueMaster.ApplySettingsToActiveBars then
                        QueueMaster:ApplySettingsToActiveBars()
                    end
                    -- Also force color theme application
                    if QueueMaster.ApplyColorTheme then
                        QueueMaster:ApplyColorTheme("custom")
                    end
                end,
                order = 8.5
            }
        }
    }
end

-- Export the module
QueueMaster.AppearanceSettings = AppearanceSettings