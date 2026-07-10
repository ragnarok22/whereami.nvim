local stub = require("luassert.stub")
local whereami = require("whereami")
local flag = require("whereami.flag")
local formatter = require("whereami.format")
local curl = require("plenary.curl")

describe("whereami", function()
	after_each(function()
		whereami.setup()
	end)

	it("returns proper flag emoji", function()
		assert.are.equal("🇺🇸", flag.get_flag("US"))
	end)

	it("uppercases country codes before generating flags", function()
		assert.are.equal("🇺🇸", flag.get_flag("us"))
	end)

	it("uses fallback icon for missing country codes", function()
		assert.are.equal("🌎", flag.get_flag(nil))
	end)

	it("uses fallback icon for empty country codes", function()
		assert.are.equal("🌎", flag.get_flag(""))
	end)

	it("uses fallback icon for invalid country codes", function()
		assert.are.equal("🌎", flag.get_flag("USA"))
		assert.are.equal("🌎", flag.get_flag("U1"))
	end)

	it("uses fallback icon when provider omits country", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"Unknown\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert
			.stub(vim.notify)
			.was_called_with("You are in 🌎unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "🌎" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("uses configured fallback icon when provider omits country", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"Unknown\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			notification = {
				icons = { country_fallback = "📍" },
			},
		})
		whereami.country()

		assert
			.stub(vim.notify)
			.was_called_with("You are in 📍unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "📍" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("formats a valid country response", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"country\":\"US\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇺🇸US", vim.log.levels.INFO, { title = "Where am I?", icon = "🇺🇸" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("formats a city response", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"New York\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.city()

		assert
			.stub(vim.notify)
			.was_called_with("You are in New York", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("formats an IP response", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"ip\":\"203.0.113.10\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.ip()

		assert
			.stub(vim.notify)
			.was_called_with("Your IP is 203.0.113.10", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("formats an ISP response", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"org\":\"Example ISP\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.isp()

		assert
			.stub(vim.notify)
			.was_called_with("Your ISP is Example ISP", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("shows all location details in one summary", function()
		local curl_stub = stub(curl, "get", function()
			return {
				body = "{\"country\":\"US\",\"city\":\"New York\",\"ip\":\"203.0.113.10\",\"org\":\"Example ISP\"}",
			}
		end)
		local notify_stub = stub(vim, "notify")

		whereami.all()

		assert.stub(vim.notify).was_called_with(
			table.concat({
				"Country: 🇺🇸US",
				"City: New York",
				"IP: 203.0.113.10",
				"ISP: Example ISP",
			}, "\n"),
			vim.log.levels.INFO,
			{ title = "Where am I?", icon = "🇺🇸" }
		)

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("configures provider URL, timeout, and notification metadata", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"Reykjavik\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			provider_url = "https://example.test/json",
			timeout = 1234,
			notification = {
				title = "VPN Check",
				icons = { default = "📍" },
			},
		})

		whereami.city()

		assert.stub(curl.get).was_called_with("https://example.test/json", { timeout = 1234 })
		assert
			.stub(vim.notify)
			.was_called_with("You are in Reykjavik", vim.log.levels.INFO, { title = "VPN Check", icon = "📍" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("normalizes provider_url responses from a built-in provider", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"country_code\":\"CA\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			provider_url = "https://ipapi.co/json/",
		})
		whereami.country()

		assert.stub(curl.get).was_called_with("https://ipapi.co/json/", { timeout = 5000 })
		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇨🇦CA", vim.log.levels.INFO, { title = "Where am I?", icon = "🇨🇦" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("prefers provider_url over configured provider lists", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"Reykjavik\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			provider_url = "https://example.test/json",
			providers = {
				{ url = "https://unused.example/json" },
			},
		})

		whereami.city()

		assert.stub(curl.get).was_called_with("https://example.test/json", { timeout = 5000 })
		assert
			.stub(vim.notify)
			.was_called_with("You are in Reykjavik", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("defaults to country when no command argument is provided", function()
		local country_stub = stub(whereami, "country")

		vim.cmd("Whereami")

		assert.stub(whereami.country).was_called(1)

		country_stub:revert()
	end)

	it("dispatches public commands from :Whereami arguments", function()
		for _, option in ipairs({ "all", "country", "city", "ip", "isp" }) do
			local command_stub = stub(whereami, option)

			vim.cmd("Whereami " .. option)

			assert.stub(whereami[option]).was_called(1)
			command_stub:revert()
		end
	end)

	it("returns completion candidates for public command arguments", function()
		assert.are.same({ "city", "country" }, vim.fn.getcompletion("Whereami c", "cmdline"))
		assert.are.same({ "ip", "isp" }, vim.fn.getcompletion("Whereami i", "cmdline"))
		assert.are.same(
			{ "all", "city", "country", "ip", "isp", "json", "refresh" },
			vim.fn.getcompletion("Whereami ", "cmdline")
		)
	end)

	it("notifies when an unknown command argument is provided", function()
		local notify_stub = stub(vim, "notify")
		local country_stub = stub(whereami, "country")

		vim.cmd("Whereami foo")

		assert.stub(vim.notify).was_called_with(
			"Unknown option: foo\nAvailable options: all, city, country, ip, isp, json, refresh",
			vim.log.levels.WARN,
			{ title = "Where am I?" }
		)
		assert.stub(whereami.country).was_not_called()

		country_stub:revert()
		notify_stub:revert()
	end)

	it("notifies when trailing command arguments are provided after a known option", function()
		local notify_stub = stub(vim, "notify")
		local country_stub = stub(whereami, "country")

		vim.cmd("Whereami country foo")

		assert.stub(vim.notify).was_called_with(
			"Unknown option: foo\nAvailable options: all, city, country, ip, isp, json, refresh",
			vim.log.levels.WARN,
			{ title = "Where am I?" }
		)
		assert.stub(whereami.country).was_not_called()

		country_stub:revert()
		notify_stub:revert()
	end)

	it("uses unknown values when optional fields are missing from available location data", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"country\":\"US\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.city()
		whereami.ip()
		whereami.isp()

		assert
			.stub(vim.notify)
			.was_called_with("You are in unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
		assert
			.stub(vim.notify)
			.was_called_with("Your IP is unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
		assert
			.stub(vim.notify)
			.was_called_with("Your ISP is unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("uses unknown values for blank optional fields", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"country\":\"US\",\"city\":\"\",\"ip\":\"\",\"org\":\"\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.city()
		whereami.ip()
		whereami.isp()

		assert
			.stub(vim.notify)
			.was_called_with("You are in unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
		assert
			.stub(vim.notify)
			.was_called_with("Your IP is unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
		assert
			.stub(vim.notify)
			.was_called_with("Your ISP is unknown", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("falls back when a provider response only has blank location fields", function()
		local calls = 0
		local curl_stub = stub(curl, "get", function(url)
			calls = calls + 1
			if url == "https://ipinfo.io/json" then
				return { status = 200, body = "{\"ip\":\"\",\"city\":\"\",\"country\":\"\",\"org\":\"\"}" }
			end

			return { status = 200, body = "{\"country_code\":\"CA\",\"city\":\"Toronto\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇨🇦CA", vim.log.levels.INFO, { title = "Where am I?", icon = "🇨🇦" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("falls back to the next default provider when the first provider fails", function()
		local calls = 0
		local curl_stub = stub(curl, "get", function(url)
			calls = calls + 1
			if url == "https://ipinfo.io/json" then
				error("ipinfo unavailable")
			end

			return { body = "{\"country\":\"CA\",\"city\":\"Toronto\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇨🇦CA", vim.log.levels.INFO, { title = "Where am I?", icon = "🇨🇦" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("falls back when a provider response has no location fields", function()
		local calls = 0
		local curl_stub = stub(curl, "get", function(url)
			calls = calls + 1
			if url == "https://ipinfo.io/json" then
				return { status = 200, body = "{\"error\":\"rate limited\"}" }
			end

			return { status = 200, body = "{\"country_code\":\"CA\",\"city\":\"Toronto\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇨🇦CA", vim.log.levels.INFO, { title = "Where am I?", icon = "🇨🇦" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("falls back when a provider returns a non-success HTTP status", function()
		local calls = 0
		local curl_stub = stub(curl, "get", function(url)
			calls = calls + 1
			if url == "https://ipinfo.io/json" then
				return { status = 429, body = "{\"error\":\"quota exceeded\"}" }
			end

			return { status = 200, body = "{\"country_code\":\"CA\",\"city\":\"Toronto\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.country()

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("You are in 🇨🇦CA", vim.log.levels.INFO, { title = "Where am I?", icon = "🇨🇦" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("supports custom provider tables with fetch handlers", function()
		local curl_stub = stub(curl, "get", function()
			error("curl should not be used for custom providers")
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			providers = {
				fetch = function()
					return "{\"city\":\"Berlin\",\"country\":\"DE\"}"
				end,
				normalize = function(data)
					return {
						city = data.city,
						country = data.country,
					}
				end,
			},
		})

		whereami.city()

		assert
			.stub(vim.notify)
			.was_called_with("You are in Berlin", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("uses cache TTL and request hooks", function()
		local calls = 0
		local before_calls = 0
		local after_calls = 0
		local curl_stub = stub(curl, "get", function()
			calls = calls + 1
			return { body = "{\"ip\":\"127.0.0." .. calls .. "\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			cache_ttl = 1000,
			hooks = {
				before_request = function()
					before_calls = before_calls + 1
				end,
				after_request = function()
					after_calls = after_calls + 1
				end,
			},
		})

		whereami.ip()
		whereami.ip()

		assert.are.equal(1, calls)
		assert.are.equal(1, before_calls)
		assert.are.equal(1, after_calls)

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("notifies instead of raising when the network request fails", function()
		local curl_stub = stub(curl, "get", function()
			error("network unavailable")
		end)
		local notify_stub = stub(vim, "notify")

		assert.has_no.errors(function()
			whereami.country()
		end)

		assert
			.stub(vim.notify)
			.was_called_with("Unable to fetch location data.", vim.log.levels.ERROR, { title = "Where am I?", icon = "❌" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("notifies instead of raising when the response is invalid JSON", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "not-json" }
		end)
		local notify_stub = stub(vim, "notify")

		assert.has_no.errors(function()
			whereami.city()
		end)

		assert
			.stub(vim.notify)
			.was_called_with("Unable to parse location data.", vim.log.levels.ERROR, { title = "Where am I?", icon = "❌" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("does not run a second refresh cycle when refresh command fails", function()
		local calls = 0
		local curl_stub = stub(curl, "get", function()
			calls = calls + 1
			error("network unavailable")
		end)
		local notify_stub = stub(vim, "notify")

		vim.cmd("Whereami refresh")

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("Unable to fetch location data.", vim.log.levels.ERROR, { title = "Where am I?", icon = "❌" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("refreshes cached data on demand", function()
		local responses = {
			"{\"country\":\"US\",\"city\":\"New York\"}",
			"{\"country\":\"CA\",\"city\":\"Toronto\"}",
		}
		local calls = 0
		local curl_stub = stub(curl, "get", function()
			calls = calls + 1
			return { body = responses[calls] }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.city()
		whereami.refresh()
		whereami.city()

		assert.are.equal(2, calls)
		assert
			.stub(vim.notify)
			.was_called_with("You are in Toronto", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("formats private location fields without fetching data", function()
		assert.are.equal("203.0.xxx.xxx", formatter.ip("203.0.113.42", { mask_ip = true }))
		assert.are.equal("hidden", formatter.city("Springfield", { hide_city = true }))
		assert.are.equal("hidden", formatter.isp("Example ISP", { hide_isp = true }))
	end)

	it("masks IP addresses when privacy mask_ip is enabled", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"ip\":\"203.0.113.42\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({ privacy = { mask_ip = true } })
		whereami.ip()

		assert
			.stub(vim.notify)
			.was_called_with("Your IP is 203.0.xxx.xxx", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("hides city and ISP values when privacy options are enabled", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"city\":\"Springfield\",\"org\":\"Example ISP\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({ privacy = { hide_city = true, hide_isp = true } })
		whereami.city()
		whereami.isp()

		assert
			.stub(vim.notify)
			.was_called_with("You are in hidden", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })
		assert
			.stub(vim.notify)
			.was_called_with("Your ISP is hidden", vim.log.levels.INFO, { title = "Where am I?", icon = "❔" })

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("applies privacy options to the all summary", function()
		local curl_stub = stub(curl, "get", function()
			return {
				body = "{\"country\":\"US\",\"city\":\"Springfield\",\"ip\":\"203.0.113.42\",\"org\":\"Example ISP\"}",
			}
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			privacy = {
				mask_ip = true,
				hide_city = true,
				hide_isp = true,
			},
		})
		whereami.all()

		assert.stub(vim.notify).was_called_with(
			table.concat({
				"Country: 🇺🇸US",
				"City: hidden",
				"IP: 203.0.xxx.xxx",
				"ISP: hidden",
			}, "\n"),
			vim.log.levels.INFO,
			{ title = "Where am I?", icon = "🇺🇸" }
		)

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("returns raw data without notifying", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"ip\":\"127.0.0.1\",\"city\":\"Localhost\",\"country\":\"US\",\"org\":\"Test ISP\"}" }
		end)
		local notify_stub = stub(vim, "notify")

		whereami.setup({
			privacy = {
				mask_ip = true,
				hide_city = true,
				hide_isp = true,
			},
		})
		local data = whereami.get()

		assert.are.equal("127.0.0.1", data.ip)
		assert.are.equal("Localhost", data.city)
		assert.are.equal("US", data.country)
		assert.are.equal("Test ISP", data.org)
		assert.stub(vim.notify).was_not_called()

		curl_stub:revert()
		notify_stub:revert()
	end)

	it("prints raw data as JSON without notifying", function()
		local curl_stub = stub(curl, "get", function()
			return { body = "{\"ip\":\"127.0.0.1\"}" }
		end)
		local notify_stub = stub(vim, "notify")
		local print_stub = stub(_G, "print")

		vim.cmd("Whereami json")

		assert.stub(_G.print).was_called_with("{\"ip\":\"127.0.0.1\"}")
		assert.stub(vim.notify).was_not_called()

		curl_stub:revert()
		notify_stub:revert()
		print_stub:revert()
	end)
end)
