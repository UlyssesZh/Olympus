return function(url, autoclose)
    if url:match("https?://") then
        -- the URL is like: https://gamebanana.com/mmdl/1414214,Mod,424541
        -- and we need to truncate it
        local endIndex = url:find(',')
        if endIndex then
            url = url:sub(1, endIndex - 1)
        end

        return require("modinstaller").install(url, nil, nil, autoclose)
    end

    return false
end
