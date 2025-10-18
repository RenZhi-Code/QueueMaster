local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Event handlers module for QueueMaster
-- Handles all WoW event callbacks and throttling

-- Event throttling to prevent excessive updates
local eventThrottle = {}
local THROTTLE_DELAY = 0.5 -- 500ms throttle

local function ThrottledUpdate(self, eventName, delay)
    delay = delay or THROTTLE_DELAY
    local now = GetTime()
    
    -- Cancel existing timer for this event type
    if eventThrottle[eventName] then
        self:CancelTimer(eventThrottle[eventName])
    end
    
    -- Schedule new update
    eventThrottle[eventName] = self:ScheduleTimer(function()
        eventThrottle[eventName] = nil
        self:UpdateQueues()
    end, delay)
end

-- Export throttled update function for use by other event modules
QueueMaster.ThrottledUpdate = ThrottledUpdate

-- LFG (Dungeon Finder) event handlers
function QueueMaster:LFG_PROPOSAL_SHOW(...)
    self:Debug("LFG_PROPOSAL_SHOW event received")
    self:OnProposalShow()
end

function QueueMaster:LFG_UPDATE(...)
    self:Debug("LFG_UPDATE event received")
    self:OnQueueLeft()
end

function QueueMaster:LFG_ROLE_CHECK_HIDE(...)
    self:Debug("LFG_ROLE_CHECK_HIDE event received")
    ThrottledUpdate(self, "ROLE_CHECK", 1)
end

function QueueMaster:LFG_ROLE_CHECK_SHOW(...)
    self:Debug("LFG_ROLE_CHECK_SHOW event received")
    ThrottledUpdate(self, "ROLE_CHECK", 2)
end

-- LFG List (Group Finder) event handlers
function QueueMaster:UPDATE_LFG_LIST(...)
    self:Debug("UPDATE_LFG_LIST event received")
    ThrottledUpdate(self, "LFG_LIST", 1)
end

function QueueMaster:LFG_LIST_ACTIVE_ENTRY_UPDATE(...)
    self:Debug("LFG_LIST_ACTIVE_ENTRY_UPDATE event received")
    ThrottledUpdate(self, "LFG_ENTRY", 1)
end

-- Player state event handlers
function QueueMaster:PLAYER_ENTERING_WORLD(...)
    self:Debug("PLAYER_ENTERING_WORLD event received")
    ThrottledUpdate(self, "ENTERING_WORLD", 2)
end

-- PvP/Battleground queue event handler
function QueueMaster:UPDATE_BATTLEFIELD_STATUS(...)
    self:Debug("UPDATE_BATTLEFIELD_STATUS event received")
    -- PvP queues update immediately for instant bar display
    ThrottledUpdate(self, "PVP_UPDATE", 0.1)
end

-- Additional event handlers that may be needed for comprehensive queue detection
function QueueMaster:LFG_PROPOSAL_FAILED(...)
    self:Debug("LFG_PROPOSAL_FAILED event received")
    self:OnProposalEnd()
end

function QueueMaster:LFG_PROPOSAL_SUCCEEDED(...)
    self:Debug("LFG_PROPOSAL_SUCCEEDED event received")
    self:OnProposalEnd()
end

function QueueMaster:LFG_PROPOSAL_DONE(...)
    self:Debug("LFG_PROPOSAL_DONE event received")
    -- Proposal process completed (any outcome)
    self:OnProposalEnd()
    ThrottledUpdate(self, "PROPOSAL_DONE", 0.1)
end

function QueueMaster:ROLE_CHANGED_INFORM(...)
    self:Debug("ROLE_CHANGED_INFORM event received")
    ThrottledUpdate(self, "ROLE_CHANGE", 1)
end

function QueueMaster:LFG_LIST_SEARCH_RESULT_UPDATED(...)
    self:Debug("LFG_LIST_SEARCH_RESULT_UPDATED event received")
    -- Don't update for search results, only for actual queue changes
end

function QueueMaster:LFG_LIST_SEARCH_RESULTS_RECEIVED(...)
    self:Debug("LFG_LIST_SEARCH_RESULTS_RECEIVED event received")
    -- Don't update for search results, only for actual queue changes
end

-- Raid Finder (LFR) specific event handlers
function QueueMaster:LFG_LOCK_INFO_RECEIVED(...)
    self:Debug("LFG_LOCK_INFO_RECEIVED event received")
    ThrottledUpdate(self, "LFR_LOCK", 1)
end

-- PvP specific event handlers
function QueueMaster:PVP_ROLE_UPDATE(...)
    self:Debug("PVP_ROLE_UPDATE event received")
    ThrottledUpdate(self, "PVP_ROLE", 0.5)
end

function QueueMaster:BATTLEFIELDS_SHOW(...)
    self:Debug("BATTLEFIELDS_SHOW event received")
    ThrottledUpdate(self, "PVP_SHOW", 1)
end

function QueueMaster:BATTLEFIELDS_CLOSED(...)
    self:Debug("BATTLEFIELDS_CLOSED event received")
    ThrottledUpdate(self, "PVP_CLOSE", 1)
end

-- Arena event handlers
function QueueMaster:ARENA_TEAM_UPDATE(...)
    self:Debug("ARENA_TEAM_UPDATE event received")
    ThrottledUpdate(self, "ARENA_UPDATE", 0.5)
end

function QueueMaster:ARENA_SEASON_WORLD_STATE(...)
    self:Debug("ARENA_SEASON_WORLD_STATE event received")
    -- This doesn't affect queues directly, but good to know about
end

-- Generic queue update event
function QueueMaster:QUEUE_STATUS_UPDATE(...)
    self:Debug("QUEUE_STATUS_UPDATE event received")
    ThrottledUpdate(self, "GENERIC_QUEUE", 0.5)
end

-- Event handler initialization
function QueueMaster:InitializeEventHandlers()
    self:Debug("Initializing event handlers...")
    
    -- Clear any existing throttles
    for eventName, timer in pairs(eventThrottle) do
        if timer then
            self:CancelTimer(timer)
        end
    end
    eventThrottle = {}
    
    self:Debug("Event handlers initialized")
end

-- Cleanup function for event handlers
function QueueMaster:CleanupEventHandlers()
    self:Debug("Cleaning up event handlers...")
    
    -- Cancel all pending throttled updates
    for eventName, timer in pairs(eventThrottle) do
        if timer then
            self:CancelTimer(timer)
        end
    end
    eventThrottle = {}
    
    self:Debug("Event handlers cleaned up")
end