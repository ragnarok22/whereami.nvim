local M = {}
local flag = require("whereami.flag")

function M.country_icon(country, config)
	config = config or {}
	local notification = config.notification or {}
	local icons = notification.icons or {}
	return flag.get_flag(country, icons.country_fallback)
end

function M.ip(ip, privacy)
	privacy = privacy or {}
	if not privacy.mask_ip then
		return ip or "unknown"
	end

	if type(ip) ~= "string" or ip == "" then
		return "hidden"
	end

	local first_octet, second_octet = ip:match("^(%d+)%.(%d+)%.%d+%.%d+$")
	if first_octet and second_octet then
		return first_octet .. "." .. second_octet .. ".xxx.xxx"
	end

	local first_group, second_group = ip:match("^([%x]+):([%x]+):")
	if first_group and second_group then
		return first_group .. ":" .. second_group .. ":xxxx:xxxx:xxxx:xxxx:xxxx:xxxx"
	end

	return "hidden"
end

function M.city(city, privacy)
	if privacy and privacy.hide_city then
		return "hidden"
	end

	return city or "unknown"
end

function M.isp(isp, privacy)
	if privacy and privacy.hide_isp then
		return "hidden"
	end

	return isp or "unknown"
end

function M.summary(data, config)
	data = data or {}
	config = config or {}
	local privacy = config.privacy or {}
	local icon = M.country_icon(data.country, config)
	return table.concat({
		"Country: " .. icon .. (data.country or "unknown"),
		"City: " .. M.city(data.city, privacy),
		"IP: " .. M.ip(data.ip, privacy),
		"ISP: " .. M.isp(data.org, privacy),
	}, "\n"),
		icon
end

return M
