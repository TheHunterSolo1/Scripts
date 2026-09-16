local genv = (getgenv and getgenv()) or _G or shared

genv.ShowError = function(input, ...)
	if not input then
		warn("--------------------------------------------------\n[ShowError Error]: No input provided\n--------------------------------------------------")
		return nil, "No input provided"
	end

	local targetFunc = nil
	local args = {...}

	if type(input) == "function" then
		targetFunc = input
	elseif type(input) == "string" then
		local compiled, compileErr = loadstring(input)
		if not compiled then
			warn("--------------------------------------------------\n[Compile Error]:\n" .. tostring(compileErr) .. "\n--------------------------------------------------")
			return nil, compileErr
		end
		targetFunc = compiled
	elseif type(input) == "table" then
		if type(input.SRC) == "string" then
			return genv.ShowError(input.SRC, unpack(args))
		elseif type(input.SRC) == "function" then
			return genv.ShowError(input.SRC, unpack(args))
		elseif type(input[1]) == "string" or type(input[1]) == "function" then
			return genv.ShowError(input[1], unpack(args))
		end
	end

	if type(targetFunc) ~= "function" then
		warn("--------------------------------------------------\n[ShowError Error]: Cannot execute type '" .. type(input) .. "'\n--------------------------------------------------")
		return nil, "Invalid input type"
	end

	local results = {}
	local success, runtimeErr = xpcall(function()
		results = {targetFunc(unpack(args))}
	end, function(err)
		if debug and debug.traceback then
			local ok, trace = pcall(debug.traceback, tostring(err), 2)
			if ok then return trace end
		end
		return tostring(err)
	end)

	if not success then
		warn("--------------------------------------------------\n[Runtime Error]:\n" .. tostring(runtimeErr) .. "\n--------------------------------------------------")
		return nil, runtimeErr
	end

	return unpack(results)
end

return genv.ShowError
