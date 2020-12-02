local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local scener = require("scener")
local alert = require("alert")
local notify = require("notify")
local config = require("config")
local sharp = require("sharp")

local scene = {
    name = "Main Menu"
}


local function buttonBig(icon, text, scene)
    return uie.button(
        uie.row({
            uie.icon(icon):with({ scale = 48 / 256 }),
            uie.label(text, ui.fontBig):with({ x = -4, y = 11 })
        }):with({ style = { bg = {}, padding = 0, spacing = 16 } }),
        type(scene) == "function" and scene or function()
            scener.push(scene)
        end
    ):with({ style = { padding = 8 } }):with(uiu.fillWidth(4))
end

local function button(icon, text, scene)
    return uie.button(
        uie.row({
            uie.icon(icon):with({ scale = 24 / 256 }),
            uie.label(text):with({ y = 2 })
        }):with({ style = { bg = {}, padding = 0 } }),
        type(scene) == "function" and scene or function()
            scener.push(scene)
        end
    ):with({ style = { padding = 8 } }):with(uiu.fillWidth(4))
end


function scene.createInstalls()
    return uie.column({
        uie.label("Your Installations", ui.fontBig),

        uie.column({

            uie.scrollbox(
                uie.list({}, function(self, data)
                    config.install = data.index
                    config.save()
                end):with({
                    grow = false
                }):with(uiu.fillWidth):as("installs")
            ):with(uiu.fillWidth):with(uiu.fillHeight),

            uie.button("Manage", function()
                scener.push("installmanager")
            end):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound):with(uiu.rightbound):as("manageInstalls")

        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false
        }):with(uiu.fillWidth):with(uiu.fillHeight(true))
    }):with(uiu.fillHeight)
end


function scene.reloadInstalls(scene, cb)
    local list = scene.root:findChild("installs")
    list.children = {}

    local installs = config.installs or {}
    for i = 1, #installs do
        local entry = installs[i]
        local item = uie.listItem({{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\nScanning..."}, { index = i, entry = entry, version = "???" })

        sharp.getVersionString(entry.path):calls(function(t, version)
            version = version or "???"

            local celeste = version:match("Celeste ([^ ]+)")
            local everest = version:match("Everest ([^ ]+)")
            if everest then
                version = celeste .. " + " .. everest

            else
                version = celeste or version
            end

            item.text = {{1, 1, 1, 1}, entry.name, {1, 1, 1, 0.5}, "\n" .. version}
            item.data.version = version
            item.data.versionCeleste = celeste
            item.data.versionEverest = everest
            if cb and item.data.index == config.install then
                cb(item.data)
            end
        end)

        list:addChild(item)
    end

    if #installs == 0 then
        list:addChild(uie.group({
            uie.label([[
No installations found.
Press the manage button.]])
        }):with({
            style = {
                padding = 8
            }
        }))
    end

    list.selected = list.children[config.install or 1] or list.children[1]
    list:reflow()

    if cb then
        cb()
    end
end


local root = uie.column({
    uie.image("header_olympus"),

    uie.row({

        scene.createInstalls(),

        uie.column({
            buttonBig("mainmenu/everest", "Install Everest (Mod Loader)", "everest"):as("installbtn"),
            button("mainmenu/gamebanana", "Download Mods From GameBanana", "gamebanana"),
            button("mainmenu/berry", "Manage Installed Mods", "modlist"),
            button("mainmenu/ahorn", "Install Ahorn (Map Editor)", function()
                alert([[
Olympus is currently unable to install Ahorn.
Please go to the Ahorn GitHub page for installation instructions.
This will probably be implemented in a future update.]])
                -- notify("OOPS.")
            end),
            button("cogwheel", "Options", "options"),
            button("cogwheel", "[DEBUG] Scene List", "scenelist"),
        }):with({
            style = {
                padding = 0,
                bg = {}
            },
            clip = false
        }):with(uiu.fillWidth(true)):with(uiu.fillHeight):as("mainlist")

    }):with({
        style = {
            padding = 0,
            bg = {}
        }
    }):with(uiu.fillWidth):with(uiu.fillHeight(true)),

})
scene.root = root


scene.installs = root:findChild("installs")
scene.mainlist = root:findChild("mainlist")
scene.launchrow = uie.row({
    uie.group({
        buttonBig("mainmenu/everest", "Celeste + Everest", function()
            sharp.launch(config.installs[config.install].path)
            alert([[
Everest is now starting in the background.
You can close this window.]])
        end)
    }):with(uiu.fillWidth(2.5 + 36)):with(uiu.at(0, 0)),
    uie.group({
        buttonBig("mainmenu/celeste", "Celeste", function()
            sharp.launch(config.installs[config.install].path, "--vanilla")
            alert([[
Celeste is now starting in the background.
You can close this window.]])
        end)
    }):with(uiu.fillWidth(2.5 + 36)):with(uiu.at(2.5 - 36, 0)),
    uie.group({
        buttonBig("cogwheel", "", "everest")
    }):with({
        width = 64 + 4
    }):with(uiu.rightbound)
}):with({
    activated = false,
    style = {
        bg = {},
        padding = 0,
        radius = 0
    },
    clip = false,
    cacheable = false
}):with(uiu.fillWidth):as("launchrow")
scene.installbtn = root:findChild("installbtn")

scene.installs:hook({
    cb = function(orig, self, data)
        orig(self, data)
        scene.updateMainList(data)
    end
})


function scene.updateMainList(install)
    if scene.launchrow.parent then
        scene.launchrow:removeSelf()
    end
    if scene.installbtn.parent then
        scene.installbtn:removeSelf()
    end

    if install and install.versionEverest then
        scene.mainlist:addChild(scene.launchrow, 1)
    else
        scene.mainlist:addChild(scene.installbtn, 1)
    end
end


function scene.load()
end


function scene.enter()
    scene.reloadInstalls(scene, scene.updateMainList)

end


return scene
