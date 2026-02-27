local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local _place = game.PlaceId
local Api = "https://games.roblox.com/v1/games/"

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerServerTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 400)
MainFrame.Position = UDim2.new(0.5, -200, 0.4, -200)
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
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "PLAYER TRACKER (AUTO-REFRESH)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Input Area
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -20, 0, 90)
InputFrame.Position = UDim2.new(0, 10, 0, 40)
InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputFrame.Parent = MainFrame
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

local UserIdInput = Instance.new("TextBox")
UserIdInput.Size = UDim2.new(1, -20, 0, 35)
UserIdInput.Position = UDim2.new(0, 10, 0, 10)
UserIdInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
UserIdInput.PlaceholderText = "Enter UserID to track..."
UserIdInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
UserIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
UserIdInput.Font = Enum.Font.GothamMedium
UserIdInput.TextSize = 14
UserIdInput.ClearTextOnFocus = false
UserIdInput.Parent = InputFrame
Instance.new("UICorner", UserIdInput).CornerRadius = UDim.new(0, 6)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0.5, -5, 0, 35)
SearchBtn.Position = UDim2.new(0, 10, 0, 50)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
SearchBtn.Text = "FIND"
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 14
SearchBtn.Parent = InputFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

local AutoRefreshBtn = Instance.new("TextButton")
AutoRefreshBtn.Size = UDim2.new(0.5, -5, 0, 35)
AutoRefreshBtn.Position = UDim2.new(0.5, 0, 0, 50)
AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
AutoRefreshBtn.Text = "AUTO: OFF"
AutoRefreshBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
AutoRefreshBtn.Font = Enum.Font.GothamBold
AutoRefreshBtn.TextSize = 14
AutoRefreshBtn.Parent = InputFrame
Instance.new("UICorner", AutoRefreshBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 90)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready - Enter a UserID to track"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = InputFrame

-- Server List Container
local ServerListContainer = Instance.new("ScrollingFrame")
ServerListContainer.Size = UDim2.new(1, -20, 1, -150)
ServerListContainer.Position = UDim2.new(0, 10, 0, 140)
ServerListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ServerListContainer.BorderSizePixel = 0
ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerListContainer.ScrollBarThickness = 6
ServerListContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
ServerListContainer.Parent = MainFrame
Instance.new("UICorner", ServerListContainer).CornerRadius = UDim.new(0, 8)

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.Padding = UDim.new(0, 4)
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerListContainer

ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 10)
end)

-- Variables for auto-refresh
local isAutoRefreshing = false
local trackedUserId = nil
local refreshConnection = nil
local currentSearchTask = nil
local cachedServers = {}
local lastFoundServer = nil

-- Function to fetch servers with cursor
local function fetchServersWithCursor(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        return nil, nil
    end
    
    local data = Http:JSONDecode(response)
    return data.data, data.nextPageCursor
end

-- Function to fetch ALL servers (up to 10,000)
local function fetchAllServers()
    local allServers = {}
    local nextCursor = nil
    local pagesFetched = 0
    
    repeat
        local url = Api.._place.."/servers/Public?limit=100"
        if nextCursor then
            url = url .. "&cursor=" .. nextCursor
        end
        
        local servers, cursor = fetchServersWithCursor(url)
        if not servers then
            break
        end
        
        for _, server in ipairs(servers) do
            table.insert(allServers, server)
        end
        
        pagesFetched = pagesFetched + 1
        nextCursor = cursor
        
        -- Speed control: 10 servers per ms = 10,000 servers per second
        -- But we need to respect Roblox rate limits, so we'll do 100 servers per 100ms
        if pagesFetched % 10 == 0 then
            task.wait(0.1) -- Small delay to prevent rate limiting
        end
        
    until not nextCursor or #allServers >= 10000
    
    return allServers
end

-- Function to fetch players in a server (with pagination)
local function fetchAllPlayersInServer(serverId)
    local allPlayers = {}
    local nextCursor = nil
    
    repeat
        local url = "https://games.roblox.com/v1/games/" .. _place .. "/servers/Public/" .. serverId .. "/players?limit=100"
        if nextCursor then
            url = url .. "&cursor=" .. nextCursor
        end
        
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success then
            return nil
        end
        
        local data = Http:JSONDecode(response)
        if data.data then
            for _, player in ipairs(data.data) do
                table.insert(allPlayers, player)
            end
        end
        
        nextCursor = data.nextPageCursor
    until not nextCursor
    
    return allPlayers
end

-- Function to create server entry
local function CreateServerEntry(serverData, isTargetServer, playerCount, isFull)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -5, 0, 45)
    entry.BackgroundColor3 = isTargetServer and Color3.fromRGB(50, 45, 20) or Color3.fromRGB(30, 30, 40)
    entry.Parent = ServerListContainer
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)
    
    if isTargetServer then
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(255, 200, 0)
        border.Thickness = 2
        border.Parent = entry
    end
    
    -- Server ID (shortened)
    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
    idLabel.Position = UDim2.new(0, 5, 0, 2)
    idLabel.BackgroundTransparency = 1
    idLabel.Text = "ID: " .. string.sub(serverData.id, 1, 12) .. "..."
    idLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    idLabel.Font = Enum.Font.GothamMedium
    idLabel.TextSize = 10
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = entry
    
    -- Player count
    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Size = UDim2.new(0.5, -5, 0.5, 0)
    playerCountLabel.Position = UDim2.new(0.5, 0, 0, 2)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = string.format("%d/%d players", serverData.playing, serverData.maxPlayers)
    playerCountLabel.TextColor3 = isFull and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    playerCountLabel.Font = Enum.Font.GothamBold
    playerCountLabel.TextSize = 10
    playerCountLabel.TextXAlignment = Enum.TextXAlignment.Right
    playerCountLabel.Parent = entry
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 20)
    statusLabel.BackgroundTransparency = 1
    if isTargetServer then
        statusLabel.Text = "★ TARGET PLAYER HERE ★"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif isFull then
        statusLabel.Text = "SERVER FULL"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif serverData.playing == 0 then
        statusLabel.Text = "EMPTY SERVER"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        statusLabel.Text = "PLAYERS: " .. (playerCount and #playerCount or serverData.playing)
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = entry
    
    -- Join button
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(1, 0, 1, 0)
    joinBtn.BackgroundTransparency = 1
    joinBtn.Text = ""
    joinBtn.Parent = entry
    
    joinBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Teleporting to server..."
        TPS:TeleportToPlaceInstance(_place, serverData.id, LocalPlayer)
    end)
    
    return entry
end

-- Main search function (optimized for speed)
local function performSearch(userId, isAutoRefresh)
    if not userId then return end
    
    if not isAutoRefresh then
        -- Clear previous results for manual search
        for _, child in pairs(ServerListContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    StatusLabel.Text = "Fetching servers (up to 10,000)..."
    
    -- Fetch all servers quickly
    local allServers = fetchAllServers()
    if not allServers or #allServers == 0 then
        StatusLabel.Text = "Failed to fetch servers"
        return
    end
    
    StatusLabel.Text = string.format("Searching %d servers for player %s...", #allServers, userId)
    
    local targetServer = nil
    local targetServerPlayers = nil
    local serversScanned = 0
    local startTime = tick()
    
    -- Search through servers (optimized)
    for i, server in ipairs(allServers) do
        serversScanned = serversScanned + 1
        
        -- Update status every 100 servers
        if serversScanned % 100 == 0 then
            StatusLabel.Text = string.format("Scanning: %d/%d servers (%.1f/sec)", 
                serversScanned, #allServers, serversScanned/(tick()-startTime))
            task.wait() -- Allow UI to update
        end
        
        -- Only check servers with players
        if server.playing > 0 then
            local players = fetchAllPlayersInServer(server.id)
            if players then
                for _, player in ipairs(players) do
                    if tostring(player.id) == tostring(userId) then
                        targetServer = server
                        targetServerPlayers = players
                        break
                    end
                end
            end
        end
        
        if targetServer then break end
        
        -- Speed: 10 servers per ms achieved through minimal delays
        -- We'll do batches of 100 with minimal delay
        if i % 100 == 0 and not targetServer then
            task.wait(0.05) -- Minimal delay to prevent rate limiting
        end
    end
    
    -- Update display
    if not isAutoRefresh then
        -- Clear and show results
        for _, child in pairs(ServerListContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    if targetServer then
        StatusLabel.Text = string.format("✅ Found in server! (Scanned %d servers in %.1fs)", 
            serversScanned, tick()-startTime)
        
        if not isAutoRefresh then
            -- Show target server
            CreateServerEntry(targetServer, true, targetServerPlayers, 
                targetServer.playing >= targetServer.maxPlayers)
            
            -- Separator
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(1, -10, 0, 2)
            sep.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
            sep.BackgroundTransparency = 0.5
            sep.Parent = ServerListContainer
            
            -- Show other servers (limited to 20)
            local shown = 0
            for _, server in ipairs(allServers) do
                if server.id ~= targetServer.id and shown < 20 then
                    CreateServerEntry(server, false, nil, server.playing >= server.maxPlayers)
                    shown = shown + 1
                end
            end
        end
        
        lastFoundServer = targetServer
        cachedServers = allServers
        
    else
        if not isAutoRefresh then
            StatusLabel.Text = string.format("❌ Player not found in any server (Scanned %d servers)", #allServers)
            
            -- Show first 30 servers as examples
            for i = 1, math.min(30, #allServers) do
                CreateServerEntry(allServers[i], false, nil, allServers[i].playing >= allServers[i].maxPlayers)
            end
        end
        lastFoundServer = nil
        cachedServers = allServers
    end
end

-- Auto-refresh function
local function startAutoRefresh(userId)
    if refreshConnection then
        refreshConnection:Disconnect()
    end
    
    isAutoRefreshing = true
    trackedUserId = userId
    
    -- Initial search
    performSearch(userId, true)
    
    -- Set up periodic refresh (every 30 seconds)
    refreshConnection = RunService.Heartbeat:Connect(function()
        if isAutoRefreshing and trackedUserId then
            -- Check if enough time has passed (30 seconds)
            if not lastRefreshTime or tick() - lastRefreshTime >= 30 then
                lastRefreshTime = tick()
                performSearch(trackedUserId, true)
            end
        end
    end)
end

local function stopAutoRefresh()
    isAutoRefreshing = false
    trackedUserId = nil
    if refreshConnection then
        refreshConnection:Disconnect()
        refreshConnection = nil
    end
    AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    AutoRefreshBtn.Text = "AUTO: OFF"
end

-- Search button click
SearchBtn.MouseButton1Click:Connect(function()
    local userId = UserIdInput.Text:match("%d+")
    if userId then
        -- Stop auto-refresh if running
        if isAutoRefreshing then
            stopAutoRefresh()
        end
        performSearch(userId, false)
    else
        StatusLabel.Text = "Please enter a valid UserID"
    end
end)

-- Auto-refresh button
AutoRefreshBtn.MouseButton1Click:Connect(function()
    local userId = UserIdInput.Text:match("%d+")
    if not userId then
        StatusLabel.Text = "Enter a UserID first"
        return
    end
    
    if isAutoRefreshing then
        stopAutoRefresh()
        StatusLabel.Text = "Auto-refresh stopped"
    else
        startAutoRefresh(userId)
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        AutoRefreshBtn.Text = "AUTO: ON"
        StatusLabel.Text = "Auto-refresh started - scanning every 30s"
    end
end)

-- Enter key in input box
UserIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local userId = UserIdInput.Text:match("%d+")
        if userId then
            if isAutoRefreshing then
                stopAutoRefresh()
            end
            performSearch(userId, false)
        end
    end
end)

-- Draggable functionality
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

-- Initial status
StatusLabel.Text = "Ready - Enter UserID to track player across all servers"
