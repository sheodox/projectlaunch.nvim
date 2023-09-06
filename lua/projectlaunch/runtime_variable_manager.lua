local RuntimeVarManager = {}
local vars = {}

local function createArgSuffix()
	return " (" .. table.concat(vars, ",") .. ")"
end

local function setRuntimeVarViaPrompt(i, command)
	local substitutionString = "$" .. i
	vim.ui.input(
		{ prompt = "ProjectLaunch: Enter argument " .. substitutionString .. " for\n" .. command .. "\n:" },
		function(input)
			vars[i] = input
		end
	)
end

function RuntimeVarManager.generateJobName(command)
	if vim.tbl_count(vars) > 0 then
		return command.name .. createArgSuffix()
	end

	return command.name
end

function RuntimeVarManager.interpolate(originalCommand)
    vars = {}
	local finalCommand = originalCommand.cmd

	for i = 1, 5, 1 do
		local substitutionString = "$" .. i

		if string.find(originalCommand.cmd, substitutionString) then
			setRuntimeVarViaPrompt(i, finalCommand)
			finalCommand = string.gsub(finalCommand, substitutionString, vars[i])
		end
	end

	return finalCommand
end

return RuntimeVarManager
