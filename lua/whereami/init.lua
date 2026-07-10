local M = {}
local cache = require("whereami.cache")
local config = require("whereami.config")
local formatter = require("whereami.format")

local available_options = { "all", "city", "country", "ip", "isp", "json", "refresh" }

local function available_options_text()
	return table.concat(available_options, ", ")
end

local function is_available_option(option)
	return vim.tbl_contains(available_options, option)
end

local function current_config()
	return config.get()
end

local function get_data(opts)
	return cache.get(current_config(), opts)
end

local function notify(message, icon)
	local cfg = current_config()
	vim.notify(message, vim.log.levels.INFO, { title = cfg.notification.title, icon = icon })
end

local function notify_error(message)
	vim.notify(message, vim.log.levels.ERROR, { title = current_config().notification.title, icon = "❌" })
end

local function notify_unknown_option(option)
	vim.notify(
		"Unknown option: " .. option .. "\nAvailable options: " .. available_options_text(),
		vim.log.levels.WARN,
		{ title = current_config().notification.title }
	)
end

local function notify_country(data)
	local cfg = current_config()
	local icon = formatter.country_icon(data.country, cfg)
	notify("You are in " .. icon .. (data.country or "unknown"), icon)
end

function M.setup(opts)
	config.setup(opts)
	cache.clear()
end

function M.clear_cache()
	cache.clear()
end

function M.refresh()
	return cache.refresh(current_config())
end

function M.get()
	return get_data()
end

function M.country()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	notify_country(data)
end

function M.city()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	local cfg = current_config()
	notify("You are in " .. formatter.city(data.city, cfg.privacy), cfg.notification.icons.default)
end

function M.ip()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	local cfg = current_config()
	notify("Your IP is " .. formatter.ip(data.ip, cfg.privacy), cfg.notification.icons.default)
end

function M.isp()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	local cfg = current_config()
	notify("Your ISP is " .. formatter.isp(data.org, cfg.privacy), cfg.notification.icons.default)
end

function M.all()
	local data, err = get_data()
	if not data then
		notify_error(err)
		return
	end

	local summary, icon = formatter.summary(data, current_config())
	notify(summary, icon)
end

function M.whereami()
	local handler = M[current_config().default_command] or M.country
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
		M.whereami()
		return
	end

	if option == "json" then
		local data, err = M.get()
		if not data then
			notify_error(err)
			return
		end
		print(vim.json.encode(data))
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
