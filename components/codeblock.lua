-- Premium code block component with syntax highlighting

local CodeBlock = {}
CodeBlock.__index = CodeBlock

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

-- Syntax highlighting rules
local SyntaxRules = {
    Lua = {
        keywords = {
            "and", "break", "do", "else", "elseif", "end", "false", "for",
            "function", "goto", "if", "in", "local", "nil", "not", "or",
            "repeat", "return", "then", "true", "until", "while"
        },
        builtins = {
            -- Global functions
            "assert", "collectgarbage", "dofile", "error", "getmetatable",
            "ipairs", "load", "loadfile", "next", "pairs", "pcall", "print",
            "rawequal", "rawget", "rawlen", "rawset", "require", "select",
            "setmetatable", "tonumber", "tostring", "type", "xpcall",
            -- Global tables
            "_G", "_VERSION", "arg", "coroutine", "debug", "io", "math",
            "os", "package", "string", "table", "utf8"
        },
        patterns = {
            {pattern = "%-%-%[%[.*%]%]", color = Color3.fromRGB(100, 150, 100)}, -- Multi-line comments
            {pattern = "%-%-.*", color = Color3.fromRGB(100, 150, 100)}, -- Single-line comments
            {pattern = "\".-[^\\]\"", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "\'.-[^\\]\'", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "%[%[.*%]%]", color = Color3.fromRGB(220, 180, 120)}, -- Long strings
            {pattern = "0x[%x]+", color = Color3.fromRGB(180, 220, 180)}, -- Hex numbers
            {pattern = "%.?%d+%.?%d*[eE]?[+-]?%d*", color = Color3.fromRGB(180, 220, 180)}, -- Numbers
        }
    },
    
    JavaScript = {
        keywords = {
            "break", "case", "catch", "class", "const", "continue", "debugger",
            "default", "delete", "do", "else", "export", "extends", "finally",
            "for", "function", "if", "import", "in", "instanceof", "new",
            "return", "super", "switch", "this", "throw", "try", "typeof",
            "var", "void", "while", "with", "yield"
        },
        builtins = {
            "Array", "Boolean", "Date", "Error", "Function", "JSON", "Math",
            "Number", "Object", "RegExp", "String", "Map", "Set", "Promise",
            "console", "window", "document", "navigator"
        },
        patterns = {
            {pattern = "/%*.*%*/", color = Color3.fromRGB(100, 150, 100)}, -- Multi-line comments
            {pattern = "//.*", color = Color3.fromRGB(100, 150, 100)}, -- Single-line comments
            {pattern = "\".-[^\\]\"", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "\'.-[^\\]\'", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "`.-`", color = Color3.fromRGB(220, 180, 120)}, -- Template strings
            {pattern = "0x[%x]+", color = Color3.fromRGB(180, 220, 180)}, -- Hex numbers
            {pattern = "%.?%d+%.?%d*[eE]?[+-]?%d*", color = Color3.fromRGB(180, 220, 180)}, -- Numbers
            {pattern = "true|false|null|undefined", color = Color3.fromRGB(180, 140, 220)}, -- Literals
        }
    },
    
    Python = {
        keywords = {
            "False", "None", "True", "and", "as", "assert", "async", "await",
            "break", "class", "continue", "def", "del", "elif", "else",
            "except", "finally", "for", "from", "global", "if", "import",
            "in", "is", "lambda", "nonlocal", "not", "or", "pass", "raise",
            "return", "try", "while", "with", "yield"
        },
        builtins = {
            "abs", "all", "any", "ascii", "bin", "bool", "bytearray", "bytes",
            "callable", "chr", "classmethod", "compile", "complex", "delattr",
            "dict", "dir", "divmod", "enumerate", "eval", "exec", "filter",
            "float", "format", "frozenset", "getattr", "globals", "hasattr",
            "hash", "help", "hex", "id", "input", "int", "isinstance",
            "issubclass", "iter", "len", "list", "locals", "map", "max",
            "memoryview", "min", "next", "object", "oct", "open", "ord",
            "pow", "print", "property", "range", "repr", "reversed", "round",
            "set", "setattr", "slice", "sorted", "staticmethod", "str",
            "sum", "super", "tuple", "type", "vars", "zip"
        },
        patterns = {
            {pattern = "#.*", color = Color3.fromRGB(100, 150, 100)}, -- Comments
            {pattern = "\".-[^\\]\"", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "\'.-[^\\]\'", color = Color3.fromRGB(220, 180, 120)}, -- Strings
            {pattern = "\"\"\".*\"\"\"", color = Color3.fromRGB(220, 180, 120)}, -- Docstrings
            {pattern = "\'\'\'.*\'\'\'", color = Color3.fromRGB(220, 180, 120)}, -- Docstrings
            {pattern = "0x[%x]+", color = Color3.fromRGB(180, 220, 180)}, -- Hex numbers
            {pattern = "%.?%d+%.?%d*[eE]?[+-]?%d*", color = Color3.fromRGB(180, 220, 180)}, -- Numbers
        }
    }
}

function CodeBlock.new(config, parent, theme, animations)
    local self = setmetatable({}, CodeBlock)
    
    self.Config = config
    self.Parent = parent
    self.Theme = theme
    self.Animations = animations
    
    self.Code = config.Code or ""
    self.Language = config.Language or "Lua"
    self.ShowLineNumbers = config.LineNumbers or true
    self.Copyable = config.Copyable or true
    
    self:_createCodeBlock()
    
    -- Set initial code
    if self.Code ~= "" then
        self:SetCode(self.Code)
    end
    
    return self
end

function CodeBlock:_createCodeBlock()
    -- Main container
    self.Container = Instance.new("Frame")
    self.Container.Name = "CelestialCodeBlock"
    self.Container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.Container.BackgroundTransparency = 0.1
    self.Container.Size = self.Config.Size or UDim2.new(1, -20, 0, 200)
    self.Container.Position = self.Config.Position or UDim2.new(0, 10, 0, 0)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.Container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 45)
    stroke.Transparency = 0.3
    stroke.Thickness = 1
    stroke.Parent = self.Container
    
    -- Header
    self.Header = Instance.new("Frame")
    self.Header.Name = "Header"
    self.Header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.Header.BackgroundTransparency = 0.2
    self.Header.Size = UDim2.new(1, 0, 0, 30)
    self.Header.Position = UDim2.new(0, 0, 0, 0)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8, 0, 0)
    headerCorner.Parent = self.Header
    
    self.Header.Parent = self.Container
    
    -- Language label
    self.LanguageLabel = Instance.new("TextLabel")
    self.LanguageLabel.Name = "Language"
    self.LanguageLabel.BackgroundTransparency = 1
    self.LanguageLabel.Size = UDim2.new(0.5, -10, 1, 0)
    self.LanguageLabel.Position = UDim2.new(0, 10, 0, 0)
    self.LanguageLabel.Font = Enum.Font.Gotham
    self.LanguageLabel.Text = self.Language
    self.LanguageLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    self.LanguageLabel.TextSize = 12
    self.LanguageLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.LanguageLabel.Parent = self.Header
    
    -- Copy button
    if self.Copyable then
        self.CopyButton = Instance.new("TextButton")
        self.CopyButton.Name = "CopyButton"
        self.CopyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        self.CopyButton.BackgroundTransparency = 0.5
        self.CopyButton.Size = UDim2.new(0, 60, 0, 20)
        self.CopyButton.Position = UDim2.new(1, -70, 0.5, -10)
        self.CopyButton.AnchorPoint = Vector2.new(1, 0.5)
        self.CopyButton.Font = Enum.Font.Gotham
        self.CopyButton.Text = "Copy"
        self.CopyButton.TextColor3 = Color3.fromRGB(220, 220, 225)
        self.CopyButton.TextSize = 12
        
        local copyCorner = Instance.new("UICorner")
        copyCorner.CornerRadius = UDim.new(0, 4)
        copyCorner.Parent = self.CopyButton
        
        self.CopyButton.Parent = self.Header
        
        -- Copy button events
        self.CopyButton.MouseButton1Click:Connect(function()
            self:CopyToClipboard()
        end)
        
        self.CopyButton.MouseEnter:Connect(function()
            self.Animations:Animate(self.CopyButton, {
                BackgroundTransparency = 0.3,
                TextColor3 = Color3.fromRGB(240, 240, 245)
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end)
        
        self.CopyButton.MouseLeave:Connect(function()
            self.Animations:Animate(self.CopyButton, {
                BackgroundTransparency = 0.5,
                TextColor3 = Color3.fromRGB(220, 220, 225)
            }, {
                Style = "Fluid",
                Duration = 0.2
            })
        end)
    end
    
    -- Content area
    self.Content = Instance.new("Frame")
    self.Content.Name = "Content"
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, -20, 1, -40)
    self.Content.Position = UDim2.new(0, 10, 0, 35)
    self.Content.ClipsDescendants = true
    self.Content.Parent = self.Container
    
    -- Scroll container
    self.ScrollContainer = Instance.new("ScrollingFrame")
    self.ScrollContainer.Name = "ScrollContainer"
    self.ScrollContainer.BackgroundTransparency = 1
    self.ScrollContainer.Size = UDim2.new(1, 0, 1, 0)
    self.ScrollContainer.Position = UDim2.new(0, 0, 0, 0)
    self.ScrollContainer.ScrollBarThickness = 4
    self.ScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
    self.ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ScrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ScrollContainer.Parent = self.Content
    
    -- Line numbers container
    if self.ShowLineNumbers then
        self.LineNumbers = Instance.new("Frame")
        self.LineNumbers.Name = "LineNumbers"
        self.LineNumbers.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        self.LineNumbers.BackgroundTransparency = 0.5
        self.LineNumbers.Size = UDim2.new(0, 40, 1, 0)
        self.LineNumbers.Position = UDim2.new(0, 0, 0, 0)
        
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(0, 6, 0, 0)
        lineCorner.Parent = self.LineNumbers
        
        self.LineNumbers.Parent = self.ScrollContainer
        
        -- Adjust code container position
        self.CodeContainer = Instance.new("Frame")
        self.CodeContainer.Name = "CodeContainer"
        self.CodeContainer.BackgroundTransparency = 1
        self.CodeContainer.Size = UDim2.new(1, -45, 0, 0)
        self.CodeContainer.Position = UDim2.new(0, 45, 0, 0)
        self.CodeContainer.AutomaticSize = Enum.AutomaticSize.Y
        self.CodeContainer.Parent = self.ScrollContainer
    else
        self.CodeContainer = Instance.new("Frame")
        self.CodeContainer.Name = "CodeContainer"
        self.CodeContainer.BackgroundTransparency = 1
        self.CodeContainer.Size = UDim2.new(1, 0, 0, 0)
        self.CodeContainer.Position = UDim2.new(0, 0, 0, 0)
        self.CodeContainer.AutomaticSize = Enum.AutomaticSize.Y
        self.CodeContainer.Parent = self.ScrollContainer
    end
    
    -- Layout for code lines
    self.CodeLayout = Instance.new("UIListLayout")
    self.CodeLayout.Name = "Layout"
    self.CodeLayout.Padding = UDim.new(0, 0)
    self.CodeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.CodeLayout.Parent = self.CodeContainer
    
    self.Container.Parent = self.Parent
end

function CodeBlock:_highlightSyntax()
    if not self.CodeContainer then return end
    
    -- Clear existing lines
    for _, child in ipairs(self.CodeContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Clear line numbers
    if self.LineNumbers then
        for _, child in ipairs(self.LineNumbers:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    end
    
    -- Split code into lines
    local lines = string.split(self.Code, "\n")
    local syntaxRules = SyntaxRules[self.Language] or SyntaxRules.Lua
    
    -- Create lines
    for lineNum, lineText in ipairs(lines) do
        self:_createCodeLine(lineNum, lineText, syntaxRules)
    end
    
    -- Update line numbers
    if self.LineNumbers then
        for i = 1, #lines do
            local lineNumber = Instance.new("TextLabel")
            lineNumber.Name = "Line" .. i
            lineNumber.BackgroundTransparency = 1
            lineNumber.Size = UDim2.new(1, 0, 0, 20)
            lineNumber.Position = UDim2.new(0, 0, 0, (i - 1) * 20)
            lineNumber.Font = Enum.Font.Code
            lineNumber.Text = tostring(i)
            lineNumber.TextColor3 = Color3.fromRGB(100, 100, 110)
            lineNumber.TextSize = 12
            lineNumber.TextXAlignment = Enum.TextXAlignment.Right
            lineNumber.Parent = self.LineNumbers
        end
    end
    
    -- Update canvas size
    task.wait()
    local totalHeight = self.CodeLayout.AbsoluteContentSize.Y
    self.ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

function CodeBlock:_createCodeLine(lineNum, lineText, syntaxRules)
    local lineContainer = Instance.new("Frame")
    lineContainer.Name = "Line" .. lineNum
    lineContainer.BackgroundTransparency = 1
    lineContainer.Size = UDim2.new(1, 0, 0, 20)
    lineContainer.LayoutOrder = lineNum
    lineContainer.Parent = self.CodeContainer
    
    -- Parse line for syntax highlighting
    local parts = self:_parseLine(lineText, syntaxRules)
    
    -- Create text elements for each part
    local currentX = 0
    for _, part in ipairs(parts) do
        local textLabel = Instance.new("TextLabel")
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(0, 0, 1, 0)
        textLabel.Position = UDim2.new(0, currentX, 0, 0)
        textLabel.Font = Enum.Font.Code
        textLabel.Text = part.text
        textLabel.TextColor3 = part.color
        textLabel.TextSize = 12
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.AutomaticSize = Enum.AutomaticSize.X
        textLabel.Parent = lineContainer
        
        -- Measure text width
        local textSize = TextService:GetTextSize(
            part.text,
            12,
            Enum.Font.Code,
            Vector2.new(1000, 20)
        )
        
        currentX = currentX + textSize.X
    end
    
    -- If line is empty, add a space to maintain height
    if #parts == 0 then
        local spacer = Instance.new("TextLabel")
        spacer.BackgroundTransparency = 1
        spacer.Size = UDim2.new(0, 10, 1, 0)
        spacer.Font = Enum.Font.Code
        spacer.Text = " "
        spacer.TextSize = 12
        spacer.Parent = lineContainer
    end
end

function CodeBlock:_parseLine(lineText, syntaxRules)
    local parts = {}
    local currentPos = 1
    
    -- Function to add a text part
    local function addPart(text, color)
        if text and text ~= "" then
            table.insert(parts, {
                text = text,
                color = color or Color3.fromRGB(220, 220, 225) -- Default text color
            })
        end
    end
    
    -- Check for patterns first
    for _, patternData in ipairs(syntaxRules.patterns or {}) do
        local startPos, endPos = lineText:find(patternData.pattern, currentPos)
        
        if startPos and startPos >= currentPos then
            -- Add text before pattern
            if startPos > currentPos then
                local beforeText = lineText:sub(currentPos, startPos - 1)
                addPart(beforeText)
            end
            
            -- Add pattern match
            local matchText = lineText:sub(startPos, endPos)
            addPart(matchText, patternData.color)
            
            currentPos = endPos + 1
        end
    end
    
    -- Add remaining text
    if currentPos <= #lineText then
        local remainingText = lineText:sub(currentPos)
        
        -- Check for keywords in remaining text
        self:_addKeywords(remainingText, syntaxRules, parts)
    end
    
    return parts
end

function CodeBlock:_addKeywords(text, syntaxRules, parts)
    local words = string.split(text, " ")
    
    for _, word in ipairs(words) do
        -- Clean word (remove punctuation)
        local cleanWord = word:gsub("[%p%s]", "")
        
        -- Check if it's a keyword
        local isKeyword = false
        for _, keyword in ipairs(syntaxRules.keywords or {}) do
            if cleanWord == keyword then
                addPart(word, Color3.fromRGB(220, 120, 120)) -- Keyword color
                isKeyword = true
                break
            end
        end
        
        -- Check if it's a built-in
        if not isKeyword then
            for _, builtin in ipairs(syntaxRules.builtins or {}) do
                if cleanWord == builtin then
                    addPart(word, Color3.fromRGB(120, 180, 220)) -- Built-in color
                    isKeyword = true
                    break
                end
            end
        end
        
        -- Regular text
        if not isKeyword then
            addPart(word)
        end
        
        -- Add spaces between words
        if _ < #words then
            addPart(" ")
        end
    end
end

function CodeBlock:SetCode(code, language)
    self.Code = code or ""
    
    if language then
        self.Language = language
        self.LanguageLabel.Text = language
    end
    
    self:_highlightSyntax()
end

function CodeBlock:GetCode()
    return self.Code
end

function CodeBlock:CopyToClipboard()
    if not self.Copyable then return end
    
    -- Set clipboard (this would need proper implementation for Roblox)
    local success = pcall(function()
        if setclipboard then
            setclipboard(self.Code)
            
            -- Visual feedback
            self.CopyButton.Text = "Copied!"
            self.CopyButton.TextColor3 = Color3.fromRGB(120, 220, 120)
            
            task.wait(1)
            
            self.CopyButton.Text = "Copy"
            self.CopyButton.TextColor3 = Color3.fromRGB(220, 220, 225)
        else
            -- Fallback: print to console
            print("Code (copy manually):")
            print(self.Code)
            
            self.CopyButton.Text = "Printed!"
            self.CopyButton.TextColor3 = Color3.fromRGB(220, 180, 120)
            
            task.wait(1)
            
            self.CopyButton.Text = "Copy"
            self.CopyButton.TextColor3 = Color3.fromRGB(220, 220, 225)
        end
    end)
    
    if not success then
        self.CopyButton.Text = "Failed"
        self.CopyButton.TextColor3 = Color3.fromRGB(220, 120, 120)
        
        task.wait(1)
        
        self.CopyButton.Text = "Copy"
        self.CopyButton.TextColor3 = Color3.fromRGB(220, 220, 225)
    end
end

function CodeBlock:SetLanguage(language)
    self.Language = language
    self.LanguageLabel.Text = language
    
    -- Re-highlight with new language
    self:_highlightSyntax()
end

function CodeBlock:SetLineNumbers(show)
    self.ShowLineNumbers = show
    
    if self.LineNumbers then
        self.LineNumbers.Visible = show
    end
    
    -- Adjust code container position
    if self.CodeContainer then
        self.CodeContainer.Position = show and UDim2.new(0, 45, 0, 0) or UDim2.new(0, 0, 0, 0)
        self.CodeContainer.Size = show and UDim2.new(1, -45, 0, 0) or UDim2.new(1, 0, 0, 0)
    end
end

function CodeBlock:SetCopyable(copyable)
    self.Copyable = copyable
    
    if self.CopyButton then
        self.CopyButton.Visible = copyable
    end
end

function CodeBlock:SetTheme(theme)
    -- Apply color theme to code block
    if theme == "Dark" then
        self.Container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        self.Header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    elseif theme == "Light" then
        self.Container.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        self.Header.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
    end
end

function CodeBlock:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

return CodeBlock