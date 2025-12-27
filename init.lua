-- Celestial UI Library v1.0.0
-- Premium, fluid, cross-platform UI library for Roblox

local Celestial = {}
Celestial.__index = Celestial
Celestial.Version = "1.0.0"

-- Configuration system
local Config = require(script.core.config)
local AnimationEngine = require(script.core.animationengine)
local Themes = require(script.core.themes)
local WindowSystem = require(script.core.window)
local ToggleIsland = require(script.systems.toggleisland)

-- Module registry
local Modules = {
    Core = {},
    Components = {},
    Systems = {},
    Loaded = false
}

-- Public API
function Celestial.new(config)
    local self = setmetatable({}, Celestial)
    
    -- Validate and apply config
    self.Config = Config:Validate(config or {})
    self.Theme = Themes.new(self.Config.Theme, self.Config.AccentColor)
    self.Animations = AnimationEngine.new(self.Config.Animation)
    
    -- Initialize systems
    self.Windows = {}
    self.ActiveWindow = nil
    self.Island = nil
    
    -- Load modules based on config
    self:_loadModules()
    
    return self
end

function Celestial:CreateWindow(config)
    local windowConfig = Config:Merge(self.Config, config or {})
    local window = WindowSystem.new(windowConfig, self.Theme, self.Animations)
    
    -- Register window
    table.insert(self.Windows, window)
    self.ActiveWindow = window
    
    -- Initialize toggle island if enabled
    if self.Config.ToggleIsland.Enabled then
        self.Island = ToggleIsland.new({
            Window = window,
            Config = self.Config.ToggleIsland
        })
    end
    
    return window
end

function Celestial:_loadModules()
    if Modules.Loaded then return end
    
    -- Load core modules
    Modules.Core.Database = require(script.core.database)
    Modules.Core.Responsive = require(script.core.responsive)
    
    -- Load components
    for _, moduleName in ipairs({
        "button", "checkbox", "toggle", "slider", 
        "dropdown", "input", "label", "tooltip",
        "tabs", "codeblock", "tags", "search",
        "icons", "colorpicker"
    }) do
        Modules.Components[moduleName] = require(script.components[moduleName])
    end
    
    -- Load systems based on config
    if self.Config.Search.Enabled then
        Modules.Systems.Search = require(script.systems.searchsystem)
    end
    
    if self.Config.KeySystem.Enabled then
        Modules.Systems.KeySystem = require(script.systems.keysystem)
    end
    
    Modules.Loaded = true
end

-- Utility functions
function Celestial:SetTheme(themeName, accentColor)
    self.Theme:Set(themeName, accentColor)
end

function Celestial:SetAnimationStyle(style, speed)
    self.Animations:SetStyle(style, speed)
end

function Celestial:EnableDebug(enabled)
    self.Config.Debug.Enabled = enabled
end

-- Module access
function Celestial:GetModule(category, name)
    return Modules[category] and Modules[category][name]
end

-- Register custom config
function Celestial:RegisterConfig(section, defaults)
    return Config:RegisterSection(section, defaults)
end

-- Global instance
local GlobalInstance = Celestial.new()
return GlobalInstance
