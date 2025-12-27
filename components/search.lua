-- Premium search bar component with auto-complete

local Search = {}
Search.__index = Search

local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

function Search.new(config, parent, theme, animations)
    local self = setmetatable({}, Search)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Value = ""
    self.Suggestions = config.Suggestions or {}
    self.FilteredSuggestions = {}
    self.ShowingSuggestions = false
    self.SelectedIndex = 0
    
    self:_createSearch()
    self:_setupEvents()
    
    return self
end

function Search:_createSearch()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialSearch"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 40)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.Parent = self.Parent
    
    -- Search container
    self.SearchContainer = Instance.new("Frame")
    self.SearchContainer.Name = "SearchContainer"
    self.SearchContainer.BackgroundColor3 = self.Theme:GetColor("Search", "Background") or Color3.fromRGB(40, 40, 45)
    self.SearchContainer.BackgroundTransparency = 0.1
    self.SearchContainer.Size = UDim2.new(1, 0, 0, 40)
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(1, 0)
    containerCorner.Parent = self.SearchContainer
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = self.Theme:GetColor("Search", "Stroke") or Color3.fromRGB(60, 60, 65)
    containerStroke.Transparency = 0.3
    containerStroke.Thickness = 1
    containerStroke.Parent = self.SearchContainer
    
    self.SearchContainer.Parent = self.Container
    
    -- Search icon
    self.SearchIcon = Instance.new("ImageLabel")
    self.SearchIcon.Name = "Icon"
    self.SearchIcon.BackgroundTransparency = 1
    self.SearchIcon.Size = UDim2.new(0, 20, 0, 20)
    self.SearchIcon.Position = UDim2.new(0, 12, 0.5, -10)
    self.SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    self.SearchIcon.Image = "rbxassetid://7072716648" -- Search icon
    self.SearchIcon.ImageColor3 = self.Theme:GetColor("Search", "Icon") or Color3.fromRGB(180, 180, 190)
    self.SearchIcon.ImageTransparency = 0.3
    self.SearchIcon.Parent = self.SearchContainer
    
    -- Search input
    self.SearchInput = Instance.new("TextBox")
    self.SearchInput.Name = "Input"
    self.SearchInput.BackgroundTransparency = 1
    self.SearchInput.Size = UDim2.new(1, -40, 1, 0)
    self.SearchInput.Position = UDim2.new(0, 40, 0, 0)
    self.SearchInput.Font = Enum.Font.Gotham
    self.SearchInput.PlaceholderText = self.Config.Placeholder or "Search..."
    self.SearchInput.PlaceholderColor3 = self.Theme:GetColor("Search", "Placeholder") or Color3.fromRGB(120, 120, 130)
    self.SearchInput.TextColor3 = self.Theme:GetColor("Search", "Text") or Color3.fromRGB(220, 220, 225)
    self.SearchInput.TextSize = 14
    self.SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    self.SearchInput.ClearTextOnFocus = false
    self.SearchInput.Parent = self.SearchContainer
    
    -- Clear button (hidden by default)
    self.ClearButton = Instance.new("ImageButton")
    self.ClearButton.Name = "Clear"
    self.ClearButton.BackgroundTransparency = 1
    self.ClearButton.Size = UDim2.new(0, 20, 0, 20)
    self.ClearButton.Position = UDim2.new(1, -30, 0.5, -10)
    self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
    self.ClearButton.Image = "rbxassetid://7072720899" -- X icon
    self.ClearButton.ImageColor3 = self.Theme:GetColor("Search", "Icon") or Color3.fromRGB(180, 180, 190)
    self.ClearButton.ImageTransparency = 0.5
    self.ClearButton.Visible = false
    self.ClearButton.Parent = self.SearchContainer
    
    -- Suggestions dropdown
    self.SuggestionsContainer = Instance.new("Frame")
    self.SuggestionsContainer.Name = "Suggestions"
    self.SuggestionsContainer.BackgroundColor3 = self.Theme:GetColor("Search", "Background") or Color3.fromRGB(40, 40, 45)
    self.SuggestionsContainer.BackgroundTransparency = 0.1
    self.SuggestionsContainer.Size = UDim2.new(1, 0, 0, 0)
    self.SuggestionsContainer.Position = UDim2.new(0, 0, 1, 5)
    self.SuggestionsContainer.ClipsDescendants = true
    self.SuggestionsContainer.Visible = false
    self.SuggestionsContainer.ZIndex = 100
    
    local suggestionsCorner = Instance.new("UICorner")
    suggestionsCorner.CornerRadius = UDim.new(0, 8)
    suggestionsCorner.Parent = self.SuggestionsContainer
    
    local suggestionsStroke = Instance.new("UIStroke")
    suggestionsStroke.Color = self.Theme:GetColor("Search", "Stroke") or Color3.fromRGB(60, 60, 65)
    suggestionsStroke.Transparency = 0.2
    suggestionsStroke.Thickness = 1
    suggestionsStroke.Parent = self.SuggestionsContainer
    
    -- Scroll container for suggestions
    self.SuggestionsScroll = Instance.new("ScrollingFrame")
    self.SuggestionsScroll.Name = "Scroll"
    self.SuggestionsScroll.BackgroundTransparency = 1
    self.SuggestionsScroll.Size = UDim2.new(1, -10, 1, -10)
    self.SuggestionsScroll.Position = UDim2.new(0, 5, 0, 5)
    self.SuggestionsScroll.ScrollBarThickness = 4
    self.SuggestionsScroll.ScrollBarImageColor3 = self.Theme:GetColor("Search", "Stroke") or Color3.fromRGB(60, 60, 65)
    self.SuggestionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.SuggestionsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    self.SuggestionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.SuggestionsScroll.ZIndex = 101
    
    local suggestionsLayout = Instance.new("UIListLayout")
    suggestionsLayout.Name = "Layout"
    suggestionsLayout.Padding = UDim.new(0, 2)
    suggestionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    suggestionsLayout.Parent = self.SuggestionsScroll
    
    self.SuggestionsScroll.Parent = self.SuggestionsContainer
    self.SuggestionsContainer.Parent = self.Container
end

function Search:_setupEvents()
    -- Input text changed
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.Value = self.SearchInput.Text
        self:_onTextChanged()
    end)
    
    -- Clear button
    self.ClearButton.MouseButton1Click:Connect(function()
        self:Clear()
    end)
    
    -- Input focus events
    self.SearchInput.Focused:Connect(function()
        self:_onFocus(true)
    end)
    
    self.SearchInput.FocusLost:Connect(function(enterPressed)
        self:_onFocus(false, enterPressed)
    end)
    
    -- Click container to focus
    self.SearchContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.SearchInput:CaptureFocus()
        end
    end)
    
    -- Hover effects
    self.SearchContainer.MouseEnter:Connect(function()
        self:_onHover(true)
    end)
    
    self.SearchContainer.MouseLeave:Connect(function()
        self:_onHover(false)
    end)
    
    -- Keyboard navigation for suggestions
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self:_updateSuggestions()
    end)
    
    -- Handle arrow keys in input
    self.SearchInput.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Up then
            self:_navigateSuggestions(-1)
        elseif input.KeyCode == Enum.KeyCode.Down then
            self:_navigateSuggestions(1)
        elseif input.KeyCode == Enum.KeyCode.Escape then
            self:HideSuggestions()
        elseif input.KeyCode == Enum.KeyCode.Tab then
            self:_selectSuggestion()
        end
    end)
end

function Search:_onTextChanged()
    -- Show/hide clear button
    self.ClearButton.Visible = #self.Value > 0
    
    -- Call change callback
    if self.Config.OnChange then
        task.spawn(self.Config.OnChange, self.Value)
    end
    
    -- Update suggestions
    if #self.Value > 0 and self.Config.AutoComplete then
        self:_updateSuggestions()
        self:ShowSuggestions()
    else
        self:HideSuggestions()
    end
end

function Search:_onFocus(focused, enterPressed)
    if focused then
        -- Visual feedback
        self.Animations:Animate(self.SearchContainer.UIStroke, {
            Color = self.Theme:GetColor("Search", "Accent") or Color3.fromRGB(80, 140, 255),
            Transparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.SearchIcon, {
            ImageTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        -- Show suggestions if there's text
        if #self.Value > 0 and self.Config.AutoComplete then
            self:ShowSuggestions()
        end
    else
        if #self.Value == 0 then
            self.Animations:Animate(self.SearchContainer.UIStroke, {
                Color = self.Theme:GetColor("Search", "Stroke") or Color3.fromRGB(60, 60, 65),
                Transparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
        
        self.Animations:Animate(self.SearchIcon, {
            ImageTransparency = 0.3
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        -- Hide suggestions after a delay
        task.wait(0.1)
        self:HideSuggestions()
        
        -- Call submit on enter
        if enterPressed and self.Config.OnSubmit then
            task.spawn(self.Config.OnSubmit, self.Value)
        end
    end
end

function Search:_onHover(enter)
    if enter then
        self.Animations:Animate(self.SearchContainer, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
        
        self.Animations:Animate(self.SearchIcon, {
            ImageTransparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        if not self.SearchInput:IsFocused() then
            self.Animations:Animate(self.SearchContainer, {
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
            
            self.Animations:Animate(self.SearchIcon, {
                ImageTransparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end
end

function Search:_updateSuggestions()
    if not self.Config.AutoComplete then return end
    
    self.FilteredSuggestions = {}
    
    if self.Value == "" then
        -- Show all suggestions or recent searches
        if self.Config.ShowRecent and self.RecentSearches then
            for _, recent in ipairs(self.RecentSearches) do
                table.insert(self.FilteredSuggestions, recent)
            end
        else
            for _, suggestion in ipairs(self.Suggestions) do
                table.insert(self.FilteredSuggestions, suggestion)
            end
        end
    else
        -- Filter suggestions
        local searchLower = string.lower(self.Value)
        
        for _, suggestion in ipairs(self.Suggestions) do
            local suggestionText = string.lower(tostring(suggestion))
            
            if self.Config.FuzzySearch then
                -- Simple fuzzy matching
                local searchIndex = 1
                for i = 1, #suggestionText do
                    if suggestionText:sub(i, i) == searchLower:sub(searchIndex, searchIndex) then
                        searchIndex = searchIndex + 1
                        if searchIndex > #searchLower then
                            table.insert(self.FilteredSuggestions, suggestion)
                            break
                        end
                    end
                end
            else
                -- Exact match
                if string.find(suggestionText, searchLower, 1, true) then
                    table.insert(self.FilteredSuggestions, suggestion)
                end
            end
        end
    end
    
    -- Limit suggestions
    local maxSuggestions = self.Config.MaxSuggestions or 10
    if #self.FilteredSuggestions > maxSuggestions then
        for i = maxSuggestions + 1, #self.FilteredSuggestions do
            self.FilteredSuggestions[i] = nil
        end
    end
    
    -- Update UI
    self:_createSuggestionItems()
end

function Search:_createSuggestionItems()
    -- Clear existing suggestions
    for _, child in ipairs(self.SuggestionsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create suggestion items
    for i, suggestion in ipairs(self.FilteredSuggestions) do
        local suggestionItem = self:_createSuggestionItem(suggestion, i)
        suggestionItem.Parent = self.SuggestionsScroll
    end
    
    -- Update canvas size
    task.wait()
    local totalHeight = self.SuggestionsScroll.UIListLayout.AbsoluteContentSize.Y
    self.SuggestionsScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    
    -- Update container size
    local maxHeight = self.Config.MaxSuggestionsHeight or 200
    local height = math.min(totalHeight + 10, maxHeight)
    
    self.SuggestionsContainer.Size = UDim2.new(1, 0, 0, height)
end

function Search:_createSuggestionItem(suggestion, index)
    local item = Instance.new("Frame")
    item.Name = "Suggestion_" .. index
    item.BackgroundColor3 = self.Theme:GetColor("Search", "SuggestionBackground") or Color3.fromRGB(50, 50, 55)
    item.BackgroundTransparency = 0.1
    item.Size = UDim2.new(1, 0, 0, 35)
    item.LayoutOrder = index
    item.ZIndex = 102
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -10, 1, 0)
    content.Position = UDim2.new(0, 5, 0, 0)
    content.ZIndex = 103
    content.Parent = item
    
    -- Icon (optional)
    if self.Config.SuggestionIcon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 0, 0.5, -8)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Image = self:_getIcon(self.Config.SuggestionIcon)
        icon.ImageColor3 = self.Theme:GetColor("Search", "SuggestionIcon") or Color3.fromRGB(180, 180, 190)
        icon.ZIndex = 104
        icon.Parent = content
    end
    
    -- Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, self.Config.SuggestionIcon and -25 or -5, 1, 0)
    textLabel.Position = UDim2.new(0, self.Config.SuggestionIcon and 25 : 5, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = tostring(suggestion)
    textLabel.TextColor3 = self.Theme:GetColor("Search", "SuggestionText") or Color3.fromRGB(220, 220, 225)
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 104
    textLabel.Parent = content
    
    -- Highlight matching text
    if self.Value ~= "" then
        self:_highlightMatchingText(textLabel, self.Value)
    end
    
    -- Events
    item.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:_selectSuggestion(suggestion)
        end
    end)
    
    item.MouseEnter:Connect(function()
        self.SelectedIndex = index
        self:_highlightSuggestion(item, true)
    end)
    
    item.MouseLeave:Connect(function()
        self:_highlightSuggestion(item, false)
    end)
    
    return item
end

function Search:_highlightMatchingText(textLabel, searchText)
    local text = textLabel.Text
    local searchLower = string.lower(searchText)
    local textLower = string.lower(text)
    
    local foundStart, foundEnd = textLower:find(searchLower, 1, true)
    if not foundStart then return end
    
    -- Create highlight
    local beforeText = text:sub(1, foundStart - 1)
    local foundText = text:sub(foundStart, foundEnd)
    
    -- Measure text
    local beforeSize = TextService:GetTextSize(
        beforeText,
        textLabel.TextSize,
        textLabel.Font,
        Vector2.new(1000, 100)
    )
    
    local foundSize = TextService:GetTextSize(
        foundText,
        textLabel.TextSize,
        textLabel.Font,
        Vector2.new(1000, 100)
    )
    
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.BackgroundColor3 = self.Theme:GetColor("Search", "Highlight") or Color3.fromRGB(80, 140, 255)
    highlight.BackgroundTransparency = 0.7
    highlight.Size = UDim2.new(0, foundSize.X, 0, foundSize.Y)
    highlight.Position = UDim2.new(0, beforeSize.X, 0, 0)
    highlight.ZIndex = textLabel.ZIndex - 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = highlight
    
    highlight.Parent = textLabel
end

function Search:_highlightSuggestion(item, highlight)
    if highlight then
        self.Animations:Animate(item, {
            BackgroundTransparency = 0,
            BackgroundColor3 = self.Theme:GetColor("Search", "SuggestionSelected") or Color3.fromRGB(60, 60, 70)
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        self.Animations:Animate(item, {
            BackgroundTransparency = 0.1,
            BackgroundColor3 = self.Theme:GetColor("Search", "SuggestionBackground") or Color3.fromRGB(50, 50, 55)
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end
end

function Search:_navigateSuggestions(direction)
    if not self.ShowingSuggestions or #self.FilteredSuggestions == 0 then return end
    
    self.SelectedIndex = self.SelectedIndex + direction
    
    -- Wrap around
    if self.SelectedIndex < 1 then
        self.SelectedIndex = #self.FilteredSuggestions
    elseif self.SelectedIndex > #self.FilteredSuggestions then
        self.SelectedIndex = 1
    end
    
    -- Update highlight
    for i, child in ipairs(self.SuggestionsScroll:GetChildren()) do
        if child:IsA("Frame") then
            self:_highlightSuggestion(child, i == self.SelectedIndex)
        end
    end
    
    -- Scroll to selected item
    local selectedItem = self.SuggestionsScroll:FindFirstChild("Suggestion_" .. self.SelectedIndex)
    if selectedItem then
        self.SuggestionsScroll.CanvasPosition = Vector2.new(
            0,
            selectedItem.Position.Y.Offset - (self.SuggestionsScroll.AbsoluteSize.Y / 2) + (selectedItem.AbsoluteSize.Y / 2)
        )
    end
end

function Search:_selectSuggestion(suggestion)
    if suggestion then
        self:SetValue(tostring(suggestion))
        
        -- Add to recent searches
        self:_addToRecent(suggestion)
        
        -- Call suggestion callback
        if self.Config.OnSuggestionSelect then
            task.spawn(self.Config.OnSuggestionSelect, suggestion)
        end
    elseif self.SelectedIndex > 0 and self.SelectedIndex <= #self.FilteredSuggestions then
        local selectedSuggestion = self.FilteredSuggestions[self.SelectedIndex]
        self:SetValue(tostring(selectedSuggestion))
        
        -- Add to recent searches
        self:_addToRecent(selectedSuggestion)
        
        if self.Config.OnSuggestionSelect then
            task.spawn(self.Config.OnSuggestionSelect, selectedSuggestion)
        end
    end
    
    self:HideSuggestions()
    self.SearchInput:CaptureFocus()
end

function Search:_addToRecent(suggestion)
    if not self.Config.SaveRecent then return end
    
    self.RecentSearches = self.RecentSearches or {}
    
    -- Remove if already exists
    for i, recent in ipairs(self.RecentSearches) do
        if recent == suggestion then
            table.remove(self.RecentSearches, i)
            break
        end
    end
    
    -- Add to beginning
    table.insert(self.RecentSearches, 1, suggestion)
    
    -- Limit recent searches
    local maxRecent = self.Config.MaxRecent or 5
    if #self.RecentSearches > maxRecent then
        table.remove(self.RecentSearches, maxRecent + 1)
    end
end

function Search:ShowSuggestions()
    if self.ShowingSuggestions or #self.FilteredSuggestions == 0 then return end
    
    self.ShowingSuggestions = true
    self.SuggestionsContainer.Visible = true
    
    -- Animate in
    self.Animations:Animate(self.SuggestionsContainer, {
        Size = UDim2.new(1, 0, 0, self.SuggestionsContainer.AbsoluteSize.Y),
        BackgroundTransparency = 0.1
    }, {
        Style = "Spring",
        Duration = 0.3
    })
end

function Search:HideSuggestions()
    if not self.ShowingSuggestions then return end
    
    self.ShowingSuggestions = false
    self.SelectedIndex = 0
    
    -- Animate out
    self.Animations:Animate(self.SuggestionsContainer, {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1
    }, {
        Style = "Spring",
        Duration = 0.2
    })
    
    -- Hide after animation
    task.delay(0.2, function()
        if self.SuggestionsContainer then
            self.SuggestionsContainer.Visible = false
        end
    end)
end

function Search:SetValue(value, noCallback)
    self.Value = value
    self.SearchInput.Text = value
    
    -- Show/hide clear button
    self.ClearButton.Visible = #value > 0
    
    -- Call callback if not suppressed
    if not noCallback and self.Config.OnChange then
        task.spawn(self.Config.OnChange, value)
    end
end

function Search:GetValue()
    return self.Value
end

function Search:Clear()
    self:SetValue("")
    self:HideSuggestions()
    self.SearchInput:CaptureFocus()
end

function Search:SetSuggestions(suggestions)
    self.Suggestions = suggestions or {}
    self:_updateSuggestions()
end

function Search:AddSuggestion(suggestion)
    table.insert(self.Suggestions, suggestion)
    self:_updateSuggestions()
end

function Search:RemoveSuggestion(suggestion)
    for i, sug in ipairs(self.Suggestions) do
        if sug == suggestion then
            table.remove(self.Suggestions, i)
            break
        end
    end
    self:_updateSuggestions()
end

function Search:SetPlaceholder(text)
    self.Config.Placeholder = text
    self.SearchInput.PlaceholderText = text
end

function Search:SetIcon(icon)
    self.SearchIcon.Image = self:_getIcon(icon)
end

function Search:_getIcon(iconName)
    -- Map icon names to asset IDs
    local iconMap = {
        Search = "rbxassetid://7072716648",
        Filter = "rbxassetid://7072716650",
        Sort = "rbxassetid://7072716651",
        Close = "rbxassetid://7072720899"
    }
    
    return iconMap[iconName] or iconName or "rbxassetid://7072716648"
end

function Search:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Search