local Http = game:GetService("HttpService")
local TPS = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local _place = game.PlaceId
local Api = "https://games.roblox.com/v1/games/"

-- UI Setup - Made smaller
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerServerTracker"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 300) -- Smaller size
MainFrame.Position = UDim2.new(0.5, -175, 0.4, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 200, 0) -- Yellow stroke
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "PLAYER TRACKER"
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
InputFrame.Size = UDim2.new(1, -20, 0, 60)
InputFrame.Position = UDim2.new(0, 10, 0, 35)
InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputFrame.Parent = MainFrame
Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)

local UserIdInput = Instance.new("TextBox")
UserIdInput.Size = UDim2.new(0.7, -5, 0, 35)
UserIdInput.Position = UDim2.new(0, 10, 0, 12)
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
SearchBtn.Size = UDim2.new(0.3, -5, 0, 35)
SearchBtn.Position = UDim2.new(0.7, 0, 0, 12)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Yellow button
SearchBtn.Text = "FIND"
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 12
SearchBtn.Parent = InputFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 47)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Enter a UserID to search"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = InputFrame

-- Create Scrolling Frame for Server List
local ServerListContainer = Instance.new("ScrollingFrame")
ServerListContainer.Size = UDim2.new(1, -20, 1, -115)
ServerListContainer.Position = UDim2.new(0, 10, 0, 100)
ServerListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ServerListContainer.BorderSizePixel = 0
ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerListContainer.ScrollBarThickness = 4
ServerListContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
ServerListContainer.Visible = false
ServerListContainer.Parent = MainFrame
Instance.new("UICorner", ServerListContainer).CornerRadius = UDim.new(0, 8)

local ServerListLayout = Instance.new("UIListLayout")
ServerListLayout.Padding = UDim.new(0, 3)
ServerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerListLayout.Parent = ServerListContainer

ServerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ServerListContainer.CanvasSize = UDim2.new(0, 0, 0, ServerListLayout.AbsoluteContentSize.Y + 5)
end)

-- Function to fetch all servers (handles pagination)
local function fetchAllServers(cursor)
    local url = Api.._place.."/servers/Public?limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        return nil, nil
    end
    
    local data = Http:JSONDecode(response)
    return data.data, data.nextPageCursor
end

-- Function to fetch players in a specific server
local function fetchServerPlayers(serverId, cursor)
    local url = "https://games.roblox.com/v1/games/" .. _place .. "/servers/Public/" .. serverId .. "/players?limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        return nil, nil
    end
    
    local data = Http:JSONDecode(response)
    return data.data, data.nextPageCursor
end

-- Function to create server entry (smaller design)
local function CreateServerEntry(serverData, isTargetServer)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -5, 0, 35) -- Smaller height
    entry.BackgroundColor3 = isTargetServer and Color3.fromRGB(50, 45, 20) or Color3.fromRGB(30, 30, 40) -- Yellow tint for target
    entry.Parent = ServerListContainer
    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 4)
    
    -- Highlight border for target server
    if isTargetServer then
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(255, 200, 0)
        border.Thickness = 2
        border.Parent = entry
    end
    
    -- Server info (compact)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.7, -5, 1, 0)
    infoLabel.Position = UDim2.new(0, 5, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = string.format("%s | %d/%d", 
        string.sub(serverData.id, 1, 8),
        serverData.playing,
        serverData.maxPlayers
    )
    infoLabel.TextColor3 = isTargetServer and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
    infoLabel.Font = isTargetServer and Enum.Font.GothamBold or Enum.Font.GothamMedium
    infoLabel.TextSize = 11
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = entry
    
    -- Status indicator
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
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Parent = entry
    
    -- Make clickable to join
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

-- Main search function
local function searchForPlayer(userId)
    -- Clear previous results
    for _, child in pairs(ServerListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not userId then
        StatusLabel.Text = "Please enter a UserID"
        return
    end
    
    ServerListContainer.Visible = true
    StatusLabel.Text = "Scanning all servers..."
    SearchBtn.Text = "🔍"
    SearchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    SearchBtn.Active = false
    
    local targetServer = nil
    local targetServerData = nil
    local allServers = {}
    local nextCursor = nil
    local totalScanned = 0
    
    -- Fetch ALL servers using pagination
    repeat
        local servers, cursor = fetchAllServers(nextCursor)
        if not servers then
            StatusLabel.Text = "Error fetching servers"
            break
        end
        
        for _, server in ipairs(servers) do
            table.insert(allServers, server)
        end
        
        totalScanned = totalScanned + #servers
        StatusLabel.Text = string.format("Scanning... %d servers found", totalScanned)
        task.wait(0.1) -- Small delay to prevent rate limiting
        
        nextCursor = cursor
    until not nextCursor
    
    StatusLabel.Text = string.format("Checking %d servers for player...", totalScanned)
    
    -- Check each server for the player
    for i, server in ipairs(allServers) do
        StatusLabel.Text = string.format("Searching... %d/%d", i, #allServers)
        
        if server.playing > 0 then
            local playerCursor = nil
            repeat
                local players, nextPlayerCursor = fetchServerPlayers(server.id, playerCursor)
                if players then
                    for _, player in ipairs(players) do
                        if tostring(player.id) == tostring(userId) then
                            targetServer = server
                            targetServerData = server
                            break
                        end
                    end
                end
                playerCursor = nextPlayerCursor
            until not playerCursor or targetServer
        end
        
        if targetServer then break end
        task.wait(0.05)
    end
    
    -- Display results
    if targetServer then
        StatusLabel.Text = string.format("✅ Found in server: %s", string.sub(targetServer.id, 1, 12))
        
        -- Add target server at the top
        CreateServerEntry(targetServer, true)
        
        -- Add separator
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -5, 0, 1)
        sep.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        sep.BackgroundTransparency = 0.5
        sep.Parent = ServerListContainer
        
        -- Add other servers (limit to 20 to keep list manageable)
        local otherCount = 0
        for _, server in ipairs(allServers) do
            if server.id ~= targetServer.id and otherCount < 20 then
                CreateServerEntry(server, false)
                otherCount = otherCount + 1
            end
        end
        
        if #allServers > 21 then
            local moreLabel = Instance.new("TextLabel")
            moreLabel.Size = UDim2.new(1, -5, 0, 20)
            moreLabel.BackgroundTransparency = 1
            moreLabel.Text = string.format("+ %d more servers", #allServers - 21)
            moreLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            moreLabel.Font = Enum.Font.GothamMedium
            moreLabel.TextSize = 10
            moreLabel.Parent = ServerListContainer
        end
    else
        StatusLabel.Text = "❌ Player not found in any server"
        
        -- Show recent servers (first 20)
        for i = 1, math.min(20, #allServers) do
            CreateServerEntry(allServers[i], false)
        end
        
        if #allServers > 20 then
            local moreLabel = Instance.new("TextLabel")
            moreLabel.Size = UDim2.new(1, -5, 0, 20)
            moreLabel.BackgroundTransparency = 1
            moreLabel.Text = string.format("+ %d more servers", #allServers - 20)
            moreLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            moreLabel.Font = Enum.Font.GothamMedium
            moreLabel.TextSize = 10
            moreLabel.Parent = ServerListContainer
        end
    end
    
    SearchBtn.Text = "FIND"
    SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    SearchBtn.Active = true
end

-- Search button click
SearchBtn.MouseButton1Click:Connect(function()
    local userId = UserIdInput.Text:match("%d+")
    searchForPlayer(userId)
end)

-- Enter key in input box
UserIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local userId = UserIdInput.Text:match("%d+")
        searchForPlayer(userId)
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
