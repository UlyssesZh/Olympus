local config = require("config")
local log = require('logger')('lang')
local utils = require('utils')

local langs = {
    en = require("lang/en"),
    fr = require("lang/fr"),
    zh = require("lang/zh"),
    ko = require("lang/ko")
}

local function get(key)
    return langs[config.language].keys[key] or langs["en"].keys[key] or ('[' .. key .. ']')
end

local function getCJKFontPriority()
    return langs[config.language].cjk_priority() or langs["en"].cjk_priority()
end


local function updateSharp()
    local sharp = require("sharp")
    local csharp_keys = {}
    for _, lang in pairs(langs) do
        for key, _ in pairs(lang.keys) do
            if key:find("^csharp_") ~= nil then
                csharp_keys[key] = true
            end
        end
    end
    for key, _ in pairs(csharp_keys) do
        csharp_keys[key] = get(key)
    end
    if sharp.setLanguageMap(utils.toJSON(csharp_keys)):result() ~= "ok" then
        log.error("Couldn't update the sharp language map! Things might go badly.")
    end
end

return {
    get = get,
    updateSharp = updateSharp,
    getCJKFontPriority = getCJKFontPriority
}
