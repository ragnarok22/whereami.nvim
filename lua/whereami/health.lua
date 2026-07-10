local M = {}

local PROVIDER_URL = "https://ipinfo.io/json"
local health = vim.health or {}

local function start(name)
	if health.start then
		health.start(name)
	elseif health.report_start then
		health.report_start(name)
	end
end

local function ok(message)
	if health.ok then
		health.ok(message)
	else
		health.report_ok(message)
	end
end

local function warn(message)
	if health.warn then
		health.warn(message)
	else
		health.report_warn(message)
	end
end

local function error(message)
	if health.error then
		health.error(message)
	else
		health.report_error(message)
	end
end

local function info(message)
	if health.info then
		health.info(message)
	else
		health.report_info(message)
	end
end

local function is_notify_customized()
	local notify_info = debug.getinfo(vim.notify, "S")
	return notify_info and notify_info.source ~= "=[C]"
end

function M.check()
	start("whereami.nvim")

	local has_curl, curl = pcall(require, "plenary.curl")
	if has_curl then
		ok("plenary.curl is available")
	else
		error("plenary.curl is not available. Install nvim-lua/plenary.nvim.")
	end

	if vim.json and vim.json.decode then
		local decoded_ok, decoded = pcall(vim.json.decode, '{"whereami":true}')
		if decoded_ok and decoded and decoded.whereami == true then
			ok("JSON decoding works")
		else
			error("vim.json.decode is available, but could not decode a simple JSON object")
		end
	else
		error("vim.json.decode is not available. whereami.nvim requires Neovim with vim.json support.")
	end

	if is_notify_customized() then
		ok("vim.notify has been customized")
	else
		info("vim.notify is using Neovim's default implementation")
	end

	if not has_curl then
		warn("Skipping provider reachability check because plenary.curl is unavailable")
		return
	end

	local request_ok, response = pcall(curl.get, PROVIDER_URL, { timeout = 5000 })
	if not request_ok then
		error("Could not reach provider " .. PROVIDER_URL .. ": " .. tostring(response))
		return
	end

	local status = response and response.status
	if status and status >= 200 and status < 300 then
		ok("Provider is reachable: " .. PROVIDER_URL)
	elseif status then
		error("Provider " .. PROVIDER_URL .. " returned HTTP status " .. tostring(status))
	else
		error("Provider " .. PROVIDER_URL .. " did not return an HTTP status")
	end
end

return M
