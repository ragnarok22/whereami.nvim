local http = require("whereami.http")
local server_helper = require("tests.helpers.http_server")

describe("HTTP transport", function()
	local server

	after_each(function()
		if server then
			server.close()
		end
	end)

	it("handles real curl errors without forwarding private provider URLs", function()
		server = server_helper.start("")

		assert.is_nil(http.get(server.url .. "?token=EXAMPLE_TOKEN", { timeout = 1000 }))
		assert.is_nil(vim.fn.execute("messages"):find("EXAMPLE_TOKEN", 1, true))
	end)

	it("terminates a timed-out curl process instead of leaving its connection open", function()
		server = server_helper.start(false)

		assert.is_nil(http.get(server.url, { timeout = 100 }))

		assert.is_true(vim.wait(1000, function()
			return server.closed == 1
		end))
	end)

	it("preserves multiline bodies and HTTP status codes", function()
		local body = "{\n\"country\":\"US\"\n}\n"
		server = server_helper.start("HTTP/1.1 200 OK\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body)

		assert.are.same({ body = body, status = 200 }, http.get(server.url, { timeout = 1000 }))
	end)
end)
