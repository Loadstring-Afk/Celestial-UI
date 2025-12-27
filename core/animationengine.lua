-- Advanced fluid animation engine with physics-based easing

local AnimationEngine = {}
AnimationEngine.__index = AnimationEngine

-- Spring physics constants
local SPRING_TENSION = 170
local SPRING_FRICTION = 26
local SPRING_MASS = 1

-- Easing functions
local EasingFunctions = {
    Linear = function(t) return t end,
    
    -- Smooth
    Smooth = function(t) return t * t * (3 - 2 * t) end,
    SmoothIn = function(t) return t * t end,
    SmoothOut = function(t) return 1 - (1 - t) * (1 - t) end,
    
    -- Elastic
    ElasticIn = function(t)
        local c4 = (2 * math.pi) / 3
        return t == 0 and 0 or t == 1 and 1 or -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4)
    end,
    
    ElasticOut = function(t)
        local c4 = (2 * math.pi) / 3
        return t == 0 and 0 or t == 1 and 1 or math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
    
    -- Bounce
    BounceOut = function(t)
        local n1 = 7.5625
        local d1 = 2.75
        
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - (1.5 / d1)
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - (2.25 / d1)
            return n1 * t * t + 0.9375
        else
            t = t - (2.625 / d1)
            return n1 * t * t + 0.984375
        end
    end,
    
    -- Fluid/Watery
    Fluid = function(t)
        return 0.5 - math.cos(t * math.pi) / 2
    end,
    
    Wave = function(t)
        return math.sin(t * math.pi * 2) * 0.5 + 0.5
    end
}

function AnimationEngine.new(config)
    local self = setmetatable({}, AnimationEngine)
    
    self.Config = config or {
        Style = "Fluid",
        Speed = 1,
        Intensity = 0.8,
        Blur = false
    }
    
    self.ActiveAnimations = {}
    self.Connections = {}
    
    -- Bind to render stepped for smooth animations
    local RunService = game:GetService("RunService")
    self.Connection = RunService.RenderStepped:Connect(function(deltaTime)
        self:_updateAnimations(deltaTime)
    end)
    
    return self
end

function AnimationEngine:Animate(object, properties, options)
    options = options or {}
    
    local animation = {
        Object = object,
        Properties = properties,
        Style = options.Style or self.Config.Style,
        Duration = options.Duration or 0.3,
        Easing = EasingFunctions[options.Style or self.Config.Style] or EasingFunctions.Fluid,
        StartTime = tick(),
        InitialValues = {},
        TargetValues = {},
        Spring = nil
    }
    
    -- Check if spring animation
    if animation.Style == "Spring" then
        animation.Spring = {
            Position = {},
            Velocity = {},
            Target = {}
        }
    end
    
    -- Store initial values and calculate targets
    for propName, targetValue in pairs(properties) do
        if object[propName] then
            animation.InitialValues[propName] = object[propName]
            animation.TargetValues[propName] = targetValue
            
            if animation.Spring then
                animation.Spring.Position[propName] = object[propName]
                animation.Spring.Velocity[propName] = 0
                animation.Spring.Target[propName] = targetValue
            end
        end
    end
    
    table.insert(self.ActiveAnimations, animation)
    
    -- Return promise-like interface
    return {
        Cancel = function()
            self:_cancelAnimation(animation)
        end,
        
        Wait = function()
            local start = tick()
            while tick() - start < animation.Duration and self:_animationExists(animation) do
                RunService.Heartbeat:Wait()
            end
        end
    }
end

function AnimationEngine:WaterRipple(position, parent, options)
    options = options or {}
    
    local ripple = Instance.new("Frame")
    ripple.Name = "WaterRipple"
    ripple.BackgroundTransparency = 1
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, position.X, 0, position.Y)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.ZIndex = 1000
    ripple.Parent = parent
    
    local circle = Instance.new("UICorner")
    circle.CornerRadius = UDim.new(1, 0)
    circle.Parent = ripple
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = options.Color or Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 2
    stroke.Parent = ripple
    
    -- Animate ripple
    self:Animate(ripple, {
        Size = UDim2.new(0, options.Size or 100, 0, options.Size or 100),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, position.X, 0, position.Y)
    }, {
        Style = "Wave",
        Duration = 0.6
    })
    
    -- Cleanup
    task.delay(0.7, function()
        if ripple then
            ripple:Destroy()
        end
    end)
end

function AnimationEngine:_updateAnimations(deltaTime)
    local currentTime = tick()
    local toRemove = {}
    
    for i, animation in ipairs(self.ActiveAnimations) do
        local elapsed = currentTime - animation.StartTime
        local progress = math.min(elapsed / animation.Duration, 1)
        
        if progress >= 1 then
            -- Animation complete
            for propName, targetValue in pairs(animation.TargetValues) do
                if animation.Object[propName] then
                    animation.Object[propName] = targetValue
                end
            end
            table.insert(toRemove, i)
        else
            -- Update animation
            local easedProgress = animation.Easing(progress)
            
            if animation.Style == "Spring" then
                self:_updateSpringAnimation(animation, deltaTime)
            else
                for propName, initialValue in pairs(animation.InitialValues) do
                    local targetValue = animation.TargetValues[propName]
                    
                    if typeof(initialValue) == "number" then
                        local current = initialValue + (targetValue - initialValue) * easedProgress
                        animation.Object[propName] = current
                    elseif typeof(initialValue) == "Color3" then
                        local r = initialValue.R + (targetValue.R - initialValue.R) * easedProgress
                        local g = initialValue.G + (targetValue.G - initialValue.G) * easedProgress
                        local b = initialValue.B + (targetValue.B - initialValue.B) * easedProgress
                        animation.Object[propName] = Color3.new(r, g, b)
                    elseif typeof(initialValue) == "UDim2" then
                        local xScale = initialValue.X.Scale + (targetValue.X.Scale - initialValue.X.Scale) * easedProgress
                        local xOffset = initialValue.X.Offset + (targetValue.X.Offset - initialValue.X.Offset) * easedProgress
                        local yScale = initialValue.Y.Scale + (targetValue.Y.Scale - initialValue.Y.Scale) * easedProgress
                        local yOffset = initialValue.Y.Offset + (targetValue.Y.Offset - initialValue.Y.Offset) * easedProgress
                        animation.Object[propName] = UDim2.new(xScale, xOffset, yScale, yOffset)
                    end
                end
            end
        end
    end
    
    -- Remove completed animations
    for i = #toRemove, 1, -1 do
        table.remove(self.ActiveAnimations, toRemove[i])
    end
end

function AnimationEngine:_updateSpringAnimation(animation, deltaTime)
    for propName in pairs(animation.Spring.Position) do
        local position = animation.Spring.Position[propName]
        local velocity = animation.Spring.Velocity[propName]
        local target = animation.Spring.Target[propName]
        
        -- Spring physics calculation
        local force = (target - position) * SPRING_TENSION
        local damping = -velocity * SPRING_FRICTION
        
        local acceleration = (force + damping) / SPRING_MASS
        velocity = velocity + acceleration * deltaTime
        position = position + velocity * deltaTime
        
        -- Update values
        animation.Spring.Position[propName] = position
        animation.Spring.Velocity[propName] = velocity
        animation.Object[propName] = position
    end
end

function AnimationEngine:_cancelAnimation(animation)
    for i, anim in ipairs(self.ActiveAnimations) do
        if anim == animation then
            table.remove(self.ActiveAnimations, i)
            break
        end
    end
end

function AnimationEngine:_animationExists(animation)
    for _, anim in ipairs(self.ActiveAnimations) do
        if anim == animation then
            return true
        end
    end
    return false
end

function AnimationEngine:SetStyle(style, speed)
    self.Config.Style = style
    self.Config.Speed = speed or self.Config.Speed
end

function AnimationEngine:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
    end
    
    -- Clear animations
    self.ActiveAnimations = {}
end

return AnimationEngine