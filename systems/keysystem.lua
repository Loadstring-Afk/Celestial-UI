-- Premium key system with local and remote validation

local KeySystem = {}
KeySystem.__index = KeySystem

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

function KeySystem.new(config)
    local self = setmetatable({}, KeySystem)
    
    self.Config = config or {
        Enabled = false,
        Title = "Authentication Required",
        Subtitle = "Enter your access key",
        Note = "Join our Discord for access",
        SaveKey = true,
        FileName = "CelestialKey",
        Keys = {},
        WebValidation = false,
        Webhook = "",
        LockoutAttempts = 5,
        LockoutTime = 300,
        AutoJoin = false,
        GameId = nil
    }
    
    self.Attempts = 0
    self.Locked = false
    self.LockUntil = 0
    self.Validated = false
    self.CurrentKey = nil
    
    self.UI = nil
    self.Database = nil
    
    if self.Config.Enabled then
        self:_loadSavedKey()
    end
    
    return self
end

function KeySystem:_loadSavedKey()
    if not self.Config.SaveKey then return end
    
    -- Try to load saved key from database
    -- This would connect to the database module
    local success, savedKey = pcall(function()
        if readfile and isfile then
            local path = self.Config.FileName or "CelestialKey"
            if isfile(path) then
                return readfile(path)
            end
        end
        return nil
    end)
    
    if savedKey and savedKey ~= "" then
        self.CurrentKey = savedKey
        
        -- Auto-validate if key exists
        if self.Config.AutoValidate then
            task.spawn(function()
                self:Validate(savedKey)
            end)
        end
    end
end

function KeySystem:_saveKey(key)
    if not self.Config.SaveKey or not key then return end
    
    -- Save key to database/file
    local success = pcall(function()
        if writefile then
            local path = self.Config.FileName or "CelestialKey"
            writefile(path, key)
            return true
        end
        return false
    end)
    
    return success
end

function KeySystem:_deleteKey()
    if not self.Config.SaveKey then return end
    
    local success = pcall(function()
        if delfile and isfile then
            local path = self.Config.FileName or "CelestialKey"
            if isfile(path) then
                delfile(path)
                return true
            end
        end
        return false
    end)
    
    return success
end

function KeySystem:ShowUI(parent, theme, animations)
    if not self.Config.Enabled then return true end
    
    if self.Validated then
        return true
    end
    
    if self.Locked then
        local currentTime = tick()
        if currentTime < self.LockUntil then
            local remaining = math.ceil(self.LockUntil - currentTime)
            self:_showLockedUI(parent, theme, animations, remaining)
            return false
        else
            -- Lock expired
            self.Locked = false
            self.Attempts = 0
        end
    end
    
    self:_createUI(parent, theme, animations)
    
    -- Show UI and wait for validation
    self.UI.Visible = true
    
    -- Return a promise-like object
    local validationPromise = {
        Completed = false,
        Success = false
    }
    
    -- Store the resolve function
    self._resolveValidation = function(success)
        validationPromise.Completed = true
        validationPromise.Success = success
    end
    
    return validationPromise
end

function KeySystem:_createUI(parent, theme, animations)
    if self.UI then
        self.UI:Destroy()
    end
    
    -- Main container
    self.UI = Instance.new("ScreenGui")
    self.UI.Name = "CelestialKeySystem"
    self.UI.ResetOnSpawn = false
    self.UI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.UI.IgnoreGuiInset = true
    self.UI.Parent = parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Background overlay
    self.Overlay = Instance.new("Frame")
    self.Overlay.Name = "Overlay"
    self.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    self.Overlay.BackgroundTransparency = 0.7
    self.Overlay.Size = UDim2.new(1, 0, 1, 0)
    self.Overlay.ZIndex = 1
    self.Overlay.Parent = self.UI
    
    -- Main modal
    self.Modal = Instance.new("Frame")
    self.Modal.Name = "Modal"
    self.Modal.BackgroundColor3 = theme:GetColor("Window", "Background") or Color3.fromRGB(30, 30, 35)
    self.Modal.BackgroundTransparency = 0.1
    self.Modal.Size = UDim2.new(0, 400, 0, 350)
    self.Modal.Position = UDim2.new(0.5, -200, 0.5, -175)
    self.Modal.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Modal.ZIndex = 2
    
    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 12)
    modalCorner.Parent = self.Modal
    
    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = Color3.new(0, 0, 0)
    modalStroke.Transparency = 0.7
    modalStroke.Thickness = 2
    modalStroke.Parent = self.Modal
    
    self.Modal.Parent = self.UI
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.BackgroundColor3 = theme:GetColor("Window", "TitleBar") or Color3.fromRGB(40, 40, 45)
    self.Header.BackgroundTransparency = 0.1
    self.Header.Size = UDim2.new(1, 0, 0, 50)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    headerCorner.Parent = self.Header
    
    self.Header.Parent = self.Modal
    
    -- Title
    self.Title = Instance.new("TextLabel")
    self.Title.Name = "Title"
    self.Title.BackgroundTransparency = 1
    self.Title.Size = UDim2.new(1, -20, 0.6, 0)
    self.Title.Position = UDim2.new(0, 10, 0, 5)
    self.Title.Font = Enum.Font.GothamBold
    self.Title.Text = self.Config.Title
    self.Title.TextColor3 = theme:GetColor("Window", "Title") or Color3.fromRGB(240, 240, 245)
    self.Title.TextSize = 20
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.Parent = self.Header
    
    -- Subtitle
    self.Subtitle = Instance.new("TextLabel")
    self.Subtitle.Name = "Subtitle"
    self.Subtitle.BackgroundTransparency = 1
    self.Subtitle.Size = UDim2.new(1, -20, 0.4, 0)
    self.Subtitle.Position = UDim2.new(0, 10, 0.6, 0)
    self.Subtitle.Font = Enum.Font.Gotham
    self.Subtitle.Text = self.Config.Subtitle
    self.Subtitle.TextColor3 = theme:GetColor("Window", "Subtitle") or Color3.fromRGB(180, 180, 190)
    self.Subtitle.TextSize = 14
    self.Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    self.Subtitle.Parent = self.Header
    
    -- Content
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, -20, 1, -70)
    self.Content.Position = UDim2.new(0, 10, 0, 60)
    self.Content.Parent = self.Modal
    
    -- Note
    self.Note = Instance.new("TextLabel")
    self.Note.Name = "Note"
    self.Note.BackgroundTransparency = 1
    self.Note.Size = UDim2.new(1, 0, 0, 40)
    self.Note.Position = UDim2.new(0, 0, 0, 0)
    self.Note.Font = Enum.Font.Gotham
    self.Note.Text = self.Config.Note
    self.Note.TextColor3 = theme:GetColor("Window", "Subtitle") or Color3.fromRGB(180, 180, 190)
    self.Note.TextSize = 12
    self.Note.TextWrapped = true
    self.Note.TextXAlignment = Enum.TextXAlignment.Left
    self.Note.Parent = self.Content
    
    -- Key input
    self.KeyInput = Instance.new("TextBox")
    self.KeyInput.Name = "KeyInput"
    self.KeyInput.BackgroundColor3 = theme:GetColor("Input", "Background") or Color3.fromRGB(40, 40, 45)
    self.KeyInput.BackgroundTransparency = 0.1
    self.KeyInput.Size = UDim2.new(1, 0, 0, 40)
    self.KeyInput.Position = UDim2.new(0, 0, 0, 50)
    self.KeyInput.Font = Enum.Font.Gotham
    self.KeyInput.PlaceholderText = "Enter your key..."
    self.KeyInput.PlaceholderColor3 = theme:GetColor("Input", "Placeholder") or Color3.fromRGB(120, 120, 130)
    self.KeyInput.TextColor3 = theme:GetColor("Input", "Text") or Color3.fromRGB(240, 240, 245)
    self.KeyInput.TextSize = 14
    self.KeyInput.ClearTextOnFocus = false
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = self.KeyInput
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = theme:GetColor("Input", "Stroke") or Color3.fromRGB(60, 60, 65)
    inputStroke.Transparency = 0.3
    inputStroke.Thickness = 1
    inputStroke.Parent = self.KeyInput
    
    -- Paste button
    self.PasteButton = Instance.new("TextButton")
    self.PasteButton.Name = "PasteButton"
    self.PasteButton.BackgroundColor3 = theme:GetColor("Button", "Background") or Color3.fromRGB(50, 50, 55)
    self.PasteButton.BackgroundTransparency = 0.5
    self.PasteButton.Size = UDim2.new(0, 60, 0, 25)
    self.PasteButton.Position = UDim2.new(1, -65, 0.5, -12.5)
    self.PasteButton.AnchorPoint = Vector2.new(1, 0.5)
    self.PasteButton.Font = Enum.Font.Gotham
    self.PasteButton.Text = "Paste"
    self.PasteButton.TextColor3 = theme:GetColor("Button", "Text") or Color3.fromRGB(220, 220, 225)
    self.PasteButton.TextSize = 12
    
    local pasteCorner = Instance.new("UICorner")
    pasteCorner.CornerRadius = UDim.new(0, 4)
    pasteCorner.Parent = self.PasteButton
    
    self.PasteButton.Parent = self.KeyInput
    
    self.KeyInput.Parent = self.Content
    
    -- Error message
    self.Error = Instance.new("TextLabel")
    self.Error.Name = "Error"
    self.Error.BackgroundTransparency = 1
    self.Error.Size = UDim2.new(1, 0, 0, 20)
    self.Error.Position = UDim2.new(0, 0, 0, 100)
    self.Error.Font = Enum.Font.Gotham
    self.Error.Text = ""
    self.Error.TextColor3 = Color3.fromRGB(255, 80, 80)
    self.Error.TextTransparency = 1
    self.Error.TextSize = 12
    self.Error.TextXAlignment = Enum.TextXAlignment.Left
    self.Error.Parent = self.Content
    
    -- Button container
    self.ButtonContainer = Instance.new("Frame")
    self.ButtonContainer.Name = "Buttons"
    self.ButtonContainer.BackgroundTransparency = 1
    self.ButtonContainer.Size = UDim2.new(1, 0, 0, 40)
    self.ButtonContainer.Position = UDim2.new(0, 0, 1, -40)
    self.ButtonContainer.Parent = self.Content
    
    -- Validate button
    self.ValidateButton = Instance.new("TextButton")
    self.ValidateButton.Name = "Validate"
    self.ValidateButton.BackgroundColor3 = theme:GetColor("Button", "Background") or Color3.fromRGB(50, 50, 55)
    self.ValidateButton.BackgroundTransparency = 0.1
    self.ValidateButton.Size = UDim2.new(0, 100, 0, 35)
    self.ValidateButton.Position = UDim2.new(1, -105, 0.5, -17.5)
    self.ValidateButton.AnchorPoint = Vector2.new(1, 0.5)
    self.ValidateButton.Font = Enum.Font.GothamBold
    self.ValidateButton.Text = "VALIDATE"
    self.ValidateButton.TextColor3 = theme:GetColor("Button", "Text") or Color3.fromRGB(240, 240, 245)
    self.ValidateButton.TextSize = 14
    
    local validateCorner = Instance.new("UICorner")
    validateCorner.CornerRadius = UDim.new(0, 8)
    validateCorner.Parent = self.ValidateButton
    
    self.ValidateButton.Parent = self.ButtonContainer
    
    -- Get key button
    self.GetKeyButton = Instance.new("TextButton")
    self.GetKeyButton.Name = "GetKey"
    self.GetKeyButton.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
    self.GetKeyButton.BackgroundTransparency = 0.2
    self.GetKeyButton.Size = UDim2.new(0, 120, 0, 35)
    self.GetKeyButton.Position = UDim2.new(0, 0, 0.5, -17.5)
    self.GetKeyButton.AnchorPoint = Vector2.new(0, 0.5)
    self.GetKeyButton.Font = Enum.Font.GothamBold
    self.GetKeyButton.Text = "GET KEY"
    self.GetKeyButton.TextColor3 = Color3.fromRGB(240, 240, 245)
    self.GetKeyButton.TextSize = 14
    
    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 8)
    getKeyCorner.Parent = self.GetKeyButton
    
    self.GetKeyButton.Parent = self.ButtonContainer
    
    -- Setup events
    self:_setupEvents(animations)
    
    -- Animate in
    animations:Animate(self.Modal, {
        Size = UDim2.new(0, 400, 0, 350),
        BackgroundTransparency = 0.1
    }, {
        Style = "Spring",
        Duration = 0.5
    })
    
    -- Focus input
    task.wait(0.1)
    self.KeyInput:CaptureFocus()
end

function KeySystem:_setupEvents(animations)
    -- Validate button
    self.ValidateButton.MouseButton1Click:Connect(function()
        self:Validate(self.KeyInput.Text)
    end)
    
    -- Get key button
    self.GetKeyButton.MouseButton1Click:Connect(function()
        self:_onGetKey()
    end)
    
    -- Paste button
    self.PasteButton.MouseButton1Click:Connect(function()
        self:_onPaste()
    end)
    
    -- Enter key in input
    self.KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self:Validate(self.KeyInput.Text)
        end
    end)
    
    -- Button hover effects
    self.ValidateButton.MouseEnter:Connect(function()
        animations:Animate(self.ValidateButton, {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 105, 0, 38)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
    end)
    
    self.ValidateButton.MouseLeave:Connect(function()
        animations:Animate(self.ValidateButton, {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 100, 0, 35)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
    end)
    
    self.GetKeyButton.MouseEnter:Connect(function()
        animations:Animate(self.GetKeyButton, {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 125, 0, 38)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
    end)
    
    self.GetKeyButton.MouseLeave:Connect(function()
        animations:Animate(self.GetKeyButton, {
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0, 120, 0, 35)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
    end)
end

function KeySystem:_showLockedUI(parent, theme, animations, remainingTime)
    if self.UI then
        self.UI:Destroy()
    end
    
    -- Create locked UI
    self.UI = Instance.new("ScreenGui")
    self.UI.Name = "CelestialKeySystemLocked"
    self.UI.ResetOnSpawn = false
    self.UI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.UI.IgnoreGuiInset = true
    self.UI.Parent = parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Background
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.7
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 1
    overlay.Parent = self.UI
    
    -- Locked modal
    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.BackgroundColor3 = theme:GetColor("Window", "Background") or Color3.fromRGB(30, 30, 35)
    modal.BackgroundTransparency = 0.1
    modal.Size = UDim2.new(0, 350, 0, 200)
    modal.Position = UDim2.new(0.5, -175, 0.5, -100)
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.ZIndex = 2
    
    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 12)
    modalCorner.Parent = modal
    
    -- Lock icon
    local lockIcon = Instance.new("ImageLabel")
    lockIcon.Name = "LockIcon"
    lockIcon.BackgroundTransparency = 1
    lockIcon.Size = UDim2.new(0, 64, 0, 64)
    lockIcon.Position = UDim2.new(0.5, -32, 0.3, -32)
    lockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    lockIcon.Image = "rbxassetid://7072722621" -- Lock icon
    lockIcon.ImageColor3 = Color3.fromRGB(255, 80, 80)
    lockIcon.Parent = modal
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0.6, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "Too Many Attempts"
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextSize = 18
    title.Parent = modal
    
    -- Message
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.BackgroundTransparency = 1
    message.Size = UDim2.new(1, -20, 0, 40)
    message.Position = UDim2.new(0, 10, 0.8, 0)
    message.Font = Enum.Font.Gotham
    message.Text = string.format("Please wait %d seconds before trying again.", remainingTime)
    message.TextColor3 = Color3.fromRGB(180, 180, 190)
    message.TextSize = 14
    message.TextWrapped = true
    message.Parent = modal
    
    modal.Parent = self.UI
    
    -- Start countdown
    self:_startLockCountdown(remainingTime, message)
end

function KeySystem:_startLockCountdown(remainingTime, messageLabel)
    local startTime = tick()
    local endTime = startTime + remainingTime
    
    while tick() < endTime do
        local currentRemaining = math.ceil(endTime - tick())
        if currentRemaining <= 0 then break end
        
        messageLabel.Text = string.format("Please wait %d seconds before trying again.", currentRemaining)
        task.wait(1)
    end
    
    -- Unlock
    self.Locked = false
    self.Attempts = 0
    
    -- Close UI
    if self.UI then
        self.UI:Destroy()
        self.UI = nil
    end
end

function KeySystem:_onGetKey()
    -- Open Discord or website
    if self.Config.DiscordInvite then
        pcall(function()
            if request then
                request({
                    Url = "http://127.0.0.1:6463/rpc?v=1",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode({
                        cmd = "INVITE_BROWSER",
                        args = {
                            code = self.Config.DiscordInvite
                        },
                        nonce = HttpService:GenerateGUID(false)
                    })
                })
            end
        end)
    elseif self.Config.Website then
        pcall(function()
            if request then
                request({
                    Url = self.Config.Website,
                    Method = "GET"
                })
            end
        })
    end
end

function KeySystem:_onPaste()
    pcall(function()
        if readclipboard then
            local clipboard = readclipboard()
            if clipboard then
                self.KeyInput.Text = clipboard
            end
        end
    end)
end

function KeySystem:Validate(key)
    if not key or key == "" then
        self:_showError("Please enter a key")
        return false
    end
    
    -- Check if locked
    if self.Locked then
        local currentTime = tick()
        if currentTime < self.LockUntil then
            local remaining = math.ceil(self.LockUntil - currentTime)
            self:_showError(string.format("Locked for %d more seconds", remaining))
            return false
        else
            -- Lock expired
            self.Locked = false
            self.Attempts = 0
        end
    end
    
    -- Trim and clean key
    key = key:gsub("%s+", "")
    
    -- Check local keys first
    for _, validKey in ipairs(self.Config.Keys) do
        if key == validKey then
            return self:_onValidationSuccess(key)
        end
    end
    
    -- Web validation
    if self.Config.WebValidation and self.Config.Webhook then
        return self:_validateWeb(key)
    end
    
    -- Increment attempts
    self.Attempts = self.Attempts + 1
    
    if self.Attempts >= self.Config.LockoutAttempts then
        self:_lockout()
        return false
    end
    
    self:_showError(string.format("Invalid key (%d/%d attempts)", self.Attempts, self.Config.LockoutAttempts))
    return false
end

function KeySystem:_validateWeb(key)
    local success, response = pcall(function()
        if request then
            local response = request({
                Url = self.Config.Webhook,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    key = key,
                    userId = game:GetService("Players").LocalPlayer.UserId,
                    timestamp = os.time()
                })
            })
            
            if response.Success then
                local data = HttpService:JSONDecode(response.Body)
                return data.valid or false
            end
        end
        return false
    end)
    
    if success and response then
        return self:_onValidationSuccess(key)
    else
        self.Attempts = self.Attempts + 1
        
        if self.Attempts >= self.Config.LockoutAttempts then
            self:_lockout()
            return false
        end
        
        self:_showError("Validation failed. Please try again.")
        return false
    end
end

function KeySystem:_onValidationSuccess(key)
    self.Validated = true
    self.CurrentKey = key
    self.Attempts = 0
    self.Locked = false
    
    -- Save key if configured
    if self.Config.SaveKey then
        self:_saveKey(key)
    end
    
    -- Show success animation
    if self.UI then
        self.ValidateButton.Text = "✓ VALID"
        self.ValidateButton.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        
        task.wait(1)
        
        -- Animate out
        if self._resolveValidation then
            self._resolveValidation(true)
        end
        
        self:_closeUI()
    else
        if self._resolveValidation then
            self._resolveValidation(true)
        end
    end
    
    return true
end

function KeySystem:_lockout()
    self.Locked = true
    self.LockUntil = tick() + self.Config.LockoutTime
    
    if self.UI then
        self.UI:Destroy()
        self.UI = nil
    end
    
    self:_showLockedUI(
        game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
        {GetColor = function() return Color3.new(1,1,1) end}, -- Dummy theme
        {Animate = function() end} -- Dummy animations
    )
end

function KeySystem:_showError(message)
    if not self.Error then return end
    
    self.Error.Text = message
    self.Error.TextTransparency = 0
    
    -- Shake animation
    local startPos = self.KeyInput.Position
    for i = 1, 3 do
        self.Animations:Animate(self.KeyInput, {
            Position = UDim2.new(0, 5, startPos.Y.Scale, startPos.Y.Offset)
        }, {
            Style = "Spring",
            Duration = 0.05
        })
        task.wait(0.05)
        self.Animations:Animate(self.KeyInput, {
            Position = UDim2.new(0, -5, startPos.Y.Scale, startPos.Y.Offset)
        }, {
            Style = "Spring",
            Duration = 0.05
        })
        task.wait(0.05)
    end
    
    self.Animations:Animate(self.KeyInput, {
        Position = startPos
    }, {
        Style = "Spring",
        Duration = 0.1
    })
    
    -- Fade out error
    task.wait(3)
    self.Animations:Animate(self.Error, {
        TextTransparency = 1
    }, {
        Style = "Fluid",
        Duration = 0.5
    })
end

function KeySystem:_closeUI()
    if not self.UI then return end
    
    -- Animate out
    self.Animations:Animate(self.Modal, {
        Size = UDim2.new(0, 400, 0, 0),
        BackgroundTransparency = 1
    }, {
        Style = "Spring",
        Duration = 0.3
    })
    
    task.wait(0.3)
    
    if self.UI then
        self.UI:Destroy()
        self.UI = nil
    end
end

function KeySystem:IsValidated()
    return self.Validated
end

function KeySystem:GetCurrentKey()
    return self.CurrentKey
end

function KeySystem:Reset()
    self.Validated = false
    self.CurrentKey = nil
    self.Attempts = 0
    self.Locked = false
    self.LockUntil = 0
    
    if self.Config.SaveKey then
        self:_deleteKey()
    end
    
    if self.UI then
        self.UI:Destroy()
        self.UI = nil
    end
end

function KeySystem:SetKeys(keys)
    self.Config.Keys = keys or {}
end

function KeySystem:AddKey(key)
    table.insert(self.Config.Keys, key)
end

function KeySystem:RemoveKey(key)
    for i, k in ipairs(self.Config.Keys) do
        if k == key then
            table.remove(self.Config.Keys, i)
            break
        end
    end
end

function KeySystem:Destroy()
    if self.UI then
        self.UI:Destroy()
    end
end

return KeySystem