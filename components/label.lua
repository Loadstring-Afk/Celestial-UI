-- Premium label component with rich text and markdown-like support

local Label = {}
Label.__index = Label

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

function Label.new(config, parent, theme, animations)
    local self = setmetatable({}, Label)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Text = config.Text or ""
    self.RichText = config.RichText or false
    self.Markdown = config.Markdown or false
    
    self:_createLabel()
    
    return self
end

function Label:_createLabel()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialLabel"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 0)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.AutomaticSize = Enum.AutomaticSize.Y
    self.Container.Parent = self.Parent
    
    if self.RichText or self.Markdown then
        self:_createRichLabel()
    else
        self:_createSimpleLabel()
    end
    
    -- Set initial text
    self:SetText(self.Text)
end

function Label:_createSimpleLabel()
    -- Simple text label
    self.TextLabel = Instance.new("TextLabel")
    self.TextLabel.Name = "Label"
    self.TextLabel.BackgroundTransparency = 1
    self.TextLabel.Size = UDim2.new(1, 0, 0, 0)
    self.TextLabel.Position = UDim2.new(0, 0, 0, 0)
    self.TextLabel.Font = self.Config.Font or Enum.Font.Gotham
    self.TextLabel.TextColor3 = self.Theme:GetColor("Label", "Text") or self.Theme:GetColor("Window", "Title")
    self.TextLabel.TextSize = self.Config.TextSize or 14
    self.TextLabel.TextWrapped = true
    self.TextLabel.TextXAlignment = self.Config.Alignment or Enum.TextXAlignment.Left
    self.TextLabel.AutomaticSize = Enum.AutomaticSize.Y
    self.TextLabel.Parent = self.Container
    
    -- Optional icon
    if self.Config.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 20, 0, 20)
        self.Icon.Position = UDim2.new(0, 0, 0, 0)
        self.Icon.Image = self:_getIcon(self.Config.Icon)
        self.Icon.ImageColor3 = self.TextLabel.TextColor3
        self.Icon.ImageTransparency = 0.3
        self.Icon.Parent = self.Container
        
        -- Adjust text position
        self.TextLabel.Position = UDim2.new(0, 30, 0, 0)
        self.TextLabel.Size = UDim2.new(1, -30, 0, 0)
    end
end

function Label:_createRichLabel()
    -- Container for rich text elements
    self.RichContainer = Instance.new("Frame")
    self.RichContainer.Name = "RichContainer"
    self.RichContainer.BackgroundTransparency = 1
    self.RichContainer.Size = UDim2.new(1, 0, 0, 0)
    self.RichContainer.Position = UDim2.new(0, 0, 0, 0)
    self.RichContainer.AutomaticSize = Enum.AutomaticSize.Y
    self.RichContainer.Parent = self.Container
    
    -- Layout for rich elements
    local layout = Instance.new("UIListLayout")
    layout.Name = "Layout"
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = self.RichContainer
    
    -- Padding
    local padding = Instance.new("UIPadding")
    padding.Name = "Padding"
    padding.PaddingLeft = UDim.new(0, 0)
    padding.PaddingRight = UDim.new(0, 0)
    padding.PaddingTop = UDim.new(0, 0)
    padding.PaddingBottom = UDim.new(0, 0)
    padding.Parent = self.RichContainer
end

function Label:_parseMarkdown(text)
    -- Simple markdown parser
    local elements = {}
    local lines = string.split(text, "\n")
    
    for _, line in ipairs(lines) do
        if line == "" then
            -- Empty line (paragraph break)
            table.insert(elements, {type = "break"})
        elseif line:match("^#%s+") then
            -- Heading 1
            local content = line:gsub("^#%s+", "")
            table.insert(elements, {
                type = "heading",
                level = 1,
                content = content
            })
        elseif line:match("^##%s+") then
            -- Heading 2
            local content = line:gsub("^##%s+", "")
            table.insert(elements, {
                type = "heading",
                level = 2,
                content = content
            })
        elseif line:match("^###%s+") then
            -- Heading 3
            local content = line:gsub("^###%s+", "")
            table.insert(elements, {
                type = "heading",
                level = 3,
                content = content
            })
        elseif line:match("^%*%s+") or line:match("^%-%s+") then
            -- List item
            local content = line:gsub("^[%*%-]%s+", "")
            table.insert(elements, {
                type = "list",
                content = content,
                bullet = "•"
            })
        elseif line:match("^%d+%.%s+") then
            -- Numbered list
            local content = line:gsub("^%d+%.%s+", "")
            table.insert(elements, {
                type = "list",
                content = content,
                bullet = "numbered"
            })
        elseif line:match("%*%*.*%*%*") or line:match("__.*__") then
            -- Bold text
            local content = line:gsub("%*%*(.*)%*%*", "<b>%1</b>")
            content = content:gsub("__(.*)__", "<b>%1</b>")
            table.insert(elements, {
                type = "paragraph",
                content = content
            })
        elseif line:match("%*.*%*") or line:match("_.*_") then
            -- Italic text
            local content = line:gsub("%*(.*)%*", "<i>%1</i>")
            content = content:gsub("_(.*)_", "<i>%1</i>")
            table.insert(elements, {
                type = "paragraph",
                content = content
            })
        elseif line:match("`[^`]+`") then
            -- Inline code
            local content = line:gsub("`([^`]+)`", "<code>%1</code>")
            table.insert(elements, {
                type = "paragraph",
                content = content
            })
        else
            -- Regular paragraph
            table.insert(elements, {
                type = "paragraph",
                content = line
            })
        end
    end
    
    return elements
end

function Label:_createTextElement(config)
    local element = Instance.new("TextLabel")
    element.Name = "TextElement"
    element.BackgroundTransparency = 1
    element.Size = UDim2.new(1, 0, 0, 0)
    element.AutomaticSize = Enum.AutomaticSize.Y
    element.TextWrapped = true
    element.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Apply styling based on type
    if config.type == "heading" then
        element.Font = Enum.Font.GothamBold
        element.TextColor3 = self.Theme:GetColor("Label", "Heading") or Color3.fromRGB(240, 240, 245)
        
        if config.level == 1 then
            element.TextSize = 24
            element.Text = config.content
        elseif config.level == 2 then
            element.TextSize = 20
            element.Text = config.content
        else
            element.TextSize = 16
            element.Text = config.content
        end
    elseif config.type == "paragraph" then
        element.Font = Enum.Font.Gotham
        element.TextSize = 14
        element.TextColor3 = self.Theme:GetColor("Label", "Text") or Color3.fromRGB(220, 220, 225)
        element.Text = config.content
        
        -- Parse inline formatting
        element.RichText = true
    elseif config.type == "list" then
        element.Font = Enum.Font.Gotham
        element.TextSize = 14
        element.TextColor3 = self.Theme:GetColor("Label", "Text") or Color3.fromRGB(220, 220, 225)
        
        if config.bullet == "numbered" then
            -- This would need dynamic numbering in a real implementation
            element.Text = "• " .. config.content
        else
            element.Text = config.bullet .. " " .. config.content
        end
        
        -- Indent
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 20)
        padding.Parent = element
    elseif config.type == "break" then
        -- Spacer
        element.Size = UDim2.new(1, 0, 0, 10)
        element.AutomaticSize = Enum.AutomaticSize.None
    end
    
    return element
end

function Label:_parseRichText(text)
    -- Simple rich text parser for <b>, <i>, <code> tags
    local parts = {}
    local currentPos = 1
    
    while currentPos <= #text do
        -- Look for tags
        local boldStart, boldEnd = text:find("<b>", currentPos)
        local italicStart, italicEnd = text:find("<i>", currentPos)
        local codeStart, codeEnd = text:find("<code>", currentPos)
        
        local nextTag = math.min(
            boldStart or math.huge,
            italicStart or math.huge,
            codeStart or math.huge
        )
        
        if nextTag == math.huge then
            -- No more tags, add remaining text
            table.insert(parts, {
                text = text:sub(currentPos),
                style = "normal"
            })
            break
        end
        
        -- Add text before tag
        if nextTag > currentPos then
            table.insert(parts, {
                text = text:sub(currentPos, nextTag - 1),
                style = "normal"
            })
        end
        
        -- Handle tag
        if nextTag == boldStart then
            local tagEnd = text:find("</b>", boldEnd + 1)
            if tagEnd then
                table.insert(parts, {
                    text = text:sub(boldEnd + 1, tagEnd - 1),
                    style = "bold"
                })
                currentPos = tagEnd + 4
            else
                currentPos = boldEnd + 1
            end
        elseif nextTag == italicStart then
            local tagEnd = text:find("</i>", italicEnd + 1)
            if tagEnd then
                table.insert(parts, {
                    text = text:sub(italicEnd + 1, tagEnd - 1),
                    style = "italic"
                })
                currentPos = tagEnd + 4
            else
                currentPos = italicEnd + 1
            end
        elseif nextTag == codeStart then
            local tagEnd = text:find("</code>", codeEnd + 1)
            if tagEnd then
                table.insert(parts, {
                    text = text:sub(codeEnd + 1, tagEnd - 1),
                    style = "code"
                })
                currentPos = tagEnd + 7
            else
                currentPos = codeEnd + 1
            end
        end
    end
    
    return parts
end

function Label:_createRichTextElement(parts)
    local container = Instance.new("Frame")
    container.Name = "RichText"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.XY
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 0)
    layout.Parent = container
    
    for _, part in ipairs(parts) do
        local textLabel = Instance.new("TextLabel")
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(0, 0, 0, 0)
        textLabel.AutomaticSize = Enum.AutomaticSize.XY
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextSize = 14
        textLabel.TextColor3 = self.Theme:GetColor("Label", "Text") or Color3.fromRGB(220, 220, 225)
        textLabel.Text = part.text
        
        if part.style == "bold" then
            textLabel.Font = Enum.Font.GothamBold
        elseif part.style == "italic" then
            textLabel.Font = Enum.Font.Gotham
            textLabel.FontStyle = Enum.FontStyle.Italic
        elseif part.style == "code" then
            textLabel.Font = Enum.Font.Code
            textLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            textLabel.BackgroundTransparency = 0.5
            textLabel.TextColor3 = Color3.fromRGB(220, 220, 100)
            
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 4)
            padding.PaddingRight = UDim.new(0, 4)
            padding.PaddingTop = UDim.new(0, 2)
            padding.PaddingBottom = UDim.new(0, 2)
            padding.Parent = textLabel
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = textLabel
        end
        
        textLabel.Parent = container
    end
    
    return container
end

function Label:SetText(text)
    self.Text = text
    
    if self.RichContainer then
        -- Clear existing elements
        for _, child in ipairs(self.RichContainer:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        if self.Markdown then
            -- Parse markdown
            local elements = self:_parseMarkdown(text)
            
            for i, element in ipairs(elements) do
                local uiElement = self:_createTextElement(element)
                uiElement.LayoutOrder = i
                uiElement.Parent = self.RichContainer
            end
        else
            -- Parse rich text
            local parts = self:_parseRichText(text)
            if #parts > 0 then
                local richElement = self:_createRichTextElement(parts)
                richElement.Parent = self.RichContainer
            end
        end
    else
        -- Simple text label
        self.TextLabel.Text = text
        
        -- Auto-size if needed
        if self.Config.AutoSize then
            local textSize = TextService:GetTextSize(
                text,
                self.TextLabel.TextSize,
                self.TextLabel.Font,
                Vector2.new(self.Container.AbsoluteSize.X, math.huge)
            )
            
            self.Container.Size = UDim2.new(
                self.Container.Size.X.Scale,
                self.Container.Size.X.Offset,
                0,
                textSize.Y + (self.Icon and 0 or 0)
            )
        end
    end
end

function Label:SetColor(color)
    if self.TextLabel then
        self.TextLabel.TextColor3 = color
    elseif self.RichContainer then
        -- Would need to update all text elements
        for _, child in ipairs(self.RichContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextColor3 = color
            end
        end
    end
end

function Label:SetAlignment(alignment)
    if self.TextLabel then
        self.TextLabel.TextXAlignment = alignment
    end
end

function Label:SetFont(font)
    if self.TextLabel then
        self.TextLabel.Font = font
    elseif self.RichContainer then
        for _, child in ipairs(self.RichContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                child.Font = font
            end
        end
    end
end

function Label:SetTextSize(size)
    if self.TextLabel then
        self.TextLabel.TextSize = size
    elseif self.RichContainer then
        for _, child in ipairs(self.RichContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                child.TextSize = size
            end
        end
    end
end

function Label:AddIcon(iconName)
    if not self.Icon then
        self.Icon = Instance.new("ImageLabel")
        self.Icon.Name = "Icon"
        self.Icon.BackgroundTransparency = 1
        self.Icon.Size = UDim2.new(0, 20, 0, 20)
        self.Icon.Position = UDim2.new(0, 0, 0, 0)
        self.Icon.Parent = self.Container
        
        -- Adjust text position
        if self.TextLabel then
            self.TextLabel.Position = UDim2.new(0, 30, 0, 0)
            self.TextLabel.Size = UDim2.new(1, -30, 0, 0)
        end
    end
    
    self.Icon.Image = self:_getIcon(iconName)
    self.Icon.ImageColor3 = self.Theme:GetColor("Label", "Text") or Color3.fromRGB(220, 220, 225)
end

function Label:SetClickable(callback)
    if not self.Container:IsA("TextButton") then
        local textButton = Instance.new("TextButton")
        
        -- Copy properties
        for prop, value in pairs(self.Container:GetProperties()) do
            if textButton[prop] and prop ~= "ClassName" then
                textButton[prop] = value
            end
        end
        
        -- Copy children
        for _, child in ipairs(self.Container:GetChildren()) do
            child.Parent = textButton
        end
        
        -- Replace container
        local oldContainer = self.Container
        self.Container = textButton
        self.Container.Parent = oldContainer.Parent
        oldContainer:Destroy()
        
        -- Add click event
        self.Container.MouseButton1Click:Connect(function()
            if callback then
                task.spawn(callback)
            end
        end)
        
        -- Add hover effects
        self.Container.MouseEnter:Connect(function()
            self.Animations:Animate(self.Container, {
                BackgroundTransparency = 0.9
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end)
        
        self.Container.MouseLeave:Connect(function()
            self.Animations:Animate(self.Container, {
                BackgroundTransparency = 1
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end)
    end
end

function Label:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Label:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Label