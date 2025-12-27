-- Premium tooltip system with smart edge detection

local Tooltip = {}
Tooltip.__index = Tooltip

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function Tooltip.new(config)
    local self = setmetatable({}, Tooltip)
    
    self.Config = config or {
        Position = "Top",
        Offset = 10,
        MaxWidth = 200,
        ShowDelay = 0.5,
        HideDelay = 0.1,
        Animation = "Spring"
    }
    
    self.Target = nil
    self.Visible = false
    self.ShowTimer = nil
    self.HideTimer = nil
    self.Connection = nil
    
    self:_createTooltip()
    
    return self
end

function Tooltip:_createTooltip()
    -- Main tooltip container
    self.Container = Instance.new("ScreenGui")
    self.Container.Name = "CelestialTooltip"
    self.Container.ResetOnSpawn = false
    self.Container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.Container.IgnoreGuiInset = true
    self.Container.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Tooltip frame
    self.Tooltip = Instance.new("Frame")
    self.Tooltip.Name = "Tooltip"
    self.Tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    self.Tooltip.BackgroundTransparency = 0.1
    self.Tooltip.Size = UDim2.new(0, self.Config.MaxWidth, 0, 0)
    self.Tooltip.Position = UDim2.new(0, 0, 0, 0)
    self.Tooltip.Visible = false
    self.Tooltip.ZIndex = 10000
    self.Tooltip.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.Tooltip
    
    -- Shadow
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.new(0, 0, 0)
    shadow.Transparency = 0.7
    shadow.Thickness = 2
    shadow.Parent = self.Tooltip
    
    -- Inner glow
    local innerGlow = Instance.new("Frame")
    innerGlow.Name = "InnerGlow"
    innerGlow.BackgroundColor3 = Color3.new(1, 1, 1)
    innerGlow.BackgroundTransparency = 0.95
    innerGlow.Size = UDim2.new(1, 0, 1, 0)
    innerGlow.Position = UDim2.new(0, 0, 0, 0)
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 8)
    innerCorner.Parent = innerGlow
    
    innerGlow.Parent = self.Tooltip
    
    -- Content
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, -20, 0, 0)
    self.Content.Position = UDim2.new(0, 10, 0, 10)
    self.Content.AutomaticSize = Enum.AutomaticSize.Y
    self.Content.Parent = self.Tooltip
    
    -- Title (optional)
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.BackgroundTransparency = 1
    self.Title.Size = UDim2.new(1, 0, 0, 0)
    self.Title.Font = Enum.Font.GothamBold
    self.Title.TextColor3 = Color3.fromRGB(240, 240, 245)
    self.Title.TextSize = 14
    self.Title.TextWrapped = true
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.AutomaticSize = Enum.AutomaticSize.Y
    self.Title.Visible = false
    self.Title.Parent = self.Content
    
    -- Description
    self.Description = Instance.new("TextLabel")
    self.Description.Name = "Description"
    self.Description.BackgroundTransparency = 1
    self.Description.Size = UDim2.new(1, 0, 0, 0)
    self.Description.Position = UDim2.new(0, 0, 0, 0)
    self.Description.Font = Enum.Font.Gotham
    self.Description.TextColor3 = Color3.fromRGB(220, 220, 225)
    self.Description.TextSize = 12
    self.Description.TextWrapped = true
    self.Description.TextXAlignment = Enum.TextXAlignment.Left
    self.Description.AutomaticSize = Enum.AutomaticSize.Y
    self.Description.Visible = false
    self.Description.Parent = self.Content
    
    -- Arrow (for positioning)
    self.Arrow = Instance.new("Frame")
    self.Arrow.Name = "Arrow"
    self.Arrow.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    self.Arrow.BackgroundTransparency = 0.1
    self.Arrow.Size = UDim2.new(0, 12, 0, 12)
    self.Arrow.Position = UDim2.new(0.5, -6, 1, -6)
    self.Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Arrow.Rotation = 45
    self.Arrow.Visible = false
    self.Arrow.ZIndex = 9999
    
    local arrowStroke = Instance.new("UIStroke")
    arrowStroke.Color = Color3.new(0, 0, 0)
    arrowStroke.Transparency = 0.7
    arrowStroke.Thickness = 2
    arrowStroke.Parent = self.Arrow
    
    self.Arrow.Parent = self.Container
    
    self.Tooltip.Parent = self.Container
end

function Tooltip:Attach(target, content, title)
    if self.Target then
        self:Detach()
    end
    
    self.Target = target
    self.Content = content or ""
    self.TitleText = title or ""
    
    -- Update tooltip content
    self:UpdateContent(content, title)
    
    -- Setup events
    self:_setupEvents()
end

function Tooltip:_setupEvents()
    if not self.Target then return end
    
    -- Mouse enter
    self.Target.MouseEnter:Connect(function()
        self:_onTargetEnter()
    end)
    
    -- Mouse leave
    self.Target.MouseLeave:Connect(function()
        self:_onTargetLeave()
    end)
    
    -- Mouse move
    if self.Target:IsA("GuiObject") then
        self.Target.MouseMoved:Connect(function()
            if self.Visible then
                self:_updatePosition()
            end
        end)
    end
    
    -- Touch support
    if UserInputService.TouchEnabled then
        local touchStart = nil
        local touchTime = nil
        
        self.Target.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                touchStart = input.Position
                touchTime = tick()
                
                -- Show tooltip after hold
                task.spawn(function()
                    task.wait(self.Config.ShowDelay)
                    if touchStart and tick() - touchTime >= self.Config.ShowDelay then
                        self:Show()
                    end
                end)
            end
        end)
        
        self.Target.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                touchStart = nil
                touchTime = nil
                self:Hide()
            end
        end)
    end
end

function Tooltip:_onTargetEnter()
    if self.ShowTimer then
        self.ShowTimer:Disconnect()
    end
    
    if self.HideTimer then
        self.HideTimer:Disconnect()
        self.HideTimer = nil
    end
    
    -- Schedule showing
    self.ShowTimer = task.delay(self.Config.ShowDelay, function()
        self:Show()
    end)
end

function Tooltip:_onTargetLeave()
    if self.ShowTimer then
        self.ShowTimer:Disconnect()
        self.ShowTimer = nil
    end
    
    -- Schedule hiding
    if self.Visible then
        if self.HideTimer then
            self.HideTimer:Disconnect()
        end
        
        self.HideTimer = task.delay(self.Config.HideDelay, function()
            self:Hide()
        end)
    end
end

function Tooltip:_updatePosition()
    if not self.Target or not self.Visible then return end
    
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Calculate preferred position
    local position = self.Config.Position or "Top"
    local offset = self.Config.Offset or 10
    
    -- Get target bounds
    local targetPos = self.Target.AbsolutePosition
    local targetSize = self.Target.AbsoluteSize
    local targetCenter = targetPos + targetSize / 2
    
    -- Get tooltip size
    local tooltipSize = self.Tooltip.AbsoluteSize
    
    -- Calculate positions for all sides
    local positions = {
        Top = Vector2.new(
            targetCenter.X - tooltipSize.X / 2,
            targetPos.Y - tooltipSize.Y - offset
        ),
        Bottom = Vector2.new(
            targetCenter.X - tooltipSize.X / 2,
            targetPos.Y + targetSize.Y + offset
        ),
        Left = Vector2.new(
            targetPos.X - tooltipSize.X - offset,
            targetCenter.Y - tooltipSize.Y / 2
        ),
        Right = Vector2.new(
            targetPos.X + targetSize.X + offset,
            targetCenter.Y - tooltipSize.Y / 2
        )
    }
    
    -- Check if preferred position fits
    local preferredPos = positions[position]
    local fits = self:_positionFits(preferredPos, tooltipSize, viewportSize)
    
    if not fits then
        -- Try other positions
        for _, altPos in pairs({"Bottom", "Top", "Right", "Left"}) do
            if altPos ~= position then
                local altPosition = positions[altPos]
                if self:_positionFits(altPosition, tooltipSize, viewportSize) then
                    preferredPos = altPosition
                    position = altPos
                    break
                end
            end
        end
    end
    
    -- Adjust position to keep within bounds
    preferredPos = Vector2.new(
        math.clamp(preferredPos.X, 0, viewportSize.X - tooltipSize.X),
        math.clamp(preferredPos.Y, 0, viewportSize.Y - tooltipSize.Y)
    )
    
    -- Update arrow position
    self:_updateArrow(position, targetCenter, preferredPos, tooltipSize)
    
    -- Animate to new position
    self.Animations:Animate(self.Tooltip, {
        Position = UDim2.new(0, preferredPos.X, 0, preferredPos.Y)
    }, {
        Style = "Spring",
        Duration = 0.2
    })
end

function Tooltip:_positionFits(position, size, viewportSize)
    return position.X >= 0 and
           position.Y >= 0 and
           position.X + size.X <= viewportSize.X and
           position.Y + size.Y <= viewportSize.Y
end

function Tooltip:_updateArrow(position, targetCenter, tooltipPos, tooltipSize)
    self.Arrow.Visible = true
    
    local arrowOffset = 6
    
    if position == "Top" then
        -- Arrow points down
        self.Arrow.Rotation = 45
        self.Arrow.Position = UDim2.new(
            0,
            math.clamp(
                targetCenter.X - 6,
                tooltipPos.X + 10,
                tooltipPos.X + tooltipSize.X - 22
            ),
            0,
            tooltipPos.Y + tooltipSize.Y - 6
        )
    elseif position == "Bottom" then
        -- Arrow points up
        self.Arrow.Rotation = 45
        self.Arrow.Position = UDim2.new(
            0,
            math.clamp(
                targetCenter.X - 6,
                tooltipPos.X + 10,
                tooltipPos.X + tooltipSize.X - 22
            ),
            0,
            tooltipPos.Y - 6
        )
    elseif position == "Left" then
        -- Arrow points right
        self.Arrow.Rotation = 45
        self.Arrow.Position = UDim2.new(
            0,
            tooltipPos.X + tooltipSize.X - 6,
            0,
            math.clamp(
                targetCenter.Y - 6,
                tooltipPos.Y + 10,
                tooltipPos.Y + tooltipSize.Y - 22
            )
        )
    elseif position == "Right" then
        -- Arrow points left
        self.Arrow.Rotation = 45
        self.Arrow.Position = UDim2.new(
            0,
            tooltipPos.X - 6,
            0,
            math.clamp(
                targetCenter.Y - 6,
                tooltipPos.Y + 10,
                tooltipPos.Y + tooltipSize.Y - 22
            )
        )
    end
end

function Tooltip:Show()
    if self.Visible or not self.Target then return end
    
    self.Visible = true
    
    -- Cancel any pending hide
    if self.HideTimer then
        self.HideTimer:Disconnect()
        self.HideTimer = nil
    end
    
    -- Update position
    self:_updatePosition()
    
    -- Show tooltip
    self.Tooltip.Visible = true
    self.Arrow.Visible = true
    
    -- Animate in
    self.Animations:Animate(self.Tooltip, {
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0, self.Config.MaxWidth, 0, self.Tooltip.AbsoluteSize.Y)
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    -- Fade in
    self.Animations:Animate(self.Tooltip.UIStroke, {
        Transparency = 0.3
    }, {
        Style = "Fluid",
        Duration = 0.3
    })
end

function Tooltip:Hide()
    if not self.Visible then return end
    
    self.Visible = false
    
    -- Cancel any pending show
    if self.ShowTimer then
        self.ShowTimer:Disconnect()
        self.ShowTimer = nil
    end
    
    -- Animate out
    self.Animations:Animate(self.Tooltip, {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, self.Config.MaxWidth, 0, 0)
    }, {
        Style = "Spring",
        Duration = 0.2
    })
    
    -- Hide after animation
    task.delay(0.2, function()
        if self.Tooltip then
            self.Tooltip.Visible = false
            self.Arrow.Visible = false
        end
    end)
end

function Tooltip:UpdateContent(content, title)
    self.Content = content or ""
    self.TitleText = title or ""
    
    -- Update title
    if self.TitleText ~= "" then
        self.Title.Visible = true
        self.Title.Text = self.TitleText
        
        -- Position description below title
        self.Description.Position = UDim2.new(0, 0, 0, self.Title.AbsoluteSize.Y + 5)
    else
        self.Title.Visible = false
        self.Description.Position = UDim2.new(0, 0, 0, 0)
    end
    
    -- Update description
    self.Description.Text = self.Content
    self.Description.Visible = self.Content ~= ""
    
    -- Update tooltip size
    task.wait()
    local totalHeight = self.Content.AbsoluteSize.Y + 
                       (self.Title.Visible and self.Title.AbsoluteSize.Y + 5 or 0) + 20
    
    self.Tooltip.Size = UDim2.new(
        0,
        math.min(self.Config.MaxWidth, self.Content.AbsoluteSize.X + 20),
        0,
        totalHeight
    )
end

function Tooltip:SetPosition(position)
    self.Config.Position = position
end

function Tooltip:SetMaxWidth(width)
    self.Config.MaxWidth = width
    self.Tooltip.Size = UDim2.new(0, width, 0, self.Tooltip.AbsoluteSize.Y)
end

function Tooltip:SetAnimation(animation)
    self.Config.Animation = animation
end

function Tooltip:Detach()
    if self.Target then
        self:Hide()
        
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
        if self.ShowTimer then
            self.ShowTimer:Disconnect()
            self.ShowTimer = nil
        end
        
        if self.HideTimer then
            self.HideTimer:Disconnect()
            self.HideTimer = nil
        end
        
        self.Target = nil
    end
end

function Tooltip:Destroy()
    self:Detach()
    
    if self.Container then
        self.Container:Destroy()
    end
end

return Tooltip