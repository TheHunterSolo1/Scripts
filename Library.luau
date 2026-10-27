local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

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

local keybindRegistry = {}
local keybindOverlay = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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
			BackgroundColor3 = Colors.Element,
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
			if entry.Callback then entry.Callback() end
		end)
	end
end

local function RegisterKeybind(name, keyCode, callback)
	keybindRegistry[name] = { Name = name, KeyCode = keyCode, Callback = callback }
	if keybindOverlay then RefreshKeybindOverlay() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	for _, entry in pairs(keybindRegistry) do
		if entry.KeyCode == input.KeyCode and entry.Callback then
			entry.Callback()
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

local function CreateElementFactory(parentContainer, screenGui, main)
	local api = {}

	function api:AddToggle(name, callback, default)
		local value = default or false
		Library.Toggles[name] = { Value = value }
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer
		})
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
		local switchBg = Create("Frame", {
			Size = UDim2.fromOffset(36, 20),
			Position = UDim2.new(1, -46, 0.5, -10),
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
			Library.Toggles[name].Value = v
			Tween(switchBg, { BackgroundColor3 = v and Colors.Accent or Colors.Stroke })
			Tween(dot, { Position = UDim2.fromOffset(v and 18 or 2, 2) })
			if callback then callback(v) end
		end
		Library.Toggles[name].Set = setValue
		btn.MouseButton1Click:Connect(function() setValue(not Library.Toggles[name].Value) end)
		return Library.Toggles[name]
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

	function api:AddKeybind(name, keyCode, callback)
		RegisterKeybind(name, keyCode, callback)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer
		})
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
			if entry.Callback then entry.Callback() end
		end)
	end

	function api:AddLabel(text)
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Parent = parentContainer
		})
		Create("TextLabel", {
			Text = text,
			Font = Fonts.Regular,
			TextSize = 13,
			TextColor3 = Colors.SubText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
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
		local selected = default or options[1] or ""
		Library.Options[name] = { Value = selected }
		local currentOptions = options
		
		local bg = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 35),
			BackgroundColor3 = Colors.Element,
			Parent = parentContainer,
			ZIndex = 2
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bg })
		local btn = Create("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = bg
		})
		local displayLabel = Create("TextLabel", {
			Text = name .. ": " .. selected,
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
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Colors.Background,
			BorderSizePixel = 0,
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Colors.Accent,
			Parent = screenGui,
			ZIndex = 100
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = listBg })
		Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = listBg })
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listBg })
		Create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = listBg })

		local function populate(opts)
			for _, child in ipairs(listBg:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for i, opt in ipairs(opts) do
				local optBtn = Create("TextButton", {
					Size = UDim2.new(1, 0, 0, 25),
					BackgroundColor3 = Colors.Element,
					Text = opt,
					Font = Fonts.Medium,
					TextSize = 13,
					TextColor3 = Colors.Text,
					LayoutOrder = i,
					Parent = listBg
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })
				optBtn.MouseEnter:Connect(function() Tween(optBtn, { BackgroundColor3 = Colors.Accent }) end)
				optBtn.MouseLeave:Connect(function() Tween(optBtn, { BackgroundColor3 = Colors.Element }) end)
				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					Library.Options[name].Value = opt
					displayLabel.Text = name .. ": " .. opt
					listBg.Visible = false
					Tween(arrow, { Rotation = 0 })
					if callback then callback(opt) end
				end)
			end
			listBg.CanvasSize = UDim2.new(0, 0, 0, listBg.UIListLayout.AbsoluteContentSize.Y + 10)
		end

		populate(currentOptions)

		btn.MouseButton1Click:Connect(function()
			if listBg.Visible then
				listBg.Visible = false
				Tween(arrow, { Rotation = 0 })
			else
				for _, child in ipairs(screenGui:GetChildren()) do
					if child:IsA("ScrollingFrame") and child.ZIndex == 100 then
						child.Visible = false
					end
				end
				
				local absPos = bg.AbsolutePosition
				local absSize = bg.AbsoluteSize
				
				listBg.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 5)
				listBg.Size = UDim2.fromOffset(absSize.X, math.min(#currentOptions * 27 + 10, 150))
				listBg.Visible = true
				Tween(arrow, { Rotation = 180 })
			end
		end)

		Library.Options[name].Set = function(v)
			selected = v
			Library.Options[name].Value = v
			displayLabel.Text = name .. ": " .. v
		end
		
		Library.Options[name].Refresh = function(newOptions)
			currentOptions = newOptions
			populate(currentOptions)
			if #currentOptions > 0 and not table.find(currentOptions, selected) then
				selected = currentOptions[1]
				Library.Options[name].Value = selected
				displayLabel.Text = name .. ": " .. selected
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
	
	local toggleBtn = Create("TextButton", {
		Name = "ToggleUI",
		Text = "Toggle UI",
		Font = Fonts.Bold,
		TextSize = 13,
		TextColor3 = Colors.Text,
		BackgroundColor3 = Colors.Background,
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(100, 30),
		Visible = false,
		Parent = screenGui
	})
	Create("UIScale", { Parent = toggleBtn })
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = toggleBtn })
	Create("UIStroke", { Color = Colors.Stroke, Thickness = 1, Parent = toggleBtn })
	
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
	closeBtn.MouseButton1Click:Connect(function()
		main.Visible = false
		toggleBtn.Visible = true
	end)
	toggleBtn.MouseButton1Click:Connect(function()
		main.Visible = true
		toggleBtn.Visible = false
	end)
	
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
		Size = UDim2.new(1, -150, 1, footerOffset),
		Position = UDim2.fromOffset(150, 40),
		BackgroundTransparency = 1,
		Parent = main
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
			
			local toggleScale = toggleBtn:FindFirstChildOfClass("UIScale")
			if toggleScale then 
				toggleScale.Scale = factor 
				toggleBtn.Position = UDim2.fromOffset(20 / factor, 20 / factor)
			end
			
			if keybindOverlay then
				local kbScale = keybindOverlay:FindFirstChildOfClass("UIScale")
				if kbScale then 
					kbScale.Scale = factor
					keybindOverlay.Position = UDim2.new(0, 20 / factor, 0.5, 0)
				end
			end
		end
	end

	updateKeybindBtn()
	self.TabContainer = tabContainer
	self.Sidebar = sidebar
	self.CurrentTab = nil
	self.Tabs = {}
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
	local tabLabel = Create("TextLabel", {
		Text = tabInfo.Name,
		Font = Fonts.Medium,
		TextSize = 14,
		TextColor3 = Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -10, 1, 0),
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
	local tab = { Button = tabButton, Container = container, Label = tabLabel }
	table.insert(self.Tabs, tab)
	local function select()
		if self.CurrentTab == tab then return end
		if self.CurrentTab then
			Tween(self.CurrentTab.Button, { BackgroundTransparency = 1 })
			Tween(self.CurrentTab.Label, { TextColor3 = Colors.SubText })
			self.CurrentTab.Container.Visible = false
		end
		self.CurrentTab = tab
		Tween(tabButton, { BackgroundTransparency = 0, BackgroundColor3 = Colors.Accent })
		Tween(tabLabel, { TextColor3 = Colors.Text })
		container.Visible = true
	end
	tabButton.MouseButton1Click:Connect(select)
	if #self.Tabs == 1 then select() end
	local api = CreateElementFactory(leftCol, self.ScreenGui, self.Main)
	function api:AddGroupbox(name, side)
		local column = (side == "Right") and rightCol or leftCol
		local gb = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Colors.Element,
			Parent = column
		})
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

function Library:Destroy()
	self.ScreenGui:Destroy()
end

return Library