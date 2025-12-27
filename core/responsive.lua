-- Responsive design system for mobile, tablet, and PC

local Responsive = {}
Responsive.__index = Responsive

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

function Responsive.new(config)
    local self = setmetatable({}, Responsive)
    
    self.Config = config or {
        Enabled = true,
        Scale = 1.0,
        LargeTouchTargets = true,
        TouchPadding = 10,
        GestureSupport = true,
        Breakpoints = {
            Mobile = 600,
            Tablet = 900,
            Desktop = 1200
        }
    }
    
    self.DeviceType = "Desktop"
    self.Orientation = "Landscape"
    self.SafeArea = nil
    self.AdaptiveScale = 1.0
    
    self.Connections = {}
    self.Callbacks = {}
    
    self:_detectDevice()
    self:_setupListeners()
    self:_calculateSafeArea()
    
    return self
end

function Responsive:_detectDevice()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    -- Check input methods
    local isMobile = UserInputService.TouchEnabled
    local isGamepad = UserInputService.GamepadEnabled
    local isDesktop = not isMobile and not isGamepad
    
    -- Determine device type based on screen size and input
    if isMobile then
        if viewportSize.X <= self.Config.Breakpoints.Mobile then
            self.DeviceType = "Mobile"
        elseif viewportSize.X <= self.Config.Breakpoints.Tablet then
            self.DeviceType = "Tablet"
        else
            self.DeviceType = "Desktop"
        end
    elseif isGamepad then
        self.DeviceType = "Console"
    else
        self.DeviceType = "Desktop"
    end
    
    -- Check orientation
    self.Orientation = viewportSize.X > viewportSize.Y and "Landscape" or "Portrait"
    
    -- Calculate adaptive scale
    self:_calculateScale()
end

function Responsive:_setupListeners()
    -- Viewport size changes
    table.insert(self.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        self:_detectDevice()
        self:_calculateSafeArea()
        self:_calculateScale()
        self:_notifyChange()
    end))
    
    -- Input type changes (for devices that support multiple inputs)
    table.insert(self.Connections, UserInputService.LastInputTypeChanged:Connect(function()
        self:_detectDevice()
        self:_notifyChange()
    end))
    
    -- Safe area changes (for mobile notches)
    if GuiService.GetSafeZoneOffsets then
        table.insert(self.Connections, GuiService:GetPropertyChangedSignal("SafeZoneCompatibility"):Connect(function()
            self:_calculateSafeArea()
            self:_notifyChange()
        end))
    end
end

function Responsive:_calculateSafeArea()
    -- Calculate safe area for mobile devices with notches
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if GuiService.GetSafeZoneOffsets then
        local safeZone = GuiService:GetSafeZoneOffsets()
        
        self.SafeArea = {
            Left = safeZone.X,
            Right = safeZone.Z,
            Top = safeZone.Y,
            Bottom = safeZone.W,
            
            Width = viewportSize.X - safeZone.X - safeZone.Z,
            Height = viewportSize.Y - safeZone.Y - safeZone.W,
            
            Position = UDim2.new(safeZone.X / viewportSize.X, 0, safeZone.Y / viewportSize.Y, 0),
            Size = UDim2.new(
                (viewportSize.X - safeZone.X - safeZone.Z) / viewportSize.X,
                0,
                (viewportSize.Y - safeZone.Y - safeZone.W) / viewportSize.Y,
                0
            )
        }
    else
        -- Default to full screen
        self.SafeArea = {
            Left = 0,
            Right = 0,
            Top = 0,
            Bottom = 0,
            
            Width = viewportSize.X,
            Height = viewportSize.Y,
            
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0)
        }
    end
end

function Responsive:_calculateScale()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local baseResolution = Vector2.new(1920, 1080) -- Base design resolution
    
    -- Calculate scale based on screen size
    local scaleX = viewportSize.X / baseResolution.X
    local scaleY = viewportSize.Y / baseResolution.Y
    
    -- Use the smaller scale to ensure everything fits
    self.BaseScale = math.min(scaleX, scaleY)
    
    -- Apply device-specific scaling
    if self.DeviceType == "Mobile" then
        self.AdaptiveScale = self.BaseScale * (self.Config.Scale or 1.1)
        
        -- Increase touch targets
        if self.Config.LargeTouchTargets then
            self.TouchScale = 1.2
        else
            self.TouchScale = 1.0
        end
    elseif self.DeviceType == "Tablet" then
        self.AdaptiveScale = self.BaseScale * (self.Config.Scale or 1.05)
        self.TouchScale = 1.1
    else
        self.AdaptiveScale = self.BaseScale * (self.Config.Scale or 1.0)
        self.TouchScale = 1.0
    end
    
    -- Clamp scale
    self.AdaptiveScale = math.clamp(self.AdaptiveScale, 0.5, 2.0)
end

function Responsive:_notifyChange()
    for _, callback in ipairs(self.Callbacks) do
        task.spawn(callback, {
            DeviceType = self.DeviceType,
            Orientation = self.Orientation,
            SafeArea = self.SafeArea,
            Scale = self.AdaptiveScale,
            ViewportSize = workspace.CurrentCamera.ViewportSize
        })
    end
end

function Responsive:GetScale()
    return self.AdaptiveScale
end

function Responsive:GetDeviceType()
    return self.DeviceType
end

function Responsive:GetOrientation()
    return self.Orientation
end

function Responsive:GetSafeArea()
    return self.SafeArea
end

function Responsive:IsMobile()
    return self.DeviceType == "Mobile"
end

function Responsive:IsTablet()
    return self.DeviceType == "Tablet"
end

function Responsive:IsDesktop()
    return self.DeviceType == "Desktop"
end

function Responsive:IsLandscape()
    return self.Orientation == "Landscape"
end

function Responsive:IsPortrait()
    return self.Orientation == "Portrait"
end

function Responsive:ScaleValue(value)
    -- Scale a value based on current device
    if type(value) == "number" then
        return value * self.AdaptiveScale
    elseif typeof(value) == "UDim2" then
        return UDim2.new(
            value.X.Scale,
            value.X.Offset * self.AdaptiveScale,
            value.Y.Scale,
            value.Y.Offset * self.AdaptiveScale
        )
    elseif typeof(value) == "Vector2" then
        return value * self.AdaptiveScale
    end
    
    return value
end

function Responsive:ScaleFrame(frame, includeTouchPadding)
    if not frame:IsA("GuiObject") then return end
    
    -- Scale size
    local currentSize = frame.Size
    frame.Size = self:ScaleValue(currentSize)
    
    -- Scale position
    local currentPosition = frame.Position
    frame.Position = self:ScaleValue(currentPosition)
    
    -- Scale padding for touch targets
    if includeTouchPadding and self.Config.LargeTouchTargets then
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, self.Config.TouchPadding)
        padding.PaddingRight = UDim.new(0, self.Config.TouchPadding)
        padding.PaddingTop = UDim.new(0, self.Config.TouchPadding)
        padding.PaddingBottom = UDim.new(0, self.Config.TouchPadding)
        padding.Parent = frame
    end
    
    -- Adjust font size for mobile
    if self:IsMobile() and frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("TextBox") then
        frame.TextSize = frame.TextSize * 1.1
    end
end

function Responsive:CreateAdaptiveContainer(parent, config)
    config = config or {}
    
    local container = Instance.new("Frame")
    container.Name = "AdaptiveContainer"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    
    -- Apply safe area
    if config.RespectSafeArea then
        container.Position = self.SafeArea.Position
        container.Size = self.SafeArea.Size
    end
    
    -- Layout based on device
    if self:IsMobile() and self:IsPortrait() then
        -- Stack vertically on mobile portrait
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10 * self.AdaptiveScale)
        layout.Parent = container
    else
        -- Use grid on larger screens
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 100 * self.AdaptiveScale, 0, 100 * self.AdaptiveScale)
        grid.CellPadding = UDim2.new(0, 10 * self.AdaptiveScale, 0, 10 * self.AdaptiveScale)
        grid.Parent = container
    end
    
    if parent then
        container.Parent = parent
    end
    
    return container
end

function Responsive:ApplyResponsiveStyles(guiObject)
    if not guiObject:IsA("GuiObject") then return end
    
    -- Device-specific styling
    if self:IsMobile() then
        -- Mobile optimizations
        if guiObject:IsA("TextButton") or guiObject:IsA("ImageButton") then
            -- Larger touch targets
            local absoluteSize = guiObject.AbsoluteSize
            if absoluteSize.X < 44 * self.AdaptiveScale or absoluteSize.Y < 44 * self.AdaptiveScale then
                guiObject.Size = UDim2.new(
                    guiObject.Size.X.Scale,
                    math.max(guiObject.Size.X.Offset, 44 * self.AdaptiveScale),
                    guiObject.Size.Y.Scale,
                    math.max(guiObject.Size.Y.Offset, 44 * self.AdaptiveScale)
                )
            end
        end
        
        -- Adjust font sizes
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
            if guiObject.TextSize < 14 then
                guiObject.TextSize = 14
            end
        end
    end
    
    -- Orientation-specific adjustments
    if self:IsPortrait() then
        -- Stack elements vertically
        if guiObject:FindFirstChildWhichIsA("UIListLayout") then
            local layout = guiObject:FindFirstChildWhichIsA("UIListLayout")
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end
    end
end

function Responsive:OnChange(callback)
    table.insert(self.Callbacks, callback)
    
    -- Return removal function
    return function()
        for i, cb in ipairs(self.Callbacks) do
            if cb == callback then
                table.remove(self.Callbacks, i)
                break
            end
        end
    end
end

function Responsive:GetRecommendedSpacing()
    -- Return recommended spacing based on device
    if self:IsMobile() then
        return {
            Small = 4 * self.AdaptiveScale,
            Medium = 8 * self.AdaptiveScale,
            Large = 16 * self.AdaptiveScale,
            XLarge = 24 * self.AdaptiveScale
        }
    elseif self:IsTablet() then
        return {
            Small = 6 * self.AdaptiveScale,
            Medium = 12 * self.AdaptiveScale,
            Large = 20 * self.AdaptiveScale,
            XLarge = 32 * self.AdaptiveScale
        }
    else
        return {
            Small = 8 * self.AdaptiveScale,
            Medium = 16 * self.AdaptiveScale,
            Large = 24 * self.AdaptiveScale,
            XLarge = 40 * self.AdaptiveScale
        }
    end
end

function Responsive:Destroy()
    -- Cleanup connections
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    
    self.Connections = {}
    self.Callbacks = {}
end

return Responsive