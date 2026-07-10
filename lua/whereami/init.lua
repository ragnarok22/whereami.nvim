local M = {}
local curl = require("plenary.curl")
local flag = require("whereami.flag")

local function get_data()
	local IP_URL = "ipinfo.io"
	local data = vim.json.decode(curl.get(IP_URL).body)
	return data
end


M.country = function()
	local data = get_data()
	local country = data.country or "unknown"
	local icon = flag.get_flag(data.country)

	vim.notify("You are in " .. icon .. country, vim.log.levels.INFO, { title = "Where am I?", icon = icon })
end

M.city = function()
	local data = get_data()
	vim.notify("You are in " .. data.city, vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
end

M.ip = function()
	local data = get_data()
	vim.notify("You IP is " .. data.ip, vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
end

M.isp = function()
	local data = get_data()
	vim.notify("You ISP is " .. data.org, vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
end

M.whereami = function()
	M.country()
end

vim.api.nvim_create_user_command("Whereami", function(opts)
	local option = opts.fargs[1]
	if option == "country" then
		M.country()
	elseif option == "city" then
		M.city()
	elseif option == "ip" then
		M.ip()
	elseif option == "isp" then
		M.isp()
	else
		M.country()
	end
end, {
	nargs = "*",
	complete = function(ArgLead, CmdLine, CursorPos)
		-- return completion candidates as a list-like table
		return { "city", "country", "ip", "isp" }
	end,
	desc = "Location where the current location was originated from.",
})

return M
