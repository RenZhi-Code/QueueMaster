local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Ensure QueueMaster exists
if not QueueMaster then
    error("QueueMaster addon not found - ensure QueueMaster.lua loads first")
end

-- AceConfig integration
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Main configuration setup and coordination
-- This file coordinates all the modular configuration sections

-- Build the complete options table from all modules
local function BuildOptionsTable()
    local options = {
        name = "|cffff0000Queue|r|cff0080ffMaster|r",
        handler = QueueMaster,
        type = "group",
        childGroups = "tab",
        desc = "|cff888888Professional queue management with enhanced visuals and smart detection|r",
        args = {
            header = {
                name = "|cffff0000Queue|r|cff0080ffMaster|r - Enhanced LFG Queue Timer",
                type = "description",
                fontSize = "large",
                order = 0
            },
            spacer1 = {
                name = "",
                type = "description",
                order = 0.1
            },
            version = {
                name = "|cFFFFD700Version:|r |cff00ff00v18.10.25.10",
                type = "description",
                order = 0.2
            },
            description = {
                name = "QueueMaster enhanced timer bar visuals, smart role detection, and comprehensive customization.\n\n|cff888888Configure each aspect below to tailor your queue management experience.|r",
                type = "description",
                fontSize = "medium",
                order = 0.25
            },
            spacer2 = {
                name = "",
                type = "description",
                order = 0.3
            },
            spacer2_5 = {
                name = "",
                type = "description",
                order = 0.4
            }
        }
    }
    
    -- Add all modular configuration sections
    if QueueMaster.GeneralSettings then
        options.args.general = QueueMaster.GeneralSettings:GetOptions()
    end
    
    if QueueMaster.DisplaySettings then
        options.args.display = QueueMaster.DisplaySettings:GetOptions()
    end
    
    if QueueMaster.AppearanceSettings then
        options.args.appearance = QueueMaster.AppearanceSettings:GetOptions()
    end
    
    if QueueMaster.TooltipsAndCommands then
        options.args.tooltips = QueueMaster.TooltipsAndCommands:GetTooltipsOptions()
        options.args.commands = QueueMaster.TooltipsAndCommands:GetCommandsOptions()
    end
    
    return options
end

-- Initialize Professional AceConfig
function QueueMaster:SetupConfig()
    -- Build the complete options table
    local options = BuildOptionsTable()
    
    -- Register main options table
    AceConfig:RegisterOptionsTable("QueueMaster", options)
    
    -- Add to Blizzard Interface Options with custom icon
    self.configDialog = AceConfigDialog:AddToBlizOptions("QueueMaster", "QueueMaster")
    
    -- Register profiles if AceDBOptions is available
    local AceDBOptions = LibStub("AceDBOptions-3.0", true)
    if AceDBOptions then
        local profileOptions = AceDBOptions:GetOptionsTable(self.db)
        -- Add professional styling to profile options
        profileOptions.name = "|cff888888PROFILES|r"
        AceConfig:RegisterOptionsTable("QueueMaster_Profiles", profileOptions)
        AceConfigDialog:AddToBlizOptions("QueueMaster_Profiles", "Profiles", "QueueMaster")
    end
    
    -- Register standalone chat commands for config
    self:RegisterChatCommand("qmconfig", function()
        self:ShowConfig()
    end)
    
    self:Debug("Professional configuration system initialized")
end

-- Delegate functions to ConfigHelpers for backward compatibility
function QueueMaster:ShowConfig()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    -- Always open the standalone AceConfig dialog for better experience
    AceConfigDialog:Open("QueueMaster")
end

function QueueMaster:HideConfig()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    -- Close any open config dialogs
    AceConfigDialog:Close("QueueMaster")
end

function QueueMaster:ApplySettings()
    if self.ConfigHelpers then
        self.ConfigHelpers:ApplySettings()
    end
end

function QueueMaster:ValidateSettings()
    if self.ConfigHelpers then
        return self.ConfigHelpers:ValidateSettings()
    end
    return true
end

function QueueMaster:ApplySettingsEnhanced()
    if self.ConfigHelpers then
        self.ConfigHelpers:ApplySettingsEnhanced()
    end
end

-- RefreshAllBars function needed by display settings
function QueueMaster:RefreshAllBars()
    for queueID, bar in pairs(self.queueBars or {}) do
        if bar and bar.roleText then
            if self.settings.showRoleBars then
                bar.roleText:Show()
            else
                bar.roleText:Hide()
            end
        end
    end
end