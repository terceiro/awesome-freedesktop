-- Grab environment

local io = io
local table = table
local ipairs = ipairs

module("freedesktop.utils")

terminal = 'xterm'

icon_theme = nil

all_icon_sizes = { '16x16', '22x22', '24x24', '32x32', '36x36', '48x48', '64x64', '72x72', '96x96', '128x128' }

local function file_exists(filename)
    local file = io.open(filename, 'r')
    local result = (file ~= nil)
    if result then
        file:close()
    end
    return result
end

function lookup_icon(arg)
    if arg.icon:sub(1, 1) == '/' and (arg.icon:find('.+%.png') or arg.icon:find('.+%.xpm')) then
        -- icons with absolute path and supported (AFAICT) formats
        return arg.icon
    else
        local icon_path = {}
        local icon_theme_paths = {}
        if icon_theme then
            table.insert(icon_theme_paths, '/usr/share/icons/' .. icon_theme .. '/')
            -- TODO also look in parent icon themes, as in freedesktop.org specification
        end
        table.insert(icon_theme_paths, '/usr/share/icons/hicolor/') -- fallback theme cf spec

        for i, icon_theme_directory in ipairs(icon_theme_paths) do
            for j, size in ipairs(arg.icon_sizes or all_icon_sizes) do
                table.insert(icon_path, icon_theme_directory .. size .. '/apps/')
                table.insert(icon_path, icon_theme_directory .. size .. '/actions/')
                table.insert(icon_path, icon_theme_directory .. size .. '/devices/')
                table.insert(icon_path, icon_theme_directory .. size .. '/places/')
                table.insert(icon_path, icon_theme_directory .. size .. '/categories/')
                table.insert(icon_path, icon_theme_directory .. size .. '/status/')
            end
        end
        -- lowest priority fallbacks
        table.insert(icon_path,  '/usr/share/pixmaps/')
        table.insert(icon_path,  '/usr/share/icons/')

        for i, directory in ipairs(icon_path) do
            if (arg.icon:find('.+%.png') or arg.icon:find('.+%.xpm')) and file_exists(directory .. arg.icon) then
                return directory .. arg.icon
            elseif file_exists(directory .. arg.icon .. '.png') then
                return directory .. arg.icon .. '.png'
            elseif file_exists(directory .. arg.icon .. '.xpm') then
                return directory .. arg.icon .. '.xpm'
            end
        end
    end
end

--- Parse a .desktop file
-- @param file The .desktop file
-- @param requested_icon_sizes A list of icon sizes (optional). If this list is given, it will be used as a priority list for icon sizes when looking up for icons. If you want large icons, for example, you can put '128x128' as the first item in the list.
-- @return A table with file entries.
function parse(file, requested_icon_sizes)
    local program = { show = true, file = file }
    for line in io.lines(file) do
        for key, value in line:gmatch("(%w+)=(.+)") do
            program[key] = value
        end
    end

    -- Only show the program if there is not OnlyShowIn attribute
    -- or if it's equal to 'awesome'
    if program.OnlyShowIn ~= nil and program.OnlyShowIn ~= "awesome" then
        program.show = false
    end

    -- Look up for a icon.
    if program.Icon then
        program.icon_path = lookup_icon({ icon = program.Icon, icon_sizes = (requested_icon_sizes or all_icon_sizes) })
    end

    -- Split categories into a table.
    if program.Categories then
        program.categories = {}
        for category in program.Categories:gfind('[^;]+') do
            table.insert(program.categories, category)
        end
    end

    if program.Exec then
        local cmdline = program.Exec:gsub('%%c', program.Name)
        cmdline = cmdline:gsub('%%[fuFU]', '')
        cmdline = cmdline:gsub('%%k', program.file)
        if program.icon_path then
            cmdline = cmdline:gsub('%%i', '--icon ' .. program.icon_path)
        end
        if program.Terminal == "true" then
            cmdline = terminal .. ' -e ' .. cmdline
        end
        program.cmdline = cmdline
    end

    return program
end

--- Parse a directory with .desktop files
-- @param dir The directory.
-- @param icons_size, The icons sizes, optional.
-- @return A table with all .desktop entries.
function parse_dir(dir, icon_sizes)
    local programs = {}
    local files = io.popen('find '.. dir ..' -maxdepth 1 -name "*.desktop"'):lines()
    for file in files do
        table.insert(programs, parse(file, icon_sizes))
    end
    return programs
end
