-- Premium color picker component inspired by iro.js

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Color conversion utilities
local function RGBToHSV(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v
    
    v = max
    
    local d = max - min
    if max == 0 then
        s = 0
    else
        s = d / max
    end
    
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then
                h = h + 6
            end
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

local function HSVToRGB(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end
    
    return r, g, b
end

local function Color3ToHSV(color)
    return RGBToHSV(color.R, color.G, color.B)
end

local function HSVToColor3(h, s, v)
    return Color3.fromRGB(
        math.floor(HSVToRGB(h, s, v) * 255),
        math.floor(HSVToRGB(h, s, v, 1) * 255),
        math.floor(HSVToRGB(h, s, v, 2) * 255)
    )
end

local function Color3ToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1")
    end
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

function ColorPicker.new(config, parent, theme, animations)
    local self = setmetatable({}, ColorPicker)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Color = config.Default or Color3.fromRGB(80, 140, 255)
    self.Alpha = config.Alpha or 1
    self.Presets = config.Presets or {}
    self.RecentColors = {}
    self.MaxRecent = config.MaxRecent or 8
    
    self.Dragging = false
    self.DraggingHue = false
    self.DraggingAlpha = false
    
    self:_createColorPicker()
    self:_setupEvents()
    
    -- Set initial color
    self:SetColor(self.Color, self.Alpha, true)
    
    return self
end

function ColorPicker:_createColorPicker()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialColorPicker"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 300)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.Parent = self.Parent
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.BackgroundTransparency = 1
    self.Header.Size = UDim2.new(1, 0, 0, 20)
    self.Header.Position = UDim2.new(0, 0, 0, 0)
    self.Header.Parent = self.Container
    
    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(0.7, 0, 1, 0)
    self.Label.Position = UDim2.new(0, 0, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Name or "Color Picker"
    self.Label.TextColor3 = self.Theme:GetColor("ColorPicker", "Text") or Color3.fromRGB(220, 220, 225)
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Header
    
    -- Color preview
    self.Preview = Instance.new("Frame")
    self.Preview.Name = "Preview"
    self.Preview.BackgroundColor3 = self.Color
    self.Preview.BackgroundTransparency = 1 - self.Alpha
    self.Preview.Size = UDim2.new(0, 60, 0, 20)
    self.Preview.Position = UDim2.new(1, -60, 0, 0)
    self.Preview.AnchorPoint = Vector2.new(1, 0)
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 4)
    previewCorner.Parent = self.Preview
    
    local previewStroke = Instance.new("UIStroke")
    previewStroke.Color = Color3.new(1, 1, 1)
    previewStroke.Transparency = 0.8
    previewStroke.Thickness = 1
    previewStroke.Parent = self.Preview
    
    -- Checkerboard pattern for transparency
    local checkerboard = Instance.new("Frame")
    checkerboard.Name = "Checkerboard"
    checkerboard.BackgroundColor3 = Color3.new(1, 1, 1)
    checkerboard.BackgroundTransparency = 0
    checkerboard.Size = UDim2.new(1, 0, 1, 0)
    checkerboard.ZIndex = -1
    
    local checkerboardGrid = Instance.new("UIGridLayout")
    checkerboardGrid.CellSize = UDim2.new(0, 5, 0, 5)
    checkerboardGrid.CellPadding = UDim2.new(0, 0, 0, 0)
    checkerboardGrid.FillDirection = Enum.FillDirection.Horizontal
    checkerboardGrid.Parent = checkerboard
    
    for i = 1, 4 do
        for j = 1, 4 do
            local square = Instance.new("Frame")
            square.BackgroundColor3 = (i + j) % 2 == 0 and Color3.new(0.8, 0.8, 0.8) or Color3.new(0.6, 0.6, 0.6)
            square.BackgroundTransparency = 0
            square.Size = UDim2.new(1, 0, 1, 0)
            square.Parent = checkerboard
        end
    end
    
    checkerboard.Parent = self.Preview
    
    self.Preview.Parent = self.Header
    
    -- Color wheel
    self.ColorWheel = Instance.new("ImageLabel")
    self.ColorWheel.Name = "ColorWheel"
    self.ColorWheel.BackgroundColor3 = Color3.new(1, 1, 1)
    self.ColorWheel.BackgroundTransparency = 0
    self.ColorWheel.Size = UDim2.new(0, 150, 0, 150)
    self.ColorWheel.Position = UDim2.new(0, 0, 0, 30)
    self.ColorWheel.Image = "rbxassetid://9151792458" -- Color wheel image
    self.ColorWheel.ScaleType = Enum.ScaleType.Fit
    
    local wheelCorner = Instance.new("UICorner")
    wheelCorner.CornerRadius = UDim.new(1, 0)
    wheelCorner.Parent = self.ColorWheel
    
    local wheelStroke = Instance.new("UIStroke")
    wheelStroke.Color = Color3.new(0, 0, 0)
    wheelStroke.Transparency = 0.7
    wheelStroke.Thickness = 2
    wheelStroke.Parent = self.ColorWheel
    
    -- Wheel selector
    self.WheelSelector = Instance.new("Frame")
    self.WheelSelector.Name = "WheelSelector"
    self.WheelSelector.BackgroundColor3 = Color3.new(1, 1, 1)
    self.WheelSelector.BackgroundTransparency = 0
    self.WheelSelector.Size = UDim2.new(0, 12, 0, 12)
    self.WheelSelector.Position = UDim2.new(0.5, -6, 0.5, -6)
    self.WheelSelector.AnchorPoint = Vector2.new(0.5, 0.5)
    self.WheelSelector.ZIndex = 10
    
    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = UDim.new(1, 0)
    selectorCorner.Parent = self.WheelSelector
    
    local selectorStroke = Instance.new("UIStroke")
    selectorStroke.Color = Color3.new(0, 0, 0)
    selectorStroke.Transparency = 0.3
    selectorStroke.Thickness = 2
    selectorStroke.Parent = self.WheelSelector
    
    self.WheelSelector.Parent = self.ColorWheel
    
    self.ColorWheel.Parent = self.Container
    
    -- Hue slider
    self.HueContainer = Instance.new("Frame")
    self.HueContainer.Name = "HueContainer"
    self.HueContainer.BackgroundTransparency = 1
    self.HueContainer.Size = UDim2.new(0, 20, 0, 150)
    self.HueContainer.Position = UDim2.new(0, 160, 0, 30)
    self.HueContainer.Parent = self.Container
    
    -- Hue gradient
    self.HueGradient = Instance.new("Frame")
    self.HueGradient.Name = "HueGradient"
    self.HueGradient.BackgroundColor3 = Color3.new(1, 1, 1)
    self.HueGradient.BackgroundTransparency = 0
    self.HueGradient.Size = UDim2.new(1, 0, 1, 0)
    
    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(0, 4)
    hueCorner.Parent = self.HueGradient
    
    local hueStroke = Instance.new("UIStroke")
    hueStroke.Color = Color3.new(0, 0, 0)
    hueStroke.Transparency = 0.5
    hueStroke.Thickness = 1
    hueStroke.Parent = self.HueGradient
    
    -- Create hue gradient using multiple frames (simplified)
    local hueLayout = Instance.new("UIListLayout")
    hueLayout.FillDirection = Enum.FillDirection.Vertical
    hueLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hueLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    hueLayout.Padding = UDim.new(0, 0)
    hueLayout.Parent = self.HueGradient
    
    for i = 0, 5 do
        local hueSegment = Instance.new("Frame")
        hueSegment.Size = UDim2.new(1, 0, 0, 25)
        hueSegment.BackgroundColor3 = HSVToColor3(i / 6, 1, 1)
        hueSegment.BorderSizePixel = 0
        hueSegment.Parent = self.HueGradient
    end
    
    self.HueGradient.Parent = self.HueContainer
    
    -- Hue selector
    self.HueSelector = Instance.new("Frame")
    self.HueSelector.Name = "HueSelector"
    self.HueSelector.BackgroundColor3 = Color3.new(1, 1, 1)
    self.HueSelector.BackgroundTransparency = 0
    self.HueSelector.Size = UDim2.new(1, 4, 0, 4)
    self.HueSelector.Position = UDim2.new(0, -2, 0, 0)
    self.HueSelector.AnchorPoint = Vector2.new(0, 0.5)
    self.HueSelector.ZIndex = 10
    
    local hueSelectorCorner = Instance.new("UICorner")
    hueSelectorCorner.CornerRadius = UDim.new(1, 0)
    hueSelectorCorner.Parent = self.HueSelector
    
    local hueSelectorStroke = Instance.new("UIStroke")
    hueSelectorStroke.Color = Color3.new(0, 0, 0)
    hueSelectorStroke.Transparency = 0.3
    hueSelectorStroke.Thickness = 2
    hueSelectorStroke.Parent = self.HueSelector
    
    self.HueSelector.Parent = self.HueContainer
    
    -- Alpha slider
    if self.Config.ShowAlpha then
        self.AlphaContainer = Instance.new("Frame")
        self.AlphaContainer.Name = "AlphaContainer"
        self.AlphaContainer.BackgroundTransparency = 1
        self.AlphaContainer.Size = UDim2.new(0, 20, 0, 150)
        self.AlphaContainer.Position = UDim2.new(0, 190, 0, 30)
        self.AlphaContainer.Parent = self.Container
        
        -- Alpha background (checkerboard)
        self.AlphaBackground = Instance.new("Frame")
        self.AlphaBackground.Name = "AlphaBackground"
        self.AlphaBackground.BackgroundColor3 = Color3.new(1, 1, 1)
        self.AlphaBackground.BackgroundTransparency = 0
        self.AlphaBackground.Size = UDim2.new(1, 0, 1, 0)
        
        local alphaCorner = Instance.new("UICorner")
        alphaCorner.CornerRadius = UDim.new(0, 4)
        alphaCorner.Parent = self.AlphaBackground
        
        local alphaStroke = Instance.new("UIStroke")
        alphaStroke.Color = Color3.new(0, 0, 0)
        alphaStroke.Transparency = 0.5
        alphaStroke.Thickness = 1
        alphaStroke.Parent = self.AlphaBackground
        
        -- Create checkerboard pattern
        local alphaGrid = Instance.new("UIGridLayout")
        alphaGrid.CellSize = UDim2.new(0, 5, 0, 5)
        alphaGrid.CellPadding = UDim2.new(0, 0, 0, 0)
        alphaGrid.FillDirection = Enum.FillDirection.Vertical
        alphaGrid.Parent = self.AlphaBackground
        
        for i = 1, 4 do
            for j = 1, 30 do
                local square = Instance.new("Frame")
                square.BackgroundColor3 = (i + j) % 2 == 0 and Color3.new(0.8, 0.8, 0.8) or Color3.new(0.6, 0.6, 0.6)
                square.Size = UDim2.new(1, 0, 1, 0)
                square.Parent = self.AlphaBackground
            end
        end
        
        self.AlphaBackground.Parent = self.AlphaContainer
        
        -- Alpha gradient overlay
        self.AlphaGradient = Instance.new("Frame")
        self.AlphaGradient.Name = "AlphaGradient"
        self.AlphaGradient.BackgroundColor3 = self.Color
        self.AlphaGradient.BackgroundTransparency = 0
        self.AlphaGradient.Size = UDim2.new(1, 0, 1, 0)
        self.AlphaGradient.ZIndex = 1
        
        local alphaGradient = Instance.new("UIGradient")
        alphaGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(self.Color.R, self.Color.G, self.Color.B)),
            ColorSequenceKeypoint.new(1, Color3.new(self.Color.R, self.Color.G, self.Color.B))
        }
        alphaGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1)
        }
        alphaGradient.Rotation = 90
        alphaGradient.Parent = self.AlphaGradient
        
        self.AlphaGradient.Parent = self.AlphaContainer
        
        -- Alpha selector
        self.AlphaSelector = Instance.new("Frame")
        self.AlphaSelector.Name = "AlphaSelector"
        self.AlphaSelector.BackgroundColor3 = Color3.new(1, 1, 1)
        self.AlphaSelector.BackgroundTransparency = 0
        self.AlphaSelector.Size = UDim2.new(1, 4, 0, 4)
        self.AlphaSelector.Position = UDim2.new(0, -2, 1, 0)
        self.AlphaSelector.AnchorPoint = Vector2.new(0, 1)
        self.AlphaSelector.ZIndex = 10
        
        local alphaSelectorCorner = Instance.new("UICorner")
        alphaSelectorCorner.CornerRadius = UDim.new(1, 0)
        alphaSelectorCorner.Parent = self.AlphaSelector
        
        local alphaSelectorStroke = Instance.new("UIStroke")
        alphaSelectorStroke.Color = Color3.new(0, 0, 0)
        alphaSelectorStroke.Transparency = 0.3
        alphaSelectorStroke.Thickness = 2
        alphaSelectorStroke.Parent = self.AlphaSelector
        
        self.AlphaSelector.Parent = self.AlphaContainer
    end
    
    -- Input fields
    self.InputContainer = Instance.new("Frame")
    self.InputContainer.Name = "InputContainer"
    self.InputContainer.BackgroundTransparency = 1
    self.InputContainer.Size = UDim2.new(1, 0, 0, 100)
    self.InputContainer.Position = UDim2.new(0, 0, 0, 190)
    self.InputContainer.Parent = self.Container
    
    -- RGB inputs
    self.RGBContainer = Instance.new("Frame")
    self.RGBContainer.Name = "RGBContainer"
    self.RGBContainer.BackgroundTransparency = 1
    self.RGBContainer.Size = UDim2.new(0.5, -5, 0, 90)
    self.RGBContainer.Position = UDim2.new(0, 0, 0, 0)
    self.RGBContainer.Parent = self.InputContainer
    
    self.RInput = self:_createNumberInput("R", "Red", 0, 0, 0)
    self.GInput = self:_createNumberInput("G", "Green", 0, 40, 0)
    self.BInput = self:_createNumberInput("B", "Blue", 0, 80, 0)
    
    -- Hex input
    self.HexContainer = Instance.new("Frame")
    self.HexContainer.Name = "HexContainer"
    self.HexContainer.BackgroundTransparency = 1
    self.HexContainer.Size = UDim2.new(0.5, -5, 0, 30)
    self.HexContainer.Position = UDim2.new(0.5, 5, 0, 0)
    self.HexContainer.Parent = self.InputContainer
    
    self.HexInput = self:_createTextInput("Hex", "Hex", 0, 0, 1)
    
    -- Presets
    if #self.Presets > 0 then
        self.PresetsContainer = Instance.new("Frame")
        self.PresetsContainer.Name = "Presets"
        self.PresetsContainer.BackgroundTransparency = 1
        self.PresetsContainer.Size = UDim2.new(1, 0, 0, 40)
        self.PresetsContainer.Position = UDim2.new(0, 0, 1, -40)
        self.PresetsContainer.Parent = self.Container
        
        local presetsLabel = Instance.new("TextLabel")
        presetsLabel.BackgroundTransparency = 1
        presetsLabel.Size = UDim2.new(1, 0, 0, 20)
        presetsLabel.Font = Enum.Font.Gotham
        presetsLabel.Text = "Presets"
        presetsLabel.TextColor3 = self.Theme:GetColor("ColorPicker", "Text")
        presetsLabel.TextSize = 12
        presetsLabel.TextXAlignment = Enum.TextXAlignment.Left
        presetsLabel.Parent = self.PresetsContainer
        
        self.PresetButtons = {}
        for i, presetColor in ipairs(self.Presets) do
            local presetButton = Instance.new("Frame")
            presetButton.Name = "Preset_" .. i
            presetButton.BackgroundColor3 = presetColor
            presetButton.BackgroundTransparency = 0
            presetButton.Size = UDim2.new(0, 20, 0, 20)
            presetButton.Position = UDim2.new(0, (i - 1) * 25, 0, 20)
            
            local presetCorner = Instance.new("UICorner")
            presetCorner.CornerRadius = UDim.new(0, 4)
            presetCorner.Parent = presetButton
            
            local presetStroke = Instance.new("UIStroke")
            presetStroke.Color = Color3.new(0, 0, 0)
            presetStroke.Transparency = 0.5
            presetStroke.Thickness = 1
            presetStroke.Parent = presetButton
            
            presetButton.Parent = self.PresetsContainer
            
            presetButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    self:SetColor(presetColor)
                end
            end)
            
            table.insert(self.PresetButtons, presetButton)
        end
    end
end

function ColorPicker:_createNumberInput(name, placeholder, x, y, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 30)
    container.Position = UDim2.new(0, x, 0, y)
    container.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 20, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextColor3 = self.Theme:GetColor("ColorPicker", "Text")
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.BackgroundColor3 = self.Theme:GetColor("Input", "Background") or Color3.fromRGB(40, 40, 45)
    input.BackgroundTransparency = 0.1
    input.Size = UDim2.new(1, -25, 1, 0)
    input.Position = UDim2.new(0, 25, 0, 0)
    input.Font = Enum.Font.Gotham
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = self.Theme:GetColor("Input", "Placeholder")
    input.TextColor3 = self.Theme:GetColor("Input", "Text")
    input.TextSize = 12
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = self.Theme:GetColor("Input", "Stroke") or Color3.fromRGB(60, 60, 65)
    inputStroke.Transparency = 0.3
    inputStroke.Thickness = 1
    inputStroke.Parent = input
    
    -- Events
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(input.Text)
            if value then
                value = math.clamp(value, 0, 255)
                self:_updateFromRGB()
            end
        end
    end)
    
    input.Parent = container
    container.Parent = self.RGBContainer
    
    return input
end

function ColorPicker:_createTextInput(name, placeholder, x, y, layoutOrder)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 30)
    container.Position = UDim2.new(0, x, 0, y)
    container.LayoutOrder = layoutOrder
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0, 30, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = name
    label.TextColor3 = self.Theme:GetColor("ColorPicker", "Text")
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.BackgroundColor3 = self.Theme:GetColor("Input", "Background") or Color3.fromRGB(40, 40, 45)
    input.BackgroundTransparency = 0.1
    input.Size = UDim2.new(1, -35, 1, 0)
    input.Position = UDim2.new(0, 35, 0, 0)
    input.Font = Enum.Font.Gotham
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = self.Theme:GetColor("Input", "Placeholder")
    input.TextColor3 = self.Theme:GetColor("Input", "Text")
    input.TextSize = 12
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = self.Theme:GetColor("Input", "Stroke") or Color3.fromRGB(60, 60, 65)
    inputStroke.Transparency = 0.3
    inputStroke.Thickness = 1
    inputStroke.Parent = input
    
    -- Events
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local text = input.Text
            if text:match("^#?[0-9A-Fa-f]+$") then
                self:SetColor(HexToColor3(text))
            end
        end
    end)
    
    input.Parent = container
    container.Parent = self.HexContainer
    
    return input
end

function ColorPicker:_setupEvents()
    -- Color wheel drag
    self.ColorWheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self:_onColorWheelDrag(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            self:_onColorWheelDrag(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = false
        end
    end)
    
    -- Hue slider drag
    self.HueContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingHue = true
            self:_onHueDrag(input)
        end
    end)
    
    -- Alpha slider drag
    if self.AlphaContainer then
        self.AlphaContainer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                self.DraggingAlpha = true
                self:_onAlphaDrag(input)
            end
        end)
    end
    
    -- Update drag events
    local function updateDrag(input)
        if self.DraggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            self:_onHueDrag(input)
        elseif self.DraggingAlpha and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
            self:_onAlphaDrag(input)
        end
    end
    
    UserInputService.InputChanged:Connect(updateDrag)
    
    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.DraggingHue = false
            self.DraggingAlpha = false
        end
    end
    
    UserInputService.InputEnded:Connect(endDrag)
end

function ColorPicker:_onColorWheelDrag(input)
    local wheelPos = self.ColorWheel.AbsolutePosition
    local wheelSize = self.ColorWheel.AbsoluteSize
    local mousePos = input.Position
    
    -- Calculate relative position
    local relX = (mousePos.X - wheelPos.X) / wheelSize.X
    local relY = (mousePos.Y - wheelPos.Y) / wheelSize.Y
    
    -- Convert to polar coordinates
    local centerX = 0.5
    local centerY = 0.5
    local dx = relX - centerX
    local dy = relY - centerY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Clamp to wheel radius
    if distance > 0.5 then
        dx = dx * 0.5 / distance
        dy = dy * 0.5 / distance
        distance = 0.5
    end
    
    -- Calculate hue and saturation
    local angle = math.atan2(dy, dx)
    local hue = (angle + math.pi) / (2 * math.pi)
    local saturation = distance * 2
    
    -- Get current value from HSV
    local currentH, currentS, currentV = Color3ToHSV(self.Color)
    
    -- Update color
    local newColor = HSVToColor3(hue, saturation, currentV)
    self:SetColor(newColor)
    
    -- Update selector position
    local selectorX = centerX + dx
    local selectorY = centerY + dy
    
    self.WheelSelector.Position = UDim2.new(selectorX, -6, selectorY, -6)
end

function ColorPicker:_onHueDrag(input)
    local containerPos = self.HueContainer.AbsolutePosition
    local containerSize = self.HueContainer.AbsoluteSize
    local mousePos = input.Position.Y
    
    -- Calculate hue (0 at top, 1 at bottom)
    local hue = (mousePos - containerPos.Y) / containerSize.Height
    hue = math.clamp(hue, 0, 1)
    
    -- Get current saturation and value
    local currentH, currentS, currentV = Color3ToHSV(self.Color)
    
    -- Update color
    local newColor = HSVToColor3(hue, currentS, currentV)
    self:SetColor(newColor)
    
    -- Update selector position
    self.HueSelector.Position = UDim2.new(0, -2, hue, 0)
end

function ColorPicker:_onAlphaDrag(input)
    if not self.AlphaContainer then return end
    
    local containerPos = self.AlphaContainer.AbsolutePosition
    local containerSize = self.AlphaContainer.AbsoluteSize
    local mousePos = input.Position.Y
    
    -- Calculate alpha (1 at top, 0 at bottom)
    local alpha = 1 - ((mousePos - containerPos.Y) / containerSize.Height)
    alpha = math.clamp(alpha, 0, 1)
    
    self.Alpha = alpha
    self.Preview.BackgroundTransparency = 1 - alpha
    
    -- Update alpha gradient
    if self.AlphaGradient then
        local gradient = self.AlphaGradient:FindFirstChildOfClass("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new(self.Color)
        end
    end
    
    -- Update selector position
    self.AlphaSelector.Position = UDim2.new(0, -2, 1 - alpha, 0)
    
    -- Call callback
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.Color, self.Alpha)
    end
end

function ColorPicker:_updateFromRGB()
    local r = tonumber(self.RInput.Text) or 0
    local g = tonumber(self.GInput.Text) or 0
    local b = tonumber(self.BInput.Text) or 0
    
    r = math.clamp(r, 0, 255)
    g = math.clamp(g, 0, 255)
    b = math.clamp(b, 0, 255)
    
    local newColor = Color3.fromRGB(r, g, b)
    self:SetColor(newColor)
end

function ColorPicker:_updateInputs()
    -- Update RGB inputs
    self.RInput.Text = tostring(math.floor(self.Color.R * 255))
    self.GInput.Text = tostring(math.floor(self.Color.G * 255))
    self.BInput.Text = tostring(math.floor(self.Color.B * 255))
    
    -- Update hex input
    self.HexInput.Text = Color3ToHex(self.Color)
    
    -- Update preview
    self.Preview.BackgroundColor3 = self.Color
    
    -- Update alpha gradient if exists
    if self.AlphaGradient then
        local gradient = self.AlphaGradient:FindFirstChildOfClass("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new(self.Color)
        end
    end
end

function ColorPicker:SetColor(color, alpha, noCallback)
    self.Color = color
    self.Alpha = alpha or self.Alpha
    
    -- Update preview transparency
    self.Preview.BackgroundTransparency = 1 - self.Alpha
    
    -- Calculate HSV
    local h, s, v = Color3ToHSV(self.Color)
    
    -- Update wheel selector position
    local angle = h * 2 * math.pi - math.pi
    local distance = s / 2
    
    local selectorX = 0.5 + math.cos(angle) * distance
    local selectorY = 0.5 + math.sin(angle) * distance
    
    self.WheelSelector.Position = UDim2.new(selectorX, -6, selectorY, -6)
    
    -- Update hue selector position
    self.HueSelector.Position = UDim2.new(0, -2, h, 0)
    
    -- Update alpha selector position
    if self.AlphaSelector then
        self.AlphaSelector.Position = UDim2.new(0, -2, 1 - self.Alpha, 0)
    end
    
    -- Update inputs
    self:_updateInputs()
    
    -- Add to recent colors
    self:_addToRecent(color)
    
    -- Call callback if not suppressed
    if not noCallback and self.Config.Callback then
        task.spawn(self.Config.Callback, color, self.Alpha)
    end
end

function ColorPicker:_addToRecent(color)
    -- Remove if already exists
    for i, recentColor in ipairs(self.RecentColors) do
        if recentColor == color then
            table.remove(self.RecentColors, i)
            break
        end
    end
    
    -- Add to beginning
    table.insert(self.RecentColors, 1, color)
    
    -- Trim if too many
    if #self.RecentColors > self.MaxRecent then
        table.remove(self.RecentColors, self.MaxRecent + 1)
    end
end

function ColorPicker:GetColor()
    return self.Color, self.Alpha
end

function ColorPicker:SetLabel(text)
    self.Config.Name = text
    self.Label.Text = text
end

function ColorPicker:SetPresets(presets)
    self.Presets = presets or {}
    
    -- Update preset buttons
    if self.PresetButtons then
        for i, button in ipairs(self.PresetButtons) do
            button:Destroy()
        end
        self.PresetButtons = {}
    end
    
    if self.PresetsContainer and #self.Presets > 0 then
        for i, presetColor in ipairs(self.Presets) do
            local presetButton = Instance.new("Frame")
            presetButton.Name = "Preset_" .. i
            presetButton.BackgroundColor3 = presetColor
            presetButton.BackgroundTransparency = 0
            presetButton.Size = UDim2.new(0, 20, 0, 20)
            presetButton.Position = UDim2.new(0, (i - 1) * 25, 0, 20)
            
            local presetCorner = Instance.new("UICorner")
            presetCorner.CornerRadius = UDim.new(0, 4)
            presetCorner.Parent = presetButton
            
            local presetStroke = Instance.new("UIStroke")
            presetStroke.Color = Color3.new(0, 0, 0)
            presetStroke.Transparency = 0.5
            presetStroke.Thickness = 1
            presetStroke.Parent = presetButton
            
            presetButton.Parent = self.PresetsContainer
            
            presetButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    self:SetColor(presetColor)
                end
            end)
            
            table.insert(self.PresetButtons, presetButton)
        end
    end
end

function ColorPicker:ShowAlpha(show)
    self.Config.ShowAlpha = show
    
    if self.AlphaContainer then
        self.AlphaContainer.Visible = show
    end
end

function ColorPicker:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return ColorPicker