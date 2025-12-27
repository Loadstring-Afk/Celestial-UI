-- URL image loader with caching system

local UrlImages = {}
UrlImages.__index = UrlImages

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

function UrlImages.new(config)
    local self = setmetatable({}, UrlImages)
    
    self.Config = config or {
        Enabled = true,
        CacheEnabled = true,
        MaxCacheSize = 50, -- MB
        CacheDuration = 86400, -- 24 hours in seconds
        PreloadQueueSize = 5,
        RetryAttempts = 3,
        RetryDelay = 2,
        DefaultImage = "rbxassetid://7072716648", -- Default icon
        Debug = false
    }
    
    self.Cache = {}
    self.Queue = {}
    self.Loading = {}
    self.TotalCacheSize = 0
    
    self:_setupCacheCleanup()
    
    return self
end

function UrlImages:_setupCacheCleanup()
    -- Cleanup old cache entries periodically
    task.spawn(function()
        while self.Config.Enabled do
            task.wait(300) -- Check every 5 minutes
            
            self:_cleanupCache()
        end
    end)
end

function UrlImages:_cleanupCache()
    local currentTime = os.time()
    local removedCount = 0
    local removedSize = 0
    
    for url, cacheEntry in pairs(self.Cache) do
        -- Check if cache entry is expired
        if currentTime - cacheEntry.Timestamp > self.Config.CacheDuration then
            removedSize = removedSize + cacheEntry.Size
            self.Cache[url] = nil
            removedCount = removedCount + 1
            
            if self.Config.Debug then
                print("[UrlImages] Removed expired cache entry:", url)
            end
        end
    end
    
    -- Remove oldest entries if cache is too large
    if self.TotalCacheSize > self.Config.MaxCacheSize * 1024 * 1024 then -- Convert MB to bytes
        -- Sort cache by timestamp
        local sortedCache = {}
        for url, cacheEntry in pairs(self.Cache) do
            table.insert(sortedCache, {
                Url = url,
                Timestamp = cacheEntry.Timestamp,
                Size = cacheEntry.Size
            })
        end
        
        table.sort(sortedCache, function(a, b)
            return a.Timestamp < b.Timestamp
        end)
        
        -- Remove oldest entries until under limit
        for _, entry in ipairs(sortedCache) do
            if self.TotalCacheSize <= self.Config.MaxCacheSize * 1024 * 1024 then
                break
            end
            
            self.Cache[entry.Url] = nil
            self.TotalCacheSize = self.TotalCacheSize - entry.Size
            removedCount = removedCount + 1
            removedSize = removedSize + entry.Size
            
            if self.Config.Debug then
                print("[UrlImages] Removed old cache entry to free space:", entry.Url)
            end
        end
    end
    
    if self.Config.Debug and removedCount > 0 then
        print(string.format("[UrlImages] Cache cleanup: removed %d entries, freed %.2f MB", 
            removedCount, removedSize / (1024 * 1024)))
    end
end

function UrlImages:_getCacheKey(url)
    -- Generate a cache key from URL
    return HttpService:GenerateGUID(false) .. "_" .. url:gsub("[^%w]", "_")
end

function UrlImages:_saveToCache(url, imageData)
    if not self.Config.CacheEnabled then return end
    
    local cacheKey = self:_getCacheKey(url)
    local size = #imageData
    
    self.Cache[url] = {
        Data = imageData,
        Timestamp = os.time(),
        Size = size,
        Key = cacheKey
    }
    
    self.TotalCacheSize = self.TotalCacheSize + size
    
    if self.Config.Debug then
        print(string.format("[UrlImages] Cached image: %s (%.2f KB)", url, size / 1024))
    end
end

function UrlImages:_loadFromCache(url)
    if not self.Config.CacheEnabled then return nil end
    
    local cacheEntry = self.Cache[url]
    
    if cacheEntry then
        -- Check if cache is still valid
        if os.time() - cacheEntry.Timestamp > self.Config.CacheDuration then
            -- Cache expired
            self.Cache[url] = nil
            self.TotalCacheSize = self.TotalCacheSize - cacheEntry.Size
            return nil
        end
        
        if self.Config.Debug then
            print("[UrlImages] Loaded from cache:", url)
        end
        
        return cacheEntry.Data
    end
    
    return nil
end

function UrlImages:_loadImage(url, callback)
    if self.Loading[url] then
        -- Image is already being loaded, add to callback queue
        table.insert(self.Loading[url].Callbacks, callback)
        return
    end
    
    -- Check cache first
    local cachedData = self:_loadFromCache(url)
    if cachedData then
        callback(cachedData, true) -- true = from cache
        return
    end
    
    -- Mark as loading
    self.Loading[url] = {
        Callbacks = {callback},
        Attempts = 0
    }
    
    -- Start loading
    task.spawn(function()
        local success, imageData = self:_tryLoadImage(url)
        
        if success and imageData then
            -- Save to cache
            self:_saveToCache(url, imageData)
            
            -- Call all waiting callbacks
            for _, cb in ipairs(self.Loading[url].Callbacks) do
                task.spawn(cb, imageData, false) -- false = not from cache
            end
        else
            -- Loading failed, use default image
            local defaultData = nil
            if self.Config.DefaultImage then
                defaultData = self:_tryLoadDefaultImage()
            end
            
            for _, cb in ipairs(self.Loading[url].Callbacks) do
                task.spawn(cb, defaultData, false)
            end
        end
        
        -- Clean up
        self.Loading[url] = nil
    end)
end

function UrlImages:_tryLoadImage(url)
    for attempt = 1, self.Config.RetryAttempts do
        local success, result = pcall(function()
            if request then
                local response = request({
                    Url = url,
                    Method = "GET"
                })
                
                if response.Success then
                    return response.Body
                else
                    error("HTTP " .. response.StatusCode)
                end
            else
                error("Request function not available")
            end
        end)
        
        if success then
            if self.Config.Debug then
                print("[UrlImages] Successfully loaded:", url)
            end
            return true, result
        else
            if self.Config.Debug then
                warn("[UrlImages] Failed to load", url, "attempt", attempt, "error:", result)
            end
            
            if attempt < self.Config.RetryAttempts then
                task.wait(self.Config.RetryDelay * attempt) -- Exponential backoff
            end
        end
    end
    
    return false, nil
end

function UrlImages:_tryLoadDefaultImage()
    if not self.Config.DefaultImage then return nil end
    
    local success, result = pcall(function()
        if request then
            local response = request({
                Url = self.Config.DefaultImage,
                Method = "GET"
            })
            
            if response.Success then
                return response.Body
            end
        end
        return nil
    end)
    
    return success and result or nil
end

function UrlImages:_createImageLabel(parent, url, config)
    config = config or {}
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = config.Name or "UrlImage"
    imageLabel.BackgroundTransparency = 1
    imageLabel.Size = config.Size or UDim2.new(0, 100, 0, 100)
    imageLabel.Position = config.Position or UDim2.new(0, 0, 0, 0)
    imageLabel.ImageTransparency = 1
    imageLabel.Image = ""
    
    if config.AnchorPoint then
        imageLabel.AnchorPoint = config.AnchorPoint
    end
    
    if config.ZIndex then
        imageLabel.ZIndex = config.ZIndex
    end
    
    -- Set placeholder if provided
    if config.Placeholder then
        imageLabel.Image = config.Placeholder
        imageLabel.ImageTransparency = 0.5
    end
    
    imageLabel.Parent = parent
    
    -- Load image
    self:LoadImage(url, function(imageData, fromCache)
        if imageData then
            -- Create texture
            pcall(function()
                local texture = "rbxgameasset://Images/" .. HttpService:GenerateGUID(false)
                
                -- Save texture to a temporary location
                if writefile then
                    local tempPath = "CelestialUI_Temp/" .. HttpService:GenerateGUID(false) .. ".png"
                    if not isfolder("CelestialUI_Temp") then
                        makefolder("CelestialUI_Temp")
                    end
                    writefile(tempPath, imageData)
                    
                    -- Use the texture
                    imageLabel.Image = "rbxasset://" .. tempPath
                    
                    -- Clean up temp file after a delay
                    task.delay(60, function()
                        pcall(function()
                            delfile(tempPath)
                        end)
                    end)
                else
                    -- Fallback: try to use base64 (not supported in all environments)
                    imageLabel.Image = "rbxasset://" -- This would need proper implementation
                end
                
                -- Fade in
                if config.Animate then
                    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(imageLabel, tweenInfo, {
                        ImageTransparency = 0
                    })
                    tween:Play()
                else
                    imageLabel.ImageTransparency = 0
                end
            end)
        else
            -- Failed to load, use default
            if self.Config.DefaultImage then
                imageLabel.Image = self.Config.DefaultImage
                imageLabel.ImageTransparency = 0
            end
            
            if config.OnError then
                config.OnError()
            end
        end
        
        if config.OnLoaded then
            config.OnLoaded(fromCache)
        end
    end)
    
    return imageLabel
end

function UrlImages:LoadImage(url, callback)
    if not self.Config.Enabled then
        if callback then
            callback(nil, false)
        end
        return
    end
    
    if not url or url == "" then
        if callback then
            callback(nil, false)
        end
        return
    end
    
    -- Check if it's already a Roblox asset ID
    if url:match("^rbxassetid://") or url:match("^http://www%.roblox%.com/asset/%?id=") then
        -- It's already a Roblox asset, no need to load
        if callback then
            callback(url, true) -- Return the URL as-is
        end
        return
    end
    
    self:_loadImage(url, callback)
end

function UrlImages:CreateImageLabel(parent, url, config)
    return self:_createImageLabel(parent, url, config)
end

function UrlImages:PreloadImages(urls)
    if not self.Config.Enabled then return end
    
    for _, url in ipairs(urls) do
        if #self.Queue < self.Config.PreloadQueueSize then
            table.insert(self.Queue, url)
        end
    end
    
    -- Process queue
    task.spawn(function()
        while #self.Queue > 0 do
            local url = table.remove(self.Queue, 1)
            self:LoadImage(url, function() end) -- Load without callback
            task.wait(0.5) -- Delay between preloads
        end
    end)
end

function UrlImages:GetImageSize(url, callback)
    self:LoadImage(url, function(imageData)
        if not imageData then
            callback(nil)
            return
        end
        
        -- This would need proper image decoding to get dimensions
        -- For simplicity, we'll return a default size
        callback(Vector2.new(100, 100))
    end)
end

function UrlImages:ClearCache()
    self.Cache = {}
    self.TotalCacheSize = 0
    
    if self.Config.Debug then
        print("[UrlImages] Cache cleared")
    end
end

function UrlImages:RemoveFromCache(url)
    if self.Cache[url] then
        self.TotalCacheSize = self.TotalCacheSize - self.Cache[url].Size
        self.Cache[url] = nil
        
        if self.Config.Debug then
            print("[UrlImages] Removed from cache:", url)
        end
    end
end

function UrlImages:GetCacheInfo()
    local info = {
        TotalEntries = 0,
        TotalSizeMB = 0,
        OldestEntry = nil,
        NewestEntry = nil
    }
    
    for url, cacheEntry in pairs(self.Cache) do
        info.TotalEntries = info.TotalEntries + 1
        info.TotalSizeMB = info.TotalSizeMB + (cacheEntry.Size / (1024 * 1024))
        
        if not info.OldestEntry or cacheEntry.Timestamp < info.OldestEntry.Timestamp then
            info.OldestEntry = {
                Url = url,
                Timestamp = cacheEntry.Timestamp,
                AgeSeconds = os.time() - cacheEntry.Timestamp
            }
        end
        
        if not info.NewestEntry or cacheEntry.Timestamp > info.NewestEntry.Timestamp then
            info.NewestEntry = {
                Url = url,
                Timestamp = cacheEntry.Timestamp,
                AgeSeconds = os.time() - cacheEntry.Timestamp
            }
        end
    end
    
    return info
end

function UrlImages:SetDefaultImage(imageUrl)
    self.Config.DefaultImage = imageUrl
end

function UrlImages:EnableCache(enabled)
    self.Config.CacheEnabled = enabled
    
    if not enabled then
        self:ClearCache()
    end
end

function UrlImages:SetMaxCacheSize(mb)
    self.Config.MaxCacheSize = mb
    self:_cleanupCache()
end

function UrlImages:SetCacheDuration(seconds)
    self.Config.CacheDuration = seconds
    self:_cleanupCache()
end

function UrlImages:Destroy()
    self:ClearCache()
    self.Queue = {}
    self.Loading = {}
end

return UrlImages