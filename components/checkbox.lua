-- Premium checkbox component with multi-state support

local Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox.new(config, parent, theme, animations)
    local self = setmetatable({}, Checkbox)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.State = config.Default or false
    self.Indeterminate = config.Indeterminate or false
    self.Debounce = false
    
    self:_createCheckbox()
    self:_setupEvents()
    
    -- Set initial state
    self:SetState(self.State, self.Indeterminate, true)
    
    return self
end

function Checkbox:_createCheckbox()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialCheckbox"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.Parent = self.Parent
    
    -- Checkbox container
    self.CheckboxContainer = Instance.new("Frame")
    self.CheckboxContainer.Name = "Checkbox"
    self.CheckboxContainer.BackgroundColor3 = self.Theme:GetColor("Checkbox", "Background") or Color3.fromRGB(50, 50, 55)
    self.CheckboxContainer.BackgroundTransparency = 0.1
    self.CheckboxContainer.Size = UDim2.new(0, 24, 0, 24)
    self.CheckboxContainer.Position = UDim2.new(0, 0, 0.5, -12)
    self.CheckboxContainer.AnchorPoint = Vector2.new(0, 0.5)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = self.CheckboxContainer
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme:GetColor("Checkbox", "Stroke") or Color3.fromRGB(70, 70, 75)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = self.CheckboxContainer
    
    self.CheckboxContainer.Parent = self.Container
    
    -- Check icon
    self.CheckIcon = Instance.new("ImageLabel")
    self.CheckIcon.Name = "Check"
    self.CheckIcon.BackgroundTransparency = 1
    self.CheckIcon.Size = UDim2.new(0, 16, 0, 16)
    self.CheckIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
    self.CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    self.CheckIcon.Image = "rbxassetid://7072718165" -- Check icon
    self.CheckIcon.ImageColor3 = self.Theme:GetColor("Checkbox", "Check") or Color3.fromRGB(240, 240, 245)
    self.CheckIcon.ImageTransparency = 1
    self.CheckIcon.Parent = self.CheckboxContainer
    
    -- Indeterminate icon (dash)
    self.IndeterminateIcon = Instance.new("Frame")
    self.IndeterminateIcon.Name = "Indeterminate"
    self.IndeterminateIcon.BackgroundColor3 = self.Theme:GetColor("Checkbox", "Check") or Color3.fromRGB(240, 240, 245)
    self.IndeterminateIcon.BackgroundTransparency = 1
    self.IndeterminateIcon.Size = UDim2.new(0, 12, 0, 2)
    self.IndeterminateIcon.Position = UDim2.new(0.5, -6, 0.5, -1)
    self.IndeterminateIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local indeterminateCorner = Instance.new("UICorner")
    indeterminateCorner.CornerRadius = UDim.new(1, 0)
    indeterminateCorner.Parent = self.IndeterminateIcon
    
    self.IndeterminateIcon.Parent = self.CheckboxContainer
    
    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(1, -40, 1, 0)
    self.Label.Position = UDim2.new(0, 40, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Name or "Checkbox"
    self.Label.TextColor3 = self.Theme:GetColor("Checkbox", "Text") or Color3.fromRGB(220, 220, 225)
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Container
    
    -- Description (optional)
    if self.Config.Description then
        self.Description = Instance.new("TextLabel")
        self.Description.Name = "Description"
        self.Description.BackgroundTransparency = 1
        self.Description.Size = UDim2.new(1, -40, 0.5, 0)
        self.Description.Position = UDim2.new(0, 40, 0.5, 0)
        self.Description.Font = Enum.Font.Gotham
        self.Description.Text = self.Config.Description
        self.Description.TextColor3 = self.Theme:GetColor("Checkbox", "Text")
        self.Description.TextTransparency = 0.3
        self.Description.TextSize = 12
        self.Description.TextXAlignment = Enum.TextXAlignment.Left
        self.Description.Parent = self.Container
        
        -- Adjust label position
        self.Label.Size = UDim2.new(1, -40, 0.5, 0)
    end
    
    -- Icon (optional)
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 16, 0, 16)
        self.Icon.Position = UDim2.new(0, 30, 0.5, -8)
        self.Icon.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.Theme:GetColor("Checkbox", "Text")
        self.Icon.ImageTransparency = 0.3
        self.Icon.Parent = self.Container
        
        -- Adjust label position
        self.Label.Position = UDim2.new(0, 60, 0, 0)
        self.Label.Size = UDim2.new(1, -60, self.Config.Description and 0.5 or 1, 0)
        
        if self.Description then
            self.Description.Position = UDim2.new(0, 60, 0.5, 0)
            self.Description.Size = UDim2.new(1, -60, 0.5, 0)
        end
    end
end

function Checkbox:_setupEvents()
    -- Click on container
    self.Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onClick()
        end
    end)
    
    -- Click on checkbox specifically
    self.CheckboxContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onClick()
        end
    end)
    
    -- Hover effects
    self.CheckboxContainer.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.CheckboxContainer.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
end

function Checkbox:_onClick()
    if self.Debounce then return end
    self.Debounce = true
    
    -- Cycle through states: false -> true -> indeterminate (if enabled) -> false
    if self.Indeterminate and self.Config.AllowIndeterminate then
        if self.State == false then
            self:SetState(true, false)
        elseif self.State == true and not self.Indeterminate then
            self:SetState(true, true)
        else
            self:SetState(false, false)
        end
    else
        -- Toggle between true/false
        self:SetState(not self.State, false)
    end
    
    -- Call callback
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.State, self.Indeterminate)
    end
    
    -- Visual feedback
    self:_createRipple()
    
    -- Debounce
    task.wait(0.2)
    self.Debounce = false
end

function Checkbox:_onHover(enter)
    if enter then
        self.Animations:Animate(self.CheckboxContainer, {
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
        self.Animations:Animate(self.CheckboxContainer, {
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

function Checkbox:_createRipple()
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = self.State and (self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255)) or 
                              self.Theme:GetColor("Checkbox", "Background") or Color3.fromRGB(50, 50, 55)
    ripple.BackgroundTransparency = 0.7
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = -1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = ripple
    
    ripple.Parent = self.CheckboxContainer
    
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

function Checkbox:SetState(state, indeterminate, instant)
    self.State = state
    self.Indeterminate = indeterminate or false
    
    if self.State then
        if self.Indeterminate then
            -- Indeterminate state (dash)
            if instant then
                self.CheckIcon.ImageTransparency = 1
                self.IndeterminateIcon.BackgroundTransparency = 0
                self.CheckboxContainer.BackgroundColor3 = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255)
                self.CheckboxContainer.UIStroke.Color = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255)
            else
                self.Animations:Animate(self.CheckIcon, {
                    ImageTransparency = 1
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.IndeterminateIcon, {
                    BackgroundTransparency = 0
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.CheckboxContainer, {
                    BackgroundColor3 = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255),
                    BackgroundTransparency = 0
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.CheckboxContainer.UIStroke, {
                    Color = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255),
                    Transparency = 0.1
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
            end
        else
            -- Checked state
            if instant then
                self.CheckIcon.ImageTransparency = 0
                self.IndeterminateIcon.BackgroundTransparency = 1
                self.CheckboxContainer.BackgroundColor3 = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255)
                self.CheckboxContainer.UIStroke.Color = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255)
            else
                self.Animations:Animate(self.CheckIcon, {
                    ImageTransparency = 0,
                    Rotation = 360
                }, {
                    Style = "Spring",
                    Duration = 0.3
                })
                
                self.Animations:Animate(self.IndeterminateIcon, {
                    BackgroundTransparency = 1
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.CheckboxContainer, {
                    BackgroundColor3 = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255),
                    BackgroundTransparency = 0
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.CheckboxContainer.UIStroke, {
                    Color = self.Theme:GetColor("Checkbox", "Checked") or Color3.fromRGB(80, 140, 255),
                    Transparency = 0.1
                }, {
                    Style = "Fluid",
                    Duration = 0.2
                })
                
                -- Bounce animation
                self.Animations:Animate(self.CheckboxContainer, {
                    Size = UDim2.new(0, 28, 0, 28)
                }, {
                    Style = "Spring",
                    Duration = 0.2
                })
                
                self.Animations:Animate(self.CheckboxContainer, {
                    Size = UDim2.new(0, 24, 0, 24)
                }, {
                    Style = "Spring",
                    Duration = 0.2,
                    Delay = 0.2
                })
            end
        end
    else
        -- Unchecked state
        if instant then
            self.CheckIcon.ImageTransparency = 1
            self.IndeterminateIcon.BackgroundTransparency = 1
            self.CheckboxContainer.BackgroundColor3 = self.Theme:GetColor("Checkbox", "Background") or Color3.fromRGB(50, 50, 55)
            self.CheckboxContainer.UIStroke.Color = self.Theme:GetColor("Checkbox", "Stroke") or Color3.fromRGB(70, 70, 75)
        else
            self.Animations:Animate(self.CheckIcon, {
                ImageTransparency = 1,
                Rotation = 0
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            self.Animations:Animate(self.IndeterminateIcon, {
                BackgroundTransparency = 1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            self.Animations:Animate(self.CheckboxContainer, {
                BackgroundColor3 = self.Theme:GetColor("Checkbox", "Background") or Color3.fromRGB(50, 50, 55),
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            self.Animations:Animate(self.CheckboxContainer.UIStroke, {
                Color = self.Theme:GetColor("Checkbox", "Stroke") or Color3.fromRGB(70, 70, 75),
                Transparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end
end

function Checkbox:GetState()
    return self.State, self.Indeterminate
end

function Checkbox:Toggle()
    if self.Indeterminate and self.Config.AllowIndeterminate then
        if self.State == false then
            self:SetState(true, false)
        elseif self.State == true and not self.Indeterminate then
            self:SetState(true, true)
        else
            self:SetState(false, false)
        end
    else
        self:SetState(not self.State, false)
    end
    
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.State, self.Indeterminate)
    end
end

function Checkbox:SetText(text)
    self.Config.Name = text
    self.Label.Text = text
end

function Checkbox:SetDescription(description)
    self.Config.Description = description
    
    if description then
        if not self.Description then
            self.Description = Instance.new("TextLabel")
            self.Description.Name = "Description"
            self.Description.BackgroundTransparency = 1
            self.Description.Size = UDim2.new(1, self.Config.Icon and -60 or -40, 0.5, 0)
            self.Description.Position = UDim2.new(0, self.Config.Icon and 60 or 40, 0.5, 0)
            self.Description.Font = Enum.Font.Gotham
            self.Description.TextColor3 = self.Theme:GetColor("Checkbox", "Text")
            self.Description.TextTransparency = 0.3
            self.Description.TextSize = 12
            self.Description.TextXAlignment = Enum.TextXAlignment.Left
            self.Description.Parent = self.Container
            
            self.Label.Size = UDim2.new(1, self.Config.Icon and -60 or -40, 0.5, 0)
        end
        
        self.Description.Text = description
    elseif self.Description then
        self.Description:Destroy()
        self.Description = nil
        self.Label.Size = UDim2.new(1, self.Config.Icon and -60 or -40, 1, 0)
    end
end

function Checkbox:SetEnabled(enabled)
    self.CheckboxContainer.Active = enabled
    self.Container.Active = enabled
    
    if enabled then
        self.Label.TextColor3 = self.Theme:GetColor("Checkbox", "Text") or Color3.fromRGB(220, 220, 225)
    else
        self.Label.TextColor3 = Color3.fromRGB(150, 150, 160)
        self.CheckboxContainer.BackgroundTransparency = 0.3
    end
end

function Checkbox:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Checkbox:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Checkbox