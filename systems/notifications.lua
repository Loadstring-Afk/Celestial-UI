-- Premium notification/toast system with fluid animations

local Notifications = {}
Notifications.__index = Notifications

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

function Notifications.new(config)
    local self = setmetatable({}, Notifications)
    
    self.Config = config or {
        Position = "TopRight",
        MaxNotifications = 5,
        Duration = 5,
        Spacing = 10,
        Animation = "Spring",
        Stacking = true,
        Sounds = true
    }
    
    self.Notifications = {}
    self.Queue = {}
    self.Sounds = {}
    
    self:_createContainer()
    self:_loadSounds()
    
    return self
end

function Notifications:_createContainer()
    -- Main container
    self.Container = Instance.new("ScreenGui")
    self.Container.Name = "CelestialNotifications"
    self.Container.ResetOnSpawn = false
    self.Container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.Container.IgnoreGuiInset = true
    self.Container.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

function Notifications:_loadSounds()
    -- Notification sounds
    self.Sounds = {
        Info = "rbxassetid://9123733197",
        Success = "rbxassetid://9123733198",
        Warning = "rbxassetid://9123733199",
        Error = "rbxassetid://9123733200"
    }
end

function Notifications:_playSound(soundType)
    if not self.Config.Sounds then return end
    
    local soundId = self.Sounds[soundType] or self.Sounds.Info
    
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.3
        sound.Parent = workspace
        sound:Play()
        
        game:GetService("Debris"):AddItem(sound, 2)
    end)
end

function Notifications:_getPosition(index)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local position = self.Config.Position
    local spacing = self.Config.Spacing
    
    if position == "TopRight" then
        return UDim2.new(
            1, -20,
            0, 20 + (index - 1) * (80 + spacing)
        )
    elseif position == "TopLeft" then
        return UDim2.new(
            0, 20,
            0, 20 + (index - 1) * (80 + spacing)
        )
    elseif position == "BottomRight" then
        return UDim2.new(
            1, -20,
            1, -20 - (index - 1) * (80 + spacing)
        )
    elseif position == "BottomLeft" then
        return UDim2.new(
            0, 20,
            1, -20 - (index - 1) * (80 + spacing)
        )
    elseif position == "TopCenter" then
        return UDim2.new(
            0.5, -175,
            0, 20 + (index - 1) * (80 + spacing)
        )
    elseif position == "BottomCenter" then
        return UDim2.new(
            0.5, -175,
            1, -20 - (index - 1) * (80 + spacing)
        )
    else
        return UDim2.new(1, -20, 0, 20 + (index - 1) * (80 + spacing))
    end
end

function Notifications:_createNotification(config)
    local notification = {
        Id = #self.Notifications + 1,
        Config = config,
        Created = tick(),
        Destroying = false
    }
    
    -- Create UI
    notification.UI = Instance.new("Frame")
    notification.UI.Name = "Notification_" .. notification.Id
    notification.UI.BackgroundColor3 = self:_getBackgroundColor(config.Type)
    notification.UI.BackgroundTransparency = 0.1
    notification.UI.Size = UDim2.new(0, 350, 0, 0)
    notification.UI.Position = self:_getPosition(#self.Notifications + 1)
    notification.UI.ClipsDescendants = true
    notification.UI.ZIndex = 10000
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification.UI
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.7
    stroke.Thickness = 2
    stroke.Parent = notification.UI
    
    -- Inner glow
    local innerGlow = Instance.new("Frame")
    innerGlow.Name = "InnerGlow"
    innerGlow.BackgroundColor3 = Color3.new(1, 1, 1)
    innerGlow.BackgroundTransparency = 0.95
    innerGlow.Size = UDim2.new(1, 0, 1, 0)
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 12)
    innerCorner.Parent = innerGlow
    
    innerGlow.Parent = notification.UI
    
    -- Header
    notification.Header = Instance.new("Frame")
    notification.Header.Name = "Header"
    notification.Header.BackgroundTransparency = 1
    notification.Header.Size = UDim2.new(1, -20, 0, 30)
    notification.Header.Position = UDim2.new(0, 10, 0, 10)
    notification.Header.Parent = notification.UI
    
    -- Icon
    if config.Icon or config.Type then
        notification.Icon = Instance.new("ImageLabel")
        notification.Icon.Name = "Icon"
        notification.Icon.BackgroundTransparency = 1
        notification.Icon.Size = UDim2.new(0, 24, 0, 24)
        notification.Icon.Position = UDim2.new(0, 0, 0, 3)
        notification.Icon.Image = self:_getIcon(config.Icon or config.Type)
        notification.Icon.ImageColor3 = self:_getIconColor(config.Type)
        notification.Icon.Parent = notification.Header
    end
    
    -- Title
    notification.Title = Instance.new("TextLabel")
    notification.Title.Name = "Title"
    notification.Title.BackgroundTransparency = 1
    notification.Title.Size = UDim2.new(1, config.Icon and -34 or -10, 0, 20)
    notification.Title.Position = UDim2.new(0, config.Icon and 34 : 10, 0, 0)
    notification.Title.Font = Enum.Font.GothamBold
    notification.Title.Text = config.Title or "Notification"
    notification.Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    notification.Title.TextSize = 14
    notification.Title.TextXAlignment = Enum.TextXAlignment.Left
    notification.Title.TextTruncate = Enum.TextTruncate.AtEnd
    notification.Title.Parent = notification.Header
    
    -- Time
    notification.TimeLabel = Instance.new("TextLabel")
    notification.TimeLabel.Name = "Time"
    notification.TimeLabel.BackgroundTransparency = 1
    notification.TimeLabel.Size = UDim2.new(1, config.Icon and -34 or -10, 0, 10)
    notification.TimeLabel.Position = UDim2.new(0, config.Icon and 34 : 10, 0, 20)
    notification.TimeLabel.Font = Enum.Font.Gotham
    notification.TimeLabel.Text = "Just now"
    notification.TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    notification.TimeLabel.TextSize = 10
    notification.TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    notification.TimeLabel.Parent = notification.Header
    
    -- Close button
    notification.CloseButton = Instance.new("ImageButton")
    notification.CloseButton.Name = "Close"
    notification.CloseButton.BackgroundTransparency = 1
    notification.CloseButton.Size = UDim2.new(0, 20, 0, 20)
    notification.CloseButton.Position = UDim2.new(1, -20, 0, 5)
    notification.CloseButton.AnchorPoint = Vector2.new(1, 0)
    notification.CloseButton.Image = "rbxassetid://7072720899"
    notification.CloseButton.ImageColor3 = Color3.fromRGB(200, 200, 210)
    notification.CloseButton.ImageTransparency = 0.5
    notification.CloseButton.Parent = notification.Header
    
    -- Content
    notification.Content = Instance.new("Frame")
    notification.Content.Name = "Content"
    notification.Content.BackgroundTransparency = 1
    notification.Content.Size = UDim2.new(1, -20, 0, 0)
    notification.Content.Position = UDim2.new(0, 10, 0, 45)
    notification.Content.AutomaticSize = Enum.AutomaticSize.Y
    notification.Content.Parent = notification.UI
    
    -- Message
    notification.Message = Instance.new("TextLabel")
    notification.Message.Name = "Message"
    notification.Message.BackgroundTransparency = 1
    notification.Message.Size = UDim2.new(1, 0, 0, 0)
    notification.Message.Font = Enum.Font.Gotham
    notification.Message.Text = config.Message or ""
    notification.Message.TextColor3 = Color3.fromRGB(220, 220, 225)
    notification.Message.TextSize = 12
    notification.Message.TextWrapped = true
    notification.Message.TextXAlignment = Enum.TextXAlignment.Left
    notification.Message.AutomaticSize = Enum.AutomaticSize.Y
    notification.Message.Parent = notification.Content
    
    -- Actions (if any)
    if config.Actions and #config.Actions > 0 then
        notification.ActionsContainer = Instance.new("Frame")
        notification.ActionsContainer.Name = "Actions"
        notification.ActionsContainer.BackgroundTransparency = 1
        notification.ActionsContainer.Size = UDim2.new(1, 0, 0, 30)
        notification.ActionsContainer.Position = UDim2.new(0, 0, 0, notification.Message.TextBounds.Y + 10)
        notification.ActionsContainer.Parent = notification.Content
        
        local actionsLayout = Instance.new("UIListLayout")
        actionsLayout.FillDirection = Enum.FillDirection.Horizontal
        actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        actionsLayout.Padding = UDim.new(0, 10)
        actionsLayout.Parent = notification.ActionsContainer
        
        for i, action in ipairs(config.Actions) do
            local actionButton = Instance.new("TextButton")
            actionButton.Name = "Action_" .. i
            actionButton.BackgroundColor3 = self:_getActionColor(action.Type or "Default")
            actionButton.BackgroundTransparency = 0.2
            actionButton.Size = UDim2.new(0, 80, 0, 25)
            actionButton.Font = Enum.Font.Gotham
            actionButton.Text = action.Text or "Action"
            actionButton.TextColor3 = Color3.fromRGB(240, 240, 245)
            actionButton.TextSize = 12
            
            local actionCorner = Instance.new("UICorner")
            actionCorner.CornerRadius = UDim.new(0, 6)
            actionCorner.Parent = actionButton
            
            actionButton.Parent = notification.ActionsContainer
            
            -- Action click event
            actionButton.MouseButton1Click:Connect(function()
                if action.Callback then
                    task.spawn(action.Callback)
                end
                
                if action.Dismiss then
                    self:Dismiss(notification.Id)
                end
            end)
        end
    end
    
    -- Progress bar (if duration is set)
    if config.Duration and config.Duration > 0 then
        notification.ProgressContainer = Instance.new("Frame")
        notification.ProgressContainer.Name = "Progress"
        notification.ProgressContainer.BackgroundColor3 = Color3.new(0, 0, 0)
        notification.ProgressContainer.BackgroundTransparency = 0.7
        notification.ProgressContainer.Size = UDim2.new(1, 0, 0, 2)
        notification.ProgressContainer.Position = UDim2.new(0, 0, 1, -2)
        notification.ProgressContainer.AnchorPoint = Vector2.new(0, 1)
        notification.ProgressContainer.Parent = notification.UI
        
        notification.ProgressBar = Instance.new("Frame")
        notification.ProgressBar.Name = "ProgressBar"
        notification.ProgressBar.BackgroundColor3 = self:_getProgressColor(config.Type)
        notification.ProgressBar.BackgroundTransparency = 0
        notification.ProgressBar.Size = UDim2.new(1, 0, 1, 0)
        notification.ProgressBar.Parent = notification.ProgressContainer
    end
    
    notification.UI.Parent = self.Container
    
    return notification
end

function Notifications:_getBackgroundColor(type)
    if type == "Success" then
        return Color3.fromRGB(40, 60, 40)
    elseif type == "Warning" then
        return Color3.fromRGB(60, 50, 30)
    elseif type == "Error" then
        return Color3.fromRGB(60, 40, 40)
    elseif type == "Info" then
        return Color3.fromRGB(40, 50, 60)
    else
        return Color3.fromRGB(40, 40, 45)
    end
end

function Notifications:_getIconColor(type)
    if type == "Success" then
        return Color3.fromRGB(80, 200, 120)
    elseif type == "Warning" then
        return Color3.fromRGB(255, 180, 60)
    elseif type == "Error" then
        return Color3.fromRGB(255, 80, 80)
    elseif type == "Info" then
        return Color3.fromRGB(80, 140, 255)
    else
        return Color3.fromRGB(180, 180, 190)
    end
end

function Notifications:_getProgressColor(type)
    if type == "Success" then
        return Color3.fromRGB(80, 200, 120)
    elseif type == "Warning" then
        return Color3.fromRGB(255, 180, 60)
    elseif type == "Error" then
        return Color3.fromRGB(255, 80, 80)
    elseif type == "Info" then
        return Color3.fromRGB(80, 140, 255)
    else
        return Color3.fromRGB(180, 180, 190)
    end
end

function Notifications:_getActionColor(type)
    if type == "Primary" then
        return Color3.fromRGB(80, 140, 255)
    elseif type == "Success" then
        return Color3.fromRGB(80, 200, 120)
    elseif type == "Warning" then
        return Color3.fromRGB(255, 180, 60)
    elseif type == "Error" then
        return Color3.fromRGB(255, 80, 80)
    else
        return Color3.fromRGB(60, 60, 65)
    end
end

function Notifications:_getIcon(iconName)
    if iconName == "Success" then
        return "rbxassetid://7072718176" -- Check icon
    elseif iconName == "Warning" then
        return "rbxassetid://7072720898" -- Warning icon
    elseif iconName == "Error" then
        return "rbxassetid://7072720899" -- X icon
    elseif iconName == "Info" then
        return "rbxassetid://7072716648" -- Info icon
    else
        return iconName or "rbxassetid://7072716648"
    end
end

function Notifications:_animateIn(notification)
    local targetHeight = 80
    
    if notification.Message then
        targetHeight = targetHeight + notification.Message.TextBounds.Y
    end
    
    if notification.ActionsContainer then
        targetHeight = targetHeight + 30
    end
    
    -- Set initial state
    notification.UI.Size = UDim2.new(0, 350, 0, 0)
    notification.UI.BackgroundTransparency = 1
    
    -- Animate in
    TweenService:Create(notification.UI, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 350, 0, targetHeight),
        BackgroundTransparency = 0.1
    }):Play()
    
    -- Slide in from position
    local startPosition = notification.UI.Position
    local slideFrom = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + 400,
        startPosition.Y.Scale,
        startPosition.Y.Offset
    )
    
    notification.UI.Position = slideFrom
    TweenService:Create(notification.UI, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = startPosition
    }):Play()
    
    -- Play sound
    self:_playSound(notification.Config.Type or "Info")
end

function Notifications:_animateOut(notification, callback)
    if notification.Destroying then return end
    notification.Destroying = true
    
    -- Slide out
    local endPosition = UDim2.new(
        notification.UI.Position.X.Scale,
        notification.UI.Position.X.Offset + 400,
        notification.UI.Position.Y.Scale,
        notification.UI.Position.Y.Offset
    )
    
    TweenService:Create(notification.UI, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = endPosition,
        BackgroundTransparency = 1
    }):Play()
    
    -- Shrink
    TweenService:Create(notification.UI, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 350, 0, 0)
    }):Play()
    
    -- Destroy after animation
    task.delay(0.3, function()
        if notification.UI and notification.UI.Parent then
            notification.UI:Destroy()
        end
        
        if callback then
            callback()
        end
    end)
end

function Notifications:_updatePositions()
    for i, notification in ipairs(self.Notifications) do
        if notification.UI and not notification.Destroying then
            local targetPosition = self:_getPosition(i)
            
            TweenService:Create(notification.UI, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPosition
            }):Play()
        end
    end
end

function Notifications:_updateTimeLabels()
    for _, notification in ipairs(self.Notifications) do
        if notification.TimeLabel and not notification.Destroying then
            local elapsed = tick() - notification.Created
            local timeText = ""
            
            if elapsed < 60 then
                timeText = "Just now"
            elseif elapsed < 3600 then
                local minutes = math.floor(elapsed / 60)
                timeText = string.format("%d minute%s ago", minutes, minutes == 1 and "" or "s")
            else
                local hours = math.floor(elapsed / 3600)
                timeText = string.format("%d hour%s ago", hours, hours == 1 and "" or "s")
            end
            
            notification.TimeLabel.Text = timeText
        end
    end
end

function Notifications:_startProgress(notification, duration)
    if not notification.ProgressBar then return end
    
    local startTime = tick()
    local endTime = startTime + duration
    
    while tick() < endTime do
        if notification.Destroying then break end
        
        local progress = 1 - ((tick() - startTime) / duration)
        notification.ProgressBar.Size = UDim2.new(progress, 0, 1, 0)
        
        task.wait(0.1)
    end
    
    if not notification.Destroying then
        self:Dismiss(notification.Id)
    end
end

function Notifications:Notify(config)
    local notificationConfig = {
        Title = config.Title or "Notification",
        Message = config.Message or "",
        Type = config.Type or "Info",
        Icon = config.Icon,
        Duration = config.Duration or self.Config.Duration,
        Actions = config.Actions or {},
        Callback = config.Callback
    }
    
    -- Check if we're at max notifications
    if #self.Notifications >= self.Config.MaxNotifications then
        if self.Config.Stacking then
            -- Remove oldest notification
            self:Dismiss(self.Notifications[1].Id)
        else
            -- Queue the notification
            table.insert(self.Queue, notificationConfig)
            return #self.Queue
        end
    end
    
    -- Create notification
    local notification = self:_createNotification(notificationConfig)
    table.insert(self.Notifications, notification)
    
    -- Animate in
    self:_animateIn(notification)
    
    -- Setup events
    if notification.CloseButton then
        notification.CloseButton.MouseButton1Click:Connect(function()
            self:Dismiss(notification.Id)
        end)
    end
    
    -- Update positions
    self:_updatePositions()
    
    -- Start progress if duration is set
    if notificationConfig.Duration and notificationConfig.Duration > 0 then
        task.spawn(function()
            self:_startProgress(notification, notificationConfig.Duration)
        end)
    end
    
    -- Start time updates
    task.spawn(function()
        while not notification.Destroying do
            self:_updateTimeLabels()
            task.wait(10)
        end
    end)
    
    return notification.Id
end

function Notifications:Dismiss(id)
    for i, notification in ipairs(self.Notifications) do
        if notification.Id == id and not notification.Destroying then
            self:_animateOut(notification, function()
                -- Remove from list
                table.remove(self.Notifications, i)
                
                -- Update positions
                self:_updatePositions()
                
                -- Show next queued notification
                if #self.Queue > 0 then
                    local nextConfig = table.remove(self.Queue, 1)
                    task.wait(0.5)
                    self:Notify(nextConfig)
                end
            end)
            break
        end
    end
end

function Notifications:DismissAll()
    for _, notification in ipairs(self.Notifications) do
        if not notification.Destroying then
            self:_animateOut(notification)
        end
    end
    
    self.Notifications = {}
    self.Queue = {}
end

function Notifications:GetNotification(id)
    for _, notification in ipairs(self.Notifications) do
        if notification.Id == id then
            return notification
        end
    end
    return nil
end

function Notifications:Update(id, config)
    for _, notification in ipairs(self.Notifications) do
        if notification.Id == id and not notification.Destroying then
            -- Update title
            if config.Title then
                notification.Title.Text = config.Title
            end
            
            -- Update message
            if config.Message then
                notification.Message.Text = config.Message
                
                -- Update size
                local targetHeight = 80 + notification.Message.TextBounds.Y
                if notification.ActionsContainer then
                    targetHeight = targetHeight + 30
                end
                
                TweenService:Create(notification.UI, TweenInfo.new(0.3), {
                    Size = UDim2.new(0, 350, 0, targetHeight)
                }):Play()
            end
            
            -- Update type/color
            if config.Type then
                notification.UI.BackgroundColor3 = self:_getBackgroundColor(config.Type)
                if notification.Icon then
                    notification.Icon.ImageColor3 = self:_getIconColor(config.Type)
                end
            end
            
            break
        end
    end
end

function Notifications:SetPosition(position)
    self.Config.Position = position
    self:_updatePositions()
end

function Notifications:SetMaxNotifications(max)
    self.Config.MaxNotifications = max
    
    -- Remove excess notifications
    while #self.Notifications > max do
        self:Dismiss(self.Notifications[1].Id)
    end
end

function Notifications:ClearQueue()
    self.Queue = {}
end

function Notifications:Destroy()
    self:DismissAll()
    
    if self.Container then
        self.Container:Destroy()
    end
end

-- Convenience methods
function Notifications:Success(title, message, duration)
    return self:Notify({
        Title = title,
        Message = message,
        Type = "Success",
        Duration = duration
    })
end

function Notifications:Error(title, message, duration)
    return self:Notify({
        Title = title,
        Message = message,
        Type = "Error",
        Duration = duration
    })
end

function Notifications:Warning(title, message, duration)
    return self:Notify({
        Title = title,
        Message = message,
        Type = "Warning",
        Duration = duration
    })
end

function Notifications:Info(title, message, duration)
    return self:Notify({
        Title = title,
        Message = message,
        Type = "Info",
        Duration = duration
    })
end

return Notifications