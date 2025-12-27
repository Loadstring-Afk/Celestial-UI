-- Configuration management system

local Config = {}
Config.__index = Config

-- Default configuration
local Defaults = {
    Name = "Celestial UI",
    Subtitle = "Premium Interface",
    Icon = "lucide:sparkles",
    
    Theme = "Dark",
    AccentColor = Color3.fromRGB(80, 140, 255),
    Font = "Gotham",
    Transparency = 0.1,
    
    Animation = {
        Style = "Fluid",
        Speed = 1,
        Intensity = 0.8,
        Blur = false,
        MobileReduced = true
    },
    
    Loader = {
        Enabled = false,
        Title = "Loading Celestial UI",
        Subtitle = "Initializing modules...",
        Logo = "",
        ProgressStyle = "Smooth",
        ShowSteps = true,
        Steps = {"Core", "Components", "Systems", "UI"}
    },
    
    ToggleIsland = {
        Enabled = true,
        Position = "Top",
        Size = UDim2.new(0.2, 0, 0.06, 0),
        ExpandOnHover = true,
        ShowNotifications = true,
        Icon = "lucide:menu",
        BackgroundColor = Color3.fromRGB(30, 30, 35),
        TextColor = Color3.fromRGB(240, 240, 245),
        AnimationStyle = "Spring"
    },
    
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "CelestialUI",
        FileName = "Config",
        Versioning = true,
        AutoSave = true
    },
    
    Database = {
        Enabled = false,
        AutoSave = true,
        SaveInterval = 30,
        WipeOnVersionMismatch = true,
        Encryption = false
    },
    
    Search = {
        Enabled = false,
        SearchTabs = true,
        SearchComponents = true,
        FuzzySearch = true,
        Hotkey = Enum.KeyCode.F
    },
    
    KeySystem = {
        Enabled = false,
        Title = "Authentication Required",
        Subtitle = "Enter your access key",
        Note = "Join our Discord for access",
        SaveKey = true,
        FileName = "AccessKey",
        Keys = {},
        WebValidation = false,
        Webhook = "",
        LockoutAttempts = 5,
        LockoutTime = 300
    },
    
    Mobile = {
        Enabled = true,
        Scale = 1.1,
        LargeTouchTargets = true,
        TouchPadding = 10,
        GestureSupport = true
    },
    
    Debug = {
        Enabled = false,
        LogWarnings = true,
        PerformanceLogging = false,
        DevMode = false
    },
    
    Extensions = {}
}

-- Validation functions
local Validators = {
    Theme = function(value) return table.find({"Dark", "Light", "Custom"}, value) ~= nil end,
    Color3 = function(value) return typeof(value) == "Color3" end,
    Number = function(value, min, max) 
        return typeof(value) == "number" and value >= (min or 0) and value <= (max or 1)
    end,
    Boolean = function(value) return typeof(value) == "boolean" end,
    String = function(value) return typeof(value) == "string" and #value > 0 end,
    Table = function(value) return typeof(value) == "table" end
}

function Config.new()
    local self = setmetatable({}, Config)
    self.Sections = {}
    self.CustomValidators = {}
    return self
end

function Config:Validate(userConfig)
    local config = self:_deepCopy(Defaults)
    
    -- Merge user config
    self:_deepMerge(config, userConfig or {})
    
    -- Validate critical values
    self:_validateSection(config, userConfig)
    
    -- Apply mobile scaling if needed
    if config.Mobile.Enabled and self:_isMobile() then
        config = self:_applyMobileScaling(config)
    end
    
    return config
end

function Config:_validateSection(config, userConfig, path)
    path = path or ""
    
    for key, value in pairs(config) do
        local fullPath = path .. (path == "" and "" or ".") .. key
        
        -- Check if user provided this value
        local userValue = self:_getPath(userConfig, fullPath)
        if userValue ~= nil then
            -- Run custom validator if exists
            if self.CustomValidators[fullPath] then
                local valid, errorMsg = self.CustomValidators[fullPath](userValue)
                if not valid then
                    warn(string.format("[Celestial Config] Invalid value for %s: %s", fullPath, errorMsg))
                    -- Revert to default
                    config[key] = Defaults[key]
                else
                    config[key] = userValue
                end
            else
                config[key] = userValue
            end
        end
    end
end

function Config:_deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = self:_deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Config:_deepMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            self:_deepMerge(t1[k], v)
        else
            t1[k] = v
        end
    end
end

function Config:_getPath(t, path)
    local parts = string.split(path, ".")
    local current = t
    
    for _, part in ipairs(parts) do
        if current and type(current) == "table" then
            current = current[part]
        else
            return nil
        end
    end
    
    return current
end

function Config:_isMobile()
    local userInputService = game:GetService("UserInputService")
    return userInputService.TouchEnabled or userInputService.GamepadEnabled
end

function Config:_applyMobileScaling(config)
    -- Adjust sizes for mobile
    if config.ToggleIsland then
        config.ToggleIsland.Size = UDim2.new(0.25, 0, 0.07, 0)
    end
    
    -- Increase touch targets
    if config.Mobile.LargeTouchTargets then
        config.Mobile.Scale = config.Mobile.Scale or 1.1
    end
    
    return config
end

function Config:RegisterSection(section, defaults)
    if not defaults or type(defaults) ~= "table" then
        error("Invalid defaults provided for section: " .. tostring(section))
    end
    
    Defaults.Extensions[section] = defaults
    return true
end

function Config:Merge(base, override)
    local result = self:_deepCopy(base)
    self:_deepMerge(result, override)
    return result
end

return Config.new()