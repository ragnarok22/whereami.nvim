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
    desc = "Location where the current location was originated from.",
    nargs = 0,
})

return M
