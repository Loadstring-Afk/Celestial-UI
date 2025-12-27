-- Premium button component with ripple effects and fluid animations

local Button = {}
Button.__index = Button

function Button.new(config, parent, theme, animations)
    local self = setmetatable({}, Button)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    self.Ripples = {}
    
    self:_createButton()
    self:_setupEvents()
    
    return self
end

function Button:_createButton()
    -- Main button frame
    self.Button = Instance.new("Frame")
    self.Button.Name = "CelestialButton"
    self.Button.BackgroundColor3 = self.Theme:GetColor("Button", "Background")
    self.Button.BackgroundTransparency = 0.1
    self.Button.Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    self.Button.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.Button
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme:GetColor("Button", "Stroke")
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = self.Button
    
    -- Gradient (optional)
    if self.Config.Gradient then
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, self.Theme:GetColor("Button", "GradientStart")),
            ColorSequenceKeypoint.new(1, self.Theme:GetColor("Button", "GradientEnd"))
        }
        gradient.Rotation = 90
        gradient.Parent = self.Button
    end
    
    -- Content container
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, 0, 1, 0)
    self.Content.Parent = self.Button
    
    -- Icon (optional)
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 20, 0, 20)
        self.Icon.Position = UDim2.new(0, 10, 0.5, -10)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.Theme:GetColor("Button", "Icon")
        self.Icon.Parent = self.Content
    end
    
    -- Text label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(1, self.Config.Icon and -40 or -20, 1, 0)
    self.Label.Position = UDim2.new(0, self.Config.Icon and 40 or 10, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Text or "Button"
    self.Label.TextColor3 = self.Theme:GetColor("Button", "Text")
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Content
    
    -- Loading spinner (hidden by default)
    self.Spinner = Instance.new("Frame")
    self.Spinner.Name = "Spinner"
    self.Spinner.BackgroundTransparency = 1
    self.Spinner.Size = UDim2.new(0, 20, 0, 20)
    self.Spinner.Position = UDim2.new(1, -30, 0.5, -10)
    self.Spinner.AnchorPoint = Vector2.new(1, 0.5)
    self.Spinner.Visible = false
    self.Spinner.Parent = self.Content
    
    for i = 1, 8 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.BackgroundColor3 = self.Theme:GetColor("Button", "Text")
        dot.Size = UDim2.new(0, 2, 0, 2)
        dot.Position = UDim2.new(0.5, -1, 0.5, -1)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        dot.Parent = self.Spinner
    end
    
    self.Button.Parent = self.Parent
end

function Button:_setupEvents()
    local UserInputService = game:GetService("UserInputService")
    
    -- Mouse/touch events
    self.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onPress(input)
        end
    end)
    
    self.Button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onRelease(input)
        end
    end)
    
    -- Hover effects
    self.Button.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.Button.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
    
    -- Long press detection
    self.LongPressThreshold = 0.5
    self.PressStartTime = nil
    
    self.Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.PressStartTime = tick()
            
            task.spawn(function()
                task.wait(self.LongPressThreshold)
                if self.PressStartTime and tick() - self.PressStartTime >= self.LongPressThreshold then
                    self:_onLongPress(input)
                end
            end)
        end
    end)
    
    self.Button.InputEnded:Connect(function(input)
        self.PressStartTime = nil
    end)
end

function Button:_onPress(input)
    -- Visual feedback
    self.Animations:Animate(self.Button, {
        BackgroundTransparency = 0,
        Size = self.Button.Size * UDim2.new(0.98, 0, 0.95, 0)
    }, {
        Style = "Spring",
        Duration = 0.1
    })
    
    -- Create ripple
    self:_createRipple(input.Position)
    
    -- Call callback
    if self.Config.Callback then
        task.spawn(self.Config.Callback)
    end
end

function Button:_onRelease(input)
    self.Animations:Animate(self.Button, {
        BackgroundTransparency = 0.1,
        Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    }, {
        Style = "Spring",
        Duration = 0.2
    })
end

function Button:_onHover(enter)
    if enter then
        self.Animations:Animate(self.Button, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        self.Animations:Animate(self.Button, {
            BackgroundTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end
end

function Button:_onLongPress(input)
    -- Long press action
    if self.Config.LongPressCallback then
        self.Config.LongPressCallback()
        
        -- Visual feedback
        self.Animations:WaterRipple(
            Vector2.new(self.Button.AbsolutePosition.X + self.Button.AbsoluteSize.X / 2,
                       self.Button.AbsolutePosition.Y + self.Button.AbsoluteSize.Y / 2),
            self.Button,
            {Color = Color3.fromRGB(255, 255, 255), Size = 50}
        )
    end
end

function Button:_createRipple(position)
    local relativePosition = Vector2.new(
        (position.X - self.Button.AbsolutePosition.X) / self.Button.AbsoluteSize.X,
        (position.Y - self.Button.AbsolutePosition.Y) / self.Button.AbsoluteSize.Y
    )
    
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.8
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(relativePosition.X, 0, relativePosition.Y, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = -1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    ripple.Parent = self.Button
    
    -- Animate ripple
    self.Animations:Animate(ripple, {
        Size = UDim2.new(2, 0, 2, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(relativePosition.X, 0, relativePosition.Y, 0)
    }, {
        Style = "Wave",
        Duration = 0.6
    })
    
    -- Cleanup
    task.delay(0.7, function()
        if ripple then
            ripple:Destroy()
        end
    end)
    
    table.insert(self.Ripples, ripple)
end

function Button:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder - would integrate with the icon module
    return iconName
end

function Button:SetLoading(loading)
    if loading then
        self.Spinner.Visible = true
        self.Label.Text = self.Config.LoadingText or "Loading..."
        
        -- Animate spinner
        self:_animateSpinner()
    else
        self.Spinner.Visible = false
        self.Label.Text = self.Config.Text or "Button"
    end
end

function Button:_animateSpinner()
    if not self.Spinner or not self.Spinner.Visible then return end
    
    local dots = self.Spinner:GetChildren()
    local angleStep = 360 / #dots
    
    for i, dot in ipairs(dots) do
        if dot:IsA("Frame") then
            local angle = math.rad(angleStep * (i - 1))
            local radius = 8
            
            self.Animations:Animate(dot, {
                Position = UDim2.new(
                    0.5 + math.cos(angle) * (radius / 20),
                    0,
                    0.5 + math.sin(angle) * (radius / 20),
                    0
                )
            }, {
                Style = "Fluid",
                Duration = 0.5,
                Delay = (i - 1) * 0.05
            })
        end
    end
end

function Button:SetText(text)
    self.Config.Text = text
    self.Label.Text = text
end

function Button:SetEnabled(enabled)
    self.Button.Active = enabled
    self.Button.BackgroundTransparency = enabled and 0.1 or 0.5
    
    if enabled then
        self.Label.TextColor3 = self.Theme:GetColor("Button", "Text")
    else
        self.Label.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

function Button:Destroy()
    if self.Button then
        self.Button:Destroy()
    end
end

return Button