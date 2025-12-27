-- Theme management system with dynamic color schemes

local Themes = {}
Themes.__index = Themes

-- Base color palettes
local ColorPalettes = {
    Dark = {
        Window = {
            Background = Color3.fromRGB(30, 30, 35),
            TitleBar = Color3.fromRGB(40, 40, 45),
            Title = Color3.fromRGB(240, 240, 245),
            Subtitle = Color3.fromRGB(180, 180, 190),
            ScrollBar = Color3.fromRGB(100, 100, 110)
        },
        Button = {
            Background = Color3.fromRGB(50, 50, 55),
            Stroke = Color3.fromRGB(70, 70, 75),
            Text = Color3.fromRGB(240, 240, 245),
            Icon = Color3.fromRGB(200, 200, 210),
            GradientStart = Color3.fromRGB(80, 80, 90),
            GradientEnd = Color3.fromRGB(60, 60, 70)
        },
        Toggle = {
            Background = Color3.fromRGB(50, 50, 55),
            OnColor = Color3.fromRGB(80, 140, 255),
            OffColor = Color3.fromRGB(100, 100, 110),
            Knob = Color3.fromRGB(240, 240, 245),
            Text = Color3.fromRGB(220, 220, 225)
        },
        Slider = {
            Background = Color3.fromRGB(50, 50, 55),
            Fill = Color3.fromRGB(80, 140, 255),
            Knob = Color3.fromRGB(240, 240, 245),
            Text = Color3.fromRGB(220, 220, 225),
            Value = Color3.fromRGB(180, 180, 190)
        },
        Input = {
            Background = Color3.fromRGB(40, 40, 45),
            Stroke = Color3.fromRGB(60, 60, 65),
            Text = Color3.fromRGB(240, 240, 245),
            Placeholder = Color3.fromRGB(120, 120, 130),
            Cursor = Color3.fromRGB(80, 140, 255)
        },
        Dropdown = {
            Background = Color3.fromRGB(40, 40, 45),
            Stroke = Color3.fromRGB(60, 60, 65),
            Text = Color3.fromRGB(240, 240, 245),
            ItemBackground = Color3.fromRGB(50, 50, 55),
            ItemHover = Color3.fromRGB(60, 60, 70),
            Selected = Color3.fromRGB(70, 130, 245)
        }
    },
    
    Light = {
        Window = {
            Background = Color3.fromRGB(245, 245, 250),
            TitleBar = Color3.fromRGB(230, 230, 235),
            Title = Color3.fromRGB(30, 30, 35),
            Subtitle = Color3.fromRGB(80, 80, 90),
            ScrollBar = Color3.fromRGB(180, 180, 190)
        },
        Button = {
            Background = Color3.fromRGB(230, 230, 235),
            Stroke = Color3.fromRGB(210, 210, 215),
            Text = Color3.fromRGB(30, 30, 35),
            Icon = Color3.fromRGB(60, 60, 70),
            GradientStart = Color3.fromRGB(240, 240, 245),
            GradientEnd = Color3.fromRGB(220, 220, 225)
        },
        Toggle = {
            Background = Color3.fromRGB(230, 230, 235),
            OnColor = Color3.fromRGB(60, 120, 235),
            OffColor = Color3.fromRGB(180, 180, 190),
            Knob = Color3.fromRGB(250, 250, 255),
            Text = Color3.fromRGB(40, 40, 45)
        },
        Slider = {
            Background = Color3.fromRGB(230, 230, 235),
            Fill = Color3.fromRGB(60, 120, 235),
            Knob = Color3.fromRGB(250, 250, 255),
            Text = Color3.fromRGB(40, 40, 45),
            Value = Color3.fromRGB(100, 100, 110)
        },
        Input = {
            Background = Color3.fromRGB(250, 250, 255),
            Stroke = Color3.fromRGB(220, 220, 225),
            Text = Color3.fromRGB(30, 30, 35),
            Placeholder = Color3.fromRGB(150, 150, 160),
            Cursor = Color3.fromRGB(60, 120, 235)
        },
        Dropdown = {
            Background = Color3.fromRGB(250, 250, 255),
            Stroke = Color3.fromRGB(220, 220, 225),
            Text = Color3.fromRGB(30, 30, 35),
            ItemBackground = Color3.fromRGB(240, 240, 245),
            ItemHover = Color3.fromRGB(230, 230, 235),
            Selected = Color3.fromRGB(60, 120, 235)
        }
    },
    
    Midnight = {
        Window = {
            Background = Color3.fromRGB(15, 15, 20),
            TitleBar = Color3.fromRGB(25, 25, 30),
            Title = Color3.fromRGB(240, 240, 245),
            Subtitle = Color3.fromRGB(160, 160, 170),
            ScrollBar = Color3.fromRGB(80, 80, 90)
        },
        -- ... other colors similar to Dark but deeper
    }
}

function Themes.new(themeName, accentColor)
    local self = setmetatable({}, Themes)
    
    self.CurrentTheme = themeName or "Dark"
    self.AccentColor = accentColor or Color3.fromRGB(80, 140, 255)
    self.CustomColors = {}
    self.ColorCache = {}
    
    -- Generate accent variants
    self.AccentVariants = {
        Primary = self.AccentColor,
        Light = self:_lightenColor(self.AccentColor, 0.3),
        Dark = self:_darkenColor(self.AccentColor, 0.3),
        Transparent = Color3.new(self.AccentColor.R, self.AccentColor.G, self.AccentColor.B)
    }
    
    return self
end

function Themes:Set(themeName, accentColor)
    self.CurrentTheme = themeName or self.CurrentTheme
    
    if accentColor then
        self.AccentColor = accentColor
        self.AccentVariants = {
            Primary = self.AccentColor,
            Light = self:_lightenColor(self.AccentColor, 0.3),
            Dark = self:_darkenColor(self.AccentColor, 0.3),
            Transparent = Color3.new(self.AccentColor.R, self.AccentColor.G, self.AccentColor.B)
        }
    end
    
    -- Clear cache on theme change
    self.ColorCache = {}
end

function Themes:GetColor(category, element)
    -- Check cache first
    local cacheKey = category .. "_" .. element .. "_" .. self.CurrentTheme
    if self.ColorCache[cacheKey] then
        return self.ColorCache[cacheKey]
    end
    
    local color = nil
    
    -- Check custom colors first
    if self.CustomColors[category] and self.CustomColors[category][element] then
        color = self.CustomColors[category][element]
    -- Check theme colors
    elseif ColorPalettes[self.CurrentTheme] and 
           ColorPalettes[self.CurrentTheme][category] and
           ColorPalettes[self.CurrentTheme][category][element] then
        color = ColorPalettes[self.CurrentTheme][category][element]
    end
    
    -- Apply accent color for accent elements
    if element == "Accent" or string.find(element:lower(), "accent") then
        if element == "AccentLight" then
            color = self.AccentVariants.Light
        elseif element == "AccentDark" then
            color = self.AccentVariants.Dark
        else
            color = self.AccentVariants.Primary
        end
    end
    
    -- If still no color, use fallback
    if not color then
        color = self:_getFallbackColor(category, element)
    end
    
    -- Cache the result
    self.ColorCache[cacheKey] = color
    
    return color
end

function Themes:SetCustomColor(category, element, color)
    if not self.CustomColors[category] then
        self.CustomColors[category] = {}
    end
    
    self.CustomColors[category][element] = color
    
    -- Clear cache for this category
    for cacheKey in pairs(self.ColorCache) do
        if string.find(cacheKey, "^" .. category) then
            self.ColorCache[cacheKey] = nil
        end
    end
end

function Themes:CreateGradient(startColor, endColor, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, startColor),
        ColorSequenceKeypoint.new(1, endColor)
    }
    gradient.Rotation = rotation or 90
    return gradient
end

function Themes:GetAccentGradient()
    return self:CreateGradient(
        self.AccentVariants.Light,
        self.AccentVariants.Dark,
        45
    )
end

function Themes:GetThemeInfo()
    return {
        Name = self.CurrentTheme,
        AccentColor = self.AccentColor,
        IsDark = self.CurrentTheme == "Dark" or self.CurrentTheme == "Midnight",
        Colors = ColorPalettes[self.CurrentTheme] or {}
    }
end

function Themes:_getFallbackColor(category, element)
    -- Fallback color system
    local fallbacks = {
        Background = Color3.fromRGB(40, 40, 45),
        Text = Color3.fromRGB(240, 240, 245),
        Stroke = Color3.fromRGB(60, 60, 65),
        Highlight = self.AccentColor
    }
    
    return fallbacks[element] or Color3.fromRGB(255, 255, 255)
end

function Themes:_lightenColor(color, amount)
    amount = math.clamp(amount, 0, 1)
    return Color3.new(
        color.R + (1 - color.R) * amount,
        color.G + (1 - color.G) * amount,
        color.B + (1 - color.B) * amount
    )
end

function Themes:_darkenColor(color, amount)
    amount = math.clamp(amount, 0, 1)
    return Color3.new(
        color.R * (1 - amount),
        color.G * (1 - amount),
        color.B * (1 - amount)
    )
end

function Themes:_blendColors(color1, color2, alpha)
    alpha = math.clamp(alpha, 0, 1)
    return Color3.new(
        color1.R * (1 - alpha) + color2.R * alpha,
        color1.G * (1 - alpha) + color2.G * alpha,
        color1.B * (1 - alpha) + color2.B * alpha
    )
end

function Themes:GetColorWithTransparency(color, transparency)
    return Color3.new(color.R, color.G, color.B), transparency
end

return Themes