

local StarterGui = game:GetService("StarterGui")

local function notify(title: string, text: string, duration: number): ()
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration,
		})
	end)
end

local function copyToClipboard(text: string): boolean
	local G: any = _G
	local sc: any = G.setclipboard
	if typeof(sc) == "function" then return pcall(sc, text) end
	local tc: any = G.toclipboard
	if typeof(tc) == "function" then return pcall(tc, text) end
	return false
end

notify("Auto Farm", "Wrapper started. Compiling...", 4)

local SCRIPT_SOURCE: string = [==[
--!strict

local StarterGui          = game:GetService("StarterGui")
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace           = game:GetService("Workspace")

local LocalPlayer: Player = Players.LocalPlayer

type TargetState = {
	position: Vector3,
	velocity: Vector3,
	time: number,
}

type ToolCache = { [Tool]: boolean }
type ConnectionList = { RBXScriptConnection }
type AnimMirror = { [AnimationTrack]: AnimationTrack }

local BOUND_POSITION: Vector3     = Vector3.new(0, -499, 0)
local HEAD_SAFE_POSITION: Vector3 = Vector3.new(0, -400, 0)
local SAFE_OFFSET: Vector3        = Vector3.new(0, 1, 0)

local FOCUS_DISTANCE: number      = 5
local TWIN_FANGS_DISTANCE: number = 5

local TWIN_FANGS_TP_DURATION: number          = 2.0
local SAFE_ZONE_DURATION: number              = 2.0
local TWIN_FANGS_TO_GRAND_GAP: number         = 1.5
local GRAND_FISSURE_WAIT: number              = 10
local FALLBACK_TOOL_DURATION: number          = 2.5
local ROTATION_LOOP_DELAY: number             = 0.15
local GRAND_FISSURE_ACTIVATION_TIMEOUT: number = 5
local TWIN_FANGS_ACTIVATION_TIMEOUT: number   = 3.0
local ACTIVATION_RETRY_INTERVAL: number       = 0.05

local TWIN_FANGS_NAME: string    = "Twin Fangs"
local GRAND_FISSURE_NAME: string = "Grand Fissure"

local TWIN_FANGS_SLOT: number    = 2
local GRAND_FISSURE_SLOT: number = 1

local SPAM_ANIMATION_ID: string = "119169968232874"
local SPAM_NUMERIC: string      = SPAM_ANIMATION_ID:match("%d+") or SPAM_ANIMATION_ID

local REMOTE_COOLDOWN: number  = 0.03
local G_INTERVAL: number       = 0.01
local JUMP_INTERVAL: number    = 0.01
local SPACE_HOLD_TIME: number  = 0.03
local RAGDOLL_COOLDOWN: number = 0.5

local CAMERA_SENSITIVITY: number = 0.003
local CAMERA_MIN_DIST: number    = 5
local CAMERA_MAX_DIST: number    = 60
local CAMERA_HEIGHT: number      = 3

local MIN_PREDICTION_TIME: number  = 0.10
local MAX_PREDICTION_TIME: number  = 0.30
local MIN_HISTORY_INTERVAL: number = 1 / 240
local MAX_HISTORY_INTERVAL: number = 0.25
local ACCELERATION_LIMIT: number   = 150

local CLONE_CHECK_INTERVAL: number   = 0.5
local CLONE_REBUILD_COOLDOWN: number = 1.5

local HEAD_DISTANCE_THRESHOLD: number  = 6
local FORCEFIELD_MAX_EFFECTIVE: number = 3
local STEALTH_STREAK_THRESHOLD: number = 6

local HEAD_SAFE_LOCK_DURATION: number = 1.0
local HEAD_SAFE_COOLDOWN: number      = 2.5

local THROWN_CLEAR_DELAY: number = 0.06

local FALLBACK_EXCLUDE: { string } = { TWIN_FANGS_NAME, GRAND_FISSURE_NAME }

local G: any = _G

local function getGuiParent(): Instance
	local gethuiFn: any = G.gethui
	if typeof(gethuiFn) == "function" then
		local ok: boolean, result: any = pcall(gethuiFn)
		if ok and typeof(result) == "Instance" then
			return result
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function randomString(length: number): string
	local chars: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local count: number = #chars
	local parts: { string } = {}
	for i: number = 1, length do
		local idx: number = math.random(1, count)
		parts[i] = chars:sub(idx, idx)
	end
	return table.concat(parts)
end

local function RUN(): ()
	local IS_MOBILE: boolean = UserInputService.TouchEnabled

	pcall(function() math.randomseed(os.time() + math.random(1, 1e6)) end)
	pcall(function() math.randomseed(tick() * 1e6) end)

	local guiParent: Instance = getGuiParent()

	local mainSafeName: string = "P_" .. randomString(14)
	local headSafeName: string = "P_" .. randomString(14)

	local BoundaryZone: Part = Instance.new("Part")
	BoundaryZone.Name = mainSafeName
	BoundaryZone.Size = Vector3.new(2048, 1, 2048)
	BoundaryZone.CFrame = CFrame.new(BOUND_POSITION)
	BoundaryZone.Anchored = true
	BoundaryZone.CanCollide = true
	BoundaryZone.CanQuery = false
	BoundaryZone.CanTouch = false
	BoundaryZone.Transparency = 0.7
	BoundaryZone.Parent = Workspace

	local HeadSafeZone: Part = Instance.new("Part")
	HeadSafeZone.Name = headSafeName
	HeadSafeZone.Size = Vector3.new(2048, 1, 2048)
	HeadSafeZone.CFrame = CFrame.new(HEAD_SAFE_POSITION)
	HeadSafeZone.Anchored = true
	HeadSafeZone.CanCollide = true
	HeadSafeZone.CanQuery = false
	HeadSafeZone.CanTouch = false
	HeadSafeZone.Transparency = 0.7
	HeadSafeZone.Parent = Workspace

	local ScreenGui: ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AutoFarmPanel"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = guiParent

	local Main: Frame = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = UDim2.fromOffset(250, 255)
	Main.Position = UDim2.new(0.5, -125, 0.5, -127)
	Main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	Main.BackgroundTransparency = 0.05
	Main.BorderSizePixel = 0
	Main.Active = true
	Main.Parent = ScreenGui

	local MainCorner: UICorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 12)
	MainCorner.Parent = Main

	local MainStroke: UIStroke = Instance.new("UIStroke")
	MainStroke.Thickness = 1.5
	MainStroke.Transparency = 0.25
	MainStroke.Parent = Main

	local Pad: UIPadding = Instance.new("UIPadding")
	Pad.PaddingTop    = UDim.new(0, 10)
	Pad.PaddingBottom = UDim.new(0, 10)
	Pad.PaddingLeft   = UDim.new(0, 10)
	Pad.PaddingRight  = UDim.new(0, 10)
	Pad.Parent = Main

	local Title: TextLabel = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, -40, 0, 28)
	Title.BackgroundTransparency = 1
	Title.Text = "Auto Farm"
	Title.TextColor3 = Color3.new(1, 1, 1)
	Title.TextSize = 18
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Main

	local Status: TextLabel = Instance.new("TextLabel")
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

	local function makeToggle(name: string, text: string, pos: UDim2): (TextButton, TextLabel)
		local btn: TextButton = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(1, 0, 0, 43)
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.Parent = Main

		local c: UICorner = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 9)
		c.Parent = btn

		local lbl: TextLabel = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -65, 1, 0)
		lbl.Position = UDim2.fromOffset(13, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextSize = 14
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = btn

		local state: TextLabel = Instance.new("TextLabel")
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

		local sc: UICorner = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 7)
		sc.Parent = state

		return btn, state
	end

	local FarmButton: TextButton = nil :: any
	local FarmState: TextLabel   = nil :: any
	FarmButton, FarmState = makeToggle("AutoFarmToggle", "Auto Farm", UDim2.fromOffset(0, 55))

	local PerfButton: TextButton = nil :: any
	local PerfState: TextLabel   = nil :: any
	PerfButton, PerfState = makeToggle("PerformanceToggle", "Performance Mode", UDim2.fromOffset(0, 101))

	local StealthButton: TextButton = nil :: any
	local StealthState: TextLabel   = nil :: any
	StealthButton, StealthState = makeToggle("StealthToggle", "Stealth Mode", UDim2.fromOffset(0, 147))

	local WarningLabel: TextLabel = Instance.new("TextLabel")
	WarningLabel.Name = "Warning"
	WarningLabel.Size = UDim2.new(1, 0, 0, 40)
	WarningLabel.Position = UDim2.fromOffset(0, 195)
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

	local WarnCorner: UICorner = Instance.new("UICorner")
	WarnCorner.CornerRadius = UDim.new(0, 8)
	WarnCorner.Parent = WarningLabel

	local farmEnabled: boolean      = false
	local performanceMode: boolean  = true
	local stealthMode: boolean      = false

	local protectionActive: boolean = false
	local rotationRunning: boolean  = false
	local focusActive: boolean      = false

	local protectionOrigin: CFrame? = nil
	local lastRemoteFire: number  = 0
	local lastGPress: number      = 0
	local lastJumpPress: number   = 0
	local lastRagdollFire: number = 0

	local headSafeLockUntil: number     = 0
	local headSafeCooldownUntil: number = 0

	local characterConnections: ConnectionList = {}
	local permanentConnections: ConnectionList = {}
	local watchedTools: ToolCache = {}

	local targetStates: { [BasePart]: TargetState } = {}

	local windowDragging: boolean  = false
	local windowDragStart: Vector2 = Vector2.zero
	local windowStartPos: UDim2    = UDim2.new()

	local cameraYaw: number      = 0
	local cameraPitch: number    = math.rad(-8)
	local cameraDistance: number = 20

	local cloneCharacter: Model?   = nil
	local cloneRoot: BasePart?     = nil
	local cloneHumanoid: Humanoid? = nil
	local cloneAnimator: Animator? = nil
	local animationMirrors: AnimMirror = {}

	local lastWatchedCharacter: Model? = nil
	local lastCloneCheck: number   = 0
	local lastCloneRebuild: number = 0

	local spamTrack: AnimationTrack? = nil
	local spamTrackCharacter: Model? = nil

	local spaceDown: boolean  = false
	local spaceDownAt: number = 0

	local cachedBackpack: Backpack? = nil
	local thrownConnection: RBXScriptConnection? = nil

	local function setToggle(label: TextLabel, on: boolean): ()
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

	local function isHeadSafeLocked(): boolean
		return os.clock() < headSafeLockUntil
	end

	local function refreshStatus(): ()
		if protectionActive then
			Status.Text = "Mode: Boundary Zone"
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

	FarmButton.Activated:Connect(function()
		farmEnabled = not farmEnabled
		setToggle(FarmState, farmEnabled)
		refreshStatus()
	end)

	PerfButton.Activated:Connect(function()
		performanceMode = not performanceMode
		setToggle(PerfState, performanceMode)
	end)

	StealthButton.Activated:Connect(function()
		stealthMode = not stealthMode
		setToggle(StealthState, stealthMode)
		WarningLabel.Visible = stealthMode
	end)

	setToggle(FarmState, false)
	setToggle(PerfState, true)
	setToggle(StealthState, false)

	Title.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			windowDragging = true
			windowDragStart = Vector2.new(input.Position.X, input.Position.Y)
			windowStartPos = Main.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if windowDragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta: Vector2 =
					Vector2.new(input.Position.X, input.Position.Y) - windowDragStart
				Main.Position = UDim2.new(
					windowStartPos.X.Scale,
					windowStartPos.X.Offset + delta.X,
					windowStartPos.Y.Scale,
					windowStartPos.Y.Offset + delta.Y
				)
			end
			return
		end

		local uit: Enum.UserInputType = input.UserInputType
		if uit == Enum.UserInputType.MouseMovement then
			if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
				cameraYaw = cameraYaw - input.Delta.X * CAMERA_SENSITIVITY
				cameraPitch = math.clamp(
					cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY,
					math.rad(-80), math.rad(80)
				)
			end
		elseif uit == Enum.UserInputType.Touch then
			if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
				cameraYaw = cameraYaw - input.Delta.X * CAMERA_SENSITIVITY * 1.4
				cameraPitch = math.clamp(
					cameraPitch - input.Delta.Y * CAMERA_SENSITIVITY * 1.4,
					math.rad(-80), math.rad(80)
				)
			end
		elseif uit == Enum.UserInputType.MouseWheel then
			cameraDistance = math.clamp(
				cameraDistance - input.Position.Z * 2,
				CAMERA_MIN_DIST, CAMERA_MAX_DIST
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			windowDragging = false
		end
	end)

	local function hasProtection(character: Model): boolean
		if character:FindFirstChild("AbsoluteImmortal") ~= nil then return true end
		if character:FindFirstChild("ForceField") ~= nil then return true end
		if character:FindFirstChild("Freeze") ~= nil then return true end
		if character:FindFirstChild("FinalDeath") ~= nil then return true end
		return false
	end

	local function getRoot(): BasePart?
		local character: Model? = LocalPlayer.Character
		if not character then return nil end
		local root: Instance? = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then return nil end
		return root
	end

	local function getTarget(): Player?
		local root: BasePart? = getRoot()
		if not root then return nil end

		local chosen: Player? = nil
		local lowestHealth: number = math.huge

		local players: { Player } = Players:GetPlayers()
		for i: number = 1, #players do
			local player: Player = players[i]
			if player ~= LocalPlayer then
				local tc: Model? = player.Character
				if tc and not hasProtection(tc) then
					local hum: Humanoid? = tc:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						local tr: Instance? = tc:FindFirstChild("HumanoidRootPart")
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

	local function predictPosition(root: BasePart): Vector3
		local now: number = os.clock()
		local curPos: Vector3 = root.Position
		local curVel: Vector3 = root.AssemblyLinearVelocity
		local state: TargetState? = targetStates[root]

		if not state then
			targetStates[root] = { position = curPos, velocity = curVel, time = now }
			return curPos + Vector3.new(curVel.X, 0, curVel.Z) * MIN_PREDICTION_TIME
		end

		local dt: number = math.clamp(now - state.time, MIN_HISTORY_INTERVAL, MAX_HISTORY_INTERVAL)
		local accel: Vector3 = (curVel - state.velocity) / dt
		if accel.Magnitude > ACCELERATION_LIMIT then
			accel = accel.Unit * ACCELERATION_LIMIT
		end

		local age: number = math.clamp(root.ReceiveAge, 0, MAX_PREDICTION_TIME)
		local predTime: number = math.clamp(
			MIN_PREDICTION_TIME + age + math.clamp(dt - (1 / 60), 0, 0.08),
			MIN_PREDICTION_TIME, MAX_PREDICTION_TIME
		)

		local vXZ: Vector3 = Vector3.new(curVel.X, 0, curVel.Z)
		local aXZ: Vector3 = Vector3.new(accel.X, 0, accel.Z)
		local predicted: Vector3 = curPos + vXZ * predTime + aXZ * (0.5 * predTime * predTime)

		state.position = curPos
		state.velocity = curVel
		state.time = now

		return Vector3.new(predicted.X, curPos.Y, predicted.Z)
	end

	local function alignBehind(root: BasePart, targetRoot: BasePart, distance: number): ()
		if isHeadSafeLocked() then return end
		local predicted: Vector3 = predictPosition(targetRoot)
		if predicted ~= predicted then return end
		local behindDir: Vector3 = -targetRoot.CFrame.LookVector
		local pos: Vector3 = predicted + behindDir * distance
		if pos ~= pos then return end
		root.CFrame = CFrame.lookAt(pos, predicted)
	end

	local function teleportTo(root: BasePart, worldPos: Vector3): ()
		local pos: Vector3 = worldPos + SAFE_OFFSET
		root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, -100, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	local function teleportToSafeZone(root: BasePart): ()
		if isHeadSafeLocked() then return end
		teleportTo(root, BOUND_POSITION)
	end

	local function teleportToHeadSafe(root: BasePart): ()
		teleportTo(root, HEAD_SAFE_POSITION)
	end

	local function teleportToBoundaryUnconditional(root: BasePart): ()
		teleportTo(root, BOUND_POSITION)
	end

	local function countForceFields(character: Model): number
		local count: number = 0
		local children: { Instance } = character:GetChildren()
		for i: number = 1, #children do
			if children[i]:IsA("ForceField") then
				count = count + 1
			end
		end
		return count
	end

	local function effectiveForceFields(character: Model): number
		local raw: number = countForceFields(character)
		if raw <= 0 then return 0 end
		return raw - 1
	end

	local function pressKey(code: Enum.KeyCode): ()
		VirtualInputManager:SendKeyEvent(true, code, false, game)
		VirtualInputManager:SendKeyEvent(false, code, false, game)
	end

	local function pressG(): ()
		local now: number = os.clock()
		if now - lastGPress < G_INTERVAL then return end
		lastGPress = now
		pressKey(Enum.KeyCode.G)
	end

	local function pressJump(): ()
		local now: number = os.clock()
		if now - lastJumpPress < JUMP_INTERVAL then return end
		lastJumpPress = now
		if not spaceDown then
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			spaceDown = true
			spaceDownAt = now
		end
	end

	local function tickSpaceRelease(): ()
		if spaceDown and os.clock() - spaceDownAt >= SPACE_HOLD_TIME then
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			spaceDown = false
		end
	end

	local function getCommunicate(): RemoteEvent?
		local character: Model? = LocalPlayer.Character
		if not character then return nil end
		local comm: Instance? = character:FindFirstChild("Communicate")
		if not comm or not comm:IsA("RemoteEvent") then return nil end
		return comm
	end

	local function getMouseCFrame(): CFrame?
		local cam: Camera? = Workspace.CurrentCamera
		if not cam then return nil end
		local mp: Vector2 = UserInputService:GetMouseLocation()
		local ray: Ray = cam:ViewportPointToRay(mp.X, mp.Y)
		return CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction * 1000)
	end

	local function fireCommunicate(): ()
		local now: number = os.clock()
		if now - lastRemoteFire < REMOTE_COOLDOWN then return end
		lastRemoteFire = now
		local comm: RemoteEvent? = getCommunicate()
		if not comm then return end
		local mouseCF: CFrame? = getMouseCFrame()
		if not mouseCF then return end
		comm:FireServer({
			Mobile   = IS_MOBILE,
			Goal     = "LeftClick",
			MousePos = mouseCF,
		})
	end

	local function activateToolViaRemote(tool: Tool): ()
		local comm: RemoteEvent? = getCommunicate()
		if not comm then return end
		comm:FireServer({
			Tool = tool,
			Goal = "Console Move",
			IsAutoActivate = true,
		})
	end

	local function fireRagdollFinish(): ()
		local comm: RemoteEvent? = getCommunicate()
		if not comm then return end
		local mouseCF: CFrame? = getMouseCFrame()
		if not mouseCF then return end
		comm:FireServer({
			Dash = Enum.KeyCode.W,
			Key = Enum.KeyCode.Q,
			Goal = "KeyPress",
			MousePos = mouseCF,
		})
	end

	local function tryFireRagdollFinish(): ()
		local now: number = os.clock()
		if now - lastRagdollFire < RAGDOLL_COOLDOWN then return end
		local target: Player? = getTarget()
		if not target then return end
		local tc: Model? = target.Character
		if not tc then return end
		if tc:FindFirstChild("Ragdoll") == nil then return end
		lastRagdollFire = now
		fireRagdollFinish()
	end

	local function getBackpack(): Backpack?
		if cachedBackpack and cachedBackpack.Parent then return cachedBackpack end
		local bp: Instance? = LocalPlayer:FindFirstChild("Backpack")
		if bp and bp:IsA("Backpack") then
			cachedBackpack = bp
			return bp
		end
		return nil
	end

	local function findTool(name: string): Tool?
		local target: string = string.lower(name)
		local bp: Backpack? = getBackpack()
		if bp then
			local children: { Instance } = bp:GetChildren()
			for i: number = 1, #children do
				local c: Instance = children[i]
				if c:IsA("Tool") and string.lower(c.Name) == target then return c end
			end
		end
		local ch: Model? = LocalPlayer.Character
		if ch then
			local children: { Instance } = ch:GetChildren()
			for i: number = 1, #children do
				local c: Instance = children[i]
				if c:IsA("Tool") and string.lower(c.Name) == target then return c end
			end
		end
		return nil
	end

	local function getAllTools(exclude: { string }): { Tool }
		local excl: { [string]: boolean } = {}
		for i: number = 1, #exclude do excl[string.lower(exclude[i])] = true end

		local result: { Tool } = {}
		local bp: Backpack? = getBackpack()
		if bp then
			local children: { Instance } = bp:GetChildren()
			for i: number = 1, #children do
				local c: Instance = children[i]
				if c:IsA("Tool") and not excl[string.lower(c.Name)] then
					table.insert(result, c)
				end
			end
		end
		local ch: Model? = LocalPlayer.Character
		if ch then
			local children: { Instance } = ch:GetChildren()
			for i: number = 1, #children do
				local c: Instance = children[i]
				if c:IsA("Tool") and not excl[string.lower(c.Name)] then
					table.insert(result, c)
				end
			end
		end
		return result
	end

	local function twinFangsExists(): boolean
		return findTool(TWIN_FANGS_NAME) ~= nil
	end

	local function genericSpam(): ()
		if twinFangsExists() then return end
		pressJump()
		fireCommunicate()
		tryFireRagdollFinish()
	end

	local function hotbarHasCooldown(slot: number): boolean
		local pg: PlayerGui? = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not pg then return false end
		local hotbar: Instance? = pg:FindFirstChild("Hotbar")
		if not hotbar then return false end
		local bp: Instance? = hotbar:FindFirstChild("Backpack")
		if not bp then return false end
		local slots: Instance? = bp:FindFirstChild("Hotbar")
		if not slots then return false end
		local frame: Instance? = slots:FindFirstChild(tostring(slot))
		if not frame then return false end
		local base: Instance? = frame:FindFirstChild("Base")
		if not base then return false end
		return base:FindFirstChild("Cooldown") ~= nil
	end

	local function activateToolAndVerify(tool: Tool, slot: number, timeout: number): boolean
		local start: number = os.clock()
		while os.clock() - start < timeout do
			if not farmEnabled or protectionActive then return false end
			if isHeadSafeLocked() then return false end

			activateToolViaRemote(tool)

			local waited: number = 0
			while waited < ACTIVATION_RETRY_INTERVAL do
				if not farmEnabled or protectionActive then return false end
				if isHeadSafeLocked() then return false end
				if hotbarHasCooldown(slot) then return true end
				local step: number = math.min(0.01, ACTIVATION_RETRY_INTERVAL - waited)
				task.wait(step)
				waited = waited + step
			end
		end
		return hotbarHasCooldown(slot)
	end

	local function ensureInvisible(): ()
		local character: Model? = LocalPlayer.Character
		if not character then return end
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end

		if spamTrackCharacter ~= character then
			if spamTrack then
				pcall(function() (spamTrack :: AnimationTrack):Stop(0) end)
			end
			spamTrack = nil
			spamTrackCharacter = character
			local anim: Animation = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. SPAM_ANIMATION_ID
			local ok: boolean, track: any = pcall(function()
				return animator:LoadAnimation(anim)
			end)
			if ok and typeof(track) == "Instance" then
				track.Priority = Enum.AnimationPriority.Action4
				track.Looped = false
				spamTrack = track
			end
		end
		local t: AnimationTrack? = spamTrack
		if not t then return end
		if not t.IsPlaying then t:Play(0, 1, 0) end
		if t.Speed ~= 0 then t:AdjustSpeed(0) end
		if t.TimePosition ~= 0 then t.TimePosition = 0 end
		if t.WeightCurrent < 0.99 then t:AdjustWeight(1, 0) end
	end

	local function validateClone(): boolean
		local cc: Model? = cloneCharacter
		if not cc or not cc.Parent then return false end
		if not cc:FindFirstChild("HumanoidRootPart") then return false end
		if not cc:FindFirstChildOfClass("Humanoid") then return false end
		if not cc:FindFirstChild("Head") then return false end
		return true
	end

	local function syncCloneAnimations(): ()
		local character: Model? = LocalPlayer.Character
		local cc: Model? = cloneCharacter
		if not character or not cc or not cc.Parent then return end

		local ca: Animator? = cloneAnimator
		if not ca or not ca.Parent then
			local ch: Humanoid? = cloneHumanoid
			if ch and ch.Parent then
				local a: Animator? = ch:FindFirstChildOfClass("Animator")
				if not a then a = Instance.new("Animator"); a.Parent = ch end
				ca = a
				cloneAnimator = a
			else return end
		end
		if not ca then return end

		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end

		local tracks: { AnimationTrack } = animator:GetPlayingAnimationTracks()
		local active: { [AnimationTrack]: boolean } = {}

		for i: number = 1, #tracks do
			local track: AnimationTrack = tracks[i]
			local anim: Animation? = track.Animation
			if anim then
				local numeric: string? = anim.AnimationId:match("%d+")
				if numeric ~= SPAM_NUMERIC then
					active[track] = true
					local mirror: AnimationTrack? = animationMirrors[track]
					if not mirror then
						local cloneAnim: Animation = Instance.new("Animation")
						cloneAnim.AnimationId = anim.AnimationId
						local ok: boolean, t: any = pcall(function()
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
					local m: AnimationTrack? = mirror
					if m then
						m.Priority = track.Priority
						m.Looped = track.Looped
						if not m.IsPlaying then m:Play(0, 1, track.Speed) end
						local w: number = track.WeightCurrent
						if w < 0.01 then w = 0.01 end
						m:AdjustWeight(w, 0)
						if math.abs(m.Speed - track.Speed) > 0.001 then m:AdjustSpeed(track.Speed) end
						if m.TimePosition ~= track.TimePosition then m.TimePosition = track.TimePosition end
					end
				end
			end
		end

		for track, mirror in pairs(animationMirrors) do
			if not active[track] then
				if mirror.IsPlaying then mirror:Stop(0.05) end
				animationMirrors[track] = nil
			end
		end
	end

	local function createClone(): ()
		local old: Model? = cloneCharacter
		if old then old:Destroy() end
		cloneCharacter = nil
		cloneRoot = nil
		cloneHumanoid = nil
		cloneAnimator = nil
		animationMirrors = {}

		local character: Model? = LocalPlayer.Character
		if not character then return end
		if not character:FindFirstChild("HumanoidRootPart") then return end
		if not character:FindFirstChildOfClass("Humanoid") then return end

		local ok: boolean, clone: any = pcall(function() return character:Clone() end)
		if not ok or typeof(clone) ~= "Instance" then return end

		clone.Name = "VisualFocusClone"

		local descendants: { Instance } = clone:GetDescendants()
		for i: number = 1, #descendants do
			local d: Instance = descendants[i]
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
				local kids: { Instance } = d:GetChildren()
				for k: number = 1, #kids do
					local kid: Instance = kids[k]
					if kid:IsA("Sound") or kid:IsA("SoundGroup") then kid:Destroy() end
				end
			elseif d:IsA("ProximityPrompt") then
				d.Enabled = false
			end
		end

		local humanoid: Humanoid? = clone:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.AutoRotate = false
			humanoid.PlatformStand = true
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			humanoid.MaxHealth = 100
			humanoid.Health = 100
			cloneHumanoid = humanoid
			local anim: Animator? = humanoid:FindFirstChildOfClass("Animator")
			if not anim then
				anim = Instance.new("Animator")
				anim.Parent = humanoid
			end
			cloneAnimator = anim
		end

		clone.Parent = Workspace
		cloneCharacter = clone

		local root: Instance? = clone:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then cloneRoot = root end
	end

	local function getStreak(): number
		local character: Model? = LocalPlayer.Character
		if not character then return 0 end
		local v: any = character:GetAttribute("CurrentStreak")
		if typeof(v) == "number" then return v end
		return 0
	end

	local function killSelf(): ()
		local character: Model? = LocalPlayer.Character
		if not character then return end
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		if humanoid.Health > 0 then
			pcall(function() humanoid.Health = 0 end)
		end
	end

	local function headTooClose(): boolean
		local character: Model? = LocalPlayer.Character
		if not character then return false end
		local realHead: Instance? = character:FindFirstChild("Head")
		if not realHead or not realHead:IsA("BasePart") then return false end
		local cc: Model? = cloneCharacter
		if not cc or not cc.Parent then return false end
		local cloneHead: Instance? = cc:FindFirstChild("Head")
		if not cloneHead or not cloneHead:IsA("BasePart") then return false end
		return (realHead.Position - cloneHead.Position).Magnitude <= HEAD_DISTANCE_THRESHOLD
	end

	local function startThrownWatcher(): ()
		if thrownConnection then thrownConnection:Disconnect() end
		local thrown: Instance? = Workspace:FindFirstChild("Thrown")
		if not thrown then return end
		thrownConnection = thrown.ChildAdded:Connect(function()
			task.wait(THROWN_CLEAR_DELAY)
			pcall(function()
				(thrown :: Instance):ClearAllChildren()
			end)
		end)
	end

	local function runRotationLoop(): ()
		if rotationRunning or protectionActive then return end
		rotationRunning = true
		refreshStatus()

		while farmEnabled and not protectionActive do
			if isHeadSafeLocked() then
				refreshStatus()
				task.wait(0.05)
				continue
			end

			local character: Model? = LocalPlayer.Character
			if not character then break end

			local tf: Tool? = findTool(TWIN_FANGS_NAME)

			if tf then
				local effective: number = effectiveForceFields(character)
				local skipWait: boolean =
					stealthMode and (effective >= FORCEFIELD_MAX_EFFECTIVE)

				local alreadyOnCooldown: boolean = hotbarHasCooldown(TWIN_FANGS_SLOT)

				if not skipWait and not alreadyOnCooldown then
					local verified: boolean = activateToolAndVerify(
						tf, TWIN_FANGS_SLOT, TWIN_FANGS_ACTIVATION_TIMEOUT
					)

					if not verified then
						task.wait(0.3)
						continue
					end

					if not farmEnabled or protectionActive then break end
					if isHeadSafeLocked() then continue end

					local tpEnd: number = os.clock() + TWIN_FANGS_TP_DURATION
					while os.clock() < tpEnd do
						if not farmEnabled or protectionActive then break end
						if isHeadSafeLocked() then break end

						local root: BasePart? = getRoot()
						if root then
							local target: Player? = getTarget()
							if target then
								local tc: Model? = target.Character
								if tc then
									local tr: Instance? = tc:FindFirstChild("HumanoidRootPart")
									if tr and tr:IsA("BasePart") and not hasProtection(tc) then
										alignBehind(root, tr, TWIN_FANGS_DISTANCE)
									end
								end
							end
						end

						pressG()

						local remaining: number = tpEnd - os.clock()
						if remaining <= 0 then break end
						task.wait(math.min(remaining, 1 / 120))
					end
				end

				if not farmEnabled or protectionActive then break end
				if isHeadSafeLocked() then task.wait(0.05); continue end

				local root: BasePart? = getRoot()
				if not root then break end
				local originCFrame: CFrame = root.CFrame
				teleportToSafeZone(root)

				local safeEnd: number = os.clock() + SAFE_ZONE_DURATION
				while os.clock() < safeEnd do
					if not farmEnabled or protectionActive then break end
					if isHeadSafeLocked() then break end
					teleportToSafeZone(root)
					pressG()
					local remaining: number = safeEnd - os.clock()
					if remaining <= 0 then break end
					task.wait(math.min(remaining, 1 / 120))
				end

				if not farmEnabled or protectionActive then break end
				if isHeadSafeLocked() then task.wait(0.05); continue end

				if root and root.Parent and not isHeadSafeLocked() then
					root.CFrame = originCFrame
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end

				local gapEnd: number = os.clock() + TWIN_FANGS_TO_GRAND_GAP
				while os.clock() < gapEnd do
					if not farmEnabled or protectionActive then break end
					if isHeadSafeLocked() then break end
					pressG()
					local remaining: number = gapEnd - os.clock()
					if remaining <= 0 then break end
					task.wait(math.min(remaining, 1 / 120))
				end

				if not farmEnabled or protectionActive then break end
				if isHeadSafeLocked() then task.wait(0.05); continue end

				local gf: Tool? = findTool(GRAND_FISSURE_NAME)
				if gf then
					local gfVerified: boolean = activateToolAndVerify(
						gf, GRAND_FISSURE_SLOT, GRAND_FISSURE_ACTIVATION_TIMEOUT
					)
					if not gfVerified then
						task.wait(0.3)
						continue
					end
				end

				if not farmEnabled or protectionActive then break end
				if isHeadSafeLocked() then task.wait(0.05); continue end

				local gfWaitEnd: number = os.clock() + GRAND_FISSURE_WAIT
				while os.clock() < gfWaitEnd do
					if not farmEnabled or protectionActive then break end
					if isHeadSafeLocked() then break end
					pressG()
					local remaining: number = gfWaitEnd - os.clock()
					if remaining <= 0 then break end
					task.wait(math.min(remaining, 1 / 120))
				end

			else
				local tools: { Tool } = getAllTools(FALLBACK_EXCLUDE)
				if #tools == 0 then break end

				for ti: number = 1, #tools do
					if not farmEnabled or protectionActive then break end
					if isHeadSafeLocked() then break end
					local tool: Tool = tools[ti]
					activateToolViaRemote(tool)
					local fbEnd: number = os.clock() + FALLBACK_TOOL_DURATION
					while os.clock() < fbEnd do
						if not farmEnabled or protectionActive then break end
						if isHeadSafeLocked() then break end
						local root: BasePart? = getRoot()
						if root then
							local target: Player? = getTarget()
							if target then
								local tc: Model? = target.Character
								if tc then
									local tr: Instance? = tc:FindFirstChild("HumanoidRootPart")
									if tr and tr:IsA("BasePart") and not hasProtection(tc) then
										alignBehind(root, tr, FOCUS_DISTANCE)
									end
								end
							end
						end
						pressG()
						genericSpam()
						local remaining: number = fbEnd - os.clock()
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

	local function processFocusAssist(): ()
		if not farmEnabled or rotationRunning or protectionActive then
			focusActive = false
			return
		end
		if isHeadSafeLocked() then
			focusActive = false
			return
		end
		local root: BasePart? = getRoot()
		if not root then focusActive = false; return end
		local target: Player? = getTarget()
		if not target then focusActive = false; return end
		local tc: Model? = target.Character
		if not tc then focusActive = false; return end
		local tr: Instance? = tc:FindFirstChild("HumanoidRootPart")
		if not tr or not tr:IsA("BasePart") or hasProtection(tc) then
			focusActive = false
			return
		end
		alignBehind(root, tr, FOCUS_DISTANCE)
		focusActive = true
	end

	local function disconnectCharacterConnections(): ()
		for i: number = 1, #characterConnections do
			local c: RBXScriptConnection = characterConnections[i]
			if c then c:Disconnect() end
		end
		characterConnections = {}
		watchedTools = {}
	end

	local function watchTool(tool: Tool): ()
		if watchedTools[tool] then return end
		watchedTools[tool] = true
	end

	local function watchCharacter(character: Model): ()
		disconnectCharacterConnections()
		targetStates = {}
		cachedBackpack = nil

		local bp: Backpack? = getBackpack()
		if bp then
			local children: { Instance } = bp:GetChildren()
			for i: number = 1, #children do
				local c: Instance = children[i]
				if c:IsA("Tool") then watchTool(c) end
			end
			table.insert(characterConnections, bp.ChildAdded:Connect(function(c: Instance)
				if c:IsA("Tool") then watchTool(c) end
			end))
		end

		local children: { Instance } = character:GetChildren()
		for i: number = 1, #children do
			local c: Instance = children[i]
			if c:IsA("Tool") then watchTool(c) end
		end
		table.insert(characterConnections, character.ChildAdded:Connect(function(c: Instance)
			if c:IsA("Tool") then watchTool(c) end
		end))

		lastWatchedCharacter = character
		createClone()
		lastCloneRebuild = os.clock()
	end

	table.insert(permanentConnections, RunService.Heartbeat:Connect(function()
		local character: Model? = LocalPlayer.Character
		if not character then return end
		local root: BasePart? = getRoot()
		if not root then return end

		local protected: boolean = character:FindFirstChild("AbsoluteImmortal") ~= nil
		if protected and not protectionActive then
			protectionOrigin = root.CFrame
			protectionActive = true
			refreshStatus()
		elseif not protected and protectionActive then
			protectionActive = false
			local po: CFrame? = protectionOrigin
			if po and root.Parent then
				root.CFrame = po
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			protectionOrigin = nil
			refreshStatus()
		end

		if protectionActive then
			teleportToSafeZone(root)
			return
		end

		if farmEnabled then
			local now: number = os.clock()

			if headTooClose() and now >= headSafeCooldownUntil then
				headSafeLockUntil = now + HEAD_SAFE_LOCK_DURATION
				headSafeCooldownUntil = now + HEAD_SAFE_COOLDOWN
			end

			if now < headSafeLockUntil then
				teleportToHeadSafe(root)
				refreshStatus()
				return
			end
		end

		if stealthMode and farmEnabled then
			if getStreak() >= STEALTH_STREAK_THRESHOLD then
				teleportToBoundaryUnconditional(root)
				killSelf()
				return
			end
		end

		if farmEnabled then
			pressG()
			genericSpam()

			if not rotationRunning then
				task.spawn(runRotationLoop)
			end

			processFocusAssist()
		else
			focusActive = false
		end
	end))

	table.insert(permanentConnections, RunService.RenderStepped:Connect(function()
		tickSpaceRelease()

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

		local character: Model? = LocalPlayer.Character
		if character ~= lastWatchedCharacter then
			lastWatchedCharacter = character
			if character then
				watchCharacter(character)
				refreshStatus()
			end
		end

		local now: number = os.clock()
		if now - lastCloneCheck >= CLONE_CHECK_INTERVAL then
			lastCloneCheck = now
			if not validateClone() and (now - lastCloneRebuild) >= CLONE_REBUILD_COOLDOWN then
				lastCloneRebuild = now
				createClone()
			end
		end

		ensureInvisible()

		local realRoot: BasePart? = getRoot()
		local cc: Model? = cloneCharacter
		if cc and cc.Parent and realRoot then
			if not isHeadSafeLocked() then
				cc:PivotTo(realRoot.CFrame)
			end
			syncCloneAnimations()
		end

		local cam: Camera? = Workspace.CurrentCamera
		if not cam then return end

		local cr: BasePart? = cloneRoot
		local followRoot: BasePart? = nil
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

		local targetPos: Vector3 = followRoot.Position + Vector3.new(0, CAMERA_HEIGHT, 0)
		local rotation: CFrame = CFrame.fromEulerAnglesYXZ(cameraPitch, cameraYaw, 0)
		local camPos: Vector3 = targetPos - rotation.LookVector * cameraDistance

		cam.CFrame = CFrame.lookAt(camPos, targetPos)
	end))

	table.insert(permanentConnections, Players.PlayerRemoving:Connect(function(player: Player)
		local ch: Model? = player.Character
		if not ch then return end
		local root: Instance? = ch:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			targetStates[root] = nil
		end
	end))

	if LocalPlayer.Character then
		lastWatchedCharacter = LocalPlayer.Character
		watchCharacter(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(function(character: Model)
		rotationRunning = false
		protectionActive = false
		protectionOrigin = nil
		focusActive = false
		spamTrack = nil
		spamTrackCharacter = nil
		cachedBackpack = nil
		spaceDown = false
		lastRagdollFire = 0
		headSafeLockUntil = 0
		headSafeCooldownUntil = 0

		targetStates = {}
		lastWatchedCharacter = character
		watchCharacter(character)
		refreshStatus()
	end)
end

RUN()
]==]

local loader: any = loadstring
if typeof(loader) ~= "function" then
	local msg: string = "LOAD ERROR: loadstring is not available in this executor."
	copyToClipboard(msg)
	notify("Auto Farm - Load Error", msg, 15)
	warn(msg)
	return
end

local loadedFn: any, loadErr: any = loader(SCRIPT_SOURCE)
if not loadedFn then
	local msg: string = "LOAD ERROR (compile-time)\n\n" .. tostring(loadErr)
	copyToClipboard(msg)
	notify("Auto Farm - Load Error",
		"Compile error copied to clipboard.\n" .. tostring(loadErr):sub(1, 80), 15)
	warn(msg)
	return
end

local ok: boolean, runErr: any = xpcall(loadedFn, function(e: any): string
	local msg: string = tostring(e)
	local tb: string = debug.traceback("", 2)
	return msg .. "\n\n" .. tb
end)

if not ok then
	local fullMsg: string = "RUNTIME ERROR\n\n" .. tostring(runErr)
	local copied: boolean = copyToClipboard(fullMsg)
	local preview: string = tostring(runErr):sub(1, 80)
	if copied then
		notify("Auto Farm - Runtime Error",
			"Error copied to clipboard.\n" .. preview, 15)
	else
		notify("Auto Farm - Runtime Error",
			"Clipboard failed.\n" .. preview, 15)
	end
	warn(fullMsg)
	return
end

notify("Auto Farm", "Loaded successfully. Turn ON Auto Farm to activate.", 5)