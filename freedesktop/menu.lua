-- Grab environment
local utils = require("freedesktop.utils")
local io = io
local string = string
local table = table
local os = os

module("freedesktop.menu", package.seeall)

-- the categories and their synonyms where shamelessly copied from lxpanel
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

for i, program in ipairs(utils.parse_dir('/usr/share/applications/')) do

    -- check whether to include in the menu
    if program.show and program.Name and program.cmdline then
        local target_category = nil
        if program.Categories then
            for category in string.gfind(program.Categories, '[^;]+') do
                if programs[category] then
                    target_category = category
                end
            end
        else
            target_category = 'Other'
        end
        if target_category then
            table.insert(programs[target_category], { program.Name, program.cmdline, program.icon })
        end
    end

end

applications_menu = {
    { "Accessories", programs["Utility"], utils.lookup_icon({ icon = 'applications-accessories.png' }) },
    { "Development", programs["Development"], utils.lookup_icon({ icon = 'applications-development.png' }) },
    { "Education", programs["Education"], utils.lookup_icon({ icon = 'applications-science.png' }) },
    { "Games", programs["Game"], utils.lookup_icon({ icon = 'applications-games.png' }) },
    { "Graphics", programs["Graphics"], utils.lookup_icon({ icon = 'applications-graphics.png' }) },
    { "Internet", programs["Network"], utils.lookup_icon({ icon = 'applications-internet.png' }) },
    { "Multimedia", programs["AudioVideo"], utils.lookup_icon({ icon = 'applications-multimedia.png' }) },
    { "Office", programs["Office"], utils.lookup_icon({ icon = 'applications-office.png' }) },
    { "Other", programs["Other"], utils.lookup_icon({ icon = 'applications-other.png' }) },
    { "Settings", programs["Settings"], utils.lookup_icon({ icon = 'applications-utilities.png' }) },
    { "System Tools", programs["System"], utils.lookup_icon({ icon = 'applications-system.png' }) },
}

