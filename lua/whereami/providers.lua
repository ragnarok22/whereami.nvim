local M = {}

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

local function has_location_field(data)
	return data.ip ~= nil or data.city ~= nil or data.country ~= nil or data.org ~= nil
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

	if type(data) ~= "table" or not has_location_field(data) then
		return nil
	end

	return data
end

return M
