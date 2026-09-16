local ScriptContext = game:GetService("ScriptContext")

local genv = (getgenv and getgenv()) or _G or shared
local hooked = false
local seen = {}

local function report(msg, trace, inst)
	local source = inst and inst:GetFullName() or "Loadstring"
	local line = msg:match(":(%d+):") or (trace and type(trace) == "string" and trace:match(":(%d+):")) or "?"

	local key = source .. ":" .. line .. ":" .. tostring(msg)
	if seen[key] then return end
	seen[key] = true

	warn("\n--------------------------------------------------\n[ERROR FOUND] Line: " .. line .. " | Script: " .. source .. "\n-> Details: " .. tostring(msg) .. "\n--------------------------------------------------\n")
end

genv.ShowError = function(src, ...)
	if not hooked then
		hooked = true
		pcall(function()
			ScriptContext.Error:Connect(report)
		end)
	end

	if not src then return false, "no input" end

	local func = src
	if type(src) == "string" then
		local compiled, err = loadstring(src)
		if not compiled then
			report(err or "Compile failed", "", nil)
			return false, err
		end
		func = compiled
	end

	if type(func) ~= "function" then
		report("Invalid input type: " .. type(src), "", nil)
		return false, "invalid input"
	end

	local trace = ""
	local ok, res = xpcall(func, function(e)
		if debug and debug.traceback then
			local tOk, tRes = pcall(debug.traceback, "", 2)
			trace = tOk and tRes or ""
		end
		return e
	end, ...)

	if not ok then
		report(res, trace, nil)
		return false, res
	end

	return true, res
end

return true
