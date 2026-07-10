local M = {}
local providers = require("whereami.providers")

local cache = {
	data = nil,
	updated_at = 0,
}

function M.clear()
	cache.data = nil
	cache.updated_at = 0
end

function M.get(config, opts)
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

function M.refresh(config)
	M.clear()
	return M.get(config, { refresh = true })
end

return M
