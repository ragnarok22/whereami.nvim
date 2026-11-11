describe("health check notifications", function()
	local original_health, original_notify, original_module
	local messages

	before_each(function()
		original_health = vim.health
		original_notify = vim.notify
		original_module = package.loaded["whereami.health"]
		messages = {}
		vim.health = {
			start = function() end,
			ok = function(message)
				table.insert(messages, message)
			end,
			error = function(message)
				error(message)
			end,
		}
		package.loaded["whereami.health"] = nil
	end)

	after_each(function()
		vim.health = original_health
		vim.notify = original_notify
		package.loaded["whereami.health"] = original_module
	end)

	it("accepts the callable table used by nvim-notify", function()
		vim.notify = setmetatable({}, { __call = function() end })

		require("whereami.health").check()

		assert.are.equal("vim.notify is available as a callable table", messages[#messages])
	end)

	it("does not claim a Lua notification function is customized", function()
		require("whereami.health").check()

		assert.are.equal("vim.notify is available as a function", messages[#messages])
	end)
end)
