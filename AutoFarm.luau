local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration })
    end)
end

local function copyToClipboard(text)
    if type(text) ~= "string" then
        text = tostring(text)
    end
    local clipped = false
    if type(toclipboard) == "function" then
        local ok = pcall(function() toclipboard(text) end)
        if ok then
            clipped = true
        end
    end
    if not clipped then
        if type(setclipboard) == "function" then
            local ok2 = pcall(function() setclipboard(text) end)
            if ok2 then
                clipped = true
            end
        end
    end
    return clipped
end

notify("Auto Farm", "Wrapper started. Compiling...", 4)

local SCRIPT_SOURCE = [==[
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local clock = os.clock
local wait_ = task.wait
local spawn_ = task.spawn
local clamp_ = math.clamp
local min_ = math.min
local abs_ = math.abs
local huge_ = math.huge
local rad_ = math.rad
local floor_ = math.floor
local random_ = math.random
local sort_ = table.sort
local insert_ = table.insert
local concat_ = table.concat
local lower_ = string.lower
local sub_ = string.sub
local match_ = string.match

local ALIGN_CF = CFrame.new(0, 0, 6)

local sethiddenFn = nil
if typeof(sethiddenproperty) == "function" then
    sethiddenFn = sethiddenproperty
end

local function setPhysRep(root, target)
    if sethiddenFn == nil then
        return
    end
    if root == nil then
        return
    end
    pcall(function() sethiddenFn(root, "PhysicsRepRootPart", target) end)
end

local forceHealthConnection = nil
local killFlag = false

local function setupForceHealth(character)
    if character == nil then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid == nil then
        local okW = false
        local h = nil
        okW = pcall(function() h = character:WaitForChild("Humanoid", 5) end)
        if okW then
            humanoid = h
        end
    end
    if humanoid == nil then
        return
    end

    pcall(function() humanoid.BreakJointsOnDeath = false end)
    pcall(function() humanoid.RequiresNeck = false end)

    if forceHealthConnection ~= nil then
        forceHealthConnection:Disconnect()
        forceHealthConnection = nil
    end

    if humanoid.Health < 100 then
        humanoid.Health = 100
    end

    forceHealthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if killFlag then
            return
        end
        if humanoid.Health < 100 then
            humanoid.Health = 100
        end
    end)
end

if LocalPlayer.Character ~= nil then
    setupForceHealth(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    setupForceHealth(Character)
end)

Workspace.FallenPartsDestroyHeight = 0/0

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"

local BOUND_POSITION = Vector3.new(0, -10000, 0)
local SAFE_POSITION = Vector3.new(0, -9997, 0)

local TWIN_FANGS_NAME = "Twin Fangs"
local TWIN_FANGS_SLOT = 2

local TF_ALIGN_DURATION = 2
local TF_BOUNDARY_SETTLE = 3.0
local TF_ACTIVATION_TIMEOUT = 3.0
local TF_RETRY_INTERVAL = 0.1
local FALLBACK_TOOL_DURATION = 0.5
local ROTATION_LOOP_DELAY = 0.05

local LOW_HP_THRESHOLD = 0.2

local ANTI_MODE_COLOR = Color3.fromRGB(255, 120, 60)

local SPAM_ANIMATION_ID = "119169968232874"
local SPAM_NUMERIC = match_(SPAM_ANIMATION_ID, "%d+") or SPAM_ANIMATION_ID

local REMOTE_COOLDOWN = 0.03
local G_INTERVAL = 0.01
local JUMP_INTERVAL = 0.01
local SPACE_HOLD_TIME = 0.03
local RAGDOLL_COOLDOWN = 0.5

local CAMERA_SENSITIVITY = 0.003
local CAMERA_MIN_DIST = 5
local CAMERA_MAX_DIST = 60
local CAMERA_HEIGHT = 3

local CLONE_CHECK_INTERVAL = 0
local CLONE_REBUILD_COOLDOWN = 0

local STEALTH_STREAK_THRESHOLD = 6

local THROWN_CLEAR_DELAY = 0.06
local HOP_CHECK_INTERVAL = 0.5
local HOP_TELEPORT_VERIFY_WAIT = 6
local HOP_MAX_ATTEMPTS = 5
local HOP_CANDIDATE_TRY_COUNT = 3

local FALLBACK_EXCLUDE = { TWIN_FANGS_NAME }
local PROXIMITY_PRIORITY_RANGE = 50

local ATTACK_POSITION_EPS = 0.01

local G = _G

local function getGuiParent()
    local gethuiFn = G.gethui
    if typeof(gethuiFn) == "function" then
        local ok, result = pcall(function() return gethuiFn() end)
        if ok and typeof(result) == "Instance" then
            return result
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local count = #chars
    local parts = {}
    local i = 1
    while i <= length do
        local idx = random_(1, count)
        parts[i] = sub_(chars, idx, idx)
        i = i + 1
    end
    return concat_(parts)
end

local function readConfig()
    if typeof(isfile) ~= "function" then
        return nil
    end
    if typeof(readfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(function() return isfile(CONFIG_PATH) end)
    if not ok or not exists then
        return nil
    end
    local readOk, content = pcall(function() return readfile(CONFIG_PATH) end)
    if not readOk or content == nil then
        return nil
    end
    if content == "" then
        return nil
    end
    local decodeOk, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not decodeOk or typeof(data) ~= "table" then
        return nil
    end
    return data
end

local function writeConfig(data)
    if typeof(writefile) ~= "function" then
        return
    end
    local encodeOk, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not encodeOk or encoded == nil then
        return
    end
    pcall(function() writefile(CONFIG_PATH, encoded) end)
end

local function RUN()
    local IS_MOBILE = UserInputService.TouchEnabled

    pcall(function() math.randomseed(os.time() + random_(1, 1e6)) end)

    local guiParent = getGuiParent()

    local BoundaryZone = Instance.new("Part")
    BoundaryZone.Name = "P_" .. randomString(14)
    BoundaryZone.Size = Vector3.new(2048, 1, 2048)
    BoundaryZone.CFrame = CFrame.new(BOUND_POSITION)
    BoundaryZone.Anchored = true
    BoundaryZone.CanCollide = true
    BoundaryZone.CanQuery = false
    BoundaryZone.CanTouch = false
    BoundaryZone.Transparency = 0.7
    BoundaryZone.Parent = Workspace

    local saved = readConfig()

    local farmEnabled = false
    local performanceMode = true
    local stealthMode = false
    local serverHopEnabled = false
    local targetKills = 20
    local showsKills = 0

    if saved ~= nil then
        if typeof(saved.farmEnabled) == "boolean" then
            farmEnabled = saved.farmEnabled
        end
        if typeof(saved.performanceMode) == "boolean" then
            performanceMode = saved.performanceMode
        end
        if typeof(saved.stealthMode) == "boolean" then
            stealthMode = saved.stealthMode
        end
        if typeof(saved.serverHopEnabled) == "boolean" then
            serverHopEnabled = saved.serverHopEnabled
        end
        if typeof(saved.targetKills) == "number" then
            targetKills = saved.targetKills
        end
        if typeof(saved.showsKills) == "number" then
            showsKills = saved.showsKills
        end
    end

    local configExisted = saved ~= nil
    local configInitialized = false

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmPanel"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = guiParent

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.fromOffset(230, 390)
    Main.Position = UDim2.new(0.5, -125, 0.5, -210)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    Main.BackgroundTransparency = 0.05
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.25
    MainStroke.Parent = Main

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 10)
    Pad.PaddingLeft = UDim.new(0, 10)
    Pad.PaddingRight = UDim.new(0, 10)
    Pad.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -40, 0, 28)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Farm"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main

    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(1, -40, 0, 18)
    Status.Position = UDim2.fromOffset(0, 29)
    Status.BackgroundTransparency = 1
    Status.Text = "Mode: Idle"
    Status.TextColor3 = Color3.fromRGB(170, 170, 180)
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main

    local function makeToggle(name, text, pos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 43)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = Main

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 9)
        c.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -65, 1, 0)
        lbl.Position = UDim2.fromOffset(13, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local state = Instance.new("TextLabel")
        state.Name = "State"
        state.Size = UDim2.fromOffset(50, 26)
        state.Position = UDim2.new(1, -57, 0.5, -13)
        state.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        state.BorderSizePixel = 0
        state.Text = "OFF"
        state.TextColor3 = Color3.fromRGB(190, 190, 195)
        state.TextSize = 11
        state.Font = Enum.Font.GothamBold
        state.Parent = btn

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, 7)
        sc.Parent = state

        return btn, state
    end

    local FarmButton, FarmState = makeToggle("AutoFarmToggle", "Auto Farm", UDim2.fromOffset(0, 55))
    local PerfButton, PerfState = makeToggle("PerformanceToggle", "Performance Mode", UDim2.fromOffset(0, 101))
    local StealthButton, StealthState = makeToggle("StealthToggle", "Stealth Mode", UDim2.fromOffset(0, 147))
    local HopButton, HopState = makeToggle("ServerHopToggle", "Server Hop", UDim2.fromOffset(0, 193))

    local KillsRow = Instance.new("Frame")
    KillsRow.Name = "KillsRow"
    KillsRow.Size = UDim2.new(1, 0, 0, 30)
    KillsRow.Position = UDim2.fromOffset(0, 240)
    KillsRow.BackgroundTransparency = 1
    KillsRow.Parent = Main

    local KillsLabel = Instance.new("TextLabel")
    KillsLabel.Size = UDim2.new(0.55, 0, 1, 0)
    KillsLabel.Position = UDim2.fromOffset(0, 0)
    KillsLabel.BackgroundTransparency = 1
    KillsLabel.Text = "Target Kills:"
    KillsLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
    KillsLabel.TextSize = 13
    KillsLabel.Font = Enum.Font.GothamMedium
    KillsLabel.TextXAlignment = Enum.TextXAlignment.Left
    KillsLabel.Parent = KillsRow

    local KillsBox = Instance.new("TextBox")
    KillsBox.Name = "KillsBox"
    KillsBox.Size = UDim2.new(0.45, 0, 1, 0)
    KillsBox.Position = UDim2.new(0.55, 0, 0, 0)
    KillsBox.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    KillsBox.BorderSizePixel = 0
    KillsBox.Text = tostring(targetKills)
    KillsBox.TextColor3 = Color3.new(1, 1, 1)
    KillsBox.TextSize = 13
    KillsBox.Font = Enum.Font.GothamMedium
    KillsBox.PlaceholderText = "20"
    KillsBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    KillsBox.ClearTextOnFocus = false
    KillsBox.Parent = KillsRow

    local KillsBoxCorner = Instance.new("UICorner")
    KillsBoxCorner.CornerRadius = UDim.new(0, 6)
    KillsBoxCorner.Parent = KillsBox

    local ShowsLabel = Instance.new("TextLabel")
    ShowsLabel.Name = "ShowsLabel"
    ShowsLabel.Size = UDim2.new(1, 0, 0, 18)
    ShowsLabel.Position = UDim2.fromOffset(0, 274)
    ShowsLabel.BackgroundTransparency = 1
    ShowsLabel.Text = "Shows Kills: 0"
    ShowsLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    ShowsLabel.TextSize = 11
    ShowsLabel.Font = Enum.Font.Gotham
    ShowsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowsLabel.Parent = Main

    local CurrentLabel = Instance.new("TextLabel")
    CurrentLabel.Name = "CurrentLabel"
    CurrentLabel.Size = UDim2.new(1, 0, 0, 18)
    CurrentLabel.Position = UDim2.fromOffset(0, 292)
    CurrentLabel.BackgroundTransparency = 1
    CurrentLabel.Text = "Current Kills: 0"
    CurrentLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    CurrentLabel.TextSize = 11
    CurrentLabel.Font = Enum.Font.Gotham
    CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentLabel.Parent = Main

    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Name = "Warning"
    WarningLabel.Size = UDim2.new(1, 0, 0, 40)
    WarningLabel.Position = UDim2.fromOffset(0, 320)
    WarningLabel.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
    WarningLabel.BackgroundTransparency = 0.15
    WarningLabel.BorderSizePixel = 0
    WarningLabel.Text = "Warning: Stealth Mode slows the farm but keeps you hidden."
    WarningLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    WarningLabel.TextSize = 10
    WarningLabel.Font = Enum.Font.GothamMedium
    WarningLabel.TextWrapped = true
    WarningLabel.Visible = false
    WarningLabel.Parent = Main

    local WarnCorner = Instance.new("UICorner")
    WarnCorner.CornerRadius = UDim.new(0, 8)
    WarnCorner.Parent = WarningLabel

    local protectionActive = false
    local rotationRunning = false
    local lowHealthMode = false
    local selfRagdollActive = false
    local attackingActive = false

    local protectionOrigin = nil
    local lastRemoteFire = 0
    local lastGPress = 0
    local lastJumpPress = 0
    local lastRagdollFire = 0
    local lastKillsLabelUpdate = 0

    local characterConnections = {}
    local permanentConnections = {}
    local watchedTools = {}
    local targetStates = {}
    local fallbackIndex = 0

    local windowDragging = false
    local windowDragStart = Vector2.zero
    local windowStartPos = UDim2.new()

    local cameraYaw = 0
    local cameraPitch = rad_(-8)
    local cameraDistance = 20

    local cloneCharacter = nil
    local cloneRoot = nil
    local cloneHumanoid = nil
    local cloneAnimator = nil
    local animationMirrors = {}

    local lastWatchedCharacter = nil
    local lastCloneCheck = 0
    local lastCloneRebuild = 0

    local spamTrack = nil
    local spamTrackCharacter = nil

    local spaceDown = false
    local spaceDownAt = 0

    local cachedBackpack = nil
    local thrownConnection = nil

    local killsValue = nil
    local lastHopCheck = 0
    local hopInProgress = false
    local hopRequestedStop = false

    local suppressHeartbeatTp = false
    local teleportFailedFlag = false
    local teleportFailConnection = nil

    local function persistConfig()
        writeConfig({
            farmEnabled = farmEnabled,
            performanceMode = performanceMode,
            stealthMode = stealthMode,
            serverHopEnabled = serverHopEnabled,
            targetKills = targetKills,
            showsKills = showsKills,
        })
    end

    local function setToggle(label, on)
        if on then
            label.Text = "ON"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
        else
            label.Text = "OFF"
            label.TextColor3 = Color3.fromRGB(190, 190, 195)
            label.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        end
    end

    local function refreshStatus()
        if selfRagdollActive then
            Status.Text = "Mode: Anti (Anti Invisible)"
            Status.TextColor3 = ANTI_MODE_COLOR
        elseif protectionActive then
            Status.Text = "Mode: Boundary Zone"
            Status.TextColor3 = Color3.fromRGB(170, 170, 180)
        elseif lowHealthMode then
            Status.Text = "Mode: LOW HP - Recovering"
            Status.TextColor3 = Color3.fromRGB(255, 90, 90)
        elseif hopInProgress then
            Status.Text = "Mode: Server Hopping"
            Status.TextColor3 = Color3.fromRGB(170, 170, 180)
        elseif rotationRunning then
            Status.Text = "Mode: Rotation Sequence"
            Status.TextColor3 = Color3.fromRGB(170, 170, 180)
        elseif farmEnabled then
            Status.Text = "Mode: FULL ACTIVE"
            Status.TextColor3 = Color3.fromRGB(170, 170, 180)
        else
            Status.Text = "Mode: Idle"
            Status.TextColor3 = Color3.fromRGB(170, 170, 180)
        end
    end

    local function refreshKillsDisplay()
        ShowsLabel.Text = "Shows Kills: " .. tostring(showsKills)
        if killsValue ~= nil then
            CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
        else
            CurrentLabel.Text = "Current Kills: 0"
        end
    end

    FarmButton.Activated:Connect(function()
        farmEnabled = not farmEnabled
        setToggle(FarmState, farmEnabled)
        if not farmEnabled then
            suppressHeartbeatTp = false
        end
        persistConfig()
        refreshStatus()
    end)

    PerfButton.Activated:Connect(function()
        performanceMode = not performanceMode
        setToggle(PerfState, performanceMode)
        persistConfig()
    end)

    StealthButton.Activated:Connect(function()
        stealthMode = not stealthMode
        setToggle(StealthState, stealthMode)
        WarningLabel.Visible = stealthMode
        persistConfig()
    end)

    HopButton.Activated:Connect(function()
        serverHopEnabled = not serverHopEnabled
        setToggle(HopState, serverHopEnabled)
        persistConfig()
        if not serverHopEnabled then
            hopRequestedStop = true
            hopInProgress = false
            refreshStatus()
        end
    end)

    KillsBox.FocusLost:Connect(function()
        local n = tonumber(KillsBox.Text)
        if n ~= nil and n > 0 then
            targetKills = floor_(n)
        end
        KillsBox.Text = tostring(targetKills)
        persistConfig()
    end)

    setToggle(FarmState, farmEnabled)
    setToggle(PerfState, performanceMode)
    setToggle(StealthState, stealthMode)
    setToggle(HopState, serverHopEnabled)
    WarningLabel.Visible = stealthMode
    refreshKillsDisplay()

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            windowDragging = true
            windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            windowStartPos = Main.Position
        elseif input.UserInputType == Enum.UserInputType.Touch then
            windowDragging = true
            windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            windowStartPos = Main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if windowDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = Vector2.new(input.Position.X, input.Position.Y) - windowDragStart
                Main.Position = UDim2.new(
                    windowStartPos.X.Scale,
                    windowStartPos.X.Offset + delta.X,
                    windowStartPos.Y.Scale,
                    windowStartPos.Y.Offset + delta.Y
                )
            end
            return
        end

        local uit = input.UserInputType
        if uit == Enum.UserInputType.MouseMovement then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                cameraYaw = cameraYaw - input.Delta.X * CAMERA_SENSITIVITY
                cameraPitch = clamp_(cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY, rad_(-80), rad_(80))
            end
        elseif uit == Enum.UserInputType.Touch then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                cameraYaw = cameraYaw - input.Delta.X * CAMERA_SENSITIVITY * 1.4
                cameraPitch = clamp_(cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY * 1.4, rad_(-80), rad_(80))
            end
        elseif uit == Enum.UserInputType.MouseWheel then
            cameraDistance = clamp_(cameraDistance - input.Position.Z * 2, CAMERA_MIN_DIST, CAMERA_MAX_DIST)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            windowDragging = false
        end
    end)

    local function hasProtection(character)
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then
            return true
        end
        if character:FindFirstChild("ForceField") ~= nil then
            return true
        end
        if character:FindFirstChild("FinalDeath") ~= nil then
            return true
        end
        if character:FindFirstChild("Counter") ~= nil then
            return true
        end
        return false
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if character == nil then
            return nil
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil then
            return nil
        end
        if not root:IsA("BasePart") then
            return nil
        end
        return root
    end

    local function selfHasRagdoll()
        local character = LocalPlayer.Character
        if character == nil then
            return false
        end
        if character:FindFirstChild("Ragdoll") ~= nil then
            return true
        end
        return false
    end

    local function checkAttacking()
        local root = getRoot()
        if root == nil then
            return false
        end
        local pos = root.CFrame.Position
        local dx = pos.X - 0
        local dy = pos.Y - 0
        local dz = pos.Z - 6
        local distSq = dx * dx + dy * dy + dz * dz
        return distSq <= (ATTACK_POSITION_EPS * ATTACK_POSITION_EPS)
    end

    local function getPlayerRoot(player)
        if player == nil then
            return nil
        end
        if player == LocalPlayer then
            return nil
        end
        local tc = player.Character
        if tc == nil then
            return nil
        end
        if hasProtection(tc) then
            return nil
        end
        local hum = tc:FindFirstChildOfClass("Humanoid")
        if hum == nil then
            return nil
        end
        if hum.Health <= 0 then
            return nil
        end
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if tr == nil then
            return nil
        end
        if not tr:IsA("BasePart") then
            return nil
        end
        return tr
    end

    local function getClosestPlayerWithin(range, refPos)
        local best = nil
        local bestDSq = range * range
        local players = Players:GetPlayers()
        local i = 1
        while i <= #players do
            local player = players[i]
            if player ~= LocalPlayer then
                local tr = getPlayerRoot(player)
                if tr ~= nil then
                    local dx = tr.Position.X - refPos.X
                    local dy = tr.Position.Y - refPos.Y
                    local dz = tr.Position.Z - refPos.Z
                    local dSq = dx * dx + dy * dy + dz * dz
                    if dSq <= bestDSq then
                        bestDSq = dSq
                        best = player
                    end
                end
            end
            i = i + 1
        end
        return best
    end

    local function getTarget()
        local root = getRoot()
        if root == nil then
            return nil
        end
        local close = getClosestPlayerWithin(PROXIMITY_PRIORITY_RANGE, root.Position)
        if close ~= nil then
            return close
        end

        local lowestHpPlayer = nil
        local lowestHealth = huge_
        local players = Players:GetPlayers()
        local i = 1
        while i <= #players do
            local player = players[i]
            if player ~= LocalPlayer then
                local tc = player.Character
                if tc ~= nil and not hasProtection(tc) then
                    local hum = tc:FindFirstChildOfClass("Humanoid")
                    if hum ~= nil and hum.Health > 0 then
                        local tr = tc:FindFirstChild("HumanoidRootPart")
                        if tr ~= nil and tr:IsA("BasePart") then
                            if hum.Health < lowestHealth then
                                lowestHealth = hum.Health
                                lowestHpPlayer = player
                            end
                        end
                    end
                end
            end
            i = i + 1
        end
        return lowestHpPlayer
    end

    local function pinToSafeZone(root)
        if root == nil then
            return
        end
        setPhysRep(root, nil)
        root.CFrame = CFrame.new(SAFE_POSITION)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function pressKey(code)
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end

    local function pressG()
        local now = clock()
        if now - lastGPress < G_INTERVAL then
            return
        end
        lastGPress = now
        pressKey(Enum.KeyCode.G)
    end

    local function pressJump()
        local now = clock()
        if now - lastJumpPress < JUMP_INTERVAL then
            return
        end
        lastJumpPress = now
        if not spaceDown then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            spaceDown = true
            spaceDownAt = now
        end
    end

    local function tickSpaceRelease()
        if spaceDown then
            if clock() - spaceDownAt >= SPACE_HOLD_TIME then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                spaceDown = false
            end
        end
    end

    local function getCommunicate()
        local character = LocalPlayer.Character
        if character == nil then
            return nil
        end
        local comm = character:FindFirstChild("Communicate")
        if comm == nil then
            return nil
        end
        if not comm:IsA("RemoteEvent") then
            return nil
        end
        return comm
    end

    local function getMouseCFrame()
        local cam = Workspace.CurrentCamera
        if cam == nil then
            return nil
        end
        local mp = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mp.X, mp.Y)
        return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction * 1000)
    end

    local function fireCommunicate()
        local now = clock()
        if now - lastRemoteFire < REMOTE_COOLDOWN then
            return
        end
        lastRemoteFire = now
        local comm = getCommunicate()
        if comm == nil then
            return
        end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then
            return
        end
        comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF })
    end

    local function activateToolViaRemote(tool)
        local comm = getCommunicate()
        if comm == nil then
            return
        end
        comm:FireServer({ Tool = tool, Goal = "Console Move", IsAutoActivate = true })
    end

    local function fireRagdollFinish()
        local comm = getCommunicate()
        if comm == nil then
            return
        end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then
            return
        end
        comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress", MousePos = mouseCF })
    end

    local function tryFireRagdollFinish()
        local now = clock()
        if now - lastRagdollFire < RAGDOLL_COOLDOWN then
            return
        end
        local target = getTarget()
        if target == nil then
            return
        end
        local tc = target.Character
        if tc == nil then
            return
        end
        if tc:FindFirstChild("Ragdoll") == nil then
            return
        end
        lastRagdollFire = now
        fireRagdollFinish()
    end

    local function getBackpack()
        if cachedBackpack ~= nil and cachedBackpack.Parent ~= nil then
            return cachedBackpack
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp ~= nil and bp:IsA("Backpack") then
            cachedBackpack = bp
            return bp
        end
        return nil
    end

    local function findTool(name)
        local target = lower_(name)
        local bp = getBackpack()
        if bp ~= nil then
            local children = bp:GetChildren()
            local i = 1
            while i <= #children do
                local c = children[i]
                if c:IsA("Tool") then
                    if lower_(c.Name) == target then
                        return c
                    end
                end
                i = i + 1
            end
        end
        local ch = LocalPlayer.Character
        if ch ~= nil then
            local children = ch:GetChildren()
            local i = 1
            while i <= #children do
                local c = children[i]
                if c:IsA("Tool") then
                    if lower_(c.Name) == target then
                        return c
                    end
                end
                i = i + 1
            end
        end
        return nil
    end

    local function getAllTools(exclude)
        local excl = {}
        local i = 1
        while i <= #exclude do
            excl[lower_(exclude[i])] = true
            i = i + 1
        end
        local result = {}
        local bp = getBackpack()
        if bp ~= nil then
            local children = bp:GetChildren()
            local j = 1
            while j <= #children do
                local c = children[j]
                if c:IsA("Tool") then
                    if not excl[lower_(c.Name)] then
                        insert_(result, c)
                    end
                end
                j = j + 1
            end
        end
        local ch = LocalPlayer.Character
        if ch ~= nil then
            local children = ch:GetChildren()
            local j = 1
            while j <= #children do
                local c = children[j]
                if c:IsA("Tool") then
                    if not excl[lower_(c.Name)] then
                        insert_(result, c)
                    end
                end
                j = j + 1
            end
        end
        return result
    end

    local function twinFangsExists()
        if findTool(TWIN_FANGS_NAME) ~= nil then
            return true
        end
        return false
    end

    local function genericSpam()
        if twinFangsExists() then
            return
        end
        pressJump()
        fireCommunicate()
        tryFireRagdollFinish()
    end

    local function hotbarHasCooldown(slot)
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg == nil then
            return false
        end
        local hotbar = pg:FindFirstChild("Hotbar")
        if hotbar == nil then
            return false
        end
        local bp = hotbar:FindFirstChild("Backpack")
        if bp == nil then
            return false
        end
        local slots = bp:FindFirstChild("Hotbar")
        if slots == nil then
            return false
        end
        local frame = slots:FindFirstChild(tostring(slot))
        if frame == nil then
            return false
        end
        local baseFrame = frame:FindFirstChild("Base")
        if baseFrame == nil then
            return false
        end
        if baseFrame:FindFirstChild("Cooldown") ~= nil then
            return true
        end
        return false
    end

    local function ensureInvisible()
        local character = LocalPlayer.Character
        if character == nil then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then
            return
        end

        if spamTrackCharacter ~= character then
            if spamTrack ~= nil then
                pcall(function() spamTrack:Stop(0) end)
            end
            spamTrack = nil
            spamTrackCharacter = character
        end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then
            local na = Instance.new("Animator")
            na.Parent = humanoid
            animator = na
        end
        if animator == nil then
            return
        end

        if spamTrack == nil then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
            local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok then
                return
            end
            if typeof(track) ~= "Instance" then
                return
            end
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            spamTrack = track
        end

        local t = spamTrack
        if not t.IsPlaying then
            pcall(function() t:Play(0, 1, 0) end)
        end
        pcall(function() t:AdjustSpeed(0) end)
        pcall(function() t.TimePosition = 0 end)
        pcall(function() t:AdjustWeight(1, 0) end)
    end

    local function validateClone()
        local cc = cloneCharacter
        if cc == nil then
            return false
        end
        if cc.Parent == nil then
            return false
        end
        if cc:FindFirstChild("HumanoidRootPart") == nil then
            return false
        end
        if cc:FindFirstChildOfClass("Humanoid") == nil then
            return false
        end
        if cc:FindFirstChild("Head") == nil then
            return false
        end
        return true
    end

    local function getCloneAnimator()
        local ca = cloneAnimator
        if ca ~= nil then
            if ca.Parent ~= nil then
                return ca
            end
        end
        local ch = cloneHumanoid
        if ch == nil then
            return nil
        end
        if ch.Parent == nil then
            return nil
        end
        local a = ch:FindFirstChildOfClass("Animator")
        if a == nil then
            a = Instance.new("Animator")
            a.Parent = ch
        end
        cloneAnimator = a
        return a
    end

    local function syncCloneAnimations()
        local character = LocalPlayer.Character
        local cc = cloneCharacter
        if character == nil then
            return
        end
        if cc == nil then
            return
        end
        if cc.Parent == nil then
            return
        end

        local ca = getCloneAnimator()
        if ca == nil then
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then
            return
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then
            return
        end

        local tracks = animator:GetPlayingAnimationTracks()
        local active = {}
        local i = 1
        while i <= #tracks do
            local track = tracks[i]
            local anim = track.Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric ~= SPAM_NUMERIC then
                    active[track] = true
                    local mirror = animationMirrors[track]
                    if mirror == nil then
                        local cloneAnim = Instance.new("Animation")
                        cloneAnim.AnimationId = anim.AnimationId
                        local ok, t = pcall(function() return ca:LoadAnimation(cloneAnim) end)
                        if ok and typeof(t) == "Instance" then
                            mirror = t
                            mirror.Priority = track.Priority
                            mirror.Looped = track.Looped
                            animationMirrors[track] = mirror
                            mirror:Play(0, 1, track.Speed)
                            mirror.TimePosition = track.TimePosition
                        end
                    end
                    local m = mirror
                    if m ~= nil then
                        m.Priority = track.Priority
                        m.Looped = track.Looped
                        if not m.IsPlaying then
                            m:Play(0, 1, track.Speed)
                        end
                        local w = track.WeightCurrent
                        if w < 0.01 then
                            w = 0.01
                        end
                        m:AdjustWeight(w, 0)
                        if abs_(m.Speed - track.Speed) > 0.001 then
                            m:AdjustSpeed(track.Speed)
                        end
                        if m.TimePosition ~= track.TimePosition then
                            m.TimePosition = track.TimePosition
                        end
                    end
                end
            end
            i = i + 1
        end

        local toRemove = {}
        local trackKey, mirrorValue = next(animationMirrors)
        while trackKey ~= nil do
            if not active[trackKey] then
                if mirrorValue.IsPlaying then
                    mirrorValue:Stop(0.05)
                end
                insert_(toRemove, trackKey)
            end
            trackKey, mirrorValue = next(animationMirrors, trackKey)
        end
        local k = 1
        while k <= #toRemove do
            animationMirrors[toRemove[k]] = nil
            k = k + 1
        end
    end

    local function createCloneInner()
        local old = cloneCharacter
        if old ~= nil then
            old:Destroy()
        end
        cloneCharacter = nil
        cloneRoot = nil
        cloneHumanoid = nil
        cloneAnimator = nil
        animationMirrors = {}

        local character = LocalPlayer.Character
        if character == nil then
            return
        end
        if character:FindFirstChild("HumanoidRootPart") == nil then
            return
        end
        if character:FindFirstChildOfClass("Humanoid") == nil then
            return
        end

        local clone = character:Clone()
        if typeof(clone) ~= "Instance" then
            return
        end

        clone.Name = "VisualFocusClone"

        local descendants = clone:GetDescendants()
        local i = 1
        while i <= #descendants do
            local d = descendants[i]
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            elseif d:IsA("Sound") or d:IsA("SoundGroup") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = false
                d.Anchored = false
                d.Massless = true
                local kids = d:GetChildren()
                local k = 1
                while k <= #kids do
                    local kid = kids[k]
                    if kid:IsA("Sound") or kid:IsA("SoundGroup") then
                        kid:Destroy()
                    end
                    k = k + 1
                end
            elseif d:IsA("ProximityPrompt") then
                d.Enabled = false
            end
            i = i + 1
        end

        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid ~= nil then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.AutoRotate = false
            humanoid.PlatformStand = true
            humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            cloneHumanoid = humanoid
            local anim = humanoid:FindFirstChildOfClass("Animator")
            if anim == nil then
                anim = Instance.new("Animator")
                anim.Parent = humanoid
            end
            cloneAnimator = anim
        end

        clone.Parent = Workspace
        cloneCharacter = clone

        local root = clone:FindFirstChild("HumanoidRootPart")
        if root ~= nil and root:IsA("BasePart") then
            cloneRoot = root
        end
    end

    local function createClone()
        local okCreate, errCreate = pcall(function() createCloneInner() end)
        if not okCreate then
            warn("[AutoFarm Clone Error] " .. tostring(errCreate))
        end
    end

    local function getStreak()
        local character = LocalPlayer.Character
        if character == nil then
            return 0
        end
        local v = character:GetAttribute("CurrentStreak")
        if typeof(v) == "number" then
            return v
        end
        return 0
    end

    local function killSelf()
        local character = LocalPlayer.Character
        if character == nil then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then
            return
        end
        if humanoid.Health > 0 then
            if forceHealthConnection ~= nil then
                forceHealthConnection:Disconnect()
                forceHealthConnection = nil
            end
            killFlag = true
            pcall(function() humanoid.Health = 0 end)
            killFlag = false
        end
    end

    local function startThrownWatcher()
        if thrownConnection ~= nil then
            thrownConnection:Disconnect()
        end
        local thrown = Workspace:FindFirstChild("Thrown")
        if thrown == nil then
            return
        end
        thrownConnection = thrown.ChildAdded:Connect(function()
            wait_(THROWN_CLEAR_DELAY)
            pcall(function() thrown:ClearAllChildren() end)
        end)
    end

    local function httpGet(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and typeof(res) == "string" then
            if #res > 0 then
                return res
            end
        end

        if typeof(request) == "function" then
            local ok2, res2 = pcall(function() return request({ Url = url, Method = "GET" }) end)
            if ok2 and typeof(res2) == "table" then
                if typeof(res2.Body) == "string" and #res2.Body > 0 then
                    return res2.Body
                end
                if typeof(res2.body) == "string" and #res2.body > 0 then
                    return res2.body
                end
            end
        end

        if typeof(http_request) == "function" then
            local ok3, res3 = pcall(function() return http_request({ Url = url, Method = "GET" }) end)
            if ok3 and typeof(res3) == "table" then
                if typeof(res3.Body) == "string" and #res3.Body > 0 then
                    return res3.Body
                end
                if typeof(res3.body) == "string" and #res3.body > 0 then
                    return res3.body
                end
            end
        end

        if typeof(syn) == "table" then
            if typeof(syn.request) == "function" then
                local ok4, res4 = pcall(function() return syn.request({ Url = url, Method = "GET" }) end)
                if ok4 and typeof(res4) == "table" then
                    if typeof(res4.Body) == "string" and #res4.Body > 0 then
                        return res4.Body
                    end
                    if typeof(res4.body) == "string" and #res4.body > 0 then
                        return res4.body
                    end
                end
            end
        end

        return nil
    end

    local function fetchServerList()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local response = httpGet(url)
        if response == nil then
            return nil
        end

        local decodeOk, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not decodeOk then
            return nil
        end
        if typeof(data) ~= "table" then
            return nil
        end
        if typeof(data.data) ~= "table" then
            return nil
        end
        return data.data
    end

    local function buildCandidates(servers)
        local candidates = {}
        local currentJob = game.JobId
        local i = 1
        while i <= #servers do
            local s = servers[i]
            if s.id ~= nil and s.id ~= currentJob then
                local playing = s.playing or 0
                local maxP = s.maxPlayers or 0
                if maxP > 0 and playing > 0 and playing < maxP then
                    insert_(candidates, { id = s.id, playing = playing, maxPlayers = maxP })
                end
            end
            i = i + 1
        end
        sort_(candidates, function(a, b)
            return a.playing > b.playing
        end)
        return candidates
    end

    local function ensureTeleportFailListener()
        if teleportFailConnection ~= nil then
            return
        end
        teleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player == LocalPlayer then
                teleportFailedFlag = true
            end
        end)
    end

    local function attemptTeleport(jobId, originalJob)
        teleportFailedFlag = false
        ensureTeleportFailListener()

        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end)
        if not ok then
            return false
        end

        local t0 = clock()
        while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
            if not serverHopEnabled then
                return false
            end
            if hopRequestedStop then
                return false
            end
            wait_(0.05)
            if game.JobId ~= originalJob then
                return true
            end
            if LocalPlayer.Parent == nil then
                return true
            end
            if teleportFailedFlag then
                return false
            end
        end
        return false
    end

    local function queueReexec()
        local code = "loadstring(game:HttpGet(\"" .. REEXEC_URL .. "\"))()"
        pcall(function()
            if typeof(queue_on_teleport) == "function" then
                queue_on_teleport(code)
            elseif typeof(queueonteleport) == "function" then
                queueonteleport(code)
            elseif typeof(QueueOnTeleport) == "function" then
                QueueOnTeleport(code)
            elseif typeof(syn) == "table" then
                if typeof(syn.queue_on_teleport) == "function" then
                    syn.queue_on_teleport(code)
                end
            end
        end)
    end

    local function doServerHop()
        if hopInProgress then
            return
        end
        if not serverHopEnabled then
            return
        end

        hopInProgress = true
        hopRequestedStop = false
        refreshStatus()

        queueReexec()

        local originalJob = game.JobId
        local attempt = 0

        while serverHopEnabled and not hopRequestedStop and hopInProgress and attempt < HOP_MAX_ATTEMPTS do
            attempt = attempt + 1

            local servers = fetchServerList()
            if servers ~= nil then
                local candidates = buildCandidates(servers)
                local tryCount = min_(#candidates, HOP_CANDIDATE_TRY_COUNT)
                local ci = 1
                while ci <= tryCount do
                    if not serverHopEnabled then
                        break
                    end
                    if hopRequestedStop then
                        break
                    end
                    local c = candidates[ci]
                    if attemptTeleport(c.id, originalJob) then
                        return
                    end
                    wait_(0.3)
                    ci = ci + 1
                end
            end

            if not serverHopEnabled then
                break
            end
            if hopRequestedStop then
                break
            end

            if typeof(serverhop) == "function" then
                pcall(serverhop)
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not serverHopEnabled then
                        break
                    end
                    if hopRequestedStop then
                        break
                    end
                    wait_(0.1)
                    if game.JobId ~= originalJob then
                        return
                    end
                    if LocalPlayer.Parent == nil then
                        return
                    end
                end
            end

            if not serverHopEnabled then
                break
            end
            if hopRequestedStop then
                break
            end

            if typeof(ServerHop) == "function" then
                pcall(ServerHop)
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not serverHopEnabled then
                        break
                    end
                    if hopRequestedStop then
                        break
                    end
                    wait_(0.1)
                    if game.JobId ~= originalJob then
                        return
                    end
                    if LocalPlayer.Parent == nil then
                        return
                    end
                end
            end

            if not serverHopEnabled then
                break
            end
            if hopRequestedStop then
                break
            end
            wait_(1)
        end

        hopInProgress = false
        refreshStatus()
    end

    local function targetRootForAlign()
        local target = getTarget()
        if target == nil then
            return nil
        end
        local tc = target.Character
        if tc == nil then
            return nil
        end
        if hasProtection(tc) then
            return nil
        end
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if tr == nil then
            return nil
        end
        if not tr:IsA("BasePart") then
            return nil
        end
        return tr
    end

    local function frameAlignUntil(endTime, getTargetRoot)
        while clock() < endTime do
            if not farmEnabled then
                return true
            end
            if protectionActive then
                return true
            end
            if lowHealthMode then
                return true
            end
            if selfRagdollActive then
                return true
            end
            local root = getRoot()
            if root ~= nil then
                local tr = getTargetRoot()
                if tr ~= nil then
                    setPhysRep(root, tr)
                    root.CFrame = ALIGN_CF
                end
            end
            pressG()
            wait_()
        end
        return false
    end

    local function activateTwinFangs()
        local deadline = clock() + TF_ACTIVATION_TIMEOUT
        while clock() < deadline do
            if not farmEnabled then
                return false
            end
            if protectionActive then
                return false
            end
            if lowHealthMode then
                return false
            end
            if selfRagdollActive then
                return false
            end
            if hotbarHasCooldown(TWIN_FANGS_SLOT) then
                return true
            end
            local tf = findTool(TWIN_FANGS_NAME)
            if tf == nil then
                return false
            end
            activateToolViaRemote(tf)
            local retryEnd = clock() + TF_RETRY_INTERVAL
            while clock() < retryEnd do
                if hotbarHasCooldown(TWIN_FANGS_SLOT) then
                    return true
                end
                local r = getRoot()
                if r ~= nil then
                    local tr = targetRootForAlign()
                    if tr ~= nil then
                        setPhysRep(r, tr)
                        r.CFrame = ALIGN_CF
                    end
                end
                pressG()
                wait_(0.02)
            end
        end
        return hotbarHasCooldown(TWIN_FANGS_SLOT)
    end

    local function runFallbackTools()
        suppressHeartbeatTp = false
        local tools = getAllTools(FALLBACK_EXCLUDE)
        if #tools <= 0 then
            wait_(0.5)
            return
        end
        fallbackIndex = fallbackIndex + 1
        if fallbackIndex > #tools then
            fallbackIndex = 1
        end
        local tool = tools[fallbackIndex]
        activateToolViaRemote(tool)
        frameAlignUntil(clock() + FALLBACK_TOOL_DURATION, targetRootForAlign)
        genericSpam()
    end

    local function rotationStep()
        if not farmEnabled then
            return
        end
        if protectionActive then
            return
        end
        if lowHealthMode then
            return
        end
        if selfRagdollActive then
            return
        end

        suppressHeartbeatTp = false

        local character = LocalPlayer.Character
        if character == nil then
            wait_(0.1)
            return
        end

        local tf = findTool(TWIN_FANGS_NAME)

        if tf == nil then
            runFallbackTools()
            return
        end

        local tfOnCd = hotbarHasCooldown(TWIN_FANGS_SLOT)
        if not tfOnCd then
            local activated = activateTwinFangs()
            if not activated then
                return
            end
            frameAlignUntil(clock() + TF_ALIGN_DURATION, targetRootForAlign)
        end

        if not farmEnabled then
            return
        end
        if protectionActive then
            return
        end
        if lowHealthMode then
            return
        end
        if selfRagdollActive then
            return
        end

        suppressHeartbeatTp = true

        local settleEnd = clock() + TF_BOUNDARY_SETTLE
        while farmEnabled and not protectionActive and not lowHealthMode and not selfRagdollActive do
            if clock() >= settleEnd then
                break
            end
            local r = getRoot()
            if r ~= nil then
                setPhysRep(r, nil)
                r.CFrame = CFrame.new(SAFE_POSITION)
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            wait_()
        end

        if not farmEnabled then
            return
        end
        if protectionActive then
            return
        end
        if lowHealthMode then
            return
        end
        if selfRagdollActive then
            return
        end

        while farmEnabled and not protectionActive and not lowHealthMode and not selfRagdollActive do
            if not hotbarHasCooldown(TWIN_FANGS_SLOT) then
                break
            end
            local r = getRoot()
            if r ~= nil then
                setPhysRep(r, nil)
                r.CFrame = CFrame.new(SAFE_POSITION)
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            wait_()
        end
    end

    local function runRotationLoop()
        if rotationRunning then
            return
        end
        rotationRunning = true
        refreshStatus()

        while farmEnabled and not protectionActive and not lowHealthMode and not selfRagdollActive do
            local ok, err = pcall(function() rotationStep() end)
            if not ok then
                warn("[AutoFarm Rotation Error] " .. tostring(err))
            end
            if ROTATION_LOOP_DELAY > 0 then
                wait_(ROTATION_LOOP_DELAY)
            end
        end

        suppressHeartbeatTp = false
        rotationRunning = false
        refreshStatus()
    end

    local function disconnectCharacterConnections()
        local i = 1
        while i <= #characterConnections do
            local c = characterConnections[i]
            if c ~= nil then
                c:Disconnect()
            end
            i = i + 1
        end
        characterConnections = {}
        watchedTools = {}
    end

    local function watchTool(tool)
        if watchedTools[tool] then
            return
        end
        watchedTools[tool] = true
    end

    local function watchCharacter(character)
        disconnectCharacterConnections()
        targetStates = {}
        cachedBackpack = nil

        local bp = getBackpack()
        if bp ~= nil then
            local bpChildren = bp:GetChildren()
            local i = 1
            while i <= #bpChildren do
                local c = bpChildren[i]
                if c:IsA("Tool") then
                    watchTool(c)
                end
                i = i + 1
            end
            insert_(characterConnections, bp.ChildAdded:Connect(function(c)
                if c:IsA("Tool") then
                    watchTool(c)
                end
            end))
        end

        local charChildren = character:GetChildren()
        local i = 1
        while i <= #charChildren do
            local c = charChildren[i]
            if c:IsA("Tool") then
                watchTool(c)
            end
            i = i + 1
        end
        insert_(characterConnections, character.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                watchTool(c)
            end
        end))

        lastWatchedCharacter = character
        createClone()
        lastCloneRebuild = clock()
    end

    local function updateKillsFromLeaderstats()
        if killsValue ~= nil then
            if killsValue.Parent ~= nil then
                return
            end
        end
        killsValue = nil

        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls == nil then
            return
        end
        local k = ls:FindFirstChild("Kills")
        if k == nil then
            return
        end
        if not k:IsA("IntValue") then
            return
        end

        killsValue = k

        if not configInitialized then
            configInitialized = true
            local live = k.Value
            if not configExisted then
                showsKills = live
            elseif live < showsKills then
                showsKills = live
            end
            persistConfig()
            refreshKillsDisplay()
        end
    end

    insert_(permanentConnections, RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if character == nil then
            return
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil then
            return
        end
        if not root:IsA("BasePart") then
            return
        end

        updateKillsFromLeaderstats()

        local protected = character:FindFirstChild("AbsoluteImmortal") ~= nil
        if protected and not protectionActive then
            protectionOrigin = root.CFrame
            protectionActive = true
            refreshStatus()
        elseif not protected and protectionActive then
            protectionActive = false
            protectionOrigin = nil
            refreshStatus()
        end

        if protectionActive then
            pinToSafeZone(root)
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid ~= nil then
            if humanoid.MaxHealth > 0 then
                local pct = humanoid.Health / humanoid.MaxHealth
                if pct < LOW_HP_THRESHOLD then
                    if not lowHealthMode then
                        lowHealthMode = true
                        refreshStatus()
                    end
                elseif pct >= LOW_HP_THRESHOLD then
                    if lowHealthMode then
                        lowHealthMode = false
                        refreshStatus()
                    end
                end
            end
        end

        if lowHealthMode then
            pinToSafeZone(root)
            return
        end

        local ragdollNow = selfHasRagdoll()
        if ragdollNow ~= selfRagdollActive then
            selfRagdollActive = ragdollNow
            refreshStatus()
        end

        if selfRagdollActive then
            pinToSafeZone(root)
            return
        end

        if stealthMode and farmEnabled then
            if getStreak() >= STEALTH_STREAK_THRESHOLD then
                pinToSafeZone(root)
                killSelf()
                return
            end
        end

        local hopNow = clock()
        if serverHopEnabled and killsValue ~= nil and not hopInProgress then
            if hopNow - lastHopCheck >= HOP_CHECK_INTERVAL then
                lastHopCheck = hopNow
                local live = killsValue.Value
                if live < showsKills then
                    showsKills = live
                    persistConfig()
                    refreshKillsDisplay()
                end
                if (live - showsKills) >= targetKills then
                    spawn_(function()
                        doServerHop()
                        if killsValue ~= nil then
                            showsKills = killsValue.Value
                            persistConfig()
                            refreshKillsDisplay()
                        end
                    end)
                    return
                end
            end
        end

        if farmEnabled then
            pressG()
            genericSpam()

            if not suppressHeartbeatTp then
                local target = getTarget()
                if target ~= nil then
                    local tc = target.Character
                    if tc ~= nil and not hasProtection(tc) then
                        local tr = tc:FindFirstChild("HumanoidRootPart")
                        if tr ~= nil and tr:IsA("BasePart") then
                            setPhysRep(root, tr)
                            root.CFrame = ALIGN_CF
                        end
                    end
                end
            end

            if not rotationRunning then
                spawn_(runRotationLoop)
            end
        end
    end))

    insert_(permanentConnections, RunService.RenderStepped:Connect(function()
        tickSpaceRelease()

        if killsValue ~= nil and killsValue.Parent ~= nil then
            local now = clock()
            if now - lastKillsLabelUpdate > 0.1 then
                lastKillsLabelUpdate = now
                CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
            end
        end

        if performanceMode then
            if thrownConnection == nil then
                startThrownWatcher()
            end
        else
            if thrownConnection ~= nil then
                thrownConnection:Disconnect()
                thrownConnection = nil
            end
        end

        local character = LocalPlayer.Character
        if character ~= lastWatchedCharacter then
            lastWatchedCharacter = character
            if character ~= nil then
                watchCharacter(character)
                refreshStatus()
            end
        end

        local now = clock()
        if now - lastCloneCheck >= CLONE_CHECK_INTERVAL then
            lastCloneCheck = now
            if not validateClone() then
                if (now - lastCloneRebuild) >= CLONE_REBUILD_COOLDOWN then
                    lastCloneRebuild = now
                    createClone()
                end
            end
        end

        ensureInvisible()

        attackingActive = checkAttacking()

        local realRoot = getRoot()
        local cc = cloneCharacter
        if cc ~= nil and cc.Parent ~= nil and realRoot ~= nil then
            if attackingActive then
                local targetRoot = targetRootForAlign()
                if targetRoot ~= nil then
                    cc:PivotTo(targetRoot.CFrame * ALIGN_CF)
                else
                    cc:PivotTo(realRoot.CFrame)
                end
            else
                cc:PivotTo(realRoot.CFrame)
            end
            syncCloneAnimations()
        end

        local cam = Workspace.CurrentCamera
        if cam == nil then
            return
        end

        local cr = cloneRoot
        local followRoot = nil
        if cr ~= nil and cr.Parent ~= nil then
            followRoot = cr
        elseif realRoot ~= nil then
            followRoot = realRoot
        end

        if followRoot == nil then
            if cam.CameraType == Enum.CameraType.Scriptable then
                cam.CameraType = Enum.CameraType.Custom
            end
            return
        end

        cam.CameraType = Enum.CameraType.Scriptable

        local targetPos = followRoot.Position + Vector3.new(0, CAMERA_HEIGHT, 0)
        local rotation = CFrame.fromEulerAnglesYXZ(cameraPitch, cameraYaw, 0)
        local camPos = targetPos - rotation.LookVector * cameraDistance

        cam.CFrame = CFrame.lookAt(camPos, targetPos)
    end))

    insert_(permanentConnections, Players.PlayerRemoving:Connect(function(player)
        local ch = player.Character
        if ch == nil then
            return
        end
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root ~= nil and root:IsA("BasePart") then
            targetStates[root] = nil
        end
    end))

    if LocalPlayer.Character ~= nil then
        lastWatchedCharacter = LocalPlayer.Character
        watchCharacter(LocalPlayer.Character)
    end

    LocalPlayer.CharacterAdded:Connect(function(character)
        rotationRunning = false
        protectionActive = false
        protectionOrigin = nil
        lowHealthMode = false
        selfRagdollActive = false
        attackingActive = false
        spamTrack = nil
        spamTrackCharacter = nil
        cachedBackpack = nil
        spaceDown = false
        lastRagdollFire = 0
        killsValue = nil
        suppressHeartbeatTp = false

        targetStates = {}
        lastWatchedCharacter = character
        watchCharacter(character)
        refreshStatus()
    end)

    refreshKillsDisplay()
end

RUN()
]==]

local loader = loadstring
if typeof(loader) ~= "function" then
    local msg = "LOAD ERROR: loadstring is not available in this executor."
    copyToClipboard(msg)
    notify("Auto Farm - Load Error", msg, 15)
    warn(msg)
    return
end

local loadedFn, loadErr = loader(SCRIPT_SOURCE)
if not loadedFn then
    local msg = "LOAD ERROR (compile-time)\n\n" .. tostring(loadErr)
    copyToClipboard(msg)
    notify("Auto Farm - Load Error", "Compile error copied to clipboard.\n" .. tostring(loadErr):sub(1, 80), 15)
    warn(msg)
    return
end

local ok, runErr = xpcall(loadedFn, function(e)
    local msg = tostring(e)
    local tb = debug.traceback("", 2)
    return msg .. "\n\n" .. tb
end)

if not ok then
    local fullMsg = "RUNTIME ERROR\n\n" .. tostring(runErr)
    local copied = copyToClipboard(fullMsg)
    local preview = tostring(runErr):sub(1, 80)
    if copied then
        notify("Auto Farm - Runtime Error", "Error copied to clipboard.\n" .. preview, 15)
    else
        notify("Auto Farm - Runtime Error", "Error on load.\n" .. preview, 15)
    end
    warn(fullMsg)
    return
end

notify("Auto Farm", "Loaded successfully. Config applied.", 5)