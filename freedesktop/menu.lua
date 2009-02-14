-- Grab environment
local utils = require("freedesktop.utils")
local io = io
local string = string
local table = table
local os = os

module("freedesktop.menu", package.seeall)

-- the categories and their synonims where shamelessly copied from lxpanel
-- source code.

root_menu = {}
known = {}
synonims = {}

known["Other"] = true

known["Games"] = true
synonims["Game"] = "Games"
synonims["Amusement"] = "Games"

known["Education"] = true
synonims["Education"] = "Education"

known["Development"] = true
synonims["Development"] = "Development"
synonims["Translation"] = "Development"
synonims["Building"] = "Development"
synonims["Debugger"] = "Development"
synonims["IDE"] = "Development"
synonims["GUIDesigner"] = "Development"
synonims["Profiling"] = "Development"
synonims["RevisionControl"] = "Development"
synonims["WebDevelopment"] = "Development"

known["Multimedia"] = true
synonims["AudioVideo"] = "Multimedia"
synonims["Audio"] = "Multimedia"
synonims["Video"] = "Multimedia"
synonims["Mixer"] = "Multimedia"
synonims["Sequencer"] = "Multimedia"
synonims["Tuner"] = "Multimedia"
synonims["TV"] = "Multimedia"
synonims["AudioVideoEditing"] = "Multimedia"
synonims["Player"] = "Multimedia"
synonims["Recorder"] = "Multimedia"
synonims["DiscBurning"] = "Multimedia"
synonims["Music"] = "Multimedia"

known["Graphics"] = true
synonims["Graphics"] = "Graphics"
synonims["VectorGraphics"] = "Graphics"
synonims["RasterGraphics"] = "Graphics"
synonims["Viewer"] = "Graphics"
synonims["2DGraphics"] = "Graphics"
synonims["3DGraphics"] = "Graphics"

known["Settings"] = true
synonims["Settings"] = "Settings"
synonims["DesktopSettings"] = "Settings"
synonims["HardwareSettings"] = "Settings"
synonims["Accessibility"] = "Settings"

known["System-Tools"] = true
synonims["System"] = "System-Tools"
synonims["Core"] = "System-Tools"
synonims["Security"] = "System-Tools"
synonims["PackageManager"] = "System-Tools"

known["Internet"] = true
synonims["Network"] = "Internet"
synonims["Dialup"] = "Internet"
synonims["Email"] = "Internet"
synonims["WebBrowser"] = "Internet"
synonims["InstantMessaging"] = "Internet"
synonims["IRCClient"] = "Internet"
synonims["FileTransfer"] = "Internet"
synonims["News"] = "Internet"
synonims["P2P"] = "Internet"
synonims["RemoteAccess"] = "Internet"
synonims["Telephony"] = "Internet"

known["Office"] = true
synonims["Office"] = "Office"
synonims["Dictionary"] = "Office"
synonims["Chart"] = "Office"
synonims["Calendar"] = "Office"
synonims["ContactManagement"] = "Office"
synonims["Database"] = "Office"

known["Accessories"] = true
synonims["Utility"] = "Accessories"

for i, program in ipairs(utils.parse('/usr/share/applications/'))    do

    -- check whether to include in the menu
    if program.show and program.name and program.cmdline then
        local target_category = nil
        if program.categories then
            for category in string.gfind(program.categories, '[^;]+') do
                if known[category] then
                    target_category = category
                else
                    if synonims[category] then
                        target_category = synonims[category]
                    end
                end
            end
        else
            target_category = 'Other'
        end
        if known[target_category] then
            if not root_menu[target_category] then
                root_menu[target_category] = {}
            end

            table.insert(root_menu[target_category], { program.name, cmdline, program.icon })
        end
    end

end

root_menu = {
    { "Accessories", root_menu["Accessories"], '/usr/share/icons/gnome/16x16/categories/applications-accessories.png' },
    { "Development", root_menu["Development"], '/usr/share/icons/gnome/16x16/categories/applications-development.png' },
    { "Education", root_menu["Education"], '/usr/share/icons/gnome/16x16/categories/applications-science.png' },
    { "Games", root_menu["Games"], '/usr/share/icons/gnome/16x16/categories/applications-games.png' },
    { "Graphics", root_menu["Graphics"], '/usr/share/icons/gnome/16x16/categories/applications-graphics.png' },
    { "Internet", root_menu["Internet"], '/usr/share/icons/gnome/16x16/categories/applications-internet.png' },
    { "Multimedia", root_menu["Multimedia"], '/usr/share/icons/gnome/16x16/categories/applications-multimedia.png' },
    { "Office", root_menu["Office"], '/usr/share/icons/gnome/16x16/categories/applications-office.png' },
    { "Other", root_menu["Other"], '/usr/share/icons/gnome/16x16/categories/applications-other.png' },
    { "Settings", root_menu["Settings"], '/usr/share/icons/gnome/16x16/categories/applications-utilities.png' },
    { "System Tools", root_menu["System-Tools"], '/usr/share/icons/gnome/16x16/categories/applications-system.png' },
}

