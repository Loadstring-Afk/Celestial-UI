-- Analytics system for tracking UI usage and performance

local Analytics = {}
Analytics.__index = Analytics

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

function Analytics.new(config)
    local self = setmetatable({}, Analytics)
    
    self.Config = config or {
        Enabled = false,
        TrackEvents = true,
        TrackPerformance = true,
        TrackErrors = true,
        Anonymous = true,
        FlushInterval = 60, -- seconds
        MaxQueueSize = 100,
        Endpoint = nil, -- Webhook for sending data
        Debug = false
    }
    
    self.Events = {}
    self.Metrics = {}
    self.ErrorLog = {}
    self.Queue = {}
    self.SessionId = HttpService:GenerateGUID(false)
    self.SessionStart = os.time()
    self.UserId = nil
    
    self.PerformanceStats = {
        FPS = {},
        Memory = {},
        Network = {}
    }
    
    self.FlushTimer = nil
    self.PerformanceTimer = nil
    
    if self.Config.Enabled then
        self:_initUser()
        self:_startFlushTimer()
        
        if self.Config.TrackPerformance then
            self:_startPerformanceTracking()
        end
    end
    
    return self
end

function Analytics:_initUser()
    if self.Config.Anonymous then
        -- Generate anonymous user ID
        self.UserId = "anonymous_" .. HttpService:GenerateGUID(false)
    else
        -- Try to get actual user ID
        local success, userId = pcall(function()
            return tostring(game:GetService("Players").LocalPlayer.UserId)
        end)
        
        if success then
            self.UserId = userId
        else
            self.UserId = "unknown"
        end
    end
end

function Analytics:_startFlushTimer()
    if self.FlushTimer then
        self.FlushTimer:Disconnect()
    end
    
    self.FlushTimer = RunService.Heartbeat:Connect(function()
        if #self.Queue >= self.Config.MaxQueueSize then
            self:Flush()
        end
    end)
    
    -- Periodic flush
    task.spawn(function()
        while self.Config.Enabled do
            task.wait(self.Config.FlushInterval)
            self:Flush()
        end
    end)
end

function Analytics:_startPerformanceTracking()
    if self.PerformanceTimer then
        self.PerformanceTimer:Disconnect()
    end
    
    self.PerformanceTimer = RunService.Heartbeat:Connect(function(deltaTime)
        self:_trackPerformance(deltaTime)
    end)
end

function Analytics:_trackPerformance(deltaTime)
    -- Track FPS
    local fps = 1 / deltaTime
    table.insert(self.PerformanceStats.FPS, fps)
    
    -- Keep only last 60 frames
    if #self.PerformanceStats.FPS > 60 then
        table.remove(self.PerformanceStats.FPS, 1)
    end
    
    -- Track memory
    local memory = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Texture)
    table.insert(self.PerformanceStats.Memory, {
        Time = os.time(),
        Texture = memory,
        Total = Stats:GetTotalMemoryUsageMb()
    })
    
    -- Keep only last 60 samples
    if #self.PerformanceStats.Memory > 60 then
        table.remove(self.PerformanceStats.Memory, 1)
    end
    
    -- Track network (simplified)
    if os.time() % 5 == 0 then -- Every 5 seconds
        table.insert(self.PerformanceStats.Network, {
            Time = os.time(),
            Sent = 0, -- Would need proper network tracking
            Received = 0
        })
        
        if #self.PerformanceStats.Network > 12 then -- Keep 1 minute of data
            table.remove(self.PerformanceStats.Network, 1)
        end
    end
end

function Analytics:_createEvent(name, category, data)
    local event = {
        Name = name,
        Category = category or "General",
        Data = data or {},
        Timestamp = os.time(),
        SessionId = self.SessionId,
        UserId = self.UserId,
        Version = "1.0.0" -- Celestial UI version
    }
    
    return event
end

function Analytics:TrackEvent(name, category, data)
    if not self.Config.Enabled or not self.Config.TrackEvents then return end
    
    local event = self:_createEvent(name, category, data)
    table.insert(self.Events, event)
    table.insert(self.Queue, event)
    
    if self.Config.Debug then
        print("[Analytics] Event tracked:", name, "Category:", category)
    end
    
    -- Auto-flush if queue is large
    if #self.Queue >= self.Config.MaxQueueSize then
        self:Flush()
    end
end

function Analytics:TrackMetric(name, value, tags)
    if not self.Config.Enabled then return end
    
    local metric = {
        Name = name,
        Value = value,
        Tags = tags or {},
        Timestamp = os.time(),
        SessionId = self.SessionId,
        UserId = self.UserId
    }
    
    table.insert(self.Metrics, metric)
    table.insert(self.Queue, metric)
    
    if self.Config.Debug then
        print("[Analytics] Metric tracked:", name, "Value:", value)
    end
end

function Analytics:TrackError(error, context)
    if not self.Config.Enabled or not self.Config.TrackErrors then return end
    
    local errorEntry = {
        Error = tostring(error),
        Context = context or {},
        Timestamp = os.time(),
        SessionId = self.SessionId,
        UserId = self.UserId,
        StackTrace = debug.traceback()
    }
    
    table.insert(self.ErrorLog, errorEntry)
    table.insert(self.Queue, errorEntry)
    
    if self.Config.Debug then
        warn("[Analytics] Error tracked:", error)
    end
end

function Analytics:TrackUIInteraction(component, action, data)
    self:TrackEvent("ui_interaction", "UI", {
        Component = component,
        Action = action,
        Data = data
    })
end

function Analytics:TrackWindowEvent(window, action)
    self:TrackEvent("window_" .. action:lower(), "Window", {
        WindowName = window.Config.Name,
        Action = action
    })
end

function Analytics:TrackComponentEvent(componentType, action, data)
    self:TrackEvent("component_" .. action:lower(), "Component", {
        Type = componentType,
        Action = action,
        Data = data
    })
end

function Analytics:GetPerformanceReport()
    if #self.PerformanceStats.FPS == 0 then
        return {
            AvgFPS = 0,
            MinFPS = 0,
            MaxFPS = 0,
            AvgMemory = 0,
            PeakMemory = 0
        }
    end
    
    -- Calculate FPS statistics
    local totalFPS = 0
    local minFPS = math.huge
    local maxFPS = 0
    
    for _, fps in ipairs(self.PerformanceStats.FPS) do
        totalFPS = totalFPS + fps
        minFPS = math.min(minFPS, fps)
        maxFPS = math.max(maxFPS, fps)
    end
    
    local avgFPS = totalFPS / #self.PerformanceStats.FPS
    
    -- Calculate memory statistics
    local totalMemory = 0
    local peakMemory = 0
    
    for _, memory in ipairs(self.PerformanceStats.Memory) do
        totalMemory = totalMemory + memory.Total
        peakMemory = math.max(peakMemory, memory.Total)
    end
    
    local avgMemory = #self.PerformanceStats.Memory > 0 and totalMemory / #self.PerformanceStats.Memory or 0
    
    return {
        AvgFPS = math.floor(avgFPS * 10) / 10,
        MinFPS = math.floor(minFPS * 10) / 10,
        MaxFPS = math.floor(maxFPS * 10) / 10,
        AvgMemory = math.floor(avgMemory * 10) / 10,
        PeakMemory = math.floor(peakMemory * 10) / 10,
        SampleCount = #self.PerformanceStats.FPS,
        SessionDuration = os.time() - self.SessionStart
    }
end

function Analytics:GetEventSummary()
    local summary = {
        TotalEvents = #self.Events,
        EventsByCategory = {},
        EventsByHour = {},
        SessionDuration = os.time() - self.SessionStart
    }
    
    -- Count events by category
    for _, event in ipairs(self.Events) do
        summary.EventsByCategory[event.Category] = (summary.EventsByCategory[event.Category] or 0) + 1
        
        -- Group by hour
        local hour = os.date("%H", event.Timestamp)
        summary.EventsByHour[hour] = (summary.EventsByHour[hour] or 0) + 1
    end
    
    -- Calculate events per minute
    if summary.SessionDuration > 0 then
        summary.EventsPerMinute = #self.Events / (summary.SessionDuration / 60)
    else
        summary.EventsPerMinute = 0
    end
    
    return summary
}

function Analytics:GetErrorSummary()
    local summary = {
        TotalErrors = #self.ErrorLog,
        ErrorsByType = {},
        RecentErrors = {}
    }
    
    -- Count errors by type
    for _, error in ipairs(self.ErrorLog) do
        local errorType = error.Error:match("^[^:]+") or "Unknown"
        summary.ErrorsByType[errorType] = (summary.ErrorsByType[errorType] or 0) + 1
    end
    
    -- Get recent errors (last 10)
    for i = math.max(1, #self.ErrorLog - 9), #self.ErrorLog do
        table.insert(summary.RecentErrors, {
            Error = self.ErrorLog[i].Error,
            Time = os.date("%H:%M:%S", self.ErrorLog[i].Timestamp),
            Context = self.ErrorLog[i].Context
        })
    end
    
    return summary
end

function Analytics:Flush()
    if not self.Config.Enabled or #self.Queue == 0 then return end
    
    local batch = table.clone(self.Queue)
    self.Queue = {}
    
    -- Send to endpoint if configured
    if self.Config.Endpoint then
        self:_sendToEndpoint(batch)
    end
    
    -- Store locally (for debugging)
    if self.Config.Debug then
        self:_storeLocally(batch)
    end
    
    if self.Config.Debug then
        print("[Analytics] Flushed", #batch, "events")
    end
end

function Analytics:_sendToEndpoint(batch)
    if not self.Config.Endpoint then return end
    
    local success, result = pcall(function()
        if request then
            local payload = {
                Batch = batch,
                SessionId = self.SessionId,
                UserId = self.UserId,
                Timestamp = os.time(),
                Source = "CelestialUI"
            }
            
            local response = request({
                Url = self.Config.Endpoint,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
            
            return response.Success
        end
        return false
    end)
    
    if not success and self.Config.Debug then
        warn("[Analytics] Failed to send to endpoint:", result)
    end
end

function Analytics:_storeLocally(batch)
    local success, result = pcall(function()
        if writefile then
            local folder = "CelestialUI_Analytics"
            if not isfolder(folder) then
                makefolder(folder)
            end
            
            local filename = folder .. "/session_" .. self.SessionId .. ".json"
            local data = HttpService:JSONEncode({
                SessionId = self.SessionId,
                UserId = self.UserId,
                StartTime = self.SessionStart,
                EndTime = os.time(),
                Events = batch
            })
            
            writefile(filename, data)
            return true
        end
        return false
    end)
    
    if not success and self.Config.Debug then
        warn("[Analytics] Failed to store locally:", result)
    end
end

function Analytics:Enable(enabled)
    self.Config.Enabled = enabled
    
    if enabled then
        self:_startFlushTimer()
        
        if self.Config.TrackPerformance then
            self:_startPerformanceTracking()
        end
    else
        if self.FlushTimer then
            self.FlushTimer:Disconnect()
            self.FlushTimer = nil
        end
        
        if self.PerformanceTimer then
            self.PerformanceTimer:Disconnect()
            self.PerformanceTimer = nil
        end
    end
end

function Analytics:SetEndpoint(endpoint)
    self.Config.Endpoint = endpoint
end

function Analytics:SetAnonymous(anonymous)
    self.Config.Anonymous = anonymous
    self:_initUser()
end

function Analytics:GetSessionId()
    return self.SessionId
end

function Analytics:GetUserId()
    return self.UserId
end

function Analytics:ClearData()
    self.Events = {}
    self.Metrics = {}
    self.ErrorLog = {}
    self.Queue = {}
    self.PerformanceStats = {
        FPS = {},
        Memory = {},
        Network = {}
    }
    
    if self.Config.Debug then
        print("[Analytics] Data cleared")
    end
end

function Analytics:ExportData()
    local data = {
        SessionId = self.SessionId,
        UserId = self.UserId,
        SessionStart = self.SessionStart,
        SessionEnd = os.time(),
        Events = self.Events,
        Metrics = self.Metrics,
        ErrorLog = self.ErrorLog,
        PerformanceStats = self.PerformanceStats,
        Config = self.Config
    }
    
    return HttpService:JSONEncode(data)
end

function Analytics:ImportData(jsonData)
    local success, data = pcall(function()
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success and data then
        self.SessionId = data.SessionId or self.SessionId
        self.UserId = data.UserId or self.UserId
        self.SessionStart = data.SessionStart or self.SessionStart
        self.Events = data.Events or self.Events
        self.Metrics = data.Metrics or self.Metrics
        self.ErrorLog = data.ErrorLog or self.ErrorLog
        self.PerformanceStats = data.PerformanceStats or self.PerformanceStats
        
        if self.Config.Debug then
            print("[Analytics] Data imported successfully")
        end
        
        return true
    else
        if self.Config.Debug then
            warn("[Analytics] Failed to import data")
        end
        return false
    end
end

function Analytics:Destroy()
    -- Flush remaining data
    self:Flush()
    
    -- Disconnect timers
    if self.FlushTimer then
        self.FlushTimer:Disconnect()
        self.FlushTimer = nil
    end
    
    if self.PerformanceTimer then
        self.PerformanceTimer:Disconnect()
        self.PerformanceTimer = nil
    end
    
    -- Clear data
    self:ClearData()
end

return Analytics