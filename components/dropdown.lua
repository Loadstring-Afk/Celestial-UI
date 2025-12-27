-- Premium dropdown component with search and multi-select support

local Dropdown = {}
Dropdown.__index = Dropdown

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

function Dropdown.new(config, parent, theme, animations)
    local self = setmetatable({}, Dropdown)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Options = config.Options or {}
    self.Default = config.Default or (config.MultiSelect and {} or self.Options[1])
    self.Value = self.Default
    self.Open = false
    self.SearchText = ""
    self.FilteredOptions = self.Options
    
    self:_createDropdown()
    self:_setupEvents()
    
    -- Set initial value
    if not config.MultiSelect then
        self:SetValue(self.Value, true)
    end
    
    return self
end

function Dropdown:_createDropdown()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialDropdown"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.ClipsDescendants = true
    self.Container.Parent = self.Parent
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.BackgroundColor3 = self.Theme:GetColor("Dropdown", "Background")
    self.Header.BackgroundTransparency = 0.1
    self.Header.Size = UDim2.new(1, 0, 0, 40)
    self.Header.Position = UDim2.new(0, 0, 0, 0)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = self.Header
    
    local headerStroke = Instance.new("UIStroke")
    headerStroke.Color = self.Theme:GetColor("Dropdown", "Stroke")
    headerStroke.Transparency = 0.3
    headerStroke.Thickness = 1
    headerStroke.Parent = self.Header
    
    self.Header.Parent = self.Container
    
    -- Label
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(0.7, -10, 1, 0)
    self.Label.Position = UDim2.new(0, 10, 0, 0)
    self.Label.Font = Enum.Font.Gotham
    self.Label.Text = self.Config.Name or "Dropdown"
    self.Label.TextColor3 = self.Theme:GetColor("Dropdown", "Text")
    self.Label.TextSize = 14
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.Parent = self.Header
    
    -- Value display
    self.ValueDisplay = Instance.new("TextLabel")
    self.ValueDisplay.Name = "ValueDisplay"
    self.ValueDisplay.BackgroundTransparency = 1
    self.ValueDisplay.Size = UDim2.new(0.5, -30, 1, 0)
    self.ValueDisplay.Position = UDim2.new(0.5, 0, 0, 0)
    self.ValueDisplay.Font = Enum.Font.Gotham
    self.ValueDisplay.Text = self.Config.Placeholder or "Select..."
    self.ValueDisplay.TextColor3 = self.Theme:GetColor("Dropdown", "Text")
    self.ValueDisplay.TextTransparency = 0.3
    self.ValueDisplay.TextSize = 14
    self.ValueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueDisplay.Parent = self.Header
    
    -- Chevron icon
    self.Chevron = Instance.new("ImageLabel")
    self.Chevron.Name = "Chevron"
    self.Chevron.BackgroundTransparency = 1
    self.Chevron.Size = UDim2.new(0, 16, 0, 16)
    self.Chevron.Position = UDim2.new(1, -30, 0.5, -8)
    self.Chevron.AnchorPoint = Vector2.new(1, 0.5)
    self.Chevron.Image = "rbxassetid://7072718165" -- Chevron down icon
    self.Chevron.ImageColor3 = self.Theme:GetColor("Dropdown", "Text")
    self.Chevron.ImageTransparency = 0.3
    self.Chevron.Parent = self.Header
    
    -- Clear button (for multi-select)
    if self.Config.MultiSelect then
        self.ClearButton = Instance.new("ImageButton")
        self.ClearButton.Name = "Clear"
        self.ClearButton.BackgroundTransparency = 1
        self.ClearButton.Size = UDim2.new(0, 20, 0, 20)
        self.ClearButton.Position = UDim2.new(1, -60, 0.5, -10)
        self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
        self.ClearButton.Image = "rbxassetid://7072720899" -- X icon
        self.ClearButton.ImageColor3 = self.Theme:GetColor("Dropdown", "Text")
        self.ClearButton.ImageTransparency = 0.5
        self.ClearButton.Visible = false
        self.ClearButton.Parent = self.Header
    end
    
    -- Dropdown list (hidden by default)
    self.ListContainer = Instance.new("Frame")
    self.ListContainer.Name = "ListContainer"
    self.ListContainer.BackgroundColor3 = self.Theme:GetColor("Dropdown", "Background")
    self.ListContainer.BackgroundTransparency = 0
    self.ListContainer.Size = UDim2.new(1, 0, 0, 0)
    self.ListContainer.Position = UDim2.new(0, 0, 1, 5)
    self.ListContainer.ClipsDescendants = true
    self.ListContainer.Visible = false
    self.ListContainer.ZIndex = 100
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 8)
    listCorner.Parent = self.ListContainer
    
    local listStroke = Instance.new("UIStroke")
    listStroke.Color = self.Theme:GetColor("Dropdown", "Stroke")
    listStroke.Transparency = 0.2
    listStroke.Thickness = 1
    listStroke.Parent = self.ListContainer
    
    -- Search bar (if enabled)
    if self.Config.Searchable then
        self.SearchContainer = Instance.new("Frame")
        self.SearchContainer.Name = "Search"
        self.SearchContainer.BackgroundColor3 = self.Theme:GetColor("Dropdown", "ItemBackground")
        self.SearchContainer.BackgroundTransparency = 0.1
        self.SearchContainer.Size = UDim2.new(1, -20, 0, 40)
        self.SearchContainer.Position = UDim2.new(0, 10, 0, 10)
        
        local searchCorner = Instance.new("UICorner")
        searchCorner.CornerRadius = UDim.new(0, 6)
        searchCorner.Parent = self.SearchContainer
        
        -- Search icon
        local searchIcon = Instance.new("ImageLabel")
        searchIcon.Name = "Icon"
        searchIcon.BackgroundTransparency = 1
        searchIcon.Size = UDim2.new(0, 20, 0, 20)
        searchIcon.Position = UDim2.new(0, 10, 0.5, -10)
        searchIcon.AnchorPoint = Vector2.new(0, 0.5)
        searchIcon.Image = "rbxassetid://7072716648" -- Search icon
        searchIcon.ImageColor3 = self.Theme:GetColor("Dropdown", "Text")
        searchIcon.ImageTransparency = 0.3
        searchIcon.Parent = self.SearchContainer
        
        -- Search input
        self.SearchInput = Instance.new("TextBox")
        self.SearchInput.Name = "Input"
        self.SearchInput.BackgroundTransparency = 1
        self.SearchInput.Size = UDim2.new(1, -40, 1, 0)
        self.SearchInput.Position = UDim2.new(0, 40, 0, 0)
        self.SearchInput.Font = Enum.Font.Gotham
        self.SearchInput.PlaceholderText = "Search..."
        self.SearchInput.PlaceholderColor3 = self.Theme:GetColor("Dropdown", "Text")
        self.SearchInput.TextColor3 = self.Theme:GetColor("Dropdown", "Text")
        self.SearchInput.TextSize = 14
        self.SearchInput.TextXAlignment = Enum.TextXAlignment.Left
        self.SearchInput.Parent = self.SearchContainer
        
        self.SearchContainer.Parent = self.ListContainer
    end
    
    -- Scroll container for items
    self.ScrollContainer = Instance.new("ScrollingFrame")
    self.ScrollContainer.Name = "ScrollContainer"
    self.ScrollContainer.BackgroundTransparency = 1
    self.ScrollContainer.Size = UDim2.new(1, -20, 0, 200)
    self.ScrollContainer.Position = UDim2.new(0, 10, self.Config.Searchable and 0.25 or 0.1, 0)
    self.ScrollContainer.ScrollBarThickness = 4
    self.ScrollContainer.ScrollBarImageColor3 = self.Theme:GetColor("Dropdown", "Stroke")
    self.ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ScrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Name = "Layout"
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.ScrollContainer
    
    self.ScrollContainer.Parent = self.ListContainer
    
    self.ListContainer.Parent = self.Container
    
    -- Create option items
    self:_createOptions()
end

function Dropdown:_setupEvents()
    -- Header click to toggle
    self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:Toggle()
        end
    end)
    
    -- Clear button
    if self.ClearButton then
        self.ClearButton.MouseButton1Click:Connect(function()
            self:Clear()
        end)
    end
    
    -- Search input events
    if self.SearchInput then
        self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
            self.SearchText = self.SearchInput.Text
            self:_filterOptions()
        end)
    end
    
    -- Close dropdown when clicking outside
    self.CloseConnection = UserInputService.InputBegan:Connect(function(input)
        if self.Open and (input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local mousePos = input.Position
            local absPos = self.ListContainer.AbsolutePosition
            local absSize = self.ListContainer.AbsoluteSize
            
            -- Check if click is outside dropdown
            if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
               mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                self:Close()
            end
        end
    end)
    
    -- Hover effects
    self.Header.MouseEnter:Connect(function()
        self:_onHeaderHover(true)
    end)
    
    self.Header.MouseLeave:Connect(function()
        self:_onHeaderHover(false)
    end)
end

function Dropdown:_createOptions()
    -- Clear existing options
    for _, child in ipairs(self.ScrollContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create new option items
    for i, option in ipairs(self.FilteredOptions) do
        local optionItem = self:_createOptionItem(option, i)
        optionItem.Parent = self.ScrollContainer
    end
    
    -- Update canvas size
    task.wait()
    local totalHeight = self.ScrollContainer.UIListLayout.AbsoluteContentSize.Y
    self.ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function Dropdown:_createOptionItem(option, index)
    local item = Instance.new("Frame")
    item.Name = "Option_" .. index
    item.BackgroundColor3 = self.Theme:GetColor("Dropdown", "ItemBackground")
    item.BackgroundTransparency = 0.1
    item.Size = UDim2.new(1, 0, 0, 35)
    item.LayoutOrder = index
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 6)
    itemCorner.Parent = item
    
    -- Checkbox for multi-select
    if self.Config.MultiSelect then
        local checkbox = Instance.new("Frame")
        checkbox.Name = "Checkbox"
        checkbox.BackgroundColor3 = self.Theme:GetColor("Dropdown", "ItemBackground")
        checkbox.BackgroundTransparency = 0.2
        checkbox.Size = UDim2.new(0, 20, 0, 20)
        checkbox.Position = UDim2.new(0, 10, 0.5, -10)
        checkbox.AnchorPoint = Vector2.new(0, 0.5)
        
        local checkboxCorner = Instance.new("UICorner")
        checkboxCorner.CornerRadius = UDim.new(0, 4)
        checkboxCorner.Parent = checkbox
        
        local checkIcon = Instance.new("ImageLabel")
        checkIcon.Name = "Check"
        checkIcon.BackgroundTransparency = 1
        checkIcon.Size = UDim2.new(0, 14, 0, 14)
        checkIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
        checkIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        checkIcon.Image = "rbxassetid://7072718165"
        checkIcon.ImageColor3 = self.Theme:GetColor("Dropdown", "Selected")
        checkIcon.ImageTransparency = 1
        checkIcon.Parent = checkbox
        
        checkbox.Parent = item
    end
    
    -- Option text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, self.Config.MultiSelect and -40 or -20, 1, 0)
    textLabel.Position = UDim2.new(0, self.Config.MultiSelect and 40 : 20, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = tostring(option)
    textLabel.TextColor3 = self.Theme:GetColor("Dropdown", "Text")
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = item
    
    -- Check if selected
    if self.Config.MultiSelect then
        local isSelected = table.find(self.Value or {}, option) ~= nil
        if isSelected then
            item.BackgroundColor3 = self.Theme:GetColor("Dropdown", "Selected")
            item.BackgroundTransparency = 0.7
            
            local checkIcon = item.Checkbox.Check
            checkIcon.ImageTransparency = 0
        end
    else
        if option == self.Value then
            item.BackgroundColor3 = self.Theme:GetColor("Dropdown", "Selected")
            item.BackgroundTransparency = 0.7
        end
    end
    
    -- Mouse events
    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_onOptionClick(option, item)
        end
    end)
    
    item.MouseEnter:Connect(function()
        self.Animations:Animate(item, {
            BackgroundTransparency = 0.3
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end)
    
    item.MouseLeave:Connect(function()
        local isSelected = false
        
        if self.Config.MultiSelect then
            isSelected = table.find(self.Value or {}, option) ~= nil
        else
            isSelected = option == self.Value
        end
        
        self.Animations:Animate(item, {
            BackgroundTransparency = isSelected and 0.7 or 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end)
    
    return item
end

function Dropdown:_filterOptions()
    if self.SearchText == "" then
        self.FilteredOptions = self.Options
    else
        self.FilteredOptions = {}
        local searchLower = string.lower(self.SearchText)
        
        for _, option in ipairs(self.Options) do
            local optionText = string.lower(tostring(option))
            if string.find(optionText, searchLower, 1, true) then
                table.insert(self.FilteredOptions, option)
            end
        end
    end
    
    self:_createOptions()
end

function Dropdown:_onHeaderHover(enter)
    if enter then
        self.Animations:Animate(self.Header, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.Chevron, {
            ImageTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        self.Animations:Animate(self.Header, {
            BackgroundTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.Chevron, {
            ImageTransparency = 0.3
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end
end

function Dropdown:_onOptionClick(option, item)
    if self.Config.MultiSelect then
        -- Toggle selection
        local index = table.find(self.Value or {}, option)
        
        if index then
            -- Remove from selection
            table.remove(self.Value, index)
            
            -- Update visual
            self.Animations:Animate(item, {
                BackgroundColor3 = self.Theme:GetColor("Dropdown", "ItemBackground"),
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            local checkIcon = item.Checkbox.Check
            self.Animations:Animate(checkIcon, {
                ImageTransparency = 1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        else
            -- Add to selection
            table.insert(self.Value, option)
            
            -- Update visual
            self.Animations:Animate(item, {
                BackgroundColor3 = self.Theme:GetColor("Dropdown", "Selected"),
                BackgroundTransparency = 0.7
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            local checkIcon = item.Checkbox.Check
            self.Animations:Animate(checkIcon, {
                ImageTransparency = 0
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
        
        -- Update display
        self:_updateDisplay()
        
        -- Call callback
        if self.Config.Callback then
            task.spawn(self.Config.Callback, self.Value)
        end
    else
        -- Single selection
        self:SetValue(option)
        self:Close()
    end
end

function Dropdown:_updateDisplay()
    if self.Config.MultiSelect then
        if #self.Value == 0 then
            self.ValueDisplay.Text = self.Config.Placeholder or "Select..."
            self.ValueDisplay.TextTransparency = 0.3
            
            if self.ClearButton then
                self.ClearButton.Visible = false
            end
        else
            if #self.Value == 1 then
                self.ValueDisplay.Text = tostring(self.Value[1])
            else
                self.ValueDisplay.Text = string.format("%d selected", #self.Value)
            end
            
            self.ValueDisplay.TextTransparency = 0
            
            if self.ClearButton then
                self.ClearButton.Visible = true
            end
        end
    else
        if self.Value then
            self.ValueDisplay.Text = tostring(self.Value)
            self.ValueDisplay.TextTransparency = 0
        else
            self.ValueDisplay.Text = self.Config.Placeholder or "Select..."
            self.ValueDisplay.TextTransparency = 0.3
        end
    end
end

function Dropdown:Toggle()
    if self.Open then
        self:Close()
    else
        self:OpenDropdown()
    end
end

function Dropdown:OpenDropdown()
    if self.Open then return end
    
    self.Open = true
    self.ListContainer.Visible = true
    
    -- Calculate max height
    local maxHeight = math.min(300, #self.FilteredOptions * 40 + (self.Config.Searchable and 60 or 20))
    
    -- Animate open
    self.Animations:Animate(self.ListContainer, {
        Size = UDim2.new(1, 0, 0, maxHeight)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    self.Animations:Animate(self.Chevron, {
        Rotation = 180
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    -- Focus search if available
    if self.SearchInput then
        task.wait(0.1)
        self.SearchInput:CaptureFocus()
    end
end

function Dropdown:Close()
    if not self.Open then return end
    
    self.Open = false
    
    -- Animate close
    self.Animations:Animate(self.ListContainer, {
        Size = UDim2.new(1, 0, 0, 0)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    self.Animations:Animate(self.Chevron, {
        Rotation = 0
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    -- Clear search
    if self.SearchInput then
        self.SearchInput.Text = ""
    end
    
    -- Hide after animation
    task.delay(0.3, function()
        if self.ListContainer then
            self.ListContainer.Visible = false
        end
    end)
end

function Dropdown:SetValue(value, noCallback)
    if self.Config.MultiSelect then
        if type(value) == "table" then
            self.Value = value
        else
            self.Value = {value}
        end
    else
        self.Value = value
    end
    
    self:_updateDisplay()
    
    -- Call callback if not suppressed
    if not noCallback and self.Config.Callback then
        task.spawn(self.Config.Callback, value)
    end
end

function Dropdown:GetValue()
    return self.Value
end

function Dropdown:Clear()
    if self.Config.MultiSelect then
        self.Value = {}
    else
        self.Value = nil
    end
    
    self:_updateDisplay()
    
    if self.Config.Callback then
        task.spawn(self.Config.Callback, self.Value)
    end
end

function Dropdown:SetOptions(options)
    self.Options = options
    self.FilteredOptions = options
    
    self:_createOptions()
    
    -- Reset value if it's no longer in options
    if not self.Config.MultiSelect and self.Value and not table.find(options, self.Value) then
        self:SetValue(options[1])
    end
end

function Dropdown:AddOption(option)
    table.insert(self.Options, option)
    self.FilteredOptions = self.Options
    
    self:_createOptions()
end

function Dropdown:RemoveOption(option)
    local index = table.find(self.Options, option)
    if index then
        table.remove(self.Options, index)
        self.FilteredOptions = self.Options
        
        self:_createOptions()
        
        -- Remove from value if selected
        if self.Config.MultiSelect then
            local valueIndex = table.find(self.Value or {}, option)
            if valueIndex then
                table.remove(self.Value, valueIndex)
                self:_updateDisplay()
            end
        elseif self.Value == option then
            self:SetValue(self.Options[1] or nil)
        end
    end
end

function Dropdown:Destroy()
    if self.CloseConnection then
        self.CloseConnection:Disconnect()
    end
    
    if self.Container then
        self.Container:Destroy()
    end
end

return Dropdown