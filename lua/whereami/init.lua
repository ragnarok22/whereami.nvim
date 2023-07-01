local M = {}

M.whereami = function ()
    local handle = io.popen("curl -s ipconfig.io/country")
    if (handle ~= nil) then
        local response = handle:read("*a")
        handle:close()
        return response
    end
end

return M
