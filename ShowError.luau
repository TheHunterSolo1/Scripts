local genv = (getgenv and getgenv()) or _G or shared

genv.ShowError = function(SRC, ...)
	if not SRC then return end

	local sourceCode = type(SRC) == "string" and SRC or nil
	local Compiled, CompileError

	if sourceCode then
		Compiled, CompileError = loadstring(sourceCode)
	else
		Compiled = SRC
	end

	if not Compiled then
		warn("--------------------------------------------------\n[Compile Error]: " .. tostring(CompileError) .. "\n--------------------------------------------------")
		return nil
	end

	local args = {...}
	local result
	local Success, RuntimeError = xpcall(function()
		result = Compiled(unpack(args))
		return result
	end, function(Error)
		if debug and debug.traceback then
			local ok, trace = pcall(debug.traceback, tostring(Error), 2)
			if ok then return trace end
		end
		return tostring(Error)
	end)

	if not Success then
		warn("--------------------------------------------------\n[Runtime Error]:\n" .. tostring(RuntimeError) .. "\n--------------------------------------------------")
		return nil
	end

	return result
end

return genv.ShowError
