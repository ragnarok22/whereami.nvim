local M = {}
local providers = require("whereami.providers")

local cache = {
	data = nil,
	updated_at = 0,
}
local pending
local generation = 0

M.CANCELLED = "Location request cancelled."

function M.clear()
	generation = generation + 1
	cache.data = nil
	cache.updated_at = 0
	if pending then
		local request = pending
		if request.cancel then
			request.cancel()
		end
		request.finish(nil, M.CANCELLED)
	end
end

local function cached_data(config, opts)
	local cache_ttl = config.cache_ttl or 0
	local now = vim.loop.now()
	if not opts.refresh and cache_ttl > 0 and cache.data and (now - cache.updated_at) < cache_ttl then
		return cache.data
	end
end

function M.get(config, opts)
	config = config or {}
	opts = opts or {}
	local hooks = config.hooks or {}
	local cached = cached_data(config, opts)
	if cached then
		return cached
	end

	if hooks.before_request then
		local ok = pcall(hooks.before_request, config)
		if not ok then
			return nil, "Location hook failed."
		end
	end

	local parse_error = false
	for _, provider in ipairs(providers.list(config)) do
		local data, err = providers.fetch(provider, config)
		if data then
			if hooks.after_request then
				local ok = pcall(hooks.after_request, data, config)
				if not ok then
					return nil, "Location hook failed."
				end
			end

			cache.data = data
			cache.updated_at = vim.loop.now()

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

function M.get_async(config, callback, opts)
	opts = opts or {}
	if opts.refresh then
		M.clear()
	end
	local version = generation
	local cached = cached_data(config, opts)
	if cached then
		vim.schedule(function()
			if version == generation then
				callback(cached)
			else
				callback(nil, M.CANCELLED)
			end
		end)
		return
	end
	if pending and pending.config == config then
		table.insert(pending.callbacks, callback)
		return
	end

	local request = { config = config, callbacks = { callback }, done = false }
	local function finish(data, err)
		if request.done then
			return
		end
		request.done = true
		if pending == request then
			pending = nil
		end
		for _, listener in ipairs(request.callbacks) do
			vim.schedule(function()
				if version == generation then
					listener(data, err)
				else
					listener(nil, M.CANCELLED)
				end
			end)
		end
	end
	request.finish = finish
	pending = request
	local hooks = config.hooks or {}
	if hooks.before_request and not pcall(hooks.before_request, config) then
		finish(nil, "Location hook failed.")
		return
	end

	local list = providers.list(config)
	local index, parse_error = 0, false
	local function try_next()
		if request.done then
			return
		end
		index = index + 1
		if not list[index] then
			finish(nil, parse_error and "Unable to parse location data." or "Unable to fetch location data.")
			return
		end
		request.cancel = providers.fetch_async(list[index], config, function(data, err)
			if request.done then
				return
			end
			if not data then
				parse_error = parse_error or err == "Unable to parse location data."
				try_next()
				return
			end
			if hooks.after_request and not pcall(hooks.after_request, data, config) then
				finish(nil, "Location hook failed.")
				return
			end
			if not request.done then
				cache.data = data
				cache.updated_at = vim.loop.now()
				finish(data)
			end
		end)
	end
	try_next()
end

return M
