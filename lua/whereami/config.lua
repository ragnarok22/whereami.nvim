local M = {}
local is_list = vim.islist or vim.tbl_islist

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
	privacy = {
		mask_ip = false,
		hide_city = false,
		hide_isp = false,
	},
	hooks = {
		before_request = nil,
		after_request = nil,
	},
}

local current_config = vim.deepcopy(default_config)

local function expect(name, value, expected, optional)
	if optional and value == nil then
		return
	end
	if type(value) ~= expected then
		error("whereami: " .. name .. " must be a " .. expected, 3)
	end
end

local function validate_provider(provider)
	if type(provider) == "string" and provider ~= "" then
		return
	end
	expect("provider", provider, "table")
	expect("provider.url", provider.url, "string", true)
	expect("provider.fetch", provider.fetch, "function", true)
	expect("provider.normalize", provider.normalize, "function", true)
	if not provider.fetch and (not provider.url or provider.url == "") then
		error("whereami: each provider must define a nonempty url or a fetch function", 3)
	end
end

local function validate(cfg)
	expect("default_command", cfg.default_command, "string")
	if not vim.tbl_contains({ "all", "city", "country", "ip", "isp" }, cfg.default_command) then
		error("whereami: default_command must be all, city, country, ip, or isp", 3)
	end
	for _, name in ipairs({ "timeout", "cache_ttl" }) do
		local value = cfg[name]
		expect(name, value, "number")
		local minimum = name == "timeout" and 1 or 0
		if value < minimum or value > 2147483647 or value ~= math.floor(value) then
			error("whereami: " .. name .. " must be an integer between " .. minimum .. " and 2147483647", 3)
		end
	end
	expect("provider_url", cfg.provider_url, "string", true)
	if cfg.provider_url == "" then
		error("whereami: provider_url must not be empty", 3)
	end
	if cfg.providers ~= nil then
		if type(cfg.providers) == "table" and is_list(cfg.providers) then
			for _, provider in ipairs(cfg.providers) do
				validate_provider(provider)
			end
		else
			validate_provider(cfg.providers)
		end
	end
	expect("notification", cfg.notification, "table")
	expect("notification.title", cfg.notification.title, "string")
	expect("notification.icons", cfg.notification.icons, "table")
	for _, name in ipairs({ "default", "country_fallback" }) do
		expect("notification.icons." .. name, cfg.notification.icons[name], "string")
	end
	expect("privacy", cfg.privacy, "table")
	for _, name in ipairs({ "mask_ip", "hide_city", "hide_isp" }) do
		expect("privacy." .. name, cfg.privacy[name], "boolean")
	end
	expect("hooks", cfg.hooks, "table")
	for _, name in ipairs({ "before_request", "after_request" }) do
		expect("hooks." .. name, cfg.hooks[name], "function", true)
	end
end

function M.setup(opts)
	expect("setup options", opts, "table", true)
	local candidate = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
	validate(candidate)
	current_config = candidate
	return current_config
end

function M.get()
	return current_config
end

function M.defaults()
	return vim.deepcopy(default_config)
end

return M
