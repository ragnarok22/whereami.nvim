local M = {}

local health = vim.health or {}

local function start(name)
	if health.start then
		health.start(name)
	elseif health.report_start then
		health.report_start(name)
	end
end

local function ok(message)
	if health.ok then
		health.ok(message)
	else
		health.report_ok(message)
	end
end

local function error(message)
	if health.error then
		health.error(message)
	else
		health.report_error(message)
	end
end

function M.check()
	start("whereami.nvim")

	local has_curl = pcall(require, "plenary.curl")
	if has_curl then
		ok("plenary.curl is available")
	else
		error("plenary.curl is not available. Install nvim-lua/plenary.nvim.")
	end

	if vim.json and vim.json.decode then
		local decoded_ok, decoded = pcall(vim.json.decode, "{\"whereami\":true}")
		if decoded_ok and decoded and decoded.whereami == true then
			ok("JSON decoding works")
		else
			error("vim.json.decode is available, but could not decode a simple JSON object")
		end
	else
		error("vim.json.decode is not available. whereami.nvim requires Neovim with vim.json support.")
	end

	local notify_type = type(vim.notify)
	local notify_metatable = notify_type == "table" and getmetatable(vim.notify)
	if notify_type == "function" then
		ok("vim.notify is available as a function")
	elseif type(notify_metatable) == "table" and type(notify_metatable.__call) == "function" then
		ok("vim.notify is available as a callable table")
	else
		error("vim.notify is not callable")
	end
end

return M
