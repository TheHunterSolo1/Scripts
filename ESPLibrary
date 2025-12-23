local Library = {}
getgenv().ESPLibrary = Library

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Cache = {}
local Connection = nil

local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3New = Color3.new
local DrawingNew = Drawing and Drawing.new
local WorldToViewportPoint = Camera.WorldToViewportPoint
local Round = math.round

local Settings = {
    Tracers = false,
    Distance = false,
    MaxDistance = 5000,
    TextSize = 23,
    Font = Enum.Font.GothamBold
}

local function GetRoot(model)
    if model:IsA("BasePart") then return model end
    if model:IsA("Model") then 
        return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") 
    end
    return nil
end

local function CreateVisuals(part, color, name)
    local root = GetRoot(part)
    if not root then return nil end
    
    if root:IsDescendantOf(LocalPlayer.Character) or part:IsDescendantOf(LocalPlayer.Character) then 
        return nil 
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = color
    highlight.OutlineColor = Color3New(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Enabled = false
    highlight.Parent = part

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3New(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Adornee = root
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = color
    label.Font = Settings.Font
    label.TextSize = Settings.TextSize
    label.Text = name
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3New(0, 0, 0)
    label.Parent = billboard

    local tracer = nil
    if DrawingNew then
        tracer = DrawingNew("Line")
        tracer.Visible = false
        tracer.Color = color
        tracer.Thickness = 1
        tracer.Transparency = 1
    end

    return {
        Root = root,
        Highlight = highlight,
        Gui = billboard,
        Label = label,
        Tracer = tracer,
        Name = name,
        LastDist = -1
    }
end

function Library:SetTracers(bool) 
    Settings.Tracers = bool 
end

function Library:ShowDistance(bool) 
    Settings.Distance = bool 
end

function Library:SetMaxDistance(num) 
    Settings.MaxDistance = num 
end

function Library:RemoveESP(part)
    local data = Cache[part]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Gui then data.Gui:Destroy() end
        if data.Tracer then 
            data.Tracer.Visible = false
            data.Tracer:Remove() 
        end
        Cache[part] = nil
    end
end

function Library:AddESP(part, name, color)
    if not part or Cache[part] then return end
    
    local data = CreateVisuals(part, color, name)
    if not data then return end

    local connection
    connection = part.AncestryChanged:Connect(function(_, parent)
        if not parent then
            connection:Disconnect()
            Library:RemoveESP(part)
        end
    end)

    Cache[part] = data
end

function Library:Unload()
    if Connection then Connection:Disconnect() end
    for part in pairs(Cache) do 
        Library:RemoveESP(part) 
    end
    table.clear(Cache)
    getgenv().ESPLibrary = nil
end

local function Update()
    if not LocalPlayer.Character then return end
    
    Camera = Workspace.CurrentCamera
    local viewportSize = Camera.ViewportSize
    local centerPos = Vector2New(viewportSize.X / 2, viewportSize.Y)
    local currentFOV = Camera.FieldOfView
    
    for _, data in pairs(Cache) do
        local rootPart = data.Root
        
        if not rootPart or not rootPart.Parent then
            data.Gui.Enabled = false
            data.Highlight.Enabled = false
            if data.Tracer then data.Tracer.Visible = false end
            continue
        end

        local rootPosition = rootPart.Position
        local vector, onScreen = Camera:WorldToViewportPoint(rootPosition)
        local distance = (Camera.CFrame.Position - rootPosition).Magnitude

        if distance > Settings.MaxDistance then
            data.Gui.Enabled = false
            data.Highlight.Enabled = false
            if data.Tracer then data.Tracer.Visible = false end
            continue
        end

        if onScreen then
            data.Gui.Enabled = true
            data.Highlight.Enabled = true
            
            data.Label.TextSize = Settings.TextSize * (currentFOV / 70)

            if Settings.Distance then
                local distMath = Round(distance)
                if data.LastDist ~= distMath then
                    data.LastDist = distMath
                    data.Label.Text = string.format("%s\n[%d]", data.Name, distMath)
                end
            else
                if data.Label.Text ~= data.Name then
                    data.Label.Text = data.Name
                end
            end

            if data.Tracer then
                if Settings.Tracers then
                    data.Tracer.From = centerPos
                    data.Tracer.To = Vector2New(vector.X, vector.Y)
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end
            end
        else
            data.Gui.Enabled = false
            data.Highlight.Enabled = false
            if data.Tracer then data.Tracer.Visible = false end
        end
    end
end

Connection = RunService.RenderStepped:Connect(Update)

return Library
