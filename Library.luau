local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Colors = {
	Background = Color3.fromRGB(15, 17, 23),
	Sidebar = Color3.fromRGB(20, 23, 30),
	Element = Color3.fromRGB(25, 28, 36),
	Accent = Color3.fromRGB(0, 102, 255),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(150, 155, 165),
	Stroke = Color3.fromRGB(40, 45, 55),
	Danger = Color3.fromRGB(255, 60, 60),
	Success = Color3.fromRGB(60, 200, 100)
}

local Fonts = {
	Bold = Enum.Font.GothamBold,
	Medium = Enum.Font.GothamMedium,
	Regular = Enum.Font.Gotham
}

local TweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Library = {}
Library.__index = Library
Library.Toggles = {}
Library.Options = {}
Library.KeybindsShown = false
Library.NotifySide = "Right"
Library.Notifications = {}

local keybindRegistry = {}
local keybindOverlay = nil

local SaveManager = {}

local function EnsureFolder()
	if makefolder then
		local folder = Library.FolderName
		if folder then
			pcall(function()
				if not isfolder(folder) then makefolder(folder) end
				if not isfolder(folder .. "/Configs") then makefolder(folder .. "/Configs") end
			end)
		end
	end
end

function SaveManager.List()
	EnsureFolder()
	local list = {}
	if listfiles then
		local ok, files = pcall(function() return listfiles(Library.FolderName .. "/Configs") end)
		if ok and files then
			for _, file in ipairs(files) do
				local name = file:match("([^/\\]+)%.json$")
				if name then table.insert(list, name) end
			end
		end
	end
	return list
end

function SaveManager.Save(name)
	if not writefile then return false end
	EnsureFolder()
	local data = { Toggles = {}, Options = {} }
	for k, v in pairs(Library.Toggles) do data.Toggles[k] = v.Value end
	for k, v in pairs(Library.Options) do data.Options[k] = v.Value end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false end
	return pcall(function() writefile(Library.FolderName .. "/Configs/" .. name .. ".json", encoded) end)
end

function SaveManager.Load(name)
	if not readfile or not isfile then return false end
	local path = Library.FolderName .. "/Configs/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or not data then return false end
	if data.Toggles then
		for k, v in pairs(data.Toggles) do
			if Library.Toggles[k] and Library.Toggles[k].Set then Library.Toggles[k].Set(v) end
		end
	end
	if data.Options then
		for k, v in pairs(data.Options) do
			if Library.Options[k] and Library.Options[k].Set then Library.Options[k].Set(v) end
		end
	end
	return true
end

function SaveManager.Delete(name)
	if not delfile then return false end
	local path = Library.FolderName .. "/Configs/" .. name .. ".json"
	if isfile and isfile(path) then
		return pcall(function() delfile(path) end)
	end
	return false
end

Library.SaveManager = SaveManager

local function GenerateRandomString(length)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = table.create(length)
	for i = 1, length do
		local rand = math.random(1, #chars)
		result[i] = string.sub(chars, rand, rand)
	end
	return table.concat(result)
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

local function Create(className, properties, children)
	local instance = Instance.new(className)
	if properties then
		for property, value in pairs(properties) do
			instance[property] = value
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

local function Tween(instance, properties)
	TweenService:Create(instance, TweenInfoFast, properties):Play()
end

local function GetKeyName(keyCode)
	local name = keyCode.Name
	if name:sub(1, 6) == "Keypad" then return name:sub(7) end
	if name:sub(1, 3) == "Key" then return name:sub(4) end
	if name:sub(1, 6) == "Button" then return name:sub(7) end
	return name
end

local function RefreshKeybindOverlay()
	if not keybindOverlay then return end
	for _, child in ipairs(keybindOverlay:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for name, entry in pairs(keybindRegistry) do
		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = (entry.Toggle and entry.Toggle.Value or entry.Active) and Colors.Accent or Colors.Background,
			Text = "",
			AutoButtonColor = false,
			Parent = keybindOverlay
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })
		Create("TextLabel", {
			Text = name,
			Font = Fonts.Medium,
			TextSize = 12,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -50, 1, 0),
			Parent = row
		})
		Create("TextLabel", {
			Text = GetKeyName(entry.KeyCode),
			Font = Fonts.Bold,
			TextSize = 12,
			TextColor3 = Colors.Accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -44, 0, 0),
			Size = UDim2.fromOffset(36, 26),
			Parent = row
		})
		row.MouseButton1Click:Connect(function()
			if entry.Callback then
				entry.Callback()
			elseif entry.Toggle then
				entry.Toggle.Value = not entry.Toggle.Value
			end
			if not entry.Toggle then entry.Active = not entry.Active end
			RefreshKeybindOverlay()
		end)
	end
end

local function RegisterKeybind(name, keyCode, callback, toggle)
	local linkedToggle = type(toggle) == "table" and toggle or (type(toggle) == "string" and Library.Toggles[toggle] or Library.Toggles[name])
	keybindRegistry[name] = { Name = name, KeyCode = keyCode, Callback = callback, Toggle = linkedToggle, Active = false }
	if keybindOverlay then RefreshKeybindOverlay() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	for _, entry in pairs(keybindRegistry) do
		if entry.KeyCode == input.KeyCode then
			if entry.Callback then
				entry.Callback()
			elseif entry.Toggle then
				entry.Toggle.Value = not entry.Toggle.Value
			end
			if not entry.Toggle then entry.Active = not entry.Active end
			RefreshKeybindOverlay()
		end
	end
end)

local function CreateKeybindOverlay(screenGui)
	local overlay = Create("Frame", {
		Name = "KeybindOverlay",
		Size = UDim2.fromOffset(200, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		Visible = Library.KeybindsShown,
		Parent = screenGui
	})
	keybindOverlay = overlay
	Create("UIScale", { Parent = overlay })
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = overlay })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = overlay })
	Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = overlay
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = overlay
	})
	Create("TextLabel", {
		Text = "Keybinds",
		Font = Fonts.Bold,
		TextSize = 12,
		TextColor3 = Colors.SubText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = -1,
		Parent = overlay
	})
	
	local dragging, dragInput, dragStart, startPos
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = overlay.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	overlay.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			overlay.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local SearchableItems = {}
local function MarkSearchable(instance)
	instance:SetAttribute("LibrarySearchItem", true)
	table.insert(SearchableItems, instance)
	return instance
end

local function MatchesSearch(instance, query)
	if query == "" then return true end
	if string.find(string.lower(instance.Name), query, 1, true) then return true end
	local extra = instance:GetAttribute("LibrarySearchExtra")
	if type(extra) == "string" and string.find(string.lower(extra), query, 1, true) then return true end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			if string.find(string.lower(descendant.Text), query, 1, true) then return true end
		end
	end
	return false
end

local function CreateElementFactory(parentContainer, screenGui, main)
	local api = {}

	function api:AddToggle(name, callback, default, tooltip)
		local value = default or false
		if type(tooltip) == "table" then tooltip = tooltip.Tooltip end
		local toggleObject = { _Value = value }
		setmetatable(toggleObject, {
			__index = function(object, key)
				if key == "Value" then return rawget(object, "_Value") end
			end,
			__newindex = function(object, key, newValue)
				if key == "Value" then
					object.Set(newValue)
				else
					rawset(object, key, newValue)
				end
			end
		})
		Library.Toggles[name] = toggleObject
		local bg = MarkSearchable(Create("Frame", {
			Size = UDim2.new(1, 0, 0, tooltip and 0 or 35),
			AutomaticSize = tooltip and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			BackgroundColor3 = Colors.Element,
			ClipsDescendants = true,
			Parent = parentContainer
		}))
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("TextLabel", {
			Text = name,
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -60, 0, 35),
			Parent = bg
		})
		if tooltip and tooltip ~= "" then
			Create("TextLabel", {
				Text = tostring(tooltip),
				Font = Fonts.Regular,
				TextSize = 12,
				TextColor3 = Colors.SubText,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 35),
				Size = UDim2.new(1, -20, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = bg
			})
		end
		local switchBg = Create("Frame", {
			Size = UDim2.fromOffset(36, 20),
			Position = UDim2.new(1, -46, 0, 7),
			BackgroundColor3 = value and Colors.Accent or Colors.Stroke,
			Parent = bg
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchBg })
		local dot = Create("Frame", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(value and 18 or 2, 2),
			BackgroundColor3 = Colors.Text,
			Parent = switchBg
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = bg
		})
		local function setValue(v)
			toggleObject._Value = not not v
			Tween(switchBg, { BackgroundColor3 = v and Colors.Accent or Colors.Stroke })
			Tween(dot, { Position = UDim2.fromOffset(v and 18 or 2, 2) })
			if callback then callback(v) end
			RefreshKeybindOverlay()
		end
		toggleObject.Set = setValue
		btn.MouseButton1Click:Connect(function() toggleObject.Value = not toggleObject.Value end)
		return toggleObject
	end

	function api:AddSlider(name, callback, min, max, default)
		min = min or 0
		max = max or 100
		if max <= min then max = min + 1 end
		default = default or min
		Library.Options[name] = { Value = default }
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 45),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer
		})
		if not bg:GetAttribute("LibrarySearchItem") then MarkSearchable(bg) end
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local label = Create("TextLabel", {
			Text = name .. ": " .. tostring(default),
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 5),
			Size = UDim2.new(1, -20, 0, 20),
			Parent = bg
		})
		
		local hitbox = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 1, -30),
			BackgroundTransparency = 1,
			Parent = bg
		})
		
		local visualBar = Create("Frame", {
			Size = UDim2.new(1, -20, 0, 4),
			Position = UDim2.new(0, 10, 0.5, -2),
			BackgroundColor3 = Colors.Stroke,
			Parent = hitbox
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = visualBar })
		local fill = Create("Frame", {
			Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = Colors.Accent,
			Parent = visualBar
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
		
		local dragging = false
		local function update(input)
			local barPos = visualBar.AbsolutePosition.X
			local barSize = visualBar.AbsoluteSize.X
			local relative = math.clamp((input.Position.X - barPos) / barSize, 0, 1)
			local v = math.floor(min + (max - min) * relative + 0.5)
			Library.Options[name].Value = v
			label.Text = name .. ": " .. tostring(v)
			fill.Size = UDim2.new(relative, 0, 1, 0)
			if callback then callback(v) end
		end
		
		hitbox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input)
			end
		end)
		hitbox.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end)
		
		Library.Options[name].Set = function(v)
			v = math.clamp(v, min, max)
			Library.Options[name].Value = v
			label.Text = name .. ": " .. tostring(v)
			fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
			if callback then callback(v) end
		end
		return Library.Options[name]
	end

	function api:AddButton(name, callback)
		local btn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Text = "",
			Parent = parentContainer
		})
		MarkSearchable(btn)
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
		Create("TextLabel", {
			Text = name,
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = btn
		})
		btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Colors.Accent }) end)
		btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Colors.Element }) end)
		btn.MouseButton1Click:Connect(function() if callback then callback() end end)
	end

	function api:AddKeybind(name, keyCode, callback, toggle)
		RegisterKeybind(name, keyCode, callback, toggle)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer
		})
		if not bg:GetAttribute("LibrarySearchItem") then MarkSearchable(bg) end
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("TextLabel", {
			Text = name,
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -60, 1, 0),
			Parent = bg
		})
		local keyBtn = Create("TextButton", {
			Text = GetKeyName(keyCode),
			Font = Fonts.Bold,
			TextSize = 13,
			TextColor3 = Colors.Accent,
			BackgroundColor3 = Colors.Background,
			Position = UDim2.new(1, -50, 0.5, -12),
			Size = UDim2.fromOffset(40, 24),
			Parent = bg
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keyBtn })
		keyBtn.MouseButton1Click:Connect(function()
			local entry = keybindRegistry[name]
			if entry and entry.Callback then entry.Callback() end
			RefreshKeybindOverlay()
		end)
	end

	function api:AddLabel(text)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parentContainer
		})
		MarkSearchable(bg)
		return Create("TextLabel", {
			Text = text,
			Font = Fonts.Regular,
			TextSize = 13,
			TextColor3 = Colors.SubText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = bg
		})
	end

	function api:AddImage(image, height)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, height or 120),
			BackgroundColor3 = Colors.Element,
			ClipsDescendants = true,
			Parent = parentContainer
		})
		if not bg:GetAttribute("LibrarySearchItem") then MarkSearchable(bg) end
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		Create("ImageLabel", {
			Image = image,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			Parent = bg
		})
	end

	function api:AddTextBox(name, callback, default)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer
		})
		if not bg:GetAttribute("LibrarySearchItem") then MarkSearchable(bg) end
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local box = Create("TextBox", {
			Text = default or "",
			PlaceholderText = name,
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			PlaceholderColor3 = Colors.SubText,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = bg
		})
		box.FocusLost:Connect(function()
			if callback then callback(box.Text) end
		end)
		return box
	end

	function api:AddDropdown(name, options, callback, default)
		local currentOptions = options or {}
		local function normalize(Option)
			if typeof(Option) == "table" then
				local Text = tostring(Option.Text or Option.Name or Option.Value or "")
				return { Text = Text, Value = Option.Value ~= nil and Option.Value or Text, Image = Option.Image or Option.Icon }
			end
			local Text = tostring(Option)
			return { Text = Text, Value = Option, Image = nil }
		end
		local function findOption(Value)
			for _, Option in ipairs(currentOptions) do
				local Normalized = normalize(Option)
				if Normalized.Value == Value then return Normalized end
			end
		end
		local selected = default
		if selected == nil and currentOptions[1] ~= nil then selected = normalize(currentOptions[1]).Value end
		selected = selected or ""
		local SelectedOption = findOption(selected)
		Library.Options[name] = { Value = selected }

		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer,
			ZIndex = 2
		})
		local function updateSearchText()
			local SearchValues = {}
			for _, Option in ipairs(currentOptions) do
				table.insert(SearchValues, normalize(Option).Text)
			end
			bg:SetAttribute("LibrarySearchExtra", table.concat(SearchValues, " "))
		end
		updateSearchText()
		if not bg:GetAttribute("LibrarySearchItem") then MarkSearchable(bg) end
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = bg
		})
		local displayLabel = Create("TextLabel", {
			Text = name .. ": " .. (SelectedOption and SelectedOption.Text or tostring(selected)),
			Font = Fonts.Medium,
			TextSize = 14,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -30, 1, 0),
			Parent = bg
		})
		local arrow = Create("TextLabel", {
			Text = "v",
			Font = Fonts.Bold,
			TextSize = 12,
			TextColor3 = Colors.SubText,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -20, 0, 0),
			Size = UDim2.fromOffset(20, 35),
			Parent = bg
		})
		local listBg = Create("ScrollingFrame", {
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0,
			Visible = false,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Colors.Accent,
			Parent = screenGui,
			ZIndex = 100
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listBg })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = listBg })
		local listLayout = Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listBg })
		Create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = listBg })

		local function positionList()
			local Camera = workspace.CurrentCamera
			if not Camera then return end
			local Viewport = Camera.ViewportSize
			local AbsolutePosition = bg.AbsolutePosition
			local AbsoluteSize = bg.AbsoluteSize
			local DesiredHeight = math.min(#currentOptions * 45 + 13, 240)
			local BelowSpace = Viewport.Y - (AbsolutePosition.Y + AbsoluteSize.Y + 6)
			local AboveSpace = AbsolutePosition.Y - 6
			local OpenBelow = BelowSpace >= math.min(DesiredHeight, 90) or BelowSpace >= AboveSpace
			local AvailableHeight = math.max(80, OpenBelow and BelowSpace or AboveSpace)
			local ListHeight = math.min(DesiredHeight, AvailableHeight)
			local ListWidth = math.min(AbsoluteSize.X, Viewport.X - 16)
			local ListX = math.clamp(AbsolutePosition.X, 8, math.max(8, Viewport.X - ListWidth - 8))
			local ListY = OpenBelow and (AbsolutePosition.Y + AbsoluteSize.Y + 5) or (AbsolutePosition.Y - ListHeight - 5)
			listBg.Position = UDim2.fromOffset(ListX, math.clamp(ListY, 4, math.max(4, Viewport.Y - ListHeight - 4)))
			listBg.Size = UDim2.fromOffset(ListWidth, ListHeight)
		end

		local function populate(Options)
			for _, Child in ipairs(listBg:GetChildren()) do
				if Child:IsA("TextButton") then Child:Destroy() end
			end
			for Index, RawOption in ipairs(Options) do
				local Option = normalize(RawOption)
				local OptionButton = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundColor3 = Colors.Element,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = Index,
					Parent = listBg,
					ZIndex = 101
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptionButton })
				local TextOffset = 10
				if Option.Image and Option.Image ~= "" then
					Create("ImageLabel", {
						Image = Option.Image,
						Size = UDim2.fromOffset(32, 32),
						Position = UDim2.fromOffset(5, 5),
						BackgroundTransparency = 1,
						ScaleType = Enum.ScaleType.Crop,
						ZIndex = 102,
						Parent = OptionButton
					})
					TextOffset = 44
				end
				Create("TextLabel", {
					Text = Option.Text,
					Font = Fonts.Medium,
					TextSize = 13,
					TextColor3 = Colors.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(TextOffset, 0),
					Size = UDim2.new(1, -TextOffset - 8, 1, 0),
					ZIndex = 102,
					Parent = OptionButton
				})
				OptionButton.Activated:Connect(function()
					selected = Option.Value
					Library.Options[name].Value = selected
					displayLabel.Text = name .. ": " .. Option.Text
					listBg.Visible = false
					Tween(arrow, { Rotation = 0 })
					if callback then callback(selected) end
				end)
				OptionButton.MouseEnter:Connect(function() Tween(OptionButton, { BackgroundColor3 = Colors.Accent }) end)
				OptionButton.MouseLeave:Connect(function() Tween(OptionButton, { BackgroundColor3 = Colors.Element }) end)
			end
			listBg.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
			if listBg.Visible then positionList() end
		end

		populate(currentOptions)
		btn.Activated:Connect(function()
			if listBg.Visible then
				listBg.Visible = false
				Tween(arrow, { Rotation = 0 })
				return
			end
			for _, Child in ipairs(screenGui:GetChildren()) do
				if Child:IsA("ScrollingFrame") and Child.ZIndex == 100 then Child.Visible = false end
			end
			positionList()
			listBg.Visible = true
			Tween(arrow, { Rotation = 180 })
		end)

		Library.Options[name].Set = function(Value)
			selected = Value
			Library.Options[name].Value = Value
			local Option = findOption(Value)
			displayLabel.Text = name .. ": " .. (Option and Option.Text or tostring(Value))
		end
		Library.Options[name].Refresh = function(NewOptions)
			currentOptions = NewOptions or {}
			updateSearchText()
			populate(currentOptions)
			if not findOption(selected) then
				selected = currentOptions[1] and normalize(currentOptions[1]).Value or ""
				Library.Options[name].Value = selected
				local Option = findOption(selected)
				displayLabel.Text = name .. ": " .. (Option and Option.Text or tostring(selected))
			end
		end
		return Library.Options[name]
	end

	return api
end

function Library.new(windowInfo)
	local self = setmetatable({}, Library)
	
	Library.FolderName = windowInfo.FolderName or windowInfo.Title or "UILibrary"
	Library.FolderName = Library.FolderName:gsub("%s+", "")
	
	local screenGui = Create("ScreenGui", {
		Name = GenerateRandomString(10),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = GetUIParent()
	})
	self.ScreenGui = screenGui
	Library.ScreenGui = screenGui

	CreateKeybindOverlay(screenGui)
	
	local main = Create("Frame", {
		Name = GenerateRandomString(8),
		Size = UDim2.fromOffset(650, 450),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		Parent = screenGui
	})
	self.Main = main
	Library.Main = main
	
	Create("UIScale", { Parent = main })
	Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = main })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = main })
	
	local topBar = Create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = main
	})
	
	if windowInfo.Icon and windowInfo.Icon ~= "" then
		Create("ImageLabel", {
			Image = windowInfo.Icon,
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.fromOffset(20, 8),
			BackgroundTransparency = 1,
			Parent = topBar
		})
	end
	
	Create("TextLabel", {
		Text = windowInfo.Title or "Example Hub",
		Font = Fonts.Bold,
		TextSize = 16,
		TextColor3 = Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset((windowInfo.Icon and windowInfo.Icon ~= "") and 52 or 20, 0),
		Size = UDim2.new(1, -160, 1, 0),
		Parent = topBar
	})
	
	local keybindBtn = Create("TextButton", {
		Text = "K",
		Font = Fonts.Bold,
		TextSize = 13,
		TextColor3 = Colors.SubText,
		BackgroundColor3 = Colors.Element,
		Position = UDim2.new(1, -120, 0, 8),
		Size = UDim2.fromOffset(28, 28),
		Parent = topBar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = keybindBtn })
	local lockBtn = Create("TextButton", {
		Text = "U",
		Font = Fonts.Bold,
		TextSize = 13,
		TextColor3 = Colors.SubText,
		BackgroundColor3 = Colors.Element,
		Position = UDim2.new(1, -85, 0, 8),
		Size = UDim2.fromOffset(28, 28),
		Parent = topBar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = lockBtn })
	local closeBtn = Create("TextButton", {
		Text = "×",
		Font = Fonts.Bold,
		TextSize = 20,
		TextColor3 = Colors.SubText,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.fromOffset(40, 40),
		Parent = topBar
	})
	
	local toggleBtn = nil
	if isMobile then
		toggleBtn = Create("TextButton", {
			Name = "ToggleUI",
			Text = "Toggle UI",
			Font = Fonts.Bold,
			TextSize = 13,
			TextColor3 = Colors.Text,
			BackgroundColor3 = Colors.Background,
			Position = UDim2.fromOffset(20, 60),
			Size = UDim2.fromOffset(100, 30),
			Visible = false,
			Parent = screenGui
		})
		Create("UIScale", { Parent = toggleBtn })
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = toggleBtn })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = toggleBtn })
	end
	
	local locked = false
	local function updateKeybindBtn()
		if keybindOverlay then keybindOverlay.Visible = Library.KeybindsShown end
		Tween(keybindBtn, { TextColor3 = Library.KeybindsShown and Colors.Text or Colors.SubText })
		Tween(keybindBtn, { BackgroundColor3 = Library.KeybindsShown and Colors.Accent or Colors.Element })
	end
	local function setKeybindsShown(value)
		Library.KeybindsShown = value
		updateKeybindBtn()
	end
	Library.SetKeybindsShown = setKeybindsShown
	keybindBtn.MouseButton1Click:Connect(function() setKeybindsShown(not Library.KeybindsShown) end)
	lockBtn.MouseButton1Click:Connect(function()
		locked = not locked
		lockBtn.Text = locked and "L" or "U"
		Tween(lockBtn, { TextColor3 = locked and Colors.Text or Colors.SubText })
		Tween(lockBtn, { BackgroundColor3 = locked and Colors.Danger or Colors.Element })
	end)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { TextColor3 = Colors.Danger }) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { TextColor3 = Colors.SubText }) end)
	local uiVisible = true
	local visibilityTween
	local function setUIVisible(value)
		if uiVisible == value then return end
		uiVisible = value
		if visibilityTween then visibilityTween:Cancel() end
		if value then
			main.Visible = true
			main.Size = UDim2.fromOffset(610, 420)
			visibilityTween = TweenService:Create(main, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(650, 450) })
			visibilityTween:Play()
			if toggleBtn then toggleBtn.Visible = false end
		else
			visibilityTween = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(610, 420) })
			visibilityTween:Play()
			visibilityTween.Completed:Once(function()
				if not uiVisible then main.Visible = false end
			end)
			if toggleBtn then toggleBtn.Visible = true end
		end
	end
	closeBtn.MouseButton1Click:Connect(function() setUIVisible(false) end)
	if toggleBtn then toggleBtn.MouseButton1Click:Connect(function() setUIVisible(true) end) end
	self.SetVisible = setUIVisible
	
	local footerOffset = windowInfo.Footer and -65 or -40
	
	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, footerOffset),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Colors.Sidebar,
		BorderSizePixel = 0,
		Parent = main
	})
	local tabContainer = Create("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(1, -150, 1, footerOffset - 38),
		Position = UDim2.fromOffset(150, 78),
		BackgroundTransparency = 1,
		Parent = main
	})

	local searchBox = Create("TextBox", {
		Name = "LibrarySearch",
		PlaceholderText = "Search tabs, toggles, buttons, dropdowns...",
		Text = "",
		Font = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Colors.Text,
		PlaceholderColor3 = Colors.SubText,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Colors.Element,
		Position = UDim2.fromOffset(165, 45),
		Size = UDim2.new(1, -180, 0, 26),
		Parent = main
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBox })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = searchBox })
	Create("UIPadding", { PaddingLeft = UDim.new(0, 9), Parent = searchBox })
	self.SearchBox = searchBox

	local profile = Create("Frame", {
		Name = "LocalPlayerProfile",
		Size = UDim2.new(1, -16, 0, 94),
		Position = UDim2.new(0, 8, 1, -102),
		BackgroundColor3 = Colors.Element,
		BorderSizePixel = 0,
		Parent = sidebar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = profile })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = profile })

	local avatarImage = Create("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.fromOffset(8, 7),
		BackgroundColor3 = Colors.Stroke,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop,
		Parent = profile
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatarImage })

	local thumbnailSuccess, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if thumbnailSuccess and type(thumbnail) == "string" and thumbnail ~= "" then
		avatarImage.Image = thumbnail
	end

	local profileUsername = Create("TextLabel", {
		Name = "Username",
		Text = "Username: " .. LocalPlayer.Name .. " [" .. LocalPlayer.DisplayName .. "]",
		Font = Fonts.Medium,
		TextSize = 9,
		TextColor3 = Colors.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(62, 5),
		Size = UDim2.new(1, -68, 0, 43),
		Parent = profile
	})
	Create("TextLabel", {
		Name = "UserId",
		Text = "UserId: " .. LocalPlayer.UserId,
		Font = Fonts.Regular,
		TextSize = 9,
		TextColor3 = Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 53),
		Size = UDim2.new(1, -16, 0, 14),
		Parent = profile
	})
	local gameInfoSuccess, gameInfo = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	local gameName = gameInfoSuccess and gameInfo and gameInfo.Name or "Unknown"

	Create("TextLabel", {
		Name = "Game",
		Text = "Game: " .. gameName,
		Font = Fonts.Regular,
		TextSize = 9,
		TextColor3 = Colors.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 69),
		Size = UDim2.new(1, -16, 0, 21),
		Parent = profile
	})
	
	if windowInfo.Footer then
		local footer = Create("Frame", {
			Name = "Footer",
			Size = UDim2.new(1, 0, 0, 25),
			Position = UDim2.new(0, 0, 1, -25),
			BackgroundTransparency = 1,
			Parent = main
		})
		Create("TextLabel", {
			Text = windowInfo.Footer,
			Font = Fonts.Medium,
			TextSize = 12,
			TextColor3 = Colors.SubText,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = footer
		})
	end
	
	local dragging, dragInput, dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if locked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			for _, child in ipairs(screenGui:GetChildren()) do
				if child:IsA("ScrollingFrame") and child.ZIndex == 100 then
					child.Visible = false
				end
			end
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging and not locked then
			local delta = input.Position - dragStart
			local scale = main:FindFirstChildOfClass("UIScale")
			local s = scale and scale.Scale or 1
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (delta.X / s), startPos.Y.Scale, startPos.Y.Offset + (delta.Y / s))
		end
	end)
	
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = UserInputService:GetMouseLocation()
			for _, child in ipairs(screenGui:GetChildren()) do
				if child:IsA("ScrollingFrame") and child.ZIndex == 100 and child.Visible then
					local pos = child.AbsolutePosition
					local size = child.AbsoluteSize
					local inList = mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
					if not inList then
						child.Visible = false
					end
				end
			end
		end
	end)
	
	function Library:SetDPI(scale)
		local num
		if type(scale) == "number" then
			num = scale
		elseif type(scale) == "string" then
			local match = scale:match("%d+")
			if match then num = tonumber(match) end
		end
		if num then
			local factor = math.clamp(num / 100, 0.25, 2.0)
			local mainScale = main:FindFirstChildOfClass("UIScale")
			if mainScale then mainScale.Scale = factor end
			
			if toggleBtn then
				local toggleScale = toggleBtn:FindFirstChildOfClass("UIScale")
				if toggleScale then 
					toggleScale.Scale = factor 
					toggleBtn.Position = UDim2.fromOffset(20 / factor, 60 / factor)
				end
			end
			
			if keybindOverlay then
				local kbScale = keybindOverlay:FindFirstChildOfClass("UIScale")
				if kbScale then
					kbScale.Scale = factor
					keybindOverlay.Position = UDim2.new(0, 20 / factor, 0.5, 0)
				end
			end
			if self.NotificationScale then self.NotificationScale.Scale = factor end
		end
	end

	updateKeybindBtn()
	
	if isMobile then
		Library:SetDPI("75%")
	else
		Library:SetDPI("100%")
	end
	
	local notificationHolder = Create("Frame", {
		Name = "Notifications",
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -16, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		ZIndex = 200,
		Parent = screenGui
	})
	local notificationScale = Create("UIScale", { Parent = notificationHolder })
	local notificationLayout = Create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = notificationHolder
	})
	self.NotificationHolder = notificationHolder
	self.NotificationScale = notificationScale
	self.NotificationLayout = notificationLayout

	self.TabContainer = tabContainer
	self.Sidebar = sidebar
	self.CurrentTab = nil
	self.Tabs = {}
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text)
		for _, searchable in ipairs(SearchableItems) do
			if searchable and searchable.Parent and searchable:IsDescendantOf(screenGui) then
				searchable.Visible = MatchesSearch(searchable, query)
			end
		end
		for _, existingTab in ipairs(self.Tabs) do
			local tabMatches = string.find(string.lower(existingTab.Name), query, 1, true) ~= nil
			local contentMatches = false
			for _, searchable in ipairs(SearchableItems) do
				if searchable and searchable.Parent and searchable:IsDescendantOf(existingTab.Container) and MatchesSearch(searchable, query) then
					contentMatches = true
					break
				end
			end
			existingTab.Button.Visible = query == "" or tabMatches or contentMatches
			if query ~= "" and contentMatches and self.CurrentTab ~= existingTab then
				for _, candidate in ipairs(self.Tabs) do
					candidate.Container.Visible = candidate == existingTab
					Tween(candidate.Button, { BackgroundTransparency = candidate == existingTab and 0 or 1 })
					Tween(candidate.Label, { TextColor3 = candidate == existingTab and Colors.Text or Colors.SubText })
				end
				self.CurrentTab = existingTab
			end
		end
	end)

	local ServerTab = self:CreateTab({ Name = "Server", Icon = "🖥️" })
	local ServerInfo = ServerTab:AddGroupbox("Server Information")
	local MarketplaceService = game:GetService("MarketplaceService")
	local GameNameLabel = ServerInfo:AddLabel("Game Name: Loading...")
	ServerInfo:AddLabel("Server JobId: " .. game.JobId)
	ServerInfo:AddLabel("Game Place ID: " .. tostring(game.PlaceId))

	task.spawn(function()
		local Success, ProductInfo = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if GameNameLabel.Parent then
			GameNameLabel.Text = "Game Name: " .. (Success and ProductInfo.Name or "Unknown")
		end
	end)

	local ServerActions = ServerTab:AddGroupbox("Server Actions", "Right")
	ServerActions:AddButton("Serverhop", function()
		task.spawn(function()
			local Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
			local RequestSuccess, Response = pcall(function()
				if game.HttpGet then
					return game:HttpGet(Url)
				end
				return HttpService:GetAsync(Url)
			end)
			if not RequestSuccess then
				warn("Serverhop failed: HTTP request unavailable.")
				return
			end

			local DecodeSuccess, ServerData = pcall(function()
				return HttpService:JSONDecode(Response)
			end)
			if not DecodeSuccess or type(ServerData) ~= "table" or type(ServerData.data) ~= "table" then
				warn("Serverhop failed: invalid server response.")
				return
			end

			local AvailableServers = {}
			for _, Server in ipairs(ServerData.data) do
				if Server.id and Server.id ~= game.JobId and Server.playing < Server.maxPlayers then
					table.insert(AvailableServers, Server.id)
				end
			end
			if #AvailableServers == 0 then
				warn("Serverhop: no available servers found.")
				return
			end

			local TargetServer = AvailableServers[math.random(1, #AvailableServers)]
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, TargetServer, LocalPlayer)
			end)
		end)
	end)
	ServerActions:AddButton("Rejoin", function()
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end)

	return self
end

function Library:CreateTab(tabInfo)
	local tabButton = Create("TextButton", {
		Size = UDim2.new(1, -20, 0, 35),
		Position = UDim2.fromOffset(10, (#self.Tabs * 40) + 10),
		BackgroundColor3 = Colors.Element,
		BackgroundTransparency = 1,
		Text = "",
		Parent = self.Sidebar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabButton })
	local tabIcon = tabInfo.Icon
	local labelOffset = 10
	if type(tabIcon) == "string" and tabIcon ~= "" then
		if tabIcon:match("^rbxassetid://") or tabIcon:match("^rbxthumb://") or tabIcon:match("^https?://") then
			Create("ImageLabel", {
				Image = tabIcon,
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(0, 9, 0.5, -9),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = tabButton
			})
		else
			Create("TextLabel", {
				Text = tabIcon,
				Font = Fonts.Regular,
				TextSize = 16,
				TextColor3 = Colors.Text,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(22, 35),
				Position = UDim2.fromOffset(7, 0),
				Parent = tabButton
			})
		end
		labelOffset = 34
	end
	local tabLabel = Create("TextLabel", {
		Text = tabInfo.Name,
		Font = Fonts.Medium,
		TextSize = 14,
		TextColor3 = Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(labelOffset, 0),
		Size = UDim2.new(1, -labelOffset, 1, 0),
		Parent = tabButton
	})
	local container = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Colors.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.TabContainer
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = container
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 15),
		PaddingLeft = UDim.new(0, 15),
		PaddingRight = UDim.new(0, 15),
		PaddingBottom = UDim.new(0, 15),
		Parent = container
	})
	local leftCol = Create("Frame", {
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = container
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = leftCol
	})
	local rightCol = Create("Frame", {
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = container
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rightCol
	})
	local tab = { Button = tabButton, Container = container, Label = tabLabel, Name = tabInfo.Name }
	table.insert(self.Tabs, tab)
	local function select()
		if self.CurrentTab == tab then return end
		if self.CurrentTab then
			local previousTab = self.CurrentTab
			Tween(previousTab.Button, { BackgroundTransparency = 1 })
			Tween(previousTab.Label, { TextColor3 = Colors.SubText })
			local fadeOut = TweenService:Create(previousTab.Container, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(8, 0) })
			fadeOut:Play()
			fadeOut.Completed:Once(function()
				if self.CurrentTab ~= previousTab then
					previousTab.Container.Visible = false
					previousTab.Container.Position = UDim2.fromOffset(0, 0)
				end
			end)
		end
		self.CurrentTab = tab
		Tween(tabButton, { BackgroundTransparency = 0, BackgroundColor3 = Colors.Accent })
		Tween(tabLabel, { TextColor3 = Colors.Text })
		container.Visible = true
		container.Position = UDim2.fromOffset(-8, 0)
		Tween(container, { Position = UDim2.fromOffset(0, 0) })
	end
	tabButton.MouseButton1Click:Connect(select)
	if #self.Tabs == 1 then select() end
	local api = CreateElementFactory(leftCol, self.ScreenGui, self.Main)
	function api:AddGroupbox(name, side)
		local column = (side == "Right") and rightCol or leftCol
		local gb = MarkSearchable(Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Colors.Element,
			Parent = column
		}))
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = gb })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = gb })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = gb
		})
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = gb
		})
		Create("TextLabel", {
			Text = name,
			Font = Fonts.Bold,
			TextSize = 13,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = -1,
			Parent = gb
		})
		local content = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = gb
		})
		Create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content
		})
		return CreateElementFactory(content, self.ScreenGui, self.Main)
	end
	return api
end

function Library:Notify(title, description, duration)
	if not self.NotificationHolder or not self.NotificationHolder.Parent then return end
	duration = type(duration) == "number" and math.max(duration, 0.1) or 5

	local holder = self.NotificationHolder
	local side = self.NotifySide == "Left" and "Left" or "Right"
	holder.AnchorPoint = Vector2.new(side == "Right" and 1 or 0, 0)
	holder.Position = UDim2.new(side == "Right" and 1 or 0, side == "Right" and -16 or 16, 0, 16)
	self.NotificationLayout.HorizontalAlignment = side == "Right" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left

	local notification = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Colors.Background,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 201,
		Parent = holder
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notification })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = notification })

	local content = Create("Frame", {
		Size = UDim2.new(1, 0, 1, -4),
		Position = UDim2.fromOffset(0, -10),
		BackgroundTransparency = 1,
		ZIndex = 202,
		Parent = notification
	})
	Create("TextLabel", {
		Text = tostring(title or "Notification"),
		Font = Fonts.Bold,
		TextSize = 14,
		TextColor3 = Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 9),
		Size = UDim2.new(1, -24, 0, 20),
		ZIndex = 203,
		Parent = content
	})
	Create("TextLabel", {
		Text = tostring(description or ""),
		Font = Fonts.Regular,
		TextSize = 12,
		TextColor3 = Colors.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 30),
		ZIndex = 203,
		Parent = content
	})

	local progress = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, -3),
		BackgroundColor3 = Colors.Accent,
		BorderSizePixel = 0,
		ZIndex = 204,
		Parent = notification
	})
	local clickArea = Create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 205,
		Parent = notification
	})

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		local exitTween = TweenService:Create(notification, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		})
		TweenService:Create(content, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromOffset(0, -18)
		}):Play()
		exitTween:Play()
		exitTween.Completed:Once(function()
			notification:Destroy()
			for index, activeNotification in ipairs(self.Notifications) do
				if activeNotification == notification then
					table.remove(self.Notifications, index)
					break
				end
			end
		end)
	end

	table.insert(self.Notifications, notification)
	clickArea.MouseButton1Click:Connect(dismiss)
	Tween(notification, { Size = UDim2.new(1, 0, 0, 76) })
	Tween(content, { Position = UDim2.fromOffset(0, 0) })
	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 3)
	}):Play()
	task.delay(duration, dismiss)
	return notification
end

function Library:ChangeLabelText(label, newText)
	if typeof(label) == "Instance" and label:IsA("TextLabel") then
		label.Text = newText
	end
end

function Library:Destroy()
	for _, notification in ipairs(self.Notifications or {}) do
		if notification and notification.Parent then notification:Destroy() end
	end
	table.clear(self.Notifications or {})
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

return Library