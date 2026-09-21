local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"

local function getExecutorEnv()
    if typeof(getgenv) == "function" then
        local ok, e = pcall(getgenv)
        if ok and typeof(e) == "table" then
            return e
        end
    end
    return _G
end

local function copyToClipboard(text)
    local env = getExecutorEnv()
    local names = { "setclipboard", "toclipboard", "setrbxclipboard", "writeclipboard" }
    for i = 1, #names do
        local n = names[i]
        local fn = env[n]
        if typeof(fn) == "function" then
            if pcall(fn, text) then return true end
        end
        local f2 = _G[n]
        if typeof(f2) == "function" and f2 ~= fn then
            if pcall(f2, text) then return true end
        end
    end
    if typeof(env.syn) == "table" then
        if typeof(env.syn.setclipboard) == "function" then
            if pcall(env.syn.setclipboard, text) then return true end
        end
        if typeof(env.syn.toclipboard) == "function" then
            if pcall(env.syn.toclipboard, text) then return true end
        end
    end
    if typeof(env.clipboard) == "table" and typeof(env.clipboard.set) == "function" then
        if pcall(env.clipboard.set, text) then return true end
    end
    if typeof(writefile) == "function" then
        if pcall(writefile, "autofarm_error.txt", text) then return true end
    end
    return false
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
        })
    end)
end

local function showErrorGui(title, text)
    pcall(function()
        local lp = Players.LocalPlayer
        local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        local sg = Instance.new("ScreenGui")
        sg.Name = "AutoFarmErr_" .. tostring(math.random(1, 999999))
        sg.ResetOnSpawn = false
        sg.Parent = pg
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 520, 0, 420)
        frame.Position = UDim2.new(0.5, -260, 0.5, -210)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        frame.BorderSizePixel = 0
        frame.Parent = sg
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -100, 0, 28)
        titleLbl.Position = UDim2.new(0, 12, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.TextColor3 = Color3.new(1, 1, 1)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 16
        titleLbl.Parent = frame
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 80, 0, 26)
        close.Position = UDim2.new(1, -92, 0, 8)
        close.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        close.BorderSizePixel = 0
        close.Text = "Close"
        close.TextColor3 = Color3.new(1, 1, 1)
        close.Font = Enum.Font.GothamBold
        close.TextSize = 12
        close.Parent = frame
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 6)
        cc.Parent = close
        close.Activated:Connect(function()
            sg:Destroy()
        end)
        local tb = Instance.new("TextBox")
        tb.Size = UDim2.new(1, -24, 1, -56)
        tb.Position = UDim2.new(0, 12, 0, 42)
        tb.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        tb.BorderSizePixel = 0
        tb.TextColor3 = Color3.fromRGB(230, 230, 230)
        tb.Text = text
        tb.TextWrapped = true
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.TextYAlignment = Enum.TextYAlignment.Top
        tb.ClearTextOnFocus = false
        tb.MultiLine = true
        tb.Font = Enum.Font.Code
        tb.TextSize = 12
        tb.Parent = frame
        local tbc = Instance.new("UICorner")
        tbc.CornerRadius = UDim.new(0, 6)
        tbc.Parent = tb
    end)
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

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"

local BOUND_POSITION = Vector3.new(0, -499, 0)
local HEAD_SAFE_POSITION = Vector3.new(0, -400, 0)
local SAFE_OFFSET = Vector3.new(0, 1, 0)

local FOCUS_DISTANCE = 6.3
local TWIN_FANGS_DISTANCE = 6.3

local TWIN_FANGS_TP_DURATION = 2.5
local SAFE_ZONE_DURATION = 2
local TWIN_FANGS_TO_GRAND_GAP = 1.5
local GRAND_FISSURE_WAIT = 10
local FALLBACK_TOOL_DURATION = 1
local ROTATION_LOOP_DELAY = 0.15
local GRAND_FISSURE_ACTIVATION_TIMEOUT = 5
local TWIN_FANGS_ACTIVATION_TIMEOUT = 3
local TABLE_FLIP_ACTIVATION_TIMEOUT = 3
local ACTIVATION_RETRY_INTERVAL = 0.05

local TWIN_FANGS_NAME = "Twin Fangs"
local GRAND_FISSURE_NAME = "Grand Fissure"
local TABLE_FLIP_NAME = "Table Flip"

local TABLE_FLIP_CLUSTER_RADIUS = 50
local TABLE_FLIP_FAR_DISTANCE = 200
local TABLE_FLIP_KEEP_DISTANCE = 200
local TABLE_FLIP_WAIT = 5
local TABLE_FLIP_MIN_CLUSTER = 2
local TABLE_FLIP_REFIRE_COOLDOWN = 15
local TABLE_FLIP_SKY_LIFT = 10

local TWIN_FANGS_SLOT = 2
local GRAND_FISSURE_SLOT = 1
local TABLE_FLIP_SLOT = 3

local SPAM_ANIMATION_ID = "119169968232874"
local SPAM_NUMERIC = SPAM_ANIMATION_ID:match("%d+") or SPAM_ANIMATION_ID

local REMOTE_COOLDOWN = 0.03
local G_INTERVAL = 0.01
local JUMP_INTERVAL = 0.01
local SPACE_HOLD_TIME = 0.03
local RAGDOLL_COOLDOWN = 0.5

local CAMERA_SENSITIVITY = 0.003
local CAMERA_MIN_DIST = 5
local CAMERA_MAX_DIST = 60
local CAMERA_HEIGHT = 3

local CLONE_CHECK_INTERVAL = 0.5
local CLONE_REBUILD_COOLDOWN = 1.5

local HEAD_DISTANCE_THRESHOLD = 6
local FORCEFIELD_MAX_EFFECTIVE = 3
local STEALTH_STREAK_THRESHOLD = 6

local HEAD_SAFE_LOCK_DURATION = 1
local HEAD_SAFE_COOLDOWN = 2.5

local THROWN_CLEAR_DELAY = 0.06

local HOP_CHECK_INTERVAL = 0.5
local HOP_TELEPORT_VERIFY_WAIT = 5

local FALLBACK_EXCLUDE = { TWIN_FANGS_NAME, GRAND_FISSURE_NAME, TABLE_FLIP_NAME }

local G = _G

local function getGuiParent()
    local gethuiFn = G.gethui
    if typeof(gethuiFn) == "function" then
        local ok, result = pcall(gethuiFn)
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
    for i = 1, length do
        local idx = math.random(1, count)
        parts[i] = chars:sub(idx, idx)
    end
    return table.concat(parts)
end

local function readConfig()
    if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(isfile, CONFIG_PATH)
    if not ok or not exists then
        return nil
    end
    local readOk, content = pcall(readfile, CONFIG_PATH)
    if not readOk or not content or content == "" then
        return nil
    end
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not decodeOk or typeof(data) ~= "table" then
        return nil
    end
    return data
end

local function writeConfig(data)
    if typeof(writefile) ~= "function" then
        return
    end
    local encodeOk, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if not encodeOk or not encoded then
        return
    end
    pcall(writefile, CONFIG_PATH, encoded)
end

local function RUN()
    local IS_MOBILE = UserInputService.TouchEnabled

    pcall(function()
        math.randomseed(os.time() + math.random(1, 1000000))
    end)
    pcall(function()
        math.randomseed(tick() * 1000000)
    end)

    local guiParent = getGuiParent()

    local mainSafeName = "P_" .. randomString(14)
    local headSafeName = "P_" .. randomString(14)

    local BoundaryZone = Instance.new("Part")
    BoundaryZone.Name = mainSafeName
    BoundaryZone.Size = Vector3.new(2048, 1, 2048)
    BoundaryZone.CFrame = CFrame.new(BOUND_POSITION)
    BoundaryZone.Anchored = true
    BoundaryZone.CanCollide = true
    BoundaryZone.CanQuery = false
    BoundaryZone.CanTouch = false
    BoundaryZone.Transparency = 0.7
    BoundaryZone.Parent = Workspace

    local HeadSafeZone = Instance.new("Part")
    HeadSafeZone.Name = headSafeName
    HeadSafeZone.Size = Vector3.new(2048, 1, 2048)
    HeadSafeZone.CFrame = CFrame.new(HEAD_SAFE_POSITION)
    HeadSafeZone.Anchored = true
    HeadSafeZone.CanCollide = true
    HeadSafeZone.CanQuery = false
    HeadSafeZone.CanTouch = false
    HeadSafeZone.Transparency = 0.7
    HeadSafeZone.Parent = Workspace

    local saved = readConfig()

    local farmEnabled = false
    local performanceMode = true
    local stealthMode = false
    local serverHopEnabled = false
    local targetKills = 20
    local showsKills = 0

    if saved then
        if typeof(saved.farmEnabled) == "boolean" then farmEnabled = saved.farmEnabled end
        if typeof(saved.performanceMode) == "boolean" then performanceMode = saved.performanceMode end
        if typeof(saved.stealthMode) == "boolean" then stealthMode = saved.stealthMode end
        if typeof(saved.serverHopEnabled) == "boolean" then serverHopEnabled = saved.serverHopEnabled end
        if typeof(saved.targetKills) == "number" then targetKills = saved.targetKills end
    end

    local configInitialized = false

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmPanel"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = guiParent

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.fromOffset(250, 420)
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
    local focusActive = false
    local tableFlipRunning = false
    local tableFlipLastActivation = 0

    local protectionOrigin = nil
    local lastRemoteFire = 0
    local lastGPress = 0
    local lastJumpPress = 0
    local lastRagdollFire = 0

    local headSafeLockUntil = 0
    local headSafeCooldownUntil = 0

    local characterConnections = {}
    local permanentConnections = {}
    local watchedTools = {}

    local targetStates = {}

    local windowDragging = false
    local windowDragStart = Vector2.zero
    local windowStartPos = UDim2.new()

    local cameraYaw = 0
    local cameraPitch = math.rad(-8)
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

    local suppressHeartbeatTp = false

    local function persistConfig()
        writeConfig({
            farmEnabled = farmEnabled,
            performanceMode = performanceMode,
            stealthMode = stealthMode,
            serverHopEnabled = serverHopEnabled,
            targetKills = targetKills,
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

    local function isHeadSafeLocked()
        return os.clock() < headSafeLockUntil
    end

    local function refreshStatus()
        if tableFlipRunning then
            Status.Text = "Mode: Table Flip AI"
        elseif protectionActive then
            Status.Text = "Mode: Protected Zone"
        elseif hopInProgress then
            Status.Text = "Mode: Server Hopping"
        elseif isHeadSafeLocked() then
            Status.Text = "Mode: Head Safe Lock"
        elseif rotationRunning then
            Status.Text = "Mode: Rotation Sequence"
        elseif farmEnabled then
            Status.Text = "Mode: FULL ACTIVE"
        else
            Status.Text = "Mode: Idle"
        end
    end

    local function refreshKillsDisplay()
        ShowsLabel.Text = "Shows Kills: " .. tostring(showsKills)
        if killsValue then
            CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
        else
            CurrentLabel.Text = "Current Kills: 0"
        end
    end

    FarmButton.Activated:Connect(function()
        farmEnabled = not farmEnabled
        setToggle(FarmState, farmEnabled)
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
    end)

    KillsBox.FocusLost:Connect(function()
        local n = tonumber(KillsBox.Text)
        if n and n > 0 then
            targetKills = math.floor(n)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
                cameraPitch = math.clamp(cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY, math.rad(-80), math.rad(80))
            end
        elseif uit == Enum.UserInputType.Touch then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                cameraYaw = cameraYaw - input.Delta.X * CAMERA_SENSITIVITY * 1.4
                cameraPitch = math.clamp(cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY * 1.4, math.rad(-80), math.rad(80))
            end
        elseif uit == Enum.UserInputType.MouseWheel then
            cameraDistance = math.clamp(cameraDistance - input.Position.Z * 2, CAMERA_MIN_DIST, CAMERA_MAX_DIST)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            windowDragging = false
        end
    end)

    local function hasProtection(character)
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then return true end
        if character:FindFirstChild("ForceField") ~= nil then return true end
        if character:FindFirstChild("FinalDeath") ~= nil then return true end
        if character:FindFirstChild("Counter") ~= nil then return true end
        return false
    end

    local function hasSelfProtection(character)
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then return true end
        if character:FindFirstChild("ForceField") ~= nil then return true end
        return false
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if not character then return nil end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return nil end
        return root
    end

    local function getTarget()
        local root = getRoot()
        if not root then return nil end

        local chosen = nil
        local lowestHealth = math.huge

        local players = Players:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if player ~= LocalPlayer then
                local tc = player.Character
                if tc and not hasProtection(tc) then
                    local hum = tc:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local tr = tc:FindFirstChild("HumanoidRootPart")
                        if tr and tr:IsA("BasePart") then
                            if hum.Health < lowestHealth then
                                lowestHealth = hum.Health
                                chosen = player
                            end
                        end
                    end
                end
            end
        end
        return chosen
    end

    local function clearPhysicsRepRootPart(root)
        if not root then return end
        if typeof(sethiddenproperty) ~= "function" then return end
        pcall(sethiddenproperty, root, "PhysicsRepRootPart", nil)
    end

    local function alignBehind(root, targetRoot, distance)
        if isHeadSafeLocked() then return end
        if not root or not targetRoot then return end

        if typeof(sethiddenproperty) == "function" then
            pcall(sethiddenproperty, root, "PhysicsRepRootPart", targetRoot)
        end

        local tpos = targetRoot.Position
        if tpos ~= tpos then return end
        local behindDir = -targetRoot.CFrame.LookVector
        local pos = tpos + behindDir * distance
        if pos ~= pos then return end

        root.CFrame = CFrame.lookAt(pos, tpos)
        root.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
        root.AssemblyAngularVelocity = targetRoot.AssemblyAngularVelocity
    end

    local function teleportTo(root, worldPos)
        clearPhysicsRepRootPart(root)
        local pos = worldPos + SAFE_OFFSET
        root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, -100, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function teleportToSafeZone(root)
        if isHeadSafeLocked() then return end
        teleportTo(root, BOUND_POSITION)
    end

    local function teleportToHeadSafe(root)
        teleportTo(root, HEAD_SAFE_POSITION)
    end

    local function teleportToBoundaryUnconditional(root)
        teleportTo(root, BOUND_POSITION)
    end

    local function countForceFields(character)
        local count = 0
        local children = character:GetChildren()
        for i = 1, #children do
            if children[i]:IsA("ForceField") then
                count = count + 1
            end
        end
        return count
    end

    local function effectiveForceFields(character)
        local raw = countForceFields(character)
        if raw <= 0 then return 0 end
        return raw - 1
    end

    local function pressKey(code)
        VirtualInputManager:SendKeyEvent(true, code, false, game)
        VirtualInputManager:SendKeyEvent(false, code, false, game)
    end

    local function pressG()
        local now = os.clock()
        if now - lastGPress < G_INTERVAL then return end
        lastGPress = now
        pressKey(Enum.KeyCode.G)
    end

    local function pressJump()
        local now = os.clock()
        if now - lastJumpPress < JUMP_INTERVAL then return end
        lastJumpPress = now
        if not spaceDown then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            spaceDown = true
            spaceDownAt = now
        end
    end

    local function tickSpaceRelease()
        if spaceDown and os.clock() - spaceDownAt >= SPACE_HOLD_TIME then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            spaceDown = false
        end
    end

    local function getCommunicate()
        local character = LocalPlayer.Character
        if not character then return nil end
        local comm = character:FindFirstChild("Communicate")
        if not comm or not comm:IsA("RemoteEvent") then return nil end
        return comm
    end

    local function getMouseCFrame()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local mp = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mp.X, mp.Y)
        return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction * 1000)
    end

    local function fireCommunicate()
        local now = os.clock()
        if now - lastRemoteFire < REMOTE_COOLDOWN then return end
        lastRemoteFire = now
        local comm = getCommunicate()
        if not comm then return end
        local mouseCF = getMouseCFrame()
        if not mouseCF then return end
        comm:FireServer({
            Mobile = IS_MOBILE,
            Goal = "LeftClick",
            MousePos = mouseCF,
        })
    end

    local function activateToolViaRemote(tool)
        local comm = getCommunicate()
        if not comm then return end
        comm:FireServer({
            Tool = tool,
            Goal = "Console Move",
            IsAutoActivate = true,
        })
    end

    local function fireRagdollFinish()
        local comm = getCommunicate()
        if not comm then return end
        local mouseCF = getMouseCFrame()
        if not mouseCF then return end
        comm:FireServer({
            Dash = Enum.KeyCode.W,
            Key = Enum.KeyCode.Q,
            Goal = "KeyPress",
            MousePos = mouseCF,
        })
    end

    local function tryFireRagdollFinish()
        local now = os.clock()
        if now - lastRagdollFire < RAGDOLL_COOLDOWN then return end
        local target = getTarget()
        if not target then return end
        local tc = target.Character
        if not tc then return end
        if tc:FindFirstChild("Ragdoll") == nil then return end
        lastRagdollFire = now
        fireRagdollFinish()
    end

    local function getBackpack()
        if cachedBackpack and cachedBackpack.Parent then return cachedBackpack end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp and bp:IsA("Backpack") then
            cachedBackpack = bp
            return bp
        end
        return nil
    end

    local function findTool(name)
        local target = string.lower(name)
        local bp = getBackpack()
        if bp then
            local children = bp:GetChildren()
            for i = 1, #children do
                local c = children[i]
                if c:IsA("Tool") and string.lower(c.Name) == target then
                    return c
                end
            end
        end
        local ch = LocalPlayer.Character
        if ch then
            local children = ch:GetChildren()
            for i = 1, #children do
                local c = children[i]
                if c:IsA("Tool") and string.lower(c.Name) == target then
                    return c
                end
            end
        end
        return nil
    end

    local function getAllTools(exclude)
        local excl = {}
        for i = 1, #exclude do
            excl[string.lower(exclude[i])] = true
        end

        local result = {}
        local bp = getBackpack()
        if bp then
            local children = bp:GetChildren()
            for i = 1, #children do
                local c = children[i]
                if c:IsA("Tool") and not excl[string.lower(c.Name)] then
                    table.insert(result, c)
                end
            end
        end
        local ch = LocalPlayer.Character
        if ch then
            local children = ch:GetChildren()
            for i = 1, #children do
                local c = children[i]
                if c:IsA("Tool") and not excl[string.lower(c.Name)] then
                    table.insert(result, c)
                end
            end
        end
        return result
    end

    local function twinFangsExists()
        return findTool(TWIN_FANGS_NAME) ~= nil
    end

    local function genericSpam()
        if twinFangsExists() then return end
        pressJump()
        fireCommunicate()
        tryFireRagdollFinish()
    end

    local function hotbarHasCooldown(slot)
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return false end
        local hotbar = pg:FindFirstChild("Hotbar")
        if not hotbar then return false end
        local bp = hotbar:FindFirstChild("Backpack")
        if not bp then return false end
        local slots = bp:FindFirstChild("Hotbar")
        if not slots then return false end
        local frame = slots:FindFirstChild(tostring(slot))
        if not frame then return false end
        local base = frame:FindFirstChild("Base")
        if not base then return false end
        return base:FindFirstChild("Cooldown") ~= nil
    end

    local function activateToolAndVerify(tool, slot, timeout)
        local start = os.clock()
        while os.clock() - start < timeout do
            if not farmEnabled then return false end
            if isHeadSafeLocked() then return false end

            activateToolViaRemote(tool)

            local waited = 0
            while waited < ACTIVATION_RETRY_INTERVAL do
                if not farmEnabled then return false end
                if isHeadSafeLocked() then return false end
                if hotbarHasCooldown(slot) then return true end
                local step = math.min(0.01, ACTIVATION_RETRY_INTERVAL - waited)
                task.wait(step)
                waited = waited + step
            end
        end
        return hotbarHasCooldown(slot)
    end

    local function ensureInvisible()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        if spamTrackCharacter ~= character then
            if spamTrack then
                pcall(function()
                    spamTrack:Stop(0)
                end)
            end
            spamTrack = nil
            spamTrackCharacter = character
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
            local ok, track = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            if ok and typeof(track) == "Instance" then
                track.Priority = Enum.AnimationPriority.Action4
                track.Looped = false
                spamTrack = track
            end
        end
        local t = spamTrack
        if not t then return end
        if not t.IsPlaying then
            t:Play(0, 1, 0)
        end
        if t.Speed ~= 0 then
            t:AdjustSpeed(0)
        end
        if t.TimePosition ~= 0 then
            t.TimePosition = 0
        end
        if t.WeightCurrent < 0.99 then
            t:AdjustWeight(1, 0)
        end
    end

    local function validateClone()
        local cc = cloneCharacter
        if not cc or not cc.Parent then return false end
        if not cc:FindFirstChild("HumanoidRootPart") then return false end
        if not cc:FindFirstChildOfClass("Humanoid") then return false end
        if not cc:FindFirstChild("Head") then return false end
        return true
    end

    local function syncCloneAnimations()
        local character = LocalPlayer.Character
        local cc = cloneCharacter
        if not character or not cc or not cc.Parent then return end

        local ca = cloneAnimator
        if not ca or not ca.Parent then
            local ch = cloneHumanoid
            if ch and ch.Parent then
                local a = ch:FindFirstChildOfClass("Animator")
                if not a then
                    a = Instance.new("Animator")
                    a.Parent = ch
                end
                ca = a
                cloneAnimator = a
            else
                return
            end
        end
        if not ca then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        local tracks = animator:GetPlayingAnimationTracks()
        local active = {}

        for i = 1, #tracks do
            local track = tracks[i]
            local anim = track.Animation
            if anim then
                local numeric = anim.AnimationId:match("%d+")
                if numeric ~= SPAM_NUMERIC then
                    active[track] = true
                    local mirror = animationMirrors[track]
                    if not mirror then
                        local cloneAnim = Instance.new("Animation")
                        cloneAnim.AnimationId = anim.AnimationId
                        local ok, t = pcall(function()
                            return ca:LoadAnimation(cloneAnim)
                        end)
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
                    if m then
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
                        if math.abs(m.Speed - track.Speed) > 0.001 then
                            m:AdjustSpeed(track.Speed)
                        end
                        if m.TimePosition ~= track.TimePosition then
                            m.TimePosition = track.TimePosition
                        end
                    end
                end
            end
        end

        for track, mirror in pairs(animationMirrors) do
            if not active[track] then
                if mirror.IsPlaying then
                    mirror:Stop(0.05)
                end
                animationMirrors[track] = nil
            end
        end
    end

    local function createClone()
        local old = cloneCharacter
        if old then
            old:Destroy()
        end
        cloneCharacter = nil
        cloneRoot = nil
        cloneHumanoid = nil
        cloneAnimator = nil
        animationMirrors = {}

        local character = LocalPlayer.Character
        if not character then return end
        if not character:FindFirstChild("HumanoidRootPart") then return end
        if not character:FindFirstChildOfClass("Humanoid") then return end

        local ok, clone = pcall(function()
            return character:Clone()
        end)
        if not ok or typeof(clone) ~= "Instance" then return end

        clone.Name = "VisualFocusClone"

        local descendants = clone:GetDescendants()
        for i = 1, #descendants do
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
                for k = 1, #kids do
                    local kid = kids[k]
                    if kid:IsA("Sound") or kid:IsA("SoundGroup") then
                        kid:Destroy()
                    end
                end
            elseif d:IsA("ProximityPrompt") then
                d.Enabled = false
            end
        end

        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.AutoRotate = false
            humanoid.PlatformStand = true
            humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            cloneHumanoid = humanoid
            local anim = humanoid:FindFirstChildOfClass("Animator")
            if not anim then
                anim = Instance.new("Animator")
                anim.Parent = humanoid
            end
            cloneAnimator = anim
        end

        clone.Parent = Workspace
        cloneCharacter = clone

        local root = clone:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            cloneRoot = root
        end
    end

    local function getStreak()
        local character = LocalPlayer.Character
        if not character then return 0 end
        local v = character:GetAttribute("CurrentStreak")
        if typeof(v) == "number" then
            return v
        end
        return 0
    end

    local function killSelf()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        if humanoid.Health > 0 then
            pcall(function()
                humanoid.Health = 0
            end)
        end
    end

    local function headTooClose()
        local character = LocalPlayer.Character
        if not character then return false end
        local realHead = character:FindFirstChild("Head")
        if not realHead or not realHead:IsA("BasePart") then return false end
        local cc = cloneCharacter
        if not cc or not cc.Parent then return false end
        local cloneHead = cc:FindFirstChild("Head")
        if not cloneHead or not cloneHead:IsA("BasePart") then return false end
        return (realHead.Position - cloneHead.Position).Magnitude <= HEAD_DISTANCE_THRESHOLD
    end

    local function startThrownWatcher()
        if thrownConnection then
            thrownConnection:Disconnect()
        end
        local thrown = Workspace:FindFirstChild("Thrown")
        if not thrown then return end
        thrownConnection = thrown.ChildAdded:Connect(function()
            task.wait(THROWN_CLEAR_DELAY)
            pcall(function()
                thrown:ClearAllChildren()
            end)
        end)
    end

    local function fetchServerList()
        local ok, response = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
        end)
        if not ok or not response or response == "" then
            return nil
        end

        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if not decodeOk or typeof(data) ~= "table" or typeof(data.data) ~= "table" then
            return nil
        end

        return data.data
    end

    local function buildCandidates(servers)
        local candidates = {}
        for i = 1, #servers do
            local s = servers[i]
            if s.id and s.id ~= game.JobId then
                local playing = s.playing or 0
                local maxP = s.maxPlayers or 0
                if maxP > 0 and playing > 0 and playing <= (maxP - 1) then
                    table.insert(candidates, {
                        id = s.id,
                        playing = playing,
                        maxPlayers = maxP,
                    })
                end
            end
        end
        table.sort(candidates, function(a, b)
            local aTarget = a.maxPlayers * 0.75
            local bTarget = b.maxPlayers * 0.75
            local aDiff = math.abs(a.playing - aTarget)
            local bDiff = math.abs(b.playing - bTarget)
            return aDiff < bDiff
        end)
        return candidates
    end

    local function doServerHop()
        if hopInProgress then return end
        hopInProgress = true
        refreshStatus()
        persistConfig()

        local code = "loadstring(game:HttpGet(\"" .. REEXEC_URL .. "\"))()"
        local queued = false

        if typeof(queue_on_teleport) == "function" then
            local ok, res = pcall(queue_on_teleport, code)
            if ok and res ~= false then queued = true end
        end
        if not queued and typeof(queueonteleport) == "function" then
            local ok, res = pcall(queueonteleport, code)
            if ok and res ~= false then queued = true end
        end
        if not queued and typeof(QueueOnTeleport) == "function" then
            local ok, res = pcall(QueueOnTeleport, code)
            if ok and res ~= false then queued = true end
        end

        local originalJob = game.JobId
        local attempt = 0

        while serverHopEnabled and hopInProgress and attempt < 10 do
            attempt = attempt + 1

            local leftServer = false

            local servers = fetchServerList()
            if servers then
                local candidates = buildCandidates(servers)
                if #candidates > 0 then
                    local c = candidates[1]
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, c.id, LocalPlayer)
                    end)
                end
            end

            local waited = 0
            while waited < HOP_TELEPORT_VERIFY_WAIT do
                task.wait(0.5)
                waited = waited + 0.5
                if game.JobId ~= originalJob then
                    leftServer = true
                    break
                end
            end

            if leftServer then
                return
            end

            if typeof(serverhop) == "function" then
                pcall(serverhop)
                local waited2 = 0
                while waited2 < HOP_TELEPORT_VERIFY_WAIT do
                    task.wait(0.5)
                    waited2 = waited2 + 0.5
                    if game.JobId ~= originalJob then
                        return
                    end
                end
            end

            if typeof(TeleportService.Teleport) == "function" then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                local waited3 = 0
                while waited3 < HOP_TELEPORT_VERIFY_WAIT do
                    task.wait(0.5)
                    waited3 = waited3 + 0.5
                    if game.JobId ~= originalJob then
                        return
                    end
                end
            end

            task.wait(1)
        end

        hopInProgress = false
        refreshStatus()
    end

    local function findPlayerClusters()
        local positions = {}
        local players = Players:GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p ~= LocalPlayer then
                local ch = p.Character
                if ch and not hasProtection(ch) then
                    local hum = ch:FindFirstChildOfClass("Humanoid")
                    local root = ch:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root and root:IsA("BasePart") then
                        positions[#positions + 1] = { pos = root.Position, player = p }
                    end
                end
            end
        end

        local clusters = {}
        local used = {}
        local radiusSq = TABLE_FLIP_CLUSTER_RADIUS * TABLE_FLIP_CLUSTER_RADIUS

        for i = 1, #positions do
            if used[i] then
                continue
            end
            local cluster = { positions[i] }
            used[i] = true
            local changed = true
            while changed do
                changed = false
                for j = 1, #positions do
                    if not used[j] then
                        for k = 1, #cluster do
                            local diff = cluster[k].pos - positions[j].pos
                            if diff:Dot(diff) <= radiusSq then
                                cluster[#cluster + 1] = positions[j]
                                used[j] = true
                                changed = true
                                break
                            end
                        end
                    end
                end
            end
            clusters[#clusters + 1] = cluster
        end

        table.sort(clusters, function(a, b) return #a > #b end)
        return clusters
    end

    local function getClusterCenter(cluster)
        local sum = Vector3.zero
        for i = 1, #cluster do
            sum = sum + cluster[i].pos
        end
        return sum / #cluster
    end

    local function aimAtCluster(root, center)
        if not root or not root.Parent then return end
        local flat = Vector3.new(center.X, root.Position.Y, center.Z)
        local diff = flat - root.Position
        if diff:Dot(diff) < 0.0001 then return end
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end

    local function keepDistanceFromCluster(root, center)
        if not root or not root.Parent then return end

        local currentPos = root.Position

        local dx = currentPos.X - center.X
        local dz = currentPos.Z - center.Z
        local horizDist = math.sqrt(dx * dx + dz * dz)

        local targetY = currentPos.Y

        local finalPos
        if horizDist < 0.001 then
            finalPos = Vector3.new(
                center.X + TABLE_FLIP_KEEP_DISTANCE,
                targetY,
                center.Z
            )
        else
            local ux = dx / horizDist
            local uz = dz / horizDist
            finalPos = Vector3.new(
                center.X + ux * TABLE_FLIP_KEEP_DISTANCE,
                targetY,
                center.Z + uz * TABLE_FLIP_KEEP_DISTANCE
            )
        end

        root.CFrame = CFrame.lookAt(finalPos, Vector3.new(center.X, targetY, center.Z))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function liftRootIntoAir(root, amount)
        if not root or not root.Parent then return end
        local pos = root.Position + Vector3.new(0, amount, 0)
        local look = root.CFrame.LookVector
        root.CFrame = CFrame.lookAt(pos, pos + look)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function runTableFlipMode()
        if tableFlipRunning then return end
        tableFlipRunning = true
        refreshStatus()

        while farmEnabled do
            if findTool(TWIN_FANGS_NAME) then
                break
            end
            if not findTool(TABLE_FLIP_NAME) then
                break
            end

            local root = getRoot()
            if not root then
                task.wait(0.2)
                continue
            end

            local clusters = findPlayerClusters()
            if #clusters == 0 then
                task.wait(0.5)
                continue
            end

            local best = clusters[1]
            if #best < TABLE_FLIP_MIN_CLUSTER then
                task.wait(0.5)
                continue
            end

            local center = getClusterCenter(best)

            local dx = root.Position.X - center.X
            local dz = root.Position.Z - center.Z
            local dist = math.sqrt(dx * dx + dz * dz)

            if not isHeadSafeLocked() then
                aimAtCluster(root, center)
            end

            if dist > TABLE_FLIP_FAR_DISTANCE then
                if not isHeadSafeLocked() then
                    keepDistanceFromCluster(root, center)
                    root = getRoot()
                end

                if os.clock() - tableFlipLastActivation < TABLE_FLIP_REFIRE_COOLDOWN then
                    task.wait(0.5)
                    continue
                end

                local tf = findTool(TABLE_FLIP_NAME)
                if tf then
                    tableFlipLastActivation = os.clock()

                    local r = getRoot()
                    if r then
                        liftRootIntoAir(r, TABLE_FLIP_SKY_LIFT)
                    end

                    local ok = activateToolAndVerify(tf, TABLE_FLIP_SLOT, TABLE_FLIP_ACTIVATION_TIMEOUT)
                    if not ok then
                        task.wait(0.3)
                    end

                    local waitEnd = os.clock() + TABLE_FLIP_WAIT
                    while os.clock() < waitEnd and farmEnabled do
                        local r2 = getRoot()
                        if r2 and not isHeadSafeLocked() then
                            keepDistanceFromCluster(r2, center)
                        end
                        local remaining = waitEnd - os.clock()
                        if remaining <= 0 then break end
                        task.wait(math.min(remaining, 0.03))
                    end

                    if not farmEnabled then break end
                    break
                end
            else
                if not isHeadSafeLocked() then
                    keepDistanceFromCluster(root, center)
                end
                task.wait(0.2)
            end
        end

        tableFlipRunning = false
        refreshStatus()
    end

    local function runRotationLoop()
        if rotationRunning or protectionActive then return end
        rotationRunning = true
        refreshStatus()

        while farmEnabled and not protectionActive do
            if tableFlipRunning then break end

            suppressHeartbeatTp = false

            if findTool(TABLE_FLIP_NAME) and not findTool(TWIN_FANGS_NAME) then
                break
            end

            if isHeadSafeLocked() then
                refreshStatus()
                task.wait(0.05)
                continue
            end

            local character = LocalPlayer.Character
            if not character then break end

            local tf = findTool(TWIN_FANGS_NAME)

            if tf then
                local effective = effectiveForceFields(character)
                local skipWait = stealthMode and (effective >= FORCEFIELD_MAX_EFFECTIVE)
                local alreadyOnCooldown = hotbarHasCooldown(TWIN_FANGS_SLOT)

                if not skipWait and not alreadyOnCooldown then
                    local verified = activateToolAndVerify(tf, TWIN_FANGS_SLOT, TWIN_FANGS_ACTIVATION_TIMEOUT)

                    if not verified then
                        task.wait(0.3)
                        continue
                    end

                    if not farmEnabled or protectionActive then break end
                    if tableFlipRunning then break end
                    if isHeadSafeLocked() then continue end

                    local tpEnd = os.clock() + TWIN_FANGS_TP_DURATION
                    while os.clock() < tpEnd do
                        if not farmEnabled or protectionActive then break end
                        if tableFlipRunning then break end
                        if isHeadSafeLocked() then break end

                        local root = getRoot()
                        if root then
                            local target = getTarget()
                            if target then
                                local tc = target.Character
                                if tc then
                                    local tr = tc:FindFirstChild("HumanoidRootPart")
                                    if tr and tr:IsA("BasePart") and not hasProtection(tc) then
                                        alignBehind(root, tr, TWIN_FANGS_DISTANCE)
                                    end
                                end
                            end
                        end

                        pressG()

                        local remaining = tpEnd - os.clock()
                        if remaining <= 0 then break end
                        task.wait(math.min(remaining, 1 / 120))
                    end
                end

                if not farmEnabled or protectionActive then break end
                if tableFlipRunning then break end
                if isHeadSafeLocked() then
                    task.wait(0.05)
                    continue
                end

                suppressHeartbeatTp = true

                local root = getRoot()
                if not root then break end
                local originCFrame = root.CFrame

                teleportToSafeZone(root)

                local safeEnd = os.clock() + SAFE_ZONE_DURATION
                while os.clock() < safeEnd do
                    if not farmEnabled or protectionActive then break end
                    if tableFlipRunning then break end
                    if isHeadSafeLocked() then break end
                    teleportToSafeZone(root)
                    pressG()
                    local remaining = safeEnd - os.clock()
                    if remaining <= 0 then break end
                    task.wait(math.min(remaining, 1 / 120))
                end

                if not farmEnabled or protectionActive then break end
                if tableFlipRunning then break end
                if isHeadSafeLocked() then
                    task.wait(0.05)
                    continue
                end

                if root and root.Parent and not isHeadSafeLocked() then
                    root.CFrame = originCFrame
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end

                local gapEnd = os.clock() + TWIN_FANGS_TO_GRAND_GAP
                while os.clock() < gapEnd do
                    if not farmEnabled or protectionActive then break end
                    if tableFlipRunning then break end
                    if isHeadSafeLocked() then break end
                    pressG()
                    local remaining = gapEnd - os.clock()
                    if remaining <= 0 then break end
                    task.wait(math.min(remaining, 1 / 120))
                end

                if not farmEnabled or protectionActive then break end
                if tableFlipRunning then break end
                if isHeadSafeLocked() then
                    task.wait(0.05)
                    continue
                end

                local gf = findTool(GRAND_FISSURE_NAME)
                if gf then
                    local gfVerified = activateToolAndVerify(gf, GRAND_FISSURE_SLOT, GRAND_FISSURE_ACTIVATION_TIMEOUT)
                    if not gfVerified then
                        task.wait(0.3)
                        continue
                    end
                end

                if not farmEnabled or protectionActive then break end
                if tableFlipRunning then break end
                if isHeadSafeLocked() then
                    task.wait(0.05)
                    continue
                end

                local gfWaitEnd = os.clock() + GRAND_FISSURE_WAIT
                while os.clock() < gfWaitEnd do
                    if not farmEnabled or protectionActive then break end
                    if tableFlipRunning then break end
                    if isHeadSafeLocked() then break end
                    pressG()
                    local remaining = gfWaitEnd - os.clock()
                    if remaining <= 0 then break end
                    task.wait(math.min(remaining, 1 / 120))
                end
            else
                suppressHeartbeatTp = false

                local tools = getAllTools(FALLBACK_EXCLUDE)
                if #tools == 0 then break end

                for ti = 1, #tools do
                    if not farmEnabled or protectionActive then break end
                    if tableFlipRunning then break end
                    if isHeadSafeLocked() then break end
                    local tool = tools[ti]
                    activateToolViaRemote(tool)
                    local fbEnd = os.clock() + FALLBACK_TOOL_DURATION
                    while os.clock() < fbEnd do
                        if not farmEnabled or protectionActive then break end
                        if tableFlipRunning then break end
                        if isHeadSafeLocked() then break end
                        local root = getRoot()
                        if root then
                            local target = getTarget()
                            if target then
                                local tc = target.Character
                                if tc then
                                    local tr = tc:FindFirstChild("HumanoidRootPart")
                                    if tr and tr:IsA("BasePart") and not hasProtection(tc) then
                                        alignBehind(root, tr, FOCUS_DISTANCE)
                                    end
                                end
                            end
                        end
                        pressG()
                        genericSpam()
                        local remaining = fbEnd - os.clock()
                        if remaining <= 0 then break end
                        task.wait(math.min(remaining, 1 / 120))
                    end
                end
            end

            task.wait(ROTATION_LOOP_DELAY)
        end

        rotationRunning = false
        refreshStatus()
    end

    local function processFocusAssist()
        if not farmEnabled or rotationRunning or protectionActive then
            focusActive = false
            return
        end
        if tableFlipRunning then
            focusActive = false
            return
        end
        if isHeadSafeLocked() then
            focusActive = false
            return
        end
        if suppressHeartbeatTp then
            focusActive = false
            return
        end
        local root = getRoot()
        if not root then
            focusActive = false
            return
        end
        local target = getTarget()
        if not target then
            focusActive = false
            return
        end
        local tc = target.Character
        if not tc then
            focusActive = false
            return
        end
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if not tr or not tr:IsA("BasePart") or hasProtection(tc) then
            focusActive = false
            return
        end
        alignBehind(root, tr, FOCUS_DISTANCE)
        focusActive = true
    end

    local function disconnectCharacterConnections()
        for i = 1, #characterConnections do
            local c = characterConnections[i]
            if c then
                c:Disconnect()
            end
        end
        characterConnections = {}
        watchedTools = {}
    end

    local function watchTool(tool)
        if watchedTools[tool] then return end
        watchedTools[tool] = true
    end

    local function watchCharacter(character)
        disconnectCharacterConnections()
        targetStates = {}
        cachedBackpack = nil

        local bp = getBackpack()
        if bp then
            local bpChildren = bp:GetChildren()
            for i = 1, #bpChildren do
                local c = bpChildren[i]
                if c:IsA("Tool") then
                    watchTool(c)
                end
            end
            table.insert(characterConnections, bp.ChildAdded:Connect(function(c)
                if c:IsA("Tool") then
                    watchTool(c)
                end
            end))
        end

        local charChildren = character:GetChildren()
        for i = 1, #charChildren do
            local c = charChildren[i]
            if c:IsA("Tool") then
                watchTool(c)
            end
        end
        table.insert(characterConnections, character.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                watchTool(c)
            end
        end))

        lastWatchedCharacter = character
        createClone()
        lastCloneRebuild = os.clock()
    end

    local function updateKillsFromLeaderstats()
        if killsValue and killsValue.Parent then
            return
        end

        killsValue = nil

        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if not ls then
            return
        end

        local k = ls:FindFirstChild("Kills")
        if not k or not k:IsA("IntValue") then
            return
        end

        killsValue = k

        if not configInitialized then
            configInitialized = true
            showsKills = k.Value
            persistConfig()
            refreshKillsDisplay()
        end
    end

    table.insert(permanentConnections, RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local root = getRoot()
        if not root then return end

        updateKillsFromLeaderstats()

        if farmEnabled and not tableFlipRunning then
            if hasSelfProtection(character) then
                if not protectionActive then
                    protectionActive = true
                    suppressHeartbeatTp = true
                    protectionOrigin = root.CFrame
                end
                teleportToBoundaryUnconditional(root)
                refreshStatus()
                return
            elseif protectionActive then
                protectionActive = false
                suppressHeartbeatTp = false
                if protectionOrigin then
                    root.CFrame = protectionOrigin
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    protectionOrigin = nil
                end
                refreshStatus()
            end
        end

        if farmEnabled then
            local now = os.clock()

            if headTooClose() and now >= headSafeCooldownUntil then
                headSafeLockUntil = now + HEAD_SAFE_LOCK_DURATION
                headSafeCooldownUntil = now + HEAD_SAFE_COOLDOWN
            end

            if now < headSafeLockUntil and not tableFlipRunning then
                teleportToHeadSafe(root)
                refreshStatus()
                return
            end
        end

        if stealthMode and farmEnabled and not tableFlipRunning then
            if getStreak() >= STEALTH_STREAK_THRESHOLD then
                teleportToBoundaryUnconditional(root)
                killSelf()
                return
            end
        end

        local hopNow = os.clock()
        if serverHopEnabled and killsValue and not hopInProgress then
            if hopNow - lastHopCheck >= HOP_CHECK_INTERVAL then
                lastHopCheck = hopNow
                local live = killsValue.Value

                if live < showsKills then
                    showsKills = live
                    persistConfig()
                    refreshKillsDisplay()
                end

                if (live - showsKills) >= targetKills then
                    task.spawn(function()
                        doServerHop()
                        if killsValue then
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
            if tableFlipRunning then
                return
            end

            local hasTwinFangs = findTool(TWIN_FANGS_NAME) ~= nil
            local hasTableFlip = findTool(TABLE_FLIP_NAME) ~= nil

            if hasTwinFangs then
                pressG()
                genericSpam()
                if not rotationRunning then
                    task.spawn(runRotationLoop)
                end
                processFocusAssist()
            elseif hasTableFlip then
                task.spawn(runTableFlipMode)
            else
                pressG()
                genericSpam()
                if not rotationRunning then
                    task.spawn(runRotationLoop)
                end
                processFocusAssist()
            end
        else
            focusActive = false
        end
    end))

    table.insert(permanentConnections, RunService.Heartbeat:Connect(function()
        if not farmEnabled then return end
        if isHeadSafeLocked() then return end
        if suppressHeartbeatTp then return end
        if rotationRunning then return end
        if tableFlipRunning then return end
        if protectionActive then return end

        local character = LocalPlayer.Character
        if not character then return end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return end

        local target = getTarget()
        if not target then return end

        local tc = target.Character
        if not tc then return end
        if hasProtection(tc) then return end

        local tr = tc:FindFirstChild("HumanoidRootPart")
        if not tr or not tr:IsA("BasePart") then return end

        alignBehind(root, tr, FOCUS_DISTANCE)
    end))

    table.insert(permanentConnections, RunService.RenderStepped:Connect(function()
        tickSpaceRelease()

        if killsValue and killsValue.Parent then
            CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
        end

        if performanceMode then
            if not thrownConnection then
                startThrownWatcher()
            end
        else
            if thrownConnection then
                thrownConnection:Disconnect()
                thrownConnection = nil
            end
        end

        local character = LocalPlayer.Character
        if character ~= lastWatchedCharacter then
            lastWatchedCharacter = character
            if character then
                watchCharacter(character)
                refreshStatus()
            end
        end

        local now = os.clock()
        if now - lastCloneCheck >= CLONE_CHECK_INTERVAL then
            lastCloneCheck = now
            if not validateClone() and (now - lastCloneRebuild) >= CLONE_REBUILD_COOLDOWN then
                lastCloneRebuild = now
                createClone()
            end
        end

        ensureInvisible()

        local realRoot = getRoot()
        local cc = cloneCharacter
        if cc and cc.Parent and realRoot then
            if not isHeadSafeLocked() then
                cc:PivotTo(realRoot.CFrame)
            end
            syncCloneAnimations()
        end

        local cam = Workspace.CurrentCamera
        if not cam then return end

        local cr = cloneRoot
        local followRoot = nil
        if cr and cr.Parent then
            followRoot = cr
        elseif realRoot then
            followRoot = realRoot
        end

        if not followRoot then
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

    table.insert(permanentConnections, Players.PlayerRemoving:Connect(function(player)
        local ch = player.Character
        if not ch then return end
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            targetStates[root] = nil
        end
    end))

    if LocalPlayer.Character then
        lastWatchedCharacter = LocalPlayer.Character
        watchCharacter(LocalPlayer.Character)
    end

    LocalPlayer.CharacterAdded:Connect(function(character)
        rotationRunning = false
        protectionActive = false
        protectionOrigin = nil
        focusActive = false
        tableFlipRunning = false
        spamTrack = nil
        spamTrackCharacter = nil
        cachedBackpack = nil
        spaceDown = false
        lastRagdollFire = 0
        headSafeLockUntil = 0
        headSafeCooldownUntil = 0
        killsValue = nil
        suppressHeartbeatTp = false
        tableFlipLastActivation = 0

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
    local ok = copyToClipboard(msg)
    if not ok then
        showErrorGui("Auto Farm - Load Error", msg)
    end
    notify("Auto Farm - Load Error", msg, 15)
    return
end

local loadedFn, loadErr = loader(SCRIPT_SOURCE)
if not loadedFn then
    local msg = "LOAD ERROR (compile-time)\n\n" .. tostring(loadErr)
    local ok = copyToClipboard(msg)
    if not ok then
        showErrorGui("Auto Farm - Compile Error", msg)
    end
    notify("Auto Farm - Compile Error", "Error shown in window (clipboard failed).", 20)
    return
end

local ok, runErr = xpcall(loadedFn, function(e)
    local msg = tostring(e)
    local tb = ""
    if typeof(debug) == "table" and typeof(debug.traceback) == "function" then
        local ok2, res = pcall(debug.traceback, "", 2)
        if ok2 and typeof(res) == "string" then
            tb = "\n\n" .. res
        end
    end
    return msg .. tb
end)

if not ok then
    local msg = "RUNTIME ERROR\n\n" .. tostring(runErr)
    local copied = copyToClipboard(msg)
    if not copied then
        showErrorGui("Auto Farm - Runtime Error", msg)
    end
    notify("Auto Farm - Runtime Error", copied and "Copied to clipboard." or "Shown in window.", 20)
    return
end

notify("Auto Farm", "Loaded successfully. Config applied.", 5)