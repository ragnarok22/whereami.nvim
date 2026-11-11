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

function M.refresh(callback)
	if callback then
		return cache.get_async(current_config(), callback, { refresh = true })
	end
	return cache.refresh(current_config())
end

function M.get(callback)
	if callback then
		return cache.get_async(current_config(), callback)
	end
	return get_data()
end

local function show(option, opts)
	local cfg = current_config()
	local function display(data, err)
		if cfg ~= current_config() or err == cache.CANCELLED then
			return
		end
		if not data then
			notify_error(err)
		elseif option == "country" then
			notify_country(data)
		elseif option == "all" then
			local summary, icon = formatter.summary(data, cfg)
			notify(summary, icon)
		elseif option == "city" then
			notify("You are in " .. formatter.city(data.city, cfg.privacy), cfg.notification.icons.default)
		elseif option == "ip" then
			notify("Your IP is " .. formatter.ip(data.ip, cfg.privacy), cfg.notification.icons.default)
		elseif option == "isp" then
			notify("Your ISP is " .. formatter.isp(data.org, cfg.privacy), cfg.notification.icons.default)
		end
	end
	if opts and opts.async then
		cache.get_async(cfg, display)
	else
		display(get_data())
	end
end

function M.country(opts)
	show("country", opts)
end

function M.city(opts)
	show("city", opts)
end

function M.ip(opts)
	show("ip", opts)
end

function M.isp(opts)
	show("isp", opts)
end

function M.all(opts)
	show("all", opts)
end

function M.whereami(opts)
	local handler = M[current_config().default_command] or M.country
	handler(opts)
end

vim.api.nvim_create_user_command("Whereami", function(opts)
	local option = opts.fargs[1]
	local extra_option = opts.fargs[2]
	if extra_option ~= nil then
		notify_unknown_option(extra_option)
		return
	end

	if option == nil then
		M.whereami({ async = true })
		return
	end

	if option == "json" then
		M.get(function(data, err)
			if data then
				print(vim.json.encode(data))
			elseif err ~= cache.CANCELLED then
				notify_error(err)
			end
		end)
		return
	end

	if option == "refresh" then
		M.refresh(function(data, err)
			if data then
				notify_country(data)
			elseif err ~= cache.CANCELLED then
				notify_error(err)
			end
		end)
		return
	end

	if is_available_option(option) then
		M[option]({ async = true })
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
	desc = "Show where the current public IP appears to originate from.",
})

return M
