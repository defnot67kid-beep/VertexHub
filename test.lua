local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local _place = game.PlaceId
local Api = "https://games.roblox.com/v1/games/"

-- UI Setup - Compact size
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerServerTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 250) -- Smaller size
MainFrame.Position = UDim2.new(0.5, -140, 0.4, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 200, 0)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "PLAYER TRACKER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -27, 0, 4)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Input Area
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, -10, 0, 50)
InputFrame.Position = UDim2.new(0, 5, 0, 30)
InputFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
InputFrame.Parent = MainFrame
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)

local UserIdInput = Instance.new("TextBox")
UserIdInput.Size = UDim2.new(0.65, -5, 0, 30)
UserIdInput.Position = UDim2.new(0, 5, 0, 10)
UserIdInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
UserIdInput.PlaceholderText = "UserID..."
UserIdInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
UserIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
UserIdInput.Font = Enum.Font.GothamMedium
UserIdInput.TextSize = 12
UserIdInput.ClearTextOnFocus = false
UserIdInput.Parent = InputFrame
Instance.new("UICorner", UserIdInput).CornerRadius = UDim.new(0, 4)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0.35, -5, 0, 30)
SearchBtn.Position = UDim2.new(0.65, 0, 0, 10)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
SearchBtn.Text = "FIND"
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 11
SearchBtn.Parent = InputFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 4)

-- Auto-refresh toggle
local AutoRefreshBtn = Instance.new("TextButton")
AutoRefreshBtn.Size = UDim2.new(0, 40, 0, 20)
AutoRefreshBtn.Position = UDim2.new(1, -45, 0, 8)
AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
AutoRefreshBtn.Text = "OFF"
AutoRefreshBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
AutoRefreshBtn.Font = Enum.Font.GothamBold
AutoRefreshBtn.TextSize = 9
AutoRefreshBtn.Parent = MainFrame
Instance.new("UICorner", AutoRefreshBtn).CornerRadius = UDim.new(0, 4)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 16)
StatusLabel.Position = UDim2.new(0, 5, 0, 85)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Enter UserID to search"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 9
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Server List Container
local ServerListContainer = Instance.new("ScrollingFrame")
ServerListContainer.Size = UDim2.new(1, -10, 1, -120)
ServerListContainer.Position = UDim2.new(0, 5, 0, 105)
ServerListContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ServerListContainer.BorderSizePixel = 0
ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerListContainer.ScrollBarThickness = 3
ServerListContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
ServerListContainer.Visible = false
ServerListContainer.Parent = MainFrame
Instance.new("UICorner", ServerListContainer).CornerRadius = UDim.new(0, 6)

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.Padding = UDim.new(0, 2)
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerListContainer

ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 5)
end)

-- Variables for auto-refresh
local autoRefreshEnabled = false
local currentUserId = nil
local refreshConnection = nil

-- Optimized server fetching with concurrency
local function fetchAllServersParallel()
    local allServers = {}
    local cursors = {nil}
    local results = {}
    local totalScanned = 0
    
    -- First, get count of pages
    local firstPage = game:HttpGet(Api.._place.."/servers/Public?limit=100")
    local data = Http:JSONDecode(firstPage)
    
    for _, server in ipairs(data.data) do
        table.insert(allServers, server)
    end
    totalScanned = totalScanned + #data.data
    
    -- Fetch remaining pages in parallel using spawn
    local nextCursor = data.nextPageCursor
    local threads = {}
    
    while nextCursor do
        local cursor = nextCursor
        local thread = coroutine.create(function()
            local success, response = pcall(function()
                return game:HttpGet(Api.._place.."/servers/Public?limit=100&cursor="..cursor)
            end)
            
            if success then
                local pageData = Http:JSONDecode(response)
                return pageData.data, pageData.nextPageCursor
            end
            return {}, nil
        end)
        
        local _, pageServers, newCursor = coroutine.resume(thread)
        for _, server in ipairs(pageServers or {}) do
            table.insert(allServers, server)
        end
        totalScanned = totalScanned + #(pageServers or {})
        
        StatusLabel.Text = string.format("Loading servers: %d", totalScanned)
        RunService.Heartbeat:Wait()
        
        nextCursor = newCursor
    end
    
    return allServers, totalScanned
end

-- Fast player search in server
local function checkServerForPlayer(serverId, userId)
    local url = "https://games.roblox.com/v1/games/".._place.."/servers/Public/"..serverId.."/players?limit=100"
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local data = Http:JSONDecode(response)
        for _, player in ipairs(data.data or {}) do
            if tostring(player.id) == tostring(userId) then
                return true
            end
        end
    end
    return false
end

-- Optimized search function
local function searchForPlayer(userId)
    if not userId or userId == "" then
        StatusLabel.Text = "Please enter a UserID"
        return
    end
    
    ServerListContainer.Visible = true
    StatusLabel.Text = "Scanning servers..."
    SearchBtn.Text = "..."
    SearchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    SearchBtn.Active = false
    
    -- Clear previous results
    for _, child in pairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Fetch servers quickly
    local allServers, totalScanned = fetchAllServersParallel()
    
    StatusLabel.Text = string.format("Checking %d servers...", #allServers)
    
    local targetServer = nil
    local serversChecked = 0
    
    -- Search through servers with fast checking
    for _, server in ipairs(allServers) do
        serversChecked = serversChecked + 1
        
        if serversChecked % 50 == 0 then
            StatusLabel.Text = string.format("Searching: %d/%d", serversChecked, #allServers)
            RunService.Heartbeat:Wait()
        end
        
        if server.playing > 0 then
            if checkServerForPlayer(server.id, userId) then
                targetServer = server
                break
            end
        end
    end
    
    -- Display results
    if targetServer then
        StatusLabel.Text = string.format("✓ Found in: %s", string.sub(targetServer.id, 1, 8))
        
        -- Add target server
        CreateServerEntry(targetServer, true)
        
        -- Add separator
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -5, 0, 1)
        sep.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        sep.BackgroundTransparency = 0.5
        sep.Parent = ServerListContainer
        
        -- Add other servers (show 10 most recent)
        local shownCount = 0
        for _, server in ipairs(allServers) do
            if server.id ~= targetServer.id and shownCount < 10 then
                CreateServerEntry(server, false)
                shownCount = shownCount + 1
            end
        end
    else
        StatusLabel.Text = "✗ Player not found"
        
        -- Show recent servers
        for i = 1, math.min(15, #allServers) do
            CreateServerEntry(allServers[i], false)
        end
    end
    
    SearchBtn.Text = "FIND"
    SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    SearchBtn.Active = true
end

-- Compact server entry creation
function CreateServerEntry(serverData, isTarget)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -5, 0, 26)
    entry.BackgroundColor3 = isTarget and Color3.fromRGB(40, 35, 15) or Color3.fromRGB(25, 25, 32)
    entry.Parent = ServerListContainer
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
    
    if isTarget then
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(255, 200, 0)
        border.Thickness = 1
        border.Parent = entry
    end
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.65, -5, 1, 0)
    infoLabel.Position = UDim2.new(0, 4, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.format("%s | %d/%d", 
        string.sub(serverData.id, 1, 6),
        serverData.playing,
        serverData.maxPlayers
    )
    infoLabel.TextColor3 = isTarget and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
    infoLabel.Font = isTarget and Enum.Font.GothamBold or Enum.Font.GothamMedium
    infoLabel.TextSize = 9
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = entry
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.35, -5, 1, 0)
    statusLabel.Position = UDim2.new(0.65, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    if isTarget then
        statusLabel.Text = "★"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif serverData.playing >= serverData.maxPlayers then
        statusLabel.Text = "FULL"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif serverData.playing == 0 then
        statusLabel.Text = "EMPTY"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        statusLabel.Text = serverData.playing.."p"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 8
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = entry
    
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(1, 0, 1, 0)
    joinBtn.BackgroundTransparency = 1
    joinBtn.Text = ""
    joinBtn.Parent = entry
    
    joinBtn.MouseButton1Click:Connect(function()
        StatusLabel.Text = "Teleporting..."
        TPS:TeleportToPlaceInstance(_place, serverData.id, LocalPlayer)
    end)
end

-- Auto-refresh functionality
local function toggleAutoRefresh()
    autoRefreshEnabled = not autoRefreshEnabled
    
    if autoRefreshEnabled then
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        AutoRefreshBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        AutoRefreshBtn.Text = "ON"
        
        if currentUserId then
            -- Start auto-refresh loop
            refreshConnection = RunService.Heartbeat:Connect(function()
                if autoRefreshEnabled and currentUserId then
                    searchForPlayer(currentUserId)
                    task.wait(5) -- Refresh every 5 seconds
                end
            end)
        end
    else
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        AutoRefreshBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        AutoRefreshBtn.Text = "OFF"
        
        if refreshConnection then
            refreshConnection:Disconnect()
            refreshConnection = nil
        end
    end
end

-- Event connections
SearchBtn.MouseButton1Click:Connect(function()
    local userId = UserIdInput.Text:match("%d+")
    if userId then
        currentUserId = userId
        searchForPlayer(userId)
        
        -- If auto-refresh is on, update the refresh loop
        if autoRefreshEnabled then
            if refreshConnection then
                refreshConnection:Disconnect()
            end
            refreshConnection = RunService.Heartbeat:Connect(function()
                if autoRefreshEnabled and currentUserId then
                    searchForPlayer(currentUserId)
                    task.wait(5)
                end
            end)
        end
    end
end)

UserIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local userId = UserIdInput.Text:match("%d+")
        if userId then
            currentUserId = userId
            searchForPlayer(userId)
        end
    end
end)

AutoRefreshBtn.MouseButton1Click:Connect(toggleAutoRefresh)

-- Make GUI draggable
local dragging = false
local dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
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

-- Initial status
StatusLabel.Text = "Ready - Enter UserID"
