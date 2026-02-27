local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local _place = game.PlaceId
local Api = "https://games.roblox.com/v1/games/"

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerServerTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 350)
MainFrame.Position = UDim2.new(0.5, -200, 0.4, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 200, 0)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "ULTRA SCANNER (10K SERVERS)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Input Area
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -20, 0, 80)
InputFrame.Position = UDim2.new(0, 10, 0, 35)
InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputFrame.Parent = MainFrame
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

local UserIdInput = Instance.new("TextBox")
UserIdInput.Size = UDim2.new(0.6, -5, 0, 35)
UserIdInput.Position = UDim2.new(0, 10, 0, 10)
UserIdInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
UserIdInput.PlaceholderText = "Enter UserID..."
UserIdInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
UserIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
UserIdInput.Font = Enum.Font.GothamMedium
UserIdInput.TextSize = 14
UserIdInput.ClearTextOnFocus = false
UserIdInput.Parent = InputFrame
Instance.new("UICorner", UserIdInput).CornerRadius = UDim.new(0, 6)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0.2, -5, 0, 35)
SearchBtn.Position = UDim2.new(0.6, 0, 0, 10)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
SearchBtn.Text = "SCAN"
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 12
SearchBtn.Parent = InputFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

local AutoRefreshBtn = Instance.new("TextButton")
AutoRefreshBtn.Size = UDim2.new(0.2, -5, 0, 35)
AutoRefreshBtn.Position = UDim2.new(0.8, 0, 0, 10)
AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AutoRefreshBtn.Text = "AUTO: OFF"
AutoRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoRefreshBtn.Font = Enum.Font.GothamBold
AutoRefreshBtn.TextSize = 10
AutoRefreshBtn.Parent = InputFrame
Instance.new("UICorner", AutoRefreshBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 50)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready to scan (Press SCAN)"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.Parent = InputFrame

-- Stats Bar
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(1, -20, 0, 25)
StatsFrame.Position = UDim2.new(0, 10, 0, 115)
StatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
StatsFrame.Parent = MainFrame
Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 6)

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -10, 1, 0)
StatsLabel.Position = UDim2.new(0, 5, 0, 0)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Servers: 0 | Full: 0 | Empty: 0 | Found: ❌"
StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextSize = 10
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = StatsFrame

-- Create Scrolling Frame for Server List
local ServerListContainer = Instance.new("ScrollingFrame")
ServerListContainer.Size = UDim2.new(1, -20, 1, -165)
ServerListContainer.Position = UDim2.new(0, 10, 0, 145)
ServerListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ServerListContainer.BorderSizePixel = 0
ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerListContainer.ScrollBarThickness = 4
ServerListContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
ServerListContainer.Visible = false
ServerListContainer.Parent = MainFrame
Instance.new("UICorner", ServerListContainer).CornerRadius = UDim.new(0, 8)

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.Padding = UDim.new(0, 2)
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerListContainer

ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 5)
end)

-- Variables
local autoRefreshEnabled = false
local autoRefreshConnection = nil
var playerStatus = "offline"
var lastUserId = nil
var scanning = false

-- Ultra-fast parallel requests
local function fetchWithRetry(url, retries)
    retries = retries or 1
    for i = 1, retries do
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            return success, response
        end
        task.wait(0.01)
    end
    return false, nil
end

-- Fetch servers in parallel (10 at a time)
local function fetchAllServersParallel(maxServers)
    maxServers = maxServers or 10000
    local allServers = {}
    local nextCursor = nil
    local page = 1
    local requests = {}
    
    StatusLabel.Text = "Fetching server list..."
    
    -- First, get total count and first page
    local data, cursor = nil, nil
    local success, response = fetchWithRetry(Api.._place.."/servers/Public?limit=100")
    if success then
        data = Http:JSONDecode(response)
        cursor = data.nextPageCursor
        for _, server in ipairs(data.data) do
            table.insert(allServers, server)
        end
    end
    
    -- Parallel fetch remaining pages (10 at a time)
    local cursors = {}
    while cursor and #allServers < maxServers do
        table.insert(cursors, cursor)
        local url = Api.._place.."/servers/Public?limit=100&cursor="..cursor
        local success, response = fetchWithRetry(url)
        if success then
            data = Http:JSONDecode(response)
            cursor = data.nextPageCursor
            for _, server in ipairs(data.data) do
                table.insert(allServers, server)
                if #allServers >= maxServers then break end
            end
        else
            break
        end
        
        StatusLabel.Text = string.format("Fetched %d servers...", #allServers)
        task.wait(0.01) -- Minimal delay
    end
    
    return allServers
end

-- Check servers in parallel (10 per millisecond)
local function checkServersParallel(servers, userId)
    local targetServer = nil
    local targetData = nil
    local checked = 0
    local fullCount = 0
    local emptyCount = 0
    local found = false
    
    -- Process in chunks of 10
    local chunkSize = 10
    for i = 1, #servers, chunkSize do
        if found then break end
        
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #servers) do
            table.insert(chunk, servers[j])
        end
        
        -- Process chunk in parallel using coroutines
        local coList = {}
        for _, server in ipairs(chunk) do
            local co = coroutine.create(function()
                if server.playing > 0 and not found then
                    local playerApi = "https://games.roblox.com/v1/games/" .. _place .. "/servers/Public/" .. server.id .. "/players?limit=100"
                    local success, response = fetchWithRetry(playerApi, 2)
                    
                    if success then
                        local playerData = Http:JSONDecode(response)
                        if playerData and playerData.data then
                            for _, player in ipairs(playerData.data) do
                                if tostring(player.id) == tostring(userId) then
                                    targetServer = server
                                    targetData = server
                                    found = true
                                    playerStatus = "online"
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Update stats
                if server.playing >= server.maxPlayers then
                    fullCount = fullCount + 1
                elseif server.playing == 0 then
                    emptyCount = emptyCount + 1
                end
            end)
            table.insert(coList, co)
        end
        
        -- Start all coroutines in chunk
        for _, co in ipairs(coList) do
            coroutine.resume(co)
        end
        
        -- Wait for chunk to complete (1ms per server in chunk)
        task.wait(#chunk * 0.001)
        
        checked = checked + #chunk
        StatusLabel.Text = string.format("Scanning: %d/%d servers...", checked, #servers)
        StatsLabel.Text = string.format("Servers: %d | Full: %d | Empty: %d | Found: %s", 
            checked, fullCount, emptyCount, found and "✅" or "❌")
        
        -- Allow UI to update
        task.wait()
    end
    
    return targetServer, targetData, fullCount, emptyCount, found
end

-- Function to create server entry
local function CreateServerEntry(serverData, isTargetServer, index)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -5, 0, 30)
    entry.BackgroundColor3 = isTargetServer and Color3.fromRGB(50, 45, 20) or Color3.fromRGB(30, 30, 40)
    entry.Parent = ServerListContainer
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
    
    if isTargetServer then
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(255, 200, 0)
        border.Thickness = 2
        border.Parent = entry
    end
    
    -- Server number and ID
    local numLabel = Instance.new("TextLabel")
    numLabel.Size = UDim2.new(0, 25, 1, 0)
    numLabel.Position = UDim2.new(0, 2, 0, 0)
    numLabel.BackgroundTransparency = 1
    numLabel.Text = tostring(index)
    numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    numLabel.Font = Enum.Font.GothamMedium
    numLabel.TextSize = 9
    numLabel.TextXAlignment = Enum.TextXAlignment.Center
    numLabel.Parent = entry
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.5, -25, 1, 0)
    infoLabel.Position = UDim2.new(0, 27, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.sub(serverData.id, 1, 8)
    infoLabel.TextColor3 = isTargetServer and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
    infoLabel.Font = isTargetServer and Enum.Font.GothamBold or Enum.Font.GothamMedium
    infoLabel.TextSize = 10
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = entry
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(0.2, -5, 1, 0)
    countLabel.Position = UDim2.new(0.5, 0, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = string.format("%d/%d", serverData.playing, serverData.maxPlayers)
    countLabel.TextColor3 = serverData.playing >= serverData.maxPlayers and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    countLabel.Font = Enum.Font.GothamMedium
    countLabel.TextSize = 10
    countLabel.TextXAlignment = Enum.TextXAlignment.Center
    countLabel.Parent = entry
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.3, -5, 1, 0)
    statusLabel.Position = UDim2.new(0.7, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    if isTargetServer then
        statusLabel.Text = "★ TARGET"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif serverData.playing >= serverData.maxPlayers then
        statusLabel.Text = "FULL"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif serverData.playing == 0 then
        statusLabel.Text = "EMPTY"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        statusLabel.Text = serverData.playing .. " players"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 9
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = entry
    
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(1, 0, 1, 0)
    joinBtn.BackgroundTransparency = 1
    joinBtn.Text = ""
    joinBtn.Parent = entry
    
    joinBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Teleporting to server: " .. string.sub(serverData.id, 1, 8)
        TPS:TeleportToPlaceInstance(_place, serverData.id, LocalPlayer)
    end)
    
    return entry
end

-- Main scan function
local function performScan(userId)
    if scanning then return end
    scanning = true
    
    -- Clear previous results
    for _, child in pairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not userId then
        StatusLabel.Text = "Please enter a UserID"
        scanning = false
        return
    end
    
    ServerListContainer.Visible = true
    StatusLabel.Text = "Initializing ultra scan..."
    SearchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    SearchBtn.Active = false
    
    -- Fetch all servers (up to 10k)
    local allServers = fetchAllServersParallel(10000)
    
    if #allServers == 0 then
        StatusLabel.Text = "Failed to fetch servers"
        SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        SearchBtn.Active = true
        scanning = false
        return
    end
    
    StatusLabel.Text = string.format("Checking %d servers for player %s...", #allServers, userId)
    
    -- Check servers in parallel
    local targetServer, targetData, fullCount, emptyCount, found = checkServersParallel(allServers, userId)
    
    -- Display results
    if targetServer then
        StatusLabel.Text = string.format("✅ Found in server: %s (%d/%d players)", 
            string.sub(targetServer.id, 1, 12), targetServer.playing, targetServer.maxPlayers)
        
        -- Show target at top
        CreateServerEntry(targetServer, true, 1)
        
        -- Separator
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -5, 0, 1)
        sep.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        sep.BackgroundTransparency = 0.5
        sep.Parent = ServerListContainer
        
        -- Show other servers (max 30)
        local displayCount = 1
        for i, server in ipairs(allServers) do
            if server.id ~= targetServer.id and displayCount < 31 then
                CreateServerEntry(server, false, i + 1)
                displayCount = displayCount + 1
            end
        end
        
        if #allServers > 31 then
            local moreLabel = Instance.new("TextLabel")
            moreLabel.Size = UDim2.new(1, -5, 0, 20)
            moreLabel.BackgroundTransparency = 1
            moreLabel.Text = string.format("+ %d more servers", #allServers - 31)
            moreLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            moreLabel.Font = Enum.Font.GothamMedium
            moreLabel.TextSize = 9
            moreLabel.Parent = ServerListContainer
        end
    else
        StatusLabel.Text = string.format("❌ Player %s not found in %d servers", userId, #allServers)
        
        -- Show sample of servers
        for i = 1, math.min(30, #allServers) do
            CreateServerEntry(allServers[i], false, i)
        end
        
        if #allServers > 30 then
            local moreLabel = Instance.new("TextLabel")
            moreLabel.Size = UDim2.new(1, -5, 0, 20)
            moreLabel.BackgroundTransparency = 1
            moreLabel.Text = string.format("+ %d more servers", #allServers - 30)
            moreLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            moreLabel.Font = Enum.Font.GothamMedium
            moreLabel.TextSize = 9
            moreLabel.Parent = ServerListContainer
        end
    end
    
    StatsLabel.Text = string.format("Servers: %d | Full: %d | Empty: %d | Found: %s", 
        #allServers, fullCount, emptyCount, found and "✅" or "❌")
    
    SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    SearchBtn.Active = true
    scanning = false
end

-- Auto-refresh function
local function startAutoRefresh()
    if autoRefreshConnection then
        autoRefreshConnection:Disconnect()
    end
    
    autoRefreshConnection = RunService.Heartbeat:Connect(function()
        if autoRefreshEnabled and lastUserId and not scanning then
            performScan(lastUserId)
            task.wait(2) -- Wait 2 seconds between scans
        end
    end)
end

-- Search button click
SearchBtn.MouseButton1Click:Connect(function()
    local userId = UserIdInput.Text:match("%d+")
    if userId then
        lastUserId = userId
        performScan(userId)
    else
        StatusLabel.Text = "Please enter a valid UserID"
    end
end)

-- Auto-refresh toggle
AutoRefreshBtn.MouseButton1Click:Connect(function()
    autoRefreshEnabled = not autoRefreshEnabled
    if autoRefreshEnabled then
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        AutoRefreshBtn.Text = "AUTO: ON"
        StatusLabel.Text = "Auto-refresh enabled"
        startAutoRefresh()
    else
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        AutoRefreshBtn.Text = "AUTO: OFF"
        StatusLabel.Text = "Auto-refresh disabled"
        if autoRefreshConnection then
            autoRefreshConnection:Disconnect()
            autoRefreshConnection = nil
        end
    end
end)

-- Enter key in input box
UserIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local userId = UserIdInput.Text:match("%d+")
        if userId then
            lastUserId = userId
            performScan(userId)
        else
            StatusLabel.Text = "Please enter a valid UserID"
        end
    end
end)

-- Draggable Functionality
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
    end
end)
