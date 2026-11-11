local stub = require("luassert.stub")
local http = require("whereami.http")
local curl = require("plenary.curl")

describe("HTTP error handling", function()
	local curl_stub

	after_each(function()
		if curl_stub then
			curl_stub:revert()
		end
	end)

	it("handles Plenary callback errors without forwarding private provider URLs", function()
		local error_handled = false
		curl_stub = stub(curl, "get", function(url, opts)
			assert.are.equal(1234, opts.timeout)
			vim.schedule(function()
				opts.on_error({ message = "curl failed: " .. url })
				error_handled = true
			end)
			return {}
		end)

		http.get("https://example.test/json?token=private", { timeout = 1234 })

		assert.is_true(vim.wait(1000, function()
			return error_handled
		end))
	end)
end)
