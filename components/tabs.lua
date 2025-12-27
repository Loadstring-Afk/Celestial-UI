-- Premium tab system with animated transitions

local Tabs = {}
Tabs.__index = Tabs

function Tabs.new(config, window, theme, animations)
    local self = setmetatable({}, Tabs)
    
    self.Config = config
    self.Window = window
    self.Theme = theme
    self.Animations = animations
    
    self.Active = false
    self.Sections = {}
    self.Elements = {}
    self.SearchKeywords = config.Keywords or {}
    
    self:_createTab()
    
    return self
end

function Tabs:_createTab()
    -- Tab button (for the tab selector)
    self.Button = Instance.new("TextButton")
    self.Button.Name = "TabButton_" .. self.Config.Name
    self.Button.BackgroundTransparency = 1
    self.Button.Size = UDim2.new(0, 100, 1, 0)
    self.Button.Font = Enum.Font.Gotham
    self.Button.Text = self.Config.Name or "Tab"
    self.Button.TextColor3 = self.Theme:GetColor("Tabs", "Inactive") or Color3.fromRGB(180, 180, 190)
    self.Button.TextSize = 14
    self.Button.TextTransparency = 0.3
    
    -- Icon (optional)
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 16, 0, 16)
        self.Icon.Position = UDim2.new(0, 10, 0.5, -8)
        self.Icon.AnchorPoint = Vector2.new(0, 0.5)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.Button.TextColor3
        self.Icon.ImageTransparency = 0.3
        self.Icon.Parent = self.Button
        
        -- Adjust text position
        self.Button.TextXAlignment = Enum.TextXAlignment.Left
        local textPos = Instance.new("UIPadding")
        textPos.PaddingLeft = UDim.new(0, 35)
        textPos.Parent = self.Button
    end
    
    -- Active indicator (hidden by default)
    self.Indicator = Instance.new("Frame")
    self.Indicator.Name = "Indicator"
    self.Indicator.BackgroundColor3 = self.Theme:GetColor("Tabs", "Active") or Color3.fromRGB(80, 140, 255)
    self.Indicator.BackgroundTransparency = 0.7
    self.Indicator.Size = UDim2.new(1, 0, 0, 3)
    self.Indicator.Position = UDim2.new(0, 0, 1, -3)
    self.Indicator.Visible = false
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 2)
    indicatorCorner.Parent = self.Indicator
    
    self.Indicator.Parent = self.Button
    
    -- Tab content container (created when tab becomes active)
    self.Content = nil
    
    -- Setup button events
    self:_setupButtonEvents()
end

function Tabs:_setupButtonEvents()
    self.Button.MouseButton1Click:Connect(function()
        if self.Window then
            self.Window:SetActiveTab(self)
        end
    end)
    
    self.Button.MouseEnter:Connect(function()
        self:_onButtonHover(true)
    end)
    
    self.Button.MouseLeave:Connect(function()
        self:_onButtonHover(false)
    end)
end

function Tabs:_onButtonHover(enter)
    if enter then
        if not self.Active then
            self.Animations:Animate(self.Button, {
                TextTransparency = 0.1,
                BackgroundTransparency = 0.95
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
        end
    else
        if not self.Active then
            self.Animations:Animate(self.Button, {
                TextTransparency = 0.3,
                BackgroundTransparency = 1
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

function Tabs:SetActive(active)
    self.Active = active
    
    if active then
        -- Activate tab
        self.Indicator.Visible = true
        self.Animations:Animate(self.Indicator, {
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, 3)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        self.Animations:Animate(self.Button, {
            TextColor3 = self.Theme:GetColor("Tabs", "Active") or Color3.fromRGB(240, 240, 245),
            TextTransparency = 0,
            BackgroundTransparency = 0.9
        }, {
            Style = "Fluid",
            Duration = 0.3
        })
        
        if self.Icon then
            self.Animations:Animate(self.Icon, {
                ImageColor3 = self.Theme:GetColor("Tabs", "Active") or Color3.fromRGB(240, 240, 245),
                ImageTransparency = 0
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
        end
        
        -- Create content if not exists
        if not self.Content then
            self:_createContent()
        end
    else
        -- Deactivate tab
        self.Animations:Animate(self.Indicator, {
            BackgroundTransparency = 0.7,
            Size = UDim2.new(0, 0, 0, 3)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        task.delay(0.3, function()
            if self.Indicator then
                self.Indicator.Visible = false
            end
        end)
        
        self.Animations:Animate(self.Button, {
            TextColor3 = self.Theme:GetColor("Tabs", "Inactive") or Color3.fromRGB(180, 180, 190),
            TextTransparency = 0.3,
            BackgroundTransparency = 1
        }, {
            Style = "Fluid",
            Duration = 0.3
        })
        
        if self.Icon then
            self.Animations:Animate(self.Icon, {
                ImageColor3 = self.Theme:GetColor("Tabs", "Inactive") or Color3.fromRGB(180, 180, 190),
                ImageTransparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
        end
    end
end

function Tabs:_createContent()
    -- Content container
    self.Content = Instance.new("Frame")
    self.Content.Name = "TabContent_" .. self.Config.Name
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, 0, 0, 0)
    self.Content.Position = UDim2.new(0, 0, 0, 0)
    self.Content.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Layout for sections
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 15)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = self.Content
    
    -- Padding
    local padding = Instance.new("UIPadding")
    padding.Name = "Padding"
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = self.Content
end

function Tabs:CreateSection(name)
    local Section = {}
    Section.Name = name
    Section.Elements = {}
    Section.LayoutOrder = #self.Sections + 1
    
    -- Create section container
    Section.Container = Instance.new("Frame")
    Section.Container.Name = "Section_" .. name
    Section.Container.BackgroundTransparency = 1
    Section.Container.Size = UDim2.new(1, 0, 0, 0)
    Section.Container.AutomaticSize = Enum.AutomaticSize.Y
    Section.Container.LayoutOrder = Section.LayoutOrder
    
    -- Section title
    Section.Title = Instance.new("TextLabel")
    Section.Title.Name = "Title"
    Section.Title.BackgroundTransparency = 1
    Section.Title.Size = UDim2.new(1, -20, 0, 20)
    Section.Title.Position = UDim2.new(0, 10, 0, 0)
    Section.Title.Font = Enum.Font.GothamBold
    Section.Title.Text = name
    Section.Title.TextColor3 = self.Theme:GetColor("Tabs", "SectionTitle") or Color3.fromRGB(220, 220, 225)
    Section.Title.TextSize = 16
    Section.Title.TextXAlignment = Enum.TextXAlignment.Left
    Section.Title.Parent = Section.Container
    
    -- Divider
    Section.Divider = Instance.new("Frame")
    Section.Divider.Name = "Divider"
    Section.Divider.BackgroundColor3 = self.Theme:GetColor("Tabs", "Divider") or Color3.fromRGB(60, 60, 65)
    Section.Divider.BackgroundTransparency = 0.5
    Section.Divider.Size = UDim2.new(1, -20, 0, 1)
    Section.Divider.Position = UDim2.new(0, 10, 0, 25)
    Section.Divider.Parent = Section.Container
    
    -- Content container
    Section.Content = Instance.new("Frame")
    Section.Content.Name = "Content"
    Section.Content.BackgroundTransparency = 1
    Section.Content.Size = UDim2.new(1, -20, 0, 0)
    Section.Content.Position = UDim2.new(0, 10, 0, 35)
    Section.Content.AutomaticSize = Enum.AutomaticSize.Y
    Section.Content.Parent = Section.Container
    
    -- Layout for elements
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = Section.Content
    
    -- Add to tab
    table.insert(self.Sections, Section)
    
    if self.Content then
        Section.Container.Parent = self.Content
    end
    
    -- Return section API
    return {
        AddLabel = function(config)
            local Label = require(script.Parent.label)
            local label = Label.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, label)
            table.insert(self.Elements, {type = "label", element = label, section = name})
            return label
        end,
        
        AddButton = function(config)
            local Button = require(script.Parent.button)
            local button = Button.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, button)
            table.insert(self.Elements, {type = "button", element = button, section = name})
            return button
        end,
        
        AddToggle = function(config)
            local Toggle = require(script.Parent.toggle)
            local toggle = Toggle.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, toggle)
            table.insert(self.Elements, {type = "toggle", element = toggle, section = name})
            return toggle
        end,
        
        AddSlider = function(config)
            local Slider = require(script.Parent.slider)
            local slider = Slider.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, slider)
            table.insert(self.Elements, {type = "slider", element = slider, section = name})
            return slider
        end,
        
        AddDropdown = function(config)
            local Dropdown = require(script.Parent.dropdown)
            local dropdown = Dropdown.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, dropdown)
            table.insert(self.Elements, {type = "dropdown", element = dropdown, section = name})
            return dropdown
        end,
        
        AddInput = function(config)
            local Input = require(script.Parent.input)
            local input = Input.new(config, Section.Content, self.Theme, self.Animations)
            table.insert(Section.Elements, input)
            table.insert(self.Elements, {type = "input", element = input, section = name})
            return input
        end,
        
        AddDivider = function()
            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.BackgroundColor3 = self.Theme:GetColor("Tabs", "Divider") or Color3.fromRGB(60, 60, 65)
            divider.BackgroundTransparency = 0.5
            divider.Size = UDim2.new(1, 0, 0, 1)
            divider.LayoutOrder = #Section.Elements + 1
            divider.Parent = Section.Content
            
            table.insert(Section.Elements, divider)
            return divider
        end,
        
        GetLastButton = function()
            for i = #Section.Elements, 1, -1 do
                local element = Section.Elements[i]
                if element and element.Container and element.Container.Name:find("CelestialButton") then
                    return element
                end
            end
            return nil
        end,
        
        SetTitle = function(newTitle)
            Section.Title.Text = newTitle
        end,
        
        Clear = function()
            for _, element in ipairs(Section.Elements) do
                if element.Destroy then
                    element:Destroy()
                elseif element:IsA("Instance") then
                    element:Destroy()
                end
            end
            Section.Elements = {}
            
            -- Remove from main elements list
            for i = #self.Elements, 1, -1 do
                if self.Elements[i].section == name then
                    table.remove(self.Elements, i)
                end
            end
        end
    }
end

function Tabs:GetContent()
    return self.Content
end

function Tabs:GetButton()
    return self.Button
end

function Tabs:SetSearchKeywords(keywords)
    self.SearchKeywords = keywords or {}
end

function Tabs:GetSearchKeywords()
    return self.SearchKeywords
end

function Tabs:SearchElements(searchText)
    if searchText == "" then
        -- Show all elements
        for _, section in ipairs(self.Sections) do
            if section.Container then
                section.Container.Visible = true
            end
        end
        return true
    end
    
    local searchLower = string.lower(searchText)
    local hasMatches = false
    
    -- Search in tab keywords
    for _, keyword in ipairs(self.SearchKeywords) do
        if string.find(string.lower(keyword), searchLower, 1, true) then
            hasMatches = true
            break
        end
    end
    
    -- Search in section titles
    for _, section in ipairs(self.Sections) do
        local sectionMatch = string.find(string.lower(section.Name), searchLower, 1, true)
        
        if sectionMatch then
            hasMatches = true
            section.Container.Visible = true
        else
            section.Container.Visible = false
        end
    end
    
    -- Search in element labels
    for _, elementData in ipairs(self.Elements) do
        local element = elementData.element
        
        if element and element.Config and element.Config.Name then
            local elementMatch = string.find(string.lower(element.Config.Name), searchLower, 1, true)
            
            if elementMatch then
                hasMatches = true
                
                -- Show parent section
                for _, section in ipairs(self.Sections) do
                    if section.Name == elementData.section then
                        section.Container.Visible = true
                        break
                    end
                end
            end
        end
    end
    
    return hasMatches
end

function Tabs:Clear()
    for _, section in ipairs(self.Sections) do
        for _, element in ipairs(section.Elements) do
            if element.Destroy then
                element:Destroy()
            elseif element:IsA("Instance") then
                element:Destroy()
            end
        end
        
        if section.Container then
            section.Container:Destroy()
        end
    end
    
    self.Sections = {}
    self.Elements = {}
    
    if self.Content then
        self.Content:Destroy()
        self.Content = nil
    end
end

function Tabs:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Tabs:Destroy()
    if self.Button then
        self.Button:Destroy()
    end
    
    if self.Content then
        self.Content:Destroy()
    end
    
    for _, section in ipairs(self.Sections) do
        if section.Container then
            section.Container:Destroy()
        end
    end
end

return Tabs