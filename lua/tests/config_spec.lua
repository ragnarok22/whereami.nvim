local config = require("whereami.config")

describe("configuration validation", function()
	after_each(function()
		config.setup()
	end)

	it("rejects recursive and non-display commands without replacing the current configuration", function()
		config.setup({ default_command = "city" })
		for _, command in ipairs({ "whereami", "setup", "get", "json", "refresh", "invalid" }) do
			assert.has_error(function()
				config.setup({ default_command = command })
			end)
			assert.are.equal("city", config.get().default_command)
		end
	end)

	it("rejects invalid timeouts, nested options, and provider handlers during setup", function()
		for _, opts in ipairs({
			{ timeout = 0 },
			{ timeout = math.huge },
			{ timeout = 0 / 0 },
			{ cache_ttl = -1 },
			{ cache_ttl = "1000" },
			{ notification = false },
			{ privacy = { mask_ip = "true" } },
			{ hooks = { after_request = true } },
			{ providers = { { fetch = true } } },
			{ providers = { { normalize = function() end } } },
		}) do
			assert.has_error(function()
				config.setup(opts)
			end)
		end
	end)
end)
