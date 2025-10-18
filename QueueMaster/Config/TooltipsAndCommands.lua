local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Tooltips and Commands configuration module
local TooltipsAndCommands = {}

function TooltipsAndCommands:GetTooltipsOptions()
    return {
        name = "|cff00ff00TOOLTIPS|r",
        type = "group",
        order = 4,
        args = {
            tooltipHeader = {
                name = "|cFFFFD700Tooltip Settings|r",
                type = "header",
                order = 1
            },
            tooltipDesc = {
                name = "Customize what information appears in queue timer tooltips.",
                type = "description",
                fontSize = "medium",
                order = 2
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 3
            },
            showPlayerInfo = {
                name = "Show Player Information",
                desc = "Display player level, class, spec, and item level in tooltips",
                type = "toggle",
                get = function() return QueueMaster.settings.showPlayerInfo end,
                set = function(info, val) QueueMaster.settings.showPlayerInfo = val end,
                order = 4
            },
            showQueueStats = {
                name = "Show Queue Statistics",
                desc = "Display queue position, attempts, and server information",
                type = "toggle",
                get = function() return QueueMaster.settings.showQueueStats end,
                set = function(info, val) QueueMaster.settings.showQueueStats = val end,
                order = 5
            },
            showWaitHistory = {
                name = "Show Wait Time History",
                desc = "Display recent wait times and averages for this queue type",
                type = "toggle",
                get = function() return QueueMaster.settings.showWaitHistory end,
                set = function(info, val) QueueMaster.settings.showWaitHistory = val end,
                order = 6
            },
            showQueueTips = {
                name = "Show Queue Tips",
                desc = "Display helpful tips and suggestions based on queue status",
                type = "toggle",
                get = function() return QueueMaster.settings.showQueueTips end,
                set = function(info, val) QueueMaster.settings.showQueueTips = val end,
                order = 7
            },
            tooltipUpdateRate = {
                name = "Tooltip Update Rate",
                desc = "How often tooltips refresh their information (in seconds)",
                type = "range",
                min = 0.1,
                max = 2.0,
                step = 0.1,
                bigStep = 0.5,
                get = function() return QueueMaster.settings.tooltipUpdateRate or 0.5 end,
                set = function(info, val) QueueMaster.settings.tooltipUpdateRate = val end,
                order = 8
            }
        }
    }
end

function TooltipsAndCommands:GetCommandsOptions()
    return {
        name = "|cffff00ffCOMMANDS|r",
        type = "group",
        order = 5,
        args = {
            commandsHeader = {
                name = "|cFFFFD700Slash Commands Reference|r",
                type = "header",
                order = 1
            },
            commandsDesc = {
                name = "|cffff0000Queue|r|cff0080ffMaster|r supports various slash commands for quick access to features.",
                type = "description",
                fontSize = "medium",
                order = 2
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 3
            },
            basicCommands = {
                name = "|cFFADD8E6Basic Commands:|r\n" ..
                       "|cFFFFD700/qm|r or |cFFFFD700/queuemaster|r - Show command help\n" ..
                       "|cFFFFD700/qm config|r - Open this configuration menu\n" ..
                       "|cFFFFD700/qm status|r - Show current addon status\n" ..
                       "|cFFFFD700/qm show|r - Force show queue frames\n" ..
                       "|cFFFFD700/qm hide|r - Hide queue frames",
                type = "description",
                fontSize = "medium",
                order = 4
            },
            spacer2 = {
                name = "",
                type = "description",
                order = 5
            },
            displayCommands = {
                name = "|cFFADD8E6Display Commands:|r\n" ..
                       "|cFFFFD700/qm scale <0.5-2.0>|r - Set UI scale\n" ..
                       "|cFFFFD700/qm anchor|r - Toggle anchor visibility",
                type = "description",
                fontSize = "medium",
                order = 6
            },
            spacer3 = {
                name = "",
                type = "description",
                order = 7
            },
            toggleCommands = {
                name = "|cFFADD8E6Toggle Commands:|r\n" ..
                       "|cFFFFD700/qm toggle rolebars|r - Toggle role information display\n" ..
                       "|cFFFFD700/qm toggle alerts|r - Toggle popup alerts\n" ..
                       "|cFFFFD700/qm toggle sound|r - Toggle sound notifications\n" ..
                       "|cFFFFD700/qm toggle flash|r - Toggle screen flash alerts",
                type = "description",
                fontSize = "medium",
                order = 8
            },
            spacer4 = {
                name = "",
                type = "description",
                order = 9
            },
            maintenanceCommands = {
                name = "|cFFADD8E6Maintenance Commands:|r\n" ..
                       "|cFFFFD700/qm clear|r - Clear all active queues\n" ..
                       "|cFFFFD700/qm cleanup|r - Remove malformed queue bars\n" ..
                       "|cFFFFD700/qm refresh|r - Force refresh queue detection\n" ..
                       "|cFFFFD700/qm reset|r - Reset frame position to center",
                type = "description",
                fontSize = "medium",
                order = 10
            },
            debugCommands = {
                name = "|cFFADD8E6Debug Commands:|r\n" ..
                       "|cFFFFD700/qm status|r - Show current queue status and diagnostics\n" ..
                       "|cFFFFD700/qm blizz|r - Toggle Blizzard queue UI (for debugging)\n" ..
                       "|cFFFFD700/qm debug|r - Toggle debug logging",
                type = "description",
                fontSize = "medium",
                order = 11
            }
        }
    }
end

-- Export the module
QueueMaster.TooltipsAndCommands = TooltipsAndCommands