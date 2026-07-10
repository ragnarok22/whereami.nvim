local M = {}

local FALLBACK_ICON = "🌎"

-- TODO: find a better way to do this. So far utf8.char() is the only way I found but is not available in lua 5.1
function M.get_flag(country_iso, fallback_icon)
	fallback_icon = fallback_icon or FALLBACK_ICON
	if type(country_iso) ~= "string" or not country_iso:match("^[A-Za-z][A-Za-z]$") then
		return fallback_icon
	end

	country_iso = country_iso:upper()

	local flag_icon = ""
	for i = 1, #country_iso do
		local code_point = country_iso:byte(i) + 127397
		if code_point <= 0x7F then
			flag_icon = flag_icon .. string.char(code_point)
		elseif code_point <= 0x7FF then
			flag_icon = flag_icon .. string.char(0xC0 + math.floor(code_point / 0x40), 0x80 + code_point % 0x40)
		elseif code_point <= 0xFFFF then
			flag_icon = flag_icon
				.. string.char(
					0xE0 + math.floor(code_point / 0x1000),
					0x80 + math.floor((code_point % 0x1000) / 0x40),
					0x80 + code_point % 0x40
				)
		elseif code_point <= 0x10FFFF then
			flag_icon = flag_icon
				.. string.char(
					0xF0 + math.floor(code_point / 0x40000),
					0x80 + math.floor((code_point % 0x40000) / 0x1000),
					0x80 + math.floor((code_point % 0x1000) / 0x40),
					0x80 + code_point % 0x40
				)
		end
	end

	-- for i = 1, #country_iso do
	--     local charCode = string.byte(country_iso:sub(i, i)) + 127397
	--     flag_icon = flag_icon .. utf8.char(charCode)
	-- end
	return flag_icon
end

return M
