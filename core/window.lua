-- Window system - Main container for UI elements

local Window = {}
Window.__index = Window

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function Window.new(config, theme, animations)
    local self = setmetatable({}, Window)
    
    self.Config = config
    self.Theme = theme
    self.Animations = animations
    
    self.Tabs = {}
    self.Sections = {}
    self.Elements = {}
    self.IsVisible = false
    self.Dragging = false
    self.Resizing = false
    self.Minimized = false
    
    self:_createUI()
    self:_setupEvents()
    
    return self
end

function Window:_createUI()
    -- Main container
    self.Container = Instance.new("ScreenGui")
    self.Container.Name = "CelestialWindow"
    self.Container.ResetOnSpawn = false
    self.Container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.Container.IgnoreGuiInset = true
    self.Container.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Background overlay
    self.Overlay = Instance.new("Frame")
    self.Overlay.Name = "Overlay"
    self.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self.Overlay.BackgroundTransparency = 0.5
    self.Overlay.Size = UDim2.new(1, 0, 1, 0)
    self.Overlay.Visible = false
    self.Overlay.ZIndex = 1
    self.Overlay.Parent = self.Container
    
    -- Main window
    self.Main = Instance.new("Frame")
    self.Main.Name = "Main"
    self.Main.BackgroundColor3 = self.Theme:GetColor("Window", "Background")
    self.Main.BackgroundTransparency = self.Config.Transparency or 0.1
    self.Main.Size = UDim2.new(0, 500, 0, 400)
    self.Main.Position = UDim2.new(0.5, -250, 0.5, -200)
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.ZIndex = 2
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.Main
    
    -- Drop shadow
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.new(0, 0, 0)
    shadow.Transparency = 0.8
    shadow.Thickness = 2
    shadow.Parent = self.Main
    
    -- Inner shadow (for depth)
    local innerShadow = Instance.new("Frame")
    innerShadow.Name = "InnerShadow"
    innerShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    innerShadow.BackgroundTransparency = 0.9
    innerShadow.Size = UDim2.new(1, 0, 0, 4)
    innerShadow.Position = UDim2.new(0, 0, 0, 0)
    innerShadow.ZIndex = 3
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 12)
    innerCorner.Parent = innerShadow
    
    innerShadow.Parent = self.Main
    
    -- Title bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.BackgroundColor3 = self.Theme:GetColor("Window", "TitleBar")
    self.TitleBar.BackgroundTransparency = 0.1
    self.TitleBar.Size = UDim2.new(1, 0, 0, 40)
    self.TitleBar.ZIndex = 4
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    titleCorner.Parent = self.TitleBar
    
    self.TitleBar.Parent = self.Main
    
    -- Title text
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.BackgroundTransparency = 1
    self.Title.Size = UDim2.new(0.7, 0, 1, 0)
    self.Title.Position = UDim2.new(0, 15, 0, 0)
    self.Title.Font = Enum.Font.GothamBold
    self.Title.Text = self.Config.Name or "Celestial UI"
    self.Title.TextColor3 = self.Theme:GetColor("Window", "Title")
    self.Title.TextSize = 18
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.ZIndex = 5
    self.Title.Parent = self.TitleBar
    
    -- Subtitle
    self.Subtitle = Instance.new("TextLabel")
    self.Subtitle.Name = "Subtitle"
    self.Subtitle.BackgroundTransparency = 1
    self.Subtitle.Size = UDim2.new(0.7, 0, 0.5, 0)
    self.Subtitle.Position = UDim2.new(0, 15, 0.5, 0)
    self.Subtitle.Font = Enum.Font.Gotham
    self.Subtitle.Text = self.Config.Subtitle or ""
    self.Subtitle.TextColor3 = self.Theme:GetColor("Window", "Subtitle")
    self.Subtitle.TextTransparency = 0.3
    self.Subtitle.TextSize = 12
    self.Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    self.Subtitle.ZIndex = 5
    self.Subtitle.Parent = self.TitleBar
    
    -- Close button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    self.CloseButton.BackgroundTransparency = 0.8
    self.CloseButton.Size = UDim2.new(0, 30, 0, 30)
    self.CloseButton.Position = UDim2.new(1, -40, 0.5, -15)
    self.CloseButton.AnchorPoint = Vector2.new(1, 0.5)
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.Text = "×"
    self.CloseButton.TextColor3 = Color3.new(1, 1, 1)
    self.CloseButton.TextSize = 20
    self.CloseButton.ZIndex = 5
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = self.CloseButton
    
    self.CloseButton.Parent = self.TitleBar
    
    -- Minimize button
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Name = "MinimizeButton"
    self.MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
    self.MinimizeButton.BackgroundTransparency = 0.8
    self.MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    self.MinimizeButton.Position = UDim2.new(1, -80, 0.5, -15)
    self.MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.Text = "—"
    self.MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
    self.MinimizeButton.TextSize = 20
    self.MinimizeButton.ZIndex = 5
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(1, 0)
    minimizeCorner.Parent = self.MinimizeButton
    
    self.MinimizeButton.Parent = self.TitleBar
    
    -- Content area
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, -20, 1, -60)
    self.Content.Position = UDim2.new(0, 10, 0, 50)
    self.Content.ZIndex = 3
    self.Content.Parent = self.Main
    
    -- Tabs container
    self.TabsContainer = Instance.new("Frame")
    self.TabsContainer.Name = "Tabs"
    self.TabsContainer.BackgroundTransparency = 1
    self.TabsContainer.Size = UDim2.new(1, 0, 0, 40)
    self.TabsContainer.Position = UDim2.new(0, 0, 0, 0)
    self.TabsContainer.ZIndex = 4
    self.TabsContainer.Parent = self.Content
    
    -- Scroll container
    self.ScrollContainer = Instance.new("ScrollingFrame")
    self.ScrollContainer.Name = "ScrollContainer"
    self.ScrollContainer.BackgroundTransparency = 1
    self.ScrollContainer.Size = UDim2.new(1, 0, 1, -40)
    self.ScrollContainer.Position = UDim2.new(0, 0, 0, 40)
    self.ScrollContainer.ScrollBarThickness = 4
    self.ScrollContainer.ScrollBarImageColor3 = self.Theme:GetColor("Window", "ScrollBar")
    self.ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ScrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.ScrollContainer.ZIndex = 3
    self.ScrollContainer.Parent = self.Content
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = self.ScrollContainer
    
    self.Main.Parent = self.Container
end

function Window:_setupEvents()
    -- Drag handling
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self.DragStart = input.Position
            self.StartPosition = self.Main.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - self.DragStart
            self.Main.Position = UDim2.new(
                self.StartPosition.X.Scale,
                self.StartPosition.X.Offset + delta.X,
                self.StartPosition.Y.Scale,
                self.StartPosition.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = false
        end
    end)
    
    -- Close button
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)
    
    -- Minimize button
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    -- Click overlay to close
    self.Overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:Hide()
        end
    end)
    
    -- Mobile gesture support
    if self.Config.Mobile.Enabled and UserInputService.TouchEnabled then
        self:_setupMobileGestures()
    end
end

function Window:_setupMobileGestures()
    -- Swipe to close
    local touchStart = nil
    local touchStartTime = nil
    
    self.Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStart = input.Position
            touchStartTime = tick()
        end
    end)
    
    self.Main.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and touchStart then
            local touchEnd = input.Position
            local delta = (touchEnd - touchStart).Magnitude
            local timeDelta = tick() - touchStartTime
            
            -- Swipe detection
            if delta > 50 and timeDelta < 0.3 then
                local direction = (touchEnd - touchStart).Unit
                
                -- Swipe down to close
                if direction.Y > 0.7 then
                    self:Hide()
                end
            end
            
            touchStart = nil
            touchStartTime = nil
        end
    end)
end

function Window:CreateTab(config)
    local TabClass = require(script.Parent.components.tabs)
    local tab = TabClass.new(config, self, self.Theme, self.Animations)
    table.insert(self.Tabs, tab)
    
    -- Add to tabs container
    local tabButton = tab:GetButton()
    tabButton.Parent = self.TabsContainer
    
    -- Set first tab as active
    if #self.Tabs == 1 then
        self:SetActiveTab(tab)
    end
    
    return tab
end

function Window:SetActiveTab(tab)
    if self.ActiveTab then
        self.ActiveTab:SetActive(false)
    end
    
    self.ActiveTab = tab
    tab:SetActive(true)
    
    -- Clear previous content
    for _, child in ipairs(self.ScrollContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "Layout" then
            child:Destroy()
        end
    end
    
    -- Add tab content
    local content = tab:GetContent()
    content.Parent = self.ScrollContainer
end

function Window:Show()
    if self.IsVisible then return end
    
    self.IsVisible = true
    self.Overlay.Visible = true
    
    -- Animate in
    self.Animations:Animate(self.Main, {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundTransparency = self.Config.Transparency or 0.1
    }, {
        Style = "Spring",
        Duration = 0.5
    })
    
    -- Fade in overlay
    self.Animations:Animate(self.Overlay, {
        BackgroundTransparency = 0.5
    }, {
        Style = "Smooth",
        Duration = 0.3
    })
end

function Window:Hide()
    if not self.IsVisible then return end
    
    self.IsVisible = false
    
    -- Animate out
    self.Animations:Animate(self.Main, {
        Size = UDim2.new(0, 500, 0, 0),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundTransparency = 1
    }, {
        Style = "Spring",
        Duration = 0.4
    })
    
    -- Fade out overlay
    self.Animations:Animate(self.Overlay, {
        BackgroundTransparency = 1
    }, {
        Style = "Smooth",
        Duration = 0.3
    })
    
    -- Hide overlay after animation
    task.delay(0.4, function()
        if self.Overlay then
            self.Overlay.Visible = false
        end
    end)
end

function Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    
    if self.Minimized then
        -- Minimize to title bar
        self.Animations:Animate(self.Main, {
            Size = UDim2.new(0, 500, 0, 40),
            Position = UDim2.new(self.Main.Position.X.Scale, self.Main.Position.X.Offset,
                               self.Main.Position.Y.Scale, self.Main.Position.Y.Offset)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        self.MinimizeButton.Text = "+"
    else
        -- Restore
        self.Animations:Animate(self.Main, {
            Size = UDim2.new(0, 500, 0, 400),
            Position = UDim2.new(self.Main.Position.X.Scale, self.Main.Position.X.Offset,
                               self.Main.Position.Y.Scale, self.Main.Position.Y.Offset)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
        
        self.MinimizeButton.Text = "—"
    end
end

function Window:SetTransparency(transparency)
    self.Config.Transparency = transparency
    self.Main.BackgroundTransparency = transparency
end

function Window:ShowNotification(message, duration)
    if self.Config.ToggleIsland.Enabled and self.Island then
        self.Island:ShowNotification(message, duration)
    end
end

function Window:ClearCache()
    -- Clear all saved data
    if self.Config.ConfigurationSaving.Enabled then
        -- Implementation would connect to database module
    end
end

function Window:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Window