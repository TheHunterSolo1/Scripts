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
    local _W = game:GetService("Workspace")
    local _SS = game:GetService("SoundService")
    local _RS = game:GetService("ReplicatedStorage")
    local _RF = game:GetService("ReplicatedFirst")
    local _Players = game:GetService("Players")

    local function inLocalChar(o)
        local lp = _Players.LocalPlayer
        if lp == nil then return false end
        local ch = lp.Character
        if ch == nil then return false end
        local p = o
        while p ~= nil do
            if p == ch then return true end
            p = p.Parent
        end
        return false
    end

    local function nuke(o)
        local c = o.ClassName
        if c == "Sound" then o.Enabled = false o.Volume = 0 pcall(function() o.Playing = false end) return end
        if c == "SoundGroup" then o.Volume = 0 return end
        if c == "ParticleEmitter" then o.Enabled = false return end
        if c == "Beam" then o.Enabled = false return end
        if c == "Trail" then o.Enabled = false return end
        if c == "Fire" then o.Enabled = false return end
        if c == "Smoke" then o.Enabled = false return end
        if c == "Sparkles" then o.Enabled = false return end
        if c == "Explosion" then o.Visible = false o.BlastPressure = 0 o.BlastRadius = 0 return end
        if c == "PointLight" then o.Enabled = false return end
        if c == "SpotLight" then o.Enabled = false return end
        if c == "SurfaceLight" then o.Enabled = false return end
        if c == "Highlight" then o.Enabled = false return end
        if c == "SelectionBox" then o.Visible = false return end
        if c == "SelectionSphere" then o.Visible = false return end
    end

    local function clean(root)
        pcall(function()
            for _, o in ipairs(root:GetDescendants()) do
                if not inLocalChar(o) then pcall(nuke, o) end
            end
        end)
        root.DescendantAdded:Connect(function(o)
            if inLocalChar(o) then return end
            pcall(nuke, o)
        end)
    end

    pcall(function() clean(_W) end)
    pcall(function() clean(_SS) end)
    pcall(function() clean(_RS) end)
    pcall(function() clean(_RF) end)
    pcall(function() _W.Map.Benchs:Destroy() end)
    pcall(function() _W.Map.Trash:Destroy() end)
    pcall(function() _W.Map.Trees:Destroy() end)
    pcall(function() _W.Map.Walls:Destroy() end)
    pcall(function() _W.Preload:Destroy() end)
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

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"
local HOP_QUEUE_FLAG = "autofarm_queued.flag"

if _G.__AUTO_FARM_INNER_ACTIVE == true then return end
if typeof(isfile) == "function" and isfile(HOP_QUEUE_FLAG) then
    pcall(function() if typeof(delfile) == "function" then delfile(HOP_QUEUE_FLAG) end end)
end
_G.__AUTO_FARM_INNER_ACTIVE = true

local LocalPlayer = Players.LocalPlayer
local clock = os.clock
local wait_ = task.wait
local spawn_ = task.spawn
local clamp_ = math.clamp
local rad_ = math.rad
local floor_ = math.floor
local random_ = math.random
local insert_ = table.insert
local lower_ = string.lower
local match_ = string.match
local abs_ = math.abs

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

local function setPhysRep(root, target)
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
    local v = Workspace.FallenPartsDestroyHeight
    if v == v then forceFallenHeight() end
end)

local forceHealthConnection = nil
local forceHealthTrackedChar = nil
local killFlag = false

local function setupForceHealth(character)
    if character == nil then return end
    if character == forceHealthTrackedChar then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid == nil then return end
    forceHealthTrackedChar = character
    pcall(function() humanoid.BreakJointsOnDeath = false humanoid.RequiresNeck = false end)
    if forceHealthConnection ~= nil then forceHealthConnection:Disconnect() forceHealthConnection = nil end
    pcall(function() humanoid.MaxHealth = 100 humanoid.Health = 100 end)
    forceHealthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if killFlag then return end
        pcall(function() humanoid.MaxHealth = 100 humanoid.Health = 100 end)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    forceFallenHeight()
    setupForceHealth(Character)
    spawn_(function()
        wait_(0.5)
        if Character == nil then return end
        if Character.Parent == nil then return end
        local ai = Character:FindFirstChild("AbsoluteImmortal")
        if ai ~= nil then pcall(function() ai:Destroy() end) end
        local ff = Character:FindFirstChild("ForceField")
        if ff ~= nil then pcall(function() ff:Destroy() end) end
    end)
    spawn_(function() wait_(1.5) forceFallenHeight() setupForceHealth(Character) end)
    spawn_(function() wait_(2.5) forceFallenHeight() setupForceHealth(Character) end)
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
local HEAD_FIRST_NAME = "Head First"
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
local SPAM_NUMERIC = match_(SPAM_ANIMATION_ID, "%d+") or SPAM_ANIMATION_ID
local SPAM_NUM = tonumber(SPAM_NUMERIC)
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
for _, n in ipairs(LTM_PART_NAMES) do LTM_PART_SET[n] = true end
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
local HOP_TELEPORT_VERIFY_WAIT = 6
local HOP_MAX_ATTEMPTS = 5
local HOP_CANDIDATE_TRY_COUNT = 3
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

local G = _G

local function getGuiParent()
    local gethuiFn = G.gethui
    if typeof(gethuiFn) == "function" then
        local ok, result = pcall(function() return gethuiFn() end)
        if ok and typeof(result) == "Instance" then return result end
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
    math.randomseed(os.time() + random_(1, 1e6))
    local guiParent = getGuiParent()

    do
        local bz = Instance.new("Part")
        bz.Name = "P_" .. randomString(14)
        bz.Size = Vector3.new(2048, 1, 2048)
        bz.CFrame = CFrame.new(BOUND_POSITION)
        bz.Anchored = true
        bz.CanCollide = true
        bz.CanQuery = false
        bz.CanTouch = false
        bz.Transparency = 0.7
        bz.Parent = Workspace
    end

    local saved = readConfig()

    local Cfg = {
        farmEnabled = false,
        performanceMode = true,
        noRenderEnabled = true,
        stealthMode = false,
        serverHopEnabled = false,
        targetKills = 20,
        showsKills = 0,
        initialized = false,
    }

    if saved ~= nil then
        if typeof(saved.farmEnabled) == "boolean" then Cfg.farmEnabled = saved.farmEnabled end
        if typeof(saved.performanceMode) == "boolean" then Cfg.performanceMode = saved.performanceMode end
        if typeof(saved.noRenderEnabled) == "boolean" then Cfg.noRenderEnabled = saved.noRenderEnabled end
        if typeof(saved.stealthMode) == "boolean" then Cfg.stealthMode = saved.stealthMode end
        if typeof(saved.serverHopEnabled) == "boolean" then Cfg.serverHopEnabled = saved.serverHopEnabled end
        if typeof(saved.targetKills) == "number" then Cfg.targetKills = saved.targetKills end
        if typeof(saved.showsKills) == "number" then Cfg.showsKills = saved.showsKills end
    end

    local St = {
        protectionActive = false, rotationRunning = false, lowHealthMode = false,
        selfRagdollActive = false, specialAnimActive = false, forceVoidActive = false,
        detectAnimVoidActive = false, detectAnimVoidLatch = false,
        voidKillingActive = false, voidKillingCounting = false,
        stealthResetPhase = false, hopInProgress = false, hopRequestedStop = false,
        suppressHeartbeatTp = false, inOriginPhase = false, teleportFailedFlag = false,
        windowDragging = false, spaceDown = false,
        voidKillingTimerStart = 0, respawnGraceUntil = 0, stealthResetAt = 0,
        lastRemoteFire = 0, lastEmoteSpin = 0, lastFallbackFire = 0,
        lastGPress = 0, lastJumpPress = 0, lastRagdollFire = 0,
        lastKillsLabelUpdate = 0, lastStatsUpdate = 0, lastStatusRefresh = 0,
        fallbackIndex = 0, lastHopCheck = 0, spaceDownAt = 0,
        currentFps = 60, fpsCounter = 0, lastFpsSample = 0,
        cameraYaw = 0, cameraPitch = rad_(-8), cameraDistance = 20,
        lastSetupCharacter = nil, lastTargetPlayer = nil, pendingTargetPlayer = nil,
        targetSwitchLockUntil = 0, windowDragStart = nil, windowStartPos = nil,
        spamTrack = nil, spamTrackCharacter = nil,
        cachedBackpack = nil, cachedBackpackParent = nil,
        thrownConnection = nil, killsValue = nil, teleportFailConnection = nil,
        rootCacheChar = nil, rootCacheV = nil,
        lastStatusText = nil, lastStatusColor = nil,
        Motor6DS = {}, characterConnections = {}, stripConnections = {},
        permanentConnections = {}, watchedTools = {},
    }

    local Ca = {
        tfT = 0, tfV = false, hotbarT = {}, hotbarV = {},
        specialT = 0, specialV = false, forceVoidT = 0, forceVoidV = false,
        crowdT = 0, crowdV = false,
        prot = setmetatable({}, {__mode = "k"}),
        targetT = 0, targetV = nil, detectT = 0, detectV = false,
    }

    local Pu = {
        model = nil, animator = nil, charRef = nil, animPlayed = nil,
        buildTarget = nil, motorMap = {}, trackMap = {},
    }

    local Lt = { applied = {}, conn = nil, descConn = nil }

    local Gu = {}
    local F = { twinFangsExists = nil, crowdBusterExists = nil, hotbarHasCooldown = nil }

    local function applyNoRender()
        pcall(function() RunService:Set3dRenderingEnabled(not Cfg.noRenderEnabled) end)
    end
    applyNoRender()

    RunService.RenderStepped:Connect(function()
        St.fpsCounter = St.fpsCounter + 1
        local dt = clock() - St.lastFpsSample
        if dt >= 1 then
            local measured = St.fpsCounter / dt
            if measured < 5 then measured = 5 end
            if measured > 240 then measured = 240 end
            St.currentFps = measured
            St.fpsCounter = 0
            St.lastFpsSample = clock()
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
    Main.Size = UDim2.fromOffset(220, 420)
    Main.Position = UDim2.new(0.5, -110, 0.5, -210)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui
    Gu.Main = Main

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 11)
    local mg = Instance.new("UIGradient")
    mg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 22)),
    }
    mg.Rotation = 90
    mg.Parent = Main
    local ms = Instance.new("UIStroke")
    ms.Thickness = 1.2
    ms.Transparency = 0.35
    ms.Parent = Main
    local sg = Instance.new("UIGradient")
    sg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 230, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255)),
    }
    sg.Rotation = 45
    sg.Parent = ms

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 10)
    Pad.PaddingLeft = UDim.new(0, 10)
    Pad.PaddingRight = UDim.new(0, 10)
    Pad.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Farm"
    Title.TextColor3 = Color3.fromRGB(240, 245, 255)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main
    Gu.Title = Title

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 16)
    Status.Position = UDim2.fromOffset(0, 28)
    Status.BackgroundTransparency = 1
    Status.Text = "Mode: Idle"
    Status.TextColor3 = DEFAULT_MODE_COLOR
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main
    Gu.Status = Status

    local function makeToggle(name, text, pos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = Main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(225, 228, 235)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn
        local state = Instance.new("TextLabel")
        state.Name = "State"
        state.Size = UDim2.fromOffset(46, 22)
        state.Position = UDim2.new(1, -52, 0.5, -11)
        state.BackgroundColor3 = Color3.fromRGB(52, 52, 60)
        state.BorderSizePixel = 0
        state.Text = "OFF"
        state.TextColor3 = Color3.fromRGB(190, 190, 195)
        state.TextSize = 10
        state.Font = Enum.Font.GothamBold
        state.Parent = btn
        Instance.new("UICorner", state).CornerRadius = UDim.new(0, 6)
        return btn, state
    end

    local FarmButton, FarmState = makeToggle("AutoFarmToggle", "Auto Farm", UDim2.fromOffset(0, 48))
    local PerfButton, PerfState = makeToggle("PerformanceToggle", "Performance Mode", UDim2.fromOffset(0, 89))
    local NoRenderButton, NoRenderState = makeToggle("NoRenderToggle", "No Render", UDim2.fromOffset(0, 130))
    local StealthButton, StealthState = makeToggle("StealthToggle", "Stealth Mode", UDim2.fromOffset(0, 171))
    local HopButton, HopState = makeToggle("ServerHopToggle", "Server Hop", UDim2.fromOffset(0, 212))
    Gu.FarmState = FarmState
    Gu.PerfState = PerfState
    Gu.NoRenderState = NoRenderState
    Gu.StealthState = StealthState
    Gu.HopState = HopState

    local KillsRow = Instance.new("Frame")
    KillsRow.Size = UDim2.new(1, 0, 0, 26)
    KillsRow.Position = UDim2.fromOffset(0, 254)
    KillsRow.BackgroundTransparency = 1
    KillsRow.Parent = Main

    local KillsLabel = Instance.new("TextLabel")
    KillsLabel.Size = UDim2.new(0.55, 0, 1, 0)
    KillsLabel.BackgroundTransparency = 1
    KillsLabel.Text = "Target Kills:"
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
    KillsBox.Text = tostring(Cfg.targetKills)
    KillsBox.TextColor3 = Color3.fromRGB(240, 245, 255)
    KillsBox.TextSize = 12
    KillsBox.Font = Enum.Font.GothamMedium
    KillsBox.PlaceholderText = "20"
    KillsBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    KillsBox.ClearTextOnFocus = false
    KillsBox.Parent = KillsRow
    Instance.new("UICorner", KillsBox).CornerRadius = UDim.new(0, 6)
    Gu.KillsBox = KillsBox

    local ShowsLabel = Instance.new("TextLabel")
    ShowsLabel.Size = UDim2.new(1, 0, 0, 15)
    ShowsLabel.Position = UDim2.fromOffset(0, 282)
    ShowsLabel.BackgroundTransparency = 1
    ShowsLabel.Text = "Shows Kills: 0"
    ShowsLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    ShowsLabel.TextSize = 11
    ShowsLabel.Font = Enum.Font.Gotham
    ShowsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowsLabel.Parent = Main
    Gu.ShowsLabel = ShowsLabel

    local CurrentLabel = Instance.new("TextLabel")
    CurrentLabel.Size = UDim2.new(1, 0, 0, 15)
    CurrentLabel.Position = UDim2.fromOffset(0, 299)
    CurrentLabel.BackgroundTransparency = 1
    CurrentLabel.Text = "Current Kills: 0"
    CurrentLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    CurrentLabel.TextSize = 11
    CurrentLabel.Font = Enum.Font.Gotham
    CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentLabel.Parent = Main
    Gu.CurrentLabel = CurrentLabel

    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Size = UDim2.new(1, 0, 0, 52)
    WarningLabel.Position = UDim2.fromOffset(0, 316)
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
    Gu.WarningLabel = WarningLabel

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, 0, 0, 20)
    StatsLabel.Position = UDim2.fromOffset(0, 372)
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
    Gu.StatsLabel = StatsLabel

    local function applyLTMToPart(part)
        if part == nil or not part:IsA("BasePart") then return end
        local ok = pcall(function() part.LocalTransparencyModifier = LTM_VALUE end)
        if ok then Lt.applied[part] = true end
    end

    local function scanAndApplyLTM(character)
        if character == nil then return end
        for _, d in ipairs(character:GetDescendants()) do
            if d:IsA("BasePart") and LTM_PART_SET[d.Name] then applyLTMToPart(d) end
        end
    end

    local function restoreAllLTM()
        for part in pairs(Lt.applied) do
            if part ~= nil and part.Parent ~= nil then
                pcall(function() part.LocalTransparencyModifier = 0 end)
            end
        end
        Lt.applied = {}
    end

    local function connectLTMDescendantWatcher(character)
        if Lt.descConn ~= nil then Lt.descConn:Disconnect() Lt.descConn = nil end
        if character == nil then return end
        Lt.descConn = character.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and LTM_PART_SET[d.Name] then
                task.defer(function() applyLTMToPart(d) end)
            end
        end)
    end

    local function startLTMEnforcer()
        if Lt.conn ~= nil then return end
        Lt.conn = RunService.RenderStepped:Connect(function()
            local ch = LocalPlayer.Character
            if ch == nil then return end
            for _, d in ipairs(ch:GetDescendants()) do
                if d:IsA("BasePart") and LTM_PART_SET[d.Name] then
                    if d.LocalTransparencyModifier ~= LTM_VALUE then
                        pcall(function() d.LocalTransparencyModifier = LTM_VALUE end)
                    end
                    Lt.applied[d] = true
                end
            end
        end)
    end

    local function destroyPuppet()
        if Pu.animPlayed ~= nil then pcall(function() Pu.animPlayed:Disconnect() end) Pu.animPlayed = nil end
        if Pu.model ~= nil and Pu.model.Parent ~= nil then pcall(function() Pu.model:Destroy() end) end
        Pu.model = nil Pu.animator = nil Pu.charRef = nil
        Pu.motorMap = {} Pu.trackMap = {}
    end

    local function mirrorTrack(realTrack)
        if Pu.animator == nil then return end
        if Pu.trackMap[realTrack] ~= nil then return end
        local num = tonumber(match_(realTrack.Animation.AnimationId, "%d+"))
        if num == SPAM_NUM then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = realTrack.Animation.AnimationId
        local pt = Pu.animator:LoadAnimation(anim)
        pcall(function()
            pt.Priority = realTrack.Priority
            pt.Looped = realTrack.Looped
            pt:Play(0, realTrack.WeightCurrent, realTrack.Speed)
            pt.TimePosition = realTrack.TimePosition
        end)
        Pu.trackMap[realTrack] = pt
        realTrack.Stopped:Connect(function()
            pcall(function() pt:Stop(0) end)
            Pu.trackMap[realTrack] = nil
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
        for _, d in ipairs(character:GetDescendants()) do
            if d:IsA("Motor6D") and d.Part1 ~= nil then hasMotor = true break end
        end
        if not hasMotor then return false end
        local okClone, clone = pcall(function() return character:Clone() end)
        if not okClone or clone == nil then return false end
        clone.Name = "AnimPuppet"
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
            elseif d:IsA("Humanoid") then d:Destroy() end
        end
        local ac = Instance.new("AnimationController")
        ac.Parent = clone
        local animator = Instance.new("Animator")
        animator.Parent = ac
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Transparency = 1 d.CanCollide = false d.CanQuery = false
                d.CanTouch = false d.Massless = true d.Anchored = true d.CastShadow = false
            end
        end
        local puppetMotorByPart1 = {}
        for _, m in ipairs(clone:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part1 ~= nil then puppetMotorByPart1[m.Part1.Name] = m end
        end
        local newMotorMap = {}
        for _, real in ipairs(character:GetDescendants()) do
            if real:IsA("Motor6D") and real.Part1 ~= nil then
                local pm = puppetMotorByPart1[real.Part1.Name]
                if pm ~= nil then newMotorMap[real] = pm end
            end
        end
        clone.Parent = Workspace
        Pu.model = clone Pu.animator = animator Pu.charRef = character
        Pu.motorMap = newMotorMap Pu.trackMap = {}
        local okTracks, tracks = pcall(function() return realAnimator:GetPlayingAnimationTracks() end)
        if okTracks and tracks ~= nil then
            for _, t in ipairs(tracks) do mirrorTrack(t) end
        end
        Pu.animPlayed = realAnimator.AnimationPlayed:Connect(function(track)
            if Pu.charRef ~= character then return end
            mirrorTrack(track)
        end)
        return true
    end

    local function buildPuppetAsync(character)
        if character == nil then return end
        for i = 1, 40 do
            if Pu.buildTarget ~= character then return end
            if character ~= LocalPlayer.Character then return end
            if character.Parent == nil then return end
            if Pu.charRef == character and Pu.model ~= nil and Pu.model.Parent ~= nil then return end
            local ok = pcall(buildPuppet, character)
            if ok and Pu.charRef == character and Pu.model ~= nil and Pu.model.Parent ~= nil then return end
            task.wait(0.1)
        end
    end

    local function disconnectStripConnections()
        local i = 1
        while i <= #St.stripConnections do
            local c = St.stripConnections[i]
            if c ~= nil then pcall(function() c:Disconnect() end) end
            i = i + 1
        end
        St.stripConnections = {}
    end

    local function stripRespawnProtections(character)
        pcall(function()
            if character == nil or character.Parent == nil then return end
            local ai = character:FindFirstChild("AbsoluteImmortal")
            if ai ~= nil then pcall(function() ai:Destroy() end) end
            local ff = character:FindFirstChild("ForceField")
            if ff ~= nil then pcall(function() ff:Destroy() end) end
        end)
    end

    local function persistConfig()
        writeConfig({
            farmEnabled = Cfg.farmEnabled,
            performanceMode = Cfg.performanceMode,
            noRenderEnabled = Cfg.noRenderEnabled,
            stealthMode = Cfg.stealthMode,
            serverHopEnabled = Cfg.serverHopEnabled,
            targetKills = Cfg.targetKills,
            showsKills = Cfg.showsKills,
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

    local function hasProtection(character)
        if character == nil then return true end
        local now = clock()
        local entry = Ca.prot[character]
        if entry ~= nil then
            if now - entry.t < PROT_CACHE_TTL then return entry.v end
        end
        local v = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then v = true
        elseif character:FindFirstChild("ForceField") ~= nil then v = true
        elseif character:FindFirstChild("FinalDeath") ~= nil then v = true
        elseif character:FindFirstChild("Counter") ~= nil then v = true
        elseif character:FindFirstChild("BeingGrabbed") ~= nil then v = true
        elseif character:FindFirstChild("BeingGrapped") ~= nil then v = true end
        Ca.prot[character] = {t = now, v = v}
        return v
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if character == nil then
            St.rootCacheChar = nil St.rootCacheV = nil
            return nil
        end
        if character == St.rootCacheChar then
            if St.rootCacheV ~= nil and St.rootCacheV.Parent ~= nil then return St.rootCacheV end
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil or not root:IsA("BasePart") then
            St.rootCacheChar = character St.rootCacheV = nil
            return nil
        end
        St.rootCacheChar = character St.rootCacheV = root
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
        local now = clock()
        if now - Ca.specialT < SPECIAL_ANIM_CACHE_TTL then return Ca.specialV end
        Ca.specialT = now
        local character = LocalPlayer.Character
        if character == nil then Ca.specialV = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then Ca.specialV = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then Ca.specialV = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then Ca.specialV = false return false end
        local found = false
        local i = 1
        while i <= #tracks do
            local anim = tracks[i].Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric ~= nil and SPECIAL_ANIM_IDS[numeric] then found = true break end
            end
            i = i + 1
        end
        Ca.specialV = found
        return found
    end

    local function isForceVoidAnimationPlaying()
        local now = clock()
        if now - Ca.forceVoidT < SPECIAL_ANIM_CACHE_TTL then return Ca.forceVoidV end
        Ca.forceVoidT = now
        local character = LocalPlayer.Character
        if character == nil then Ca.forceVoidV = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then Ca.forceVoidV = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then Ca.forceVoidV = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then Ca.forceVoidV = false return false end
        local found = false
        local i = 1
        while i <= #tracks do
            local anim = tracks[i].Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric ~= nil and FORCE_VOID_ANIM_IDS[numeric] then found = true break end
            end
            i = i + 1
        end
        Ca.forceVoidV = found
        return found
    end

    local function isDetectAnimForceVoid()
        local now = clock()
        if now - Ca.detectT < SPECIAL_ANIM_CACHE_TTL then return Ca.detectV end
        Ca.detectT = now
        local character = LocalPlayer.Character
        if character == nil then St.detectAnimVoidLatch = false Ca.detectV = false return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then St.detectAnimVoidLatch = false Ca.detectV = false return false end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then St.detectAnimVoidLatch = false Ca.detectV = false return false end
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if not ok or tracks == nil then St.detectAnimVoidLatch = false Ca.detectV = false return false end
        local isPlaying = false
        local tp = 0
        local i = 1
        while i <= #tracks do
            local anim = tracks[i].Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric == DETECT_ANIM_ID then isPlaying = true tp = tracks[i].TimePosition break end
            end
            i = i + 1
        end
        if not isPlaying or tp > DETECT_TIME_MAX then
            St.detectAnimVoidLatch = false Ca.detectV = false return false
        end
        if tp >= DETECT_TIME_MIN then St.detectAnimVoidLatch = true end
        Ca.detectV = St.detectAnimVoidLatch
        return St.detectAnimVoidLatch
    end

    local function getPlayerRoot(player)
        if player == nil or player == LocalPlayer then return nil end
        local tc = player.Character
        if tc == nil then return nil end
        if hasProtection(tc) then return nil end
        local hum = tc:FindFirstChildOfClass("Humanoid")
        if hum == nil or hum.Health <= 0 then return nil end
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if tr == nil or not tr:IsA("BasePart") then return nil end
        return tr
    end

    local function getClosestPlayerWithin(range, refPos)
        local best = nil
        local bestDSq = range * range
        local players = Players:GetPlayers()
        local rX, rY, rZ = refPos.X, refPos.Y, refPos.Z
        local i = 1
        while i <= #players do
            local player = players[i]
            if player ~= LocalPlayer then
                local tr = getPlayerRoot(player)
                if tr ~= nil then
                    local p = tr.Position
                    local dx, dy, dz = p.X - rX, p.Y - rY, p.Z - rZ
                    local dSq = dx * dx + dy * dy + dz * dz
                    if dSq <= bestDSq then bestDSq = dSq best = player end
                end
            end
            i = i + 1
        end
        return best
    end

    local function getTarget()
        local now = clock()
        if now - Ca.targetT < TARGET_CACHE_TTL then return Ca.targetV end
        Ca.targetT = now
        local root = getRoot()
        if root == nil then
            St.lastTargetPlayer = nil St.pendingTargetPlayer = nil St.targetSwitchLockUntil = 0 Ca.targetV = nil
            return nil
        end
        if St.pendingTargetPlayer ~= nil then
            if now < St.targetSwitchLockUntil then
                Ca.targetV = St.lastTargetPlayer
                return St.lastTargetPlayer
            end
            St.lastTargetPlayer = St.pendingTargetPlayer
            St.pendingTargetPlayer = nil St.targetSwitchLockUntil = 0
        end
        local result = nil
        local close = getClosestPlayerWithin(PROXIMITY_PRIORITY_RANGE, root.Position)
        if close ~= nil then
            result = close
        else
            local lowestHpPlayer = nil
            local lowestHealth = math.huge
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
            result = lowestHpPlayer
        end
        if result == nil then
            St.lastTargetPlayer = nil St.pendingTargetPlayer = nil St.targetSwitchLockUntil = 0 Ca.targetV = nil
            return nil
        end
        if result ~= St.lastTargetPlayer then
            if St.lastTargetPlayer ~= nil then
                St.pendingTargetPlayer = result
                St.targetSwitchLockUntil = now + TARGET_SWITCH_DELAY
                Ca.targetV = St.lastTargetPlayer
                return St.lastTargetPlayer
            end
            St.lastTargetPlayer = result
            Ca.targetV = result
            return result
        end
        Ca.targetV = result
        return result
    end

    local function canAlignToTarget(target)
        if target == nil or target == LocalPlayer then return false end
        local tc = target.Character
        if tc == nil or tc.Parent == nil then return false end
        if hasProtection(tc) then return false end
        local tr = tc:FindFirstChild("HumanoidRootPart")
        if tr == nil or not tr:IsA("BasePart") then return false end
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
        setPhysRep(root, nil)
        root.CFrame = CFrame.new(SAFE_POSITION)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function forceToVoid(root)
        if root == nil then return end
        setPhysRep(root, nil)
        root.CFrame = CFrame.new(SAFE_POSITION)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function pressKey(code)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, code, false, game)
            VirtualInputManager:SendKeyEvent(false, code, false, game)
        end)
    end

    local function pressG()
        if Cfg.stealthMode then return end
        local now = clock()
        if now - St.lastGPress < G_INTERVAL then return end
        if now < St.respawnGraceUntil then return end
        if F.crowdBusterExists ~= nil then
            local ok, cb = pcall(F.crowdBusterExists)
            if ok and cb then return end
        end
        St.lastGPress = now
        pressKey(Enum.KeyCode.G)
    end

    local function pressJump()
        local now = clock()
        if now - St.lastJumpPress < JUMP_INTERVAL then return end
        St.lastJumpPress = now
        if not St.spaceDown then
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end)
            St.spaceDown = true
            St.spaceDownAt = now
        end
    end

    local function tickSpaceRelease()
        if St.spaceDown and clock() - St.spaceDownAt >= SPACE_HOLD_TIME then
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
            St.spaceDown = false
        end
    end

    local function getCommunicate()
        local character = LocalPlayer.Character
        if character == nil then return nil end
        local comm = character:FindFirstChild("Communicate")
        if comm == nil or not comm:IsA("RemoteEvent") then return nil end
        return comm
    end

    local function getMouseCFrame()
        local cam = Workspace.CurrentCamera
        if cam == nil then return nil end
        local mp = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mp.X, mp.Y)
        return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction * 1000)
    end

    local function getBackpack()
        if St.cachedBackpack ~= nil then
            if St.cachedBackpackParent ~= nil and St.cachedBackpack.Parent ~= nil then return St.cachedBackpack end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp ~= nil and bp:IsA("Backpack") then
                St.cachedBackpack = bp St.cachedBackpackParent = bp.Parent
                return bp
            end
            St.cachedBackpack = nil St.cachedBackpackParent = nil
            return nil
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp ~= nil and bp:IsA("Backpack") then
            St.cachedBackpack = bp St.cachedBackpackParent = bp.Parent
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
                if c:IsA("Tool") and lower_(c.Name) == target then return c end
                i = i + 1
            end
        end
        local ch = LocalPlayer.Character
        if ch ~= nil then
            local children = ch:GetChildren()
            local i = 1
            while i <= #children do
                local c = children[i]
                if c:IsA("Tool") and lower_(c.Name) == target then return c end
                i = i + 1
            end
        end
        return nil
    end

    local function findToolExact(name)
        local bp = getBackpack()
        if bp ~= nil then
            local children = bp:GetChildren()
            local i = 1
            while i <= #children do
                local c = children[i]
                if c:IsA("Tool") and c.Name == name then return c end
                i = i + 1
            end
        end
        local ch = LocalPlayer.Character
        if ch ~= nil then
            local children = ch:GetChildren()
            local i = 1
            while i <= #children do
                local c = children[i]
                if c:IsA("Tool") and c.Name == name then return c end
                i = i + 1
            end
        end
        return nil
    end

    F.twinFangsExists = function()
        local now = clock()
        if now - Ca.tfT < TF_CACHE_TTL then return Ca.tfV end
        Ca.tfT = now
        local character = LocalPlayer.Character
        if character == nil then Ca.tfV = false return false end
        if character:GetAttribute("Ulted") == true then Ca.tfV = true return true end
        Ca.tfV = findTool(TWIN_FANGS_NAME) ~= nil
        return Ca.tfV
    end

    F.crowdBusterExists = function()
        local now = clock()
        if now - Ca.crowdT < TF_CACHE_TTL then return Ca.crowdV end
        Ca.crowdT = now
        Ca.crowdV = findTool(CROWD_BUSTER_NAME) ~= nil
        return Ca.crowdV
    end

    local function fireEmoteSpin()
        local now = clock()
        local interval = 2 / St.currentFps
        if interval < EMOTE_SPIN_MIN_INTERVAL then interval = EMOTE_SPIN_MIN_INTERVAL end
        if now - St.lastEmoteSpin < interval then return end
        St.lastEmoteSpin = now
        local comm = getCommunicate()
        if comm == nil then return end
        pcall(function() comm:FireServer({ Goal = "Emote Spin" }) end)
    end

    local function fireCommunicate()
        local now = clock()
        if now - St.lastRemoteFire < REMOTE_COOLDOWN then return end
        St.lastRemoteFire = now
        local comm = getCommunicate()
        if comm == nil then return end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then return end
        local character = LocalPlayer.Character
        if character == nil then return end
        local isM1ing = character:FindFirstChild("M1ing") ~= nil
        pcall(function()
            if Cfg.stealthMode then
                if not isM1ing then comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF }) end
                return
            end
            if F.crowdBusterExists ~= nil and F.crowdBusterExists() then
                if not isM1ing then comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF }) end
            elseif F.twinFangsExists() then
                if isM1ing then
                    comm:FireServer({ Goal = "KeyPress", Key = Enum.KeyCode.F, MousePos = mouseCF })
                    comm:FireServer({ Goal = "LeftClickRelease", Mobile = IS_MOBILE })
                else
                    comm:FireServer({ Goal = "KeyRelease", Key = Enum.KeyCode.F })
                end
            else
                if not isM1ing then comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF }) end
            end
        end)
    end

    local function activateToolViaRemote(tool)
        local comm = getCommunicate()
        if comm == nil then return end
        if tool == nil then return end
        pcall(function() comm:FireServer({ Tool = tool, Goal = "Console Move", IsAutoActivate = true }) end)
    end

    local function fireRagdollFinish()
        local comm = getCommunicate()
        if comm == nil then return end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then return end
        if F.twinFangsExists() then return end
        pcall(function() comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress", MousePos = mouseCF }) end)
    end

    local function tryFireRagdollFinish()
        local now = clock()
        if now - St.lastRagdollFire < RAGDOLL_COOLDOWN then return end
        local target = getTarget()
        if target == nil then return end
        local tc = target.Character
        if tc == nil or tc:FindFirstChild("Ragdoll") == nil then return end
        St.lastRagdollFire = now
        fireRagdollFinish()
    end

    local function getAllTools(exclude)
        local excl = {}
        local i = 1
        while i <= #exclude do excl[lower_(exclude[i])] = true i = i + 1 end
        local result = {}
        local bp = getBackpack()
        if bp ~= nil then
            local children = bp:GetChildren()
            local j = 1
            while j <= #children do
                local c = children[j]
                if c:IsA("Tool") and not excl[lower_(c.Name)] then insert_(result, c) end
                j = j + 1
            end
        end
        local ch = LocalPlayer.Character
        if ch ~= nil then
            local children = ch:GetChildren()
            local j = 1
            while j <= #children do
                local c = children[j]
                if c:IsA("Tool") and not excl[lower_(c.Name)] then insert_(result, c) end
                j = j + 1
            end
        end
        return result
    end

    local function getFilteredFallbackTools()
        local cbActive = false
        if F.crowdBusterExists ~= nil then
            local ok, res = pcall(F.crowdBusterExists)
            if ok then cbActive = res end
        end
        local skipHeadFirst = false
        local tgt = getTarget()
        if tgt ~= nil and tgt.Character ~= nil then
            local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
            if hum ~= nil and hum.MaxHealth > 0 and hum.Health > 0 then
                if (hum.Health / hum.MaxHealth) < LOW_HP_TARGET_FALLBACK_THRESHOLD then skipHeadFirst = true end
            end
        end
        local excl = { TWIN_FANGS_NAME, "Grand Fissure" }
        if skipHeadFirst then table.insert(excl, HEAD_FIRST_NAME) end
        local hhTarget = lower_(HAMMER_HEEL_NAME)
        local bcTarget = lower_(BINDING_CLOTH_NAME)
        local hfTarget = lower_(HEAD_FIRST_NAME)
        local result = {}
        local hh = findTool(HAMMER_HEEL_NAME)
        local bc = findTool(BINDING_CLOTH_NAME)
        if hh ~= nil and bc ~= nil then
            if random_() < 0.5 then insert_(result, hh) insert_(result, bc)
            else insert_(result, bc) insert_(result, hh) end
        elseif hh ~= nil then insert_(result, hh)
        elseif bc ~= nil then insert_(result, bc) end
        if cbActive then
            if #result > 0 then return result end
            return getAllTools(excl)
        end
        local others = getAllTools(excl)
        local i = 1
        while i <= #others do
            local c = others[i]
            local ln = lower_(c.Name)
            if ln ~= hhTarget and ln ~= bcTarget then
                if not (skipHeadFirst and ln == hfTarget) then insert_(result, c) end
            end
            i = i + 1
        end
        if #result > 0 then return result end
        return getAllTools(excl)
    end

    local function genericSpam()
        pressJump() fireCommunicate() tryFireRagdollFinish()
    end

    F.hotbarHasCooldown = function(slot)
        local now = clock()
        local lastT = Ca.hotbarT[slot]
        if lastT ~= nil and now - lastT < HOTBAR_CACHE_TTL then return Ca.hotbarV[slot] end
        Ca.hotbarT[slot] = now
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg == nil then Ca.hotbarV[slot] = false return false end
        local hotbar = pg:FindFirstChild("Hotbar")
        if not hotbar then Ca.hotbarV[slot] = false return false end
        local bp = hotbar:FindFirstChild("Backpack")
        if bp == nil then Ca.hotbarV[slot] = false return false end
        local slots = bp:FindFirstChild("Hotbar")
        if slots == nil then Ca.hotbarV[slot] = false return false end
        local frame = slots:FindFirstChild(tostring(slot))
        if frame == nil then Ca.hotbarV[slot] = false return false end
        local baseFrame = frame:FindFirstChild("Base")
        if baseFrame == nil then Ca.hotbarV[slot] = false return false end
        local result = baseFrame:FindFirstChild("Cooldown") ~= nil
        Ca.hotbarV[slot] = result
        return result
    end

    local function ensureInvisible()
        pcall(function()
            local character = LocalPlayer.Character
            if character == nil then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid == nil then return end
            if humanoid.Health <= 0 then return end
            if St.spamTrackCharacter == character and St.spamTrack ~= nil then
                local okCheck, skip = pcall(function()
                    return St.spamTrack.IsPlaying and St.spamTrack.Speed == 0
                        and St.spamTrack.WeightCurrent > 0.95
                        and abs_(St.spamTrack.TimePosition - SPAM_TIME_POSITION) < 0.005
                end)
                if okCheck and skip then return end
            end
            if St.spamTrackCharacter ~= character then
                if St.spamTrack ~= nil then pcall(function() St.spamTrack:Stop(0) end) end
                St.spamTrack = nil St.spamTrackCharacter = character
            end
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator == nil then
                local na = Instance.new("Animator")
                na.Parent = humanoid
                animator = na
            end
            if animator == nil then return end
            if St.spamTrack == nil then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
                local track = animator:LoadAnimation(anim)
                if typeof(track) == "Instance" then
                    track.Priority = Enum.AnimationPriority.Action4
                    track.Looped = true
                    St.spamTrack = track
                end
            end
            local t = St.spamTrack
            if t == nil then return end
            if not t.IsPlaying then pcall(function() t:Play(0, 1, 0) end) end
            pcall(function()
                t:AdjustSpeed(0)
                t.TimePosition = SPAM_TIME_POSITION
                t:AdjustWeight(1, 0)
            end)
        end)
    end

    local function collectMotor6Ds(character)
        St.Motor6DS = {}
        if character == nil then return end
        local descendants = character:GetDescendants()
        local i = 1
        while i <= #descendants do
            local d = descendants[i]
            if d:IsA("Motor6D") then insert_(St.Motor6DS, d) end
            i = i + 1
        end
    end

    local function getStreak()
        local character = LocalPlayer.Character
        if character == nil then return 0 end
        local v = character:GetAttribute("CurrentStreak")
        if typeof(v) == "number" then return v end
        return 0
    end

    local function killSelf()
        local character = LocalPlayer.Character
        if character == nil then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then return end
        if humanoid.Health > 0 then
            if forceHealthConnection ~= nil then
                forceHealthConnection:Disconnect() forceHealthConnection = nil
            end
            killFlag = true
            pcall(function() humanoid.Health = 0 end)
            killFlag = false
        end
    end

    local function startThrownWatcher()
        if St.thrownConnection ~= nil then St.thrownConnection:Disconnect() end
        local thrown = Workspace:FindFirstChild("Thrown")
        if thrown == nil then return end
        St.thrownConnection = thrown.ChildAdded:Connect(function()
            wait_(THROWN_CLEAR_DELAY)
            pcall(function() thrown:ClearAllChildren() end)
        end)
    end

    local function httpGet(url)
        local res = game:HttpGet(url)
        if typeof(res) == "string" and #res > 0 then return res end
        if typeof(request) == "function" then
            local res2 = request({ Url = url, Method = "GET" })
            if typeof(res2) == "table" then
                if typeof(res2.Body) == "string" and #res2.Body > 0 then return res2.Body end
                if typeof(res2.body) == "string" and #res2.body > 0 then return res2.body end
            end
        end
        if typeof(http_request) == "function" then
            local res3 = http_request({ Url = url, Method = "GET" })
            if typeof(res3) == "table" then
                if typeof(res3.Body) == "string" and #res3.Body > 0 then return res3.Body end
                if typeof(res3.body) == "string" and #res3.body > 0 then return res3.body end
            end
        end
        if typeof(syn) == "table" and typeof(syn.request) == "function" then
            local res4 = syn.request({ Url = url, Method = "GET" })
            if typeof(res4) == "table" then
                if typeof(res4.Body) == "string" and #res4.Body > 0 then return res4.Body end
                if typeof(res4.body) == "string" and #res4.body > 0 then return res4.body end
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
        table.sort(candidates, function(a, b) return a.playing > b.playing end)
        return candidates
    end

    local function ensureTeleportFailListener()
        if St.teleportFailConnection ~= nil then return end
        St.teleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player == LocalPlayer then St.teleportFailedFlag = true end
        end)
    end

    local function attemptTeleport(jobId, originalJob)
        St.teleportFailedFlag = false
        ensureTeleportFailListener()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        local t0 = clock()
        while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
            if not Cfg.serverHopEnabled or St.hopRequestedStop then return false end
            wait_(0.05)
            if game.JobId ~= originalJob then return true end
            if LocalPlayer.Parent == nil then return true end
            if St.teleportFailedFlag then return false end
        end
        return false
    end

    local function queueReexec()
        if typeof(isfile) == "function" and isfile(HOP_QUEUE_FLAG) then return end
        if typeof(writefile) == "function" then pcall(function() writefile(HOP_QUEUE_FLAG, "1") end) end
        local code = "loadstring(game:HttpGet(\"" .. REEXEC_URL .. "\"))()"
        if typeof(queue_on_teleport) == "function" then queue_on_teleport(code)
        elseif typeof(queueonteleport) == "function" then queueonteleport(code)
        elseif typeof(QueueOnTeleport) == "function" then QueueOnTeleport(code)
        elseif typeof(syn) == "table" and typeof(syn.queue_on_teleport) == "function" then syn.queue_on_teleport(code) end
    end

    local function doServerHop()
        if St.hopInProgress then return end
        if not Cfg.serverHopEnabled then return end
        St.hopInProgress = true
        St.hopRequestedStop = false
        refreshStatus()
        queueReexec()
        local originalJob = game.JobId
        local attempt = 0
        while Cfg.serverHopEnabled and not St.hopRequestedStop and St.hopInProgress and attempt < HOP_MAX_ATTEMPTS do
            attempt = attempt + 1
            local servers = fetchServerList()
            if servers ~= nil then
                local candidates = buildCandidates(servers)
                local tryCount = math.min(#candidates, HOP_CANDIDATE_TRY_COUNT)
                local ci = 1
                while ci <= tryCount do
                    if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
                    local c = candidates[ci]
                    if attemptTeleport(c.id, originalJob) then return end
                    wait_(0.3)
                    ci = ci + 1
                end
            end
            if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
            if typeof(serverhop) == "function" then
                serverhop()
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
                    wait_(0.1)
                    if game.JobId ~= originalJob or LocalPlayer.Parent == nil then return end
                end
            end
            if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
            if typeof(ServerHop) == "function" then
                ServerHop()
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
                    wait_(0.1)
                    if game.JobId ~= originalJob or LocalPlayer.Parent == nil then return end
                end
            end
            if not Cfg.serverHopEnabled or St.hopRequestedStop then break end
            wait_(1)
        end
        St.hopInProgress = false
        refreshStatus()
    end

    local function frameAlignUntil(endTime, getTargetRoot)
        local cachedTr = getTargetRoot()
        while clock() < endTime do
            if not Cfg.farmEnabled or St.protectionActive or St.lowHealthMode or St.selfRagdollActive then
                if not St.specialAnimActive then return true end
            end
            if cachedTr ~= nil and cachedTr.Parent == nil then cachedTr = getTargetRoot() end
            local root = getRoot()
            if root ~= nil then setPhysRep(root, cachedTr) root.CFrame = ALIGN_CF end
            pressG()
            wait_()
        end
        return false
    end

    local function activateTwinFangs()
        local deadline = clock() + TF_ACTIVATION_TIMEOUT
        while clock() < deadline do
            if not Cfg.farmEnabled then return false end
            if not St.specialAnimActive then
                if St.protectionActive or St.lowHealthMode or St.selfRagdollActive then return false end
            end
            if F.hotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
            local tf = findTool(TWIN_FANGS_NAME)
            if tf == nil then return false end
            activateToolViaRemote(tf)
            local cachedTr = targetRootForAlign()
            local retryEnd = clock() + TF_RETRY_INTERVAL
            while clock() < retryEnd do
                if F.hotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
                if cachedTr ~= nil and cachedTr.Parent == nil then cachedTr = targetRootForAlign() end
                local r = getRoot()
                if r ~= nil then setPhysRep(r, cachedTr) r.CFrame = ALIGN_CF end
                pressG()
                wait_(0.02)
            end
        end
        return F.hotbarHasCooldown(TWIN_FANGS_SLOT)
    end

    local function runFallbackTools()
        St.suppressHeartbeatTp = false
        local tools = getFilteredFallbackTools()
        if #tools <= 0 then return end
        St.fallbackIndex = St.fallbackIndex + 1
        if St.fallbackIndex > #tools then St.fallbackIndex = 1 end
        local tool = tools[St.fallbackIndex]
        if tool ~= nil and tool.Parent ~= nil then activateToolViaRemote(tool) end
        genericSpam()
    end

    local function isTargetRagdolled(target)
        if target == nil then return false end
        local tc = target.Character
        if tc == nil then return false end
        return tc:FindFirstChild("Ragdoll") ~= nil
    end

    local function isTargetLowHp(target, threshold)
        if target == nil then return false end
        local tc = target.Character
        if tc == nil then return false end
        local hum = tc:FindFirstChildOfClass("Humanoid")
        if hum == nil then return false end
        if hum.MaxHealth <= 0 then return false end
        if hum.Health <= 0 then return false end
        return (hum.Health / hum.MaxHealth) < threshold
    end

    local function rotationStep()
        if not Cfg.farmEnabled then wait_(0.05) return end
        if not St.specialAnimActive then
            if St.protectionActive or St.lowHealthMode or St.selfRagdollActive
                or St.forceVoidActive or St.detectAnimVoidActive then
                wait_(0.05) return
            end
        end
        St.suppressHeartbeatTp = false
        local character = LocalPlayer.Character
        if character == nil then wait_(0.1) return end
        if Cfg.stealthMode then
            local target = getTarget()
            if target ~= nil then
                if canAlignToTarget(target) then
                    local root = getRoot()
                    local tr = target.Character:FindFirstChild("HumanoidRootPart")
                    if root ~= nil and tr ~= nil then setPhysRep(root, tr) root.CFrame = ALIGN_CF end
                end
                runFallbackTools()
            end
            wait_(0.05) return
        end
        local tf = findTool(TWIN_FANGS_NAME)
        if not F.twinFangsExists() then
            local target = getTarget()
            if target ~= nil then
                local runNow = false
                if isTargetRagdolled(target) then runNow = true
                elseif isTargetLowHp(target, LOW_HP_TARGET_FALLBACK_THRESHOLD) then runNow = true end
                if runNow then runFallbackTools() end
            end
            wait_(0.05) return
        end
        if tf == nil then wait_(0.05) return end
        if F.hotbarHasCooldown(TWIN_FANGS_SLOT) then wait_(0.05) return end
        local activated = activateTwinFangs()
        if not activated then wait_(0.05) return end
        frameAlignUntil(clock() + TF_ALIGN_DURATION, targetRootForAlign)
        if not Cfg.farmEnabled then wait_(0.05) return end
        if not St.specialAnimActive then
            if St.protectionActive or St.lowHealthMode or St.selfRagdollActive then wait_(0.05) return end
        end
        local r = getRoot()
        if r == nil then wait_(0.05) return end
        local originPos = Vector3.new(63, 441, 65)
        local originCF = CFrame.new(originPos)
        St.inOriginPhase = true
        St.suppressHeartbeatTp = true
        local _originChar = LocalPlayer.Character
        local voidEnd = clock() + VOID_STAY_DURATION
        while clock() < voidEnd and Cfg.farmEnabled do
            if LocalPlayer.Character ~= _originChar then break end
            local rr = getRoot()
            if rr ~= nil then
                setPhysRep(rr, nil)
                rr.CFrame = CFrame.new(SAFE_POSITION)
                rr.AssemblyLinearVelocity = Vector3.zero
                rr.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            wait_()
        end
        local tpDeadline = clock() + 1.5
        while Cfg.farmEnabled and clock() < tpDeadline do
            if LocalPlayer.Character ~= _originChar then break end
            local rr = getRoot()
            if rr ~= nil then
                setPhysRep(rr, nil)
                rr.AssemblyLinearVelocity = Vector3.zero
                rr.AssemblyAngularVelocity = Vector3.zero
                rr.CFrame = originCF
                local p = rr.Position
                local dx, dy, dz = p.X - originPos.X, p.Y - originPos.Y, p.Z - originPos.Z
                if (dx * dx + dy * dy + dz * dz) < 4 then break end
            end
            wait_()
        end
        local gfDetected = false
        local gfDetectedAt = 0
        local originStartT = clock()
        if F.hotbarHasCooldown(GRAND_FISSURE_SLOT) then gfDetected = true gfDetectedAt = originStartT end
        while Cfg.farmEnabled do
            if LocalPlayer.Character ~= _originChar then break end
            local now = clock()
            if not gfDetected then
                if now - originStartT >= GF_SPAM_TIMEOUT then break end
            else
                if now - gfDetectedAt >= GF_STAY_TIMEOUT then break end
            end
            local rr = getRoot()
            if rr ~= nil then
                setPhysRep(rr, nil)
                rr.CFrame = originCF
                rr.AssemblyLinearVelocity = Vector3.zero
                rr.AssemblyAngularVelocity = Vector3.zero
            end
            pressG()
            if not St.specialAnimActive then
                if St.protectionActive or St.lowHealthMode or St.selfRagdollActive then break end
            end
            local gf = findToolExact(GRAND_FISSURE_NAME)
            if gf ~= nil then
                local cdActive = F.hotbarHasCooldown(GRAND_FISSURE_SLOT)
                if not gfDetected then
                    if cdActive then gfDetected = true gfDetectedAt = clock()
                    else
                        activateToolViaRemote(gf)
                        Ca.hotbarT[GRAND_FISSURE_SLOT] = nil
                        if F.hotbarHasCooldown(GRAND_FISSURE_SLOT) then gfDetected = true gfDetectedAt = clock() end
                    end
                else
                    local stayElapsed = clock() - gfDetectedAt
                    if not cdActive and stayElapsed >= GF_MIN_STAY_AFTER_USE then break end
                end
            else
                local tfTool = findTool(TWIN_FANGS_NAME)
                if tfTool == nil then break end
                if not F.hotbarHasCooldown(TWIN_FANGS_SLOT) then break end
            end
            wait_()
        end
        Ca.hotbarT = {} Ca.hotbarV = {}
        St.inOriginPhase = false
        St.suppressHeartbeatTp = false
    end

    local function runRotationLoop()
        if St.rotationRunning then return end
        St.rotationRunning = true
        refreshStatus()
        while Cfg.farmEnabled do
            local ch = LocalPlayer.Character
            if ch == nil or ch ~= St.lastSetupCharacter then break end
            if not St.specialAnimActive then
                if St.protectionActive or St.lowHealthMode or St.selfRagdollActive
                    or St.forceVoidActive or St.detectAnimVoidActive then break end
            end
            local ok = pcall(rotationStep)
            if not ok then
                St.inOriginPhase = false St.suppressHeartbeatTp = false
            end
            task.wait()
        end
        St.inOriginPhase = false St.suppressHeartbeatTp = false
        St.rotationRunning = false
        refreshStatus()
    end

    local function disconnectCharacterConnections()
        local i = 1
        while i <= #St.characterConnections do
            local c = St.characterConnections[i]
            if c ~= nil then c:Disconnect() end
            i = i + 1
        end
        St.characterConnections = {}
        St.watchedTools = {}
    end

    local function watchTool(tool)
        if St.watchedTools[tool] then return end
        St.watchedTools[tool] = true
    end

    local function watchCharacter(character)
        disconnectCharacterConnections()
        St.cachedBackpack = nil St.cachedBackpackParent = nil
        local bp = getBackpack()
        if bp ~= nil then
            local bpChildren = bp:GetChildren()
            local i = 1
            while i <= #bpChildren do
                local c = bpChildren[i]
                if c:IsA("Tool") then watchTool(c) end
                i = i + 1
            end
            insert_(St.characterConnections, bp.ChildAdded:Connect(function(c)
                if c:IsA("Tool") then watchTool(c) end
            end))
        end
        local charChildren = character:GetChildren()
        local i = 1
        while i <= #charChildren do
            local c = charChildren[i]
            if c:IsA("Tool") then watchTool(c) end
            i = i + 1
        end
        insert_(St.characterConnections, character.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then watchTool(c) end
        end))
        collectMotor6Ds(character)
        insert_(St.characterConnections, character.DescendantAdded:Connect(function(d)
            if d:IsA("Motor6D") then insert_(St.Motor6DS, d) end
        end))
    end

    local function updateKillsFromLeaderstats()
        if St.killsValue ~= nil and St.killsValue.Parent ~= nil then return end
        St.killsValue = nil
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls == nil then return end
        local k = ls:FindFirstChild("Kills")
        if k == nil then return end
        if not k:IsA("IntValue") then return end
        St.killsValue = k
        if not Cfg.initialized then
            Cfg.initialized = true
            Cfg.showsKills = k.Value
            persistConfig()
            refreshKillsDisplay()
        end
    end

    function refreshStatus()
        local text, color
        local ch = LocalPlayer.Character
        local hum = nil
        if ch ~= nil then hum = ch:FindFirstChildOfClass("Humanoid") end
        local isSetup = false
        if ch ~= nil and hum ~= nil and hum.Health > 0 and ch == St.lastSetupCharacter then isSetup = true end
        if not isSetup then
            text = "Mode: Respawning..." color = DEFAULT_MODE_COLOR
        elseif St.stealthResetPhase then
            text = "Mode: Stealth Reset (Void)" color = ANTI_MODE_COLOR
        elseif Cfg.stealthMode and Cfg.farmEnabled then
            text = "Mode: Stealth Farming" color = Color3.fromRGB(150, 200, 255)
        elseif St.forceVoidActive then
            text = "Mode: Force Void" color = VOID_ZONE_COLOR
        elseif St.detectAnimVoidActive then
            text = "Mode: Detect Anim Void" color = VOID_ZONE_COLOR
        elseif St.voidKillingActive then
            text = "Mode: Void Killing" color = VOID_KILLING_COLOR
        elseif St.lowHealthMode then
            text = "Mode: LOW HP - Recovering" color = Color3.fromRGB(255, 90, 90)
        elseif St.selfRagdollActive then
            text = "Mode: Anti (Anti Invisible)" color = ANTI_MODE_COLOR
        elseif St.hopInProgress then
            text = "Mode: Server Hopping" color = DEFAULT_MODE_COLOR
        elseif St.protectionActive then
            text = "Mode: Void Zone" color = VOID_ZONE_COLOR
        elseif F.crowdBusterExists ~= nil and F.crowdBusterExists() then
            text = "Mode: Void Killing" color = VOID_KILLING_COLOR
        elseif F.twinFangsExists ~= nil and F.twinFangsExists() then
            text = "Mode: Farming Kills" color = FARMING_KILLS_COLOR
        else
            text = "Mode: Getting Ultimate and Kills" color = DEFAULT_MODE_COLOR
        end
        if text ~= St.lastStatusText then St.lastStatusText = text Status.Text = text end
        if color ~= St.lastStatusColor then St.lastStatusColor = color Status.TextColor3 = color end
    end

    function refreshKillsDisplay()
        ShowsLabel.Text = "Shows Kills: " .. tostring(Cfg.showsKills)
        if St.killsValue ~= nil then
            CurrentLabel.Text = "Current Kills: " .. tostring(St.killsValue.Value)
        else
            CurrentLabel.Text = "Current Kills: 0"
        end
    end

    local function updateStatsLabel()
        local now = clock()
        if now - St.lastStatsUpdate < 0.5 then return end
        St.lastStatsUpdate = now
        local ping = 0
        local ok, val = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ok and typeof(val) == "number" then ping = floor_(val) end
        local fps = floor_(St.currentFps)
        local fpsColor
        if fps >= 60 then fpsColor = "rgb(120,255,150)"
        elseif fps >= 40 then fpsColor = "rgb(255,190,90)"
        else fpsColor = "rgb(255,90,90)" end
        local pingColor
        if ping < 100 then pingColor = "rgb(120,255,150)"
        elseif ping < 200 then pingColor = "rgb(255,190,90)"
        else pingColor = "rgb(255,90,90)" end
        StatsLabel.Text = string.format(
            'Ping <font color="%s">%d</font> ms  <font color="rgb(80,80,100)">|</font>  Fps <font color="%s">%d</font>',
            pingColor, ping, fpsColor, fps
        )
    end

    local function handleCharacterSetup()
        local ch = LocalPlayer.Character
        if ch == nil then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum == nil then return end
        if hum.Health <= 0 then return end
        if ch == St.lastSetupCharacter then return end
        St.lastSetupCharacter = ch
        St.respawnGraceUntil = clock() + RESPAWN_G_GRACE
        St.inOriginPhase = false St.protectionActive = false St.lowHealthMode = false
        St.selfRagdollActive = false St.specialAnimActive = false St.forceVoidActive = false
        St.detectAnimVoidActive = false St.detectAnimVoidLatch = false
        Ca.detectT = 0 Ca.detectV = false
        St.voidKillingActive = false St.voidKillingCounting = false St.voidKillingTimerStart = 0
        St.stealthResetPhase = false St.stealthResetAt = 0
        St.lastTargetPlayer = nil St.pendingTargetPlayer = nil St.targetSwitchLockUntil = 0
        St.Motor6DS = {}
        if St.spamTrack ~= nil then pcall(function() St.spamTrack:Stop(0) end) end
        St.spamTrack = nil St.spamTrackCharacter = nil
        St.cachedBackpack = nil St.cachedBackpackParent = nil
        St.spaceDown = false St.lastRagdollFire = 0 St.killsValue = nil
        St.suppressHeartbeatTp = false St.inOriginPhase = false
        St.rootCacheChar = nil St.rootCacheV = nil
        Ca.targetT = 0 Ca.targetV = nil Ca.tfT = 0
        Ca.hotbarT = {} Ca.hotbarV = {}
        Ca.specialT = 0 Ca.forceVoidT = 0 Ca.crowdT = 0
        Ca.prot = setmetatable({}, {__mode = "k"})
        St.lastEmoteSpin = 0 St.lastFallbackFire = 0
        disconnectStripConnections()
        disconnectCharacterConnections()
        forceFallenHeight()
        setupForceHealth(ch)
        stripRespawnProtections(ch)
        pcall(function()
            local conn = ch.ChildAdded:Connect(function(c)
                if ch == nil or ch.Parent == nil then return end
                if ch ~= LocalPlayer.Character then return end
                if c == nil then return end
                if c.Name == "AbsoluteImmortal" or c.Name == "ForceField" then
                    pcall(function() c:Destroy() end)
                end
            end)
            insert_(St.stripConnections, conn)
        end)
        watchCharacter(ch)
        scanAndApplyLTM(ch)
        connectLTMDescendantWatcher(ch)
        Pu.buildTarget = ch
        do
            local ok = pcall(buildPuppet, ch)
            if not (ok and Pu.charRef == ch and Pu.model ~= nil and Pu.model.Parent ~= nil) then
                spawn_(function() buildPuppetAsync(ch) end)
            end
        end
        refreshStatus()
    end

    FarmButton.Activated:Connect(function()
        Cfg.farmEnabled = not Cfg.farmEnabled
        setToggle(FarmState, Cfg.farmEnabled)
        if not Cfg.farmEnabled then
            St.inOriginPhase = false St.suppressHeartbeatTp = false
            St.stealthResetPhase = false St.stealthResetAt = 0
        end
        persistConfig()
        refreshStatus()
    end)

    PerfButton.Activated:Connect(function()
        Cfg.performanceMode = not Cfg.performanceMode
        setToggle(PerfState, Cfg.performanceMode)
        persistConfig()
    end)

    NoRenderButton.Activated:Connect(function()
        Cfg.noRenderEnabled = not Cfg.noRenderEnabled
        setToggle(NoRenderState, Cfg.noRenderEnabled)
        applyNoRender()
        persistConfig()
    end)

    StealthButton.Activated:Connect(function()
        Cfg.stealthMode = not Cfg.stealthMode
        setToggle(StealthState, Cfg.stealthMode)
        WarningLabel.Visible = Cfg.stealthMode
        if not Cfg.stealthMode then St.stealthResetPhase = false St.stealthResetAt = 0 end
        persistConfig()
        refreshStatus()
    end)

    HopButton.Activated:Connect(function()
        Cfg.serverHopEnabled = not Cfg.serverHopEnabled
        setToggle(HopState, Cfg.serverHopEnabled)
        persistConfig()
        if not Cfg.serverHopEnabled then
            St.hopRequestedStop = true St.hopInProgress = false
            if typeof(delfile) == "function" then pcall(function() delfile(HOP_QUEUE_FLAG) end) end
            refreshStatus()
        end
    end)

    KillsBox.FocusLost:Connect(function()
        local n = tonumber(KillsBox.Text)
        if n ~= nil and n > 0 then Cfg.targetKills = floor_(n) end
        KillsBox.Text = tostring(Cfg.targetKills)
        persistConfig()
    end)

    setToggle(FarmState, Cfg.farmEnabled)
    setToggle(PerfState, Cfg.performanceMode)
    setToggle(NoRenderState, Cfg.noRenderEnabled)
    setToggle(StealthState, Cfg.stealthMode)
    setToggle(HopState, Cfg.serverHopEnabled)
    WarningLabel.Visible = Cfg.stealthMode
    refreshKillsDisplay()

    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            St.windowDragging = true
            St.windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            St.windowStartPos = Main.Position
        elseif input.UserInputType == Enum.UserInputType.Touch then
            St.windowDragging = true
            St.windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
            St.windowStartPos = Main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if St.windowDragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = Vector2.new(input.Position.X, input.Position.Y) - St.windowDragStart
                Main.Position = UDim2.new(
                    St.windowStartPos.X.Scale,
                    St.windowStartPos.X.Offset + delta.X,
                    St.windowStartPos.Y.Scale,
                    St.windowStartPos.Y.Offset + delta.Y
                )
            end
            return
        end
        local uit = input.UserInputType
        if uit == Enum.UserInputType.MouseMovement then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                St.cameraYaw = St.cameraYaw - input.Delta.X * CAMERA_SENSITIVITY
                St.cameraPitch = clamp_(St.cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY, rad_(-80), rad_(80))
            end
        elseif uit == Enum.UserInputType.Touch then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                St.cameraYaw = St.cameraYaw - input.Delta.X * CAMERA_SENSITIVITY * 1.4
                St.cameraPitch = clamp_(St.cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY * 1.4, rad_(-80), rad_(80))
            end
        elseif uit == Enum.UserInputType.MouseWheel then
            St.cameraDistance = clamp_(St.cameraDistance - input.Position.Z * 2, CAMERA_MIN_DIST, CAMERA_MAX_DIST)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            St.windowDragging = false
        end
    end)

    RunService:BindToRenderStep("CameraSubjectUpdate", Enum.RenderPriority.Camera.Value - 1, function()
        local target = getTarget()
        local localHum = LocalPlayer.Character.Humanoid
        local targetHum = target.Character.Humanoid
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local dist = (rootPart.Position - ALIGN_CF.Position).Magnitude
        local cam = workspace.CurrentCamera
        local desired
        if cam.CameraSubject == targetHum then
            desired = (dist <= 1.6) and targetHum or localHum
        else
            desired = (dist <= 1.2) and targetHum or localHum
        end
        if cam.CameraSubject ~= desired then cam.CameraSubject = desired end
    end)

    insert_(St.permanentConnections, RunService.Heartbeat:Connect(function()
        pcall(handleCharacterSetup)
        pcall(tickSpaceRelease)
        pcall(updateStatsLabel)
        if St.killsValue ~= nil and St.killsValue.Parent ~= nil then
            local now = clock()
            if now - St.lastKillsLabelUpdate > 0.1 then
                St.lastKillsLabelUpdate = now
                pcall(function() CurrentLabel.Text = "Current Kills: " .. tostring(St.killsValue.Value) end)
            end
        end
        if St.lastSetupCharacter ~= LocalPlayer.Character then
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then
                St.lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end
        local character = LocalPlayer.Character
        if character == nil then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil then return end
        if not root:IsA("BasePart") then return end
        St.rootCacheChar = character
        St.rootCacheV = root
        pcall(fireEmoteSpin)
        pcall(ensureInvisible)
        pcall(updateKillsFromLeaderstats)
        pcall(function()
            St.specialAnimActive = isSpecialAnimationPlaying()
            St.forceVoidActive = isForceVoidAnimationPlaying()
            St.detectAnimVoidActive = isDetectAnimForceVoid()
        end)
        if St.forceVoidActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
            return
        end
        if St.detectAnimVoidActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
            return
        end
        St.voidKillingActive = false
        if F.crowdBusterExists ~= nil then
            local okCB, cbVal = pcall(F.crowdBusterExists)
            if okCB and cbVal then
                if F.hotbarHasCooldown(3) and F.hotbarHasCooldown(4) then
                    if not St.voidKillingCounting then
                        St.voidKillingCounting = true St.voidKillingTimerStart = clock()
                    end
                    St.voidKillingActive = true
                    if clock() - St.voidKillingTimerStart >= VOID_KILL_DELAY then
                        St.voidKillingCounting = false St.voidKillingTimerStart = 0
                        pinToSafeZone(root)
                        killSelf()
                        local sn = clock()
                        if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
                        return
                    end
                else
                    St.voidKillingCounting = false St.voidKillingTimerStart = 0
                end
            else
                St.voidKillingCounting = false St.voidKillingTimerStart = 0
            end
        end
        local protected = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then protected = true end
        if protected and not St.protectionActive then St.protectionActive = true
        elseif not protected and St.protectionActive then St.protectionActive = false end
        if St.protectionActive and not St.specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid ~= nil and humanoid.MaxHealth > 0 then
            local pct = humanoid.Health / humanoid.MaxHealth
            if pct < LOW_HP_THRESHOLD then St.lowHealthMode = true
            elseif pct >= LOW_HP_THRESHOLD then St.lowHealthMode = false end
        end
        if St.lowHealthMode and not St.specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
            return
        end
        local ragdollNow = selfHasRagdoll()
        St.selfRagdollActive = ragdollNow
        if St.selfRagdollActive and not St.specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
            return
        end
        if Cfg.stealthMode and Cfg.farmEnabled and not St.specialAnimActive then
            local alive = humanoid ~= nil and humanoid.Health > 0
            if alive and getStreak() >= STEALTH_STREAK_THRESHOLD then
                if not St.stealthResetPhase then St.stealthResetPhase = true St.stealthResetAt = clock() end
                forceToVoid(root)
                if clock() - St.stealthResetAt >= STEALTH_VOID_WAIT then
                    St.stealthResetPhase = false St.stealthResetAt = 0
                    killSelf()
                end
                local sn = clock()
                if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
                return
            elseif St.stealthResetPhase then
                St.stealthResetPhase = false St.stealthResetAt = 0
            end
        end
        local hopNow = clock()
        if Cfg.serverHopEnabled and St.killsValue ~= nil and not St.hopInProgress then
            if hopNow - St.lastHopCheck >= HOP_CHECK_INTERVAL then
                St.lastHopCheck = hopNow
                local live = St.killsValue.Value
                if live < Cfg.showsKills then
                    Cfg.showsKills = live
                    persistConfig()
                    refreshKillsDisplay()
                end
                if (live - Cfg.showsKills) >= Cfg.targetKills then
                    spawn_(function()
                        doServerHop()
                        if St.killsValue ~= nil then
                            Cfg.showsKills = St.killsValue.Value
                            persistConfig()
                            refreshKillsDisplay()
                        end
                    end)
                    return
                end
            end
        end
        if Cfg.farmEnabled and not St.inOriginPhase then
            pressG()
            genericSpam()
            local target = getTarget()
            if target == nil then
                if not St.specialAnimActive then pinToSafeZone(root) end
                if not St.rotationRunning then spawn_(runRotationLoop) end
                local sn = clock()
                if sn - St.lastStatusRefresh >= 0.25 then St.lastStatusRefresh = sn refreshStatus() end
                return
            end
            if isNearVoid() then
                setPhysRep(root, nil)
                if not St.suppressHeartbeatTp and canAlignToTarget(target) then root.CFrame = ALIGN_CF end
            elseif not St.suppressHeartbeatTp and canAlignToTarget(target) then
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if tr ~= nil and tr:IsA("BasePart") then
                    setPhysRep(root, tr)
                    root.CFrame = ALIGN_CF
                end
            end
            if not St.rotationRunning then spawn_(runRotationLoop) end
        elseif Cfg.farmEnabled and St.inOriginPhase then
            if not St.rotationRunning then spawn_(runRotationLoop) end
        end
        local statusNow = clock()
        if statusNow - St.lastStatusRefresh >= 0.25 then
            St.lastStatusRefresh = statusNow
            refreshStatus()
        end
    end))

    insert_(St.permanentConnections, RunService.RenderStepped:Connect(function()
        if Cfg.noRenderEnabled then return end
        if Cfg.performanceMode then
            if St.thrownConnection == nil then startThrownWatcher() end
        else
            if St.thrownConnection ~= nil then St.thrownConnection:Disconnect() St.thrownConnection = nil end
        end
        local character = LocalPlayer.Character
        if character == nil or character ~= St.lastSetupCharacter then return end
        local realRoot = getRoot()
        if realRoot == nil then return end
        local cam = Workspace.CurrentCamera
        if cam == nil then return end
        if sethiddenFn ~= nil then
            pcall(function() sethiddenFn(LocalPlayer, "FrustumStreaming", true) end)
        end
    end))

    insert_(St.permanentConnections, RunService.PreSimulation:Connect(function()
        if Pu.animator == nil then return end
        local toRemove = nil
        for real, pt in pairs(Pu.trackMap) do
            if real.IsPlaying and pt.IsPlaying then
                pcall(function()
                    pt.TimePosition = real.TimePosition
                    pt:AdjustSpeed(real.Speed)
                    pt:AdjustWeight(real.WeightCurrent, 0)
                end)
            elseif real.IsPlaying and not pt.IsPlaying then
                pcall(function()
                    pt:Play(0, real.WeightCurrent, real.Speed)
                    pt.TimePosition = real.TimePosition
                end)
            elseif not real.IsPlaying and pt.IsPlaying then
                if toRemove == nil then toRemove = {} end
                insert_(toRemove, real)
            end
        end
        if toRemove ~= nil then
            local i = 1
            while i <= #toRemove do
                local k = toRemove[i]
                local pt = Pu.trackMap[k]
                if pt ~= nil then pcall(function() pt:Stop(0) end) end
                Pu.trackMap[k] = nil
                i = i + 1
            end
        end
    end))

    insert_(St.permanentConnections, RunService.PreSimulation:Connect(function()
        if Pu.animator == nil then return end
        for real, pm in pairs(Pu.motorMap) do
            if real.Parent ~= nil and pm.Parent ~= nil then real.Transform = pm.Transform end
        end
    end))

    insert_(St.permanentConnections, LocalPlayer.CharacterRemoving:Connect(function()
        pcall(destroyPuppet)
        restoreAllLTM()
    end))

    insert_(St.permanentConnections, Players.PlayerRemoving:Connect(function(player)
        local ch = player.Character
        if ch == nil then return end
        Ca.prot[ch] = nil
    end))

    startLTMEnforcer()
    do
        local _sc = LocalPlayer.Character
        if _sc ~= nil then
            scanAndApplyLTM(_sc)
            connectLTMDescendantWatcher(_sc)
        end
    end
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