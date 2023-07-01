local M = {}

M.whereami = function ()
    local handle = io.popen("curl -s ipconfig.io/country")
    if (handle ~= nil) then
        local response = handle:read("*a")
        handle:close()
        print(response)
        return response
    end
    print("Connection error")
end

vim.api.nvim_create_user_command("Whereami", "lua require('whereami').whereami()", {
    desc = "Where your Internet Provider is",
    nargs = 0,
})

return M
