-- ======= Locales/Locales.lua =======
-- Localisation system for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Create localisation table
local L = {}
QueueMaster.L = L

-- Get current locale
local locale = GetLocale()

-- Default locale (enUS/enGB) - all strings must be defined here
local defaultStrings = {
    -- General
    ["QueueMaster"] = "QueueMaster",
    ["Enabled"] = "Enabled",
    ["Disabled"] = "Disabled",
    
    -- Queue states
    ["Joined Queue"] = "Joined Queue",
    ["Left Queue"] = "Left Queue",
    ["Queue Ready"] = "Queue Ready",
    ["In Queue"] = "In Queue",
    
    -- Queue types
    ["Dungeon Finder"] = "Dungeon Finder",
    ["Raid Finder"] = "Raid Finder",
    ["LFR"] = "LFR",
    ["Scenarios"] = "Scenarios",
    ["Flexible Raid"] = "Flexible Raid",
    ["PvP"] = "PvP",
    ["Battleground"] = "Battleground",
    ["Arena"] = "Arena",
    ["Unknown Queue"] = "Unknown Queue",
    
    -- Roles
    ["Tank"] = "Tank",
    ["Healer"] = "Healer",
    ["DPS"] = "DPS",
    ["Tanks"] = "Tanks",
    ["Healers"] = "Healers",
    
    -- Time
    ["Elapsed"] = "Elapsed",
    ["Wait"] = "Wait",
    ["Average Wait"] = "Average Wait",
    ["Estimated Wait"] = "Estimated Wait",
    
    -- Configuration sections
    ["GENERAL"] = "GENERAL",
    ["DISPLAY"] = "DISPLAY",
    ["APPEARANCE"] = "APPEARANCE",
    ["CONTROLS"] = "CONTROLS",
    ["Notifications"] = "Notifications",
    ["Advanced"] = "Advanced",
    
    -- Configuration options
    ["Show Alert Messages"] = "Show Alert Messages",
    ["Enable Sound Notifications"] = "Enable Sound Notifications",
    ["Enable Screen Flash"] = "Enable Screen Flash",
    ["Enable Debug Mode"] = "Enable Debug Mode",
    ["Bar Layout Mode"] = "Bar Layout Mode",
    ["Compact Mode"] = "Compact Mode",
    ["Lock Bar Positions"] = "Lock Bar Positions",
    ["Group Movement Mode"] = "Group Movement Mode",
    ["Use Movable Anchor"] = "Use Movable Anchor",
    ["Reset Bar Positions"] = "Reset Bar Positions",
    ["UI Scale"] = "UI Scale",
    ["Bar Height"] = "Bar Height",
    ["Bar Width"] = "Bar Width",
    ["Bar Spacing"] = "Bar Spacing",
    ["Frame Transparency"] = "Frame Transparency",
    ["Edge Opacity"] = "Edge Opacity",
    ["Font Style"] = "Font Style",
    ["Show Instance Name"] = "Show Instance Name",
    ["Show Timer"] = "Show Timer",
    ["Show Role Composition"] = "Show Role Composition",
    ["Color Theme"] = "Colour Theme",
    
    -- Layout modes
    ["Vertical"] = "Vertical",
    ["Horizontal"] = "Horizontal",
    ["Text-only"] = "Text-only",
    
    -- Colour themes
    ["Default"] = "Default",
    ["Class Colors"] = "Class Colours",
    ["Custom"] = "Custom",
    
    -- Descriptions
    ["Display popup alert messages for queue events"] = "Display popup alert messages for queue events like joining, leaving, and queue ready notifications",
    ["Play sound effects for queue events"] = "Play sound effects for queue events and alerts",
    ["Flash the screen for important events"] = "Flash the screen briefly for important queue events like queue ready notifications",
    ["Show debug messages in chat"] = "Show debug messages in chat (for troubleshooting only)",
    ["Choose how queue timer bars are arranged"] = "Choose how queue timer bars are arranged on your screen",
    ["Use smaller fonts for narrow bars"] = "Use smaller fonts and tighter spacing to fit all information on narrow bars. Shows all elements even on bars < 300px width.",
    ["Prevent bars from being moved"] = "Prevent timer bars from being moved by dragging. When unlocked, you'll see a movable anchor to position all bars.",
    ["Move all bars together or individually"] = "When enabled, moving one bar moves all bars together as a group. When disabled, each bar can be positioned individually.",
    ["Show movable anchor point"] = "Show a movable anchor point that controls the position of all timer bars",
    ["Reset all positions to default"] = "Reset all timer bar positions to their default top-left location",
    ["Scale all queue bars"] = "Scale all queue bars (larger or smaller). Default is 1.0 (100%)",
    ["Height of each queue bar"] = "Height of each queue timer bar in pixels",
    ["Width of each queue bar"] = "Width of each queue timer bar in pixels",
    ["Spacing between bars"] = "Spacing between multiple queue bars (vertical or horizontal depending on layout mode)",
    ["Adjust frame transparency"] = "Adjust the transparency of queue frames (higher = more opaque)",
    ["Adjust edge and background opacity"] = "Adjust the opacity of bar edges and backgrounds. Lower values create a text-only appearance.",
    ["Choose font style"] = "Choose the font style for all text in queue timer bars",
    ["Display dungeon/raid name"] = "Display the dungeon/raid name on the bar",
    ["Display elapsed queue time"] = "Display the elapsed queue time on the bar",
    ["Display role counts"] = "Display tank/healer/DPS role counts (T:1/1 H:1/1 D:3/3)",
    ["Choose colour scheme"] = "Choose a colour scheme for queue bars",
    
    -- Chat messages
    ["QueueMaster is now active!"] = "QueueMaster is now active!",
    ["Enhanced queue tracking with visual indicators"] = "Enhanced queue tracking with visual indicators",
    ["Smart role detection and wait time estimates"] = "Smart role detection and wait time estimates",
    ["Works automatically - no setup required!"] = "Works automatically - no setup required!",
    ["Right-click any queue bar to access settings"] = "Right-click any queue bar to access settings",
    ["Blizzard queue UI hidden."] = "Blizzard queue UI hidden.",
    ["QueueMaster is handling your queues."] = "QueueMaster is handling your queues.",
    ["Blizzard queue UI restored."] = "Blizzard queue UI restored.",
    ["Use /qmblizz again to hide it."] = "Use /qmblizz again to hide it.",
    ["No active queues detected."] = "No active queues detected.",
    ["Tip:"] = "Tip:",
    ["Open LFR/LFD and queue for something!"] = "Open LFR/LFD and queue for something!",
    ["Forcing queue detection..."] = "Forcing queue detection...",
    ["Total:"] = "Total:",
    ["queue(s)"] = "queue(s)",
    ["Blizzard UI:"] = "Blizzard UI:",
    ["Hidden"] = "Hidden",
    ["Visible"] = "Visible",
    ["Movement:"] = "Movement:",
    ["Locked"] = "Locked",
    ["Unlocked"] = "Unlocked",
    ["Group"] = "Group",
    ["Individual"] = "Individual",
    ["Update timer is running"] = "Update timer is running",
    ["Update timer is NOT running"] = "Update timer is NOT running",
    ["Use /qmblizz to toggle Blizzard UI"] = "Use /qmblizz to toggle Blizzard UI",
    ["Creating test queue..."] = "Creating test queue...",
    ["Test queue created:"] = "Test queue created:",
    ["CreateQueueBar method not found"] = "CreateQueueBar method not found",
    ["Group movement enabled."] = "Group movement enabled.",
    ["All bars will move together."] = "All bars will move together.",
    ["Individual movement enabled."] = "Individual movement enabled.",
    ["Each bar can be moved separately."] = "Each bar can be moved separately.",
    ["Debug mode enabled."] = "Debug mode enabled.",
    ["You will see technical messages in chat."] = "You will see technical messages in chat.",
    ["Debug mode disabled."] = "Debug mode disabled.",
    ["Timer bars are now locked in position."] = "Timer bars are now locked in position.",
    ["Timer bars can now be moved by dragging."] = "Timer bars can now be moved by dragging. Look for the red anchor box!",
    ["Look for the red anchor box!"] = "Look for the red anchor box!",
    ["Layout changed to"] = "Layout changed to",
    ["bars will stack vertically."] = "bars will stack vertically.",
    ["bars will arrange side by side."] = "bars will arrange side by side.",
    ["Compact mode enabled"] = "Compact mode enabled",
    ["all elements visible on narrow bars with smaller fonts."] = "all elements visible on narrow bars with smaller fonts.",
    ["Compact mode disabled"] = "Compact mode disabled",
    ["using width-based element hiding."] = "using width-based element hiding.",
    ["Movable anchor enabled."] = "Movable anchor enabled.",
    ["Drag the anchor to reposition all bars."] = "Drag the anchor to reposition all bars.",
    ["Movable anchor disabled."] = "Movable anchor disabled.",
    ["All timer bar positions have been reset to top-left."] = "All timer bar positions have been reset to top-left.",
    
    -- Alert messages
    ["Joined:"] = "Joined:",
    ["Left queue:"] = "Left queue:",
    ["Invite declined. You're still in queue."] = "Invite declined. You're still in queue.",
    
    -- Tooltip headers
    ["Queue Information"] = "Queue Information",
    ["Role Breakdown"] = "Role Breakdown",
    ["Click to configure"] = "Click to configure",
    ["Drag to move"] = "Drag to move",
}

-- Set up metatable for localisation fallback
setmetatable(L, {
    __index = function(t, k)
        -- If translation doesn't exist, return the key itself
        return defaultStrings[k] or k
    end
})

-- Populate default strings
for k, v in pairs(defaultStrings) do
    L[k] = v
end
