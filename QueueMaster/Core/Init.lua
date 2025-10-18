-- ======= Core/Init.lua (Updated for Ace3) =======
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists (should be created in main file)
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- This file provides compatibility functions for the Ace3 conversion

-- Compatibility function for legacy Initialize calls
function QueueMaster:Initialize()
    -- This is now handled by Ace3's OnInitialize and OnEnable
    if not self.db then
        self:Debug("Initialize called before Ace3 initialization, deferring...")
        return
    end
    
    self:Debug("Legacy Initialize called - already handled by Ace3")
end

function QueueMaster:CreateMainFrame()
    if self.mainFrame then 
        return 
    end
    
    -- Create movable anchor frame for queue bars
    self:CreateQueueAnchor()
    
    self.mainFrame = CreateFrame("Frame", "QueueMasterMainFrame", UIParent, "BackdropTemplate")
    self.mainFrame:SetSize(320, 50)
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetFrameStrata("MEDIUM")
    self.mainFrame:SetFrameLevel(100)
    
    -- Modern backdrop with rounded corners effect
    self.mainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    
    -- Dark gradient background with transparency
    self.mainFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    self.mainFrame:SetBackdropBorderColor(0.3, 0.5, 0.8, 0.9)
    
    -- Add shadow effect
    self.mainFrame.shadow = CreateFrame("Frame", nil, self.mainFrame, "BackdropTemplate")
    self.mainFrame.shadow:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", -4, 4)
    self.mainFrame.shadow:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", 4, -4)
    self.mainFrame.shadow:SetFrameLevel(self.mainFrame:GetFrameLevel() - 1)
    self.mainFrame.shadow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    self.mainFrame.shadow:SetBackdropColor(0, 0, 0, 0.6)
    self.mainFrame.shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
    
    -- Subtle glow effect
    self.mainFrame.glow = CreateFrame("Frame", nil, self.mainFrame, "BackdropTemplate")
    self.mainFrame.glow:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", -2, 2)
    self.mainFrame.glow:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", 2, -2)
    self.mainFrame.glow:SetFrameLevel(self.mainFrame:GetFrameLevel() - 1)
    self.mainFrame.glow:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8
    })
    self.mainFrame.glow:SetBackdropBorderColor(0.4, 0.6, 1, 0.3)
    
    -- Make draggable (will be controlled by settings)
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function(frame)
        if not (QueueMaster.settings and QueueMaster.settings.lockFrame) then
            frame:StartMoving()
        end
    end)
    self.mainFrame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        QueueMaster:SaveFramePosition()
    end)
    
    -- Enhanced title with modern styling
    self.mainFrame.title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.mainFrame.title:SetPoint("TOP", self.mainFrame, "TOP", 0, -12)
    self.mainFrame.title:SetText("|cffff0000Queue|r|cff0080ffMaster|r")
    self.mainFrame.title:SetTextColor(0.9, 0.9, 1, 1)
    self.mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Add title shadow for depth
    self.mainFrame.titleShadow = self.mainFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
    self.mainFrame.titleShadow:SetPoint("TOP", self.mainFrame, "TOP", 1, -13)
    self.mainFrame.titleShadow:SetText("|cffff0000Queue|r|cff0080ffMaster|r")
    self.mainFrame.titleShadow:SetTextColor(0, 0, 0, 0.8)
    self.mainFrame.titleShadow:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Scroll frame for multiple queues
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.mainFrame)
    self.scrollFrame:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 10, -32)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -10, 10)
    
    self.contentFrame = CreateFrame("Frame", nil, self.scrollFrame)
    self.contentFrame:SetSize(300, 120)
    self.scrollFrame:SetScrollChild(self.contentFrame)
    
    self.mainFrame:Hide()
end

function QueueMaster:ShowMainFrame()
    -- Main frame disabled - using independent queue bars instead
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function QueueMaster:HideMainFrame()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

-- Create a test queue for demonstration purposes
function QueueMaster:CreateTestQueue()
    local testQueueID = "TEST_QUEUE_001"
    
    -- Ensure main frame exists first
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    -- Initialize queues table if it doesn't exist
    if not self.queues then
        self.queues = {}
    end
    
    -- Initialize queueBars table if it doesn't exist
    if not self.queueBars then
        self.queueBars = {}
    end
    
    -- Create test queue data in the correct structure
    self.queues[testQueueID] = {
        id = testQueueID,
        queueType = "Dungeon",
        type = "Dungeon Finder",
        instanceName = "Test Dungeon",
        name = "Test Dungeon",
        categoryName = "Dungeon Finder",
        queueCategory = "Dungeon",
        startTime = GetTime(),
        estimatedWait = 300, -- 5 minutes
        averageWait = 5, -- 5 minutes in minutes
        totalTanks = 1,
        totalHealers = 1,
        totalDPS = 3,
        tankNeeds = 0,
        healerNeeds = 0,
        dpsNeeds = 1,
        position = 15,
        independent = true
    }
    
    
    -- Create the queue bar
    self:CreateQueueBar(testQueueID)
    
    -- Show the main frame
    self:ShowMainFrame()
    
    -- Update the queue bar immediately
    self:UpdateQueueBar(testQueueID)
end

-- Simulate different queue types for testing
function QueueMaster:SimulateQueue(queueType)
    queueType = queueType or "dungeon"
    
    local queueConfigs = {
        dungeon = {
            id = "SIM_DUNGEON_" .. GetTime(),
            type = "Dungeon Finder",
            instanceName = "Mythic Keystone",
            categoryName = "Dungeon Finder",
            queueCategory = "Dungeon",
            totalTanks = 1, totalHealers = 1, totalDPS = 3,
            tankNeeds = 0, healerNeeds = 0, dpsNeeds = 1,
            averageWait = 8
        },
        raid = {
            id = "SIM_RAID_" .. GetTime(),
            type = "Raid Finder", 
            instanceName = "Nerub-ar Palace",
            categoryName = "Raid Finder",
            queueCategory = "LFR",
            totalTanks = 2, totalHealers = 5, totalDPS = 13,
            tankNeeds = 1, healerNeeds = 2, dpsNeeds = 5,
            averageWait = 15
        },
        pvp = {
            id = "SIM_PVP_" .. GetTime(),
            type = "PvP",
            instanceName = "Random Battleground", 
            categoryName = "PvP",
            queueCategory = "PvP",
            totalTanks = 0, totalHealers = 0, totalDPS = 10,
            tankNeeds = 0, healerNeeds = 0, dpsNeeds = 3,
            averageWait = 3
        }
    }
    
    local config = queueConfigs[queueType] or queueConfigs.dungeon
    
    -- Ensure main frame exists
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    -- Initialize tables
    if not self.queues then self.queues = {} end
    if not self.queueBars then self.queueBars = {} end
    
    -- Create simulated queue
    self.queues[config.id] = {
        id = config.id,
        queueType = config.type,
        type = config.type,
        instanceName = config.instanceName,
        name = config.instanceName,
        categoryName = config.categoryName,
        queueCategory = config.queueCategory,
        startTime = GetTime(),
        averageWait = config.averageWait,
        totalTanks = config.totalTanks,
        totalHealers = config.totalHealers,
        totalDPS = config.totalDPS,
        tankNeeds = config.tankNeeds,
        healerNeeds = config.healerNeeds,
        dpsNeeds = config.dpsNeeds,
        independent = true,
        simulated = true
    }
    
    -- Create and show the queue bar
    self:CreateQueueBar(config.id)
    self:ShowMainFrame()
    self:UpdateQueueBar(config.id)
    

end

-- Create a simple debug test bar to verify visibility
function QueueMaster:CreateDebugTestBar()
    -- Check if main frame exists
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    -- Create a simple test bar attached directly to UIParent
    local testBar = CreateFrame("StatusBar", "QueueMasterDebugBar", UIParent)
    testBar:SetSize(300, 50)
    testBar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    testBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    testBar:SetStatusBarColor(1, 0, 0, 1) -- Bright red
    testBar:SetMinMaxValues(0, 1)
    testBar:SetValue(0.7)
    testBar:SetFrameStrata("DIALOG") -- Very high strata
    testBar:SetFrameLevel(999) -- Very high level
    testBar:SetAlpha(1.0) -- Full opacity
    
    -- Bright background
    testBar.bg = testBar:CreateTexture(nil, "BACKGROUND")
    testBar.bg:SetAllPoints(testBar)
    testBar.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    testBar.bg:SetVertexColor(0, 1, 0, 1) -- Bright green background
    
    -- Large obvious text
    testBar.text = testBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    testBar.text:SetPoint("CENTER", testBar, "CENTER", 0, 0)
    testBar.text:SetText("DEBUG TEST BAR")
    testBar.text:SetTextColor(1, 1, 1, 1)
    testBar.text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    
    -- Border for visibility
    testBar.border = CreateFrame("Frame", nil, testBar, "BackdropTemplate")
    testBar.border:SetAllPoints(testBar)
    testBar.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16
    })
    testBar.border:SetBackdropBorderColor(1, 1, 1, 1)
    
    testBar:Show()
    self.mainFrame:Show()
    
    -- Store reference for cleanup
    self.debugTestBar = testBar
end

-- Create a simple queue bar using the exact same method as the working debug bar
function QueueMaster:CreateSimpleQueueBar()
    -- Use the exact same creation method as the working debug test bar
    local queueBar = CreateFrame("StatusBar", "QueueMasterSimpleBar", UIParent)
    queueBar:SetSize(300, 50)
    queueBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100) -- Slightly below center
    queueBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    queueBar:SetStatusBarColor(0.8, 0.2, 0.2, 1) -- Red for LFR
    queueBar:SetMinMaxValues(0, 1)
    queueBar:SetValue(0.3)
    queueBar:SetFrameStrata("DIALOG")
    queueBar:SetFrameLevel(999)
    queueBar:SetAlpha(1.0)
    
    -- Background
    queueBar.bg = queueBar:CreateTexture(nil, "BACKGROUND")
    queueBar.bg:SetAllPoints(queueBar)
    queueBar.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    queueBar.bg:SetVertexColor(0.2, 0.2, 0.2, 1)
    
    -- Queue text - simulate real queue data
    queueBar.text = queueBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    queueBar.text:SetPoint("LEFT", queueBar, "LEFT", 10, 0)
    queueBar.text:SetText("The Chrome King - 01:45")
    queueBar.text:SetTextColor(1, 1, 1, 1)
    queueBar.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Role text
    queueBar.roleText = queueBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    queueBar.roleText:SetPoint("RIGHT", queueBar, "RIGHT", -10, 0)
    queueBar.roleText:SetText("T:1/2 H:3/5 D:8/17")
    queueBar.roleText:SetTextColor(1, 0.8, 0.2, 1)
    queueBar.roleText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    
    -- Border
    queueBar.border = CreateFrame("Frame", nil, queueBar, "BackdropTemplate")
    queueBar.border:SetAllPoints(queueBar)
    queueBar.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16
    })
    queueBar.border:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    
    queueBar:Show()
    
    -- Store reference
    self.simpleQueueBar = queueBar
end

-- Load saved positions for main frame
function QueueMaster:LoadFramePosition()
    if self.savedPositions and self.savedPositions.mainFrame and self.mainFrame then
        local pos = self.savedPositions.mainFrame
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
    end
end

-- Save current frame position
function QueueMaster:SaveFramePosition()
    if not self.mainFrame then return end
    
    local point, relativeTo, relativePoint, x, y = self.mainFrame:GetPoint()
    if not self.savedPositions then
        self.savedPositions = {}
        QueueMasterDB.positions = self.savedPositions
    end
    
    self.savedPositions.mainFrame = {
        point = point or "CENTER",
        relativePoint = relativePoint or "CENTER",
        x = x or 0,
        y = y or 0
    }
end

-- Save queues and settings
function QueueMaster:SaveData()
    if QueueMasterDB then
        QueueMasterDB.queues = self.queues or {}
        QueueMasterDB.settings = self.settings or {}
        QueueMasterDB.positions = self.savedPositions or {}
        QueueMasterDB.waitTimes = self.waitTimes or {}
    end
end

-- Hook logout to save data
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if QueueMaster.SaveData then
        QueueMaster:SaveData()
    end
end)

-- Create movable anchor frame for queue bars
function QueueMaster:CreateQueueAnchor()
    if self.queueAnchor then return end
    
    local anchor = CreateFrame("Frame", "QueueMasterAnchor", UIParent, "BackdropTemplate")
    anchor:SetSize(8, 8)  -- Very small box - just a few pixels as requested
    
    -- Load saved position or use default (TOPLEFT offset as per memory specs)
    if self.db and self.db.char and self.db.char.anchorPosition then
        local pos = self.db.char.anchorPosition
        anchor:SetPoint(pos.anchor or "TOPLEFT", UIParent, pos.relativeAnchor or "TOPLEFT", pos.x or 100, pos.y or -100)
    else
        -- Default to TOPLEFT with offset (100, -100) as per memory specifications
        anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -100)
    end
    
    -- Visual styling - small visible box
    anchor:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    anchor:SetBackdropColor(0.8, 0.1, 0.1, 0.9)  -- Bright red background
    anchor:SetBackdropBorderColor(1, 0.3, 0.3, 1.0)  -- Red border
    
    -- Small text that only shows on mouseover
    anchor.title = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    anchor.title:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    anchor.title:SetText("|cffffffff⚓|r")
    anchor.title:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    
    -- Make it movable
    anchor:SetMovable(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    
    -- Drag start - begin smooth movement
    anchor:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
        frame.isDragging = true
        
        -- Enable smooth updates during drag
        frame:SetScript("OnUpdate", function(self, elapsed)
            if self.isDragging then
                -- Continuously update bar positions while dragging
                QueueMaster:UpdateQueueBarLayout()
            end
        end)
    end)
    
    -- Drag stop - save position and stop smooth updates
    anchor:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        frame.isDragging = false
        
        -- Disable OnUpdate to save performance when not dragging
        frame:SetScript("OnUpdate", nil)
        
        -- Save the anchor position
        QueueMaster:SaveAnchorPosition()
        
        -- Final layout update
        QueueMaster:UpdateQueueBarLayout()
        
        -- CRITICAL: Save all bar positions after anchor movement
        if QueueMaster.queueBars and QueueMaster.db and QueueMaster.db.char then
            if not QueueMaster.db.char.positions then
                QueueMaster.db.char.positions = {}
            end
            
            for queueID, bar in pairs(QueueMaster.queueBars) do
                if bar and bar:IsVisible() then
                    local anchor, _, relativeAnchor, x, y = bar:GetPoint()
                    QueueMaster.db.char.positions[queueID] = {
                        anchor = anchor,
                        relativeAnchor = relativeAnchor,
                        x = x,
                        y = y
                    }
                    QueueMaster:Debug("Saved bar position after anchor drag: " .. queueID)
                end
            end
        end
    end)
    
    -- Show/hide with queues
    anchor:SetFrameStrata("HIGH")
    anchor:SetFrameLevel(200)
    -- DON'T hide here - let UpdateQueueBarLayout() control visibility based on settings!
    -- This prevents race conditions and ensures proper visibility after queue join
    
    self.queueAnchor = anchor
    self:Debug("Queue anchor created - visibility will be controlled by UpdateQueueBarLayout")
end

-- Save anchor position
function QueueMaster:SaveAnchorPosition()
    if not self.queueAnchor or not self.db or not self.db.char then return end
    
    local point, relativeTo, relativePoint, x, y = self.queueAnchor:GetPoint()
    if not self.db.char.anchorPosition then
        self.db.char.anchorPosition = {}
    end
    
    self.db.char.anchorPosition = {
        anchor = point or "TOPLEFT",
        relativeAnchor = relativePoint or "TOPLEFT",
        x = x or 100,
        y = y or -100
    }
    
    self:Debug("Anchor position saved: " .. tostring(x) .. ", " .. tostring(y))
end

-- Toggle anchor visibility
function QueueMaster:ToggleAnchor()
    if not self.queueAnchor then
        self:CreateQueueAnchor()
    end
    
    if self.queueAnchor:IsShown() then
        self.queueAnchor:Hide()
        self:Print("Anchor hidden")
    else
        self.queueAnchor:Show()
        self:Print("Anchor shown - drag it to reposition all queue bars")
    end
end

-- Show the movable anchor (called from config)
function QueueMaster:ShowGroupAnchor()
    if not self.queueAnchor then
        self:CreateQueueAnchor()
    end
    -- Only show anchor if bars are unlocked
    if not (self.settings and self.settings.lockFrame) then
        self.queueAnchor:Show()
        self:Debug("Group anchor shown (bars unlocked)")
    else
        self:Debug("Group anchor not shown - bars are locked")
    end
end

-- Hide the movable anchor (called from config)
function QueueMaster:HideGroupAnchor()
    if self.queueAnchor then
        self.queueAnchor:Hide()
    end
end
