local M = {}

function M.get(url, opts)
	return require("plenary.curl").get(url, {
		timeout = opts.timeout,
		-- Plenary invokes this from a libuv callback, outside the caller's pcall.
		-- Never forward its error message: it includes the complete provider URL.
		on_error = function() end,
	})
end

return M
