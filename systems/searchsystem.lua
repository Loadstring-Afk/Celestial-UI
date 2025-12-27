-- Premium search system for tabs and components

local SearchSystem = {}
SearchSystem.__index = SearchSystem

local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

function SearchSystem.new(config)
    local self = setmetatable({}, SearchSystem)
    
    self.Config = config or {
        Enabled = false,
        SearchTabs = true,
        SearchComponents = true,
        FuzzySearch = true,
        Hotkey = Enum.KeyCode.F,
        Animation = "Spring",
        HighlightColor = Color3.fromRGB(80, 140, 255),
        MaxResults = 50
    }
    
    self.Window = nil
    self.SearchBar = nil
    self.Results = {}
    self.ActiveSearch = ""
    self.Highlights = {}
    
    self.HotkeyConnection = nil
    
    return self
end

function SearchSystem:AttachToWindow(window)
    self.Window = window
    
    if self.Config.Enabled then
        self:_createSearchBar()
        self:_setupHotkey()
    end
end

function SearchSystem:_createSearchBar()
    if not self.Window then return end
    
    -- Create search bar in window title
    self.SearchBar = Instance.new("Frame")
    self.SearchBar.Name = "SearchBar"
    self.SearchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    self.SearchBar.BackgroundTransparency = 0.1
    self.SearchBar.Size = UDim2.new(0, 0, 0, 30)
    self.SearchBar.Position = UDim2.new(1, -40, 0.5, -15)
    self.SearchBar.AnchorPoint = Vector2.new(1, 0.5)
    self.SearchBar.ClipsDescendants = true
    self.SearchBar.Visible = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = self.SearchBar
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 65)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = self.SearchBar
    
    -- Search icon
    self.SearchIcon = Instance.new("ImageLabel")
    self.SearchIcon.Name = "Icon"
    self.SearchIcon.BackgroundTransparency = 1
    self.SearchIcon.Size = UDim2.new(0, 20, 0, 20)
    self.SearchIcon.Position = UDim2.new(0, 8, 0.5, -10)
    self.SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    self.SearchIcon.Image = "rbxassetid://7072716648" -- Search icon
    self.SearchIcon.ImageColor3 = Color3.fromRGB(180, 180, 190)
    self.SearchIcon.Parent = self.SearchBar
    
    -- Search input
    self.SearchInput = Instance.new("TextBox")
    self.SearchInput.Name = "Input"
    self.SearchInput.BackgroundTransparency = 1
    self.SearchInput.Size = UDim2.new(1, -40, 1, 0)
    self.SearchInput.Position = UDim2.new(0, 40, 0, 0)
    self.SearchInput.Font = Enum.Font.Gotham
    self.SearchInput.PlaceholderText = "Search..."
    self.SearchInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    self.SearchInput.TextColor3 = Color3.fromRGB(220, 220, 225)
    self.SearchInput.TextSize = 12
    self.SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    self.SearchInput.Visible = false
    self.SearchInput.Parent = self.SearchBar
    
    -- Clear button
    self.ClearButton = Instance.new("ImageButton")
    self.ClearButton.Name = "Clear"
    self.ClearButton.BackgroundTransparency = 1
    self.ClearButton.Size = UDim2.new(0, 20, 0, 20)
    self.ClearButton.Position = UDim2.new(1, -30, 0.5, -10)
    self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
    self.ClearButton.Image = "rbxassetid://7072720899" -- X icon
    self.ClearButton.ImageColor3 = Color3.fromRGB(180, 180, 190)
    self.ClearButton.ImageTransparency = 0.5
    self.ClearButton.Visible = false
    self.ClearButton.Parent = self.SearchBar
    
    self.SearchBar.Parent = self.Window.TitleBar
    
    -- Setup events
    self:_setupSearchEvents()
end

function SearchSystem:_setupSearchEvents()
    -- Search icon click to expand
    self.SearchIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:ToggleSearch()
        end
    end)
    
    -- Input text changed
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.ActiveSearch = self.SearchInput.Text
        self:Search(self.ActiveSearch)
    end)
    
    -- Clear button
    self.ClearButton.MouseButton1Click:Connect(function()
        self:ClearSearch()
    end)
    
    -- Input focus events
    self.SearchInput.Focused:Connect(function()
        self.Animations:Animate(self.SearchBar.UIStroke, {
            Color = self.Config.HighlightColor,
            Transparency = 0.1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end)
    
    self.SearchInput.FocusLost:Connect(function()
        if self.ActiveSearch == "" then
            self.Animations:Animate(self.SearchBar.UIStroke, {
                Color = Color3.fromRGB(60, 60, 65),
                Transparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end)
    
    -- Hover effects
    self.SearchBar.MouseEnter:Connect(function()
        self.Animations:Animate(self.SearchBar, {
            BackgroundTransparency = 0.05
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end)
    
    self.SearchBar.MouseLeave:Connect(function()
        if not self.SearchInput:IsFocused() then
            self.Animations:Animate(self.SearchBar, {
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end
    end)
end

function SearchSystem:_setupHotkey()
    if not self.Config.Hotkey then return end
    
    self.HotkeyConnection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == self.Config.Hotkey and UserInputService:GetFocusedTextBox() == nil then
            self:ToggleSearch()
        end
    end)
end

function SearchSystem:_fuzzyMatch(text, search)
    if not self.Config.FuzzySearch then
        return string.find(string.lower(text), string.lower(search), 1, true)
    end
    
    -- Simple fuzzy matching
    local textLower = string.lower(text)
    local searchLower = string.lower(search)
    
    local searchIndex = 1
    for i = 1, #textLower do
        if textLower:sub(i, i) == searchLower:sub(searchIndex, searchIndex) then
            searchIndex = searchIndex + 1
            if searchIndex > #searchLower then
                return true
            end
        end
    end
    
    return false
end

function SearchSystem:_highlightText(textLabel, searchText)
    if not textLabel or not searchText or searchText == "" then return end
    
    local text = textLabel.Text
    local searchLower = string.lower(searchText)
    local textLower = string.lower(text)
    
    -- Clear previous highlights
    if self.Highlights[textLabel] then
        for _, highlight in ipairs(self.Highlights[textLabel]) do
            highlight:Destroy()
        end
    end
    self.Highlights[textLabel] = {}
    
    -- Find all occurrences
    local startPos = 1
    while true do
        local foundStart, foundEnd = textLower:find(searchLower, startPos, true)
        if not foundStart then break end
        
        -- Calculate position and size for highlight
        local beforeText = text:sub(1, foundStart - 1)
        local foundText = text:sub(foundStart, foundEnd)
        
        -- Measure text size
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
        
        -- Create highlight frame
        local highlight = Instance.new("Frame")
        highlight.Name = "Highlight"
        highlight.BackgroundColor3 = self.Config.HighlightColor
        highlight.BackgroundTransparency = 0.7
        highlight.Size = UDim2.new(0, foundSize.X, 0, foundSize.Y)
        highlight.Position = UDim2.new(0, beforeSize.X, 0, 0)
        highlight.ZIndex = textLabel.ZIndex - 1
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 2)
        corner.Parent = highlight
        
        highlight.Parent = textLabel
        table.insert(self.Highlights[textLabel], highlight)
        
        startPos = foundEnd + 1
    end
end

function SearchSystem:_clearHighlights()
    for textLabel, highlights in pairs(self.Highlights) do
        for _, highlight in ipairs(highlights) do
            highlight:Destroy()
        end
    end
    self.Highlights = {}
end

function SearchSystem:Search(searchText)
    if not self.Window then return end
    
    self:_clearHighlights()
    
    if searchText == "" then
        -- Show all tabs and components
        for _, tab in ipairs(self.Window.Tabs) do
            if tab.Search then
                tab:Search("")
            end
        end
        return
    end
    
    self.Results = {}
    
    -- Search tabs
    if self.Config.SearchTabs then
        for _, tab in ipairs(self.Window.Tabs) do
            local hasMatches = false
            
            -- Search in tab keywords
            if tab.SearchKeywords then
                for _, keyword in ipairs(tab.SearchKeywords) do
                    if self:_fuzzyMatch(keyword, searchText) then
                        hasMatches = true
                        break
                    end
                end
            end
            
            -- Search in tab name
            if not hasMatches and tab.Config.Name then
                hasMatches = self:_fuzzyMatch(tab.Config.Name, searchText)
            end
            
            -- Highlight tab button if it matches
            if hasMatches and tab.Button then
                self:_highlightText(tab.Button, searchText)
            end
            
            -- Search within tab
            if tab.Search then
                local tabHasMatches = tab:Search(searchText)
                hasMatches = hasMatches or tabHasMatches
            end
            
            if hasMatches then
                table.insert(self.Results, {
                    Type = "Tab",
                    Name = tab.Config.Name,
                    Tab = tab
                })
            end
        end
    end
    
    -- Search components within active tab
    if self.Config.SearchComponents and self.Window.ActiveTab then
        -- This would search through all components in the active tab
        -- Implementation depends on how components are stored
    end
    
    -- Show results count
    if self.SearchInput then
        if #self.Results > 0 then
            self.SearchInput.PlaceholderText = string.format("%d results", #self.Results)
        else
            self.SearchInput.PlaceholderText = "No results"
        end
    end
end

function SearchSystem:ToggleSearch()
    if not self.SearchBar then return end
    
    if self.SearchBar.Visible then
        if self.SearchInput:IsFocused() or self.ActiveSearch ~= "" then
            self:ClearSearch()
            self.SearchInput:ReleaseFocus()
        else
            self:HideSearch()
        end
    else
        self:ShowSearch()
    end
end

function SearchSystem:ShowSearch()
    if not self.SearchBar then return end
    
    self.SearchBar.Visible = true
    
    -- Animate expand
    self.Animations:Animate(self.SearchBar, {
        Size = UDim2.new(0, 200, 0, 30)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    -- Show input after animation
    task.wait(0.2)
    self.SearchInput.Visible = true
    
    -- Focus input
    task.wait(0.1)
    self.SearchInput:CaptureFocus()
end

function SearchSystem:HideSearch()
    if not self.SearchBar then return end
    
    -- Clear search first
    self:ClearSearch()
    
    -- Hide input
    self.SearchInput.Visible = false
    
    -- Animate collapse
    self.Animations:Animate(self.SearchBar, {
        Size = UDim2.new(0, 0, 0, 30)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    -- Hide after animation
    task.delay(0.3, function()
        if self.SearchBar then
            self.SearchBar.Visible = false
        end
    end)
end

function SearchSystem:ClearSearch()
    self.ActiveSearch = ""
    self.SearchInput.Text = ""
    self.SearchInput.PlaceholderText = "Search..."
    
    -- Clear highlights
    self:_clearHighlights()
    
    -- Show all tabs
    for _, tab in ipairs(self.Window.Tabs) do
        if tab.Search then
            tab:Search("")
        end
    end
    
    -- Hide clear button
    self.ClearButton.Visible = false
end

function SearchSystem:GetResults()
    return self.Results
end

function SearchSystem:NavigateToResult(index)
    if index < 1 or index > #self.Results then return end
    
    local result = self.Results[index]
    
    if result.Type == "Tab" and result.Tab then
        -- Switch to tab
        self.Window:SetActiveTab(result.Tab)
        
        -- Scroll to first matching element if possible
        -- This would need integration with the tab's search system
    end
    
    -- Hide search
    self:HideSearch()
end

function SearchSystem:SetHotkey(hotkey)
    self.Config.Hotkey = hotkey
    
    -- Recreate connection
    if self.HotkeyConnection then
        self.HotkeyConnection:Disconnect()
    end
    
    self:_setupHotkey()
end

function SearchSystem:SetHighlightColor(color)
    self.Config.HighlightColor = color
end

function SearchSystem:EnableFuzzySearch(enabled)
    self.Config.FuzzySearch = enabled
end

function SearchSystem:Destroy()
    if self.HotkeyConnection then
        self.HotkeyConnection:Disconnect()
    end
    
    self:_clearHighlights()
    
    if self.SearchBar then
        self.SearchBar:Destroy()
    end
    
    self.Window = nil
end

return SearchSystem