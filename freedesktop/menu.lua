-- Grab environment
local utils = require("freedesktop.utils")
local io = io
local string = string
local table = table
local os = os

module("freedesktop.menu", package.seeall)

-- the categories and their synonims where shamelessly copied from lxpanel
-- source code.

programs = {}
programs['AudioVideo'] = {}
programs['Audio'] = {}
programs['Video'] = {}
programs['Development'] = {}
programs['Education'] = {}
programs['Game'] = {}
programs['Graphics'] = {}
programs['Network'] = {}
programs['Office'] = {}
programs['Settings'] = {}
programs['System'] = {}
programs['Utility'] = {}
programs['Other'] = {}

for i, program in ipairs(utils.parse('/usr/share/applications/'))    do

    -- check whether to include in the menu
    if program.show and program.name and program.cmdline then
        local target_category = nil
        if program.categories then
            for category in string.gfind(program.categories, '[^;]+') do
                if programs[category] then
                    target_category = category
                end
            end
        else
            target_category = 'Other'
        end
        if target_category then
            table.insert(programs[target_category], { program.name, program.cmdline, program.icon })
        end
    end

end

applications_menu = {
    { "Accessories", programs["Utility"], freedesktop.utils.lookup_icon('applications-accessories.png') },
    { "Development", programs["Development"], freedesktop.utils.lookup_icon('applications-development.png') },
    { "Education", programs["Education"], freedesktop.utils.lookup_icon('applications-science.png') },
    { "Games", programs["Game"], freedesktop.utils.lookup_icon('applications-games.png') },
    { "Graphics", programs["Graphics"], freedesktop.utils.lookup_icon('applications-graphics.png') },
    { "Internet", programs["Network"], freedesktop.utils.lookup_icon('applications-internet.png') },
    { "Multimedia", programs["AudioVideo"], freedesktop.utils.lookup_icon('applications-multimedia.png') },
    { "Office", programs["Office"], freedesktop.utils.lookup_icon('applications-office.png') },
    { "Other", programs["Other"], freedesktop.utils.lookup_icon('applications-other.png') },
    { "Settings", programs["Settings"], freedesktop.utils.lookup_icon('applications-utilities.png') },
    { "System Tools", programs["System"], freedesktop.utils.lookup_icon('applications-system.png') },
}

