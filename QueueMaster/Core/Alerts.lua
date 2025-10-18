-- ======= Core/Alerts.lua (Updated for Ace3) =======
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- Alert system with multiple notification types
function QueueMaster:ShowAlert(message, alertType, duration)
    if not self.settings or not self.settings.showAlerts then return end
    
    alertType = alertType or "info"
    duration = duration or 5
    
    -- Create alert frame if it doesn't exist
    if not self.alertFrame then
        self:CreateAlertFrame()
    end
    
    -- Set alert styling based on type
    self:StyleAlert(alertType)
    
    -- Show alert
    self.alertFrame.text:SetText(message)
    if self.alertFrame.textShadow then
        self.alertFrame.textShadow:SetText(message)
    end
    self.alertFrame:Show()
    
    -- Animate entrance
    self:AnimateAlertIn()
    
    -- Auto-hide after duration
    if self.alertTimer then
        self:CancelTimer(self.alertTimer)
    end
    
    self.alertTimer = self:ScheduleTimer("HideAlert", duration)
    
    -- Play sound based on alert type
    self:PlayAlertSound(alertType)
    
    -- Flash screen if enabled
    if self.settings.flashEnabled then
        self:FlashScreen(alertType)
    end
end

function QueueMaster:CreateAlertFrame()
    self.alertFrame = CreateFrame("Frame", "QueueMasterAlert", UIParent, "BackdropTemplate")
    self.alertFrame:SetSize(380, 90)
    self.alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    self.alertFrame:SetFrameStrata("HIGH")
    self.alertFrame:SetFrameLevel(200)
    
    -- Modern backdrop with enhanced styling
    self.alertFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    self.alertFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.95)
    self.alertFrame:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
    
    -- Add shadow effect
    self.alertFrame.shadow = CreateFrame("Frame", nil, self.alertFrame, "BackdropTemplate")
    self.alertFrame.shadow:SetPoint("TOPLEFT", self.alertFrame, "TOPLEFT", -4, 4)
    self.alertFrame.shadow:SetPoint("BOTTOMRIGHT", self.alertFrame, "BOTTOMRIGHT", 4, -4)
    self.alertFrame.shadow:SetFrameLevel(self.alertFrame:GetFrameLevel() - 1)
    self.alertFrame.shadow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    self.alertFrame.shadow:SetBackdropColor(0, 0, 0, 0.7)
    self.alertFrame.shadow:SetBackdropBorderColor(0, 0, 0, 0.9)
    
    -- Add glow effect
    self.alertFrame.glow = CreateFrame("Frame", nil, self.alertFrame, "BackdropTemplate")
    self.alertFrame.glow:SetPoint("TOPLEFT", self.alertFrame, "TOPLEFT", -2, 2)
    self.alertFrame.glow:SetPoint("BOTTOMRIGHT", self.alertFrame, "BOTTOMRIGHT", 2, -2)
    self.alertFrame.glow:SetFrameLevel(self.alertFrame:GetFrameLevel() - 1)
    self.alertFrame.glow:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8
    })
    self.alertFrame.glow:SetBackdropBorderColor(1, 0.8, 0.4, 0.5)
    
    -- Enhanced title with modern styling
    self.alertFrame.title = self.alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.alertFrame.title:SetPoint("TOP", self.alertFrame, "TOP", 0, -12)
    self.alertFrame.title:SetText("|cffff0000Queue|r|cff0080ffMaster|r")
    self.alertFrame.title:SetTextColor(1, 0.9, 0.6, 1)
    self.alertFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Title shadow
    self.alertFrame.titleShadow = self.alertFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge")
    self.alertFrame.titleShadow:SetPoint("TOP", self.alertFrame, "TOP", 1, -13)
    self.alertFrame.titleShadow:SetText("|cffff0000Queue|r|cff0080ffMaster|r")
    self.alertFrame.titleShadow:SetTextColor(0, 0, 0, 0.9)
    self.alertFrame.titleShadow:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Enhanced main text
    self.alertFrame.text = self.alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.alertFrame.text:SetPoint("CENTER", self.alertFrame, "CENTER", 0, -8)
    self.alertFrame.text:SetWidth(350)
    self.alertFrame.text:SetJustifyH("CENTER")
    self.alertFrame.text:SetTextColor(1, 1, 1, 1)
    self.alertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    
    -- Text shadow
    self.alertFrame.textShadow = self.alertFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
    self.alertFrame.textShadow:SetPoint("CENTER", self.alertFrame, "CENTER", 1, -9)
    self.alertFrame.textShadow:SetWidth(350)
    self.alertFrame.textShadow:SetJustifyH("CENTER")
    self.alertFrame.textShadow:SetTextColor(0, 0, 0, 0.8)
    self.alertFrame.textShadow:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    
    -- Close button
    self.alertFrame.closeButton = CreateFrame("Button", nil, self.alertFrame, "UIPanelCloseButton")
    self.alertFrame.closeButton:SetPoint("TOPRIGHT", self.alertFrame, "TOPRIGHT", -5, -5)
    self.alertFrame.closeButton:SetScript("OnClick", function()
        QueueMaster:HideAlert()
    end)
    
    -- Make clickable to dismiss
    self.alertFrame:EnableMouse(true)
    self.alertFrame:SetScript("OnMouseDown", function()
        QueueMaster:HideAlert()
    end)
    
    self.alertFrame:Hide()
end

function QueueMaster:StyleAlert(alertType)
    if not self.alertFrame then return end
    
    local colors = {
        info = {bg = {0.2, 0.2, 0.8, 0.9}, border = {0.4, 0.4, 1, 1}, text = {1, 1, 1}},
        success = {bg = {0.2, 0.8, 0.2, 0.9}, border = {0.4, 1, 0.4, 1}, text = {1, 1, 1}},
        warning = {bg = {0.8, 0.6, 0.2, 0.9}, border = {1, 0.8, 0.4, 1}, text = {1, 1, 1}},
        error = {bg = {0.8, 0.2, 0.2, 0.9}, border = {1, 0.4, 0.4, 1}, text = {1, 1, 1}},
        queue = {bg = {0.6, 0.2, 0.8, 0.9}, border = {0.8, 0.4, 1, 1}, text = {1, 1, 1}}
    }
    
    local color = colors[alertType] or colors.info
    
    self.alertFrame:SetBackdropColor(unpack(color.bg))
    self.alertFrame:SetBackdropBorderColor(unpack(color.border))
    self.alertFrame.text:SetTextColor(unpack(color.text))
end

function QueueMaster:AnimateAlertIn()
    if not self.alertFrame then return end

    -- Start from above screen
    self.alertFrame:ClearAllPoints()
    self.alertFrame:SetPoint("TOP", UIParent, "TOP", 0, 50)
    self.alertFrame:SetAlpha(0)

    -- PERFORMANCE FIX: Reuse animation group instead of creating new ones
    if not self.alertFrame.animGroupIn then
        self.alertFrame.animGroupIn = self.alertFrame:CreateAnimationGroup()

        local translate = self.alertFrame.animGroupIn:CreateAnimation("Translation")
        translate:SetOffset(0, -150)
        translate:SetDuration(0.3)
        translate:SetSmoothing("OUT")

        local fade = self.alertFrame.animGroupIn:CreateAnimation("Alpha")
        fade:SetFromAlpha(0)
        fade:SetToAlpha(1)
        fade:SetDuration(0.3)
    end

    -- Stop any running animation and restart
    self.alertFrame.animGroupIn:Stop()
    self.alertFrame.animGroupIn:Play()
end

function QueueMaster:HideAlert()
    if not self.alertFrame then return end

    if self.alertTimer then
        self:CancelTimer(self.alertTimer)
        self.alertTimer = nil
    end

    -- PERFORMANCE FIX: Reuse animation group instead of creating new ones
    if not self.alertFrame.animGroupOut then
        self.alertFrame.animGroupOut = self.alertFrame:CreateAnimationGroup()

        local fade = self.alertFrame.animGroupOut:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(0.2)

        self.alertFrame.animGroupOut:SetScript("OnFinished", function()
            self.alertFrame:Hide()
        end)
    end

    -- Stop any running animation and restart
    self.alertFrame.animGroupOut:Stop()
    self.alertFrame.animGroupOut:Play()
end

function QueueMaster:PlayAlertSound(alertType)
    if not self.settings.soundEnabled then return end
    
    local sounds = {
        info = SOUNDKIT.UI_DUNGEON_FINDER_QUEUE_READY,
        success = SOUNDKIT.READY_CHECK,
        warning = SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING,
        error = SOUNDKIT.UI_RAID_BOSS_EMOTE_WARNING,
        queue = SOUNDKIT.UI_DUNGEON_FINDER_QUEUE_READY
    }
    
    local soundID = sounds[alertType] or sounds.info
    PlaySound(soundID)
end

function QueueMaster:FlashScreen(alertType)
    if not self.flashFrame then
        self.flashFrame = CreateFrame("Frame", nil, UIParent)
        self.flashFrame:SetAllPoints(UIParent)
        self.flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")

        self.flashFrame.texture = self.flashFrame:CreateTexture(nil, "BACKGROUND")
        self.flashFrame.texture:SetAllPoints(self.flashFrame)
        self.flashFrame.texture:SetColorTexture(1, 1, 1, 0)

        self.flashFrame:Hide()

        -- PERFORMANCE FIX: Create animation group once
        self.flashFrame.animGroup = self.flashFrame:CreateAnimationGroup()

        local fadeIn = self.flashFrame.animGroup:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(0.3)
        fadeIn:SetDuration(0.1)
        fadeIn:SetOrder(1)

        local fadeOut = self.flashFrame.animGroup:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.3)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.4)
        fadeOut:SetStartDelay(0.1)
        fadeOut:SetOrder(2)

        self.flashFrame.animGroup:SetScript("OnFinished", function()
            self.flashFrame:Hide()
        end)
    end

    -- Set flash color based on alert type
    local colors = {
        info = {0.2, 0.2, 1},
        success = {0.2, 1, 0.2},
        warning = {1, 0.8, 0.2},
        error = {1, 0.2, 0.2},
        queue = {0.8, 0.2, 1}
    }

    local color = colors[alertType] or colors.info
    self.flashFrame.texture:SetColorTexture(color[1], color[2], color[3], 0.3)

    -- Flash animation - reuse existing animation group
    self.flashFrame:Show()
    self.flashFrame.animGroup:Stop()
    self.flashFrame.animGroup:Play()
end

-- Specific alert functions
function QueueMaster:ShowQueueReadyAlert(queueName)
    local message = string.format("Queue Ready!\n%s", queueName or "Unknown Queue")
    self:ShowAlert(message, "queue", 10)
end

function QueueMaster:ShowQueueJoinedAlert(queueName, queueType)
    local message = string.format("Joined Queue\n%s (%s)", queueName or "Unknown", queueType or "Queue")
    self:ShowAlert(message, "success", 3)
end

function QueueMaster:ShowQueueLeftAlert(queueName)
    local message = string.format("Left Queue\n%s", queueName or "Unknown Queue")
    self:ShowAlert(message, "warning", 3)
end

function QueueMaster:ShowErrorAlert(errorMessage)
    self:ShowAlert("Error: " .. (errorMessage or "Unknown error"), "error", 5)
end

function QueueMaster:QueuePopped(queueID)
    local q = self.queues[queueID]
    if not q then return end

    self:ShowQueueReadyAlert(q.name)
end
