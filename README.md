# 🌌 Celestial UI

> **Premium, Fluid, Cross-Platform UI Library for Roblox**

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-purple.svg)]()

Celestial UI is an ultra-advanced, fully open-source UI library designed for Roblox with premium fluid animations, modular architecture, and cross-platform support. Built for both exploit users and legitimate developers.

## ✨ Features

### 🎨 **Premium Design**
- Fluid, watery animations with physics-based easing
- Dynamic Island-style UI toggle
- Dark/Light theme support with custom accent colors
- Cross-platform optimization (Mobile, Tablet, PC)
- Smooth transitions and micro-interactions

### 🧩 **Modular Architecture**
- Every component in separate files
- Easy to extend and customize
- Load only what you need
- GitHub-ready structure

### 🎮 **Components**
- **Buttons** (Icon, Loading, Gradient, Ripple, Long-press)
- **Toggles & Switches** (Multi-state support)
- **Sliders** (Smooth drag + numeric input)
- **Dropdowns** (Multi-select + search)
- **Text Inputs** (Validation, Masked, Numeric)
- **Color Picker** (HSV/RGB/Hex, Presets)
- **Tabs** (Animated + Nested)
- **Tooltips** (Smart edge detection)
- **Code Blocks** (Syntax highlighting)
- **Notifications & Toasts**
- **Context Menus**
- **And much more...**

### ⚡ **Advanced Systems**
- **Dynamic Island** - Floating UI toggle with notifications
- **Loader System** - Customizable loading screen
- **Search System** - Tab and component search
- **Key System** - Authentication with local/web validation
- **Database** - Local storage with encryption
- **Analytics** - Usage tracking and performance monitoring
- **URL Images** - Image loading with caching

## 🚀 Quick Start

### Installation
```lua
local Celestial = loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPO/BRANCH/Celestial-UI/init.lua"))()

# Basic Usage

```
-- Create window with config
local Window = Celestial:CreateWindow({
    Name = "My Application",
    Subtitle = "Powered by Celestial UI",
    Theme = "Dark",
    AccentColor = Color3.fromRGB(80, 140, 255),
    
    ToggleIsland = {
        Enabled = true,
        Position = "Top",
        ExpandOnHover = true
    },
    
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MyApp"
    }
})

-- Create tabs
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "lucide:home"
})

-- Create sections
local WelcomeSection = MainTab:CreateSection("Welcome")

-- Add components
WelcomeSection:AddLabel({
    Text = "Welcome to Celestial UI",
    TextSize = 18,
    Font = Enum.Font.GothamBold
})

WelcomeSection:AddButton({
    Name = "Click Me",
    Icon = "lucide:zap",
    Callback = function()
        print("Button clicked!")
    end
})

WelcomeSection:AddToggle({
    Name = "Enable Effects",
    Default = true,
    Callback = function(value)
        print("Effects:", value)
    end
})

WelcomeSection:AddSlider({
    Name = "Effect Intensity",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Intensity:", value)
    end
})

-- Show window
Window:Show()```

# Config

```
local Window = Celestial:CreateWindow({
    Name = "Celestial UI Demo",
    Subtitle = "Premium Interface System",
    Icon = "lucide:sparkles",
    
    -- Theme & Appearance
    Theme = "Dark",
    AccentColor = Color3.fromRGB(80, 140, 255),
    Font = "Gotham",
    Transparency = 0.1,
    
    -- Animations
    Animation = {
        Style = "Fluid", -- Fluid, Spring, Elastic, Instant
        Speed = 1,
        Intensity = 0.8,
        Blur = true
    },
    
    -- Loader
    Loader = {
        Enabled = true,
        Title = "Celestial Interface",
        Subtitle = "Loading modules...",
        Logo = "https://example.com/logo.png",
        ProgressStyle = "Smooth",
        ShowSteps = true
    },
    
    -- Dynamic Island
    ToggleIsland = {
        Enabled = true,
        Position = "Top",
        Size = UDim2.new(0.2, 0, 0.06, 0),
        ExpandOnHover = true,
        ShowNotifications = true,
        Icon = "lucide:menu"
    },
    
    -- Data Saving
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CelestialDemo",
        FileName = "Settings",
        Versioning = true,
        AutoSave = true
    },
    
    -- Database
    Database = {
        Enabled = true,
        AutoSave = true,
        SaveInterval = 30,
        Encryption = false
    },
    
    -- Search System
    Search = {
        Enabled = true,
        SearchTabs = true,
        SearchComponents = true,
        FuzzySearch = true,
        Hotkey = Enum.KeyCode.F
    },
    
    -- Key System (Optional)
    KeySystem = {
        Enabled = false,
        Title = "Authentication Required",
        Subtitle = "Enter your access key",
        Note = "Join our Discord for access",
        SaveKey = true,
        Keys = {"example-key"},
        WebValidation = false
    },
    
    -- Mobile Optimization
    Mobile = {
        Enabled = true,
        Scale = 1.1,
        LargeTouchTargets = true,
        TouchPadding = 10,
        GestureSupport = true
    },
    
    -- Debug
    Debug = {
        Enabled = false,
        LogWarnings = true,
        PerformanceLogging = false
    }
}) ```