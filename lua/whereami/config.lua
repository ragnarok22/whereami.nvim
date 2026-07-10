local M = {}

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

function M.setup(opts)
	current_config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
	return current_config
end

function M.get()
	return current_config
end

function M.defaults()
	return vim.deepcopy(default_config)
end

return M
