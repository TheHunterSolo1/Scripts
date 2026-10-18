local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"
local HOP_QUEUE_FLAG = "autofarm_queued.flag"

if _G.__AUTO_FARM_WRAPPER_ACTIVE == true then
    return
end
_G.__AUTO_FARM_WRAPPER_ACTIVE = true

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
                if not inLocalChar(o) then
                    pcall(nuke, o)
                end
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

local HOP_QUEUE_FLAG = "autofarm_queued.flag"

if _G.__AUTO_FARM_INNER_ACTIVE == true then
    return
end

if typeof(isfile) == "function" and isfile(HOP_QUEUE_FLAG) then
    pcall(function()
        if typeof(delfile) == "function" then
            delfile(HOP_QUEUE_FLAG)
        end
    end)
end

_G.__AUTO_FARM_INNER_ACTIVE = true

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
local fmt_ = string.format

local ALIGN_CF = CFrame.new(0, 0, 6)

local SPECIAL_ANIM_IDS = {
    ["136370737633649"] = true,
    ["18182425133"] = true,
}

local FORCE_VOID_ANIM_IDS = {
    ["94638356008696"] = true,
    ["115484690572880"] = true,
    ["95034083206292"] = true,
}

local sethiddenFn = nil
if typeof(sethiddenproperty) == "function" then
    sethiddenFn = sethiddenproperty
elseif typeof(syn) == "table" and typeof(syn.sethiddenproperty) == "function" then
    sethiddenFn = syn.sethiddenproperty
end

if sethiddenFn ~= nil then
    local ok = pcall(function()
        sethiddenFn(Workspace, "FallenPartsDestroyHeight", 0/0)
    end)
    if not ok then
        sethiddenFn = nil
    end
end

local function setPhysRep(root, target)
    if sethiddenFn == nil then return end
    pcall(function()
        sethiddenFn(root, "PhysicsRepRootPart", target)
    end)
end

local function forceFallenHeight()
    pcall(function()
        Workspace.FallenPartsDestroyHeight = 0/0
    end)
    if sethiddenFn ~= nil then
        pcall(function()
            sethiddenFn(Workspace, "FallenPartsDestroyHeight", 0/0)
        end)
    end
end

forceFallenHeight()

RunService.Heartbeat:Connect(function()
    local v = Workspace.FallenPartsDestroyHeight
    if v == v then
        forceFallenHeight()
    end
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

    pcall(function()
        humanoid.BreakJointsOnDeath = false
        humanoid.RequiresNeck = false
    end)

    if forceHealthConnection ~= nil then
        forceHealthConnection:Disconnect()
        forceHealthConnection = nil
    end

    pcall(function()
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end)

    forceHealthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if killFlag then return end
        pcall(function()
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end)
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
        if ai ~= nil then
            pcall(function() ai:Destroy() end)
        end
        local ff = Character:FindFirstChild("ForceField")
        if ff ~= nil then
            pcall(function() ff:Destroy() end)
        end
    end)

    spawn_(function()
        wait_(1.5)
        forceFallenHeight()
        setupForceHealth(Character)
    end)
    spawn_(function()
        wait_(2.5)
        forceFallenHeight()
        setupForceHealth(Character)
    end)
end)

local CONFIG_PATH = "autofarm_config.json"
local REEXEC_URL = "https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/AutoFarm.luau"

local BOUND_POSITION = Vector3.new(0, -10000, 0)
local SAFE_POSITION = Vector3.new(0, -9997, 0)

local TWIN_FANGS_NAME = "Twin Fangs"
local TWIN_FANGS_SLOT = 2
local CROWD_BUSTER_NAME = "Crowd Buster"
local HAMMER_HEEL_NAME = "Hammer Heel"
local BINDING_CLOTH_NAME = "Binding Cloth"
local LAST_BREATH_NAME = "Last Breath"

local TF_ALIGN_DURATION = 2.2
local TF_BOUNDARY_SETTLE = 3.0
local TF_ACTIVATION_TIMEOUT = 3.0
local TF_RETRY_INTERVAL = 0.1
local FALLBACK_TOOL_DURATION = 1
local FALLBACK_NORMAL_DELAY = 0
local LOW_TARGET_HP_THRESHOLD = 0.25
local VOID_KILL_DELAY = 2.5
local RESPAWN_G_GRACE = 1.5

local LOW_HP_THRESHOLD = 0.2
local TARGET_SWITCH_DELAY = 0.025

local ANTI_MODE_COLOR = Color3.fromRGB(255, 120, 60)
local VOID_ZONE_COLOR = Color3.fromRGB(150, 100, 255)
local VOID_KILLING_COLOR = Color3.fromRGB(200, 80, 255)
local FARMING_KILLS_COLOR = Color3.fromRGB(80, 230, 130)
local DEFAULT_MODE_COLOR = Color3.fromRGB(170, 170, 180)

local SPAM_ANIMATION_ID = "119169968232874"
local SPAM_NUMERIC = match_(SPAM_ANIMATION_ID, "%d+") or SPAM_ANIMATION_ID

local G_INTERVAL = 0.01
local JUMP_INTERVAL = 0.01
local SPACE_HOLD_TIME = 0.03
local RAGDOLL_COOLDOWN = 0.5

local REMOTE_COOLDOWN = 0.03

local EMOTE_SPIN_MIN_INTERVAL = 0.02

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

local FALLBACK_EXCLUDE = { TWIN_FANGS_NAME, "Grand Fissure" }

local PROXIMITY_PRIORITY_RANGE = 50

local ATTACK_POSITION_EPS = 0.01

local MOBILE_UI_SCALE = 0.75

local PROT_CACHE_TTL = 0.03
local TF_CACHE_TTL = 0.1
local HOTBAR_CACHE_TTL = 0.05
local SPECIAL_ANIM_CACHE_TTL = 0.05
local TARGET_CACHE_TTL = 0.03

local VOID_Y_THRESHOLD = -9000

local DRAGON_SOUND_NAME = "Dragon"
local DRAGON_TIME_THRESHOLD = 45
local LAST_BREATH_BLOCK_TIME = 1.5

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
    local noRenderEnabled = true
    local stealthMode = false
    local serverHopEnabled = false
    local targetKills = 20
    local showsKills = 0

    if saved ~= nil then
        if typeof(saved.farmEnabled) == "boolean" then farmEnabled = saved.farmEnabled end
        if typeof(saved.performanceMode) == "boolean" then performanceMode = saved.performanceMode end
        if typeof(saved.noRenderEnabled) == "boolean" then noRenderEnabled = saved.noRenderEnabled end
        if typeof(saved.stealthMode) == "boolean" then stealthMode = saved.stealthMode end
        if typeof(saved.serverHopEnabled) == "boolean" then serverHopEnabled = saved.serverHopEnabled end
        if typeof(saved.targetKills) == "number" then targetKills = saved.targetKills end
        if typeof(saved.showsKills) == "number" then showsKills = saved.showsKills end
    end

    local configExisted = saved ~= nil
    local configInitialized = false

    local function applyNoRender()
        pcall(function()
            RunService:Set3dRenderingEnabled(not noRenderEnabled)
        end)
    end

    applyNoRender()

    local currentFps = 60
    local fpsCounter = 0
    local lastFpsSample = clock()

    RunService.RenderStepped:Connect(function()
        fpsCounter = fpsCounter + 1
        local now = clock()
        local dt = now - lastFpsSample
        if dt >= 1 then
            local measured = fpsCounter / dt
            if measured < 5 then measured = 5 end
            if measured > 240 then measured = 240 end
            currentFps = measured
            fpsCounter = 0
            lastFpsSample = now
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
    Main.Size = UDim2.fromOffset(220, 400)
    Main.ClipsDescendants = false
    Main.Position = UDim2.new(0.5, -110, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 11)
    MainCorner.Parent = Main

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 36)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 22)),
    }
    MainGradient.Rotation = 90
    MainGradient.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.2
    MainStroke.Transparency = 0.35
    MainStroke.Parent = Main

    local StrokeGradient = Instance.new("UIGradient")
    StrokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 230, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255)),
    }
    StrokeGradient.Rotation = 45
    StrokeGradient.Parent = MainStroke

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 10)
    Pad.PaddingLeft = UDim.new(0, 10)
    Pad.PaddingRight = UDim.new(0, 10)
    Pad.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 26)
    Title.Position = UDim2.fromOffset(0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Farm"
    Title.TextColor3 = Color3.fromRGB(240, 245, 255)
    Title.TextSize = 17
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main

    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(1, 0, 0, 16)
    Status.Position = UDim2.fromOffset(0, 28)
    Status.BackgroundTransparency = 1
    Status.Text = "Mode: Idle"
    Status.TextColor3 = DEFAULT_MODE_COLOR
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main

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

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

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

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, 6)
        sc.Parent = state

        return btn, state
    end

    local FarmButton, FarmState = makeToggle("AutoFarmToggle", "Auto Farm", UDim2.fromOffset(0, 48))
    local PerfButton, PerfState = makeToggle("PerformanceToggle", "Performance Mode", UDim2.fromOffset(0, 89))
    local NoRenderButton, NoRenderState = makeToggle("NoRenderToggle", "No Render", UDim2.fromOffset(0, 130))
    local StealthButton, StealthState = makeToggle("StealthToggle", "Stealth Mode", UDim2.fromOffset(0, 171))
    local HopButton, HopState = makeToggle("ServerHopToggle", "Server Hop", UDim2.fromOffset(0, 212))

    local KillsRow = Instance.new("Frame")
    KillsRow.Name = "KillsRow"
    KillsRow.Size = UDim2.new(1, 0, 0, 26)
    KillsRow.Position = UDim2.fromOffset(0, 254)
    KillsRow.BackgroundTransparency = 1
    KillsRow.Parent = Main

    local KillsLabel = Instance.new("TextLabel")
    KillsLabel.Size = UDim2.new(0.55, 0, 1, 0)
    KillsLabel.Position = UDim2.fromOffset(0, 0)
    KillsLabel.BackgroundTransparency = 1
    KillsLabel.Text = "Target Kills:"
    KillsLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
    KillsLabel.TextSize = 12
    KillsLabel.Font = Enum.Font.GothamMedium
    KillsLabel.TextXAlignment = Enum.TextXAlignment.Left
    KillsLabel.Parent = KillsRow

    local KillsBox = Instance.new("TextBox")
    KillsBox.Name = "KillsBox"
    KillsBox.Size = UDim2.new(0.45, 0, 1, 0)
    KillsBox.Position = UDim2.new(0.55, 0, 0, 0)
    KillsBox.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    KillsBox.BorderSizePixel = 0
    KillsBox.Text = tostring(targetKills)
    KillsBox.TextColor3 = Color3.fromRGB(240, 245, 255)
    KillsBox.TextSize = 12
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
    ShowsLabel.Size = UDim2.new(1, 0, 0, 15)
    ShowsLabel.Position = UDim2.fromOffset(0, 282)
    ShowsLabel.BackgroundTransparency = 1
    ShowsLabel.Text = "Shows Kills: 0"
    ShowsLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    ShowsLabel.TextSize = 11
    ShowsLabel.Font = Enum.Font.Gotham
    ShowsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShowsLabel.Parent = Main

    local CurrentLabel = Instance.new("TextLabel")
    CurrentLabel.Name = "CurrentLabel"
    CurrentLabel.Size = UDim2.new(1, 0, 0, 15)
    CurrentLabel.Position = UDim2.fromOffset(0, 299)
    CurrentLabel.BackgroundTransparency = 1
    CurrentLabel.Text = "Current Kills: 0"
    CurrentLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    CurrentLabel.TextSize = 11
    CurrentLabel.Font = Enum.Font.Gotham
    CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentLabel.Parent = Main

    local WarningLabel = Instance.new("TextLabel")
    WarningLabel.Name = "Warning"
    WarningLabel.Size = UDim2.new(1, 0, 0, 38)
    WarningLabel.Position = UDim2.fromOffset(0, 316)
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

    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Name = "StatsLabel"
    StatsLabel.Size = UDim2.new(1, 0, 0, 20)
    StatsLabel.Position = UDim2.fromOffset(0, 356)
    StatsLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    StatsLabel.BackgroundTransparency = 0.15
    StatsLabel.BorderSizePixel = 0
    StatsLabel.RichText = true
    StatsLabel.Text = 'Ping <font color="rgb(150,200,255)">0</font> ms  <font color="rgb(80,80,100)">|</font>  Fps <font color="rgb(150,255,180)">60</font>'
    StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    StatsLabel.TextSize = 11
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.Parent = Main

    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 6)
    StatsCorner.Parent = StatsLabel

    local protectionActive = false
    local rotationRunning = false
    local lowHealthMode = false
    local selfRagdollActive = false
    local attackingActive = false
    local specialAnimActive = false
    local forceVoidActive = false
    local voidKillingActive = false
    local voidKillingCounting = false
    local voidKillingTimerStart = 0
    local respawnGraceUntil = 0
    local lastSetupCharacter = nil

    local protectionOrigin = nil
    local lastRemoteFire = 0
    local lastEmoteSpin = 0
    local lastFallbackFire = 0
    local lastGPress = 0
    local lastJumpPress = 0
    local lastRagdollFire = 0
    local lastKillsLabelUpdate = 0
    local lastStatsUpdate = 0
    local lastStatusRefresh = 0

    local lastBreathFired = false
    local lastBreathBlockUntil = 0

    local characterConnections = {}
    local stripConnections = {}
    local permanentConnections = {}
    local watchedTools = {}
    local targetStates = {}
    local fallbackIndex = 0

    local lastTargetPlayer = nil
    local pendingTargetPlayer = nil
    local targetSwitchLockUntil = 0

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

    local lastCloneCheck = 0
    local lastCloneRebuild = 0

    local spamTrack = nil
    local spamTrackCharacter = nil

    local spaceDown = false
    local spaceDownAt = 0

    local cachedBackpack = nil
    local cachedBackpackParent = nil
    local thrownConnection = nil

    local killsValue = nil
    local lastHopCheck = 0
    local hopInProgress = false
    local hopRequestedStop = false

    local suppressHeartbeatTp = false
    local teleportFailedFlag = false
    local teleportFailConnection = nil

    local tfCacheT = 0
    local tfCacheV = false
    local hotbarCacheT = {}
    local hotbarCacheV = {}
    local specialAnimCacheT = 0
    local specialAnimCacheV = false
    local forceVoidCacheT = 0
    local forceVoidCacheV = false
    local crowdBusterCacheT = 0
    local crowdBusterCacheV = false
    local hammerBindingCacheT = 0
    local hammerBindingCacheV = false
    local protCache = setmetatable({}, {__mode = "k"})
    local targetCacheT = 0
    local targetCacheV = nil
    local rootCacheChar = nil
    local rootCacheV = nil

    local lastStatusText = nil
    local lastStatusColor = nil

    local twinFangsExists = nil
    local crowdBusterExists = nil
    local hammerOrBindingExists = nil
    local hotbarHasCooldown = nil

    local function disconnectStripConnections()
        local i = 1
        while i <= #stripConnections do
            local c = stripConnections[i]
            if c ~= nil then
                pcall(function() c:Disconnect() end)
            end
            i = i + 1
        end
        stripConnections = {}
    end

    local function stripRespawnProtections(character)
        pcall(function()
            if character == nil or character.Parent == nil then return end
            local ai = character:FindFirstChild("AbsoluteImmortal")
            if ai ~= nil then
                pcall(function() ai:Destroy() end)
            end
            local ff = character:FindFirstChild("ForceField")
            if ff ~= nil then
                pcall(function() ff:Destroy() end)
            end
        end)
    end

    local function persistConfig()
        writeConfig({
            farmEnabled = farmEnabled,
            performanceMode = performanceMode,
            noRenderEnabled = noRenderEnabled,
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

    local function hasProtection(character)
        if character == nil then return true end
        local now = clock()
        local entry = protCache[character]
        if entry ~= nil then
            if now - entry.t < PROT_CACHE_TTL then
                return entry.v
            end
        end
        local v = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then
            v = true
        elseif character:FindFirstChild("ForceField") ~= nil then
            v = true
        elseif character:FindFirstChild("FinalDeath") ~= nil then
            v = true
        elseif character:FindFirstChild("Counter") ~= nil then
            v = true
        elseif character:FindFirstChild("BeingGrabbed") ~= nil then
            v = true
        elseif character:FindFirstChild("BeingGrapped") ~= nil then
            v = true
        end
        protCache[character] = {t = now, v = v}
        return v
    end

    local function getRoot()
        local character = LocalPlayer.Character
        if character == nil then
            rootCacheChar = nil
            rootCacheV = nil
            return nil
        end
        if character == rootCacheChar then
            if rootCacheV ~= nil and rootCacheV.Parent ~= nil then
                return rootCacheV
            end
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil or not root:IsA("BasePart") then
            rootCacheChar = character
            rootCacheV = nil
            return nil
        end
        rootCacheChar = character
        rootCacheV = root
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
        if now - specialAnimCacheT < SPECIAL_ANIM_CACHE_TTL then
            return specialAnimCacheV
        end
        specialAnimCacheT = now
        local character = LocalPlayer.Character
        if character == nil then
            specialAnimCacheV = false
            return false
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then
            specialAnimCacheV = false
            return false
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then
            specialAnimCacheV = false
            return false
        end
        local ok, tracks = pcall(function()
            return animator:GetPlayingAnimationTracks()
        end)
        if not ok or tracks == nil then
            specialAnimCacheV = false
            return false
        end
        local found = false
        local i = 1
        while i <= #tracks do
            local anim = tracks[i].Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric ~= nil and SPECIAL_ANIM_IDS[numeric] then
                    found = true
                    break
                end
            end
            i = i + 1
        end
        specialAnimCacheV = found
        return found
    end

    local function isForceVoidAnimationPlaying()
        local now = clock()
        if now - forceVoidCacheT < SPECIAL_ANIM_CACHE_TTL then
            return forceVoidCacheV
        end
        forceVoidCacheT = now
        local character = LocalPlayer.Character
        if character == nil then
            forceVoidCacheV = false
            return false
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then
            forceVoidCacheV = false
            return false
        end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then
            forceVoidCacheV = false
            return false
        end
        local ok, tracks = pcall(function()
            return animator:GetPlayingAnimationTracks()
        end)
        if not ok or tracks == nil then
            forceVoidCacheV = false
            return false
        end
        local found = false
        local i = 1
        while i <= #tracks do
            local anim = tracks[i].Animation
            if anim ~= nil then
                local numeric = match_(anim.AnimationId, "%d+")
                if numeric ~= nil and FORCE_VOID_ANIM_IDS[numeric] then
                    found = true
                    break
                end
            end
            i = i + 1
        end
        forceVoidCacheV = found
        return found
    end

    local function checkAttacking()
        local root = getRoot()
        if root == nil then return false end
        local pos = root.CFrame.Position
        local dx = pos.X
        local dy = pos.Y
        local dz = pos.Z - 6
        return (dx * dx + dy * dy + dz * dz) <= (ATTACK_POSITION_EPS * ATTACK_POSITION_EPS)
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
        local rX = refPos.X
        local rY = refPos.Y
        local rZ = refPos.Z
        local i = 1
        while i <= #players do
            local player = players[i]
            if player ~= LocalPlayer then
                local tr = getPlayerRoot(player)
                if tr ~= nil then
                    local p = tr.Position
                    local dx = p.X - rX
                    local dy = p.Y - rY
                    local dz = p.Z - rZ
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
        local now = clock()
        if now - targetCacheT < TARGET_CACHE_TTL then
            return targetCacheV
        end
        targetCacheT = now
        local root = getRoot()
        if root == nil then
            lastTargetPlayer = nil
            pendingTargetPlayer = nil
            targetSwitchLockUntil = 0
            targetCacheV = nil
            return nil
        end

        if pendingTargetPlayer ~= nil then
            if now < targetSwitchLockUntil then
                targetCacheV = lastTargetPlayer
                return lastTargetPlayer
            end
            lastTargetPlayer = pendingTargetPlayer
            pendingTargetPlayer = nil
            targetSwitchLockUntil = 0
        end

        local result = nil

        local close = getClosestPlayerWithin(PROXIMITY_PRIORITY_RANGE, root.Position)
        if close ~= nil then
            result = close
        else
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
            result = lowestHpPlayer
        end

        if result == nil then
            lastTargetPlayer = nil
            pendingTargetPlayer = nil
            targetSwitchLockUntil = 0
            targetCacheV = nil
            return nil
        end

        if result ~= lastTargetPlayer then
            if lastTargetPlayer ~= nil then
                pendingTargetPlayer = result
                targetSwitchLockUntil = now + TARGET_SWITCH_DELAY
                targetCacheV = lastTargetPlayer
                return lastTargetPlayer
            end
            lastTargetPlayer = result
            targetCacheV = result
            return result
        end

        targetCacheV = result
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
        local now = clock()
        if now - lastGPress < G_INTERVAL then return end
        if now < respawnGraceUntil then return end
        if crowdBusterExists ~= nil then
            local ok, cb = pcall(crowdBusterExists)
            if ok and cb then return end
        end
        lastGPress = now
        pressKey(Enum.KeyCode.G)
    end

    local function pressJump()
        local now = clock()
        if now - lastJumpPress < JUMP_INTERVAL then return end
        lastJumpPress = now
        if not spaceDown then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            end)
            spaceDown = true
            spaceDownAt = now
        end
    end

    local function tickSpaceRelease()
        if spaceDown and clock() - spaceDownAt >= SPACE_HOLD_TIME then
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            spaceDown = false
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
        if cachedBackpack ~= nil then
            if cachedBackpackParent ~= nil and cachedBackpack.Parent ~= nil then
                return cachedBackpack
            end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp ~= nil and bp:IsA("Backpack") then
                cachedBackpack = bp
                cachedBackpackParent = bp.Parent
                return bp
            end
            cachedBackpack = nil
            cachedBackpackParent = nil
            return nil
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp ~= nil and bp:IsA("Backpack") then
            cachedBackpack = bp
            cachedBackpackParent = bp.Parent
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
                if c:IsA("Tool") and lower_(c.Name) == target then
                    return c
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
                if c:IsA("Tool") and lower_(c.Name) == target then
                    return c
                end
                i = i + 1
            end
        end
        return nil
    end

    twinFangsExists = function()
        local now = clock()
        if now - tfCacheT < TF_CACHE_TTL then
            return tfCacheV
        end
        tfCacheT = now
        local character = LocalPlayer.Character
        if character == nil then
            tfCacheV = false
            return false
        end
        if character:GetAttribute("Ulted") == true then
            tfCacheV = true
            return true
        end
        tfCacheV = findTool(TWIN_FANGS_NAME) ~= nil
        return tfCacheV
    end

    crowdBusterExists = function()
        local now = clock()
        if now - crowdBusterCacheT < TF_CACHE_TTL then
            return crowdBusterCacheV
        end
        crowdBusterCacheT = now
        crowdBusterCacheV = findTool(CROWD_BUSTER_NAME) ~= nil
        return crowdBusterCacheV
    end

    hammerOrBindingExists = function()
        local now = clock()
        if now - hammerBindingCacheT < TF_CACHE_TTL then
            return hammerBindingCacheV
        end
        hammerBindingCacheT = now
        hammerBindingCacheV = findTool(HAMMER_HEEL_NAME) ~= nil or findTool(BINDING_CLOTH_NAME) ~= nil
        return hammerBindingCacheV
    end

    local function fireEmoteSpin()
        local now = clock()
        local interval = 2 / currentFps
        if interval < EMOTE_SPIN_MIN_INTERVAL then
            interval = EMOTE_SPIN_MIN_INTERVAL
        end
        if now - lastEmoteSpin < interval then return end
        lastEmoteSpin = now
        local comm = getCommunicate()
        if comm == nil then return end
        pcall(function()
            comm:FireServer({ Goal = "Emote Spin" })
        end)
    end

    local function fireCommunicate()
        local now = clock()
        if now - lastRemoteFire < REMOTE_COOLDOWN then return end
        lastRemoteFire = now
        local comm = getCommunicate()
        if comm == nil then return end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then return end

        local character = LocalPlayer.Character
        if character == nil then return end
        local isM1ing = character:FindFirstChild("M1ing") ~= nil

        pcall(function()
            if crowdBusterExists ~= nil and crowdBusterExists() then
                if not isM1ing then
                    comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF })
                end
            elseif twinFangsExists() then
                if isM1ing then
                    comm:FireServer({
                        Goal = "KeyPress",
                        Key = Enum.KeyCode.F,
                        MousePos = mouseCF
                    })
                    comm:FireServer({
                        Goal = "LeftClickRelease",
                        Mobile = IS_MOBILE
                    })
                else
                    comm:FireServer({
                        Goal = "KeyRelease",
                        Key = Enum.KeyCode.F
                    })
                end
            else
                if not isM1ing then
                    comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF })
                end
            end
        end)
    end

    local function activateToolViaRemote(tool)
        local comm = getCommunicate()
        if comm == nil then return end
        if tool == nil then return end
        pcall(function()
            comm:FireServer({ Tool = tool, Goal = "Console Move", IsAutoActivate = true })
        end)
    end

    local function fireRagdollFinish()
        local comm = getCommunicate()
        if comm == nil then return end
        local mouseCF = getMouseCFrame()
        if mouseCF == nil then return end
        if twinFangsExists() then return end
        pcall(function()
            comm:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress", MousePos = mouseCF })
        end)
    end

    local function tryFireRagdollFinish()
        local now = clock()
        if now - lastRagdollFire < RAGDOLL_COOLDOWN then return end
        local target = getTarget()
        if target == nil then return end
        local tc = target.Character
        if tc == nil or tc:FindFirstChild("Ragdoll") == nil then return end
        lastRagdollFire = now
        fireRagdollFinish()
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
                if c:IsA("Tool") and not excl[lower_(c.Name)] then
                    insert_(result, c)
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
                if c:IsA("Tool") and not excl[lower_(c.Name)] then
                    insert_(result, c)
                end
                j = j + 1
            end
        end
        return result
    end

    local function getFilteredFallbackTools()
        local cbActive = false
        if crowdBusterExists ~= nil then
            local ok, res = pcall(crowdBusterExists)
            if ok then cbActive = res end
        end

        local hhTarget = lower_(HAMMER_HEEL_NAME)
        local bcTarget = lower_(BINDING_CLOTH_NAME)
        local result = {}

        local hh = findTool(HAMMER_HEEL_NAME)
        local bc = findTool(BINDING_CLOTH_NAME)

        if hh ~= nil and bc ~= nil then
            if random_() < 0.5 then
                insert_(result, hh)
                insert_(result, bc)
            else
                insert_(result, bc)
                insert_(result, hh)
            end
        elseif hh ~= nil then
            insert_(result, hh)
        elseif bc ~= nil then
            insert_(result, bc)
        end

        if cbActive then
            if #result > 0 then
                return result
            end
            return getAllTools(FALLBACK_EXCLUDE)
        end

        local others = getAllTools(FALLBACK_EXCLUDE)
        local i = 1
        while i <= #others do
            local c = others[i]
            local ln = lower_(c.Name)
            if ln ~= hhTarget and ln ~= bcTarget then
                insert_(result, c)
            end
            i = i + 1
        end

        if #result > 0 then
            return result
        end
        return getAllTools(FALLBACK_EXCLUDE)
    end

    local function genericSpam()
        pressJump()
        fireCommunicate()
        tryFireRagdollFinish()
    end

    hotbarHasCooldown = function(slot)
        local now = clock()
        local lastT = hotbarCacheT[slot]
        if lastT ~= nil and now - lastT < HOTBAR_CACHE_TTL then
            return hotbarCacheV[slot]
        end
        hotbarCacheT[slot] = now
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg == nil then
            hotbarCacheV[slot] = false
            return false
        end
        local hotbar = pg:FindFirstChild("Hotbar")
        if not hotbar then
            hotbarCacheV[slot] = false
            return false
        end
        local bp = hotbar:FindFirstChild("Backpack")
        if bp == nil then
            hotbarCacheV[slot] = false
            return false
        end
        local slots = bp:FindFirstChild("Hotbar")
        if slots == nil then
            hotbarCacheV[slot] = false
            return false
        end
        local frame = slots:FindFirstChild(tostring(slot))
        if frame == nil then
            hotbarCacheV[slot] = false
            return false
        end
        local baseFrame = frame:FindFirstChild("Base")
        if baseFrame == nil then
            hotbarCacheV[slot] = false
            return false
        end
        local result = baseFrame:FindFirstChild("Cooldown") ~= nil
        hotbarCacheV[slot] = result
        return result
    end

    local function ensureInvisible()
        pcall(function()
            local character = LocalPlayer.Character
            if character == nil then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid == nil then return end
            if humanoid.Health <= 0 then return end

            if spamTrackCharacter == character and spamTrack ~= nil then
                local okCheck = pcall(function()
                    return spamTrack.IsPlaying and spamTrack.Speed == 0 and spamTrack.WeightCurrent > 0.95
                end)
                if okCheck then
                    if spamTrack.IsPlaying and spamTrack.Speed == 0 and spamTrack.WeightCurrent > 0.95 then
                        return
                    end
                end
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
            if animator == nil then return end

            if spamTrack == nil then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
                local track = animator:LoadAnimation(anim)
                if typeof(track) == "Instance" then
                    track.Priority = Enum.AnimationPriority.Action4
                    track.Looped = true
                    spamTrack = track
                end
            end

            local t = spamTrack
            if t == nil then return end
            if not t.IsPlaying then
                pcall(function() t:Play(0, 1, 0) end)
            end
            pcall(function()
                t:AdjustSpeed(0)
                t.TimePosition = 0
                t:AdjustWeight(1, 0)
            end)
        end)
    end

    local function validateClone()
        local cc = cloneCharacter
        if cc == nil or cc.Parent == nil then return false end
        if cc:FindFirstChild("HumanoidRootPart") == nil then return false end
        if cc:FindFirstChildOfClass("Humanoid") == nil then return false end
        if cc:FindFirstChild("Head") == nil then return false end
        local ch = LocalPlayer.Character
        if ch == nil then return false end
        if ch:FindFirstChild("HumanoidRootPart") == nil then return false end
        return true
    end

    local function getCloneAnimator()
        local ca = cloneAnimator
        if ca ~= nil and ca.Parent ~= nil then return ca end
        local ch = cloneHumanoid
        if ch == nil or ch.Parent == nil then return nil end
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
        if character == nil or cc == nil or cc.Parent == nil then return end
        local ca = getCloneAnimator()
        if ca == nil then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid == nil then return end
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator == nil then return end

        local ok, tracks = pcall(function()
            return animator:GetPlayingAnimationTracks()
        end)
        if not ok or tracks == nil then return end

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
                        local t = ca:LoadAnimation(cloneAnim)
                        if typeof(t) == "Instance" then
                            mirror = t
                            mirror.Priority = track.Priority
                            mirror.Looped = track.Looped
                            animationMirrors[track] = mirror
                            pcall(function()
                                mirror:Play(0, 1, track.Speed)
                                mirror.TimePosition = track.TimePosition
                            end)
                        end
                    end
                    local m = mirror
                    if m ~= nil then
                        pcall(function()
                            m.Priority = track.Priority
                            m.Looped = track.Looped
                            if not m.IsPlaying then m:Play(0, 1, track.Speed) end
                            local w = track.WeightCurrent
                            if w < 0.01 then w = 0.01 end
                            m:AdjustWeight(w, 0)
                            if abs_(m.Speed - track.Speed) > 0.001 then m:AdjustSpeed(track.Speed) end
                            if m.TimePosition ~= track.TimePosition then m.TimePosition = track.TimePosition end
                        end)
                    end
                end
            end
            i = i + 1
        end

        local toRemove = {}
        local trackKey, mirrorValue = next(animationMirrors)
        while trackKey ~= nil do
            if not active[trackKey] then
                pcall(function()
                    if mirrorValue.IsPlaying then mirrorValue:Stop(0.05) end
                end)
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
        if old ~= nil then old:Destroy() end
        cloneCharacter = nil
        cloneRoot = nil
        cloneHumanoid = nil
        cloneAnimator = nil
        animationMirrors = {}

        local character = LocalPlayer.Character
        if character == nil then return end
        if character:FindFirstChild("HumanoidRootPart") == nil then return end
        if character:FindFirstChildOfClass("Humanoid") == nil then return end

        local clone = character:Clone()
        if typeof(clone) ~= "Instance" then return end
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
                    if kid:IsA("Sound") or kid:IsA("SoundGroup") then kid:Destroy() end
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
        if root ~= nil and root:IsA("BasePart") then cloneRoot = root end
    end

    local function createClone()
        pcall(createCloneInner)
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
                forceHealthConnection:Disconnect()
                forceHealthConnection = nil
            end
            killFlag = true
            pcall(function()
                humanoid.Health = 0
            end)
            killFlag = false
        end
    end

    local function startThrownWatcher()
        if thrownConnection ~= nil then thrownConnection:Disconnect() end
        local thrown = Workspace:FindFirstChild("Thrown")
        if thrown == nil then return end
        thrownConnection = thrown.ChildAdded:Connect(function()
            wait_(THROWN_CLEAR_DELAY)
            pcall(function()
                thrown:ClearAllChildren()
            end)
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
        sort_(candidates, function(a, b) return a.playing > b.playing end)
        return candidates
    end

    local function ensureTeleportFailListener()
        if teleportFailConnection ~= nil then return end
        teleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player)
            if player == LocalPlayer then teleportFailedFlag = true end
        end)
    end

    local function attemptTeleport(jobId, originalJob)
        teleportFailedFlag = false
        ensureTeleportFailListener()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        local t0 = clock()
        while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
            if not serverHopEnabled or hopRequestedStop then return false end
            wait_(0.05)
            if game.JobId ~= originalJob then return true end
            if LocalPlayer.Parent == nil then return true end
            if teleportFailedFlag then return false end
        end
        return false
    end

    local function queueReexec()
        if typeof(isfile) == "function" and isfile(HOP_QUEUE_FLAG) then
            return
        end
        if typeof(writefile) == "function" then
            pcall(function()
                writefile(HOP_QUEUE_FLAG, "1")
            end)
        end
        local code = "loadstring(game:HttpGet(\"" .. REEXEC_URL .. "\"))()"
        if typeof(queue_on_teleport) == "function" then
            queue_on_teleport(code)
        elseif typeof(queueonteleport) == "function" then
            queueonteleport(code)
        elseif typeof(QueueOnTeleport) == "function" then
            QueueOnTeleport(code)
        elseif typeof(syn) == "table" and typeof(syn.queue_on_teleport) == "function" then
            syn.queue_on_teleport(code)
        end
    end

    local function doServerHop()
        if hopInProgress then return end
        if not serverHopEnabled then return end
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
                    if not serverHopEnabled or hopRequestedStop then break end
                    local c = candidates[ci]
                    if attemptTeleport(c.id, originalJob) then return end
                    wait_(0.3)
                    ci = ci + 1
                end
            end
            if not serverHopEnabled or hopRequestedStop then break end
            if typeof(serverhop) == "function" then
                serverhop()
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not serverHopEnabled or hopRequestedStop then break end
                    wait_(0.1)
                    if game.JobId ~= originalJob or LocalPlayer.Parent == nil then return end
                end
            end
            if not serverHopEnabled or hopRequestedStop then break end
            if typeof(ServerHop) == "function" then
                ServerHop()
                local t0 = clock()
                while clock() - t0 < HOP_TELEPORT_VERIFY_WAIT do
                    if not serverHopEnabled or hopRequestedStop then break end
                    wait_(0.1)
                    if game.JobId ~= originalJob or LocalPlayer.Parent == nil then return end
                end
            end
            if not serverHopEnabled or hopRequestedStop then break end
            wait_(1)
        end
        hopInProgress = false
        refreshStatus()
    end

    local function frameAlignUntil(endTime, getTargetRoot)
        local cachedTr = getTargetRoot()
        while clock() < endTime do
            if not farmEnabled or protectionActive or lowHealthMode or selfRagdollActive then
                if not specialAnimActive then return true end
            end
            if cachedTr ~= nil and cachedTr.Parent == nil then
                cachedTr = getTargetRoot()
            end
            local root = getRoot()
            if root ~= nil and cachedTr ~= nil then
                setPhysRep(root, cachedTr)
                root.CFrame = ALIGN_CF
            end
            pressG()
            wait_()
        end
        return false
    end

    local function activateTwinFangs()
        local deadline = clock() + TF_ACTIVATION_TIMEOUT
        while clock() < deadline do
            if not farmEnabled then return false end
            if not specialAnimActive then
                if protectionActive or lowHealthMode or selfRagdollActive then return false end
            end
            if hotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
            local tf = findTool(TWIN_FANGS_NAME)
            if tf == nil then return false end
            activateToolViaRemote(tf)

            local cachedTr = targetRootForAlign()
            local retryEnd = clock() + TF_RETRY_INTERVAL
            while clock() < retryEnd do
                if hotbarHasCooldown(TWIN_FANGS_SLOT) then return true end
                if cachedTr ~= nil and cachedTr.Parent == nil then
                    cachedTr = targetRootForAlign()
                end
                local r = getRoot()
                if r ~= nil and cachedTr ~= nil then
                    setPhysRep(r, cachedTr)
                    r.CFrame = ALIGN_CF
                end
                pressG()
                wait_(0.02)
            end
        end
        return hotbarHasCooldown(TWIN_FANGS_SLOT)
    end

    local function runFallbackTools()
        suppressHeartbeatTp = false
        local tools = getFilteredFallbackTools()
        if #tools <= 0 then return end
        fallbackIndex = fallbackIndex + 1
        if fallbackIndex > #tools then fallbackIndex = 1 end
        local tool = tools[fallbackIndex]
        if tool ~= nil and tool.Parent ~= nil then
            activateToolViaRemote(tool)
        end
        genericSpam()
    end

    local function isTargetRagdolled(target)
        if target == nil then return false end
        local tc = target.Character
        if tc == nil then return false end
        return tc:FindFirstChild("Ragdoll") ~= nil
    end

    local function tryLastBreath(root)
        if root == nil then return false end

        local dragon = nil
        local okFind, found = pcall(function()
            return root:FindFirstChild(DRAGON_SOUND_NAME)
        end)
        if okFind then
            dragon = found
        end
        if dragon == nil then
            lastBreathFired = false
            return false
        end
        local isSound = false
        pcall(function()
            isSound = dragon:IsA("Sound")
        end)
        if not isSound then
            lastBreathFired = false
            return false
        end

        local tp = 0
        local okTp = pcall(function()
            tp = dragon.TimePosition
        end)
        if not okTp then
            lastBreathFired = false
            return false
        end
        if typeof(tp) ~= "number" then
            lastBreathFired = false
            return false
        end
        if tp <= DRAGON_TIME_THRESHOLD then
            lastBreathFired = false
            return false
        end
        if lastBreathFired then
            return clock() < lastBreathBlockUntil
        end

        local lbTool = findTool(LAST_BREATH_NAME)
        if lbTool == nil then
            return false
        end

        activateToolViaRemote(lbTool)

        local comm = getCommunicate()
        if comm ~= nil then
            local mouseCF = getMouseCFrame()
            if mouseCF ~= nil then
                pcall(function()
                    comm:FireServer({ Mobile = IS_MOBILE, Goal = "LeftClick", MousePos = mouseCF })
                end)
            end
        end

        lastBreathFired = true
        lastBreathBlockUntil = clock() + LAST_BREATH_BLOCK_TIME
        return true
    end

    local function rotationStep()
        if not farmEnabled then
            wait_(0.05)
            return
        end

        if not specialAnimActive then
            if protectionActive or lowHealthMode or selfRagdollActive then
                wait_(0.05)
                return
            end
        end

        suppressHeartbeatTp = false

        local character = LocalPlayer.Character
        if character == nil then
            wait_(0.1)
            return
        end

        local tf = findTool(TWIN_FANGS_NAME)

        if not twinFangsExists() then
            local target = getTarget()
            if target ~= nil then
                if isTargetRagdolled(target) then
                    runFallbackTools()
                end
            end
            wait_(0.05)
            return
        end

        if tf == nil then
            wait_(0.05)
            return
        end

        if hotbarHasCooldown(TWIN_FANGS_SLOT) then
            wait_(0.05)
            return
        end

        local activated = activateTwinFangs()
        if not activated then
            wait_(0.05)
            return
        end
        frameAlignUntil(clock() + TF_ALIGN_DURATION, targetRootForAlign)

        if not farmEnabled then
            wait_(0.05)
            return
        end
        if not specialAnimActive then
            if protectionActive or lowHealthMode or selfRagdollActive then
                wait_(0.05)
                return
            end
        end

        suppressHeartbeatTp = true

        local settleEnd = clock() + TF_BOUNDARY_SETTLE
        while farmEnabled do
            if not specialAnimActive then
                if protectionActive or lowHealthMode or selfRagdollActive then break end
            end
            if clock() >= settleEnd then break end
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
            wait_(0.05)
            return
        end
        if not specialAnimActive then
            if protectionActive or lowHealthMode or selfRagdollActive then
                wait_(0.05)
                return
            end
        end

        while farmEnabled do
            if not specialAnimActive then
                if protectionActive or lowHealthMode or selfRagdollActive then break end
            end
            if not hotbarHasCooldown(TWIN_FANGS_SLOT) then break end
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
        if rotationRunning then return end
        rotationRunning = true
        refreshStatus()

        while farmEnabled do
            if not specialAnimActive then
                if protectionActive or lowHealthMode or selfRagdollActive then break end
            end
            rotationStep()
            task.wait()
        end

        suppressHeartbeatTp = false
        rotationRunning = false
        refreshStatus()
    end

    local function disconnectCharacterConnections()
        local i = 1
        while i <= #characterConnections do
            local c = characterConnections[i]
            if c ~= nil then c:Disconnect() end
            i = i + 1
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
        cachedBackpackParent = nil

        local bp = getBackpack()
        if bp ~= nil then
            local bpChildren = bp:GetChildren()
            local i = 1
            while i <= #bpChildren do
                local c = bpChildren[i]
                if c:IsA("Tool") then watchTool(c) end
                i = i + 1
            end
            insert_(characterConnections, bp.ChildAdded:Connect(function(c)
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
        insert_(characterConnections, character.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then watchTool(c) end
        end))

        createClone()
        lastCloneRebuild = clock()
    end

    local function updateKillsFromLeaderstats()
        if killsValue ~= nil and killsValue.Parent ~= nil then return end
        killsValue = nil
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls == nil then return end
        local k = ls:FindFirstChild("Kills")
        if k == nil then return end
        if not k:IsA("IntValue") then return end
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

    function refreshStatus()
        local text
        local color
        local ch = LocalPlayer.Character
        local hum = nil
        if ch ~= nil then
            hum = ch:FindFirstChildOfClass("Humanoid")
        end
        local isSetup = false
        if ch ~= nil and hum ~= nil and hum.Health > 0 and ch == lastSetupCharacter then
            isSetup = true
        end

        if not isSetup then
            text = "Mode: Respawning..."
            color = DEFAULT_MODE_COLOR
        elseif forceVoidActive then
            text = "Mode: Force Void"
            color = VOID_ZONE_COLOR
        elseif voidKillingActive then
            text = "Mode: Void Killing"
            color = VOID_KILLING_COLOR
        elseif lowHealthMode then
            text = "Mode: LOW HP - Recovering"
            color = Color3.fromRGB(255, 90, 90)
        elseif selfRagdollActive then
            text = "Mode: Anti (Anti Invisible)"
            color = ANTI_MODE_COLOR
        elseif hopInProgress then
            text = "Mode: Server Hopping"
            color = DEFAULT_MODE_COLOR
        elseif protectionActive then
            text = "Mode: Void Zone"
            color = VOID_ZONE_COLOR
        elseif crowdBusterExists ~= nil and crowdBusterExists() then
            text = "Mode: Void Killing"
            color = VOID_KILLING_COLOR
        elseif twinFangsExists ~= nil and twinFangsExists() then
            text = "Mode: Farming Kills"
            color = FARMING_KILLS_COLOR
        else
            text = "Mode: Getting Ultimate and Kills"
            color = DEFAULT_MODE_COLOR
        end
        if text ~= lastStatusText then
            lastStatusText = text
            Status.Text = text
        end
        if color ~= lastStatusColor then
            lastStatusColor = color
            Status.TextColor3 = color
        end
    end

    function refreshKillsDisplay()
        ShowsLabel.Text = "Shows Kills: " .. tostring(showsKills)
        if killsValue ~= nil then
            CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
        else
            CurrentLabel.Text = "Current Kills: 0"
        end
    end

    local function updateStatsLabel()
        local now = clock()
        if now - lastStatsUpdate < 0.5 then return end
        lastStatsUpdate = now

        local ping = 0
        local ok, val = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and typeof(val) == "number" then
            ping = floor_(val)
        end

        local fps = floor_(currentFps)

        local fpsColor
        if fps >= 60 then
            fpsColor = "rgb(120,255,150)"
        elseif fps >= 40 then
            fpsColor = "rgb(255,190,90)"
        else
            fpsColor = "rgb(255,90,90)"
        end

        local pingColor
        if ping < 100 then
            pingColor = "rgb(120,255,150)"
        elseif ping < 200 then
            pingColor = "rgb(255,190,90)"
        else
            pingColor = "rgb(255,90,90)"
        end

        StatsLabel.Text = fmt_(
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
        if ch == lastSetupCharacter then return end

        lastSetupCharacter = ch
        respawnGraceUntil = clock() + RESPAWN_G_GRACE

        rotationRunning = false
        protectionActive = false
        protectionOrigin = nil
        lowHealthMode = false
        selfRagdollActive = false
        attackingActive = false
        specialAnimActive = false
        forceVoidActive = false
        voidKillingActive = false
        voidKillingCounting = false
        voidKillingTimerStart = 0
        lastTargetPlayer = nil
        pendingTargetPlayer = nil
        targetSwitchLockUntil = 0

        lastBreathFired = false
        lastBreathBlockUntil = 0

        if cloneCharacter ~= nil and cloneCharacter ~= ch then
            pcall(function() cloneCharacter:Destroy() end)
        end
        cloneCharacter = nil
        cloneRoot = nil
        cloneHumanoid = nil
        cloneAnimator = nil
        animationMirrors = {}

        if spamTrack ~= nil then
            pcall(function() spamTrack:Stop(0) end)
        end
        spamTrack = nil
        spamTrackCharacter = nil

        cachedBackpack = nil
        cachedBackpackParent = nil
        spaceDown = false
        lastRagdollFire = 0
        killsValue = nil
        suppressHeartbeatTp = false
        rootCacheChar = nil
        rootCacheV = nil
        targetCacheT = 0
        targetCacheV = nil
        tfCacheT = 0
        hotbarCacheT = {}
        hotbarCacheV = {}
        specialAnimCacheT = 0
        forceVoidCacheT = 0
        crowdBusterCacheT = 0
        hammerBindingCacheT = 0
        protCache = setmetatable({}, {__mode = "k"})
        lastEmoteSpin = 0
        lastFallbackFire = 0
        lastCloneRebuild = 0
        lastCloneCheck = 0

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
            insert_(stripConnections, conn)
        end)

        watchCharacter(ch)

        refreshStatus()
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

    NoRenderButton.Activated:Connect(function()
        noRenderEnabled = not noRenderEnabled
        setToggle(NoRenderState, noRenderEnabled)
        applyNoRender()
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
            if typeof(delfile) == "function" then
                pcall(function() delfile(HOP_QUEUE_FLAG) end)
            end
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
    setToggle(NoRenderState, noRenderEnabled)
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

    insert_(permanentConnections, RunService.Heartbeat:Connect(function()
        pcall(handleCharacterSetup)

        pcall(tickSpaceRelease)
        pcall(updateStatsLabel)

        if killsValue ~= nil and killsValue.Parent ~= nil then
            local now = clock()
            if now - lastKillsLabelUpdate > 0.1 then
                lastKillsLabelUpdate = now
                pcall(function()
                    CurrentLabel.Text = "Current Kills: " .. tostring(killsValue.Value)
                end)
            end
        end

        if lastSetupCharacter ~= LocalPlayer.Character then
            local sn = clock()
            if sn - lastStatusRefresh >= 0.25 then
                lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end

        local character = LocalPlayer.Character
        if character == nil then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root == nil then return end
        if not root:IsA("BasePart") then return end

        rootCacheChar = character
        rootCacheV = root

        if farmEnabled then
            local blockedByLastBreath = tryLastBreath(root)
            if blockedByLastBreath then
                local sn = clock()
                if sn - lastStatusRefresh >= 0.25 then
                    lastStatusRefresh = sn
                    refreshStatus()
                end
                return
            end
        end

        pcall(fireEmoteSpin)
        pcall(ensureInvisible)

        pcall(updateKillsFromLeaderstats)

        pcall(function()
            specialAnimActive = isSpecialAnimationPlaying()
            forceVoidActive = isForceVoidAnimationPlaying()
        end)

        if forceVoidActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - lastStatusRefresh >= 0.25 then
                lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end

        voidKillingActive = false
        if crowdBusterExists ~= nil then
            local okCB, cbVal = pcall(crowdBusterExists)
            if okCB and cbVal then
                if hotbarHasCooldown(3) and hotbarHasCooldown(4) then
                    if not voidKillingCounting then
                        voidKillingCounting = true
                        voidKillingTimerStart = clock()
                    end
                    voidKillingActive = true
                    if clock() - voidKillingTimerStart >= VOID_KILL_DELAY then
                        voidKillingCounting = false
                        voidKillingTimerStart = 0
                        pinToSafeZone(root)
                        killSelf()
                        local sn = clock()
                        if sn - lastStatusRefresh >= 0.25 then
                            lastStatusRefresh = sn
                            refreshStatus()
                        end
                        return
                    end
                else
                    voidKillingCounting = false
                    voidKillingTimerStart = 0
                end
            else
                voidKillingCounting = false
                voidKillingTimerStart = 0
            end
        end

        local protected = false
        if character:FindFirstChild("AbsoluteImmortal") ~= nil then
            protected = true
        end
        if protected and not protectionActive then
            protectionOrigin = root.CFrame
            protectionActive = true
        elseif not protected and protectionActive then
            protectionActive = false
            protectionOrigin = nil
        end

        if protectionActive and not specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - lastStatusRefresh >= 0.25 then
                lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid ~= nil and humanoid.MaxHealth > 0 then
            local pct = humanoid.Health / humanoid.MaxHealth
            if pct < LOW_HP_THRESHOLD then
                lowHealthMode = true
            elseif pct >= LOW_HP_THRESHOLD then
                lowHealthMode = false
            end
        end

        if lowHealthMode and not specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - lastStatusRefresh >= 0.25 then
                lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end

        local ragdollNow = selfHasRagdoll()
        selfRagdollActive = ragdollNow

        if selfRagdollActive and not specialAnimActive then
            pinToSafeZone(root)
            local sn = clock()
            if sn - lastStatusRefresh >= 0.25 then
                lastStatusRefresh = sn
                refreshStatus()
            end
            return
        end

        if stealthMode and farmEnabled and not specialAnimActive then
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

            local target = getTarget()

            if target == nil then
                if not specialAnimActive then
                    pinToSafeZone(root)
                end
                if not rotationRunning then spawn_(runRotationLoop) end
                local sn = clock()
                if sn - lastStatusRefresh >= 0.25 then
                    lastStatusRefresh = sn
                    refreshStatus()
                end
                return
            end

            if isNearVoid() then
                setPhysRep(root, nil)
                if not suppressHeartbeatTp and canAlignToTarget(target) then
                    root.CFrame = ALIGN_CF
                end
            elseif not suppressHeartbeatTp and canAlignToTarget(target) then
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if tr ~= nil and tr:IsA("BasePart") then
                    setPhysRep(root, tr)
                    root.CFrame = ALIGN_CF
                end
            end

            if not rotationRunning then spawn_(runRotationLoop) end
        end

        local statusNow = clock()
        if statusNow - lastStatusRefresh >= 0.25 then
            lastStatusRefresh = statusNow
            refreshStatus()
        end
    end))

    insert_(permanentConnections, RunService.RenderStepped:Connect(function()
        if noRenderEnabled then return end

        if performanceMode then
            if thrownConnection == nil then startThrownWatcher() end
        else
            if thrownConnection ~= nil then
                thrownConnection:Disconnect()
                thrownConnection = nil
            end
        end

        local character = LocalPlayer.Character
        if character == nil or character ~= lastSetupCharacter then return end

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
        if cam == nil then return end

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
        if ch == nil then return end
        protCache[ch] = nil
        local root = ch:FindFirstChild("HumanoidRootPart")
        if root ~= nil and root:IsA("BasePart") then
            targetStates[root] = nil
        end
    end))

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