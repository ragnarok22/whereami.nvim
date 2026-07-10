local function path_exists(path)
	local stat = (vim.uv or vim.loop).fs_stat(path)
	return stat and stat.type == "directory"
end

local function append_runtimepath(path)
	if path and path ~= "" and path_exists(path) then
		vim.opt.runtimepath:append(path)
	end
end

local root = vim.fn.getcwd()

append_runtimepath(root)
append_runtimepath(root .. "/lua")

-- Prefer an explicit checkout path in CI/local shells, then fall back to common
-- package-manager and repository-local dependency locations.
append_runtimepath(vim.env.PLENARY_NVIM_PATH)
append_runtimepath(root .. "/.deps/plenary.nvim")
append_runtimepath(root .. "/deps/plenary.nvim")
append_runtimepath(root .. "/tests/deps/plenary.nvim")
append_runtimepath(vim.fn.stdpath("data") .. "/lazy/plenary.nvim")
append_runtimepath(vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim")
