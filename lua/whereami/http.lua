local M = {}
local uv = vim.uv or vim.loop

local function start_request(url, timeout, callback)
	local chunks = {}
	local finished, failed = false, false
	local job, timer

	local function close_timer()
		if timer and not timer:is_closing() then
			timer:stop()
			timer:close()
		end
	end

	local function cancel()
		if not finished then
			failed = true
			close_timer()
			if job then
				pcall(vim.fn.jobstop, job)
			end
		end
	end

	local function complete(code)
		if finished then
			return
		end
		finished = true
		close_timer()
		local response
		if code == 0 and not failed then
			local body, status = table.concat(chunks):match("^(.*)\n(%d%d%d)$")
			if status then
				response = { body = body, status = tonumber(status) }
			end
		end
		callback(response)
	end

	local ok, id = pcall(vim.fn.jobstart, {
		vim.g.plenary_curl_bin_path or "curl",
		"-q",
		"--silent",
		"--show-error",
		"--location",
		"--max-time",
		string.format("%.3f", timeout / 1000),
		"--write-out",
		"\n%{http_code}",
		"--url",
		url,
	}, {
		on_stdout = function(_, data)
			if not finished and not failed then
				table.insert(chunks, table.concat(data, "\n"))
			end
		end,
		-- curl errors include the full URL; expose only the plugin's generic errors.
		on_stderr = function() end,
		on_exit = function(_, code)
			complete(code)
		end,
	})
	if not ok or id <= 0 then
		complete(-1)
		return cancel
	end
	job = id
	timer = uv.new_timer()
	timer:start(timeout, 0, vim.schedule_wrap(cancel))
	return cancel
end

function M.get(url, opts, callback)
	local timeout = opts.timeout or 5000
	if callback then
		return start_request(url, timeout, callback)
	end

	local response, done
	local cancel = start_request(url, timeout, function(result)
		response, done = result, true
	end)
	if not vim.wait(timeout + 1000, function()
		return done
	end, 10) then
		cancel()
	end
	return response
end

return M
