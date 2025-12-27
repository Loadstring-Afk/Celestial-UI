-- Premium toggle/switch component with smooth animations

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(config, parent, theme, animations)
    local self = setmetatable({}, Toggle)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    self.State = config.Default or false
    self.Debounce = false
    
    self:_createToggle()
    self:_setupEvents()
    
    -- Set initial state
    self:SetState(self.State, true)
    
    return self
end

function Toggle:_createToggle()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialToggle"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.Parent = self.Parent
    
    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(0.7, -10, 1, 0)
    self.Label.Position = UDim2.new(0, 0, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Name or "Toggle"
    self.Label.TextColor3 = self.Theme:GetColor("Toggle", "Text")
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Container
    
    -- Toggle container
    self.ToggleContainer = Instance.new("Frame")
    self.ToggleContainer.Name = "ToggleContainer"
    self.ToggleContainer.BackgroundColor3 = self.Theme:GetColor("Toggle", "Background")
    self.ToggleContainer.BackgroundTransparency = 0.1
    self.ToggleContainer.Size = UDim2.new(0, 50, 0, 24)
    self.ToggleContainer.Position = UDim2.new(1, -50, 0.5, -12)
    self.ToggleContainer.AnchorPoint = Vector2.new(1, 0.5)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = self.ToggleContainer
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme:GetColor("Toggle", "OffColor")
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = self.ToggleContainer
    
    self.ToggleContainer.Parent = self.Container
    
    -- Toggle knob
    self.Knob = Instance.new("Frame")
    self.Knob.Name = "Knob"
    self.Knob.BackgroundColor3 = self.Theme:GetColor("Toggle", "Knob")
    self.Knob.BackgroundTransparency = 0
    self.Knob.Size = UDim2.new(0, 20, 0, 20)
    self.Knob.Position = UDim2.new(0, 2, 0.5, -10)
    self.Knob.AnchorPoint = Vector2.new(0, 0.5)
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = self.Knob
    
    local knobShadow = Instance.new("UIStroke")
    knobShadow.Color = Color3.new(0, 0, 0)
    knobShadow.Transparency = 0.7
    knobShadow.Thickness = 1
    knobShadow.Parent = self.Knob
    
    self.Knob.Parent = self.ToggleContainer
    
    -- Icon (optional)
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 14, 0, 14)
        self.Icon.Position = UDim2.new(0, 8, 0.5, -7)
        self.Icon.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.Theme:GetColor("Toggle", "Text")
        self.Icon.ImageTransparency = 0.3
        self.Icon.Visible = false
        self.Icon.Parent = self.Container
    end
    
    -- Description (optional)
    if self.Config.Description then
        self.Description = Instance.new("TextLabel")
        self.Description.Name = "Description"
        self.Description.BackgroundTransparency = 1
        self.Description.Size = UDim2.new(0.7, -10, 0.5, 0)
        self.Description.Position = UDim2.new(0, 0, 0.5, 0)
        self.Description.Font = Enum.Font.Gotham
        self.Description.Text = self.Config.Description
        self.Description.TextColor3 = self.Theme:GetColor("Toggle", "Text")
        self.Description.TextTransparency = 0.3
        self.Description.TextSize = 12
        self.Description.TextXAlignment = Enum.TextXAlignment.Left
        self.Description.Parent = self.Container
        
        -- Adjust label position
        self.Label.Size = UDim2.new(0.7, -10, 0.5, 0)
    end
end

function Toggle:_setupEvents()
    -- Click on container
    self.Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onPress()
        end
    end)
    
    -- Click on toggle specifically
    self.ToggleContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onPress()
        end
    end)
    
    -- Hover effects
    self.Container.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.Container.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
end

function Toggle:_onPress()
    if self.Debounce then return end
    self.Debounce = true
    
    -- Toggle state
    self:SetState(not self.State)
    
    -- Call callback
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.State)
    end
    
    -- Visual feedback
    self:_createRipple()
    
    -- Debounce
    task.wait(0.2)
    self.Debounce = false
end

function Toggle:_onHover(enter)
    if enter then
        self.Animations:Animate(self.ToggleContainer, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        if self.Icon then
            self.Animations:Animate(self.Icon, {
                ImageTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    else
        self.Animations:Animate(self.ToggleContainer, {
            BackgroundTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        if self.Icon then
            self.Animations:Animate(self.Icon, {
                ImageTransparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end
end

function Toggle:_createRipple()
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = self.State and self.Theme:GetColor("Toggle", "OnColor") or 
                              self.Theme:GetColor("Toggle", "OffColor")
    ripple.BackgroundTransparency = 0.7
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = -1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    ripple.Parent = self.ToggleContainer
    
    -- Animate ripple
    self.Animations:Animate(ripple, {
        Size = UDim2.new(2, 0, 2, 0),
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

function Toggle:SetState(state, instant)
    self.State = state
    
    local targetPosition = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    local targetColor = state and self.Theme:GetColor("Toggle", "OnColor") or 
                       self.Theme:GetColor("Toggle", "OffColor")
    
    if instant then
        self.Knob.Position = targetPosition
        self.ToggleContainer.UIStroke.Color = targetColor
    else
        -- Animate knob movement
        self.Animations:Animate(self.Knob, {
            Position = targetPosition
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        -- Animate color change
        self.Animations:Animate(self.ToggleContainer.UIStroke, {
            Color = targetColor
        }, {
            Style = "Fluid",
            Duration = 0.3
        })
        
        -- Pulse effect
        self.Animations:Animate(self.Knob, {
            Size = UDim2.new(0, 22, 0, 22)
        }, {
            Style = "Elastic",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.Knob, {
            Size = UDim2.new(0, 20, 0, 20)
        }, {
            Style = "Spring",
            Duration = 0.2,
            Delay = 0.2
        })
    end
    
    -- Update icon visibility
    if self.Icon then
        self.Icon.Visible = state
        self.Animations:Animate(self.Icon, {
            ImageTransparency = state and 0.1 or 0.3
        }, {
            Style = "Fluid",
            Duration = 0.3
        })
    end
end

function Toggle:GetState()
    return self.State
end

function Toggle:Toggle()
    self:SetState(not self.State)
    
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.State)
    end
end

function Toggle:SetText(text)
    self.Config.Name = text
    self.Label.Text = text
end

function Toggle:SetDescription(description)
    self.Config.Description = description
    
    if description then
        if not self.Description then
            self.Description = Instance.new("TextLabel")
            self.Description.Name = "Description"
            self.Description.BackgroundTransparency = 1
            self.Description.Size = UDim2.new(0.7, -10, 0.5, 0)
            self.Description.Position = UDim2.new(0, 0, 0.5, 0)
            self.Description.Font = Enum.Font.Gotham
            self.Description.TextColor3 = self.Theme:GetColor("Toggle", "Text")
            self.Description.TextTransparency = 0.3
            self.Description.TextSize = 12
            self.Description.TextXAlignment = Enum.TextXAlignment.Left
            self.Description.Parent = self.Container
            
            self.Label.Size = UDim2.new(0.7, -10, 0.5, 0)
        end
        
        self.Description.Text = description
    elseif self.Description then
        self.Description:Destroy()
        self.Description = nil
        self.Label.Size = UDim2.new(0.7, -10, 1, 0)
    end
end

function Toggle:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Toggle:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Toggle