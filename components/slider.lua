-- Premium slider component with smooth dragging and fluid animations

local Slider = {}
Slider.__index = Slider

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

function Slider.new(config, parent, theme, animations)
    local self = setmetatable({}, Slider)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Default = config.Default or 50
    self.Increment = config.Increment or 1
    self.Value = self.Default
    self.Dragging = false
    
    self:_createSlider()
    self:_setupEvents()
    
    -- Set initial value
    self:SetValue(self.Value, true)
    
    return self
end

function Slider:_createSlider()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialSlider"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 60)
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
    self.Label.Text = self.Config.Name or "Slider"
    self.Label.TextColor3 = self.Theme:GetColor("Slider", "Text")
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Header
    
    -- Value display
    self.ValueLabel = Instance.new("TextLabel")
    self.ValueLabel.Name = "Value"
    self.ValueLabel.BackgroundTransparency = 1
    self.ValueLabel.Size = UDim2.new(0.3, 0, 1, 0)
    self.ValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    self.ValueLabel.Font = Enum.Font.Gotham
    self.ValueLabel.Text = tostring(self.Default)
    self.ValueLabel.TextColor3 = self.Theme:GetColor("Slider", "Value")
    self.ValueLabel.TextSize = 14
    self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueLabel.Parent = self.Header
    
    -- Slider track
    self.Track = Instance.new("Frame")
    self.Track.Name = "Track"
    self.Track.BackgroundColor3 = self.Theme:GetColor("Slider", "Background")
    self.Track.BackgroundTransparency = 0.1
    self.Track.Size = UDim2.new(1, 0, 0, 8)
    self.Track.Position = UDim2.new(0, 0, 0.5, -4)
    self.Track.AnchorPoint = Vector2.new(0, 0.5)
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = self.Track
    
    local trackStroke = Instance.new("UIStroke")
    trackStroke.Color = self.Theme:GetColor("Slider", "Background")
    trackStroke.Transparency = 0.5
    trackStroke.Thickness = 1
    trackStroke.Parent = self.Track
    
    self.Track.Parent = self.Container
    
    -- Fill
    self.Fill = Instance.new("Frame")
    self.Fill.Name = "Fill"
    self.Fill.BackgroundColor3 = self.Theme:GetColor("Slider", "Fill")
    self.Fill.BackgroundTransparency = 0
    self.Fill.Size = UDim2.new(0, 0, 0, 8)
    self.Fill.Position = UDim2.new(0, 0, 0.5, -4)
    self.Fill.AnchorPoint = Vector2.new(0, 0.5)
    self.Fill.ZIndex = 2
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = self.Fill
    
    -- Fill gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, self.Theme:GetColor("Slider", "Fill")),
        ColorSequenceKeypoint.new(1, self.Theme:_lightenColor(self.Theme:GetColor("Slider", "Fill"), 0.3))
    }
    gradient.Rotation = 90
    gradient.Parent = self.Fill
    
    self.Fill.Parent = self.Container
    
    -- Knob
    self.Knob = Instance.new("Frame")
    self.Knob.Name = "Knob"
    self.Knob.BackgroundColor3 = self.Theme:GetColor("Slider", "Knob")
    self.Knob.BackgroundTransparency = 0
    self.Knob.Size = UDim2.new(0, 20, 0, 20)
    self.Knob.Position = UDim2.new(0, 0, 0.5, -10)
    self.Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Knob.ZIndex = 3
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = self.Knob
    
    -- Knob glow
    local glow = Instance.new("UIStroke")
    glow.Color = self.Theme:GetColor("Slider", "Fill")
    glow.Transparency = 0.5
    glow.Thickness = 3
    glow.Parent = self.Knob
    
    -- Knob shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1.5, 0, 1.5, 0)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Image = "rbxassetid://8992231221" -- Soft shadow
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ZIndex = 2
    shadow.Parent = self.Knob
    
    self.Knob.Parent = self.Container
    
    -- Input field (optional)
    if self.Config.ShowInput then
        self.Input = Instance.new("TextBox")
        self.Input.Name = "Input"
        self.Input.BackgroundColor3 = self.Theme:GetColor("Input", "Background")
        self.Input.BackgroundTransparency = 0.1
        self.Input.Size = UDim2.new(0, 60, 0, 30)
        self.Input.Position = UDim2.new(1, -60, 0.5, -15)
        self.Input.AnchorPoint = Vector2.new(1, 0.5)
        self.Input.Font = Enum.Font.Gotham
        self.Input.Text = tostring(self.Default)
        self.Input.TextColor3 = self.Theme:GetColor("Input", "Text")
        self.Input.TextSize = 14
        self.Input.PlaceholderText = "Value"
        self.Input.ClearTextOnFocus = false
        
        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 6)
        inputCorner.Parent = self.Input
        
        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = self.Theme:GetColor("Input", "Stroke")
        inputStroke.Transparency = 0.3
        inputStroke.Thickness = 1
        inputStroke.Parent = self.Input
        
        self.Input.Parent = self.Container
        
        -- Input events
        self.Input.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local value = tonumber(self.Input.Text)
                if value then
                    self:SetValue(math.clamp(value, self.Min, self.Max))
                else
                    self.Input.Text = tostring(self.Value)
                end
            end
        end)
    end
    
    -- Description (optional)
    if self.Config.Description then
        self.Description = Instance.new("TextLabel")
        self.Description.Name = "Description"
        self.Description.BackgroundTransparency = 1
        self.Description.Size = UDim2.new(1, 0, 0, 16)
        self.Description.Position = UDim2.new(0, 0, 1, -16)
        self.Description.Font = Enum.Font.Gotham
        self.Description.Text = self.Config.Description
        self.Description.TextColor3 = self.Theme:GetColor("Slider", "Text")
        self.Description.TextTransparency = 0.3
        self.Description.TextSize = 12
        self.Description.TextXAlignment = Enum.TextXAlignment.Left
        self.Description.Parent = self.Container
    end
end

function Slider:_setupEvents()
    -- Track click
    self.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onTrackClick(input)
        end
    end)
    
    -- Knob drag
    self.Knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onDragStart(input)
        end
    end)
    
    -- Global input handling for drag
    self.DragConnection = UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            self:_onDrag(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onDragEnd()
        end
    end)
    
    -- Hover effects
    self.Track.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.Track.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
end

function Slider:_onTrackClick(input)
    local trackPosition = self.Track.AbsolutePosition
    local trackSize = self.Track.AbsoluteSize
    local clickX = input.Position.X - trackPosition.X
    
    -- Calculate value from click position
    local percentage = math.clamp(clickX / trackSize.X, 0, 1)
    local value = self.Min + (self.Max - self.Min) * percentage
    
    -- Snap to increment
    if self.Increment > 0 then
        value = math.floor(value / self.Increment) * self.Increment
    end
    
    self:SetValue(value)
    
    -- Call callback
    if self.Config.Callback then
        task.spawn(self.Config.Callback, value)
    end
end

function Slider:_onDragStart(input)
    self.Dragging = true
    self.DragStart = input.Position.X
    self.StartValue = self.Value
    
    -- Visual feedback
    self.Animations:Animate(self.Knob, {
        Size = UDim2.new(0, 24, 0, 24)
    }, {
        Style = "Spring",
        Duration = 0.2
    })
end

function Slider:_onDrag(input)
    if not self.Dragging then return end
    
    local trackPosition = self.Track.AbsolutePosition
    local trackSize = self.Track.AbsoluteSize
    local dragX = input.Position.X - trackPosition.X
    
    -- Calculate value from drag position
    local percentage = math.clamp(dragX / trackSize.X, 0, 1)
    local value = self.Min + (self.Max - self.Min) * percentage
    
    -- Snap to increment
    if self.Increment > 0 then
        value = math.floor(value / self.Increment) * self.Increment
    end
    
    self:SetValue(value, false, true)
    
    -- Call callback continuously if configured
    if self.Config.ContinuousCallback then
        task.spawn(self.Config.Callback, value)
    end
end

function Slider:_onDragEnd()
    if not self.Dragging then return end
    
    self.Dragging = false
    
    -- Visual feedback
    self.Animations:Animate(self.Knob, {
        Size = UDim2.new(0, 20, 0, 20)
    }, {
        Style = "Spring",
        Duration = 0.2
    })
    
    -- Call final callback
    if self.Config.Callback and not self.Config.ContinuousCallback then
        task.spawn(self.Config.Callback, self.Value)
    end
    
    -- Create ripple effect
    self:_createRipple()
end

function Slider:_onHover(enter)
    if enter then
        self.Animations:Animate(self.Track, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.Knob.UIStroke, {
            Thickness = 4
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        if not self.Dragging then
            self.Animations:Animate(self.Track, {
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            self.Animations:Animate(self.Knob.UIStroke, {
                Thickness = 3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end
end

function Slider:_createRipple()
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = self.Theme:GetColor("Slider", "Fill")
    ripple.BackgroundTransparency = 0.7
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    ripple.Parent = self.Knob
    
    -- Animate ripple
    self.Animations:Animate(ripple, {
        Size = UDim2.new(1.5, 0, 1.5, 0),
        BackgroundTransparency = 1
    }, {
        Style = "Wave",
        Duration = 0.5
    })
    
    -- Cleanup
    task.delay(0.6, function()
        if ripple then
            ripple:Destroy()
        end
    end)
end

function Slider:SetValue(value, instant, noCallback)
    -- Clamp value
    value = math.clamp(value, self.Min, self.Max)
    
    -- Snap to increment
    if self.Increment > 0 then
        value = math.floor(value / self.Increment) * self.Increment
    end
    
    self.Value = value
    
    -- Calculate percentage
    local percentage = (value - self.Min) / (self.Max - self.Min)
    
    -- Update visual elements
    local fillWidth = percentage * self.Track.AbsoluteSize.X
    local knobPosition = fillWidth
    
    if instant then
        self.Fill.Size = UDim2.new(0, fillWidth, 0, 8)
        self.Knob.Position = UDim2.new(0, knobPosition, 0.5, -10)
    else
        -- Animate fill
        self.Animations:Animate(self.Fill, {
            Size = UDim2.new(0, fillWidth, 0, 8)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        -- Animate knob
        self.Animations:Animate(self.Knob, {
            Position = UDim2.new(0, knobPosition, 0.5, -10)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
    end
    
    -- Update value label
    if self.ValueLabel then
        local displayValue = value
        
        -- Format based on suffix
        if self.Config.Suffix then
            self.ValueLabel.Text = string.format("%d%s", displayValue, self.Config.Suffix)
        else
            self.ValueLabel.Text = tostring(displayValue)
        end
    end
    
    -- Update input field if exists
    if self.Input then
        self.Input.Text = tostring(value)
    end
    
    -- Call callback if not suppressed
    if not noCallback and self.Config.Callback and not instant then
        task.spawn(self.Config.Callback, value)
    end
end

function Slider:GetValue()
    return self.Value
end

function Slider:SetRange(min, max)
    self.Min = min
    self.Max = max
    
    -- Clamp current value to new range
    self:SetValue(math.clamp(self.Value, min, max))
end

function Slider:SetText(text)
    self.Config.Name = text
    self.Label.Text = text
end

function Slider:SetDescription(description)
    self.Config.Description = description
    
    if description then
        if not self.Description then
            self.Description = Instance.new("TextLabel")
            self.Description.Name = "Description"
            self.Description.BackgroundTransparency = 1
            self.Description.Size = UDim2.new(1, 0, 0, 16)
            self.Description.Position = UDim2.new(0, 0, 1, -16)
            self.Description.Font = Enum.Font.Gotham
            self.Description.TextColor3 = self.Theme:GetColor("Slider", "Text")
            self.Description.TextTransparency = 0.3
            self.Description.TextSize = 12
            self.Description.TextXAlignment = Enum.TextXAlignment.Left
            self.Description.Parent = self.Container
        end
        
        self.Description.Text = description
    elseif self.Description then
        self.Description:Destroy()
        self.Description = nil
    end
end

function Slider:Destroy()
    if self.DragConnection then
        self.DragConnection:Disconnect()
    end
    
    if self.Container then
        self.Container:Destroy()
    end
end

return Slider