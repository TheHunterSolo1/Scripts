local ScriptContext = game:GetService("ScriptContext")

local genv = (getgenv and getgenv()) or _G or shared
local listening = false
local seen = {}

local function safeTraceback(level)
	if not debug or not debug.traceback then return "" end
	local ok, trace = pcall(debug.traceback, "", level or 2)
	return ok and type(trace) == "string" and trace or ""
end

local function logError(msg, trace, inst)
	local scriptPath = inst and inst:GetFullName() or "Loadstring"
	local line = msg:match(":(%d+):") or (trace and type(trace) == "string" and trace:match(":(%d+):")) or "?"
	
	local key = scriptPath .. ":" .. line .. ":" .. tostring(msg)
	if seen[key] then return end
	seen[key] = true

	warn("\n--------------------------------------------------\n[ERROR FOUND] Line: " .. line .. " | Script: " .. scriptPath .. "\n-> Details: " .. tostring(msg) .. "\n--------------------------------------------------\n")
end

genv.ShowError = function(input, ...)
	if not listening then
		listening = true
		pcall(function()
			ScriptContext.Error:Connect(logError)
		end)
	end

	if not input then return false, "no input" end

	local fn = input
	if type(input) == "string" then
		local compiled, parseErr = loadstring(input)
		if not compiled then
			logError(parseErr or "Compile failed", "", nil)
			return false, parseErr
		end
		fn = compiled
	end

	if type(fn) ~= "function" then
		logError("Invalid input type: " .. type(input), "", nil)
		return false, "invalid input"
	end

	local args = {...}
	local errTrace = ""
	
	local ok, res = xpcall(function()
		return fn(unpack(args))
	end, function(e)
		errTrace = safeTraceback(2)
		return e
	end)

	if not ok then
		logError(res, errTrace, nil)
		return false, res
	end

	return true, res
end

return true
