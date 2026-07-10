local M = {}
local curl = require("plenary.curl")

local config = {
	privacy = {
		mask_ip = false,
		hide_city = false,
		hide_isp = false,
	},
}

local function get_data()
	local IP_URL = "ipinfo.io"
	local data = vim.json.decode(curl.get(IP_URL).body)
	return data
end

-- TODO: find a better way to do this. So far utf8.char() is the only way I found but is not available in lua 5.1
local function get_flag(country_iso)
	local flag_icon = ""
	for i = 1, #country_iso do
		local code_point = country_iso:byte(i) + 127397
		if code_point <= 0x7F then
			flag_icon = flag_icon .. string.char(code_point)
		elseif code_point <= 0x7FF then
			flag_icon = flag_icon .. string.char(0xC0 + math.floor(code_point / 0x40), 0x80 + code_point % 0x40)
		elseif code_point <= 0xFFFF then
			flag_icon = flag_icon
				.. string.char(
					0xE0 + math.floor(code_point / 0x1000),
					0x80 + math.floor((code_point % 0x1000) / 0x40),
					0x80 + code_point % 0x40
				)
		elseif code_point <= 0x10FFFF then
			flag_icon = flag_icon
				.. string.char(
					0xF0 + math.floor(code_point / 0x40000),
					0x80 + math.floor((code_point % 0x40000) / 0x1000),
					0x80 + math.floor((code_point % 0x1000) / 0x40),
					0x80 + code_point % 0x40
				)
		end
	end

	-- for i = 1, #country_iso do
	--     local charCode = string.byte(country_iso:sub(i, i)) + 127397
	--     flag_icon = flag_icon .. utf8.char(charCode)
	-- end
	return flag_icon
end

local function mask_ip(ip)
	if not ip or ip == "" then
		return ip
	end

	local masked_ipv4 = ip:gsub("^(%d+)%.(%d+)%.(%d+)%.(%d+)$", "%1.%2.xxx.xxx")
	if masked_ipv4 ~= ip then
		return masked_ipv4
	end

	local first, second = ip:match("^([^:]+):([^:]+):")
	if first and second then
		return first .. ":" .. second .. ":xxxx:xxxx:xxxx:xxxx:xxxx:xxxx"
	end

	return "xxx.xxx.xxx.xxx"
end

local function format_ip(ip)
	if config.privacy.mask_ip then
		return mask_ip(ip)
	end

	return ip
end

local function format_city(city)
	if config.privacy.hide_city then
		return "hidden"
	end

	return city
end

local function format_isp(isp)
	if config.privacy.hide_isp then
		return "hidden"
	end

	return isp
end

M.setup = function(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
end

M.country = function()
	local data = get_data()
	local icon = get_flag(data.country)
	if not icon or icon == "" then
		icon = "🌎"
	end

	vim.notify("You are in " .. icon .. data.country, vim.log.levels.INFO, { title = "Where am I?", icon = icon })
end

M.city = function()
	local data = get_data()
	vim.notify("You are in " .. format_city(data.city), vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
end

M.ip = function()
	local data = get_data()
	vim.notify("You IP is " .. format_ip(data.ip), vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
end

M.isp = function()
	local data = get_data()
	vim.notify("You ISP is " .. format_isp(data.org), vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
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
