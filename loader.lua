-- Celestial UI Loader with fluid animations

local Loader = {}
Loader.__index = Loader

function Loader.new(config)
    local self = setmetatable({}, Loader)
    
    self.Config = config or {}
    self.Modules = {}
    self.CurrentStep = 0
    self.TotalSteps = 0
    self.Completed = false
    
    self:_createUI()
    
    return self
end

function Loader:_createUI()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main container
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "CelestialLoader"
    self.Screen.ResetOnSpawn = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.Screen.IgnoreGuiInset = true
    self.Screen.Parent = playerGui
    
    -- Background
    self.Background = Instance.new("Frame")
    self.Background.Name = "Background"
    self.Background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    self.Background.BackgroundTransparency = 0
    self.Background.Size = UDim2.new(1, 0, 1, 0)
    self.Background.Parent = self.Screen
    
    -- Blur effect
    local blur = Instance.new("BlurEffect")
    blur.Size = 24
    blur.Parent = self.Background
    
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "Container"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 400, 0, 300)
    self.Container.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Container.Parent = self.Background
    
    -- Logo/Icon
    if self.Config.Logo and self.Config.Logo ~= "" then
        self.Logo = Instance.new("ImageLabel")
        self.Logo.Name = "Logo"
        self.Logo.BackgroundTransparency = 1
        self.Logo.Size = UDim2.new(0, 80, 0, 80)
        self.Logo.Position = UDim2.new(0.5, -40, 0.2, -40)
        self.Logo.AnchorPoint = Vector2.new(0.5, 0.5)
        self.Logo.Image = self.Config.Logo
        self.Logo.Parent = self.Container
    else
        -- Default logo
        self.Logo = Instance.new("Frame")
        self.Logo.Name = "Logo"
        self.Logo.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        self.Logo.Size = UDim2.new(0, 80, 0, 80)
        self.Logo.Position = UDim2.new(0.5, -40, 0.2, -40)
        self.Logo.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 20)
        corner.Parent = self.Logo
        
        -- Sparkle effect
        local sparkle = Instance.new("ImageLabel")
        sparkle.Name = "Sparkle"
        sparkle.BackgroundTransparency = 1
        sparkle.Size = UDim2.new(1, 0, 1, 0)
        sparkle.Image = "rbxassetid://"
        sparkle.ImageColor3 = Color3.fromRGB(255, 255, 255)
        sparkle.ImageTransparency = 0.5
        sparkle.Parent = self.Logo
        
        self.Logo.Parent = self.Container
    end
    
    -- Title
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.BackgroundTransparency = 1
    self.Title.Size = UDim2.new(1, 0, 0, 40)
    self.Title.Position = UDim2.new(0, 0, 0.4, 0)
    self.Title.Font = Enum.Font.GothamBold
    self.Title.Text = self.Config.Title or "Celestial UI"
    self.Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    self.Title.TextSize = 28
    self.Title.TextTransparency = 0
    self.Title.Parent = self.Container
    
    -- Subtitle
    self.Subtitle = Instance.new("TextLabel")
    self.Subtitle.Name = "Subtitle"
    self.Subtitle.BackgroundTransparency = 1
    self.Subtitle.Size = UDim2.new(1, 0, 0, 20)
    self.Subtitle.Position = UDim2.new(0, 0, 0.5, 0)
    self.Subtitle.Font = Enum.Font.Gotham
    self.Subtitle.Text = self.Config.Subtitle or "Initializing..."
    self.Subtitle.TextColor3 = Color3.fromRGB(180, 180, 190)
    self.Subtitle.TextSize = 16
    self.Subtitle.TextTransparency = 0
    self.Subtitle.Parent = self.Container
    
    -- Progress container
    self.ProgressContainer = Instance.new("Frame")
    self.ProgressContainer.Name = "ProgressContainer"
    self.ProgressContainer.BackgroundTransparency = 1
    self.ProgressContainer.Size = UDim2.new(1, -40, 0, 20)
    self.ProgressContainer.Position = UDim2.new(0, 20, 0.7, 0)
    self.ProgressContainer.Parent = self.Container
    
    -- Progress bar background
    self.ProgressBackground = Instance.new("Frame")
    self.ProgressBackground.Name = "ProgressBackground"
    self.ProgressBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    self.ProgressBackground.BackgroundTransparency = 0.2
    self.ProgressBackground.Size = UDim2.new(1, 0, 0, 4)
    self.ProgressBackground.Position = UDim2.new(0, 0, 0.5, -2)
    self.ProgressBackground.AnchorPoint = Vector2.new(0, 0.5)
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = self.ProgressBackground
    
    self.ProgressBackground.Parent = self.ProgressContainer
    
    -- Progress bar fill
    self.ProgressFill = Instance.new("Frame")
    self.ProgressFill.Name = "ProgressFill"
    self.ProgressFill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    self.ProgressFill.BackgroundTransparency = 0
    self.ProgressFill.Size = UDim2.new(0, 0, 0, 4)
    self.ProgressFill.Position = UDim2.new(0, 0, 0.5, -2)
    self.ProgressFill.AnchorPoint = Vector2.new(0, 0.5)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = self.ProgressFill
    
    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 180, 255))
    }
    gradient.Rotation = 90
    gradient.Parent = self.ProgressFill
    
    self.ProgressFill.Parent = self.ProgressContainer
    
    -- Progress text
    self.ProgressText = Instance.new("TextLabel")
    self.ProgressText.Name = "ProgressText"
    self.ProgressText.BackgroundTransparency = 1
    self.ProgressText.Size = UDim2.new(1, 0, 0, 20)
    self.ProgressText.Position = UDim2.new(0, 0, 0.6, 10)
    self.ProgressText.Font = Enum.Font.Gotham
    self.ProgressText.Text = "0%"
    self.ProgressText.TextColor3 = Color3.fromRGB(150, 150, 160)
    self.ProgressText.TextSize = 14
    self.ProgressText.Parent = self.ProgressContainer
    
    -- Steps container
    if self.Config.ShowSteps then
        self.StepsContainer = Instance.new("Frame")
        self.StepsContainer.Name = "StepsContainer"
        self.StepsContainer.BackgroundTransparency = 1
        self.StepsContainer.Size = UDim2.new(1, -40, 0, 60)
        self.StepsContainer.Position = UDim2.new(0, 20, 0.8, 0)
        self.StepsContainer.Parent = self.Container
        
        self.StepLabels = {}
    end
    
    -- Water droplets animation
    self:_createWaterEffects()
end

function Loader:_createWaterEffects()
    -- Create floating water droplets
    for i = 1, 5 do
        task.spawn(function()
            while self.Screen and self.Screen.Parent do
                local droplet = Instance.new("Frame")
                droplet.Name = "Droplet"
                droplet.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
                droplet.BackgroundTransparency = 0.7
                droplet.Size = UDim2.new(0, math.random(4, 10), 0, math.random(4, 10))
                droplet.Position = UDim2.new(
                    math.random() * 0.9 + 0.05,
                    0,
                    -0.1,
                    0
                )
                droplet.AnchorPoint = Vector2.new(0.5, 0.5)
                droplet.ZIndex = -1
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = droplet
                
                droplet.Parent = self.Background
                
                -- Animate droplet falling
                local targetY = 1.1
                local duration = 2 + math.random() * 2
                local startTime = tick()
                
                while droplet and droplet.Parent do
                    local elapsed = tick() - startTime
                    local progress = elapsed / duration
                    
                    if progress >= 1 then
                        break
                    end
                    
                    -- Sine wave for horizontal movement
                    local wave = math.sin(progress * math.pi * 4) * 0.1
                    
                    droplet.Position = UDim2.new(
                        0.5 + wave,
                        0,
                        -0.1 + progress * targetY,
                        0
                    )
                    
                    droplet.BackgroundTransparency = 0.7 + progress * 0.3
                    
                    task.wait()
                end
                
                if droplet then
                    droplet:Destroy()
                end
                
                task.wait(math.random(1, 3))
            end
        end)
    end
end

function Loader:AddStep(name, weight)
    weight = weight or 1
    
    local step = {
        Name = name,
        Weight = weight,
        Completed = false
    }
    
    table.insert(self.Modules, step)
    self.TotalSteps = self.TotalSteps + weight
    
    -- Create step label if showing steps
    if self.Config.ShowSteps and self.StepsContainer then
        local stepLabel = Instance.new("TextLabel")
        stepLabel.Name = "Step_" .. name
        stepLabel.BackgroundTransparency = 1
        stepLabel.Size = UDim2.new(0.5, -5, 0, 20)
        stepLabel.Position = UDim2.new(
            #self.StepLabels % 2 * 0.5,
            0,
            math.floor(#self.StepLabels / 2) * 25,
            0
        )
        stepLabel.Font = Enum.Font.Gotham
        stepLabel.Text = "○ " .. name
        stepLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
        stepLabel.TextSize = 12
        stepLabel.TextXAlignment = Enum.TextXAlignment.Left
        stepLabel.Parent = self.StepsContainer
        
        table.insert(self.StepLabels, {
            Label = stepLabel,
            Step = step
        })
    end
end

function Loader:UpdateStep(name, progress)
    for _, step in ipairs(self.Modules) do
        if step.Name == name then
            step.Progress = progress
            break
        end
    end
    
    self:_updateProgress()
end

function Loader:CompleteStep(name)
    for _, step in ipairs(self.Modules) do
        if step.Name == name then
            step.Completed = true
            step.Progress = 1
            break
        end
    end
    
    self.CurrentStep = self.CurrentStep + 1
    
    -- Update step label
    if self.Config.ShowSteps then
        for _, stepLabel in ipairs(self.StepLabels) do
            if stepLabel.Step.Name == name then
                stepLabel.Label.Text = "✓ " .. name
                stepLabel.Label.TextColor3 = Color3.fromRGB(80, 200, 120)
                
                -- Animate completion
                game:GetService("TweenService"):Create(
                    stepLabel.Label,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {TextTransparency = 0}
                ):Play()
            end
        end
    end
    
    self:_updateProgress()
end

function Loader:_updateProgress()
    local totalWeight = 0
    local completedWeight = 0
    
    for _, step in ipairs(self.Modules) do
        totalWeight = totalWeight + step.Weight
        if step.Completed then
            completedWeight = completedWeight + step.Weight
        elseif step.Progress then
            completedWeight = completedWeight + (step.Weight * step.Progress)
        end
    end
    
    local progress = totalWeight > 0 and completedWeight / totalWeight or 0
    
    -- Animate progress bar
    if self.ProgressFill then
        game:GetService("TweenService"):Create(
            self.ProgressFill,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(progress, 0, 0, 4)}
        ):Play()
    end
    
    if self.ProgressText then
        self.ProgressText.Text = string.format("%d%%", math.floor(progress * 100))
    end
    
    -- Update subtitle
    if self.Subtitle and #self.Modules > 0 then
        local currentModule = self.Modules[math.min(self.CurrentStep + 1, #self.Modules)]
        if currentModule then
            self.Subtitle.Text = currentModule.Name
        end
    end
end

function Loader:SetMessage(message)
    if self.Subtitle then
        self.Subtitle.Text = message
    end
end

function Loader:Complete()
    if self.Completed then return end
    self.Completed = true
    
    -- Complete all steps
    for _, step in ipairs(self.Modules) do
        if not step.Completed then
            step.Completed = true
        end
    end
    
    self:_updateProgress()
    
    -- Animate completion
    task.wait(0.5)
    
    -- Fade out
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local tweens = {}
    
    if self.Title then
        table.insert(tweens, game:GetService("TweenService"):Create(
            self.Title,
            tweenInfo,
            {TextTransparency = 1}
        ))
    end
    
    if self.Subtitle then
        table.insert(tweens, game:GetService("TweenService"):Create(
            self.Subtitle,
            tweenInfo,
            {TextTransparency = 1}
        ))
    end
    
    if self.ProgressContainer then
        table.insert(tweens, game:GetService("TweenService"):Create(
            self.ProgressContainer,
            tweenInfo,
            {BackgroundTransparency = 1}
        ))
    end
    
    if self.Logo then
        table.insert(tweens, game:GetService("TweenService"):Create(
            self.Logo,
            TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}
        ))
    end
    
    -- Start all tweens
    for _, tween in ipairs(tweens) do
        tween:Play()
    end
    
    -- Fade background
    task.wait(0.5)
    
    if self.Background then
        game:GetService("TweenService"):Create(
            self.Background,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()
    end
    
    -- Destroy after animation
    task.wait(1)
    self:Destroy()
end

function Loader:Destroy()
    if self.Screen then
        self.Screen:Destroy()
    end
end

return Loader