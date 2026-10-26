local StarterGui = game:GetService("StarterGui")

if _G.__AUTO_FARM_WRAPPER_ACTIVE == true then return end
_G.__AUTO_FARM_WRAPPER_ACTIVE = true

local function notify(title, text, duration)
    pcall(function() StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration }) end)
end

local function copyToClipboard(text)
    if type(text) ~= "string" then text = tostring(text) end
    local clipped = false
    if type(toclipboard) == "function" then
        local ok = pcall(function() toclipboard(text) end)
        if ok then clipped = true end
    end
    if not clipped then
        if type(setclipboard) == "function" then
            local ok2 = pcall(function() setclipboard(text) end)
            if ok2 then clipped = true end
        end
    end
    return clipped
end

notify("Auto Farm", "Wrapper started. Compiling...", 4)

local SCRIPT_SOURCE = [==[
do
    local cleanupWorkspace = game:GetService("Workspace")
    local cleanupSoundService = game:GetService("SoundService")
    local cleanupReplicatedStorage = game:GetService("ReplicatedStorage")
    local cleanupReplicatedFirst = game:GetService("ReplicatedFirst")
    local cleanupPlayers = game:GetService("Players")

    local function isInsideLocalCharacter(instance)
        local localPlayer = cleanupPlayers.LocalPlayer
        if localPlayer == nil then return false end
        local character = localPlayer.Character
        if character == nil then return false end
        local current = instance
        while current ~= nil do
            if current == character then return true end
            current = current.Parent
        end
        return false
    end

    local function nukeInstance(instance)
        local className = instance.ClassName
        if className == "Sound" then instance.Enabled = false instance.Volume = 0 pcall(function() instance.Playing = false end) return end
        if className == "SoundGroup" then instance.Volume = 0 return end
        if className == "ParticleEmitter" then instance.Enabled = false return end
        if className == "Beam" then instance.Enabled = false return end
        if className == "Trail" then instance.Enabled = false return end
        if className == "Fire" then instance.Enabled = false return end
        if className == "Smoke" then instance.Enabled = false return end
        if className == "Sparkles" then instance.Enabled = false return end
        if className == "Explosion" then instance.Visible = false instance.BlastPressure = 0 instance.BlastRadius = 0 return end
        if className == "PointLight" then instance.Enabled = false return end
        if className == "SpotLight" then instance.Enabled = false return end
        if className == "SurfaceLight" then instance.Enabled = false return end
        if className == "Highlight" then instance.Enabled = false return end
        if className == "SelectionBox" then instance.Visible = false return end
        if className == "SelectionSphere" then instance.Visible = false return end
    end

    local function cleanContainer(root)
        pcall(function()
            for _, descendant in ipairs(root:GetDescendants()) do
                if not isInsideLocalCharacter(descendant) then pcall(nukeInstance, descendant) end
            end
        end)
        root.DescendantAdded:Connect(function(descendant)
            if isInsideLocalCharacter(descendant) then return end
            pcall(nukeInstance, descendant)
        end)
    end

    pcall(function() cleanContainer(cleanupWorkspace) end)
    pcall(function() cleanContainer(cleanupSoundService) end)
    pcall(function() cleanContainer(cleanupReplicatedStorage) end)
    pcall(function() cleanContainer(cleanupReplicatedFirst) end)
    pcall(function() cleanupWorkspace.Map.Benchs:Destroy() end)
    pcall(function() cleanupWorkspace.Map.Trash:Destroy() end)
    pcall(function() cleanupWorkspace.Map.Trees:Destroy() end)
    pcall(function() cleanupWorkspace.Map.Walls:Destroy() end)
    pcall(function() cleanupWorkspace.Preload:Destroy() end)
    pcall(function() setfpscap(10000) end)
end

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"
local HOP_QUEUE_FLAG = "autofarm_queued.flag"

if _G.__AUTO_FARM_INNER_ACTIVE == true then return end
if typeof(isfile) == "function" and isfile(HOP_QUEUE_FLAG) then
    pcall(function() if typeof(delfile) == "function" then delfile(HOP_QUEUE_FLAG) end end)
end
_G.__AUTO_FARM_INNER_ACTIVE = true

local LocalPlayer = Players.LocalPlayer

local ALIGN_CF = CFrame.new(0, 0, 6)
local SPECIAL_ANIM_IDS = { ["136370737633649"] = true, ["18182425133"] = true }
local FORCE_VOID_ANIM_IDS = { ["94638356008696"] = true, ["115484690572880"] = true, ["95034083206292"] = true }
local DETECT_ANIM_ID = "17799224866"
local DETECT_TIME_MIN = 1.5
local DETECT_TIME_MAX = 3

local sethiddenFn = nil
if typeof(sethiddenproperty) == "function" then
    sethiddenFn = sethiddenproperty
elseif typeof(syn) == "table" and typeof(syn.sethiddenproperty) == "function" then
    sethiddenFn = syn.sethiddenproperty
end
if sethiddenFn ~= nil then
    local ok = pcall(function() sethiddenFn(Workspace, "FallenPartsDestroyHeight", 0/0) end)
    if not ok then sethiddenFn = nil end
end
if sethiddenFn ~= nil then
    pcall(function() sethiddenFn(workspace, "StreamingEnabled", false) end)
end

local function setPhysicsRepRootPart(root, target)
    if sethiddenFn == nil then return end
    pcall(function() sethiddenFn(root, "PhysicsRepRootPart", target) end)
end

local function forceFallenHeight()
    pcall(function() Workspace.FallenPartsDestroyHeight = 0/0 end)
    if sethiddenFn ~= nil then
        pcall(function() sethiddenFn(Workspace, "FallenPartsDestroyHeight", 0/0) end)
    end
end

forceFallenHeight()

RunService.Heartbeat:Connect(function()
    local fallenHeight = Workspace.FallenPartsDestroyHeight
    if fallenHeight == fallenHeight then forceFallenHeight() end
end)

local forceHealthConnection = nil
local forceHealthTrackedCharacter = nil
local killFlag = false

local function setupForceHealth(character)
    if character == nil then return end
    if character == forceHealthTrackedCharacter then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid == nil then return end
    forceHealthTrackedCharacter = character
    pcall(function() humanoid.BreakJointsOnDeath = false humanoid.RequiresNeck = false end)
    if forceHealthConnection ~= nil then forceHealthConnection:Disconnect() forceHealthConnection = nil end
    pcall(function() humanoid.MaxHealth = 100 humanoid.Health = 100 end)
    forceHealthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if killFlag then return end
        pcall(function() humanoid.MaxHealth = 100 humanoid.Health = 100 end)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    forceFallenHeight()
    setupForceHealth(character)
    task.spawn(function()
        task.wait(0.5)
        if character == nil then return end
        if character.Parent == nil then return end
        local absoluteImmortal = character:FindFirstChild("AbsoluteImmortal")
        if absoluteImmortal ~= nil then pcall(function() absoluteImmortal:Destroy() end) end
        local forceField = character:FindFirstChild("ForceField")
        if forceField ~= nil then pcall(function() forceField:Destroy() end) end
    end)
    task.spawn(function() task.wait(1.5) forceFallenHeight() setupForceHealth(character) end)
    task.spawn(function() task.wait(2.5) forceFallenHeight() setupForceHealth(character) end)
end)

local BOUND_POSITION = Vector3.new(0, -506, 0)
local SAFE_POSITION = Vector3.new(0, -503, 0)
local VOID_Y_THRESHOLD = -400
local VOID_STAY_DURATION = 1
local PIN_SAFE_Y_MAX = 350
local TWIN_FANGS_NAME = "Twin Fangs"
local TWIN_FANGS_SLOT = 2
local CROWD_BUSTER_NAME = "Crowd Buster"
local HAMMER_HEEL_NAME = "Hammer Heel"
local BINDING_CLOTH_NAME = "Binding Cloth"
local GRAND_FISSURE_NAME = "Grand Fissure"
local GRAND_FISSURE_SLOT = 1
local TF_ALIGN_DURATION = 2.2
local TF_ACTIVATION_TIMEOUT = 3.0
local TF_RETRY_INTERVAL = 0.1
local VOID_KILL_DELAY = 2.5
local RESPAWN_G_GRACE = 1.5
local LOW_HP_THRESHOLD = 0.2
local LOW_HP_TARGET_FALLBACK_THRESHOLD = 0.25
local TARGET_SWITCH_DELAY = 0.025
local ANTI_MODE_COLOR = Color3.fromRGB(255, 120, 60)
local VOID_ZONE_COLOR = Color3.fromRGB(150, 100, 255)
local VOID_KILLING_COLOR = Color3.fromRGB(200, 80, 255)
local FARMING_KILLS_COLOR = Color3.fromRGB(80, 230, 130)
local DEFAULT_MODE_COLOR = Color3.fromRGB(170, 170, 180)
local SPAM_ANIMATION_ID = "107114358965793"
local SPAM_TIME_POSITION = 18
local SPAM_NUMERIC = string.match(SPAM_ANIMATION_ID, "%d+") or SPAM_ANIMATION_ID
local SPAM_NUMBER = tonumber(SPAM_NUMERIC)
local LTM_VALUE = 0.5
local LTM_PART_NAMES = {
    "Head", "Torso", "UpperTorso", "LowerTorso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local LTM_PART_SET = {}
for _, partName in ipairs(LTM_PART_NAMES) do LTM_PART_SET[partName] = true end

local G_INTERVAL = 0.01
local JUMP_INTERVAL = 0.01
local SPACE_HOLD_TIME = 0.03
local RAGDOLL_COOLDOWN = 0.5
local REMOTE_COOLDOWN = 0.2
local EMOTE_SPIN_MIN_INTERVAL = 0.02
local CAMERA_SENSITIVITY = 0.003
local CAMERA_MIN_DIST = 5
local CAMERA_MAX_DIST = 60
local STEALTH_STREAK_THRESHOLD = 6
local STEALTH_VOID_WAIT = 1.0
local THROWN_CLEAR_DELAY = 0.06
local HOP_CHECK_INTERVAL = 0.5
local HOP_TELEPORT_VERIFY_WAIT = 5
local HOP_MAX_ATTEMPTS = 5
local HOP_CANDIDATE_TRY_COUNT = 3
local HOP_FAILURE_COOLDOWN = 30
local PROXIMITY_PRIORITY_RANGE = 50
local MOBILE_UI_SCALE = 0.75
local PROT_CACHE_TTL = 0.03
local TF_CACHE_TTL = 0.1
local HOTBAR_CACHE_TTL = 0.05
local SPECIAL_ANIM_CACHE_TTL = 0.05
local TARGET_CACHE_TTL = 0.03
local GF_SPAM_TIMEOUT = 5.0
local GF_STAY_TIMEOUT = 10.0
local GF_MIN_STAY_AFTER_USE = 0.5

local function getGuiParent()
    local gethuiFn = _G.gethui
    if typeof(gethuiFn) == "function" then
        local ok, result = pcall(function() return gethuiFn() end)
        if ok and typeof(result) == "Instance" then return result end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function randomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local charsCount = #chars
    local parts = {}
    local i = 1
    while i <= length do
        local idx = math.random(1, charsCount)
        parts[i] = string.sub(chars, idx, idx)
        i = i + 1
    end
    return table.concat(parts)
end

local function readConfig()
    if typeof(isfile) ~= "function" then return nil end
    if typeof(readfile) ~= "function" then return nil end
    if not isfile(CONFIG_PATH) then return nil end
    local ok, content = pcall(readfile, CONFIG_PATH)
    if not ok or content == nil or content == "" then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or typeof(data) ~= "table" then return nil end
    return data
end

local function writeConfig(data)
    if typeof(writefile) ~= "function" then return end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok or encoded == nil then return end
    pcall(writefile, CONFIG_PATH, encoded)
end

local function RUN()
    local IS_MOBILE = UserInputService.TouchEnabled
    math.randomseed(os.time() + math.random(1, 1e6))
    local guiParent = getGuiParent()

    do
        local boundaryPart = Instance.new("Part")
        boundaryPart.Name = "P_" .. randomString(14)
        boundaryPart.Size = Vector3.new(2048, 1, 2048)
        boundaryPart.CFrame = CFrame.new(BOUND_POSITION)
        boundaryPart.Anchored = true
        boundaryPart.CanCollide = true
        boundaryPart.CanQuery = false
        boundaryPart.CanTouch = false
        boundaryPart.Transparency = 0.7
        boundaryPart.Parent = Workspace
    end

    local saved = readConfig()

    local Config = {
        farmEnabled = false,
        performanceMode = true,
        noRenderEnabled = true,
        stealthMode = false,
        serverHopEnabled = false,
        autoHopKills = false,
        targetKills = 20,
        showsKills = 0,
        initialized = false,
    }

    if saved ~= nil then
        if typeof(saved.farmEnabled) == "boolean" then Config.farmEnabled = saved.farmEnabled end
        if typeof(saved.performanceMode) == "boolean" then Config.performanceMode = saved.performanceMode end
        if typeof(saved.noRenderEnabled) == "boolean" then Config.noRenderEnabled = saved.noRenderEnabled end
        if typeof(saved.stealthMode) == "boolean" then Config.stealthMode = saved.stealthMode end
        if typeof(saved.serverHopEnabled) == "boolean" then Config.serverHopEnabled = saved.serverHopEnabled end
        if typeof(saved.autoHopKills) == "boolean" then Config.autoHopKills = saved.autoHopKills end
        if typeof(saved.targetKills) == "number" then Config.targetKills = saved.targetKills end
        if typeof(saved.showsKills) == "number" then Config.showsKills = saved.showsKills end
    end

    local State = {
        ProtectionActive = false,
        RotationRunning = false,
        LowHealthMode = false,
        SelfRagdollActive = false,
        SpecialAnimActive = false,
        ForceVoidActive = false,
        DetectAnimVoidActive = false,
        DetectAnimVoidLatch = false,
        VoidKillingActive = false,
        VoidKillingCounting = false,
        StealthResetPhase = false,
        HopInProgress = false,
        HopRequestedStop = false,
        SuppressHeartbeatTeleport = false,
        InOriginPhase = false,
        TeleportFailedFlag = false,
        WindowDragging = false,
        SpaceDown = false,
        VoidKillingTimerStart = 0,
        RespawnGraceUntil = 0,
        StealthResetAt = 0,
        LastRemoteFire = 0,
        LastEmoteSpin = 0,
        LastFallbackFire = 0,
        LastGPress = 0,
        LastJumpPress = 0,
        LastRagdollFire = 0,
        LastKillsLabelUpdate = 0,
        LastStatsUpdate = 0,
        LastStatusRefresh = 0,
        FallbackIndex = 0,
        LastHopCheck = 0,
        LastHopAttempt = -1e9,
        SpaceDownAt = 0,
        CurrentFps = 60,
        FpsCounter = 0,
        LastFpsSample = 0,
        CameraYaw = 0,
        CameraPitch = math.rad(-8),
        CameraDistance = 20,
        LastSetupCharacter = nil,
        LastTargetPlayer = nil,
        PendingTargetPlayer = nil,
        TargetSwitchLockUntil = 0,
        WindowDragStart = nil,
        WindowStartPosition = nil,
        SpamAnimationTrack = nil,
        SpamAnimationTrackCharacter = nil,
        CachedBackpack = nil,
        CachedBackpackParent = nil,
        ThrownConnection = nil,
        KillsValue = nil,
        TeleportFailConnection = nil,
        RootCacheCharacter = nil,
        RootCacheValue = nil,
        LastStatusText = nil,
        LastStatusColor = nil,
        Motor6DList = {},
        CharacterConnections = {},
        StripConnections = {},
        PermanentConnections = {},
        WatchedTools = {},
    }

    local Cache = {
        TwinFangsTime = 0,
        TwinFangsValue = false,
        HotbarTime = {},
        HotbarValue = {},
        SpecialAnimTime = 0,
        SpecialAnimValue = false,
        ForceVoidTime = 0,
        ForceVoidValue = false,
        CrowdBusterTime = 0,
        CrowdBusterValue = false,
        ProtectionData = setmetatable({}, {__mode = "k"}),
        TargetTime = 0,
        TargetValue = nil,
        DetectTime = 0,
        DetectValue = false,
    }

    local Puppet = {
        Model = nil,
        Animator = nil,
        CharacterReference = nil,
        AnimationPlayedConnection = nil,
        BuildTarget = nil,
        MotorMap = {},
        TrackMap = {},
    }

    local LocalTransparency = {
        AppliedParts = {},
        EnforcerConnection = nil,
        DescendantConnection = nil,
    }

    local GuiElements = {}

    local Functions = {
        TwinFangsExists = nil,
        CrowdBusterExists = nil,
        HotbarHasCooldown = nil,
    }

    local refreshStatus
    local refreshKillsDisplay

    local function applyNoRender()
        pcall(function() RunService:Set3dRenderingEnabled(not Config.noRenderEnabled) end)
    end
    applyNoRender()

    RunService.RenderStepped:Connect(function()
        State.FpsCounter = State.FpsCounter + 1
        local deltaTime = os.clock() - State.LastFpsSample
        if deltaTime >= 1 then
            local measuredFps = State.FpsCounter / deltaTime
            if measuredFps < 5 then measuredFps = 5 end
            if measuredFps > 240 then measuredFps = 240 end
            State.CurrentFps = measuredFps
            State.FpsCounter = 0
            State.LastFpsSample = os.clock()
        end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmPanel"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = guiParent
    if IS_MOBILE then
        local uiScale = Instance.new("UIScale")
        uiScale.Scale = MOBILE_UI_SCALE
        uiScale.Parent = ScreenGui
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.fromOffset(220, 450)
    Main.Position = UDim2.new(0.5, -110, 0.5, -225)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui
    GuiElements.Main = Main

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 11)
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 22)),
    }
    mainGradient.Rotation = 90
    mainGradient.Parent = Main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 1.2
    mainStroke.Transparency = 0.35
    mainStroke.Parent = Main

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 230, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255)),
    }
    strokeGradient.Rotation = 45
    strokeGradient.Parent = mainStroke

    task.spawn(function()
        while Main.Parent ~= nil do
            strokeGradient.Rotation = (strokeGradient.Rotation + 2) % 360
            task.wait(0.05)
        end
    end)

    local mainScale = Instance.new("UIScale")
    mainScale.Scale = 0.9
    mainScale.Parent = Main
    TweenService:Create(mainScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    local mainPadding = Instance.new("UIPadding")
    mainPadding.PaddingTop = UDim.new(0, 10)
    mainPadding.PaddingBottom = UDim.new(0, 10)
    mainPadding.PaddingLeft = UDim.new(0, 10)
    mainPadding.PaddingRight = UDim.new(0, 10)
    mainPadding.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Farm"
    Title.TextColor3 = Color3.fromRGB(240, 245, 255)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main
    GuiElements.Title = Title

    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(110, 200, 255)
    titleStroke.Thickness = 1
    titleStroke.Transparency = 0.55
    titleStroke.Parent = Title

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 16)
    Status.Position = UDim2.fromOffset(0, 28)
    Status.BackgroundTransparency = 1
    Status.RichText = true
    Status.Text = '<font color="rgb(170,170,180)">●</font> Mode: Idle'
    Status.TextColor3 = DEFAULT_MODE_COLOR
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main
    GuiElements.Status = Status

    task.spawn(function()
        while Status.Parent ~= nil do
            local statusText = State.LastStatusText or "Mode: Idle"
            local statusColor = State.LastStatusColor or DEFAULT_MODE_COLOR
            local pulse = 0.8 + math.sin(os.clock() * 2.5) * 0.2
            local red = math.floor(statusColor.R * 255 * pulse + 0.5)
            local green = math.floor(statusColor.G * 255 * pulse + 0.5)
            local blue = math.floor(statusColor.B * 255 * pulse + 0.5)
            Status.Text = string.format('<font color="rgb(%d,%d,%d)">●</font> %s', red, green, blue, statusText)
            task.wait(0.06)
        end
    end)

    local badgeStrokes = {}

    local function createToggle(name, text, position)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, 0, 0, 38)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.Parent = Main
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(62, 62, 74)
        buttonStroke.Thickness = 1
        buttonStroke.Transparency = 0.4
        buttonStroke.Parent = button

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(225, 228, 235)
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button

        local stateLabel = Instance.new("TextLabel")
        stateLabel.Name = "State"
        stateLabel.Size = UDim2.fromOffset(46, 22)
        stateLabel.Position = UDim2.new(1, -52, 0.5, -11)
        stateLabel.BackgroundColor3 = Color3.fromRGB(52, 52, 60)
        stateLabel.BorderSizePixel = 0
        stateLabel.Text = "OFF"
        stateLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
        stateLabel.TextSize = 10
        stateLabel.Font = Enum.Font.GothamBold
        stateLabel.Parent = button
        Instance.new("UICorner", stateLabel).CornerRadius = UDim.new(0, 6)

        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Color = Color3.fromRGB(80, 220, 140)
        badgeStroke.Thickness = 0
        badgeStroke.Transparency = 1
        badgeStroke.Parent = stateLabel
        badgeStrokes[stateLabel] = badgeStroke

        local baseBackground = Color3.fromRGB(32, 32, 40)
        local hoverBackground = Color3.fromRGB(44, 44, 54)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverBackground}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = baseBackground}):Play()
        end)

        local pressScale = Instance.new("UIScale")
        pressScale.Scale = 1
        pressScale.Parent = button
        button.MouseButton1Down:Connect(function()
            TweenService:Create(pressScale, TweenInfo.new(0.08), {Scale = 0.96}):Play()
        end)
        button.MouseButton1Up:Connect(function()
            TweenService:Create(pressScale, TweenInfo.new(0.12), {Scale = 1}):Play()
        end)

        return {
            Button = button,
            State = stateLabel,
        }
    end

    local farmToggle = createToggle("AutoFarmToggle", "Auto Farm", UDim2.fromOffset(0, 48))
    local performanceToggle = createToggle("PerformanceToggle", "Performance Mode", UDim2.fromOffset(0, 89))
    local noRenderToggle = createToggle("NoRenderToggle", "No Render", UDim2.fromOffset(0, 130))
    local stealthToggle = createToggle("StealthToggle", "Stealth Mode", UDim2.fromOffset(0, 171))
    local hopToggle = createToggle("ServerHopToggle", "Server Hop", UDim2.fromOffset(0, 212))
    local autoHopToggle = createToggle("AutoHopKillsToggle", "Auto Hop Kills", UDim2.fromOffset(0, 253))

    local farmButton = farmToggle.Button
    local farmState = farmToggle.State
    local performanceButton = performanceToggle.Button
    local performanceState = performanceToggle.State
    local noRenderButton = noRenderToggle.Button
    local noRenderState = noRenderToggle.State
    local stealthButton = stealthToggle.Button
    local stealthState = stealthToggle.State
    local hopButton = hopToggle.Button
    local hopState = hopToggle.State
    local autoHopButton = autoHopToggle.Button
    local autoHopState = autoHopToggle.State

    GuiElements.FarmState = farmState
    GuiElements.PerformanceState = performanceState
    GuiElements.NoRenderState = noRenderState
    GuiElements.StealthState = stealthState
    GuiElements.HopState = hopState
    GuiElements.AutoHopState = autoHopState

    local KillsRow = Instance.new("Frame")
    KillsRow.Size = UDim2.new(1, 0, 0, 26)
    KillsRow.Position = UDim2.fromOffset(0, 295)
    KillsRow.BackgroundTransparency = 1
    KillsRow.Parent = Main

    local KillsLabel = Instance.new("TextLabel")
    KillsLabel.Size = UDim2.new(0.55, 0, 1, 0)
    KillsLabel.BackgroundTransparency = 1
    KillsLabel.Text = "Hop Kills:"
    KillsLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
    KillsLabel.TextSize = 12
    KillsLabel.Font = Enum.Font.GothamMedium
    KillsLabel.TextXAlignment = Enum.TextXAlignment.Left
    KillsLabel.Parent = KillsRow

    local KillsBox = Instance.new("TextBox")
    KillsBox.Size = UDim2.new(0.45, 0, 1, 0)
    KillsBox.Position = UDim2.new(0.55, 0, 0, 0)
    KillsBox.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    KillsBox.BorderSizePixel = 0
    KillsBox.Text = tostring(Config.targetKills)
    KillsBox.TextColor3 = Color3.fromRGB(240, 245, 255)
    KillsBox.TextSize = 12
    KillsBox.Font = Enum.Font.GothamMedium
    KillsBox.PlaceholderText = "20"
    KillsBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    KillsBox.ClearTextOnFocus = false
    KillsBox.Parent = KillsRow
    Instance.new("UICorner", KillsBox).CornerRadius = UDim.new(0, 6)

    local killsStroke = Instance.new("UIStroke")
    killsStroke.Color = Color3.fromRGB(62, 62, 74)
    killsStroke.Thickness = 1
    killsStroke.Transparency = 0.4
    killsStroke.Parent = KillsBox
    GuiElements.KillsBox = KillsBox

    KillsBox.Focused:Connect(function()
        TweenService:Create(KillsBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(46, 46, 58)}):Play()
        TweenService:Create(killsStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(120, 200, 255), Transparency = 0.1}):Play()
    end)
    KillsBox.FocusLost:Connect(function()
        TweenService:Create(KillsBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(32, 32, 40)}):Play()
        TweenService:Create(killsStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(62, 62, 74), Transparency = 0.4}):Play()
        local parsedValue = tonumber(KillsBox.Text)
        if parsedValue ~= nil and parsedValue > 0 then Config.targetKills = math.floor(parsedValue) end
        KillsBox.Text = tostring(Config.targetKills)
        persistConfig()
    end)

    local ShowsLabel = Instance.new("TextLabel")
    ShowsLabel.Size = UDim2.new(1, 0, 0, 15)
    ShowsLabel.Position = UDim2.fromOffset(0, 323)
    ShowsLabel.BackgroundTransparency = 1
    ShowsLabel.Text = "Shows Kills: 0"
    ShowsLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    ShowsLabel.TextSize = 11
    ShowsLabel.Font = Enum.Font.Gotham
    ShowsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowsLabel.Parent = Main
    GuiElements.ShowsLabel = ShowsLabel

    local CurrentLabel = Instance.new("TextLabel")
    CurrentLabel.Size = UDim2.new(1, 0, 0, 15)
    CurrentLabel.Position = UDim2.fromOffset(0, 340)
    CurrentLabel.BackgroundTransparency = 1
    CurrentLabel.Text = "Current Kills: 0"
    CurrentLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    CurrentLabel.TextSize = 11
    CurrentLabel.Font = Enum.Font.Gotham
    CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentLabel.Parent = Main
    GuiElements.CurrentLabel = CurrentLabel

    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Size = UDim2.new(1, 0, 0, 52)
    WarningLabel.Position = UDim2.fromOffset(0, 357)
    WarningLabel.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
    WarningLabel.BackgroundTransparency = 0.15
    WarningLabel.BorderSizePixel = 0
    WarningLabel.Text = "Stealth: no G key, no ultimate. Only basic attacks. Auto-resets via void on high streak."
    WarningLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
    WarningLabel.TextSize = 10
    WarningLabel.Font = Enum.Font.GothamMedium
    WarningLabel.TextWrapped = true
    WarningLabel.Visible = false
    WarningLabel.Parent = Main
    Instance.new("UICorner", WarningLabel).CornerRadius = UDim.new(0, 8)
    GuiElements.WarningLabel = WarningLabel

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, 0, 0, 20)
    StatsLabel.Position = UDim2.fromOffset(0, 413)
    StatsLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    StatsLabel.BackgroundTransparency = 0.15
    StatsLabel.BorderSizePixel = 0
    StatsLabel.RichText = true
    StatsLabel.Text = 'Ping <font color="rgb(150,200,255)">0</font> ms  <font color="rgb(80,80,100)">|</font>  Fps <font color="rgb(150,255,180)">60</font>'
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    StatsLabel.TextSize = 11
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.Parent = Main
    Instance.new("UICorner", StatsLabel).CornerRadius = UDim.new(0, 6)
    GuiElements.StatsLabel = StatsLabel

    local function applyLTMToPart(part)
        if part == nil or not part:IsA("BasePart") then return end
        local ok = pcall(function() part.LocalTransparencyModifier = LTM_VALUE end)
        if ok then LocalTransparency.AppliedParts[part] = true end
    end

    local function isInAccessory(part, character)
        local current = part.Parent
        while current ~= nil and current ~= character do
            if current:IsA("Accessory") or current:IsA("Hat") then return true end
            current = current.Parent
        end
        return false
    end

    local function shouldApplyLTM(part, character)
        if part == nil or not part:IsA("BasePart") then return false end
        if LTM_PART_SET[part.Name] then return true end
        if character ~= nil and isInAccessory(part, character) then return true end
        return false
    end

    local function scanAndApplyLTM(character)
        if character == nil then return end
        for _, descendant in ipairs(character:GetDescendants()) do
            if shouldApplyLTM(descendant, character) then applyLTMToPart(descendant) end
        end
    end

    local function restoreAllLTM()
        for part in pairs(LocalTransparency.AppliedParts) do
            if part ~= nil and part.Parent ~= nil then
                pcall(function() part.LocalTransparencyModifier = 0 end)
            end
        end
        LocalTransparency.AppliedParts = {}
    end

    local function connectLTMDescendantWatcher(character)
        if LocalTransparency.DescendantConnection ~= nil then LocalTransparency.DescendantConnection:Disconnect() LocalTransparency.DescendantConnection = nil end
        if character == nil then return end
        LocalTransparency.DescendantConnection = character.DescendantAdded:Connect(function(descendant)
            if shouldApplyLTM(descendant, character) then
                task.defer(function() applyLTMToPart(descendant) end)
            end
        end)
    end

    local function startLTMEnforcer()
        if LocalTransparency.EnforcerConnection ~= nil then return end
        LocalTransparency.EnforcerConnection = RunService.RenderStepped:Connect(function()
            local character = LocalPlayer.Character
            if character == nil then return end
            for _, descendant in ipairs(character:GetDescendants()) do
                if shouldApplyLTM(descendant, character) then
                    if descendant.LocalTransparencyModifier ~= LTM_VALUE then
                        pcall(function() descendant.LocalTransparencyModifier = LTM_VALUE end)
                    end
                    LocalTransparency.AppliedParts[descendant] = true
                end
            end
        end)
    end

    local function destroyPuppet()
        if Puppet.AnimationPlayedConnection ~= nil then pcall(function() Puppet.AnimationPlayedConnection:Disconnect() end) Puppet.AnimationPlayedConnection = nil end
        if Puppet.Model ~= nil and Puppet.Model.Parent ~= nil then pcall(function() Puppet.Model:Destroy() end) end
        Puppet.Model = nil Puppet.Animator = nil Puppet.CharacterReference = nil
        Puppet.MotorMap = {} Puppet.TrackMap = {}
    end

    local function mirrorTrack(realTrack)
        if Puppet.Animator == nil then return end
        if Puppet.TrackMap[realTrack] ~= nil then return end
        local numericId = tonumber(string.match(realTrack.Animation.AnimationId, "%d+"))
        if numericId == SPAM_NUMBER then return end
        local newAnimation = Instance.new("Animation")
        newAnimation.AnimationId = realTrack.Animation.AnimationId
        local puppetTrack = Puppet.Animator:LoadAnimation(newAnimation)
        pcall(function()
            puppetTrack.Priority = realTrack.Priority
            puppetTrack.Looped = realTrack.Looped
            puppetTrack:Play(0, realTrack.WeightCurrent, realTrack.Speed)
            puppetTrack.TimePosition = realTrack.TimePosition
        end)
        Puppet.TrackMap[realTrack] = puppetTrack
        realTrack.Stopped:Connect(function()
            pcall(function() puppetTrack:Stop(0) end)
            Puppet.TrackMap[realTrack] = nil
        end)
    end

    local function buildPuppet(character)
        destroyPuppet()
        if character == nil or character.Parent == nil then return false end
        if character ~= LocalPlayer.Character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil or humanoid.Health <= 0 then return false end
        local realAnimator = humanoid:FindFirstChildOfClass("Animator")
        if realAnimator == nil then return false end
        if character:FindFirstChild("HumanoidRootPart") == nil then return false end
        local hasMotor = false
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("Motor6D") and descendant.Part1 ~= nil then hasMotor = true break end
        end
        if not hasMotor then return false end
        local okClone, clone = pcall(function() return character:Clone() end)
        if not okClone or clone == nil then return false end
        clone.Name = "AnimPuppet"
        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then descendant:Destroy()
            elseif descendant:IsA("Humanoid") then descendant:Destroy() end
        end
        local animationController = Instance.new("AnimationController")
        animationController.Parent = clone
        local animator = Instance.new("Animator")
        animator.Parent = animationController
        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Transparency = 1
                descendant.CanCollide = false
                descendant.CanQuery = false
                descendant.CanTouch = false
                descendant.Massless = true
                descendant.Anchored = true
                descendant.CastShadow = false
            end
        end
        local puppetMotorByPart1 = {}
        for _, motor in ipairs(clone:GetDescendants()) do
            if motor:IsA("Motor6D") and motor.Part1 ~= nil then puppetMotorByPart1[motor.Part1.Name] = motor end
        end
        local newMotorMap = {}
        for _, realMotor in ipairs(character:GetDescendants()) do
            if realMotor:IsA("Motor6D") and realMotor.Part1 ~= nil then
                local puppetMotor = puppetMotorByPart1[realMotor.Part1.Name]
                if puppetMotor ~= nil then newMotorMap[realMotor] = puppetMotor end
            end
        end
        clone.Parent = Workspace
        Puppet.Model = clone Puppet.Animator = animator Puppet.CharacterReference = character
        Puppet.MotorMap = newMotorMap Puppet.TrackMap = {}
        local okTracks, tracks = pcall(function() return realAnimator:GetPlayingAnimationTracks() end)
        if okTracks and tracks ~= nil then
            for _, track in ipairs(tracks) do mirrorTrack(track) end
        end
        Puppet.AnimationPlayedConnection = realAnimator.AnimationPlayed:Connect(function(track)
            if Puppet.CharacterReference ~= character then return end
            mirrorTrack(track)
        end)
        return true
    end

    local function buildPuppetAsync(character)
        if character == nil then return end
        for i = 1, 40 do
            if Puppet.BuildTarget ~= character then return end
            if character ~= LocalPlayer.Character then return end
            if character.Parent == nil then return end
            if Puppet.CharacterReference == character and Puppet.Model ~= nil and Puppet.Model.Parent ~= nil then return end
            local ok = pcall(buildPuppet, character)
            if ok and Puppet.CharacterReference == character and Puppet.Model ~= nil and Puppet.Model.Parent ~= nil then return end
            task.wait(0.1)
        end
    end

    local function disconnectStripConnections()
        local index = 1
        while index <= #State.StripConnections do
            local connection = State.StripConnections[index]
            if connection ~= nil then pcall(function() connection:Disconnect() end) end
            index = index + 1
        end
        State.StripConnections = {}
    end

    local function stripRespawnProtections(character)
        pcall(function()
            if character == nil or character.Parent == nil then return end
            local absoluteImmortal = character:FindFirstChild("AbsoluteImmortal")
            if absoluteImmortal ~= nil then pcall(function() absoluteImmortal:Destroy() end) end
            local forceField = character:FindFirstChild("ForceField")
            if forceField ~= nil then pcall(function() forceField:Destroy() end) end
        end)
    end

    local function persistConfig()
        writeConfig({
            farmEnabled = Config.farmEnabled,
            performanceMode = Config.performanceMode,
            noRenderEnabled = Config.noRenderEnabled,
            stealthMode = Config.stealthMode,
            serverHopEnabled = Config.serverHopEnabled,
            autoHopKills = Config.autoHopKills,
            targetKills = Config.targetKills,
            showsKills = Config.showsKills,
        })
    end

    local function setToggle(label, isOn)
        if isOn then
            label.Text = "ON"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
        else
            label.Text = "OFF"
            label.TextColor3 = Color3.fromRGB(190, 190, 195)
            label.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
        end
        local badgeStroke = badgeStrokes[label]
        if badgeStroke ~= nil then
            if isOn then
                badgeStroke.Thickness = 1.5
                badgeStroke.Transparency = 0.3
            else
                badgeStroke.Thickness = 0
                badgeStroke.Transparency = 1
            end
        end
    end

    local function calculateAverageKills()
        local allPlayers = Players:GetPlayers()
        local totalKills = 0
        local countedPlayers = 0
        for _, player in ipairs(allPlayers) do
            if player ~= LocalPlayer then
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats ~= nil then
                    local killsValue = leaderstats:FindFirstChild("Total Kills")
                    if killsValue ~= nil and killsValue:IsA("IntValue") then
                        totalKills = totalKills + killsValue.Value
                        countedPlayers = countedPlayers + 1
                    end
                end
            end
        end
        if countedPlayers == 0 then return nil end
        return totalKills / countedPlayers
    end

    local function killsFromAverage(averageKills)
        if averageKills < 100 then return 50 end
        if averageKills < 500 then return 50 end
        if averageKills < 1000 then return 25 end
        if averageKills < 10000 then return 10 end
        return 6
    end

    local function hasProtection(character)
        if character == nil then return true end
        local currentTime = os.clock()
        local cachedEntry = Cache.ProtectionData[character]
        if cachedEntry ~= nil then
            if currentTime - cachedEntry.time < PROT_CACHE_TTL then return cachedEntry.value end
        end
        local isProtected = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then isProtected = true
        elseif character:FindFirstChild("ForceField") ~= nil then isProtected = true
        elseif character:FindFirstChild("FinalDeath") ~= nil then isProtected = true
        elseif character:FindFirstChild("Counter") ~= nil then isProtected = true
        elseif character:FindFirstChild("BeingGrabbed") ~= nil then isProtected = true
        elseif character:FindFirstChild("BeingGrapped") ~= nil then isProtected = true end
        Cache.ProtectionData[character] = {time = currentTime, value = isProtected}
        return isProtected
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if character == nil then
            State.RootCacheCharacter = nil State.RootCacheValue = nil
            return nil
        end
        if character == State.RootCacheCharacter then
            if State.RootCacheValue ~= nil and State.RootCacheValue.Parent ~= nil then return State.RootCacheValue end
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil or not root:IsA("BasePart") then
            State.RootCacheCharacter = character State.RootCacheValue = nil
            return nil
        end
        State.RootCacheCharacter = character State.RootCacheValue = root
        return root
    end

    local function selfHasRagdoll()
        local character = LocalPlayer.Character
        if character == nil then return false end
        return character:FindFirstChild("Ragdoll") ~= nil
    end

    local function isNearVoid()
        local root = getRoot()
        if root == nil then return false end
        return root.Position.Y <= VOID_Y_THRESHOLD
    end

    local function isSpecialAnimationPlaying()
        local currentTime = os.clock()
        if currentTime - Cache.SpecialAnimTime < SPECIAL_ANIM_CACHE_TTL then return Cache.SpecialAnimValue end
        Cache.SpecialAnimTime = currentTime
        local character = LocalPlayer.Character
        if character == nil then Cache.SpecialAnimValue = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then Cache.SpecialAnimValue = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then Cache.SpecialAnimValue = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then Cache.SpecialAnimValue = false return false end
        local found = false
        local index = 1
        while index <= #tracks do
            local animation = tracks[index].Animation
            if animation ~= nil then
                local numericId = string.match(animation.AnimationId, "%d+")
                if numericId ~= nil and SPECIAL_ANIM_IDS[numericId] then found = true break end
            end
            index = index + 1
        end
        Cache.SpecialAnimValue = found
        return found
    end

    local function isForceVoidAnimationPlaying()
        local currentTime = os.clock()
        if currentTime - Cache.ForceVoidTime < SPECIAL_ANIM_CACHE_TTL then return Cache.ForceVoidValue end
        Cache.ForceVoidTime = currentTime
        local character = LocalPlayer.Character
        if character == nil then Cache.ForceVoidValue = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then Cache.ForceVoidValue = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then Cache.ForceVoidValue = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then Cache.ForceVoidValue = false return false end
        local found = false
        local index = 1
        while index <= #tracks do
            local animation = tracks[index].Animation
            if animation ~= nil then
                local numericId = string.match(animation.AnimationId, "%d+")
                if numericId ~= nil and FORCE_VOID_ANIM_IDS[numericId] then found = true break end
            end
            index = index + 1
        end
        Cache.ForceVoidValue = found
        return found
    end

    local function isDetectAnimForceVoid()
        local currentTime = os.clock()
        if currentTime - Cache.DetectTime < SPECIAL_ANIM_CACHE_TTL then return Cache.DetectValue end
        Cache.DetectTime = currentTime
        local character = LocalPlayer.Character
        if character == nil then State.DetectAnimVoidLatch = false Cache.DetectValue = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then State.DetectAnimVoidLatch = false Cache.DetectValue = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then State.DetectAnimVoidLatch = false Cache.DetectValue = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then State.DetectAnimVoidLatch = false Cache.DetectValue = false return false end
        local isPlaying = false
        local timePosition = 0
        local index = 1
        while index <= #tracks do
            local animation = tracks[index].Animation
            if animation ~= nil then
                local numericId = string.match(animation.AnimationId, "%d+")
                if numericId == DETECT_ANIM_ID then isPlaying = true timePosition = tracks[index].TimePosition break end
            end
            index = index + 1
        end
        if not isPlaying or timePosition > DETECT_TIME_MAX then
            State.DetectAnimVoidLatch = false Cache.DetectValue = false return false
        end
        if timePosition >= DETECT_TIME_MIN then State.DetectAnimVoidLatch = true end
        Cache.DetectValue = State.DetectAnimVoidLatch
        return State.DetectAnimVoidLatch
    end

    local function getPlayerRoot(player)
        if player == nil or player == LocalPlayer then return nil end
        local targetCharacter = player.Character
        if targetCharacter == nil then return nil end
        if hasProtection(targetCharacter) then return nil end
        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid == nil or humanoid.Health <= 0 then return nil end
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if targetRoot == nil or not targetRoot:IsA("BasePart") then return nil end
        return targetRoot
    end

    local function getClosestPlayerWithin(range, referencePosition)
        local closestPlayer = nil
        local bestDistanceSquared = range * range
        local allPlayers = Players:GetPlayers()
        for _, player in ipairs(allPlayers) do
            if player ~= LocalPlayer then
                local targetRoot = getPlayerRoot(player)
                if targetRoot ~= nil then
                    local difference = targetRoot.Position - referencePosition
                    local distanceSquared = difference.X * difference.X + difference.Y * difference.Y + difference.Z * difference.Z
                    if distanceSquared <= bestDistanceSquared then
                        bestDistanceSquared = distanceSquared
                        closestPlayer = player
                    end
                end
            end
        end
        return closestPlayer
    end

    local function getTarget()
        local currentTime = os.clock()
        if currentTime - Cache.TargetTime < TARGET_CACHE_TTL then return Cache.TargetValue end
        Cache.TargetTime = currentTime
        local root = getRoot()
        if root == nil then
            State.LastTargetPlayer = nil
            State.PendingTargetPlayer = nil
            State.TargetSwitchLockUntil = 0
            Cache.TargetValue = nil
            return nil
        end
        if State.PendingTargetPlayer ~= nil then
            if currentTime < State.TargetSwitchLockUntil then
                Cache.TargetValue = State.LastTargetPlayer
                return State.LastTargetPlayer
            end
            State.LastTargetPlayer = State.PendingTargetPlayer
            State.PendingTargetPlayer = nil
            State.TargetSwitchLockUntil = 0
        end
        local result = nil
        local closestPlayer = getClosestPlayerWithin(PROXIMITY_PRIORITY_RANGE, root.Position)
        if closestPlayer ~= nil then
            result = closestPlayer
        else
            local lowestHpPlayer = nil
            local lowestHealth = math.huge
            local allPlayers = Players:GetPlayers()
            for _, player in ipairs(allPlayers) do
                if player ~= LocalPlayer then
                    local targetCharacter = player.Character
                    if targetCharacter ~= nil and not hasProtection(targetCharacter) then
                        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
                        if humanoid ~= nil and humanoid.Health > 0 then
                            local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
                            if targetRoot ~= nil and targetRoot:IsA("BasePart") then
                                if humanoid.Health < lowestHealth then
                                    lowestHealth = humanoid.Health
                                    lowestHpPlayer = player
                                end
                            end
                        end
                    end
                end
            end
            result = lowestHpPlayer
        end
        if result == nil then
            State.LastTargetPlayer = nil
            State.PendingTargetPlayer = nil
            State.TargetSwitchLockUntil = 0
            Cache.TargetValue = nil
            return nil
        end
        if result ~= State.LastTargetPlayer then
            if State.LastTargetPlayer ~= nil then
                State.PendingTargetPlayer = result
                State.TargetSwitchLockUntil = currentTime + TARGET_SWITCH_DELAY
                Cache.TargetValue = State.LastTargetPlayer
                return State.LastTargetPlayer
            end
            State.LastTargetPlayer = result
            Cache.TargetValue = result
            return result
        end
        Cache.TargetValue = result
        return result
    end

    local function canAlignToTarget(target)
        if target == nil or target == LocalPlayer then return false end
        local targetCharacter = target.Character
        if targetCharacter == nil or targetCharacter.Parent == nil then return false end
        if hasProtection(targetCharacter) then return false end
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if targetRoot == nil or not targetRoot:IsA("BasePart") then return false end
        return true
    end

    local function targetRootForAlign()
        local target = getTarget()
        if not canAlignToTarget(target) then return nil end
        return target.Character:FindFirstChild("HumanoidRootPart")
    end

    local function pinToSafeZone(root)
        if root == nil then return end
        if root.Position.Y > PIN_SAFE_Y_MAX then return end
        setPhysicsRepRootPart(root, nil)
        root.CFrame = CFrame.new(SAFE_POSITION)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function forceToVoid(root)
        if root == nil then return end
        setPhysicsRepRootPart(root, nil)
        root.CFrame = CFrame.new(SAFE_POSITION)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function pressKey(keyCode)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end

    local function pressG()
        if Config.stealthMode then return end
        local currentTime = os.clock()
        if currentTime - State.LastGPress < G_INTERVAL then return end
        if currentTime < State.RespawnGraceUntil then return end
        if Functions.CrowdBusterExists ~= nil then
            local ok, hasCrowdBuster = pcall(Functions.CrowdBusterExists)
            if ok and hasCrowdBuster then return end
        end
        State.LastGPress = currentTime
        pressKey(Enum.KeyCode.G)
    end

    local function pressJump()
        local currentTime = os.clock()
        if currentTime - State.LastJumpPress < JUMP_INTERVAL then return end
        State.LastJumpPress = currentTime
        if not State.SpaceDown then
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
            State.SpaceDown = true
            State.SpaceDownAt = currentTime
        end
    end

    local function tickSpaceRelease()
        if State.SpaceDown and os.clock() - State.SpaceDownAt >= SPACE_HOLD_TIME then
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
            State.SpaceDown = false
        end
    end

    local function getCommunicate()
        local character = LocalPlayer.Character
        if character == nil then return nil end
        local communicate = character:FindFirstChild("Communicate")
        if communicate == nil or not communicate:IsA("RemoteEvent") then return nil end
        return communicate
    end

    local function getMouseCFrame()
        local currentCamera = Workspace.CurrentCamera
        if currentCamera == nil then return nil end
        local mouseLocation = UserInputService:GetMouseLocation()
        local ray = currentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
        return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction * 1000)
    end

    local function getBackpack()
        if State.CachedBackpack ~= nil then
            if State.CachedBackpackParent ~= nil and State.CachedBackpack.Parent ~= nil then return State.CachedBackpack end
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            if backpack ~= nil and backpack:IsA("Backpack") then
                State.CachedBackpack = backpack
                State.CachedBackpackParent = backpack.Parent
                return backpack
            end
            State.CachedBackpack = nil
            State.CachedBackpackParent = nil
            return nil
        end
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack ~= nil and backpack:IsA("Backpack") then
            State.CachedBackpack = backpack
            State.CachedBackpackParent = backpack.Parent
            return backpack
        end
        return nil
    end

    local function findTool(name)
        local targetName = string.lower(name)
        local backpack = getBackpack()
        if backpack ~= nil then
            local children = backpack:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and string.lower(child.Name) == targetName then return child end
            end
        end
        local character = LocalPlayer.Character
        if character ~= nil then
            local children = character:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and string.lower(child.Name) == targetName then return child end
            end
        end
        return nil
    end

    local function findToolExact(name)
        local backpack = getBackpack()
        if backpack ~= nil then
            local children = backpack:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and child.Name == name then return child end
            end
        end
        local character = LocalPlayer.Character
        if character ~= nil then
            local children = character:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and child.Name == name then return child end
            end
        end
        return nil
    end

    Functions.TwinFangsExists = function()
        local currentTime = os.clock()
        if currentTime - Cache.TwinFangsTime < TF_CACHE_TTL then return Cache.TwinFangsValue end
        Cache.TwinFangsTime = currentTime
        local character = LocalPlayer.Character
        if character == nil then Cache.TwinFangsValue = false return false end
        if character:GetAttribute("Ulted") == true then Cache.TwinFangsValue = true return true end
        Cache.TwinFangsValue = findTool(TWIN_FANGS_NAME) ~= nil
        return Cache.TwinFangsValue
    end

    Functions.CrowdBusterExists = function()
        local currentTime = os.clock()
        if currentTime - Cache.CrowdBusterTime < TF_CACHE_TTL then return Cache.CrowdBusterValue end
        Cache.CrowdBusterTime = currentTime
        Cache.CrowdBusterValue = findTool(CROWD_BUSTER_NAME) ~= nil
        return Cache.CrowdBusterValue
    end

    local function fireEmoteSpin()
        local currentTime = os.clock()
        local interval = 2 / State.CurrentFps
        if interval < EMOTE_SPIN_MIN_INTERVAL then interval = EMOTE_SPIN_MIN_INTERVAL end
        if currentTime - State.LastEmoteSpin < interval then return end
        State.LastEmoteSpin = currentTime
        local communicate = getCommunicate()
        if communicate == nil then return end
        pcall(function() communicate:FireServer({ Goal = "Emote Spin" }) end)
    end

    local function fireCommunicate()
        local currentTime = os.clock()
        if currentTime - State.LastRemoteFire < REMOTE_COOLDOWN then return end
        State.LastRemoteFire = currentTime
        local communicate = getCommunicate()
        if communicate == nil then return end
        local mouseCFrame = getMouseCFrame()
        if mouseCFrame == nil then return end
        local character = LocalPlayer.Character
        if character == nil then return end
        local isM1ing = character:FindFirstChild("M1ing") ~= nil
        pcall(function()
            if Config.stealthMode then
                if not isM1ing then communicate:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCFrame }) end
                return
            end
            if Functions.CrowdBusterExists ~= nil and Functions.CrowdBusterExists() then
                if not isM1ing then communicate:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCFrame }) end
            elseif Functions.TwinFangsExists() then
                if isM1ing then
                    communicate:FireServer({ Goal = "KeyPress", Key = Enum.KeyCode.F, MousePos = mouseCFrame })
                    communicate:FireServer({ Goal = "LeftClickRelease", Mobile = IS_MOBILE })
                else
                    communicate:FireServer({ Goal = "KeyRelease", Key = Enum.KeyCode.F })
                end
            else
                if not isM1ing then communicate:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCFrame }) end
            end
        end)
    end

    local function activateToolViaRemote(tool)
        local communicate = getCommunicate()
        if communicate == nil then return end
        if tool == nil then return end
        pcall(function() communicate:FireServer({ Tool = tool, Goal = "Console Move", IsAutoActivate = true }) end)
    end

    local function fireRagdollFinish()
        local communicate = getCommunicate()
        if communicate == nil then return end
        local mouseCFrame = getMouseCFrame()
        if mouseCFrame == nil then return end
        if Functions.TwinFangsExists() then return end
        pcall(function() communicate:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress", MousePos = mouseCFrame }) end)
    end

    local function tryFireRagdollFinish()
        local currentTime = os.clock()
        if currentTime - State.LastRagdollFire < RAGDOLL_COOLDOWN then return end
        local target = getTarget()
        if target == nil then return end
        local targetCharacter = target.Character
        if targetCharacter == nil or targetCharacter:FindFirstChild("Ragdoll") == nil then return end
        State.LastRagdollFire = currentTime
        fireRagdollFinish()
    end

    local function getAllTools(excludeList)
        local excludedSet = {}
        for _, name in ipairs(excludeList) do excludedSet[string.lower(name)] = true end
        local result = {}
        local backpack = getBackpack()
        if backpack ~= nil then
            local children = backpack:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and not excludedSet[string.lower(child.Name)] then table.insert(result, child) end
            end
        end
        local character = LocalPlayer.Character
        if character ~= nil then
            local children = character:GetChildren()
            for _, child in ipairs(children) do
                if child:IsA("Tool") and not excludedSet[string.lower(child.Name)] then table.insert(result, child) end
            end
        end
        return result
    end

    local function getFilteredFallbackTools()
        local crowdBusterActive = false
        if Functions.CrowdBusterExists ~= nil then
            local ok, result = pcall(Functions.CrowdBusterExists)
            if ok then crowdBusterActive = result end
        end
        local excluded = { TWIN_FANGS_NAME, "Grand Fissure" }
        local hammerHeelLower = string.lower(HAMMER_HEEL_NAME)
        local bindingClothLower = string.lower(BINDING_CLOTH_NAME)
        local result = {}
        local hammerHeel = findTool(HAMMER_HEEL_NAME)
        local bindingCloth = findTool(BINDING_CLOTH_NAME)
        if hammerHeel ~= nil and bindingCloth ~= nil then
            if math.random() < 0.5 then
                table.insert(result, hammerHeel)
                table.insert(result, bindingCloth)
            else
                table.insert(result, bindingCloth)
                table.insert(result, hammerHeel)
            end
        elseif hammerHeel ~= nil then
            table.insert(result, hammerHeel)
        elseif bindingCloth ~= nil then
            table.insert(result, bindingCloth)
        end
        if crowdBusterActive then
            if #result > 0 then return result end
            return getAllTools(excluded)
        end
        local otherTools = getAllTools(excluded)
        for _, tool in ipairs(otherTools) do
            local toolLower = string.lower(tool.Name)
            if toolLower ~= hammerHeelLower and toolLower ~= bindingClothLower then
                table.insert(result, tool)
            end
        end
        if #result > 0 then return result end
        return getAllTools(excluded)
    end

    local function genericSpam()
        pressJump()
        fireCommunicate()
        tryFireRagdollFinish()
    end

    Functions.HotbarHasCooldown = function(slot)
        local currentTime = os.clock()
        local lastTime = Cache.HotbarTime[slot]
        if lastTime ~= nil and currentTime - lastTime < HOTBAR_CACHE_TTL then return Cache.HotbarValue[slot] end
        Cache.HotbarTime[slot] = currentTime
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui == nil then Cache.HotbarValue[slot] = false return false end
        local hotbar = playerGui:FindFirstChild("Hotbar")
        if not hotbar then Cache.HotbarValue[slot] = false return false end
        local backpack = hotbar:FindFirstChild("Backpack")
        if backpack == nil then Cache.HotbarValue[slot] = false return false end
        local slots = backpack:FindFirstChild("Hotbar")
        if slots == nil then Cache.HotbarValue[slot] = false return false end
        local frame = slots:FindFirstChild(tostring(slot))
        if frame == nil then Cache.HotbarValue[slot] = false return false end
        local baseFrame = frame:FindFirstChild("Base")
        if baseFrame == nil then Cache.HotbarValue[slot] = false return false end
        local result = baseFrame:FindFirstChild("Cooldown") ~= nil
        Cache.HotbarValue[slot] = result
        return result
    end

    local function ensureInvisible()
        pcall(function()
            local character = LocalPlayer.Character
            if character == nil then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid == nil then return end
            if humanoid.Health <= 0 then return end
            if State.SpamAnimationTrackCharacter == character and State.SpamAnimationTrack ~= nil then
                local okCheck, shouldSkip = pcall(function()
                    return State.SpamAnimationTrack.IsPlaying and State.SpamAnimationTrack.Speed == 0
                        and State.SpamAnimationTrack.WeightCurrent > 0.95
                        and math.abs(State.SpamAnimationTrack.TimePosition - SPAM_TIME_POSITION) < 0.005
                end)
                if okCheck and shouldSkip then return end
            end
            if State.SpamAnimationTrackCharacter ~= character then
                if State.SpamAnimationTrack ~= nil then pcall(function() State.SpamAnimationTrack:Stop(0) end) end
                State.SpamAnimationTrack = nil
                State.SpamAnimationTrackCharacter = character
            end
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator == nil then
                local newAnimator = Instance.new("Animator")
                newAnimator.Parent = humanoid
                animator = newAnimator
            end
            if animator == nil then return end
            if State.SpamAnimationTrack == nil then
                local newAnimation = Instance.new("Animation")
                newAnimation.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
                local loadedTrack = animator:LoadAnimation(newAnimation)
                if typeof(loadedTrack) == "Instance" then
                    loadedTrack.Priority = Enum.AnimationPriority.Action4
                    loadedTrack.Looped = true
                    State.SpamAnimationTrack = loadedTrack
                end
            end
            local track = State.SpamAnimationTrack
            if track == nil then return end
            if not track.IsPlaying then pcall(function() track:Play(0, 1, 0) end) end
            pcall(function()
                track:AdjustSpeed(0)
                track.TimePosition = SPAM_TIME_POSITION
                track:AdjustWeight(1, 0)
            end)
        end)
    end

    local function collectMotor6Ds(character)
        State.Motor6DList = {}
        if character == nil then return end
        local descendants = character:GetDescendants()
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("Motor6D") then table.insert(State.Motor6DList, descendant) end
        end
    end

    local function getStreak()
        local character = LocalPlayer.Character
        if character == nil then return 0 end
        local streakValue = character:GetAttribute("CurrentStreak")
        if typeof(streakValue) == "number" then return streakValue end
        return 0
    end

    local function killSelf()
        local character = LocalPlayer.Character
        if character == nil then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then return end
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
        if State.ThrownConnection ~= nil then State.ThrownConnection:Disconnect() end
        local thrownFolder = Workspace:FindFirstChild("Thrown")
        if thrownFolder == nil then return end
        State.ThrownConnection = thrownFolder.ChildAdded:Connect(function()
            task.wait(THROWN_CLEAR_DELAY)
            pcall(function() thrownFolder:ClearAllChildren() end)
        end)
    end

    local function httpGet(url)
        if typeof(game.HttpGet) == "function" then
            local ok, response = pcall(function() return game:HttpGet(url) end)
            if ok and typeof(response) == "string" and #response > 0 then return response end
        end
        if typeof(request) == "function" then
            local ok, response = pcall(function() return request({ Url = url, Method = "GET" }) end)
            if ok and typeof(response) == "table" then
                if typeof(response.Body) == "string" and #response.Body > 0 then return response.Body end
                if typeof(response.body) == "string" and #response.body > 0 then return response.body end
            end
        end
        if typeof(http_request) == "function" then
            local ok, response = pcall(function() return http_request({ Url = url, Method = "GET" }) end)
            if ok and typeof(response) == "table" then
                if typeof(response.Body) == "string" and #response.Body > 0 then return response.Body end
                if typeof(response.body) == "string" and #response.body > 0 then return response.body end
            end
        end
        if typeof(syn) == "table" and typeof(syn.request) == "function" then
            local ok, response = pcall(function() return syn.request({ Url = url, Method = "GET" }) end)
            if ok and typeof(response) == "table" then
                if typeof(response.Body) == "string" and #response.Body > 0 then return response.Body end
                if typeof(response.body) == "string" and #response.body > 0 then return response.body end
            end
        end
        return nil
    end

    local function fetchServerList()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        local response = httpGet(url)
        if response == nil then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not ok or typeof(data) ~= "table" then return nil end
        if typeof(data.data) ~= "table" then return nil end
        return data.data
    end

    local function buildCandidates(servers)
        local candidates = {}
        local currentJobId = game.JobId
        for _, server in ipairs(servers) do
            if server.id ~= nil and server.id ~= currentJobId then
                local playingCount = server.playing or 0
                local maxPlayersCount = server.maxPlayers or 0
                if maxPlayersCount > 0 and playingCount > 0 and playingCount < maxPlayersCount then
                    table.insert(candidates, { id = server.id, playing = playingCount, maxPlayers = maxPlayersCount })
                end
            end
        end
        table.sort(candidates, function(a, b) return a.playing > b.playing end)
        return candidates
    end

    local function ensureTeleportFailListener()
        if State.TeleportFailConnection ~= nil then return end
        State.TeleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player == LocalPlayer then State.TeleportFailedFlag = true end
        end)
    end

    local function attemptTeleport(jobId)
        State.TeleportFailedFlag = false
        ensureTeleportFailListener()

        local initOk = pcall(function()
            local options = Instance.new("TeleportOptions")
            options.ServerInstanceId = jobId
            TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, options)
        end)

        if not initOk then return false end

        local startTime = os.clock()
        while os.clock() - startTime < HOP_TELEPORT_VERIFY_WAIT do
            if State.TeleportFailedFlag then return false end
            if not Config.serverHopEnabled or State.HopRequestedStop then return false end
            task.wait(0.1)
        end
        return true
    end

    local function queueReexec()
        if typeof(writefile) == "function" then pcall(function() writefile(HOP_QUEUE_FLAG, "1") end) end
        local code = "_G.__AUTO_FARM_WRAPPER_ACTIVE=nil _G.__AUTO_FARM_INNER_ACTIVE=nil loadstring(game:HttpGet(\"" .. REEXEC_URL .. "\"))()"
        if typeof(queue_on_teleport) == "function" then queue_on_teleport(code)
        elseif typeof(queueonteleport) == "function" then queueonteleport(code)
        elseif typeof(QueueOnTeleport) == "function" then QueueOnTeleport(code)
        elseif typeof(syn) == "table" and typeof(syn.queue_on_teleport) == "function" then syn.queue_on_teleport(code) end
    end

    local function doServerHop()
        if State.HopInProgress then return end
        if not Config.serverHopEnabled then return end
        State.HopInProgress = true
        State.HopRequestedStop = false
        pcall(refreshStatus)
        pcall(queueReexec)

        local switched = false
        pcall(function()
            TeleportService:TeleportSwitchServer()
            switched = true
        end)

        if not switched then
            pcall(function()
                local servers = fetchServerList()
                if servers == nil then return end
                local candidates = buildCandidates(servers)
                local tryCount = math.min(#candidates, HOP_CANDIDATE_TRY_COUNT)
                local index = 1
                while index <= tryCount do
                    if not Config.serverHopEnabled or State.HopRequestedStop then break end
                    local candidate = candidates[index]
                    if attemptTeleport(candidate.id) then return end
                    task.wait(0.5)
                    index = index + 1
                end
            end)
        end

        State.HopInProgress = false
        pcall(refreshStatus)
    end

    local function frameAlignUntil(endTime, getTargetRoot)
        local cachedTargetRoot = getTargetRoot()
        while os.clock() < endTime do
            if not Config.farmEnabled or State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive then
                if not State.SpecialAnimActive then return true end
            end
            if cachedTargetRoot ~= nil and cachedTargetRoot.Parent == nil then cachedTargetRoot = getTargetRoot() end
            local root = getRoot()
            if root ~= nil then setPhysicsRepRootPart(root, cachedTargetRoot) root.CFrame = ALIGN_CF end
            pressG()
            task.wait()
        end
        return false
    end

    local function activateTwinFangs()
        local deadline = os.clock() + TF_ACTIVATION_TIMEOUT
        while os.clock() < deadline do
            if not Config.farmEnabled then return false end
            if not State.SpecialAnimActive then
                if State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive then return false end
            end
            if Functions.HotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
            local twinFangs = findTool(TWIN_FANGS_NAME)
            if twinFangs == nil then return false end
            activateToolViaRemote(twinFangs)
            local cachedTargetRoot = targetRootForAlign()
            local retryEnd = os.clock() + TF_RETRY_INTERVAL
            while os.clock() < retryEnd do
                if Functions.HotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
                if cachedTargetRoot ~= nil and cachedTargetRoot.Parent == nil then cachedTargetRoot = targetRootForAlign() end
                local root = getRoot()
                if root ~= nil then setPhysicsRepRootPart(root, cachedTargetRoot) root.CFrame = ALIGN_CF end
                pressG()
                task.wait(0.02)
            end
        end
        return Functions.HotbarHasCooldown(TWIN_FANGS_SLOT)
    end

    local function runFallbackTools()
        State.SuppressHeartbeatTeleport = false
        local tools = getFilteredFallbackTools()
        if #tools <= 0 then return end
        State.FallbackIndex = State.FallbackIndex + 1
        if State.FallbackIndex > #tools then State.FallbackIndex = 1 end
        local tool = tools[State.FallbackIndex]
        if tool ~= nil and tool.Parent ~= nil then activateToolViaRemote(tool) end
        genericSpam()
    end

    local function isTargetRagdolled(target)
        if target == nil then return false end
        local targetCharacter = target.Character
        if targetCharacter == nil then return false end
        return targetCharacter:FindFirstChild("Ragdoll") ~= nil
    end

    local function isTargetLowHp(target, threshold)
        if target == nil then return false end
        local targetCharacter = target.Character
        if targetCharacter == nil then return false end
        local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then return false end
        if humanoid.MaxHealth <= 0 then return false end
        if humanoid.Health <= 0 then return false end
        return (humanoid.Health / humanoid.MaxHealth) < threshold
    end

    local function rotationStep()
        if not Config.farmEnabled then task.wait(0.05) return end
        if not State.SpecialAnimActive then
            if State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive
                or State.ForceVoidActive or State.DetectAnimVoidActive then
                task.wait(0.05) return
            end
        end
        State.SuppressHeartbeatTeleport = false
        local character = LocalPlayer.Character
        if character == nil then task.wait(0.1) return end
        if Config.stealthMode then
            local target = getTarget()
            if target ~= nil then
                if canAlignToTarget(target) then
                    local root = getRoot()
                    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if root ~= nil and targetRoot ~= nil then setPhysicsRepRootPart(root, targetRoot) root.CFrame = ALIGN_CF end
                end
                runFallbackTools()
            end
            task.wait(0.05) return
        end
        local twinFangs = findTool(TWIN_FANGS_NAME)
        if not Functions.TwinFangsExists() then
            local target = getTarget()
            if target ~= nil then
                local runNow = false
                if isTargetRagdolled(target) then runNow = true
                elseif isTargetLowHp(target, LOW_HP_TARGET_FALLBACK_THRESHOLD) then runNow = true end
                if runNow then runFallbackTools() end
            end
            task.wait(0.05) return
        end
        if twinFangs == nil then task.wait(0.05) return end
        if Functions.HotbarHasCooldown(TWIN_FANGS_SLOT) then task.wait(0.05) return end
        local activated = activateTwinFangs()
        if not activated then task.wait(0.05) return end
        frameAlignUntil(os.clock() + TF_ALIGN_DURATION, targetRootForAlign)
        if not Config.farmEnabled then task.wait(0.05) return end
        if not State.SpecialAnimActive then
            if State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive then task.wait(0.05) return end
        end
        local root = getRoot()
        if root == nil then task.wait(0.05) return end
        local originPosition = Vector3.new(63, 441, 65)
        local originCFrame = CFrame.new(originPosition)
        State.InOriginPhase = true
        State.SuppressHeartbeatTeleport = true
        local originCharacter = LocalPlayer.Character
        local voidEnd = os.clock() + VOID_STAY_DURATION
        while os.clock() < voidEnd and Config.farmEnabled do
            if LocalPlayer.Character ~= originCharacter then break end
            local currentRoot = getRoot()
            if currentRoot ~= nil then
                setPhysicsRepRootPart(currentRoot, nil)
                currentRoot.CFrame = CFrame.new(SAFE_POSITION)
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            task.wait()
        end
        local teleportDeadline = os.clock() + 1.5
        while Config.farmEnabled and os.clock() < teleportDeadline do
            if LocalPlayer.Character ~= originCharacter then break end
            local currentRoot = getRoot()
            if currentRoot ~= nil then
                setPhysicsRepRootPart(currentRoot, nil)
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
                currentRoot.CFrame = originCFrame
                local difference = currentRoot.Position - originPosition
                local distanceSquared = difference.X * difference.X + difference.Y * difference.Y + difference.Z * difference.Z
                if distanceSquared < 4 then break end
            end
            task.wait()
        end
        local grandFissureDetected = false
        local grandFissureDetectedAt = 0
        local originStartTime = os.clock()
        if Functions.HotbarHasCooldown(GRAND_FISSURE_SLOT) then grandFissureDetected = true grandFissureDetectedAt = originStartTime end
        while Config.farmEnabled do
            if LocalPlayer.Character ~= originCharacter then break end
            local currentTime = os.clock()
            if not grandFissureDetected then
                if currentTime - originStartTime >= GF_SPAM_TIMEOUT then break end
            else
                if currentTime - grandFissureDetectedAt >= GF_STAY_TIMEOUT then break end
            end
            local currentRoot = getRoot()
            if currentRoot ~= nil then
                setPhysicsRepRootPart(currentRoot, nil)
                currentRoot.CFrame = originCFrame
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            if not State.SpecialAnimActive then
                if State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive then break end
            end
            local grandFissure = findToolExact(GRAND_FISSURE_NAME)
            if grandFissure ~= nil then
                local cooldownActive = Functions.HotbarHasCooldown(GRAND_FISSURE_SLOT)
                if not grandFissureDetected then
                    if cooldownActive then grandFissureDetected = true grandFissureDetectedAt = os.clock()
                    else
                        activateToolViaRemote(grandFissure)
                        Cache.HotbarTime[GRAND_FISSURE_SLOT] = nil
                        if Functions.HotbarHasCooldown(GRAND_FISSURE_SLOT) then grandFissureDetected = true grandFissureDetectedAt = os.clock() end
                    end
                else
                    local stayElapsed = os.clock() - grandFissureDetectedAt
                    if not cooldownActive and stayElapsed >= GF_MIN_STAY_AFTER_USE then break end
                end
            else
                local twinFangsTool = findTool(TWIN_FANGS_NAME)
                if twinFangsTool == nil then break end
                if not Functions.HotbarHasCooldown(TWIN_FANGS_SLOT) then break end
            end
            task.wait()
        end
        Cache.HotbarTime = {}
        Cache.HotbarValue = {}
        State.InOriginPhase = false
        State.SuppressHeartbeatTeleport = false
    end

    local function runRotationLoop()
        if State.RotationRunning then return end
        State.RotationRunning = true
        pcall(refreshStatus)
        while Config.farmEnabled do
            local character = LocalPlayer.Character
            if character == nil or character ~= State.LastSetupCharacter then break end
            if not State.SpecialAnimActive then
                if State.ProtectionActive or State.LowHealthMode or State.SelfRagdollActive
                    or State.ForceVoidActive or State.DetectAnimVoidActive then break end
            end
            local ok = pcall(rotationStep)
            if not ok then
                State.InOriginPhase = false State.SuppressHeartbeatTeleport = false
            end
            task.wait()
        end
        State.InOriginPhase = false State.SuppressHeartbeatTeleport = false
        State.RotationRunning = false
        pcall(refreshStatus)
    end

    local function disconnectCharacterConnections()
        local index = 1
        while index <= #State.CharacterConnections do
            local connection = State.CharacterConnections[index]
            if connection ~= nil then connection:Disconnect() end
            index = index + 1
        end
        State.CharacterConnections = {}
        State.WatchedTools = {}
    end

    local function watchTool(tool)
        if State.WatchedTools[tool] then return end
        State.WatchedTools[tool] = true
    end

    local function watchCharacter(character)
        disconnectCharacterConnections()
        State.CachedBackpack = nil
        State.CachedBackpackParent = nil
        local backpack = getBackpack()
        if backpack ~= nil then
            local backpackChildren = backpack:GetChildren()
            for _, child in ipairs(backpackChildren) do
                if child:IsA("Tool") then watchTool(child) end
            end
            table.insert(State.CharacterConnections, backpack.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then watchTool(child) end
            end))
        end
        local characterChildren = character:GetChildren()
        for _, child in ipairs(characterChildren) do
            if child:IsA("Tool") then watchTool(child) end
        end
        table.insert(State.CharacterConnections, character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then watchTool(child) end
        end))
        collectMotor6Ds(character)
        table.insert(State.CharacterConnections, character.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Motor6D") then table.insert(State.Motor6DList, descendant) end
        end))
    end

    local function updateKillsFromLeaderstats()
        if State.KillsValue ~= nil and State.KillsValue.Parent ~= nil then return end
        State.KillsValue = nil
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats == nil then return end
        local killsValue = leaderstats:FindFirstChild("Kills")
        if killsValue == nil then return end
        if not killsValue:IsA("IntValue") then return end
        State.KillsValue = killsValue
        if not Config.initialized then
            Config.initialized = true
            Config.showsKills = killsValue.Value
            persistConfig()
            refreshKillsDisplay()
        end
    end

    refreshStatus = function()
        local statusText = nil
        local statusColor = nil
        local character = LocalPlayer.Character
        local humanoid = nil
        if character ~= nil then humanoid = character:FindFirstChildOfClass("Humanoid") end
        local isSetup = false
        if character ~= nil and humanoid ~= nil and humanoid.Health > 0 and character == State.LastSetupCharacter then isSetup = true end
        if not isSetup then
            statusText = "Mode: Respawning..."
            statusColor = DEFAULT_MODE_COLOR
        elseif State.StealthResetPhase then
            statusText = "Mode: Stealth Reset (Void)"
            statusColor = ANTI_MODE_COLOR
        elseif Config.stealthMode and Config.farmEnabled then
            statusText = "Mode: Stealth Farming"
            statusColor = Color3.fromRGB(150, 200, 255)
        elseif State.ForceVoidActive then
            statusText = "Mode: Force Void"
            statusColor = VOID_ZONE_COLOR
        elseif State.DetectAnimVoidActive then
            statusText = "Mode: Detect Anim Void"
            statusColor = VOID_ZONE_COLOR
        elseif State.VoidKillingActive then
            statusText = "Mode: Void Killing"
            statusColor = VOID_KILLING_COLOR
        elseif State.LowHealthMode then
            statusText = "Mode: LOW HP - Recovering"
            statusColor = Color3.fromRGB(255, 90, 90)
        elseif State.SelfRagdollActive then
            statusText = "Mode: Anti (Anti Invisible)"
            statusColor = ANTI_MODE_COLOR
        elseif State.HopInProgress then
            statusText = "Mode: Server Hopping"
            statusColor = DEFAULT_MODE_COLOR
        elseif State.ProtectionActive then
            statusText = "Mode: Void Zone"
            statusColor = VOID_ZONE_COLOR
        elseif Functions.CrowdBusterExists ~= nil and Functions.CrowdBusterExists() then
            statusText = "Mode: Void Killing"
            statusColor = VOID_KILLING_COLOR
        elseif Functions.TwinFangsExists ~= nil and Functions.TwinFangsExists() then
            statusText = "Mode: Farming Kills"
            statusColor = FARMING_KILLS_COLOR
        else
            statusText = "Mode: Getting Ultimate and Kills"
            statusColor = DEFAULT_MODE_COLOR
        end
        State.LastStatusText = statusText
        State.LastStatusColor = statusColor
        Status.TextColor3 = statusColor
    end

    refreshKillsDisplay = function()
        ShowsLabel.Text = "Shows Kills: " .. tostring(Config.showsKills)
        if State.KillsValue ~= nil then
            CurrentLabel.Text = "Current Kills: " .. tostring(State.KillsValue.Value)
        else
            CurrentLabel.Text = "Current Kills: 0"
        end
    end

    local function updateStatsLabel()
        local currentTime = os.clock()
        if currentTime - State.LastStatsUpdate < 0.5 then return end
        State.LastStatsUpdate = currentTime
        local ping = 0
        local ok, value = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ok and typeof(value) == "number" then ping = math.floor(value) end
        local fps = math.floor(State.CurrentFps)
        local fpsColor = nil
        if fps >= 60 then fpsColor = "rgb(120,255,150)"
        elseif fps >= 40 then fpsColor = "rgb(255,190,90)"
        else fpsColor = "rgb(255,90,90)" end
        local pingColor = nil
        if ping < 100 then pingColor = "rgb(120,255,150)"
        elseif ping < 200 then pingColor = "rgb(255,190,90)"
        else pingColor = "rgb(255,90,90)" end
        StatsLabel.Text = string.format(
            'Ping <font color="%s">%d</font> ms  <font color="rgb(80,80,100)">|</font>  Fps <font color="%s">%d</font>',
            pingColor, ping, fpsColor, fps
        )
    end

    local function handleCharacterSetup()
        local character = LocalPlayer.Character
        if character == nil then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then return end
        if humanoid.Health <= 0 then return end
        if character == State.LastSetupCharacter then return end
        State.LastSetupCharacter = character
        State.RespawnGraceUntil = os.clock() + RESPAWN_G_GRACE
        State.InOriginPhase = false
        State.ProtectionActive = false
        State.LowHealthMode = false
        State.SelfRagdollActive = false
        State.SpecialAnimActive = false
        State.ForceVoidActive = false
        State.DetectAnimVoidActive = false
        State.DetectAnimVoidLatch = false
        Cache.DetectTime = 0
        Cache.DetectValue = false
        State.VoidKillingActive = false
        State.VoidKillingCounting = false
        State.VoidKillingTimerStart = 0
        State.StealthResetPhase = false
        State.StealthResetAt = 0
        State.LastTargetPlayer = nil
        State.PendingTargetPlayer = nil
        State.TargetSwitchLockUntil = 0
        State.Motor6DList = {}
        if State.SpamAnimationTrack ~= nil then pcall(function() State.SpamAnimationTrack:Stop(0) end) end
        State.SpamAnimationTrack = nil
        State.SpamAnimationTrackCharacter = nil
        State.CachedBackpack = nil
        State.CachedBackpackParent = nil
        State.SpaceDown = false
        State.LastRagdollFire = 0
        State.KillsValue = nil
        State.SuppressHeartbeatTeleport = false
        State.InOriginPhase = false
        State.RootCacheCharacter = nil
        State.RootCacheValue = nil
        Cache.TargetTime = 0
        Cache.TargetValue = nil
        Cache.TwinFangsTime = 0
        Cache.HotbarTime = {}
        Cache.HotbarValue = {}
        Cache.SpecialAnimTime = 0
        Cache.ForceVoidTime = 0
        Cache.CrowdBusterTime = 0
        Cache.ProtectionData = setmetatable({}, {__mode = "k"})
        State.LastEmoteSpin = 0
        State.LastFallbackFire = 0
        disconnectStripConnections()
        disconnectCharacterConnections()
        forceFallenHeight()
        setupForceHealth(character)
        stripRespawnProtections(character)
        pcall(function()
            local connection = character.ChildAdded:Connect(function(child)
                if character == nil or character.Parent == nil then return end
                if character ~= LocalPlayer.Character then return end
                if child == nil then return end
                if child.Name == "AbsoluteImmortal" or child.Name == "ForceField" then
                    pcall(function() child:Destroy() end)
                end
            end)
            table.insert(State.StripConnections, connection)
        end)
        watchCharacter(character)
        scanAndApplyLTM(character)
        connectLTMDescendantWatcher(character)
        Puppet.BuildTarget = character
        do
            local ok = pcall(buildPuppet, character)
            if not (ok and Puppet.CharacterReference == character and Puppet.Model ~= nil and Puppet.Model.Parent ~= nil) then
                task.spawn(function() buildPuppetAsync(character) end)
            end
        end
        refreshStatus()
    end

    farmButton.Activated:Connect(function()
        Config.farmEnabled = not Config.farmEnabled
        setToggle(farmState, Config.farmEnabled)
        if not Config.farmEnabled then
            State.InOriginPhase = false
            State.SuppressHeartbeatTeleport = false
            State.StealthResetPhase = false
            State.StealthResetAt = 0
        end
        persistConfig()
        refreshStatus()
    end)

    performanceButton.Activated:Connect(function()
        Config.performanceMode = not Config.performanceMode
        setToggle(performanceState, Config.performanceMode)
        persistConfig()
    end)

    noRenderButton.Activated:Connect(function()
        Config.noRenderEnabled = not Config.noRenderEnabled
        setToggle(noRenderState, Config.noRenderEnabled)
        applyNoRender()
        persistConfig()
    end)

    stealthButton.Activated:Connect(function()
        Config.stealthMode = not Config.stealthMode
        setToggle(stealthState, Config.stealthMode)
        WarningLabel.Visible = Config.stealthMode
        if not Config.stealthMode then State.StealthResetPhase = false State.StealthResetAt = 0 end
        persistConfig()
        refreshStatus()
    end)

    hopButton.Activated:Connect(function()
        Config.serverHopEnabled = not Config.serverHopEnabled
        setToggle(hopState, Config.serverHopEnabled)
        persistConfig()
        if not Config.serverHopEnabled then
            State.HopRequestedStop = true
            State.HopInProgress = false
            if typeof(delfile) == "function" then pcall(function() delfile(HOP_QUEUE_FLAG) end) end
            refreshStatus()
        end
    end)

    autoHopButton.Activated:Connect(function()
        Config.autoHopKills = not Config.autoHopKills
        setToggle(autoHopState, Config.autoHopKills)
        persistConfig()
    end)

    setToggle(farmState, Config.farmEnabled)
    setToggle(performanceState, Config.performanceMode)
    setToggle(noRenderState, Config.noRenderEnabled)
    setToggle(stealthState, Config.stealthMode)
    setToggle(hopState, Config.serverHopEnabled)
    setToggle(autoHopState, Config.autoHopKills)
    WarningLabel.Visible = Config.stealthMode
    refreshKillsDisplay()

    task.spawn(function()
        while true do
            if Config.autoHopKills then
                local averageKills = calculateAverageKills()
                if averageKills ~= nil then
                    local newTargetKills = killsFromAverage(averageKills)
                    if Config.targetKills ~= newTargetKills then
                        Config.targetKills = newTargetKills
                        if GuiElements.KillsBox ~= nil and not GuiElements.KillsBox:IsFocused() then
                            GuiElements.KillsBox.Text = tostring(newTargetKills)
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            State.WindowDragging = true
            State.WindowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            State.WindowStartPosition = Main.Position
        elseif input.UserInputType == Enum.UserInputType.Touch then
            State.WindowDragging = true
            State.WindowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            State.WindowStartPosition = Main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if State.WindowDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = Vector2.new(input.Position.X, input.Position.Y) - State.WindowDragStart
                Main.Position = UDim2.new(
                    State.WindowStartPosition.X.Scale,
                    State.WindowStartPosition.X.Offset + delta.X,
                    State.WindowStartPosition.Y.Scale,
                    State.WindowStartPosition.Y.Offset + delta.Y
                )
            end
            return
        end
        local inputType = input.UserInputType
        if inputType == Enum.UserInputType.MouseMovement then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                State.CameraYaw = State.CameraYaw - input.Delta.X * CAMERA_SENSITIVITY
                State.CameraPitch = math.clamp(State.CameraPitch - input.Delta.Y * CAMERA_SENSITIVITY, math.rad(-80), math.rad(80))
            end
        elseif inputType == Enum.UserInputType.Touch then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                State.CameraYaw = State.CameraYaw - input.Delta.X * CAMERA_SENSITIVITY * 1.4
                State.CameraPitch = math.clamp(State.CameraPitch - input.Delta.Y * CAMERA_SENSITIVITY * 1.4, math.rad(-80), math.rad(80))
            end
        elseif inputType == Enum.UserInputType.MouseWheel then
            State.CameraDistance = math.clamp(State.CameraDistance - input.Position.Z * 2, CAMERA_MIN_DIST, CAMERA_MAX_DIST)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.WindowDragging = false
        end
    end)

    RunService:BindToRenderStep("CameraSubjectUpdate", Enum.RenderPriority.Camera.Value - 1, function()
        pcall(function()
            local character = LocalPlayer.Character
            if character == nil then return end
            local localHumanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if localHumanoid == nil or rootPart == nil then return end
            local target = getTarget()
            if target == nil then return end
            local targetCharacter = target.Character
            if targetCharacter == nil then return end
            local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
            if targetHumanoid == nil then return end
            local distance = (rootPart.Position - ALIGN_CF.Position).Magnitude
            local currentCamera = workspace.CurrentCamera
            if currentCamera == nil then return end
            local desiredSubject = nil
            if currentCamera.CameraSubject == targetHumanoid then
                desiredSubject = (distance <= 1.6) and targetHumanoid or localHumanoid
            else
                desiredSubject = (distance <= 1.2) and targetHumanoid or localHumanoid
            end
            if currentCamera.CameraSubject ~= desiredSubject then currentCamera.CameraSubject = desiredSubject end
        end)
    end)

    table.insert(State.PermanentConnections, RunService.Heartbeat:Connect(function()
        pcall(handleCharacterSetup)
        pcall(tickSpaceRelease)
        pcall(updateStatsLabel)
        if State.KillsValue ~= nil and State.KillsValue.Parent ~= nil then
            local currentTime = os.clock()
            if currentTime - State.LastKillsLabelUpdate > 0.1 then
                State.LastKillsLabelUpdate = currentTime
                pcall(function() CurrentLabel.Text = "Current Kills: " .. tostring(State.KillsValue.Value) end)
            end
        end
        pcall(updateKillsFromLeaderstats)

        do
            local hopNow = os.clock()
            if Config.serverHopEnabled and State.KillsValue ~= nil and not State.HopInProgress then
                if hopNow - State.LastHopCheck >= HOP_CHECK_INTERVAL then
                    State.LastHopCheck = hopNow
                    local liveKills = State.KillsValue.Value
                    if liveKills < Config.showsKills then
                        Config.showsKills = liveKills
                        persistConfig()
                        refreshKillsDisplay()
                    end
                    if (liveKills - Config.showsKills) >= Config.targetKills then
                        if hopNow - State.LastHopAttempt >= HOP_FAILURE_COOLDOWN then
                            State.LastHopAttempt = hopNow
                            task.spawn(function()
                                doServerHop()
                            end)
                        end
                        return
                    end
                end
            end
        end

        if State.LastSetupCharacter ~= LocalPlayer.Character then
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then
                State.LastStatusRefresh = statusNow
                refreshStatus()
            end
            return
        end
        local character = LocalPlayer.Character
        if character == nil then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil then return end
        if not root:IsA("BasePart") then return end
        State.RootCacheCharacter = character
        State.RootCacheValue = root
        pcall(fireEmoteSpin)
        pcall(ensureInvisible)
        pcall(function()
            State.SpecialAnimActive = isSpecialAnimationPlaying()
            State.ForceVoidActive = isForceVoidAnimationPlaying()
            State.DetectAnimVoidActive = isDetectAnimForceVoid()
        end)
        if State.ForceVoidActive then
            pinToSafeZone(root)
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
            return
        end
        if State.DetectAnimVoidActive then
            pinToSafeZone(root)
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
            return
        end
        State.VoidKillingActive = false
        if Functions.CrowdBusterExists ~= nil then
            local okCrowd, hasCrowdBuster = pcall(Functions.CrowdBusterExists)
            if okCrowd and hasCrowdBuster then
                if Functions.HotbarHasCooldown(3) and Functions.HotbarHasCooldown(4) then
                    if not State.VoidKillingCounting then
                        State.VoidKillingCounting = true
                        State.VoidKillingTimerStart = os.clock()
                    end
                    State.VoidKillingActive = true
                    if os.clock() - State.VoidKillingTimerStart >= VOID_KILL_DELAY then
                        State.VoidKillingCounting = false
                        State.VoidKillingTimerStart = 0
                        pinToSafeZone(root)
                        killSelf()
                        local statusNow = os.clock()
                        if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
                        return
                    end
                else
                    State.VoidKillingCounting = false
                    State.VoidKillingTimerStart = 0
                end
            else
                State.VoidKillingCounting = false
                State.VoidKillingTimerStart = 0
            end
        end
        local isProtected = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then isProtected = true end
        if isProtected then
            State.ProtectionActive = true
            pinToSafeZone(root)
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
            return
        else
            State.ProtectionActive = false
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid ~= nil and humanoid.MaxHealth > 0 then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            if healthPercent < LOW_HP_THRESHOLD then State.LowHealthMode = true
            elseif healthPercent >= LOW_HP_THRESHOLD then State.LowHealthMode = false end
        end
        if State.LowHealthMode and not State.SpecialAnimActive then
            pinToSafeZone(root)
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
            return
        end
        local hasRagdoll = selfHasRagdoll()
        State.SelfRagdollActive = hasRagdoll
        if State.SelfRagdollActive and not State.SpecialAnimActive then
            pinToSafeZone(root)
            local statusNow = os.clock()
            if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
            return
        end
        if Config.stealthMode and Config.farmEnabled and not State.SpecialAnimActive then
            local isAlive = humanoid ~= nil and humanoid.Health > 0
            if isAlive and getStreak() >= STEALTH_STREAK_THRESHOLD then
                if not State.StealthResetPhase then State.StealthResetPhase = true State.StealthResetAt = os.clock() end
                forceToVoid(root)
                if os.clock() - State.StealthResetAt >= STEALTH_VOID_WAIT then
                    State.StealthResetPhase = false
                    State.StealthResetAt = 0
                    killSelf()
                end
                local statusNow = os.clock()
                if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
                return
            elseif State.StealthResetPhase then
                State.StealthResetPhase = false
                State.StealthResetAt = 0
            end
        end
        if Config.farmEnabled and not State.InOriginPhase then
            pressG()
            genericSpam()
            local target = getTarget()
            if target == nil then
                if not State.SpecialAnimActive then pinToSafeZone(root) end
                if not State.RotationRunning then task.spawn(runRotationLoop) end
                local statusNow = os.clock()
                if statusNow - State.LastStatusRefresh >= 0.25 then State.LastStatusRefresh = statusNow refreshStatus() end
                return
            end
            if isNearVoid() then
                setPhysicsRepRootPart(root, nil)
                if not State.SuppressHeartbeatTeleport and canAlignToTarget(target) then root.CFrame = ALIGN_CF end
            elseif not State.SuppressHeartbeatTeleport and canAlignToTarget(target) then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot ~= nil and targetRoot:IsA("BasePart") then
                    setPhysicsRepRootPart(root, targetRoot)
                    root.CFrame = ALIGN_CF
                end
            end
            if not State.RotationRunning then task.spawn(runRotationLoop) end
        elseif Config.farmEnabled and State.InOriginPhase then
            if not State.RotationRunning then task.spawn(runRotationLoop) end
        end
        local statusNow = os.clock()
        if statusNow - State.LastStatusRefresh >= 0.25 then
            State.LastStatusRefresh = statusNow
            refreshStatus()
        end
    end))

    table.insert(State.PermanentConnections, RunService.RenderStepped:Connect(function()
        if Config.noRenderEnabled then return end
        if Config.performanceMode then
            if State.ThrownConnection == nil then startThrownWatcher() end
        else
            if State.ThrownConnection ~= nil then State.ThrownConnection:Disconnect() State.ThrownConnection = nil end
        end
        local character = LocalPlayer.Character
        if character == nil or character ~= State.LastSetupCharacter then return end
        local realRoot = getRoot()
        if realRoot == nil then return end
        local currentCamera = Workspace.CurrentCamera
        if currentCamera == nil then return end
        if sethiddenFn ~= nil then
            pcall(function() sethiddenFn(LocalPlayer, "FrustumStreaming", true) end)
        end
    end))

    table.insert(State.PermanentConnections, RunService.PreSimulation:Connect(function()
        
        local toRemove = nil
        for realTrack, puppetTrack in pairs(Puppet.TrackMap) do
            if realTrack.IsPlaying and puppetTrack.IsPlaying then
                pcall(function()
                    puppetTrack.TimePosition = realTrack.TimePosition
                    puppetTrack:AdjustSpeed(realTrack.Speed)
                    puppetTrack:AdjustWeight(realTrack.WeightCurrent, 0)
                end)
            elseif realTrack.IsPlaying and not puppetTrack.IsPlaying then
                pcall(function()
                    puppetTrack:Play(0, realTrack.WeightCurrent, realTrack.Speed)
                    puppetTrack.TimePosition = realTrack.TimePosition
                end)
            elseif not realTrack.IsPlaying and puppetTrack.IsPlaying then
                if toRemove == nil then toRemove = {} end
                table.insert(toRemove, realTrack)
            end
        end
        if toRemove ~= nil then
            for _, track in ipairs(toRemove) do
                local puppetTrack = Puppet.TrackMap[track]
                if puppetTrack ~= nil then pcall(function() puppetTrack:Stop(0) end) end
                Puppet.TrackMap[track] = nil
            end
        end
    end))

    table.insert(State.PermanentConnections, RunService.PreSimulation:Connect(function()
        
        for realMotor, puppetMotor in pairs(Puppet.MotorMap) do
            if realMotor.Parent ~= nil and puppetMotor.Parent ~= nil then realMotor.Transform = puppetMotor.Transform end
        end
    end))

    table.insert(State.PermanentConnections, LocalPlayer.CharacterRemoving:Connect(function()
        pcall(destroyPuppet)
        restoreAllLTM()
    end))

    table.insert(State.PermanentConnections, Players.PlayerRemoving:Connect(function(player)
        local character = player.Character
        if character == nil then return end
        Cache.ProtectionData[character] = nil
    end))

    startLTMEnforcer()
    do
        local startingCharacter = LocalPlayer.Character
        if startingCharacter ~= nil then
            scanAndApplyLTM(startingCharacter)
            connectLTMDescendantWatcher(startingCharacter)
        end
    end
    refreshKillsDisplay()
end

RUN()
]==]

local loader = loadstring
if typeof(loader) ~= "function" then
    local message = "LOAD ERROR: loadstring is not available in this executor."
    copyToClipboard(message)
    notify("Auto Farm - Load Error", message, 15)
    warn(message)
    return
end

local loadedFunction, loadError = loader(SCRIPT_SOURCE)
if not loadedFunction then
    local message = "LOAD ERROR (compile-time)\n\n" .. tostring(loadError)
    copyToClipboard(message)
    notify("Auto Farm - Load Error", "Compile error copied to clipboard.\n" .. tostring(loadError):sub(1, 80), 15)
    warn(message)
    return
end

local ok, runtimeError = xpcall(loadedFunction, function(errorValue)
    local errorMessage = tostring(errorValue)
    local traceback = debug.traceback("", 2)
    return errorMessage .. "\n\n" .. traceback
end)

if not ok then
    local fullMessage = "RUNTIME ERROR\n\n" .. tostring(runtimeError)
    local wasCopied = copyToClipboard(fullMessage)
    local preview = tostring(runtimeError):sub(1, 80)
    if wasCopied then
        notify("Auto Farm - Runtime Error", "Error copied to clipboard.\n" .. preview, 15)
    else
        notify("Auto Farm - Runtime Error", "Error on load.\n" .. preview, 15)
    end
    warn(fullMessage)
    return
end

if ok then
    if hookfunction then
        hookfunction(print, function(...) return end)
        hookfunction(warn, function(...) return end)
        hookfunction(error, function(...) return end)
    else
        print = function(...) return end
        warn = function(...) return end
        error = function(...) return end
    end
end

notify("Auto Farm", "Loaded successfully. Config applied.", 5)