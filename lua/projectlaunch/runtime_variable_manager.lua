local RuntimeVarManager = {}
local varLimit = 5
local varPrefix = "$"

local function createArgSuffix(vars)
	return " (" .. table.concat(vars, ",") .. ")"
end

function RuntimeVarManager.prompt(command)
	local vars = {}
	for i = 1, varLimit, 1 do
		local substitutionString = varPrefix .. i

		if string.find(command.cmd, substitutionString) then
			vim.ui.input(
				{ prompt = "ProjectLaunch: Enter argument " .. substitutionString .. " for\n" .. command.cmd .. "\n:" },
				function(input)
					vars[i] = input
				end
			)
		end
	end

	return vars
end

function RuntimeVarManager.generateJobName(command, vars)
	if vim.tbl_count(vars) > 0 then
		return command.name .. createArgSuffix(vars)
	end

	return command.name
end

function RuntimeVarManager.interpolate(originalCommand, vars)
	local finalCommand = originalCommand.cmd

	for i = 1, varLimit, 1 do
		local substitutionString = varPrefix .. i

		if string.find(originalCommand.cmd, substitutionString) then
			finalCommand = string.gsub(finalCommand, substitutionString, vars[i])
		end
	end

	return finalCommand
end

return RuntimeVarManager
