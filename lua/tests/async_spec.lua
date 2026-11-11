local stub = require("luassert.stub")
local whereami = require("whereami")
local server_helper = require("tests.helpers.http_server")

describe("asynchronous requests", function()
	local server, notify_stub
	local notifications

	before_each(function()
		notifications = {}
		notify_stub = stub(vim, "notify", function(message)
			table.insert(notifications, message)
		end)
	end)

	after_each(function()
		whereami.setup()
		if server then
			server.close()
			server = nil
		end
		notify_stub:revert()
	end)

	it("returns from commands before receiving data and shares one request between commands", function()
		local client
		server = server_helper.start(function(connection)
			client = connection
		end)
		local before_calls, after_calls = 0, 0
		whereami.setup({
			provider_url = server.url,
			timeout = 2000,
			hooks = {
				before_request = function()
					before_calls = before_calls + 1
				end,
				after_request = function()
					after_calls = after_calls + 1
				end,
			},
		})

		vim.cmd("Whereami country")
		vim.cmd("Whereami ip")

		assert.are.same({}, notifications)
		assert.is_true(vim.wait(1000, function()
			return client ~= nil
		end))
		local body = "{\"country\":\"US\",\"ip\":\"203.0.113.10\"}"
		client:write("HTTP/1.1 200 OK\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body)
		assert.is_true(vim.wait(1000, function()
			return #notifications == 2
		end))
		assert.are.same({ "You are in 🇺🇸US", "Your IP is 203.0.113.10" }, notifications)
		assert.are.equal(1, server.connections)
		assert.are.equal(1, before_calls)
		assert.are.equal(1, after_calls)
		assert.are.equal("US", whereami.get().country)
	end)

	it("cancels an in-flight request on setup without restoring its stale cache", function()
		server = server_helper.start(false)
		whereami.setup({ provider_url = server.url, timeout = 2000 })
		local called, result, request_error
		whereami.get(function(data, err)
			called, result, request_error = true, data, err
		end)
		assert.is_true(vim.wait(1000, function()
			return server.connections == 1
		end))

		whereami.setup({
			providers = {
				fetch = function()
					return { country = "CA" }
				end,
			},
		})
		assert.is_true(vim.wait(1000, function()
			return called and server.closed == 1
		end))
		assert.is_nil(result)
		assert.are.equal("Location request cancelled.", request_error)
		assert.are.same({ country = "CA" }, whereami.get())
		assert.are.same({}, notifications)
	end)

	it("falls back asynchronously after an HTTP failure", function()
		server = server_helper.start("HTTP/1.1 429 Too Many Requests\r\nContent-Length: 2\r\n\r\n{}")
		whereami.setup({
			providers = {
				server.url,
				{
					fetch = function()
						return { country = "CA" }
					end,
				},
			},
		})

		vim.cmd("Whereami country")

		assert.is_true(vim.wait(1000, function()
			return #notifications == 1
		end))
		assert.are.equal("You are in 🇨🇦CA", notifications[1])
	end)

	it("refreshes an in-flight request without accepting its older response", function()
		local calls = 0
		whereami.setup({
			providers = {
				fetch = function()
					calls = calls + 1
					return { country = calls == 1 and "US" or "CA" }
				end,
			},
		})
		local old_error, fresh, callbacks = nil, nil, 0
		whereami.get(function(data, err)
			assert.is_nil(data)
			old_error = err
			callbacks = callbacks + 1
		end)
		whereami.refresh(function(data)
			fresh = data
			callbacks = callbacks + 1
		end)

		assert.is_true(vim.wait(1000, function()
			return callbacks == 2
		end))
		assert.are.equal("Location request cancelled.", old_error)
		assert.are.same({ country = "CA" }, fresh)
		assert.are.same(fresh, whereami.get())
		assert.are.equal(2, calls)
	end)

	it("does not deliver a cached response after the cache is cleared", function()
		whereami.setup({
			providers = {
				fetch = function()
					return { country = "US" }
				end,
			},
		})
		whereami.get()
		local called, result, request_error
		whereami.get(function(data, err)
			called, result, request_error = true, data, err
		end)
		whereami.clear_cache()

		assert.is_true(vim.wait(1000, function()
			return called
		end))
		assert.is_nil(result)
		assert.are.equal("Location request cancelled.", request_error)
	end)
end)
