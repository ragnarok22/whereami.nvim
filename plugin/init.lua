vim.api.nvim_create_user_command("Whereami", function(opts)
	local whereami = require("whereami")
	local option = opts.fargs[1]

	if option == "country" then
		whereami.country()
	elseif option == "city" then
		whereami.city()
	elseif option == "ip" then
		whereami.ip()
	else
		whereami.country()
	end
end, {
	nargs = "*",
	complete = function()
		-- return completion candidates as a list-like table
		return { "city", "country", "ip" }
	end,
	desc = "Location where the current location was originated from.",
})
