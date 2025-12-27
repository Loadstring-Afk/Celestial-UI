-- Premium context menu system with fluid animations

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

function ContextMenu.new(config)
    local self = setmetatable({}, ContextMenu)
    
    self.Config = config or {
        Animation = "Spring",
        Theme = "Dark",
        Position = "Cursor",
        MaxHeight = 300,
        SubmenuOffset = 10
    }
    
    self.Menu = nil
    self.ActiveSubmenu = nil
    self.Visible = false
    self.Items = {}
    
    self:_createMenu()
    
    return self
end

function ContextMenu:_createMenu()
    -- Main container
    self.Container = Instance.new("ScreenGui")
    self.Container.Name = "CelestialContextMenu"
    self.Container.ResetOnSpawn = false
    self.Container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.Container.IgnoreGuiInset = true
    self.Container.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Menu frame (created when shown)
    self.MenuFrame = nil
    
    -- Background overlay (for clicking outside)
    self.Overlay = Instance.new("Frame")
    self.Overlay.Name = "Overlay"
    self.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self.Overlay.BackgroundTransparency = 1
    self.Overlay.Size = UDim2.new(1, 0, 1, 0)
    self.Overlay.Visible = false
    self.Overlay.ZIndex = 100
    self.Overlay.Parent = self.Container
    
    -- Click outside to close
    self.Overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self:Hide()
        end
    end)
end

function ContextMenu:_createMenuFrame()
    if self.MenuFrame then
        self.MenuFrame:Destroy()
    end
    
    self.MenuFrame = Instance.new("Frame")
    self.MenuFrame.Name = "ContextMenu"
    self.MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.MenuFrame.BackgroundTransparency = 0.1
    self.MenuFrame.Size = UDim2.new(0, 200, 0, 0)
    self.MenuFrame.Position = UDim2.new(0, 0, 0, 0)
    self.MenuFrame.ClipsDescendants = true
    self.MenuFrame.ZIndex = 101
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.MenuFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.7
    stroke.Thickness = 2
    stroke.Parent = self.MenuFrame
    
    -- Inner shadow
    local innerShadow = Instance.new("Frame")
    innerShadow.Name = "InnerShadow"
    innerShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    innerShadow.BackgroundTransparency = 0.9
    innerShadow.Size = UDim2.new(1, 0, 0, 4)
    innerShadow.Position = UDim2.new(0, 0, 0, 0)
    innerShadow.ZIndex = 102
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 8)
    innerCorner.Parent = innerShadow
    
    innerShadow.Parent = self.MenuFrame
    
    -- Items container
    self.ItemsContainer = Instance.new("Frame")
    self.ItemsContainer.Name = "Items"
    self.ItemsContainer.BackgroundTransparency = 1
    self.ItemsContainer.Size = UDim2.new(1, -10, 1, -10)
    self.ItemsContainer.Position = UDim2.new(0, 5, 0, 5)
    self.ItemsContainer.ZIndex = 103
    self.ItemsContainer.Parent = self.MenuFrame
    
    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = self.ItemsContainer
    
    self.MenuFrame.Parent = self.Container
end

function ContextMenu:_createMenuItem(itemConfig, index)
    local item = Instance.new("Frame")
    item.Name = "Item_" .. index
    item.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    item.BackgroundTransparency = 0.1
    item.Size = UDim2.new(1, 0, 0, 35)
    item.LayoutOrder = index
    item.ZIndex = 104
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = item
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -10, 1, 0)
    content.Position = UDim2.new(0, 5, 0, 0)
    content.ZIndex = 105
    content.Parent = item
    
    -- Icon (optional)
    if itemConfig.Icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 0, 0.5, -10)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Image = self:_getIcon(itemConfig.Icon)
        icon.ImageColor3 = Color3.fromRGB(200, 200, 210)
        icon.ZIndex = 106
        icon.Parent = content
    end
    
    -- Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, itemConfig.Icon and -25 or -5, 1, 0)
    textLabel.Position = UDim2.new(0, itemConfig.Icon and 25 : 5, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = itemConfig.Text or "Item"
    textLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 106
    textLabel.Parent = content
    
    -- Hotkey (optional)
    if itemConfig.Hotkey then
        local hotkey = Instance.new("TextLabel")
        hotkey.Name = "Hotkey"
        hotkey.BackgroundTransparency = 1
        hotkey.Size = UDim2.new(0, 40, 1, 0)
        hotkey.Position = UDim2.new(1, -40, 0, 0)
        hotkey.AnchorPoint = Vector2.new(1, 0)
        hotkey.Font = Enum.Font.Gotham
        hotkey.Text = itemConfig.Hotkey
        hotkey.TextColor3 = Color3.fromRGB(150, 150, 160)
        hotkey.TextSize = 10
        hotkey.TextXAlignment = Enum.TextXAlignment.Right
        hotkey.ZIndex = 106
        hotkey.Parent = content
    end
    
    -- Chevron for submenu (optional)
    if itemConfig.Submenu then
        local chevron = Instance.new("ImageLabel")
        chevron.Name = "Chevron"
        chevron.BackgroundTransparency = 1
        chevron.Size = UDim2.new(0, 12, 0, 12)
        chevron.Position = UDim2.new(1, -15, 0.5, -6)
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Image = "rbxassetid://7072718165" -- Chevron right
        chevron.ImageColor3 = Color3.fromRGB(150, 150, 160)
        chevron.Rotation = 270
        chevron.ZIndex = 106
        chevron.Parent = content
    end
    
    -- Divider (optional)
    if itemConfig.Divider then
        item.Size = UDim2.new(1, 0, 0, 1)
        item.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        item.BackgroundTransparency = 0.5
        
        -- Remove other elements
        content:Destroy()
    end
    
    -- Events (if not a divider)
    if not itemConfig.Divider then
        -- Mouse enter
        item.MouseEnter:Connect(function()
            self:_onItemHover(item, true, itemConfig)
        end)
        
        -- Mouse leave
        item.MouseLeave:Connect(function()
            self:_onItemHover(item, false, itemConfig)
        end)
        
        -- Click
        item.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                self:_onItemClick(itemConfig)
            end
        end)
        
        -- Right click (for submenu)
        if itemConfig.Submenu then
            item.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 or 
                   (input.UserInputType == Enum.UserInputType.Touch and itemConfig.Submenu) then
                    self:_showSubmenu(item, itemConfig.Submenu)
                end
            end)
        end
    end
    
    return item
end

function ContextMenu:_onItemHover(item, enter, itemConfig)
    if itemConfig.Divider then return end
    
    if enter then
        -- Animate hover
        TweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        }):Play()
        
        -- Show submenu if exists
        if itemConfig.Submenu then
            task.wait(0.3) -- Delay before showing submenu
            if item:IsDescendantOf(game) then
                self:_showSubmenu(item, itemConfig.Submenu)
            end
        end
    else
        TweenService:Create(item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
            BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        }):Play()
    end
end

function ContextMenu:_onItemClick(itemConfig)
    if itemConfig.Callback then
        task.spawn(itemConfig.Callback)
    end
    
    if not itemConfig.KeepOpen then
        self:Hide()
    end
end

function ContextMenu:_showSubmenu(parentItem, submenuConfig)
    if self.ActiveSubmenu then
        self.ActiveSubmenu:Hide()
    end
    
    -- Create submenu
    local submenu = ContextMenu.new(self.Config)
    submenu:SetItems(submenuConfig)
    
    -- Calculate position
    local parentPos = parentItem.AbsolutePosition
    local parentSize = parentItem.AbsoluteSize
    
    local submenuX = parentPos.X + parentSize.X + self.Config.SubmenuOffset
    local submenuY = parentPos.Y
    
    -- Ensure it stays on screen
    local viewportSize = workspace.CurrentCamera.ViewportSize
    if submenuX + 200 > viewportSize.X then
        submenuX = parentPos.X - 200 - self.Config.SubmenuOffset
    end
    
    submenu:Show(submenuX, submenuY)
    
    self.ActiveSubmenu = submenu
    
    -- Close submenu when parent item loses hover
    local connection
    connection = parentItem.MouseLeave:Connect(function()
        task.wait(0.1)
        if self.ActiveSubmenu == submenu then
            local mousePos = UserInputService:GetMouseLocation()
            local submenuPos = submenu.MenuFrame.AbsolutePosition
            local submenuSize = submenu.MenuFrame.AbsoluteSize
            
            -- Check if mouse is over submenu
            if mousePos.X < submenuPos.X or mousePos.X > submenuPos.X + submenuSize.X or
               mousePos.Y < submenuPos.Y or mousePos.Y > submenuPos.Y + submenuSize.Y then
                submenu:Hide()
                connection:Disconnect()
            end
        end
    end)
    
    -- Close submenu when it closes
    submenu.Closed:Connect(function()
        if self.ActiveSubmenu == submenu then
            self.ActiveSubmenu = nil
        end
    end)
end

function ContextMenu:_getIcon(iconName)
    -- Map icon names to asset IDs
    local iconMap = {
        Copy = "rbxassetid://7072716649",
        Paste = "rbxassetid://7072716650",
        Cut = "rbxassetid://7072716651",
        Delete = "rbxassetid://7072720899",
        Edit = "rbxassetid://7072716652",
        Settings = "rbxassetid://7072716653",
        Refresh = "rbxassetid://7072716654",
        Save = "rbxassetid://7072716655",
        Open = "rbxassetid://7072716656",
        Close = "rbxassetid://7072720899",
        Add = "rbxassetid://7072716648",
        Remove = "rbxassetid://7072720899",
        Search = "rbxassetid://7072716648",
        Help = "rbxassetid://7072716657",
        Info = "rbxassetid://7072716657",
        Warning = "rbxassetid://7072720898",
        Error = "rbxassetid://7072720899",
        Success = "rbxassetid://7072718176",
        Folder = "rbxassetid://7072716658",
        File = "rbxassetid://7072716659",
        Image = "rbxassetid://7072716660",
        Video = "rbxassetid://7072716661",
        Audio = "rbxassetid://7072716662",
        Document = "rbxassetid://7072716663"
    }
    
    return iconMap[iconName] or iconName or "rbxassetid://7072716648"
end

function ContextMenu:SetItems(items)
    self.Items = items or {}
end

function ContextMenu:AddItem(item)
    table.insert(self.Items, item)
end

function ContextMenu:RemoveItem(index)
    if index >= 1 and index <= #self.Items then
        table.remove(self.Items, index)
    end
end

function ContextMenu:ClearItems()
    self.Items = {}
end

function ContextMenu:Show(x, y)
    if self.Visible then return end
    
    self.Visible = true
    
    -- Create menu frame
    self:_createMenuFrame()
    
    -- Create menu items
    for i, itemConfig in ipairs(self.Items) do
        local item = self:_createMenuItem(itemConfig, i)
        item.Parent = self.ItemsContainer
    end
    
    -- Calculate size
    task.wait() -- Wait for layout to update
    local totalHeight = self.ItemsContainer.UIListLayout.AbsoluteContentSize.Y + 10
    
    -- Limit height
    if totalHeight > self.Config.MaxHeight then
        totalHeight = self.Config.MaxHeight
        self.ItemsContainer.Size = UDim2.new(1, -10, 1, -10)
        
        -- Add scrolling
        local scrolling = Instance.new("ScrollingFrame")
        scrolling.Name = "Scrolling"
        scrolling.BackgroundTransparency = 1
        scrolling.Size = UDim2.new(1, 0, 1, 0)
        scrolling.ScrollBarThickness = 4
        scrolling.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
        scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
        
        -- Move items to scrolling frame
        for _, child in ipairs(self.ItemsContainer:GetChildren()) do
            if child:IsA("Frame") then
                child.Parent = scrolling
            end
        end
        
        scrolling.Parent = self.ItemsContainer
    end
    
    -- Set position
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    if not x or not y then
        local mousePos = UserInputService:GetMouseLocation()
        x = mousePos.X
        y = mousePos.Y
    end
    
    -- Ensure it stays on screen
    if x + 200 > viewportSize.X then
        x = viewportSize.X - 210
    end
    
    if y + totalHeight > viewportSize.Y then
        y = viewportSize.Y - totalHeight - 10
    end
    
    self.MenuFrame.Position = UDim2.new(0, x, 0, y)
    
    -- Show overlay
    self.Overlay.Visible = true
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.5
    }):Play()
    
    -- Animate in
    self.MenuFrame.Size = UDim2.new(0, 200, 0, 0)
    self.MenuFrame.BackgroundTransparency = 1
    
    TweenService:Create(self.MenuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 200, 0, totalHeight),
        BackgroundTransparency = 0.1
    }):Play()
    
    -- Fire show event
    if self.ShowEvent then
        self.ShowEvent:Fire(x, y)
    end
end

function ContextMenu:Hide()
    if not self.Visible then return end
    
    self.Visible = false
    
    -- Hide active submenu
    if self.ActiveSubmenu then
        self.ActiveSubmenu:Hide()
        self.ActiveSubmenu = nil
    end
    
    -- Animate out
    if self.MenuFrame then
        TweenService:Create(self.MenuFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 200, 0, 0),
            BackgroundTransparency = 1
        }):Play()
    end
    
    -- Hide overlay
    TweenService:Create(self.Overlay, TweenInfo.new(0.3), {
        BackgroundTransparency = 1
    }):Play()
    
    task.wait(0.3)
    
    -- Clean up
    if self.MenuFrame then
        self.MenuFrame:Destroy()
        self.MenuFrame = nil
    end
    
    self.Overlay.Visible = false
    
    -- Fire close event
    if self.Closed then
        self.Closed:Fire()
    end
end

function ContextMenu:Toggle(x, y)
    if self.Visible then
        self:Hide()
    else
        self:Show(x, y)
    end
end

function ContextMenu:IsVisible()
    return self.Visible
end

function ContextMenu:SetTheme(theme)
    self.Config.Theme = theme
    
    -- Update colors based on theme
    if self.MenuFrame then
        if theme == "Dark" then
            self.MenuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        elseif theme == "Light" then
            self.MenuFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        end
    end
end

function ContextMenu:SetPosition(position)
    self.Config.Position = position
end

-- Event support
function ContextMenu:GetShowEvent()
    if not self.ShowEvent then
        self.ShowEvent = Instance.new("BindableEvent")
    end
    return self.ShowEvent.Event
end

function ContextMenu:GetClosedEvent()
    if not self.Closed then
        self.Closed = Instance.new("BindableEvent")
    end
    return self.Closed.Event
end

function ContextMenu:Destroy()
    self:Hide()
    
    if self.Container then
        self.Container:Destroy()
    end
    
    if self.ShowEvent then
        self.ShowEvent:Destroy()
    end
    
    if self.Closed then
        self.Closed:Destroy()
    end
end

return ContextMenu