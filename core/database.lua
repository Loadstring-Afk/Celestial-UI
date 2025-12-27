-- Local database system with JSON-like serialization

local Database = {}
Database.__index = Database

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Check if we're in a compatible environment
local IS_STUDIO = RunService:IsStudio()
local CAN_USE_HTTP = pcall(function() return HttpService.JSONEncode end) ~= nil

function Database.new(config)
    local self = setmetatable({}, Database)
    
    self.Config = config or {
        Enabled = false,
        AutoSave = true,
        SaveInterval = 30,
        Encryption = false,
        WipeOnVersionMismatch = true
    }
    
    self.Data = {}
    self.Cache = {}
    self.SaveQueue = {}
    self.IsSaving = false
    self.LastSaveTime = 0
    self.Version = "1.0.0"
    
    -- Setup auto-save if enabled
    if self.Config.Enabled and self.Config.AutoSave then
        self:_setupAutoSave()
    end
    
    -- Try to load existing data
    if self.Config.Enabled then
        self:Load()
    end
    
    return self
end

function Database:_setupAutoSave()
    if not self.Config.Enabled then return end
    
    -- Auto-save on game close (if possible)
    game:BindToClose(function()
        if self.Config.Enabled then
            self:Save(true)
        end
    end)
    
    -- Periodic auto-save
    task.spawn(function()
        while self.Config.Enabled and self.Config.AutoSave do
            task.wait(self.Config.SaveInterval)
            
            if tick() - self.LastSaveTime >= self.Config.SaveInterval then
                self:Save()
            end
        end
    end)
end

function Database:Set(key, value, immediateSave)
    if not self.Config.Enabled then return false end
    
    -- Store in memory
    self.Data[key] = value
    
    -- Queue for saving
    if not self.SaveQueue[key] then
        self.SaveQueue[key] = true
    end
    
    -- Save immediately if requested
    if immediateSave then
        self:Save()
    end
    
    return true
end

function Database:Get(key, defaultValue)
    if not self.Config.Enabled then return defaultValue end
    
    -- Check memory first
    if self.Data[key] ~= nil then
        return self.Data[key]
    end
    
    -- Check cache (for computed values)
    if self.Cache[key] ~= nil then
        return self.Cache[key]
    end
    
    return defaultValue
end

function Database:Delete(key)
    if not self.Config.Enabled then return false end
    
    self.Data[key] = nil
    self.Cache[key] = nil
    self.SaveQueue[key] = true
    
    return true
end

function Database:Exists(key)
    if not self.Config.Enabled then return false end
    
    return self.Data[key] ~= nil
end

function Database:GetAll()
    if not self.Config.Enabled then return {} end
    
    return self.Data
end

function Database:Clear()
    if not self.Config.Enabled then return false end
    
    self.Data = {}
    self.Cache = {}
    self.SaveQueue = {}
    
    return true
end

function Database:Save(force)
    if not self.Config.Enabled or self.IsSaving then return false end
    
    -- Check if we need to save
    if not force and next(self.SaveQueue) == nil then
        return false
    end
    
    self.IsSaving = true
    
    -- Try to save to different locations based on environment
    local success = false
    
    if IS_STUDIO then
        -- Studio: Save to test file
        success = self:_saveToFile("CelestialDB_Test.json")
    elseif CAN_USE_HTTP and not IS_STUDIO then
        -- Game with HttpService: Try multiple methods
        success = self:_saveToDataStore() or 
                  self:_saveToFile("CelestialDB.json") or 
                  self:_saveToCache()
    else
        -- Limited environment: Use memory only
        success = true
    end
    
    if success then
        self.LastSaveTime = tick()
        self.SaveQueue = {}
        
        if self.Config.Debug then
            print("[Database] Saved successfully")
        end
    else
        warn("[Database] Failed to save data")
    end
    
    self.IsSaving = false
    return success
end

function Database:Load()
    if not self.Config.Enabled then return false end
    
    local loadedData = nil
    
    -- Try different loading methods
    if IS_STUDIO then
        loadedData = self:_loadFromFile("CelestialDB_Test.json")
    elseif CAN_USE_HTTP and not IS_STUDIO then
        loadedData = self:_loadFromDataStore() or 
                     self:_loadFromFile("CelestialDB.json") or 
                     self:_loadFromCache()
    end
    
    if loadedData then
        -- Version check
        if self.Config.WipeOnVersionMismatch and loadedData._version ~= self.Version then
            warn("[Database] Version mismatch, clearing old data")
            self:Clear()
        else
            -- Merge loaded data
            for key, value in pairs(loadedData) do
                if key ~= "_version" and key ~= "_metadata" then
                    self.Data[key] = value
                end
            end
            
            if self.Config.Debug then
                print("[Database] Loaded", #self.Data, "entries")
            end
        end
    end
    
    return loadedData ~= nil
end

function Database:_saveToDataStore()
    -- Attempt to save using DataStoreService
    local success, result = pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local dataStore = DataStoreService:GetDataStore("CelestialUI_Data")
        
        -- Prepare data with metadata
        local saveData = {
            _version = self.Version,
            _metadata = {
                saveTime = os.time(),
                entryCount = #self.Data
            },
            _data = self.Data
        }
        
        -- Encrypt if enabled
        if self.Config.Encryption then
            saveData = self:_encryptData(saveData)
        end
        
        -- Serialize
        local serialized = HttpService:JSONEncode(saveData)
        
        -- Save (using Player.UserId as key in actual implementation)
        local key = "GlobalConfig" -- This would be player-specific in real use
        dataStore:SetAsync(key, serialized)
        
        return true
    end)
    
    return success
end

function Database:_loadFromDataStore()
    local success, result = pcall(function()
        local DataStoreService = game:GetService("DataStoreService")
        local dataStore = DataStoreService:GetDataStore("CelestialUI_Data")
        
        local key = "GlobalConfig"
        local serialized = dataStore:GetAsync(key)
        
        if serialized then
            local loaded = HttpService:JSONDecode(serialized)
            
            -- Decrypt if needed
            if self.Config.Encryption then
                loaded = self:_decryptData(loaded)
            end
            
            -- Extract data
            if loaded._data then
                return loaded
            end
        end
    end)
    
    return success and result or nil
end

function Database:_saveToFile(filename)
    -- Save to a file (works in some exploit environments)
    local success, result = pcall(function()
        if not writefile then return false end
        
        local saveData = {
            _version = self.Version,
            _metadata = {
                saveTime = os.time(),
                entryCount = #self.Data
            },
            _data = self.Data
        }
        
        if self.Config.Encryption then
            saveData = self:_encryptData(saveData)
        end
        
        local serialized = HttpService:JSONEncode(saveData)
        
        -- Ensure directory exists
        local path = self.Config.FolderName or "CelestialUI"
        if not isfolder(path) then
            makefolder(path)
        end
        
        writefile(path .. "/" .. filename, serialized)
        return true
    end)
    
    return success
end

function Database:_loadFromFile(filename)
    local success, result = pcall(function()
        if not readfile then return nil end
        
        local path = self.Config.FolderName or "CelestialUI"
        local filePath = path .. "/" .. filename
        
        if not isfile(filePath) then return nil end
        
        local serialized = readfile(filePath)
        local loaded = HttpService:JSONDecode(serialized)
        
        if self.Config.Encryption then
            loaded = self:_decryptData(loaded)
        end
        
        return loaded
    end)
    
    return success and result or nil
end

function Database:_saveToCache()
    -- Memory-only cache for environments without file access
    self.Cache = table.clone(self.Data)
    return true
end

function Database:_loadFromCache()
    return {_data = self.Cache, _version = self.Version}
end

function Database:_encryptData(data)
    if not self.Config.Encryption then return data end
    
    -- Simple XOR encryption for demonstration
    -- In production, use proper encryption
    local key = "CelestialSecretKey"
    local serialized = HttpService:JSONEncode(data)
    
    local encrypted = ""
    for i = 1, #serialized do
        local charCode = string.byte(serialized, i)
        local keyChar = string.byte(key, (i - 1) % #key + 1)
        encrypted = encrypted .. string.char(bit32.bxor(charCode, keyChar))
    end
    
    return {encrypted = encrypted, iv = "demo"} -- Add proper IV in production
end

function Database:_decryptData(data)
    if not self.Config.Encryption or not data.encrypted then return data end
    
    local key = "CelestialSecretKey"
    local encrypted = data.encrypted
    
    local decrypted = ""
    for i = 1, #encrypted do
        local charCode = string.byte(encrypted, i)
        local keyChar = string.byte(key, (i - 1) % #key + 1)
        decrypted = decrypted .. string.char(bit32.bxor(charCode, keyChar))
    end
    
    return HttpService:JSONDecode(decrypted)
end

function Database:Query(pattern)
    if not self.Config.Enabled then return {} end
    
    local results = {}
    
    for key, value in pairs(self.Data) do
        if string.find(key, pattern) then
            results[key] = value
        end
    end
    
    return results
end

function Database:Increment(key, amount)
    if not self.Config.Enabled then return nil end
    
    amount = amount or 1
    local current = self:Get(key, 0)
    
    if type(current) == "number" then
        local newValue = current + amount
        self:Set(key, newValue)
        return newValue
    end
    
    return nil
end

function Database:Toggle(key)
    if not self.Config.Enabled then return nil end
    
    local current = self:Get(key, false)
    local newValue = not current
    
    self:Set(key, newValue)
    return newValue
end

function Database:GetSize()
    if not self.Config.Enabled then return 0 end
    
    local count = 0
    for _ in pairs(self.Data) do
        count = count + 1
    end
    
    return count
end

function Database:Backup()
    if not self.Config.Enabled then return false end
    
    local backup = table.clone(self.Data)
    local timestamp = os.time()
    
    self:Set("_backup_" .. timestamp, backup, true)
    
    return true
end

function Database:Restore(timestamp)
    if not self.Config.Enabled then return false end
    
    local backup = self:Get("_backup_" .. timestamp)
    
    if backup then
        self.Data = table.clone(backup)
        self.SaveQueue = {}
        
        for key in pairs(self.Data) do
            self.SaveQueue[key] = true
        end
        
        self:Save(true)
        return true
    end
    
    return false
end

function Database:Destroy()
    -- Save before destroying
    if self.Config.Enabled then
        self:Save(true)
    end
    
    self.Data = nil
    self.Cache = nil
    self.SaveQueue = nil
end

return Database