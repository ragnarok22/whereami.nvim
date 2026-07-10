local M = {}
local providers = require("whereami.providers")

local available_options = { "all", "city", "country", "ip", "isp", "refresh" }

local function available_options_text()
	return table.concat(available_options, ", ")
end

local function is_available_option(option)
	return vim.tbl_contains(available_options, option)
end

local default_config = {
	providers = nil,
	provider_url = nil,
	timeout = 5000,
	notification = {
		title = "Where am I?",
		icons = {
			country_fallback = "🌎",
			default = "❔",
		},
	},
	default_command = "country",
	cache_ttl = 300000,
	hooks = {
		before_request = nil,
		after_request = nil,
	},
}

local config = vim.deepcopy(default_config)
local cache = {
	data = nil,
	updated_at = 0,
}

local function merge_config(opts)
	config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
end

local function notify_error(message)
	vim.notify(message, vim.log.levels.ERROR, { title = config.notification.title, icon = "❌" })
end

local function notify_unknown_option(option)
	vim.notify(
		"Unknown option: " .. option .. "\nAvailable options: " .. available_options_text(),
		vim.log.levels.WARN,
		{ title = config.notification.title }
	)
end

local function get_data(opts)
	opts = opts or {}
	local now = vim.loop.now()
	if not opts.refresh and config.cache_ttl > 0 and cache.data and (now - cache.updated_at) < config.cache_ttl then
		return cache.data
	end

	if config.hooks.before_request then
		config.hooks.before_request(config)
	end

	local parse_error = false
	for _, provider in ipairs(providers.list(config)) do
		local data, err = providers.fetch(provider, config)
		if data then
			cache.data = data
			cache.updated_at = vim.loop.now()

			if config.hooks.after_request then
				config.hooks.after_request(data, config)
			end

			return data
		end
		parse_error = parse_error or err == "Unable to parse location data."
	end

	if parse_error then
		return nil, "Unable to parse location data."
	end
	return nil, "Unable to fetch location data."
end

-- TODO: find a better way to do this. So far utf8.char() is the only way I found but is not available in lua 5.1
local function get_flag(country_iso)
	local flag_icon = ""
	if type(country_iso) ~= "string" then
		return flag_icon
	end

	country_iso = country_iso:upper()
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

local function notify(message, icon)
	vim.notify(message, vim.log.levels.INFO, { title = config.notification.title, icon = icon })
end

local function get_country_icon(country)
	local icon = get_flag(country or "")
	if not icon or icon == "" then
		icon = config.notification.icons.country_fallback
	end
	return icon
end

local function notify_country(data)
	local icon = get_country_icon(data.country)
	notify("You are in " .. icon .. (data.country or "unknown"), icon)
end

M.setup = function(opts)
	merge_config(opts)
	cache.data = nil
	cache.updated_at = 0
end

M.clear_cache = function()
	cache.data = nil
	cache.updated_at = 0
end

M.refresh = function()
	M.clear_cache()
	return get_data({ refresh = true })
end

M.country = function()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	notify_country(data)
end

M.city = function()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	notify("You are in " .. (data.city or "unknown"), config.notification.icons.default)
end

M.ip = function()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	notify("Your IP is " .. (data.ip or "unknown"), config.notification.icons.default)
end

M.isp = function()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	notify("Your ISP is " .. (data.org or "unknown"), config.notification.icons.default)
end

M.all = function()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	local icon = get_country_icon(data.country)
	local summary = table.concat({
		"Country: " .. icon .. (data.country or "unknown"),
		"City: " .. (data.city or "unknown"),
		"IP: " .. (data.ip or "unknown"),
		"ISP: " .. (data.org or "unknown"),
	}, "\n")

	notify(summary, icon)
end

M.whereami = function()
	local handler = M[config.default_command] or M.country
	handler()
end

vim.api.nvim_create_user_command("Whereami", function(opts)
	local option = opts.fargs[1]
	local extra_option = opts.fargs[2]
	if extra_option ~= nil then
		notify_unknown_option(extra_option)
		return
	end

	if option == nil then
		local handler = M[config.default_command] or M.country
		handler()
		return
	end

	if option == "refresh" then
		local data, err = M.refresh()
		if not data then
			notify_error(err)
			return
		end
		notify_country(data)
		return
	end

	if is_available_option(option) then
		M[option]()
	else
		notify_unknown_option(option)
	end
end, {
	nargs = "*",
	complete = function(arg_lead)
		return vim.tbl_filter(function(candidate)
			return vim.startswith(candidate, arg_lead)
		end, available_options)
	end,
	desc = "Location where the current location was originated from.",
})

return M
