local providers = require("whereami.providers")

describe("provider data", function()
	it("preserves custom metadata while removing invalid location fields", function()
		local response = {
			ip = "203.0.113.10",
			country = { nested = "invalid" },
			city = "",
			org = string.rep("x", 1025),
			region = "New York",
			coordinates = { 40.7, -74.0 },
		}
		local data = providers.fetch({
			fetch = function()
				return response
			end,
		}, {})

		assert.are.same({
			ip = "203.0.113.10",
			region = "New York",
			coordinates = { 40.7, -74.0 },
		}, data)
		assert.are.same({ nested = "invalid" }, response.country)
	end)
end)
