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

    elseif msg == "forceshow" then
        -- Force all bars to center of screen and make them visible
        local count = 0
        for queueID, bar in pairs(QueueMaster.queueBars or {}) do
            count = count + 1
            bar:ClearAllPoints()
            bar:SetPoint("CENTER", UIParent, "CENTER", 0, (count - 1) * -50)
            bar:SetAlpha(1)
            bar:Show()
            bar:SetFrameStrata("FULLSCREEN")
            QueueMaster:Print(string.format("Forced bar %d (%s) to center", count, queueID))
        end
        QueueMaster:Print(string.format("Forced %d bars to screen center", count))
    elseif msg == "reset" or msg == "resetbars" then
        -- Force recreate all bars with new structure AND clear saved positions
        QueueMaster:Print("Clearing saved positions and recreating all queue bars...")

        -- Clear all saved bar positions
        if QueueMaster.db and QueueMaster.db.char then
            QueueMaster.db.char.positions = {}
            QueueMaster:Print("Cleared all saved bar positions")
        end

        QueueMaster:ClearAllQueues()
        C_Timer.After(0.5, function()
            QueueMaster:UpdateQueues()
            QueueMaster:Print("Queue bars recreated with latest structure!")
        end)
    elseif msg == "update" or msg == "force" then
        -- Force immediate queue update
        QueueMaster:Print("Forcing queue update...")
        QueueMaster:UpdateQueues(true)
        C_Timer.After(0.5, function()
            QueueMaster:Print("Update complete. Queues detected: " .. (QueueMaster.queues and QueueMaster:TableCount(QueueMaster.queues) or 0))
        end)

    elseif msg == "status" or msg == "info" then
        -- Show detailed queue and bar status
        QueueMaster:Print("=== QueueMaster Status ===")
        QueueMaster:Print("Addon enabled: " .. tostring(QueueMaster.settings.enabled))

        -- Count queues
        local queueCount = 0
        for queueID, queue in pairs(QueueMaster.queues or {}) do
            queueCount = queueCount + 1
            QueueMaster:Print(string.format("Queue %d: %s (ID: %s)", queueCount, queue.instanceName or "Unknown", queueID))
        end
        QueueMaster:Print("Total queues in memory: " .. queueCount)

        -- Count bars
        local barCount = 0
        local visibleCount = 0
        for queueID, bar in pairs(QueueMaster.queueBars or {}) do
            barCount = barCount + 1
            local queue = QueueMaster.queues[queueID]
            local queueName = queue and queue.instanceName or "Unknown"

            if bar:IsShown() then
                visibleCount = visibleCount + 1
                local point, relativeTo, relativePoint, x, y = bar:GetPoint()
                QueueMaster:Print(string.format("Bar %d: %s (%s) - VISIBLE at (%.0f, %.0f)", barCount, queueName, queueID, x or 0, y or 0))
            else
                QueueMaster:Print(string.format("Bar %d: %s (%s) - HIDDEN", barCount, queueName, queueID))
            end
        end
        QueueMaster:Print(string.format("Total bars: %d (%d visible, %d hidden)", barCount, visibleCount, barCount - visibleCount))

        -- Check LFG API directly
        QueueMaster:Print("=== LFG API Check ===")
        for category = 1, 10 do
            local mode, submode = QueueMaster.SafeGetLFGMode(category)
            if mode and mode ~= "none" then
                QueueMaster:Print(string.format("Category %d: %s", category, mode))

                -- Check GetLFGQueuedList
                if GetLFGQueuedList then
                    local queuedTable = GetLFGQueuedList(category)
                    if queuedTable and type(queuedTable) == "table" then
                        local count = 0
                        for activeID, _ in pairs(queuedTable) do
                            count = count + 1
                            local queueInfo = QueueMaster.SafeGetLFGQueueStats(category, activeID)
                            if queueInfo and queueInfo.hasData then
                                QueueMaster:Print(string.format("  - ActiveID %s: %s", tostring(activeID), queueInfo.instanceName or "Unknown"))
                            else
                                QueueMaster:Print(string.format("  - ActiveID %s: No data", tostring(activeID)))
                            end
                        end
                        QueueMaster:Print(string.format("  Total activeIDs found: %d", count))
                    else
                        QueueMaster:Print("  GetLFGQueuedList returned no data")
                    end
                else
                    QueueMaster:Print("  GetLFGQueuedList not available")
                end
            end
        end

    elseif msg == "debug" then
        -- Toggle debug mode
        QueueMaster.debugMode = not QueueMaster.debugMode
        if QueueMaster.debugMode then
            QueueMaster:Print("Debug mode |cFF00FF00ENABLED|r - Warning: This will spam chat constantly!")
            QueueMaster:Print("Use |cFFFFFF00/qm debugonce|r for a single debug update instead")
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

    elseif msg == "debugonce" then
        -- One-time debug update without enabling continuous spam
        local oldDebugMode = QueueMaster.debugMode
        QueueMaster.debugMode = true
        QueueMaster:Print("=== One-time Debug Update ===")
        QueueMaster:UpdateQueues(true)
        C_Timer.After(0.1, function()
            QueueMaster.debugMode = oldDebugMode
            QueueMaster:Print("=== Debug Update Complete ===")
        end)
    elseif msg == "help" then
        -- Show help
        QueueMaster:Print("Available commands:")
        QueueMaster:Print("  |cFFFFFF00/qm|r - Open settings panel")
        QueueMaster:Print("  |cFFFFFF00/qm status|r - Show detailed queue and bar information")
        QueueMaster:Print("  |cFFFFFF00/qm update|r - Force immediate queue detection")
        QueueMaster:Print("  |cFFFFFF00/qm refresh|r - Force refresh and show all bars")
        QueueMaster:Print("  |cFFFFFF00/qm reset|r - Recreate all bars (fixes missing timer)")
        QueueMaster:Print("  |cFFFFFF00/qm anchor|r - Toggle anchor visibility")
        QueueMaster:Print("  |cFFFFFF00/qm debug|r - Toggle continuous debug mode (spammy!)")
        QueueMaster:Print("  |cFFFFFF00/qm debugonce|r - Run one debug update (no spam)")
        QueueMaster:Print("  |cFFFFFF00/qm help|r - Show this help")
    else
        QueueMaster:ShowConfig()
    end
end
