local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- General settings configuration module
local GeneralSettings = {}

function GeneralSettings:GetOptions()
    return {
        name = "|cffff0000GENERAL|r",
        type = "group",
        order = 1,
        args = {
            enabledHeader = {
                name = "|cFFFFD700CONTROLS|r",
                type = "header",
                order = 1
            },
            enabledDesc = {
                name = "|cff888888QueueMaster is active..|r",
                type = "description",
                fontSize = "medium",
                order = 1.5
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 3
            },
            notificationHeader = {
                name = "|cFFFFD700Notifications|r",
                type = "header",
                order = 4
            },
            showAlerts = {
                name = "Show Alert Messages",
                desc = "Display popup alert messages for queue events like joining, leaving, and queue ready notifications",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.settings.showAlerts end,
                set = function(info, val) QueueMaster.settings.showAlerts = val end,
                order = 5
            },
            soundEnabled = {
                name = "Enable Sound Notifications",
                desc = "Play sound effects for queue events and alerts",
                type = "toggle",
                width = "full",
                disabled = function() return not QueueMaster.settings.showAlerts end,
                get = function() return QueueMaster.settings.soundEnabled end,
                set = function(info, val) QueueMaster.settings.soundEnabled = val end,
                order = 6
            },
            flashEnabled = {
                name = "Enable Screen Flash",
                desc = "Flash the screen briefly for important queue events like queue ready notifications",
                type = "toggle",
                width = "full",
                disabled = function() return not QueueMaster.settings.showAlerts end,
                get = function() return QueueMaster.settings.flashEnabled end,
                set = function(info, val) QueueMaster.settings.flashEnabled = val end,
                order = 7
            },
            spacer_advanced = {
                name = "",
                type = "description",
                order = 8
            },
            advancedHeader = {
                name = "|cFFFFD700Advanced|r",
                type = "header",
                order = 9
            },
            debugMode = {
                name = "Enable Debug Mode",
                desc = "Show debug messages in chat (for troubleshooting only)",
                type = "toggle",
                width = "full",
                get = function() return QueueMaster.debugMode or false end,
                set = function(info, val) 
                    QueueMaster.debugMode = val
                    if val then
                        QueueMaster:Print("|cFFFF6600Debug mode enabled.|r You will see technical messages in chat.")
                    else
                        QueueMaster:Print("Debug mode disabled.")
                    end
                end,
                order = 10
            }
        }
    }
end

-- Export the module
QueueMaster.GeneralSettings = GeneralSettings