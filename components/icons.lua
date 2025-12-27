-- Icon system supporting multiple icon packs

local Icons = {}
Icons.__index = Icons

-- Icon pack definitions
local IconPacks = {
    Lucide = {
        -- Mapping of icon names to Roblox asset IDs (would need actual IDs)
        Home = "rbxassetid://",
        Settings = "rbxassetid://",
        User = "rbxassetid://",
        Search = "rbxassetid://7072716648",
        Menu = "rbxassetid://",
        Close = "rbxassetid://7072720899",
        ChevronDown = "rbxassetid://7072718165",
        ChevronRight = "rbxassetid://7072718165",
        Check = "rbxassetid://7072718176",
        X = "rbxassetid://7072720899",
        Info = "rbxassetid://",
        Warning = "rbxassetid://7072720898",
        Error = "rbxassetid://7072720899",
        Success = "rbxassetid://7072718176",
        Plus = "rbxassetid://7072716648",
        Minus = "rbxassetid://",
        Star = "rbxassetid://",
        Heart = "rbxassetid://",
        Download = "rbxassetid://",
        Upload = "rbxassetid://",
        Edit = "rbxassetid://",
        Trash = "rbxassetid://",
        Copy = "rbxassetid://",
        Paste = "rbxassetid://",
        Cut = "rbxassetid://",
        Filter = "rbxassetid://",
        Sort = "rbxassetid://",
        Refresh = "rbxassetid://",
        Lock = "rbxassetid://7072722621",
        Unlock = "rbxassetid://",
        Eye = "rbxassetid://",
        EyeOff = "rbxassetid://",
        Mail = "rbxassetid://",
        Phone = "rbxassetid://",
        Camera = "rbxassetid://",
        Video = "rbxassetid://",
        Mic = "rbxassetid://",
        Headphones = "rbxassetid://",
        Speaker = "rbxassetid://",
        Bell = "rbxassetid://",
        Calendar = "rbxassetid://",
        Clock = "rbxassetid://",
        Cloud = "rbxassetid://",
        Database = "rbxassetid://",
        Folder = "rbxassetid://",
        File = "rbxassetid://",
        Image = "rbxassetid://",
        Music = "rbxassetid://",
        Paperclip = "rbxassetid://",
        Printer = "rbxassetid://",
        Save = "rbxassetid://",
        Share = "rbxassetid://",
        Tag = "rbxassetid://",
        Terminal = "rbxassetid://",
        Wifi = "rbxassetid://",
        Zap = "rbxassetid://",
        Moon = "rbxassetid://",
        Sun = "rbxassetid://"
    },
    
    Feather = {
        -- Similar mapping for Feather icons
        Home = "rbxassetid://",
        Settings = "rbxassetid://",
        User = "rbxassetid://",
        Search = "rbxassetid://",
        Menu = "rbxassetid://",
        Close = "rbxassetid://",
        ChevronDown = "rbxassetid://",
        Check = "rbxassetid://",
        X = "rbxassetid://",
        Info = "rbxassetid://",
        Alert = "rbxassetid://",
        Plus = "rbxassetid://",
        Minus = "rbxassetid://",
        Star = "rbxassetid://",
        Heart = "rbxassetid://",
        Download = "rbxassetid://",
        Upload = "rbxassetid://",
        Edit = "rbxassetid://",
        Trash = "rbxassetid://",
        Copy = "rbxassetid://",
        Filter = "rbxassetid://",
        Refresh = "rbxassetid://",
        Lock = "rbxassetid://",
        Eye = "rbxassetid://",
        Mail = "rbxassetid://",
        Phone = "rbxassetid://",
        Camera = "rbxassetid://",
        Video = "rbxassetid://",
        Mic = "rbxassetid://",
        Bell = "rbxassetid://",
        Calendar = "rbxassetid://",
        Clock = "rbxassetid://",
        Cloud = "rbxassetid://",
        Database = "rbxassetid://",
        Folder = "rbxassetid://",
        File = "rbxassetid://",
        Image = "rbxassetid://",
        Link = "rbxassetid://",
        Paperclip = "rbxassetid://",
        Printer = "rbxassetid://",
        Save = "rbxassetid://",
        Share = "rbxassetid://",
        Tag = "rbxassetid://",
        Wifi = "rbxassetid://",
        Zap = "rbxassetid://",
        Moon = "rbxassetid://",
        Sun = "rbxassetid://"
    },
    
    Material = {
        -- Material Design icons
        Home = "rbxassetid://",
        Settings = "rbxassetid://",
        Person = "rbxassetid://",
        Search = "rbxassetid://",
        Menu = "rbxassetid://",
        Close = "rbxassetid://",
        ExpandMore = "rbxassetid://",
        Check = "rbxassetid://",
        Clear = "rbxassetid://",
        Info = "rbxassetid://",
        Warning = "rbxassetid://",
        Error = "rbxassetid://",
        Add = "rbxassetid://",
        Remove = "rbxassetid://",
        Star = "rbxassetid://",
        Favorite = "rbxassetid://",
        Download = "rbxassetid://",
        Upload = "rbxassetid://",
        Edit = "rbxassetid://",
        Delete = "rbxassetid://",
        ContentCopy = "rbxassetid://",
        FilterList = "rbxassetid://",
        Refresh = "rbxassetid://",
        Lock = "rbxassetid://",
        Visibility = "rbxassetid://",
        Email = "rbxassetid://",
        Phone = "rbxassetid://",
        Camera = "rbxassetid://",
        Videocam = "rbxassetid://",
        Mic = "rbxassetid://",
        Notifications = "rbxassetid://",
        Event = "rbxassetid://",
        Schedule = "rbxassetid://",
        Cloud = "rbxassetid://",
        Storage = "rbxassetid://",
        Folder = "rbxassetid://",
        InsertDriveFile = "rbxassetid://",
        Image = "rbxassetid://",
        AttachFile = "rbxassetid://",
        Print = "rbxassetid://",
        Save = "rbxassetid://",
        Share = "rbxassetid://",
        LocalOffer = "rbxassetid://",
        Wifi = "rbxassetid://",
        FlashOn = "rbxassetid://",
        DarkMode = "rbxassetid://",
        LightMode = "rbxassetid://"
    }
}

function Icons.new(config)
    local self = setmetatable({}, Icons)
    
    self.Config = config or {
        DefaultPack = "Lucide",
        CacheEnabled = true,
        CustomIcons = {},
        FallbackIcon = "rbxassetid://7072716648", -- Default search icon
        Debug = false
    }
    
    self.Cache = {}
    self.CustomPacks = {}
    self.UrlImages = nil -- Would be set by parent system
    
    return self
end

function Icons:_parseIconString(iconString)
    -- Parse icon strings like "lucide:home", "feather:user", "material:settings"
    -- or custom URLs like "http://example.com/icon.png"
    
    if not iconString then
        return nil, nil
    end
    
    -- Check if it's a URL
    if iconString:match("^https?://") or iconString:match("^rbxassetid://") then
        return "url", iconString
    end
    
    -- Check for pack:name format
    local pack, name = iconString:match("^([^:]+):(.+)$")
    
    if pack and name then
        return pack:lower(), name
    end
    
    -- Default to configured pack
    return self.Config.DefaultPack:lower(), iconString
end

function Icons:GetIcon(iconString, color, size)
    local packType, iconName = self:_parseIconString(iconString)
    
    if not packType or not iconName then
        if self.Config.Debug then
            warn("[Icons] Invalid icon string:", iconString)
        end
        return self.Config.FallbackIcon
    end
    
    -- Check cache first
    local cacheKey = packType .. ":" .. iconName .. ":" .. tostring(color) .. ":" .. tostring(size)
    if self.Config.CacheEnabled and self.Cache[cacheKey] then
        return self.Cache[cacheKey]
    end
    
    local iconUrl = nil
    
    if packType == "url" then
        -- Direct URL or Roblox asset
        iconUrl = iconName
    else
        -- Get from icon pack
        local pack = IconPacks[packType:gsub("^%l", string.upper)] or 
                     self.CustomPacks[packType] or 
                     IconPacks[self.Config.DefaultPack]
        
        if pack and pack[iconName] then
            iconUrl = pack[iconName]
        end
    end
    
    -- Use fallback if icon not found
    if not iconUrl or iconUrl == "" then
        if self.Config.Debug then
            warn("[Icons] Icon not found:", packType, iconName)
        end
        iconUrl = self.Config.FallbackIcon
    end
    
    -- Cache the result
    if self.Config.CacheEnabled then
        self.Cache[cacheKey] = iconUrl
    end
    
    return iconUrl
end

function Icons:CreateIconLabel(iconString, parent, config)
    config = config or {}
    
    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = config.Name or "Icon"
    iconLabel.BackgroundTransparency = 1
    iconLabel.Size = config.Size or UDim2.new(0, 24, 0, 24)
    iconLabel.Position = config.Position or UDim2.new(0, 0, 0, 0)
    iconLabel.ImageTransparency = config.Transparency or 0
    
    if config.AnchorPoint then
        iconLabel.AnchorPoint = config.AnchorPoint
    end
    
    if config.ZIndex then
        iconLabel.ZIndex = config.ZIndex
    end
    
    -- Get icon URL
    local iconUrl = self:GetIcon(iconString, config.Color, config.Size)
    iconLabel.Image = iconUrl
    
    -- Apply color if specified
    if config.Color then
        iconLabel.ImageColor3 = config.Color
    end
    
    -- Handle URL images if needed
    if iconUrl:match("^https?://") and self.UrlImages then
        -- Use URL image loader
        self.UrlImages:LoadImage(iconUrl, function(imageData)
            if imageData then
                -- Would need to convert to texture
                -- For now, just use the URL
                iconLabel.Image = iconUrl
            end
        end)
    end
    
    if parent then
        iconLabel.Parent = parent
    end
    
    return iconLabel
end

function Icons:CreateIconButton(iconString, parent, config)
    config = config or {}
    
    local iconButton = Instance.new("ImageButton")
    iconButton.Name = config.Name or "IconButton"
    iconButton.BackgroundTransparency = 1
    iconButton.Size = config.Size or UDim2.new(0, 32, 0, 32)
    iconButton.Position = config.Position or UDim2.new(0, 0, 0, 0)
    iconButton.ImageTransparency = config.Transparency or 0
    
    if config.AnchorPoint then
        iconButton.AnchorPoint = config.AnchorPoint
    end
    
    if config.ZIndex then
        iconButton.ZIndex = config.ZIndex
    end
    
    -- Get icon URL
    local iconUrl = self:GetIcon(iconString, config.Color, config.Size)
    iconButton.Image = iconUrl
    
    -- Apply color if specified
    if config.Color then
        iconButton.ImageColor3 = config.Color
    end
    
    -- Add hover effects
    if config.HoverEffect then
        iconButton.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(iconButton, TweenInfo.new(0.2), {
                ImageTransparency = 0.1,
                Size = config.Size * UDim2.new(1.1, 0, 1.1, 0)
            }):Play()
        end)
        
        iconButton.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(iconButton, TweenInfo.new(0.2), {
                ImageTransparency = config.Transparency or 0,
                Size = config.Size or UDim2.new(0, 32, 0, 32)
            }):Play()
        end)
    end
    
    -- Click callback
    if config.Callback then
        iconButton.MouseButton1Click:Connect(function()
            task.spawn(config.Callback)
        end)
    end
    
    if parent then
        iconButton.Parent = parent
    end
    
    return iconButton
end

function Icons:RegisterCustomPack(packName, icons)
    if not packName or type(icons) ~= "table" then
        if self.Config.Debug then
            warn("[Icons] Invalid custom pack:", packName)
        end
        return false
    end
    
    self.CustomPacks[packName:lower()] = icons
    
    if self.Config.Debug then
        print("[Icons] Registered custom pack:", packName, "with", #icons, "icons")
    end
    
    return true
end

function Icons:AddCustomIcon(packName, iconName, iconUrl)
    if not packName or not iconName or not iconUrl then
        if self.Config.Debug then
            warn("[Icons] Invalid custom icon:", packName, iconName, iconUrl)
        end
        return false
    end
    
    local pack = self.CustomPacks[packName:lower()]
    if not pack then
        pack = {}
        self.CustomPacks[packName:lower()] = pack
    end
    
    pack[iconName] = iconUrl
    
    -- Clear cache for this pack
    self:ClearPackCache(packName)
    
    if self.Config.Debug then
        print("[Icons] Added custom icon:", packName, iconName)
    end
    
    return true
end

function Icons:SetDefaultPack(packName)
    if IconPacks[packName] or self.CustomPacks[packName:lower()] then
        self.Config.DefaultPack = packName
        
        if self.Config.Debug then
            print("[Icons] Default pack set to:", packName)
        end
        
        return true
    else
        if self.Config.Debug then
            warn("[Icons] Pack not found:", packName)
        end
        return false
    end
end

function Icons:GetAvailablePacks()
    local packs = {}
    
    -- Add built-in packs
    for packName, _ in pairs(IconPacks) do
        table.insert(packs, packName)
    end
    
    -- Add custom packs
    for packName, _ in pairs(self.CustomPacks) do
        table.insert(packs, packName)
    end
    
    return packs
end

function Icons:GetPackIcons(packName)
    local pack = IconPacks[packName] or self.CustomPacks[packName:lower()]
    
    if not pack then
        if self.Config.Debug then
            warn("[Icons] Pack not found:", packName)
        end
        return {}
    end
    
    local icons = {}
    for iconName, _ in pairs(pack) do
        table.insert(icons, iconName)
    end
    
    table.sort(icons)
    return icons
end

function Icons:ClearCache()
    self.Cache = {}
    
    if self.Config.Debug then
        print("[Icons] Cache cleared")
    end
end

function Icons:ClearPackCache(packName)
    if not packName then
        self:ClearCache()
        return
    end
    
    local toRemove = {}
    for cacheKey, _ in pairs(self.Cache) do
        if cacheKey:match("^" .. packName:lower() .. ":") then
            table.insert(toRemove, cacheKey)
        end
    end
    
    for _, cacheKey in ipairs(toRemove) do
        self.Cache[cacheKey] = nil
    end
    
    if self.Config.Debug then
        print("[Icons] Cleared cache for pack:", packName, "removed", #toRemove, "entries")
    end
end

function Icons:SetFallbackIcon(iconUrl)
    self.Config.FallbackIcon = iconUrl
end

function Icons:SetUrlImagesSystem(urlImagesSystem)
    self.UrlImages = urlImagesSystem
end

function Icons:Destroy()
    self:ClearCache()
    self.CustomPacks = {}
    self.UrlImages = nil
end

-- Convenience methods for common icons
function Icons:GetHomeIcon()
    return self:GetIcon("lucide:home")
end

function Icons:GetSettingsIcon()
    return self:GetIcon("lucide:settings")
end

function Icons:GetSearchIcon()
    return self:GetIcon("lucide:search")
end

function Icons:GetCloseIcon()
    return self:GetIcon("lucide:close")
end

function Icons:GetCheckIcon()
    return self:GetIcon("lucide:check")
end

function Icons:GetWarningIcon()
    return self:GetIcon("lucide:warning")
end

function Icons:GetErrorIcon()
    return self:GetIcon("lucide:error")
end

function Icons:GetSuccessIcon()
    return self:GetIcon("lucide:success")
end

return Icons