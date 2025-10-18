-- Minimal slash command for QueueMaster
-- Only provides access to the settings panel

local addonName, addon = ...
local QueueMaster = addon.QueueMaster

if not QueueMaster then
    error("QueueMaster addon not found")
end

-- Single slash command to open settings
SLASH_QMCONFIG1 = "/qmconfig"
SLASH_QMCONFIG2 = "/qm"

SlashCmdList["QMCONFIG"] = function(msg)
    msg = msg:lower():trim()
    
    if msg == "anchor" then
        QueueMaster:ToggleAnchor()
    elseif msg == "testanchor" then
        -- Force create and show anchor for testing
        if not QueueMaster.queueAnchor then
            QueueMaster:CreateQueueAnchor()
        end
        QueueMaster.queueAnchor:Show()
        QueueMaster:Print("Anchor forced visible at top of screen for testing")
    elseif msg == "refresh" or msg == "show" then
        -- Force refresh all bars - make them visible without full reset
        QueueMaster:RefreshAllBars()
        QueueMaster:Print("Queue bars refreshed and forced visible")
    elseif msg == "reset" or msg == "resetbars" then
        -- Force recreate all bars with new structure
        QueueMaster:Print("Recreating all queue bars...")
        QueueMaster:ClearAllQueues()
        C_Timer.After(0.5, function()
            QueueMaster:UpdateQueues()
            QueueMaster:Print("Queue bars recreated with latest structure!")
        end)
    elseif msg == "debug" then
        -- Toggle debug mode
        QueueMaster.debugMode = not QueueMaster.debugMode
        if QueueMaster.debugMode then
            QueueMaster:Print("Debug mode |cFF00FF00ENABLED|r")
            -- Show current anchor status
            if QueueMaster.queueAnchor then
                local isShown = QueueMaster.queueAnchor:IsShown()
                QueueMaster:Print("Anchor exists: |cFF00FF00YES|r, Shown: " .. (isShown and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))
                QueueMaster:Print("Settings: useAnchor=" .. tostring(QueueMaster.settings.useAnchor) .. ", lockFrame=" .. tostring(QueueMaster.settings.lockFrame))
            else
                QueueMaster:Print("Anchor exists: |cFFFF0000NO|r")
            end
        else
            QueueMaster:Print("Debug mode |cFFFF0000DISABLED|r")
        end
    elseif msg == "help" then
        -- Show help
        QueueMaster:Print("Available commands:")
        QueueMaster:Print("  |cFFFFFF00/qm|r - Open settings panel")
        QueueMaster:Print("  |cFFFFFF00/qm refresh|r - Force refresh and show all bars")
        QueueMaster:Print("  |cFFFFFF00/qm reset|r - Recreate all bars (fixes missing timer)")
        QueueMaster:Print("  |cFFFFFF00/qm anchor|r - Toggle anchor visibility")
        QueueMaster:Print("  |cFFFFFF00/qm debug|r - Toggle debug mode")
        QueueMaster:Print("  |cFFFFFF00/qm help|r - Show this help")
    else
        QueueMaster:ShowConfig()
    end
end
