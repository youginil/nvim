local api = vim.api
local fn = vim.fn

local M = {}

local function prettier_exe(s)
	return string.format('prettier --stdin-filepath "%s"', s)
end

local formatters = {
	["html"] = { { cmd = "prettier", exe = prettier_exe } },
	["css"] = { { cmd = "prettier", exe = prettier_exe } },
	["scss"] = { { cmd = "prettier", exe = prettier_exe } },
	["sass"] = { { cmd = "prettier", exe = prettier_exe } },
	["less"] = { { cmd = "prettier", exe = prettier_exe } },
	["javascript"] = { { cmd = "prettier", exe = prettier_exe } },
	["typescript"] = { { cmd = "prettier", exe = prettier_exe } },
	["json"] = { { cmd = "prettier", exe = prettier_exe } },
	["markdown"] = { { cmd = "prettier", exe = prettier_exe } },
	["vue"] = { { cmd = "prettier", exe = prettier_exe } },
	["yaml"] = { { cmd = "prettier", exe = prettier_exe } },
	["lua"] = {
		{
			cmd = "stylua",
			exe = function(s)
				return string.format('stylua --search-parent-directories --stdin-filepath "%s" -- -', s)
			end,
		},
	},
	["python"] = { {
		cmd = "black",
		exe = function(s)
			return string.format('black -q --stdin-filename "%s" - ', s)
		end,
	} },
}

local job_id = nil

local function execute(cmd)
	if job_id ~= nil then
		print("Previous formatter is working...")
		return
	end
	local curpos = fn.getcurpos()
	local content = table.concat(fn.getline(1, "$"), "\n")
	job_id = fn.jobstart(cmd, {
		on_stdout = function(_, output)
			if #output == 1 and output[1] == "" then
				return
			end
			local lines = fn.getline(1, "$")
			local same = true
			if #lines == #output then
				for i, line in ipairs(lines) do
					if line ~= output[i] then
						same = false
						break
					end
				end
			else
				same = false
			end
			if not same then
				api.nvim_buf_set_lines(0, 0, -1, true, output)
				local ln = fn.line("$")
				local row = ln < curpos[1] and ln or curpos[1]
				local line = fn.getline(row)
				local col = #line < curpos[2] and #line or curpos[2]
				fn.cursor({ row, col })
			end
			print("Document is formatted")
		end,
		on_stderr = function(_, output)
			local msg = table.concat(output, "\n")
			if #msg > 0 then
				api.nvim_err_writeln(msg)
			end
		end,
		on_exit = function()
			job_id = nil
		end,
		stdout_buffered = true,
		stderr_buffered = true,
	})
	fn.chansend(job_id, content)
	fn.chanclose(job_id, "stdin")
end

function M.format()
	if not vim.bo.buflisted then
		return
	end
	local ft = vim.bo.filetype
	if ft == "" then
		return
	end
	local fmts = formatters[ft]
	if fmts then
		for _, fmt in ipairs(fmts) do
			if fn.executable(fmt.cmd) then
				print("Formatting by " .. fmt.cmd .. "...")
				local s = fn.expand("%:p")
				execute(fmt.exe(s))
				return
			end
		end
	end
	print("Formatted by Language Server")
	vim.lsp.buf.format()
end

return M

