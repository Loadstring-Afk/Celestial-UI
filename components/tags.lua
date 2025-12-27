-- Premium tags/chips component with fluid animations

local Tags = {}
Tags.__index = Tags

function Tags.new(config, parent, theme, animations)
    local self = setmetatable({}, Tags)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Tags = config.Tags or {}
    self.Selectable = config.Selectable or false
    self.MultiSelect = config.MultiSelect or false
    self.SelectedTags = {}
    self.Removable = config.Removable or false
    
    self:_createTagsContainer()
    self:_createTags()
    
    return self
end

function Tags:_createTagsContainer()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialTags"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 0)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    self.Container.AutomaticSize = Enum.AutomaticSize.Y
    self.Container.Parent = self.Parent
    
    -- Flow layout for tags
    self.Layout = Instance.new("UIGridLayout")
    self.Layout.Name = "Layout"
    self.Layout.CellSize = UDim2.new(0, 100, 0, 30)
    self.Layout.CellPadding = UDim2.new(0, 8, 0, 8)
    self.Layout.StartCorner = Enum.StartCorner.TopLeft
    self.Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    self.Layout.VerticalAlignment = Enum.VerticalAlignment.Top
    self.Layout.Parent = self.Container
    
    -- Input for adding new tags (if enabled)
    if self.Config.Addable then
        self:_createAddInput()
    end
end

function Tags:_createAddInput()
    self.AddContainer = Instance.new("Frame")
    self.AddContainer.Name = "AddContainer"
    self.AddContainer.BackgroundColor3 = self.Theme:GetColor("Tags", "Background") or Color3.fromRGB(50, 50, 55)
    self.AddContainer.BackgroundTransparency = 0.1
    self.AddContainer.Size = UDim2.new(0, 120, 0, 30)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = self.AddContainer
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme:GetColor("Tags", "Stroke") or Color3.fromRGB(70, 70, 75)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = self.AddContainer
    
    -- Plus icon
    local plusIcon = Instance.new("ImageLabel")
    plusIcon.Name = "PlusIcon"
    plusIcon.BackgroundTransparency = 1
    plusIcon.Size = UDim2.new(0, 16, 0, 16)
    plusIcon.Position = UDim2.new(0, 8, 0.5, -8)
    plusIcon.AnchorPoint = Vector2.new(0, 0.5)
    plusIcon.Image = "rbxassetid://7072716648" -- Plus icon
    plusIcon.ImageColor3 = self.Theme:GetColor("Tags", "Text") or Color3.fromRGB(180, 180, 190)
    plusIcon.ImageTransparency = 0.3
    plusIcon.Parent = self.AddContainer
    
    -- Input
    self.AddInput = Instance.new("TextBox")
    self.AddInput.Name = "Input"
    self.AddInput.BackgroundTransparency = 1
    self.AddInput.Size = UDim2.new(1, -30, 1, 0)
    self.AddInput.Position = UDim2.new(0, 30, 0, 0)
    self.AddInput.Font = Enum.Font.Gotham
    self.AddInput.PlaceholderText = "Add tag..."
    self.AddInput.PlaceholderColor3 = self.Theme:GetColor("Tags", "Text")
    self.AddInput.TextColor3 = self.Theme:GetColor("Tags", "Text")
    self.AddInput.TextSize = 12
    self.AddInput.TextXAlignment = Enum.TextXAlignment.Left
    self.AddInput.Parent = self.AddContainer
    
    self.AddContainer.Parent = self.Container
    
    -- Input events
    self.AddInput.Focused:Connect(function()
        self.Animations:Animate(self.AddContainer, {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 150, 0, 30)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
    end)
    
    self.AddInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and self.AddInput.Text ~= "" then
            self:AddTag(self.AddInput.Text)
            self.AddInput.Text = ""
        end
        
        self.Animations:Animate(self.AddContainer, {
            BackgroundTransparency = 0.1,
            Size = UDim2.new(0, 120, 0, 30)
        }, {
            Style = "Spring",
            Duration = 0.3
        })
    end)
    
    -- Click container to focus
    self.AddContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.AddInput:CaptureFocus()
        end
    end)
end

function Tags:_createTags()
    -- Clear existing tags
    for _, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "AddContainer" then
            child:Destroy()
        end
    end
    
    -- Create tags
    for i, tagText in ipairs(self.Tags) do
        self:_createTag(tagText, i)
    end
end

function Tags:_createTag(text, index)
    local tag = Instance.new("Frame")
    tag.Name = "Tag_" .. text
    tag.BackgroundColor3 = self.Theme:GetColor("Tags", "Background") or Color3.fromRGB(50, 50, 55)
    tag.BackgroundTransparency = 0.1
    tag.Size = UDim2.new(0, 0, 0, 30)
    tag.AutomaticSize = Enum.AutomaticSize.X
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = tag
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.Theme:GetColor("Tags", "Stroke") or Color3.fromRGB(70, 70, 75)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = tag
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, self.Removable and -30 or -10, 1, 0)
    content.Position = UDim2.new(0, 10, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.X
    content.Parent = tag
    
    -- Icon (optional)
    if self.Config.Icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 14, 0, 14)
        icon.Position = UDim2.new(0, 0, 0.5, -7)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Image = self:_getIcon(self.Config.Icon)
        icon.ImageColor3 = self.Theme:GetColor("Tags", "Icon") or self.Theme:GetColor("Tags", "Text")
        icon.ImageTransparency = 0.3
        icon.Parent = content
    end
    
    -- Text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(0, 0, 1, 0)
    textLabel.Position = UDim2.new(0, self.Config.Icon and 20 or 0, 0, 0)
    textLabel.Font = Enum.Font.Gotham
    textLabel.Text = text
    textLabel.TextColor3 = self.Theme:GetColor("Tags", "Text") or Color3.fromRGB(220, 220, 225)
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.AutomaticSize = Enum.AutomaticSize.X
    textLabel.Parent = content
    
    -- Close button (if removable)
    if self.Removable then
        local closeButton = Instance.new("ImageButton")
        closeButton.Name = "Close"
        closeButton.BackgroundTransparency = 1
        closeButton.Size = UDim2.new(0, 20, 0, 20)
        closeButton.Position = UDim2.new(1, -25, 0.5, -10)
        closeButton.AnchorPoint = Vector2.new(1, 0.5)
        closeButton.Image = "rbxassetid://7072720899" -- X icon
        closeButton.ImageColor3 = self.Theme:GetColor("Tags", "Text")
        closeButton.ImageTransparency = 0.5
        closeButton.Parent = tag
        
        -- Close button events
        closeButton.MouseButton1Click:Connect(function()
            self:RemoveTag(text)
        end)
        
        closeButton.MouseEnter:Connect(function()
            self.Animations:Animate(closeButton, {
                ImageTransparency = 0.1,
                Rotation = 90
            }, {
                Style = "Spring",
                Duration = 0.2
            })
        end)
        
        closeButton.MouseLeave:Connect(function()
            self.Animations:Animate(closeButton, {
                ImageTransparency = 0.5,
                Rotation = 0
            }, {
                Style = "Spring",
                Duration = 0.2
            })
        end)
    end
    
    -- Layout for content
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 5)
    layout.Parent = content
    
    -- Add to container
    tag.Parent = self.Container
    
    -- Check if selected
    if self.Selectable and table.find(self.SelectedTags, text) then
        self:_setTagSelected(tag, true, true)
    end
    
    -- Tag events
    if self.Selectable then
        tag.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                self:_onTagClick(text, tag)
            end
        end)
    end
    
    tag.MouseEnter:Connect(function()
        self:_onTagHover(tag, true)
    end)
    
    tag.MouseLeave:Connect(function()
        self:_onTagHover(tag, false)
    end)
    
    -- Animate in
    self.Animations:Animate(tag, {
        Size = UDim2.new(0, tag.AbsoluteSize.X, 0, 30)
    }, {
        Style = "Spring",
        Duration = 0.3,
        Delay = (index - 1) * 0.05
    })
    
    return tag
end

function Tags:_onTagClick(text, tag)
    if not self.Selectable then return end
    
    if self.MultiSelect then
        -- Toggle selection
        local index = table.find(self.SelectedTags, text)
        
        if index then
            -- Deselect
            table.remove(self.SelectedTags, index)
            self:_setTagSelected(tag, false)
        else
            -- Select
            table.insert(self.SelectedTags, text)
            self:_setTagSelected(tag, true)
        end
    else
        -- Single select
        if #self.SelectedTags > 0 and self.SelectedTags[1] == text then
            -- Deselect if already selected
            self.SelectedTags = {}
            self:_setTagSelected(tag, false)
        else
            -- Select new tag
            self.SelectedTags = {text}
            
            -- Deselect all other tags
            for _, child in ipairs(self.Container:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "AddContainer" and child ~= tag then
                    self:_setTagSelected(child, false)
                end
            end
            
            self:_setTagSelected(tag, true)
        end
    end
    
    -- Call callback
    if self.Config.OnSelect then
        task.spawn(self.Config.OnSelect, self.SelectedTags)
    end
end

function Tags:_onTagHover(tag, enter)
    if enter then
        self.Animations:Animate(tag, {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, tag.AbsoluteSize.X, 0, 32)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
        
        self.Animations:Animate(tag.UIStroke, {
            Thickness = 2
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    else
        local isSelected = table.find(self.SelectedTags, tag.Name:gsub("Tag_", "")) ~= nil
        
        self.Animations:Animate(tag, {
            BackgroundTransparency = isSelected and 0.1 or 0.1,
            Size = UDim2.new(0, tag.AbsoluteSize.X, 0, 30)
        }, {
            Style = "Spring",
            Duration = 0.2
        })
        
        self.Animations:Animate(tag.UIStroke, {
            Thickness = 1
        }, {
            Style = "Fluid",
            Duration = 0.2
        })
    end
end

function Tags:_setTagSelected(tag, selected, instant)
    if selected then
        if instant then
            tag.BackgroundColor3 = self.Theme:GetColor("Tags", "Selected") or Color3.fromRGB(80, 140, 255)
            tag.UIStroke.Color = self.Theme:GetColor("Tags", "Selected") or Color3.fromRGB(80, 140, 255)
            tag.BackgroundTransparency = 0.1
        else
            self.Animations:Animate(tag, {
                BackgroundColor3 = self.Theme:GetColor("Tags", "Selected") or Color3.fromRGB(80, 140, 255),
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
            
            self.Animations:Animate(tag.UIStroke, {
                Color = self.Theme:GetColor("Tags", "Selected") or Color3.fromRGB(80, 140, 255),
                Transparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
            
            -- Pulse effect
            self.Animations:Animate(tag, {
                Size = UDim2.new(0, tag.AbsoluteSize.X * 1.05, 0, 32)
            }, {
                Style = "Spring",
                Duration = 0.2
            })
            
            self.Animations:Animate(tag, {
                Size = UDim2.new(0, tag.AbsoluteSize.X, 0, 30)
            }, {
                Style = "Spring",
                Duration = 0.2,
                Delay = 0.2
            })
        end
    else
        if instant then
            tag.BackgroundColor3 = self.Theme:GetColor("Tags", "Background") or Color3.fromRGB(50, 50, 55)
            tag.UIStroke.Color = self.Theme:GetColor("Tags", "Stroke") or Color3.fromRGB(70, 70, 75)
            tag.BackgroundTransparency = 0.1
        else
            self.Animations:Animate(tag, {
                BackgroundColor3 = self.Theme:GetColor("Tags", "Background") or Color3.fromRGB(50, 50, 55),
                BackgroundTransparency = 0.1
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
            
            self.Animations:Animate(tag.UIStroke, {
                Color = self.Theme:GetColor("Tags", "Stroke") or Color3.fromRGB(70, 70, 75),
                Transparency = 0.3
            }, {
                Style = "Fluid",
                Duration = 0.3
            })
        end
    end
end

function Tags:AddTag(text)
    if not text or text == "" then return end
    
    -- Check if tag already exists
    if table.find(self.Tags, text) then
        return
    end
    
    table.insert(self.Tags, text)
    self:_createTag(text, #self.Tags + 1)
    
    -- Call callback
    if self.Config.OnAdd then
        task.spawn(self.Config.OnAdd, text)
    end
end

function Tags:RemoveTag(text)
    local index = table.find(self.Tags, text)
    if not index then return end
    
    -- Remove from tags list
    table.remove(self.Tags, index)
    
    -- Remove from selected if selected
    local selectedIndex = table.find(self.SelectedTags, text)
    if selectedIndex then
        table.remove(self.SelectedTags, selectedIndex)
    end
    
    -- Find and animate out the tag
    for _, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Tag_" .. text then
            self.Animations:Animate(child, {
                Size = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1
            }, {
                Style = "Spring",
                Duration = 0.3
            })
            
            task.delay(0.3, function()
                if child and child.Parent then
                    child:Destroy()
                end
            end)
            
            break
        end
    end
    
    -- Call callback
    if self.Config.OnRemove then
        task.spawn(self.Config.OnRemove, text)
    end
end

function Tags:SetTags(tags)
    self.Tags = tags or {}
    self.SelectedTags = {}
    self:_createTags()
end

function Tags:GetTags()
    return self.Tags
end

function Tags:GetSelectedTags()
    return self.SelectedTags
end

function Tags:ClearSelected()
    -- Deselect all tags
    for _, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "AddContainer" then
            self:_setTagSelected(child, false)
        end
    end
    
    self.SelectedTags = {}
end

function Tags:Clear()
    self.Tags = {}
    self.SelectedTags = {}
    
    for _, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "AddContainer" then
            child:Destroy()
        end
    end
end

function Tags:SetSelectable(selectable, multiSelect)
    self.Selectable = selectable
    self.MultiSelect = multiSelect or false
    
    if not selectable then
        self:ClearSelected()
    end
end

function Tags:SetRemovable(removable)
    self.Removable = removable
    
    -- Update existing tags
    for _, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "AddContainer" then
            local closeButton = child:FindFirstChild("Close")
            
            if removable and not closeButton then
                -- Add close button
                local closeButton = Instance.new("ImageButton")
                closeButton.Name = "Close"
                closeButton.BackgroundTransparency = 1
                closeButton.Size = UDim2.new(0, 20, 0, 20)
                closeButton.Position = UDim2.new(1, -25, 0.5, -10)
                closeButton.AnchorPoint = Vector2.new(1, 0.5)
                closeButton.Image = "rbxassetid://7072720899"
                closeButton.ImageColor3 = self.Theme:GetColor("Tags", "Text")
                closeButton.ImageTransparency = 0.5
                closeButton.Parent = child
                
                -- Adjust content size
                local content = child:FindFirstChild("Content")
                if content then
                    content.Size = UDim2.new(1, -30, 1, 0)
                end
                
                -- Close button events
                closeButton.MouseButton1Click:Connect(function()
                    local tagName = child.Name:gsub("Tag_", "")
                    self:RemoveTag(tagName)
                end)
            elseif not removable and closeButton then
                -- Remove close button
                closeButton:Destroy()
                
                -- Adjust content size
                local content = child:FindFirstChild("Content")
                if content then
                    content.Size = UDim2.new(1, -10, 1, 0)
                end
            end
        end
    end
end

function Tags:_getIcon(iconName)
    -- Connect to icon system
    -- This is a placeholder
    return iconName
end

function Tags:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return Tags