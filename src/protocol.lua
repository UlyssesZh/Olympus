return function(url, autoclose)
    if url:match("https?://") then
        return require("modinstaller").install(url, nil, nil, autoclose)
    end

    return false
end
