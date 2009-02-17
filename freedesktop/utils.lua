-- Grab environment

local io = io
local string = string
local table = table
local os = os

module("freedesktop.utils", package.seeall)

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
    if string.sub(arg.icon, 1, 1) == '/' and (string.find(arg.icon, '.+%.png') or string.find(arg.icon, '.+%.xpm')) then
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
            if (string.find(arg.icon, '.+%.png') or string.find(arg.icon, '.+%.xpm')) and file_exists(directory .. arg.icon) then
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
-- @param icons_size, The icons sizes, optional.
-- @return A table with file entries.
function parse(file, icons_sizes)
    local program = { show = true, file = file }
    for line in io.lines(file) do
        -- command line
        if string.sub(line, 1, 5) == 'Exec=' then
            program.exec = string.sub(line, 6, -1)
        end

        -- categories
        if string.sub(line, 1, 11) == 'Categories=' then
            program.categories = string.sub(line, 12, -1)
        end

        -- program name
        if string.sub(line, 1, 5) == 'Name=' then
            program.name = string.sub(line, 6, -1)
        end

        -- wheter to show the program or not
        if string.sub(line, 1, 11) == 'OnlyShowIn=' then
            program.show = false
            for desktop in string.gfind(line, '[^;]+') do
                if string.lower(desktop) == 'awesome' then
                    program.show = true
                end
            end
        end

        -- detect program icon
        if string.sub(line, 1, 5) == 'Icon=' then
            local icon = string.sub(line, 6, -1)
            program.icon = lookup_icon({ icon = icon, icon_sizes = icon_sizes or all_icon_sizes })
        end

        -- detect programas that need a terminal
        if line == 'Terminal=true' then
            program.needs_terminal = true
        end
    end

    if program.exec then
        local cmdline = string.gsub(program.exec, '%%c', program.name)
        cmdline = string.gsub(cmdline, '%%[fuFU]', '')
        cmdline = string.gsub(cmdline, '%%k', program.file)
        if program.icon then
            cmdline = string.gsub(cmdline, '%%i', '--icon ' .. program.icon)
        end
        if program.needs_terminal then
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
