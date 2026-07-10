local M = {}

local FALLBACK_ICON = "🌎"
local REGIONAL_INDICATOR_OFFSET = 127397

function M.get_flag(country_iso, fallback_icon)
	fallback_icon = fallback_icon or FALLBACK_ICON
	if type(country_iso) ~= "string" or not country_iso:match("^[A-Za-z][A-Za-z]$") then
		return fallback_icon
	end

	country_iso = country_iso:upper()

	return vim.fn.nr2char(country_iso:byte(1) + REGIONAL_INDICATOR_OFFSET)
		.. vim.fn.nr2char(country_iso:byte(2) + REGIONAL_INDICATOR_OFFSET)
end

return M
