local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Device = UserInputService.TouchEnabled and "Mobile" or UserInputService.KeyboardEnabled and "PC"
local CoreGui = gethui and gethui() or game:GetService("CoreGui")

local Library = {
    Settings = {
        Tracers = true,
        Distance = true,
        Arrows = true,
        Rainbow = false,
        MaxDistance = 999999,
        TextSize = 25,
        Font = Enum.Font.RobotoMono,
        FadeTime = 0.7,
        ESPMode = "Highlight/Text",
        RenderTime = (Device == "PC" and 240 or Device == "Mobile" and 30) or 60,

        LOD100 = 1,
        LOD250 = 0.75,
        LOD500 = 0.5,
        LOD1000 = 0.25,
        LODFar = 0.1,

        AdaptiveLOD = true,
        MovementPriority = true,
        FrameBudget = 100,
        MetadataInterval = 0.12,
        RainbowRate = 30,
        CleanupInterval = 2,
    },

    Cache = {},

    TweenInfoFadeIn = nil,
    TweenInfoFadeOut = nil,

    ESPCount = 0,

    Scheduler = {},
    SchedulerSize = 0,
    SchedulerEpoch = 0,

    LastCleanup = 0,
    LastRainbow = 0,
    RainbowColor = Color3.fromHSV(0, 1, 1),

    Connection = nil,
    Unloaded = false,
}

local Screen = Instance.new("ScreenGui")
Screen.Name = HttpService:GenerateGUID(false)
Screen.IgnoreGuiInset = true
Screen.Parent = CoreGui

local function GetRoot(Object)
    if not Object then
        return nil
    end

    if Object:IsA("Model") then
        return Object:FindFirstChild("HumanoidRootPart")
            or Object.PrimaryPart
            or Object:FindFirstChildWhichIsA("BasePart")
    end

    if Object:IsA("BasePart") then
        return Object
    end

    return nil
end

local function FindHighlight(Object)
    if not Object then
        return nil
    end

    return Object:FindFirstChildWhichIsA("Highlight", true)
end

local function SaveHighlightState(Highlight)
    if not Highlight then
        return nil
    end

    return {
        Enabled = Highlight.Enabled,
        Adornee = Highlight.Adornee,
        FillColor = Highlight.FillColor,
        FillTransparency = Highlight.FillTransparency,
        OutlineColor = Highlight.OutlineColor,
        OutlineTransparency = Highlight.OutlineTransparency,
        DepthMode = Highlight.DepthMode,
    }
end

local function IsValidHighlight(Highlight)
    return Highlight ~= nil
        and Highlight.Parent ~= nil
        and Highlight:IsA("Highlight")
end

local function RestoreHighlight(Data)
    local Highlight = Data.Box
    local Original = Data.OriginalHighlight

    if not IsValidHighlight(Highlight) then
        return
    end

    if Data.HighlightInstance ~= Highlight then
        return
    end

    if not Original then
        return
    end

    Highlight.Enabled = Original.Enabled
    Highlight.Adornee = Original.Adornee
    Highlight.FillColor = Original.FillColor
    Highlight.FillTransparency = Original.FillTransparency
    Highlight.OutlineColor = Original.OutlineColor
    Highlight.OutlineTransparency = Original.OutlineTransparency
    Highlight.DepthMode = Original.DepthMode
end

local function ConfigureHighlight(Data, Highlight)
    if not IsValidHighlight(Highlight) then
        return false
    end

    local Object = Data.Object

    if not Object or not Object.Parent then
        return false
    end

    Highlight.Adornee = Object
    Highlight.FillColor = Data.Color
    Highlight.FillTransparency = 0.6
    Highlight.OutlineTransparency = 1
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Enabled = true

    Data.Box = Highlight
    Data.HighlightInstance = Highlight
    Data.LastHighlightColor = Data.Color
    Data.LastBoxEnabled = true

    return true
end

local function EnsureHighlight(Data)
    local Object = Data.Object

    if not Object or not Object.Parent then
        Data.Box = nil
        return nil
    end

    local Current = Data.Box

    if IsValidHighlight(Current) then
        ConfigureHighlight(Data, Current)
        return Current
    end

    Data.Box = nil

    local Existing = FindHighlight(Object)

    if IsValidHighlight(Existing) then
        Data.Box = Existing
        Data.HighlightInstance = Existing
        Data.OwnsHighlight = false
        Data.OriginalHighlight = SaveHighlightState(Existing)

        ConfigureHighlight(Data, Existing)

        return Existing
    end

    local Highlight = Instance.new("Highlight")

    Highlight.Name = "ESPHighlight"
    Highlight.Adornee = Object
    Highlight.Enabled = true
    Highlight.FillColor = Data.Color
    Highlight.FillTransparency = 0.6
    Highlight.OutlineTransparency = 1
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Parent = Object

    Data.Box = Highlight
    Data.HighlightInstance = Highlight
    Data.OwnsHighlight = true
    Data.OriginalHighlight = nil
    Data.LastHighlightColor = Data.Color
    Data.LastBoxEnabled = true

    return Highlight
end

local function ReleaseHighlight(Data)
    local Highlight = Data.Box

    if not Highlight then
        return
    end

    if Data.OwnsHighlight then
        if IsValidHighlight(Highlight) then
            Highlight:Destroy()
        end
    else
        RestoreHighlight(Data)
    end

    Data.Box = nil
    Data.HighlightInstance = nil
    Data.OriginalHighlight = nil
    Data.OwnsHighlight = false
    Data.LastBoxEnabled = false
end

local function HeapPush(Heap, Size, Node)
    Size += 1

    local Index = Size

    while Index > 1 do
        local Parent = math.floor(Index / 2)

        if Heap[Parent].Time <= Node.Time then
            break
        end

        Heap[Index] = Heap[Parent]
        Index = Parent
    end

    Heap[Index] = Node

    return Size
end

local function HeapPop(Heap, Size)
    if Size <= 0 then
        return nil, 0
    end

    local Root = Heap[1]
    local Last = Heap[Size]

    Heap[Size] = nil
    Size -= 1

    if Size <= 0 then
        return Root, 0
    end

    local Index = 1

    while true do
        local Left = Index * 2

        if Left > Size then
            break
        end

        local Right = Left + 1
        local Child = Left

        if Right <= Size and Heap[Right].Time < Heap[Left].Time then
            Child = Right
        end

        if Heap[Child].Time >= Last.Time then
            break
        end

        Heap[Index] = Heap[Child]
        Index = Child
    end

    Heap[Index] = Last

    return Root, Size
end

local function GetLODInterval(DistanceSquared, RenderTime, Settings, ESPCount)
    local Multiplier

    if DistanceSquared <= 10000 then
        Multiplier = Settings.LOD100
    elseif DistanceSquared <= 62500 then
        Multiplier = Settings.LOD250
    elseif DistanceSquared <= 250000 then
        Multiplier = Settings.LOD500
    elseif DistanceSquared <= 1000000 then
        Multiplier = Settings.LOD1000
    else
        Multiplier = Settings.LODFar
    end

    Multiplier = math.max(Multiplier, 0.01)

    if Settings.AdaptiveLOD then
        if ESPCount > 150 then
            Multiplier *= 0.45
        elseif ESPCount > 100 then
            Multiplier *= 0.6
        elseif ESPCount > 60 then
            Multiplier *= 0.8
        end
    end

    return math.max(
        1 / math.max(RenderTime, 1) / Multiplier,
        1 / 60
    )
end

local function SetVisible(Data, TagVisible, TextVisible, LineVisible, ArrowVisible)
    if Data.Tag and Data.LastTagEnabled ~= TagVisible then
        Data.Tag.Enabled = TagVisible
        Data.LastTagEnabled = TagVisible
    end

    if Data.Text and Data.LastTextVisible ~= TextVisible then
        Data.Text.Visible = TextVisible
        Data.LastTextVisible = TextVisible
    end

    if Data.Line and Data.LastLineVisible ~= LineVisible then
        Data.Line.Visible = LineVisible
        Data.LastLineVisible = LineVisible
    end

    if Data.Arrow and Data.LastArrowVisible ~= ArrowVisible then
        Data.Arrow.Visible = ArrowVisible
        Data.LastArrowVisible = ArrowVisible
    end
end

local function SetHighlightEnabled(Data, Enabled)
    local Highlight = Data.Box

    if not IsValidHighlight(Highlight) then
        Data.LastBoxEnabled = false
        return
    end

    if Highlight.Enabled ~= Enabled then
        Highlight.Enabled = Enabled
    end

    Data.LastBoxEnabled = Enabled
end

local function SetTextColor(Data, Color)
    if Data.Text and Data.LastTextColor ~= Color then
        Data.Text.TextColor3 = Color
        Data.LastTextColor = Color
    end
end

local function SetLineColor(Data, Color)
    if Data.Line and Data.LastLineColor ~= Color then
        Data.Line.BackgroundColor3 = Color
        Data.LastLineColor = Color
    end
end

local function SetArrowColor(Data, Color)
    if Data.Arrow and Data.LastArrowColor ~= Color then
        Data.Arrow.ImageColor3 = Color
        Data.LastArrowColor = Color
    end
end

local function SetHighlightColor(Data, Color)
    local Highlight = Data.Box

    if IsValidHighlight(Highlight) and Data.LastHighlightColor ~= Color then
        Highlight.FillColor = Color
        Data.LastHighlightColor = Color
    end
end

local function ScheduleData(Data, Time)
    Library.SchedulerSize = HeapPush(
        Library.Scheduler,
        Library.SchedulerSize,
        {
            Time = Time,
            Object = Data.Object,
            Version = Data.ScheduleVersion,
            Epoch = Library.SchedulerEpoch,
        }
    )
end

local function ScheduleObject(Data, Time)
    Data.NextUpdate = Time
    Data.ScheduleVersion += 1
    ScheduleData(Data, Time)
end

local function InvalidateScheduler()
    Library.SchedulerEpoch += 1
    Library.Scheduler = {}
    Library.SchedulerSize = 0

    local Now = os.clock()

    for _, Data in pairs(Library.Cache) do
        Data.ScheduleVersion += 1
        Data.NextUpdate = Now

        ScheduleData(Data, Now)
    end
end

function Library:RebuildTweenInfo()
    local FadeTime = math.max(self.Settings.FadeTime, 0)

    self.TweenInfoFadeIn = TweenInfo.new(
        FadeTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    self.TweenInfoFadeOut = TweenInfo.new(
        FadeTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
end

Library:RebuildTweenInfo()

function Library:SetFont(Font)
    self.Settings.Font = Font

    for _, Data in pairs(self.Cache) do
        if Data.Text then
            Data.Text.Font = Font
        end
    end
end

function Library:SetRainbow(Value)
    self.Settings.Rainbow = Value
    InvalidateScheduler()
end

function Library:SetFadeTime(Value)
    self.Settings.FadeTime = math.max(Value, 0)
    self:RebuildTweenInfo()
end

function Library:SetArrows(Value)
    self.Settings.Arrows = Value
    InvalidateScheduler()
end

function Library:SetTracers(Value)
    self.Settings.Tracers = Value
    InvalidateScheduler()
end

function Library:SetShowDistance(Value)
    self.Settings.Distance = Value
    InvalidateScheduler()
end

function Library:SetESPMode(Value)
    self.Settings.ESPMode = Value
    InvalidateScheduler()
end

function Library:SetRenderingSpeed(Value)
    self.Settings.RenderTime = math.max(Value, 1)
    InvalidateScheduler()
end

function Library:HasESP(Object)
    return self.Cache[Object] ~= nil
end

function Library:GetESPData(Object)
    return self.Cache[Object]
end

function Library:GetAllESP()
    local Result = {}

    for Object, Data in pairs(self.Cache) do
        Result[Object] = {
            Name = Data.Name,
            Color = Data.Color,
            Root = Data.Root,
        }
    end

    return Result
end

function Library:CountESP()
    return self.ESPCount
end

function Library:AddESP(Cfg)
    if self.Unloaded then
        return
    end

    if not Cfg then
        return
    end

    local Object = Cfg.Object

    if not Object or self.Cache[Object] then
        return
    end

    local Root = GetRoot(Object)

    if not Root then
        task.spawn(function()
            local Attempts = 0

            while Object.Parent and Attempts < 60 and not self.Unloaded do
                Root = GetRoot(Object)

                if Root then
                    break
                end

                Attempts += 1
                task.wait(0.5)
            end

            if Root and Object.Parent and not self.Cache[Object] and not self.Unloaded then
                self:AddESP(Cfg)
            end
        end)

        return
    end

    local InitialColor = Cfg.Color or Color3.new(1, 1, 1)
    local InitialText = Cfg.Text or "ESP"

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = HttpService:GenerateGUID(false)
    Billboard.Size = UDim2.new(0, 250, 0, 60)
    Billboard.AlwaysOnTop = true
    Billboard.Adornee = Root
    Billboard.MaxDistance = self.Settings.MaxDistance
    Billboard.Parent = Object

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.TextColor3 = InitialColor
    Label.Font = self.Settings.Font
    Label.TextSize = self.Settings.TextSize
    Label.TextStrokeTransparency = 0
    Label.TextTransparency = 1
    Label.Text = InitialText
    Label.Parent = Billboard

    local Line = Instance.new("Frame")
    Line.AnchorPoint = Vector2.new(0.5, 0.5)
    Line.BorderSizePixel = 0
    Line.BackgroundColor3 = InitialColor
    Line.Visible = true
    Line.BackgroundTransparency = 1
    Line.Parent = Screen

    local Arrow = Instance.new("ImageLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    Arrow.Size = UDim2.new(0, 32, 0, 32)
    Arrow.Image = "rbxassetid://10526559647"
    Arrow.ImageColor3 = InitialColor
    Arrow.Visible = false
    Arrow.Parent = Screen

    local Data = {
        Object = Object,

        Tag = Billboard,
        Text = Label,
        Line = Line,
        Box = nil,
        Arrow = Arrow,

        Name = InitialText,
        Color = InitialColor,
        Root = Root,

        OwnsHighlight = false,
        HighlightInstance = nil,
        OriginalHighlight = nil,

        NextUpdate = 0,
        NextMetadataUpdate = 0,

        LastPosition = Root.Position,
        LastDistance = -1,
        LastDisplayedDistance = -1,

        LastTextColor = InitialColor,
        LastHighlightColor = InitialColor,
        LastLineColor = InitialColor,
        LastArrowColor = InitialColor,

        LastTextSize = self.Settings.TextSize,

        LastTagEnabled = true,
        LastTextVisible = false,
        LastBoxEnabled = false,
        LastLineVisible = true,
        LastArrowVisible = false,

        LastTracerX = -1,
        LastTracerY = -1,
        LastTracerLength = -1,
        LastTracerRotation = -999,

        LastArrowX = -1,
        LastArrowY = -1,
        LastArrowRotation = -999,

        ScheduleVersion = 0,
        FadeToken = 0,
    }

    self.Cache[Object] = Data
    self.ESPCount += 1

    local ExistingHighlight = FindHighlight(Object)

    if IsValidHighlight(ExistingHighlight) then
        Data.Box = ExistingHighlight
        Data.HighlightInstance = ExistingHighlight
        Data.OwnsHighlight = false
        Data.OriginalHighlight = SaveHighlightState(ExistingHighlight)

        ConfigureHighlight(Data, ExistingHighlight)
    end

    local FadeTime = self.Settings.FadeTime

    if FadeTime > 0 then
        TweenService:Create(
            Label,
            self.TweenInfoFadeIn,
            {TextTransparency = 0}
        ):Play()

        if IsValidHighlight(Data.Box) then
            TweenService:Create(
                Data.Box,
                self.TweenInfoFadeIn,
                {FillTransparency = 0.6}
            ):Play()
        end

        TweenService:Create(
            Line,
            self.TweenInfoFadeIn,
            {BackgroundTransparency = 0}
        ):Play()
    else
        Label.TextTransparency = 0

        if IsValidHighlight(Data.Box) then
            Data.Box.FillTransparency = 0.6
            Data.Box.Enabled = true
        end

        Line.BackgroundTransparency = 0
    end

    local Now = os.clock()

    Data.NextMetadataUpdate = Now

    ScheduleObject(Data, Now)
end

function Library:RemoveESP(Object)
    local Data = self.Cache[Object]

    if not Data then
        return
    end

    self.Cache[Object] = nil
    self.ESPCount = math.max(self.ESPCount - 1, 0)

    Data.ScheduleVersion += 1
    Data.FadeToken += 1

    local Token = Data.FadeToken
    local FadeTime = math.max(self.Settings.FadeTime, 0)

    if FadeTime > 0 then
        if Data.Text and Data.Text.Parent then
            TweenService:Create(
                Data.Text,
                self.TweenInfoFadeOut,
                {TextTransparency = 1}
            ):Play()
        end

        if IsValidHighlight(Data.Box) then
            TweenService:Create(
                Data.Box,
                self.TweenInfoFadeOut,
                {FillTransparency = 1}
            ):Play()
        end

        if Data.Line and Data.Line.Parent then
            TweenService:Create(
                Data.Line,
                self.TweenInfoFadeOut,
                {BackgroundTransparency = 1}
            ):Play()
        end

        task.delay(FadeTime, function()
            if Data.FadeToken ~= Token then
                return
            end

            ReleaseHighlight(Data)

            if Data.Tag and Data.Tag.Parent then
                Data.Tag:Destroy()
            end

            if Data.Line and Data.Line.Parent then
                Data.Line:Destroy()
            end

            if Data.Arrow and Data.Arrow.Parent then
                Data.Arrow:Destroy()
            end
        end)
    else
        ReleaseHighlight(Data)

        if Data.Tag and Data.Tag.Parent then
            Data.Tag:Destroy()
        end

        if Data.Line and Data.Line.Parent then
            Data.Line:Destroy()
        end

        if Data.Arrow and Data.Arrow.Parent then
            Data.Arrow:Destroy()
        end
    end
end

function Library:UpdateESP(Object, NewText, NewColor)
    local Data = self.Cache[Object]

    if Data then
        if NewText and Data.Name ~= NewText then
            Data.Name = NewText
            Data.Text.Text = NewText
            Data.LastDisplayedDistance = -1
            Data.NextMetadataUpdate = 0
        end

        if NewColor and Data.Color ~= NewColor then
            Data.Color = NewColor

            if Data.Text then
                Data.Text.TextColor3 = NewColor
            end

            if IsValidHighlight(Data.Box) then
                Data.Box.FillColor = NewColor
            end

            if Data.Line then
                Data.Line.BackgroundColor3 = NewColor
            end

            if Data.Arrow then
                Data.Arrow.ImageColor3 = NewColor
            end

            Data.LastTextColor = NewColor
            Data.LastHighlightColor = NewColor
            Data.LastLineColor = NewColor
            Data.LastArrowColor = NewColor
        end

        ScheduleObject(Data, os.clock())
    else
        self:AddESP({
            Object = Object,
            Text = NewText or "ESP",
            Color = NewColor or Color3.new(1, 1, 1),
        })
    end
end

function Library:BulkUpdateESP(UpdateTable)
    local Now = os.clock()

    for Object, Info in pairs(UpdateTable) do
        local Data = self.Cache[Object]

        if Data then
            if Info.Text and Data.Name ~= Info.Text then
                Data.Name = Info.Text
                Data.Text.Text = Info.Text
                Data.LastDisplayedDistance = -1
                Data.NextMetadataUpdate = 0
            end

            if Info.Color and Data.Color ~= Info.Color then
                local Color = Info.Color

                Data.Color = Color

                if Data.Text then
                    Data.Text.TextColor3 = Color
                end

                if IsValidHighlight(Data.Box) then
                    Data.Box.FillColor = Color
                end

                if Data.Line then
                    Data.Line.BackgroundColor3 = Color
                end

                if Data.Arrow then
                    Data.Arrow.ImageColor3 = Color
                end

                Data.LastTextColor = Color
                Data.LastHighlightColor = Color
                Data.LastLineColor = Color
                Data.LastArrowColor = Color
            end

            ScheduleObject(Data, Now)
        elseif Info.Text and Info.Color then
            self:AddESP({
                Object = Object,
                Text = Info.Text,
                Color = Info.Color,
            })
        end
    end
end

function Library:ClearAllESP()
    local Objects = {}

    for Object in pairs(self.Cache) do
        Objects[#Objects + 1] = Object
    end

    for i = 1, #Objects do
        self:RemoveESP(Objects[i])
    end
end

function Library:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    self.Scheduler = {}
    self.SchedulerSize = 0
    self.SchedulerEpoch += 1

    for Object, Data in pairs(self.Cache) do
        self.Cache[Object] = nil

        Data.FadeToken += 1

        ReleaseHighlight(Data)

        if Data.Tag and Data.Tag.Parent then
            Data.Tag:Destroy()
        end

        if Data.Line and Data.Line.Parent then
            Data.Line:Destroy()
        end

        if Data.Arrow and Data.Arrow.Parent then
            Data.Arrow:Destroy()
        end
    end

    self.ESPCount = 0

    if Screen and Screen.Parent then
        Screen:Destroy()
    end
end

local Camera = workspace.CurrentCamera
local ViewportSize = Camera and Camera.ViewportSize or Vector2.zero
local ScreenCenter = ViewportSize / 2
local FOVScale = Camera and Camera.FieldOfView / 70 or 1

local LastCamera = Camera
local LastViewportX = ViewportSize.X
local LastViewportY = ViewportSize.Y
local LastFOV = Camera and Camera.FieldOfView or 70
local LastHeartbeat = os.clock()

Library.Connection = RS.Heartbeat:Connect(function()
    if Library.Unloaded then
        return
    end

    local Now = os.clock()
    local Settings = Library.Settings

    Camera = workspace.CurrentCamera

    if not Camera then
        return
    end

    local CurrentViewport = Camera.ViewportSize
    local CurrentFOV = Camera.FieldOfView

    local CameraChanged = Camera ~= LastCamera

    local ViewportChanged =
        CurrentViewport.X ~= LastViewportX
        or CurrentViewport.Y ~= LastViewportY

    local FOVChanged = CurrentFOV ~= LastFOV

    if CameraChanged or ViewportChanged or FOVChanged then
        LastCamera = Camera
        LastViewportX = CurrentViewport.X
        LastViewportY = CurrentViewport.Y
        LastFOV = CurrentFOV

        ViewportSize = CurrentViewport
        ScreenCenter = CurrentViewport / 2
        FOVScale = CurrentFOV / 70

        InvalidateScheduler()
    end

    local RainbowInterval =
        1 / math.max(Settings.RainbowRate, 1)

    if Now - Library.LastRainbow >= RainbowInterval then
        Library.LastRainbow = Now
        Library.RainbowColor =
            Color3.fromHSV((Now % 5) / 5, 1, 1)
    end

    if Now - Library.LastCleanup >= Settings.CleanupInterval then
        Library.LastCleanup = Now

        for Object, Data in pairs(Library.Cache) do
            if not Object or not Object.Parent then
                Library:RemoveESP(Object)
                continue
            end

            if not Data.Root or not Data.Root.Parent then
                Data.Root = GetRoot(Object)
            end

            if Data.Box and not IsValidHighlight(Data.Box) then
                Data.Box = nil
                Data.HighlightInstance = nil
                Data.OriginalHighlight = nil
                Data.OwnsHighlight = false
                Data.LastBoxEnabled = false
            end
        end
    end

    local RenderInterval =
        1 / math.max(Settings.RenderTime, 1)

    if Now - LastHeartbeat < RenderInterval then
        return
    end

    LastHeartbeat = Now

    local Processed = 0
    local Budget = math.max(Settings.FrameBudget, 1)

    while Library.SchedulerSize > 0 and Processed < Budget do
        local Node

        Node, Library.SchedulerSize =
            HeapPop(
                Library.Scheduler,
                Library.SchedulerSize
            )

        if not Node then
            break
        end

        if Node.Epoch ~= Library.SchedulerEpoch then
            continue
        end

        if Node.Time > Now then
            Library.SchedulerSize =
                HeapPush(
                    Library.Scheduler,
                    Library.SchedulerSize,
                    Node
                )

            break
        end

        local Object = Node.Object
        local Data = Library.Cache[Object]

        if not Data then
            continue
        end

        if Data.ScheduleVersion ~= Node.Version then
            continue
        end

        Processed += 1

        if not Object or not Object.Parent then
            Library:RemoveESP(Object)
            continue
        end

        local RootPart = Data.Root

        if not RootPart or not RootPart.Parent then
            RootPart = GetRoot(Object)
            Data.Root = RootPart

            if not RootPart then
                ScheduleObject(Data, Now + 0.5)
                continue
            end
        end

        local Position = RootPart.Position
        local CameraCFrame = Camera.CFrame
        local CameraPosition = CameraCFrame.Position

        local DX = Position.X - CameraPosition.X
        local DY = Position.Y - CameraPosition.Y
        local DZ = Position.Z - CameraPosition.Z

        local DistanceSquared =
            DX * DX
            + DY * DY
            + DZ * DZ

        local MaxDistance = Settings.MaxDistance
        local MaxDistanceSquared =
            MaxDistance * MaxDistance

        if DistanceSquared > MaxDistanceSquared then
            SetVisible(
                Data,
                false,
                false,
                false,
                false
            )

            SetHighlightEnabled(Data, false)

            ScheduleObject(
                Data,
                Now + GetLODInterval(
                    DistanceSquared,
                    Settings.RenderTime,
                    Settings,
                    Library.ESPCount
                )
            )

            continue
        end

        local Distance = math.sqrt(DistanceSquared)

        local LastPosition = Data.LastPosition

        local MovementDX =
            Position.X - LastPosition.X

        local MovementDY =
            Position.Y - LastPosition.Y

        local MovementDZ =
            Position.Z - LastPosition.Z

        local MovementSquared =
            MovementDX * MovementDX
            + MovementDY * MovementDY
            + MovementDZ * MovementDZ

        Data.LastPosition = Position
        Data.LastDistance = Distance

        local Moving = MovementSquared > 0.0004

        local ScreenPosition, IsOnScreen =
            Camera:WorldToViewportPoint(Position)

        local DisplayColor =
            Settings.Rainbow
            and Library.RainbowColor
            or Data.Color

        local ESPMode = Settings.ESPMode

        local ShowHighlight =
            ESPMode == "Highlight"
            or ESPMode == "Highlight/Text"

        local ShowText =
            ESPMode == "Text"
            or ESPMode == "Highlight/Text"

        if IsOnScreen then
            if ShowHighlight then
                local Highlight = EnsureHighlight(Data)

                if Highlight then
                    SetHighlightColor(
                        Data,
                        DisplayColor
                    )

                    SetHighlightEnabled(
                        Data,
                        true
                    )
                else
                    SetHighlightEnabled(
                        Data,
                        false
                    )
                end
            else
                SetHighlightEnabled(
                    Data,
                    false
                )
            end

            SetVisible(
                Data,
                true,
                ShowText,
                Settings.Tracers and Distance < 1500,
                false
            )

            if ShowText then
                SetTextColor(
                    Data,
                    DisplayColor
                )

                local TextSize =
                    Settings.TextSize * FOVScale

                if Data.LastTextSize ~= TextSize then
                    Data.Text.TextSize = TextSize
                    Data.LastTextSize = TextSize
                end

                if Now >= Data.NextMetadataUpdate then
                    local DistanceFloor =
                        math.floor(Distance)

                    if Settings.Distance then
                        if Data.LastDisplayedDistance ~= DistanceFloor then
                            Data.Text.Text =
                                Data.Name
                                .. "\n["
                                .. DistanceFloor
                                .. "m]"

                            Data.LastDisplayedDistance =
                                DistanceFloor
                        end
                    elseif Data.LastDisplayedDistance ~= -2 then
                        Data.Text.Text = Data.Name
                        Data.LastDisplayedDistance = -2
                    end

                    Data.NextMetadataUpdate =
                        Now + Settings.MetadataInterval
                end
            end

            if Settings.Tracers and Distance < 1500 then
                SetLineColor(
                    Data,
                    DisplayColor
                )

                local SX = ScreenPosition.X
                local SY = ScreenPosition.Y

                local OriginX = ScreenCenter.X
                local OriginY = ViewportSize.Y

                local DifferenceX =
                    SX - OriginX

                local DifferenceY =
                    SY - OriginY

                local Length =
                    math.sqrt(
                        DifferenceX * DifferenceX
                        + DifferenceY * DifferenceY
                    )

                local Rotation =
                    math.deg(
                        math.atan2(
                            DifferenceY,
                            DifferenceX
                        )
                    )

                if
                    Data.LastTracerX ~= SX
                    or Data.LastTracerY ~= SY
                    or Data.LastTracerLength ~= Length
                    or Data.LastTracerRotation ~= Rotation
                then
                    Data.Line.Size =
                        UDim2.new(
                            0,
                            Length,
                            0,
                            1
                        )

                    Data.Line.Position =
                        UDim2.new(
                            0,
                            OriginX + DifferenceX * 0.5,
                            0,
                            OriginY + DifferenceY * 0.5
                        )

                    Data.Line.Rotation = Rotation

                    Data.LastTracerX = SX
                    Data.LastTracerY = SY
                    Data.LastTracerLength = Length
                    Data.LastTracerRotation = Rotation
                end
            end
        else
            SetVisible(
                Data,
                false,
                false,
                false,
                Settings.Arrows
            )

            SetHighlightEnabled(
                Data,
                false
            )

            if Settings.Arrows then
                SetArrowColor(
                    Data,
                    DisplayColor
                )

                local Relative =
                    CameraCFrame:PointToObjectSpace(
                        Position
                    )

                local DirectionAngle =
                    math.atan2(
                        -Relative.X,
                        -Relative.Z
                    )

                local Radius =
                    ViewportSize.Y * 0.4

                local ArrowX =
                    ScreenCenter.X
                    + math.sin(DirectionAngle)
                    * Radius

                local ArrowY =
                    ScreenCenter.Y
                    + math.cos(DirectionAngle)
                    * Radius

                local ArrowRotation =
                    math.deg(DirectionAngle)

                if
                    Data.LastArrowX ~= ArrowX
                    or Data.LastArrowY ~= ArrowY
                    or Data.LastArrowRotation ~= ArrowRotation
                then
                    Data.Arrow.Position =
                        UDim2.new(
                            0,
                            ArrowX,
                            0,
                            ArrowY
                        )

                    Data.Arrow.Rotation =
                        ArrowRotation

                    Data.LastArrowX = ArrowX
                    Data.LastArrowY = ArrowY
                    Data.LastArrowRotation =
                        ArrowRotation
                end
            end
        end

        local Interval =
            GetLODInterval(
                DistanceSquared,
                Settings.RenderTime,
                Settings,
                Library.ESPCount
            )

        if Settings.MovementPriority then
            if Moving then
                Interval *= 0.55
            else
                Interval *= 1.15
            end
        end

        ScheduleObject(
            Data,
            Now + math.max(
                Interval,
                1 / 60
            )
        )
    end
end)

return Library