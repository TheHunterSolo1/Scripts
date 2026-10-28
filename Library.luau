local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Colors = {
	Background = Color3.fromRGB(15, 17, 23),
	Sidebar    = Color3.fromRGB(20, 23, 30),
	Element    = Color3.fromRGB(25, 28, 36),
	Accent     = Color3.fromRGB(0, 102, 255),
	Text       = Color3.fromRGB(255, 255, 255),
	SubText    = Color3.fromRGB(150, 155, 165),
	Stroke     = Color3.fromRGB(40, 45, 55),
	Danger     = Color3.fromRGB(255, 60, 60),
	Success    = Color3.fromRGB(60, 200, 100),
	Disabled   = Color3.fromRGB(18, 20, 26),
	DisabledTxt= Color3.fromRGB(100, 105, 115)
}

local Fonts = {
	Bold    = Enum.Font.GothamBold,
	Medium  = Enum.Font.GothamMedium,
	Regular = Enum.Font.Gotham
}

local TweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function Create(className, properties, children)
	local inst = Instance.new(className)
	if properties then
		for k, v in pairs(properties) do inst[k] = v end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	return inst
end

local function Tween(inst, props)
	return TweenService:Create(inst, TweenInfoFast, props)
end

local function GetKeyName(keyCode)
	local n = keyCode.Name
	if n:sub(1, 6) == "Keypad" then return n:sub(7) end
	if n:sub(1, 3) == "Key"    then return n:sub(4) end
	if n:sub(1, 6) == "Button" then return n:sub(7) end
	return n
end

local function GenerateRandomString(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local out = table.create(len)
	for i = 1, len do
		local r = math.random(1, #chars)
		out[i] = string.sub(chars, r, r)
	end
	return table.concat(out)
end

local function GetUIParent()
	if gethui then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function SafeCall(fn, ...)
	if not fn then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[UI] callback error:", err) end
end

local function IsTyping()
	local ok, box = pcall(function() return UserInputService:GetFocusedTextBox() end)
	return ok and box ~= nil
end

local function SmartArg(a, b)
	if b ~= nil then return b end
	return a
end

local ParticleSystem = {}
function ParticleSystem.Create(parent, opts)
	opts = opts or {}
	local count    = opts.Count       or 14
	local color    = opts.Color       or Colors.Accent
	local minSize  = opts.MinSize     or 2
	local maxSize  = opts.MaxSize     or 4
	local speed    = opts.Speed       or 14
	local minTrans = opts.MinTransparency or 0.65
	local maxTrans = opts.MaxTransparency or 0.9
	local z        = opts.ZIndex      or 0
	local rng = Random.new()

	local container = Create("Frame", {
		Name = "ParticleField",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = z,
		Parent = parent
	})

	local particles = {}
	for i = 1, count do
		local size = rng:NextNumber(minSize, maxSize)
		local p = Create("Frame", {
			Name = "Particle",
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromScale(rng:NextNumber(0, 1), rng:NextNumber(0, 1)),
			BackgroundColor3 = color,
			BackgroundTransparency = rng:NextNumber(minTrans, maxTrans),
			BorderSizePixel = 0,
			ZIndex = z,
			Parent = container
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = p })
		particles[i] = {
			Frame = p,
			Vel   = Vector2.new(rng:NextNumber(-speed, speed), rng:NextNumber(-speed, speed))
		}
	end

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not container.Parent then return end
		local sz = container.AbsoluteSize
		if sz.X <= 0 or sz.Y <= 0 then return end
		for _, pt in ipairs(particles) do
			local f = pt.Frame
			local px = f.Position.X.Scale * sz.X + f.Position.X.Offset + pt.Vel.X * dt
			local py = f.Position.Y.Scale * sz.Y + f.Position.Y.Offset + pt.Vel.Y * dt
			local s = f.AbsoluteSize.X
			if px < -s - 4 then px = sz.X + 4
			elseif px > sz.X + 4 then px = -s - 4 end
			if py < -s - 4 then py = sz.Y + 4
			elseif py > sz.Y + 4 then py = -s - 4 end
			f.Position = UDim2.fromOffset(px, py)
		end
	end)

	return {
		Container = container,
		Destroy = function() conn:Disconnect(); container:Destroy() end
	}
end

local Library = {}
Library.__index = Library

local SaveManager = {}

local function EnsureFolder(self)
	if not makefolder then return end
	pcall(function()
		local f = self.FolderName
		if not isfolder(f) then makefolder(f) end
		if not isfolder(f .. "/Configs") then makefolder(f .. "/Configs") end
	end)
end

function SaveManager.List(self)
	EnsureFolder(self)
	local list = {}
	if not listfiles then return list end
	local ok, files = pcall(function() return listfiles(self.FolderName .. "/Configs") end)
	if ok and files then
		for _, file in ipairs(files) do
			local name = file:match("([^/\\]+)%.json$") or file:match("([^/\\]+)$")
			if name then
				name = name:gsub("%.json$", "")
				table.insert(list, name)
			end
		end
	end
	return list
end

function SaveManager.Save(self, name)
	if not writefile then return false end
	EnsureFolder(self)
	local data = { Toggles = {}, Options = {}, Keybinds = {}, Textboxes = {} }
	for k, v in pairs(self.Toggles) do data.Toggles[k] = v.Value end
	for k, v in pairs(self.Options) do
		if typeof(v.Value) == "Color3" then
			data.Options[k] = { __type = "Color3", R = v.Value.R, G = v.Value.G, B = v.Value.B }
		else
			data.Options[k] = v.Value
		end
	end
	for k, v in pairs(self.Keybinds) do data.Keybinds[k] = v.KeyCode.Name end
	for k, v in pairs(self.Textboxes or {}) do data.Textboxes[k] = v.Value end
	local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false end
	return pcall(function()
		writefile(self.FolderName .. "/Configs/" .. name .. ".json", enc)
	end)
end

function SaveManager.LoadConfig(self, name)
	if not readfile or not isfile then return false end
	local path = self.FolderName .. "/Configs/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or not data then return false end

	for k, v in pairs(data.Toggles or {}) do
		if self.Toggles[k] and self.Toggles[k].Set then self.Toggles[k].Set(v) end
	end
	for k, v in pairs(data.Options or {}) do
		local opt = self.Options[k]
		if opt and opt.Set then
			if type(v) == "table" and v.__type == "Color3" then
				opt.Set(Color3.new(v.R, v.G, v.B))
			else
				opt.Set(v)
			end
		end
	end
	for k, keyName in pairs(data.Keybinds or {}) do
		local entry = self.Keybinds[k]
		local kc = Enum.KeyCode[keyName]
		if entry and kc then
			entry.KeyCode = kc
			if entry.UpdateUI then entry.UpdateUI() end
		end
	end
	for k, v in pairs(data.Textboxes or {}) do
		if self.Textboxes[k] and self.Textboxes[k].Set then self.Textboxes[k].Set(v) end
	end

	if self.RefreshKeybindOverlay then self:RefreshKeybindOverlay() end
	return true
end

SaveManager.Load = SaveManager.LoadConfig

function SaveManager.Delete(self, name)
	if not delfile then return false end
	local path = self.FolderName .. "/Configs/" .. name .. ".json"
	if isfile and isfile(path) then
		return pcall(function() delfile(path) end)
	end
	return false
end

Library.SaveManager = SaveManager

function Library.new(windowInfo)
	local self = setmetatable({}, Library)

	self.FolderName = (windowInfo.FolderName or windowInfo.Title or "UILibrary"):gsub("%s+", "")
	self.Toggles    = {}
	self.Options    = {}
	self.Keybinds   = {}
	self.Textboxes  = {}
	self.Dropdowns  = {}
	self.Connections = {}
	self.Particles   = {}
	self.Tabs        = {}
	self.CurrentTab  = nil
	self.KeybindsShown = false
	self.Locked      = false

	local function track(conn)
		table.insert(self.Connections, conn)
		return conn
	end

	local screenGui = Create("ScreenGui", {
		Name = GenerateRandomString(10),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = GetUIParent()
	})
	self.ScreenGui = screenGui

	local overlay = Create("Frame", {
		Name = "KeybindOverlay",
		Size = UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 8,
		Parent = screenGui
	})
	self.KeybindOverlay = overlay
	Create("UIScale", { Parent = overlay })
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = overlay })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = overlay })
	Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = overlay })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
		Parent = overlay
	})
	Create("TextLabel", {
		Text = "Keybinds",
		Font = Fonts.Bold, TextSize = 12, TextColor3 = Colors.SubText,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = -1, Parent = overlay
	})

	table.insert(self.Particles, ParticleSystem.Create(overlay, {
		Count = 12, Color = Colors.Accent,
		MinSize = 2, MaxSize = 3, Speed = 10,
		MinTransparency = 0.7, MaxTransparency = 0.9, ZIndex = 0
	}))

	local oDrag, oIn, oStart, oPos
	track(overlay.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			oDrag, oIn, oStart, oPos = true, i, i.Position, overlay.Position
			track(i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then oDrag = false end
			end))
		end
	end))
	track(overlay.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			oIn = i
		end
	end))
	track(UserInputService.InputChanged:Connect(function(i)
		if oDrag and i == oIn then
			local d = i.Position - oStart
			overlay.Position = UDim2.new(oPos.X.Scale, oPos.X.Offset + d.X, oPos.Y.Scale, oPos.Y.Offset + d.Y)
		end
	end))

	local main = Create("Frame", {
		Name = GenerateRandomString(8),
		Size = UDim2.fromOffset(650, 450),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = screenGui
	})
	self.Main = main
	Create("UIScale", { Parent = main })
	Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = main })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = main })

	table.insert(self.Particles, ParticleSystem.Create(main, {
		Count = 26, Color = Colors.Accent,
		MinSize = 2, MaxSize = 5, Speed = 12,
		MinTransparency = 0.85, MaxTransparency = 0.95, ZIndex = 0
	}))

	local topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = main
	})

	if windowInfo.Icon and windowInfo.Icon ~= "" then
		Create("ImageLabel", {
			Image = windowInfo.Icon, Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(20, 8), BackgroundTransparency = 1,
			Parent = topBar
		})
	end

	Create("TextLabel", {
		Text = windowInfo.Title or "Example Hub",
		Font = Fonts.Bold, TextSize = 16, TextColor3 = Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
		Position = UDim2.fromOffset((windowInfo.Icon and windowInfo.Icon ~= "") and 52 or 20, 0),
		Size = UDim2.new(1, -160, 1, 0), Parent = topBar
	})

	local keybindBtn = Create("TextButton", {
		Text = "Keybinds", Font = Fonts.Bold, TextSize = 12,
		TextColor3 = Colors.SubText, BackgroundColor3 = Colors.Element,
		Position = UDim2.new(1, -110, 0, 8), Size = UDim2.fromOffset(70, 28),
		Parent = topBar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keybindBtn })

	local closeBtn = Create("TextButton", {
		Text = "X", Font = Fonts.Bold, TextSize = 16,
		TextColor3 = Colors.SubText, BackgroundTransparency = 1,
		Position = UDim2.new(1, -40, 0, 0), Size = UDim2.fromOffset(30, 40),
		Parent = topBar
	})

	track(closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {TextColor3 = Colors.Danger}):Play() end))
	track(closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {TextColor3 = Colors.SubText}):Play() end))
	track(closeBtn.MouseButton1Click:Connect(function() main.Visible = false end))

	local function refreshKeybindBtn()
		overlay.Visible = self.KeybindsShown
		Tween(keybindBtn, {
			TextColor3 = self.KeybindsShown and Colors.Text or Colors.SubText,
			BackgroundColor3 = self.KeybindsShown and Colors.Accent or Colors.Element
		}):Play()
	end
	track(keybindBtn.MouseButton1Click:Connect(function()
		self.KeybindsShown = not self.KeybindsShown
		refreshKeybindBtn()
	end))
	self.RefreshKeybindBtn = refreshKeybindBtn

	local function makeSideButton(text, yOffset)
		local btn = Create("TextButton", {
			Text = "",
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(20, yOffset),
			Size = UDim2.fromOffset(120, 32),
			ZIndex = 5,
			Parent = screenGui
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = btn })
		table.insert(self.Particles, ParticleSystem.Create(btn, {
			Count = 8, Color = Colors.Accent,
			MinSize = 1, MaxSize = 2.5, Speed = 10,
			MinTransparency = 0.65, MaxTransparency = 0.9, ZIndex = 0
		}))
		Create("TextLabel", {
			Text = text, Font = Fonts.Bold, TextSize = 13,
			TextColor3 = Colors.Text, BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = btn
		})
		return btn
	end

	local toggleUIbtn = makeSideButton("Toggle UI", 60)
	local lockBtn     = makeSideButton("Lock",      100)
	local unlockBtn   = makeSideButton("Unlock",    140)

	track(toggleUIbtn.MouseButton1Click:Connect(function()
		main.Visible = not main.Visible
		if main.Visible then main.ZIndex = 10 end
	end))

	local function setLocked(v)
		self.Locked = v
		Tween(lockBtn,   { BackgroundColor3 = v and Colors.Danger  or Colors.Background }):Play()
		Tween(unlockBtn, { BackgroundColor3 = v and Colors.Background or Colors.Success }):Play()
	end
	track(lockBtn.MouseButton1Click:Connect(function() setLocked(true)  end))
	track(unlockBtn.MouseButton1Click:Connect(function() setLocked(false) end))
	setLocked(false)

	local footerOffset = windowInfo.Footer and -65 or -40
	if windowInfo.Footer then
		local footer = Create("Frame", {
			Name = "Footer", Size = UDim2.new(1, 0, 0, 25),
			Position = UDim2.new(0, 0, 1, -25),
			BackgroundTransparency = 1, ZIndex = 3, Parent = main
		})
		Create("TextLabel", {
			Text = windowInfo.Footer, Font = Fonts.Medium, TextSize = 12,
			TextColor3 = Colors.SubText, BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
			Parent = footer
		})
	end

	local sidebar = Create("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, 150, 1, footerOffset),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Colors.Sidebar, BorderSizePixel = 0,
		ZIndex = 2, Parent = main
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = sidebar
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = sidebar
	})

	local searchBox = Create("TextBox", {
		Text = "",
		PlaceholderText = "Search tabs...",
		Font = Fonts.Medium, TextSize = 13,
		TextColor3 = Colors.Text,
		PlaceholderColor3 = Colors.SubText,
		BackgroundColor3 = Colors.Element,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = sidebar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBox })
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = searchBox })

	track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(searchBox.Text)
		for _, tab in ipairs(self.Tabs) do
			local matched = q == "" or string.find(string.lower(tab.Label.Text), q, 1, true) ~= nil
			tab.Button.Visible = matched
			tab.Button.Size = matched and UDim2.new(1, 0, 0, 35) or UDim2.new(0, 0, 0, 0)
		end
	end))

	local tabContainer = Create("Frame", {
		Name = "TabContainer", Size = UDim2.new(1, -150, 1, footerOffset),
		Position = UDim2.fromOffset(150, 40),
		BackgroundTransparency = 1, ZIndex = 2, Parent = main
	})
	self.Sidebar = sidebar
	self.TabContainer = tabContainer

	local mDrag, mIn, mStart, mPos
	track(topBar.InputBegan:Connect(function(i)
		if self.Locked then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			mDrag, mIn, mStart, mPos = true, i, i.Position, main.Position
			track(i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then mDrag = false end
			end))
		end
	end))
	track(topBar.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			mIn = i
		end
	end))
	track(UserInputService.InputChanged:Connect(function(i)
		if mDrag and not self.Locked and i == mIn then
			local d = i.Position - mStart
			local sc = main:FindFirstChildOfClass("UIScale")
			local s = sc and sc.Scale or 1
			main.Position = UDim2.new(
				mPos.X.Scale, mPos.X.Offset + d.X / s,
				mPos.Y.Scale, mPos.Y.Offset + d.Y / s
			)
		end
	end))

	track(UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if IsTyping() then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		for _, entry in pairs(self.Keybinds) do
			if entry.KeyCode == input.KeyCode then
				SafeCall(entry.Callback)
			end
		end
	end))

	self:AddKeybindGlobal("Toggle Menu", Enum.KeyCode.RightShift, function()
		main.Visible = not main.Visible
	end)

	local notifContainer = Create("Frame", {
		Name = "Notifications",
		Size = UDim2.fromOffset(280, 400),
		Position = UDim2.new(1, -300, 0, 20),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = screenGui
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifContainer
	})
	self.NotifContainer = notifContainer
	self._notifOrder = 0

	refreshKeybindBtn()
	self:SetDPI(isMobile and "75%" or "100%")
	return self
end

function Library:Notify(title, text, duration)
	duration = duration or 3
	self._notifOrder = self._notifOrder + 1
	local order = self._notifOrder

	local frame = Create("Frame", {
		Size = UDim2.fromOffset(260, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = self.NotifContainer
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = frame })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		Parent = frame
	})
	Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = frame })
	Create("TextLabel", {
		Text = title, Font = Fonts.Bold, TextSize = 13, TextColor3 = Colors.Accent,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = frame
	})
	Create("TextLabel", {
		Text = text, Font = Fonts.Medium, TextSize = 12, TextColor3 = Colors.Text,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame
	})

	Tween(frame, { BackgroundTransparency = 0 }):Play()
	task.delay(duration, function()
		if not frame.Parent then return end
		local t = Tween(frame, { BackgroundTransparency = 1 })
		t:Play()
		t.Completed:Connect(function() frame:Destroy() end)
	end)
end

function Library:AddKeybindGlobal(name, keyCode, callback)
	self.Keybinds[name] = {
		Name = name, KeyCode = keyCode, Callback = callback
	}
	self:RefreshKeybindOverlay()
end

function Library:RefreshKeybindOverlay()
	local overlay = self.KeybindOverlay
	if not overlay then return end
	for _, c in ipairs(overlay:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for name, entry in pairs(self.Keybinds) do
		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Colors.Element, Text = "",
			AutoButtonColor = false, ZIndex = 1, Parent = overlay
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })
		Create("TextLabel", {
			Text = name, Font = Fonts.Medium, TextSize = 12,
			TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -50, 1, 0), Parent = row
		})
		Create("TextLabel", {
			Text = GetKeyName(entry.KeyCode), Font = Fonts.Bold, TextSize = 12,
			TextColor3 = Colors.Accent, TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1, Position = UDim2.new(1, -44, 0, 0),
			Size = UDim2.fromOffset(36, 26), Parent = row
		})
		row.MouseButton1Click:Connect(function() SafeCall(entry.Callback) end)
	end
end

function Library:SetDPI(scale)
	local num
	if type(scale) == "number" then num = scale
	elseif type(scale) == "string" then num = tonumber(scale:match("%d+")) end
	if not num then return end
	local factor = math.clamp(num / 100, 0.25, 2.0)

	local ms = self.Main:FindFirstChildOfClass("UIScale")
	if ms then ms.Scale = factor end
	if self.KeybindOverlay then
		local ks = self.KeybindOverlay:FindFirstChildOfClass("UIScale")
		if ks then ks.Scale = factor end
	end
end

local function CreateElementFactory(self, parentContainer)
	local api = {}
	local orderCounter = 0
	local function nextOrder() orderCounter = orderCounter + 1; return orderCounter end

	local function track(conn) table.insert(self.Connections, conn); return conn end

	function api:AddToggle(name, callback, default, config)
		config = config or {}
		local value = default or false
		local disabled = config.Disabled or false

		self.Toggles[name] = { Value = value, Disabled = disabled }

		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = disabled and Colors.Disabled or Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local label = Create("TextLabel", {
			Text = name, Font = Fonts.Medium, TextSize = 14,
			TextColor3 = disabled and Colors.DisabledTxt or Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -60, 1, 0), Parent = bg
		})
		local sw = Create("Frame", {
			Size = UDim2.fromOffset(36, 20),
			Position = UDim2.new(1, -46, 0.5, -10),
			BackgroundColor3 = disabled and Colors.Stroke or (value and Colors.Accent or Colors.Stroke),
			BackgroundTransparency = disabled and 0.5 or 0,
			Parent = bg
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
		local dot = Create("Frame", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(value and 18 or 2, 2),
			BackgroundColor3 = disabled and Colors.DisabledTxt or Colors.Text,
			Parent = sw
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", Parent = bg
		})

		local function applyVisual()
			if disabled then
				Tween(bg, { BackgroundColor3 = Colors.Disabled }):Play()
				Tween(label, { TextColor3 = Colors.DisabledTxt }):Play()
				Tween(sw, { BackgroundColor3 = Colors.Stroke, BackgroundTransparency = 0.5 }):Play()
				Tween(dot, { BackgroundColor3 = Colors.DisabledTxt }):Play()
			else
				Tween(bg, { BackgroundColor3 = Colors.Element }):Play()
				Tween(label, { TextColor3 = Colors.Text }):Play()
				Tween(sw, { BackgroundColor3 = value and Colors.Accent or Colors.Stroke, BackgroundTransparency = 0 }):Play()
				Tween(dot, { BackgroundColor3 = Colors.Text }):Play()
			end
		end

		local function setValueInternal(v)
			if disabled and v then return end
			value = v
			self.Toggles[name].Value = v
			Tween(sw, { BackgroundColor3 = v and Colors.Accent or Colors.Stroke }):Play()
			Tween(dot, { Position = UDim2.fromOffset(v and 18 or 2, 2) }):Play()
			SafeCall(callback, v)
		end

		local function setDisabledInternal(v)
			disabled = v
			self.Toggles[name].Disabled = v
			if v and value then
				value = false
				self.Toggles[name].Value = false
				Tween(sw, { BackgroundColor3 = Colors.Stroke }):Play()
				Tween(dot, { Position = UDim2.fromOffset(2, 2) }):Play()
				SafeCall(callback, false)
			end
			applyVisual()
		end

		local function smartSetValue(a, b) setValueInternal(SmartArg(a, b)) end
		local function smartSetDisabled(a, b) setDisabledInternal(SmartArg(a, b)) end

		self.Toggles[name].Set = smartSetValue
		self.Toggles[name].SetValue = smartSetValue
		self.Toggles[name].SetDisabled = smartSetDisabled
		self.Toggles[name].Get = function() return value end
		self.Toggles[name].IsDisabled = function() return disabled end

		track(btn.MouseButton1Click:Connect(function()
			if disabled then return end
			setValueInternal(not value)
		end))

		return self.Toggles[name]
	end

	function api:AddSlider(name, callback, min, max, default)
		min = min or 0
		max = max or 100
		if max <= min then max = min + 1 end
		default = math.clamp(default or min, min, max)
		self.Options[name] = { Value = default }
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 45),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local label = Create("TextLabel", {
			Text = name .. ": " .. tostring(default),
			Font = Fonts.Medium, TextSize = 14, TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 0, 20), Parent = bg
		})
		local hitbox = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 1, -30),
			BackgroundTransparency = 1, Parent = bg
		})
		local bar = Create("Frame", {
			Size = UDim2.new(1, -20, 0, 4),
			Position = UDim2.new(0, 10, 0.5, -2),
			BackgroundColor3 = Colors.Stroke, Parent = hitbox
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
		local fill = Create("Frame", {
			Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = Colors.Accent, Parent = bar
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

		local dragging = false
		local function update(input)
			local bp = bar.AbsolutePosition.X
			local bs = bar.AbsoluteSize.X
			if bs <= 0 then return end
			local rel = math.clamp((input.Position.X - bp) / bs, 0, 1)
			local v = math.floor(min + (max - min) * rel + 0.5)
			self.Options[name].Value = v
			label.Text = name .. ": " .. tostring(v)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			SafeCall(callback, v)
		end
		track(hitbox.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(i)
			end
		end))
		track(UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				update(i)
			end
		end))
		track(UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
		self.Options[name].Set = function(v)
			v = math.clamp(v, min, max)
			self.Options[name].Value = v
			label.Text = name .. ": " .. tostring(v)
			fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
			SafeCall(callback, v)
		end
		return self.Options[name]
	end

	function api:AddButton(name, callback)
		local btn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element, Text = "",
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
		Create("TextLabel", {
			Text = name, Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), Parent = btn
		})
		track(btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Colors.Accent }):Play() end))
		track(btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Colors.Element }):Play() end))
		track(btn.MouseButton1Click:Connect(function() SafeCall(callback) end))
	end

	function api:AddKeybind(name, keyCode, callback)
		self:AddKeybindGlobal(name, keyCode, callback)
		local entry = self.Keybinds[name]
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("TextLabel", {
			Text = name, Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -60, 1, 0), Parent = bg
		})
		local keyBtn = Create("TextButton", {
			Text = GetKeyName(keyCode), Font = Fonts.Bold, TextSize = 13,
			TextColor3 = Colors.Accent, BackgroundColor3 = Colors.Background,
			Position = UDim2.new(1, -60, 0.5, -12), Size = UDim2.fromOffset(50, 24),
			Parent = bg
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keyBtn })

		local capturing = false
		local function updateUI()
			keyBtn.Text = GetKeyName(entry.KeyCode)
		end
		entry.UpdateUI = updateUI
		track(keyBtn.MouseButton1Click:Connect(function()
			if capturing then return end
			capturing = true
			keyBtn.Text = "..."
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.Keyboard then
					conn:Disconnect()
					capturing = false
					entry.KeyCode = input.KeyCode
					updateUI()
					self:RefreshKeybindOverlay()
				end
			end)
			track(conn)
		end))
	end

	function api:AddLabel(text)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("TextLabel", {
			Text = text, Font = Fonts.Regular, TextSize = 13,
			TextColor3 = Colors.SubText, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = bg
		})
	end

	function api:AddImage(image, height)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, height or 120),
			BackgroundColor3 = Colors.Element, ClipsDescendants = true,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("ImageLabel", {
			Image = image, Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, Parent = bg
		})
	end

	function api:AddTextBox(name, callback, default)
		self.Textboxes[name] = { Value = default or "" }
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local box = Create("TextBox", {
			Text = default or "", PlaceholderText = name,
			Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, PlaceholderColor3 = Colors.SubText,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false, Parent = bg
		})
		box.FocusLost:Connect(function()
			self.Textboxes[name].Value = box.Text
			SafeCall(callback, box.Text)
		end)
		self.Textboxes[name].Set = function(v) box.Text = v end
		return box
	end

	function api:AddDropdown(name, options, callback, default)
		local selected = (default and table.find(options, default)) and default or options[1] or ""
		self.Options[name] = { Value = selected }
		local currentOptions = options

		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", Parent = bg
		})
		local displayLabel = Create("TextLabel", {
			Text = name .. ": " .. selected, Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -30, 1, 0), Parent = bg
		})
		local arrow = Create("TextLabel", {
			Text = "v", Font = Fonts.Bold, TextSize = 12,
			TextColor3 = Colors.SubText, BackgroundTransparency = 1,
			Position = UDim2.new(1, -20, 0, 0), Size = UDim2.fromOffset(20, 35),
			Parent = bg
		})

		local listBg = Create("ScrollingFrame", {
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0, Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.Accent,
			ZIndex = 100, Parent = self.Main
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listBg })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = listBg })
		Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = listBg })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
			Parent = listBg
		})
		table.insert(self.Dropdowns, listBg)

		local outsideConn = nil

		local function closeList()
			listBg.Visible = false
			Tween(arrow, { Rotation = 0 }):Play()
			if outsideConn then
				outsideConn:Disconnect()
				outsideConn = nil
			end
		end

		local function populate(opts)
			for _, c in ipairs(listBg:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for i, opt in ipairs(opts) do
				local ob = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 25),
					BackgroundColor3 = Colors.Element, Text = opt,
					Font = Fonts.Medium, TextSize = 13, TextColor3 = Colors.Text,
					LayoutOrder = i, Parent = listBg
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ob })
				track(ob.MouseEnter:Connect(function() Tween(ob, { BackgroundColor3 = Colors.Accent }):Play() end))
				track(ob.MouseLeave:Connect(function() Tween(ob, { BackgroundColor3 = Colors.Element }):Play() end))
				track(ob.MouseButton1Click:Connect(function()
					selected = opt
					self.Options[name].Value = opt
					displayLabel.Text = name .. ": " .. opt
					closeList()
					SafeCall(callback, opt)
				end))
			end
		end
		populate(currentOptions)

		track(btn.MouseButton1Click:Connect(function()
			if listBg.Visible then
				closeList()
				return
			end
			for _, d in ipairs(self.Dropdowns) do
				if d ~= listBg then d.Visible = false end
			end

			local absPos  = bg.AbsolutePosition
			local absSize = bg.AbsoluteSize
			local mainAbs = self.Main.AbsolutePosition
			local ms = self.Main:FindFirstChildOfClass("UIScale")
			local scale = ms and ms.Scale or 1

			local listVisualH = math.min(#currentOptions * 27 + 10, 150)
			local viewport = Workspace.CurrentCamera.ViewportSize
			local dropY = absPos.Y + absSize.Y + 5
			if dropY + listVisualH > viewport.Y - 10 then
				dropY = absPos.Y - listVisualH - 5
			end
			if dropY < 10 then dropY = 10 end

			local relX = (absPos.X  - mainAbs.X) / scale
			local relY = (dropY     - mainAbs.Y) / scale

			listBg.Position = UDim2.fromOffset(relX, relY)
			listBg.Size     = UDim2.fromOffset(absSize.X / scale, listVisualH / scale)
			listBg.Visible  = true
			Tween(arrow, { Rotation = 180 }):Play()

			outsideConn = UserInputService.InputBegan:Connect(function(i, gp)
				if gp then return end
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
				if not listBg.Visible then
					if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
					return
				end
				local mp = UserInputService:GetMouseLocation()
				local lp, ls = listBg.AbsolutePosition, listBg.AbsoluteSize
				local bp, bs = bg.AbsolutePosition, bg.AbsoluteSize
				local inList = mp.X >= lp.X and mp.X <= lp.X + ls.X and mp.Y >= lp.Y and mp.Y <= lp.Y + ls.Y
				local inBtn  = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
				if not inList and not inBtn then closeList() end
			end)
			track(outsideConn)
		end))

		self.Options[name].Set = function(v)
			selected = v
			self.Options[name].Value = v
			displayLabel.Text = name .. ": " .. tostring(v)
		end
		self.Options[name].Refresh = function(newOpts)
			currentOptions = newOpts
			populate(currentOptions)
			if #currentOptions > 0 and not table.find(currentOptions, selected) then
				selected = currentOptions[1]
				self.Options[name].Value = selected
				displayLabel.Text = name .. ": " .. selected
			end
		end
		return self.Options[name]
	end

	function api:AddMultiDropdown(name, options, callback, default)
		local selected = {}
		default = default or {}
		for _, v in ipairs(default) do
			if table.find(options, v) then selected[v] = true end
		end
		self.Options[name] = { Value = selected }
		local currentOptions = options

		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", Parent = bg
		})
		local displayLabel = Create("TextLabel", {
			Text = name .. ": (0)", Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -30, 1, 0), Parent = bg
		})
		local arrow = Create("TextLabel", {
			Text = "v", Font = Fonts.Bold, TextSize = 12,
			TextColor3 = Colors.SubText, BackgroundTransparency = 1,
			Position = UDim2.new(1, -20, 0, 0), Size = UDim2.fromOffset(20, 35),
			Parent = bg
		})

		local listBg = Create("ScrollingFrame", {
			Size = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0, Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2, ScrollBarImageColor3 = Colors.Accent,
			ZIndex = 100, Parent = self.Main
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listBg })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = listBg })
		Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = listBg })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
			Parent = listBg
		})
		table.insert(self.Dropdowns, listBg)

		local outsideConn = nil

		local function updateDisplay()
			local count = 0
			for _ in pairs(selected) do count = count + 1 end
			if count == 0 then
				displayLabel.Text = name .. ": (none)"
			elseif count <= 2 then
				local names = {}
				for k in pairs(selected) do table.insert(names, k) end
				displayLabel.Text = name .. ": " .. table.concat(names, ", ")
			else
				displayLabel.Text = name .. ": (" .. count .. " selected)"
			end
		end

		local function closeList()
			listBg.Visible = false
			Tween(arrow, { Rotation = 0 }):Play()
			if outsideConn then
				outsideConn:Disconnect()
				outsideConn = nil
			end
		end

		local function populate(opts)
			for _, c in ipairs(listBg:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for i, opt in ipairs(opts) do
				local ob = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 25),
					BackgroundColor3 = selected[opt] and Colors.Accent or Colors.Element,
					Text = opt, Font = Fonts.Medium, TextSize = 13,
					TextColor3 = Colors.Text, LayoutOrder = i, Parent = listBg
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ob })
				track(ob.MouseEnter:Connect(function()
					if not selected[opt] then Tween(ob, { BackgroundColor3 = Colors.Accent }):Play() end
				end))
				track(ob.MouseLeave:Connect(function()
					if not selected[opt] then Tween(ob, { BackgroundColor3 = Colors.Element }):Play() end
				end))
				track(ob.MouseButton1Click:Connect(function()
					if selected[opt] then
						selected[opt] = nil
						Tween(ob, { BackgroundColor3 = Colors.Element }):Play()
					else
						selected[opt] = true
						Tween(ob, { BackgroundColor3 = Colors.Accent }):Play()
					end
					self.Options[name].Value = selected
					updateDisplay()
					SafeCall(callback, selected)
				end))
			end
		end
		populate(currentOptions)
		updateDisplay()

		track(btn.MouseButton1Click:Connect(function()
			if listBg.Visible then
				closeList()
				return
			end
			for _, d in ipairs(self.Dropdowns) do
				if d ~= listBg then d.Visible = false end
			end

			local absPos  = bg.AbsolutePosition
			local absSize = bg.AbsoluteSize
			local mainAbs = self.Main.AbsolutePosition
			local ms = self.Main:FindFirstChildOfClass("UIScale")
			local scale = ms and ms.Scale or 1

			local listVisualH = math.min(#currentOptions * 27 + 10, 150)
			local viewport = Workspace.CurrentCamera.ViewportSize
			local dropY = absPos.Y + absSize.Y + 5
			if dropY + listVisualH > viewport.Y - 10 then
				dropY = absPos.Y - listVisualH - 5
			end
			if dropY < 10 then dropY = 10 end

			local relX = (absPos.X  - mainAbs.X) / scale
			local relY = (dropY     - mainAbs.Y) / scale

			listBg.Position = UDim2.fromOffset(relX, relY)
			listBg.Size     = UDim2.fromOffset(absSize.X / scale, listVisualH / scale)
			listBg.Visible  = true
			Tween(arrow, { Rotation = 180 }):Play()

			outsideConn = UserInputService.InputBegan:Connect(function(i, gp)
				if gp then return end
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
				if not listBg.Visible then
					if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
					return
				end
				local mp = UserInputService:GetMouseLocation()
				local lp, ls = listBg.AbsolutePosition, listBg.AbsoluteSize
				local bp, bs = bg.AbsolutePosition, bg.AbsoluteSize
				local inList = mp.X >= lp.X and mp.X <= lp.X + ls.X and mp.Y >= lp.Y and mp.Y <= lp.Y + ls.Y
				local inBtn  = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
				if not inList and not inBtn then closeList() end
			end)
			track(outsideConn)
		end))

		self.Options[name].Set = function(v)
			if type(v) ~= "table" then return end
			local newSel = {}
			for k, val in pairs(v) do
				if type(k) == "number" then
					if type(val) == "string" and table.find(currentOptions, val) then
						newSel[val] = true
					end
				elseif val and table.find(currentOptions, k) then
					newSel[k] = true
				end
			end
			selected = newSel
			self.Options[name].Value = selected
			populate(currentOptions)
			updateDisplay()
		end
		self.Options[name].Refresh = function(newOpts)
			currentOptions = newOpts
			populate(currentOptions)
			updateDisplay()
		end
		self.Options[name].GetSelected = function()
			local t = {}
			for k in pairs(selected) do table.insert(t, k) end
			return t
		end
		return self.Options[name]
	end

	function api:AddColorPicker(name, callback, default)
		default = default or Color3.fromRGB(255, 255, 255)
		self.Options[name] = { Value = default }

		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			LayoutOrder = nextOrder(), Parent = parentContainer
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("TextLabel", {
			Text = name, Font = Fonts.Medium, TextSize = 14,
			TextColor3 = Colors.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -60, 1, 0), Parent = bg
		})
		local swatch = Create("Frame", {
			Position = UDim2.new(1, -46, 0.5, -10),
			Size = UDim2.fromOffset(36, 20),
			BackgroundColor3 = default, Parent = bg
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = swatch })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = swatch })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "", Parent = bg
		})

		local panel = Create("Frame", {
			Size = UDim2.fromOffset(240, 145),
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0, Visible = false,
			ZIndex = 100, Parent = self.Main
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = panel })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = panel })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
			Parent = panel
		})

		local preview = Create("Frame", {
			Position = UDim2.fromOffset(10, 8),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = default, Parent = panel
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = preview })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = preview })

		local h, s, v = default:ToHSV()
		local updateFromHSV

		local function makeHSVSlider(yPos, labelText, minV, maxV, initialVal, getGradient, onChange)
			local container = Create("Frame", {
				Position = UDim2.fromOffset(60, yPos),
				Size = UDim2.new(1, -70, 0, 20),
				BackgroundTransparency = 1,
				Parent = panel
			})
			Create("TextLabel", {
				Text = labelText,
				Position = UDim2.fromOffset(-50, 0),
				Size = UDim2.fromOffset(50, 20),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Fonts.Medium, TextSize = 11, TextColor3 = Colors.SubText,
				BackgroundTransparency = 1, Parent = container
			})
			local bar = Create("Frame", {
				Position = UDim2.fromOffset(0, 6),
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = Colors.Stroke, Parent = container
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
			local grad = Create("UIGradient", { Parent = bar })
			if getGradient then
				local c = getGradient()
				if c then grad.Color = c end
			end
			local marker = Create("Frame", {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new((initialVal - minV) / (maxV - minV), -6, 0.5, -6),
				BackgroundColor3 = Colors.Text, Parent = bar
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = marker })
			Create("UIStroke", { Color = Colors.Background, Thickness = 1, Parent = marker })

			local dragging = false
			local function update(input)
				local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				marker.Position = UDim2.new(rel, -6, 0.5, -6)
				onChange(minV + (maxV - minV) * rel)
			end
			track(bar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					update(i)
				end
			end))
			track(UserInputService.InputChanged:Connect(function(i)
				if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					update(i)
				end
			end))
			track(UserInputService.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end))

			return {
				SetValue = function(vv)
					marker.Position = UDim2.new((vv - minV) / (maxV - minV), -6, 0.5, -6)
				end,
				SetGradient = function(c) grad.Color = c end
			}
		end

		local hueSlider = makeHSVSlider(55, "H", 0, 1, h,
			function()
				return ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
				})
			end,
			function(newH) h = newH; updateFromHSV() end
		)

		local satSlider = makeHSVSlider(80, "S", 0, 1, s, nil, function(newS)
			s = newS; updateFromHSV()
		end)

		local valSlider = makeHSVSlider(105, "V", 0, 1, v, nil, function(newV)
			v = newV; updateFromHSV()
		end)

		updateFromHSV = function()
			local base = Color3.fromHSV(h, 1, 1)
			satSlider.SetGradient(ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, base)
			}))
			valSlider.SetGradient(ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, base)
			}))
			local color = Color3.fromHSV(h, s, v)
			self.Options[name].Value = color
			swatch.BackgroundColor3 = color
			preview.BackgroundColor3 = color
			SafeCall(callback, color)
		end
		updateFromHSV()

		local outsideConn = nil

		local function closePanel()
			panel.Visible = false
			if outsideConn then
				outsideConn:Disconnect()
				outsideConn = nil
			end
		end

		track(btn.MouseButton1Click:Connect(function()
			if panel.Visible then
				closePanel()
				return
			end
			local bgAbs   = bg.AbsolutePosition
			local mainAbs = self.Main.AbsolutePosition
			local ms      = self.Main:FindFirstChildOfClass("UIScale")
			local scale   = ms and ms.Scale or 1

			local relX = (bgAbs.X - mainAbs.X) / scale
			local relY = (bgAbs.Y - mainAbs.Y + bg.AbsoluteSize.Y + 5) / scale
			panel.Position = UDim2.fromOffset(relX, relY)
			panel.Visible = true

			outsideConn = UserInputService.InputBegan:Connect(function(i, gp)
				if gp then return end
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
				if not panel.Visible then
					if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
					return
				end
				local mp = UserInputService:GetMouseLocation()
				local pp, ps = panel.AbsolutePosition, panel.AbsoluteSize
				local bp, bs = bg.AbsolutePosition, bg.AbsoluteSize
				local inP = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
				local inB = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
				if not inP and not inB then closePanel() end
			end)
			track(outsideConn)
		end))

		self.Options[name].Set = function(color)
			if typeof(color) == "Color3" then
				h, s, v = color:ToHSV()
				hueSlider.SetValue(h)
				satSlider.SetValue(s)
				valSlider.SetValue(v)
				updateFromHSV()
			end
		end
		return self.Options[name]
	end

	return api
end

function Library:CreateTab(tabInfo)
	local tabButton = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 35),
		LayoutOrder = #self.Tabs + 1,
		BackgroundColor3 = Colors.Element, BackgroundTransparency = 1,
		Text = "", Parent = self.Sidebar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabButton })
	local tabLabel = Create("TextLabel", {
		Text = tabInfo.Name, Font = Fonts.Medium, TextSize = 14,
		TextColor3 = Colors.SubText, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -10, 1, 0), Parent = tabButton
	})
	local container = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollBarImageColor3 = Colors.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = self.TabContainer
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10), Parent = container
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 15), PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15),
		Parent = container
	})
	local leftCol = Create("Frame", {
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = 1, Parent = container
	})
	Create("UIListLayout", { Padding = UDim.new(0, 10), Parent = leftCol })
	local rightCol = Create("Frame", {
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = 2, Parent = container
	})
	Create("UIListLayout", { Padding = UDim.new(0, 10), Parent = rightCol })

	local tab = { Button = tabButton, Container = container, Label = tabLabel }
	table.insert(self.Tabs, tab)

	local function select()
		if self.CurrentTab == tab then return end
		if self.CurrentTab then
			Tween(self.CurrentTab.Button, { BackgroundTransparency = 1 }):Play()
			Tween(self.CurrentTab.Label, { TextColor3 = Colors.SubText }):Play()
			self.CurrentTab.Container.Visible = false
		end
		self.CurrentTab = tab
		Tween(tabButton, { BackgroundTransparency = 0, BackgroundColor3 = Colors.Accent }):Play()
		Tween(tabLabel,  { TextColor3 = Colors.Text }):Play()
		container.Visible = true
	end
	tabButton.MouseButton1Click:Connect(select)
	if #self.Tabs == 1 then select() end

	local api = CreateElementFactory(self, leftCol)

	function api:AddGroupbox(name, side)
		local col = (side == "Right") and rightCol or leftCol
		local gb = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Colors.Element, Parent = col
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = gb })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = gb })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = gb
		})
		Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = gb })
		Create("TextLabel", {
			Text = name, Font = Fonts.Bold, TextSize = 13, TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20), LayoutOrder = -1, Parent = gb
		})
		local content = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Parent = gb
		})
		Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = content })
		return CreateElementFactory(self, content)
	end

	function api:AddConfigPanel()
		local gb = self:AddGroupbox("Configs", "Right")
		local nameBox = gb:AddTextBox("Config Name", nil, "")
		local dropdown = gb:AddDropdown("Config", self:ListConfigs(), nil)

		gb:AddButton("Save", function()
			local cfgName = nameBox.Text
			if cfgName == "" then
				self:Notify("Config", "Enter a name first", 2)
				return
			end
			local ok = self:Save(cfgName)
			self:Notify("Config", ok and "Saved!" or "Save failed", 2)
			dropdown.Refresh(self:ListConfigs())
		end)

		gb:AddButton("Load", function()
			local cfgName = dropdown.Value
			if not cfgName or cfgName == "" then
				self:Notify("Config", "Select a config", 2)
				return
			end
			local ok = self:LoadConfig(cfgName)
			self:Notify("Config", ok and "Loaded!" or "Load failed", 2)
		end)

		gb:AddButton("Delete", function()
			local cfgName = dropdown.Value
			if not cfgName or cfgName == "" then return end
			local ok = self:DeleteConfig(cfgName)
			self:Notify("Config", ok and "Deleted!" or "Delete failed", 2)
			dropdown.Refresh(self:ListConfigs())
		end)

		return { Dropdown = dropdown, NameBox = nameBox }
	end

	return api
end

function Library:Save(name)          return SaveManager.Save(self, name) end
function Library:LoadConfig(name)    return SaveManager.LoadConfig(self, name) end
function Library:DeleteConfig(name)  return SaveManager.Delete(self, name) end
function Library:ListConfigs()       return SaveManager.List(self) end

function Library:Destroy()
	for _, c in ipairs(self.Connections) do
		pcall(function() c:Disconnect() end)
	end
	self.Connections = {}
	for _, p in ipairs(self.Particles) do
		pcall(function() p.Destroy() end)
	end
	self.Particles = {}
	if self.ScreenGui then self.ScreenGui:Destroy() end
	self.Toggles, self.Options, self.Keybinds, self.Textboxes = {}, {}, {}, {}
	self.Dropdowns, self.Tabs, self.KeybindOverlay = {}, {}, nil
end

return Library