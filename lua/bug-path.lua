local loop = vim.loop
local fs = vim.fs

local M = {}

M.sep = (function()
	if jit then
		local os = string.lower(jit.os)
		if os ~= "windows" then
			return "/"
		else
			return "\\"
		end
	else
		return package.config:sub(1, 1)
	end
end)()

function M.join(p, ...)
	local result = p
	for _, v in ipairs({ ... }) do
		result = result .. M.sep .. v
	end
    return result
end

return M

