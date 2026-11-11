local M = {}

local MAX_RESPONSE_SIZE = 64 * 1024
local MAX_LOCATION_VALUE_SIZE = 1024
local location_fields = { "ip", "city", "country", "org" }

local default_providers = {
	{
		name = "ipinfo",
		url = "https://ipinfo.io/json",
		normalize = function(data)
			return {
				ip = data.ip,
				city = data.city,
				country = data.country,
				org = data.org,
			}
		end,
	},
	{
		name = "ipapi",
		url = "https://ipapi.co/json/",
		normalize = function(data)
			return {
				ip = data.ip,
				city = data.city,
				country = data.country_code or data.country,
				org = data.org or data.asn,
			}
		end,
	},
}

local function normalize_provider(provider)
	if type(provider) == "string" then
		return { url = provider }
	end

	if type(provider) ~= "table" then
		return nil
	end

	return provider
end

local function is_single_provider(provider)
	if type(provider) ~= "table" then
		return false
	end

	return provider.url ~= nil or provider.fetch ~= nil or provider.normalize ~= nil
end

local function has_location_value(value)
	return type(value) == "string" and value ~= "" and #value <= MAX_LOCATION_VALUE_SIZE
end

local function has_location_field(data)
	return has_location_value(data.ip)
		or has_location_value(data.city)
		or has_location_value(data.country)
		or has_location_value(data.org)
end

local function sanitize_location_data(data)
	if type(data) ~= "table" then
		return nil
	end

	local sanitized = {}
	for key, value in pairs(data) do
		sanitized[key] = value
	end
	for _, field in ipairs(location_fields) do
		local value = data[field]
		sanitized[field] = has_location_value(value) and value or nil
	end

	return has_location_field(sanitized) and sanitized or nil
end

local function unwrap_response(response)
	if type(response) ~= "table" or response.body == nil then
		return response
	end

	local status = response.status
	if status and (status < 200 or status >= 300) then
		return nil
	end

	return response.body
end

function M.list(config)
	config = config or {}

	if config.provider_url then
		for _, provider in ipairs(default_providers) do
			if provider.url == config.provider_url then
				return { provider }
			end
		end

		return { { url = config.provider_url } }
	end

	if type(config.providers) == "string" then
		return { { url = config.providers } }
	end

	if is_single_provider(config.providers) then
		return { config.providers }
	end

	if type(config.providers) == "table" and #config.providers > 0 then
		return config.providers
	end

	return default_providers
end

function M.fetch(provider, config)
	provider = normalize_provider(provider)
	if not provider then
		return nil
	end

	local ok, response
	if provider.fetch then
		ok, response = pcall(provider.fetch, config)
	else
		ok, response = pcall(require("plenary.curl").get, provider.url, { timeout = config.timeout })
	end

	if not ok or not response or response == "" then
		return nil
	end

	response = unwrap_response(response)
	if not response or response == "" then
		return nil
	end
	if type(response) == "string" and #response > MAX_RESPONSE_SIZE then
		return nil
	end

	local data = response
	if type(response) == "string" then
		local decode_ok, decoded = pcall(vim.json.decode, response)
		if not decode_ok or type(decoded) ~= "table" then
			return nil, "Unable to parse location data."
		end
		data = decoded
	end

	if provider.normalize then
		local normalize_ok, normalized = pcall(provider.normalize, data)
		if not normalize_ok then
			return nil
		end
		data = normalized
	end

	return sanitize_location_data(data)
end

return M
