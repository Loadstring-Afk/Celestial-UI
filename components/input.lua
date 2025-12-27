-- Premium text input component with validation and masked input

local Input = {}
Input.__index = Input

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

function Input.new(config, parent, theme, animations)
    local self = setmetatable({}, Input)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Value = config.Default or ""
    self.Focused = false
    self.ValidationError = nil
    self.Masked = config.Masked or false
    self.Numeric = config.Numeric or false
    
    self:_createInput()
    self:_setupEvents()
    
    -- Set initial value
    if self.Value ~= "" then
        self:SetValue(self.Value, true)
    end
    
    return self
end

function Input:_createInput()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialInput"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 50)
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
    self.Label.Size = UDim2.new(0.5, 0, 1, 0)
    self.Label.Position = UDim2.new(0, 0, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Name or "Input"
    self.Label.TextColor3 = self.Theme:GetColor("Input", "Text")
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Header
    
    -- Character counter (optional)
    if self.Config.MaxLength then
        self.Counter = Instance.new("TextLabel")
        self.Counter.Name = "Counter"
        self.Counter.BackgroundTransparency = 1
        self.Counter.Size = UDim2.new(0.5, 0, 1, 0)
        self.Counter.Position = UDim2.new(0.5, 0, 0, 0)
        self.Counter.Font = Enum.Font.Gotham
        self.Counter.Text = "0/" .. self.Config.MaxLength
        self.Counter.TextColor3 = self.Theme:GetColor("Input", "Text")
        self.Counter.TextTransparency = 0.3
        self.Counter.TextSize = 12
        self.Counter.TextXAlignment = Enum.TextXAlignment.Right
        self.Counter.Parent = self.Header
    end
    
    -- Input field container
    self.InputContainer = Instance.new("Frame")
    self.InputContainer.Name = "InputContainer"
    self.InputContainer.BackgroundColor3 = self.Theme:GetColor("Input", "Background")
    self.InputContainer.BackgroundTransparency = 0.1
    self.InputContainer.Size = UDim2.new(1, 0, 0, 40)
    self.InputContainer.Position = UDim2.new(0, 0, 0, 25)
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = self.InputContainer
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = self.Theme:GetColor("Input", "Stroke")
    containerStroke.Transparency = 0.3
    containerStroke.Thickness = 1
    containerStroke.Parent = self.InputContainer
    
    self.InputContainer.Parent = self.Container
    
    -- Icon (optional)
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 20, 0, 20)
        self.Icon.Position = UDim2.new(0, 10, 0.5, -10)
        self.Icon.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.Theme:GetColor("Input", "Text")
        self.Icon.ImageTransparency = 0.3
        self.Icon.Parent = self.InputContainer
    end
    
    -- Text input
    self.TextBox = Instance.new("TextBox")
    self.TextBox.Name = "TextBox"
    self.TextBox.BackgroundTransparency = 1
    self.TextBox.Size = UDim2.new(1, self.Config.Icon and -40 or -20, 1, 0)
    self.TextBox.Position = UDim2.new(0, self.Config.Icon and 40 : 10, 0, 0)
    self.TextBox.Font = Enum.Font.Gotham
    self.TextBox.PlaceholderText = self.Config.Placeholder or "Enter text..."
    self.TextBox.PlaceholderColor3 = self.Theme:GetColor("Input", "Placeholder")
    self.TextBox.TextColor3 = self.Theme:GetColor("Input", "Text")
    self.TextBox.TextSize = 14
    self.TextBox.TextXAlignment = Enum.TextXAlignment.Left
    self.TextBox.Text = ""
    self.TextBox.ClearTextOnFocus = false
    
    -- Set text properties
    if self.Masked then
        self.TextBox.TextTransparency = 0
        self:_createMaskedDisplay()
    end
    
    if self.Numeric then
        self.TextBox.Text = ""
    end
    
    self.TextBox.Parent = self.InputContainer
    
    -- Clear button (optional)
    if self.Config.Clearable then
        self.ClearButton = Instance.new("ImageButton")
        self.ClearButton.Name = "Clear"
        self.ClearButton.BackgroundTransparency = 1
        self.ClearButton.Size = UDim2.new(0, 20, 0, 20)
        self.ClearButton.Position = UDim2.new(1, -30, 0.5, -10)
        self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
        self.ClearButton.Image = "rbxassetid://7072720899" -- X icon
        self.ClearButton.ImageColor3 = self.Theme:GetColor("Input", "Text")
        self.ClearButton.ImageTransparency = 0.5
        self.ClearButton.Visible = false
        self.ClearButton.Parent = self.InputContainer
    end
    
    -- Validation error display
    self.ErrorLabel = Instance.new("TextLabel")
    self.ErrorLabel.Name = "Error"
    self.ErrorLabel.BackgroundTransparency = 1
    self.ErrorLabel.Size = UDim2.new(1, 0, 0, 16)
    self.ErrorLabel.Position = UDim2.new(0, 0, 1, 0)
    self.ErrorLabel.Font = Enum.Font.Gotham
    self.ErrorLabel.Text = ""
    self.ErrorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    self.ErrorLabel.TextTransparency = 1
    self.ErrorLabel.TextSize = 12
    self.ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.ErrorLabel.Parent = self.Container
    
    -- Focus indicator (animated line)
    self.FocusLine = Instance.new("Frame")
    self.FocusLine.Name = "FocusLine"
    self.FocusLine.BackgroundColor3 = self.Theme:GetColor("Input", "Cursor")
    self.FocusLine.BackgroundTransparency = 0.7
    self.FocusLine.Size = UDim2.new(1, 0, 0, 2)
    self.FocusLine.Position = UDim2.new(0, 0, 1, 0)
    self.FocusLine.AnchorPoint = Vector2.new(0, 1)
    self.FocusLine.Visible = false
    self.FocusLine.Parent = self.InputContainer
end

function Input:_createMaskedDisplay()
    -- Create display for masked text (like password fields)
    self.MaskedDisplay = Instance.new("TextLabel")
    self.MaskedDisplay.Name = "MaskedDisplay"
    self.MaskedDisplay.BackgroundTransparency = 1
    self.MaskedDisplay.Size = UDim2.new(1, 0, 1, 0)
    self.MaskedDisplay.Position = UDim2.new(0, 0, 0, 0)
    self.MaskedDisplay.Font = Enum.Font.Gotham
    self.MaskedDisplay.TextColor3 = self.Theme:GetColor("Input", "Text")
    self.MaskedDisplay.TextSize = 14
    self.MaskedDisplay.TextXAlignment = Enum.TextXAlignment.Left
    self.MaskedDisplay.Text = string.rep("•", #self.Value)
    self.MaskedDisplay.Visible = false
    self.MaskedDisplay.Parent = self.InputContainer
    
    -- Hide actual text
    self.TextBox.TextTransparency = 1
end

function Input:_setupEvents()
    -- Focus events
    self.TextBox.Focused:Connect(function()
        self:Focus()
    end)
    
    self.TextBox.FocusLost:Connect(function(enterPressed)
        self:Blur(enterPressed)
    end)
    
    -- Text changed
    self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_onTextChanged()
    end)
    
    -- Clear button
    if self.ClearButton then
        self.ClearButton.MouseButton1Click:Connect(function()
            self:Clear()
        end)
    end
    
    -- Input container click to focus
    self.InputContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.TextBox:CaptureFocus()
        end
    end)
    
    -- Hover effects
    self.InputContainer.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.InputContainer.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
    
    -- Numeric validation
    if self.Numeric then
        self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = self.TextBox.Text
            if text ~= "" and not tonumber(text) then
                -- Remove non-numeric characters
                local numeric = text:gsub("[^%d%.%-]", "")
                self.TextBox.Text = numeric
            end
        end)
    end
end

function Input:_onTextChanged()
    local text = self.TextBox.Text
    
    -- Handle masked input
    if self.Masked then
        if self.MaskedDisplay then
            self.MaskedDisplay.Text = string.rep("•", #text)
            
            -- Show last character briefly
            if #text > #self.Value then
                local lastChar = text:sub(#text, #text)
                self.MaskedDisplay.Text = string.rep("•", #text - 1) .. lastChar
                
                task.delay(0.5, function()
                    if self.MaskedDisplay then
                        self.MaskedDisplay.Text = string.rep("•", #text)
                    end
                end)
            end
        end
    end
    
    -- Update value
    self.Value = text
    
    -- Update character counter
    if self.Counter then
        self.Counter.Text = string.format("%d/%d", #text, self.Config.MaxLength)
        
        -- Change color when near limit
        if #text > self.Config.MaxLength * 0.9 then
            self.Counter.TextColor3 = Color3.fromRGB(255, 120, 80)
        else
            self.Counter.TextColor3 = self.Theme:GetColor("Input", "Text")
        end
    end
    
    -- Show/hide clear button
    if self.ClearButton then
        self.ClearButton.Visible = #text > 0
    end
    
    -- Validate if needed
    if self.Config.Validate and not self.Focused then
        self:Validate()
    end
    
    -- Call change callback
    if self.Config.OnChange then
        task.spawn(self.Config.OnChange, text)
    end
end

function Input:_onHover(enter)
    if enter then
        self.Animations:Animate(self.InputContainer, {
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
        if not self.Focused then
            self.Animations:Animate(self.InputContainer, {
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
end

function Input:Focus()
    if self.Focused then return end
    
    self.Focused = true
    
    -- Visual feedback
    self.FocusLine.Visible = true
    self.Animations:Animate(self.FocusLine, {
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 2)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    self.Animations:Animate(self.InputContainer.UIStroke, {
        Color = self.Theme:GetColor("Input", "Cursor"),
        Transparency = 0.1
    }, {
        Style = "Fluid",
        Duration = 0.2
    })
    
    -- Show masked display if needed
    if self.Masked and self.MaskedDisplay then
        self.MaskedDisplay.Visible = true
    end
    
    -- Call focus callback
    if self.Config.OnFocus then
        task.spawn(self.Config.OnFocus)
    end
end

function Input:Blur(enterPressed)
    if not self.Focused then return end
    
    self.Focused = false
    
    -- Visual feedback
    self.Animations:Animate(self.FocusLine, {
        BackgroundTransparency = 0.7,
        Size = UDim2.new(0, 0, 0, 2)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    task.delay(0.3, function()
        if self.FocusLine then
            self.FocusLine.Visible = false
        end
    end)
    
    self.Animations:Animate(self.InputContainer.UIStroke, {
        Color = self.Theme:GetColor("Input", "Stroke"),
        Transparency = 0.3
    }, {
        Style = "Fluid",
        Duration = 0.2
    })
    
    -- Hide masked display if needed
    if self.Masked and self.MaskedDisplay then
        self.MaskedDisplay.Visible = false
    end
    
    -- Validate
    self:Validate()
    
    -- Call blur callback
    if self.Config.OnBlur then
        task.spawn(self.Config.OnBlur, enterPressed)
    end
    
    -- Call submit callback on enter
    if enterPressed and self.Config.OnSubmit then
        task.spawn(self.Config.OnSubmit, self.Value)
    end
end

function Input:Validate()
    if not self.Config.Validate then return true end
    
    local success, errorMessage = self.Config.Validate(self.Value)
    
    if success then
        self:ClearError()
        return true
    else
        self:SetError(errorMessage or "Invalid input")
        return false
    end
end

function Input:SetError(message)
    self.ValidationError = message
    self.ErrorLabel.Text = message
    
    -- Animate error display
    self.ErrorLabel.TextTransparency = 0
    self.Animations:Animate(self.ErrorLabel, {
        TextTransparency = 0
    }, {
        Style = "Fluid",
        Duration = 0.3
    })
    
    -- Visual feedback on input
    self.Animations:Animate(self.InputContainer.UIStroke, {
        Color = Color3.fromRGB(255, 80, 80),
        Transparency = 0.1
    }, {
        Style = "Spring",
        Duration = 0.3
    })
end

function Input:ClearError()
    if not self.ValidationError then return end
    
    self.ValidationError = nil
    
    -- Animate out error
    self.Animations:Animate(self.ErrorLabel, {
        TextTransparency = 1
    }, {
        Style = "Fluid",
        Duration = 0.3
    })
    
    -- Restore normal stroke color
    if not self.Focused then
        self.Animations:Animate(self.InputContainer.UIStroke, {
            Color = self.Theme:GetColor("Input", "Stroke"),
            Transparency = 0.3
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end
end

function Input:SetValue(value, noCallback)
    self.Value = tostring(value)
    
    if self.Masked then
        if self.MaskedDisplay then
            self.MaskedDisplay.Text = string.rep("•", #self.Value)
        end
        self.TextBox.Text = self.Value
    else
        self.TextBox.Text = self.Value
    end
    
    -- Update counter
    if self.Counter then
        self.Counter.Text = string.format("%d/%d", #self.Value, self.Config.MaxLength)
    end
    
    -- Show/hide clear button
    if self.ClearButton then
        self.ClearButton.Visible = #self.Value > 0
    end
    
    -- Call callback if not suppressed
    if not noCallback and self.Config.OnChange then
        task.spawn(self.Config.OnChange, self.Value)
    end
end

function Input:GetValue()
    return self.Value
end

function Input:Clear()
    self:SetValue("")
    self:ClearError()
    
    if self.TextBox then
        self.TextBox:CaptureFocus()
    end
end

function Input:SetPlaceholder(text)
    self.Config.Placeholder = text
    self.TextBox.PlaceholderText = text
end

function Input:SetLabel(text)
    self.Config.Name = text
    self.Label.Text = text
end

function Input:SetEnabled(enabled)
    self.TextBox.Active = enabled
    self.TextBox.TextTransparency = enabled and (self.Masked and 1 or 0) or 0.5
    
    if self.MaskedDisplay then
        self.MaskedDisplay.TextTransparency = enabled and 0 or 0.5
    end
    
    self.InputContainer.BackgroundTransparency = enabled and 0.1 or 0.3
end

function Input:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Input:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Input