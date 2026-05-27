local UserInputService = game:GetService("UserInputService")

local Device = UserInputService.TouchEnabled and "Mobile" or UserInputService.KeyboardEnabled and "PC"

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
    },
    Cache = {}
}

local RS = game:GetService("RunService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")
local LP = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")

local Screen = Instance.new("ScreenGui", CoreGui)
Screen.Name = "ESPLibrary_Screen"
Screen.IgnoreGuiInset = true

local function GetRoot(Obj)
    if not Obj then return nil end
    return Obj:IsA("Model") and (Obj.PrimaryPart or Obj:FindFirstChild("HumanoidRootPart") or Obj:FindFirstChildWhichIsA("BasePart")) or (Obj:IsA("BasePart") and Obj) or nil
end

function Library:SetFont(Font)
    self.Settings.Font = Font
    for _, Data in pairs(self.Cache) do Data.Text.Font = Font end
end

function Library:SetRainbow(Bool) self.Settings.Rainbow = Bool end
function Library:SetFadeTime(Value) self.Settings.FadeTime = Value end
function Library:SetArrows(Bool) self.Settings.Arrows = Bool end
function Library:SetTracers(Bool) self.Settings.Tracers = Bool end
function Library:SetShowDistance(Bool) self.Settings.Distance = Bool end
function Library:SetESPMode(Value) self.Settings.ESPMode = Value end
function Library:SetRenderingSpeed(Value) Library.Settings.RenderTime = Value end

function Library:AddESP(Cfg)
    local Obj = Cfg.Object
    if not Obj or self.Cache[Obj] then return end

    local Root = GetRoot(Obj)
    task.spawn(function()
        while not Root do
            Root = GetRoot(Obj)
            task.wait(0.5)
        end

        if Root then
            local Billboard = Instance.new("BillboardGui", Obj)
            Billboard.Name = "ESPLibrary"
            Billboard.Size = UDim2.new(0, 250, 0, 60)
            Billboard.AlwaysOnTop = true
            Billboard.Adornee = Root
            
            local Label = Instance.new("TextLabel", Billboard)
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.TextColor3 = Cfg.Color
            Label.Font = self.Settings.Font
            Label.TextSize = self.Settings.TextSize
            Label.TextStrokeTransparency = 0
            Label.TextTransparency = 1
             
            local Highlight = Instance.new("Highlight", Billboard)
            Highlight.Adornee = Obj
            Highlight.FillColor = Cfg.Color
            Highlight.FillTransparency = 1
            Highlight.OutlineTransparency = 1
            Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            local Line = Instance.new("Frame", Screen)
            Line.AnchorPoint = Vector2.new(0.5, 0.5)
            Line.BorderSizePixel = 0
            Line.BackgroundColor3 = Cfg.Color
            Line.Visible = true
            Line.BackgroundTransparency = 1

            local Arrow = Instance.new("ImageLabel", Screen)
            Arrow.BackgroundTransparency = 1
            Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
            Arrow.Size = UDim2.new(0, 32, 0, 32)
            Arrow.Image = "rbxassetid://10526559647"
            Arrow.ImageColor3 = Cfg.Color
            Arrow.Visible = false

            if self.Settings.FadeTime > 0 then
                local TI = TweenInfo.new(self.Settings.FadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                TweenService:Create(Label, TI, {TextTransparency = 0}):Play()
                TweenService:Create(Highlight, TI, {FillTransparency = 0.6}):Play()
                TweenService:Create(Line, TI, {BackgroundTransparency = 0}):Play()
            else
                Label.TextTransparency = 0
                Highlight.FillTransparency = 0.6
                Line.BackgroundTransparency = 0
            end

            self.Cache[Obj] = {
                Tag = Billboard,
                Text = Label,
                Line = Line,
                Box = Highlight,
                Arrow = Arrow,
                Name = Cfg.Text,
                Color = Cfg.Color
            }
        end
    end)
end

function Library:RemoveESP(Obj)
    local Data = self.Cache[Obj]
    if Data then
        self.Cache[Obj] = nil
        if self.Settings.FadeTime > 0 then
            local TI = TweenInfo.new(self.Settings.FadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            TweenService:Create(Data.Text, TI, {TextTransparency = 1}):Play()
            TweenService:Create(Data.Box, TI, {FillTransparency = 1}):Play()
            TweenService:Create(Data.Line, TI, {BackgroundTransparency = 1}):Play()
            
            task.delay(self.Settings.FadeTime, function()
                Data.Tag:Destroy()
                Data.Line:Destroy()
                Data.Box:Destroy()
                Data.Arrow:Destroy()
            end)
        else
            Data.Tag:Destroy()
            Data.Line:Destroy()
            Data.Box:Destroy()
            Data.Arrow:Destroy()
        end
    end
end

function Library:UpdateESP(Obj, NewText, NewColor)
    local Data = self.Cache[Obj]
    if Data then
        if Data.Name ~= NewText then
            Data.Name = NewText
        end
        
        if Data.Color ~= NewColor then
            Data.Color = NewColor
            Data.Text.TextColor3 = NewColor
            Data.Box.FillColor = NewColor
            Data.Line.BackgroundColor3 = NewColor
            Data.Arrow.ImageColor3 = NewColor
        end
    else
        self:AddESP({
            Object = Obj,
            Text = NewText,
            Color = NewColor
        })
    end
end

function Library:BulkUpdateESP(UpdateTable)
    for Obj, Info in pairs(UpdateTable) do
        local Data = self.Cache[Obj]
        if Data then
            local NeedsUpdate = false
            
            if Info.Text and Data.Name ~= Info.Text then
                Data.Name = Info.Text
            end
            
            if Info.Color and Data.Color ~= Info.Color then
                Data.Color = Info.Color
                NeedsUpdate = true
            end
            
            if NeedsUpdate then
                local Color = Info.Color
                Data.Text.TextColor3 = Color
                Data.Box.FillColor = Color
                Data.Line.BackgroundColor3 = Color
                Data.Arrow.ImageColor3 = Color
            end
        else
            if Info.Text and Info.Color then
                self:AddESP({
                    Object = Obj,
                    Text = Info.Text,
                    Color = Info.Color
                })
            end
        end
    end
end

function Library:Unload()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    for Obj, _ in pairs(self.Cache) do
        self:RemoveESP(Obj)
    end

    if Screen then
        Screen:Destroy()
    end
end

local LastUpdateTick = tick()
 
Library.Connection = RS.PreRender:Connect(function()
    local RenderInterval = 1 / Library.Settings.RenderTime

    if tick() - LastUpdateTick > RenderInterval then
        LastUpdateTick = tick()
        
        local Camera = workspace.CurrentCamera
        local CameraCFrame = Camera.CFrame
        local ViewportSize = Camera.ViewportSize
        local ScreenCenter = ViewportSize / 2
        local FOVScale = Camera.FieldOfView / 70
        local RainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)

        for Object, Data in pairs(Library.Cache) do
            if not Object or not Object.Parent then
                Library:RemoveESP(Object)
                continue
            end

            local RootPart = GetRoot(Object)
            if not RootPart then continue end

            local ScreenPosition, IsOnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local DisplayColor = Library.Settings.Rainbow and RainbowColor or Data.Color
            local CalculatedDistance = (CameraCFrame.Position - RootPart.Position).Magnitude

            if CalculatedDistance > Library.Settings.MaxDistance then
                Data.Tag.Enabled = false
                Data.Text.Visible = false
                Data.Box.Enabled = false
                Data.Line.Visible = false
                Data.Arrow.Visible = false
                continue
            end

            if IsOnScreen then
                local ShowHighlight = (Library.Settings.ESPMode == "Highlight" or Library.Settings.ESPMode == "Highlight/Text")
                local ShowText = (Library.Settings.ESPMode == "Text" or Library.Settings.ESPMode == "Highlight/Text")

                Data.Tag.Enabled = true
                Data.Arrow.Visible = false
                
                if ShowText then
                    Data.Text.Visible = true
                    Data.Text.TextColor3 = DisplayColor
                    Data.Text.TextSize = Library.Settings.TextSize * FOVScale
                    Data.Text.Text = string.format("%s%s", Data.Name, Library.Settings.Distance and string.format("\n[%dm]", math.floor(CalculatedDistance)) or "")
                else
                    Data.Text.Visible = false
                end

                if ShowHighlight then
                    Data.Box.Enabled = true
                    Data.Box.FillColor = DisplayColor
                else
                    Data.Box.Enabled = false
                end

                if Library.Settings.Tracers and CalculatedDistance < 1500 then
                    local ScreenPoint = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                    local OriginPoint = Vector2.new(ScreenCenter.X, ViewportSize.Y)
                    local VectorDifference = ScreenPoint - OriginPoint
                    
                    Data.Line.Visible = true
                    Data.Line.BackgroundColor3 = DisplayColor
                    Data.Line.Size = UDim2.new(0, VectorDifference.Magnitude, 0, 1)
                    Data.Line.Position = UDim2.new(0, OriginPoint.X + VectorDifference.X / 2, 0, OriginPoint.Y + VectorDifference.Y / 2)
                    Data.Line.Rotation = math.deg(math.atan2(VectorDifference.Y, VectorDifference.X))
                else
                    Data.Line.Visible = false
                end
            else
                Data.Tag.Enabled = false
                Data.Text.Visible = false
                Data.Box.Enabled = false
                Data.Line.Visible = false
                
                if Library.Settings.Arrows then
                    local ObjectRelativeSpace = CameraCFrame:PointToObjectSpace(RootPart.Position)
                    local DirectionAngle = math.atan2(-ObjectRelativeSpace.X, -ObjectRelativeSpace.Z)
                    local Radius = ViewportSize.Y * 0.4
                    
                    Data.Arrow.Visible = true
                    Data.Arrow.ImageColor3 = DisplayColor
                    Data.Arrow.Position = UDim2.new(0, ScreenCenter.X + math.sin(DirectionAngle) * Radius, 0, ScreenCenter.Y + math.cos(DirectionAngle) * Radius)
                    Data.Arrow.Rotation = math.deg(DirectionAngle)
                else
                    Data.Arrow.Visible = false
                end
            end
        end
    end
end)

return Library
