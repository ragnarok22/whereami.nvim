local uv = vim.uv or vim.loop
local M = {}

function M.start(response)
	local listener = uv.new_tcp()
	assert(listener:bind("127.0.0.1", 0))
	local clients = {}
	local server = { closed = 0 }

	local function close(client)
		if not client:is_closing() then
			client:read_stop()
			client:close()
			clients[client] = nil
			server.closed = server.closed + 1
		end
	end

	assert(listener:listen(16, function(err)
		assert(not err, err)
		local client = uv.new_tcp()
		assert(listener:accept(client))
		clients[client] = true
		local received = false
		client:read_start(function(read_err, data)
			if read_err or not data then
				close(client)
			elseif not received then
				received = true
				if response ~= false then
					client:write(response, function()
						if not client:is_closing() then
							client:shutdown(function()
								close(client)
							end)
						end
					end)
				end
			end
		end)
	end))
	server.url = "http://127.0.0.1:" .. listener:getsockname().port .. "/json"
	function server.close()
		if not listener:is_closing() then
			listener:close()
		end
		for client in pairs(clients) do
			close(client)
		end
	end
	return server
end

return M
