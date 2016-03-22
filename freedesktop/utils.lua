-- -*- lua-indent-level: 4; indent-tabs-mode: nil -*-
-- Grab environment

local io = io
local os = os
local table = table
local type = type
local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber
local dirs = require("freedesktop.dirs")

module("freedesktop.utils")

terminal = 'xterm'

icon_theme = nil

all_icon_sizes = {
    '128',
    '96',
    '72',
    '64',
    '48',
    '36',
    '32',
    '24',
    '22',
    '16'
}
all_icon_types = {
    'apps',
    'actions',
    'devices',
    'places',
    'categories',
    'status',
    'mimetypes'
}
all_icon_paths = {}
local icon_theme_data = nil

local mime_types = {}

local function _init_all_icon_paths()
    for _,dir in ipairs({ os.getenv("HOME") .. '/.icons/',
                          dirs.xdg_data_home() .. 'icons/'}) do
        if directory_exists(dir) then
            table.insert(all_icon_paths, dir)
        end
    end
    for _,dir in ipairs(dirs.xdg_data_dirs()) do
        if directory_exists(dir .. 'icons/') then
            table.insert(all_icon_paths, dir .. 'icons/')
        end
    end
end

function get_lines(...)
    local f = io.popen(...)
    return function () -- iterator
        local data = f:read()
        if data == nil then f:close() end
        return data
    end
end

function directory_exists(filename)
    local file = io.open(filename)
    local result = (file ~= nil)
    if result then
        local a,b,c = file:read(0)
        file:close()
        result = (c == 21)
    end
    return result
end

function file_exists(filename)
    local file = io.open(filename, 'r')
    local result = (file ~= nil)
    if result then
        file:close()
    end
    return result
end

function string_split(string, separator)
    local separator, fields = separator or ":", {}
    local pattern = string.format("([^%s]+)", separator)
    string:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function lookup_icon(arg)
    if arg.icon:sub(1, 1) == '/' and (arg.icon:find('.+%.png') or arg.icon:find('.+%.xpm')) then
        -- icons with absolute path and supported (AFAICT) formats
        return arg.icon
    else
        -- scan theme directories if no cached theme data found
        if not icon_theme_data then
            local initial_themes = {}
            if icon_theme and type(icon_theme) == 'table' then
                for k,v in pairs(icon_theme) do
                    initial_themes[k] = v
                end
            elseif icon_theme then
                initial_themes = { icon_theme }
            end
            local has_hicolor = false
            for i, theme in ipairs(initial_themes) do
                if (theme == 'hicolor') then
                    has_hicolor = true
                    break
                end
            end
            if not has_hicolor then
                table.insert(initial_themes, 'hicolor')
            end
            icon_theme_data = scan_theme_data(initial_themes)
        end

        local icon_themes = {}
        if arg.icon_themes then
            if type(arg.icon_themes) ~= 'table' then
                arg.icon_themes = { arg.icon_themes }
            end
            icon_themes = arg.icon_themes
        else
            icon_themes = icon_theme_data.themes.ordered
        end

        local icon_sizes
        if arg.icon_sizes then
            if type(arg.icon_sizes) ~= 'table' then
                arg.icon_sizes = { arg.icon_sizes }
            end
            for j, icon_size in ipairs(arg.icon_sizes) do
                local size
                -- support old NNxNN format
                icon_size:gsub('^(%d+)x(%d+)$', function(s1, s2)
                    if s1 == s2 then
                        size = s1
                    end
                end)
                if not size then
                    size = icon_size
                end
                if not icon_sizes then
                    icon_sizes = {}
                end
                table.insert(icon_sizes, size)
            end
        end

        local icon_path = {}
        for i, theme in ipairs(icon_themes) do
            local sizes
            if icon_sizes then
                sizes = icon_sizes
            elseif icon_theme_data.sizes.ordered[theme] then
                sizes = icon_theme_data.sizes.ordered[theme]
            end
            if icon_theme_data.paths[theme] and sizes then
                for j, size in ipairs(sizes) do
                    if icon_theme_data.paths[theme][size] then
                        for k, path in ipairs(icon_theme_data.paths[theme][size]) do
                            table.insert(icon_path, path)
                        end
                    end
                end
            end
        end
        -- lowest priority fallback
        table.insert(icon_path,  '/usr/share/pixmaps/')

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

function lookup_file_icon(arg)
    load_mime_types()

    local extension = arg.filename:match('%a+$')
    local mime = mime_types[extension] or ''
    local mime_family = mime:match('^%a+') or ''

    -- possible icons in a typical gnome theme (i.e. Tango icons)
    local possible_filenames = {
        mime,
        'gnome-mime-' .. mime,
        mime_family,
        'gnome-mime-' .. mime_family,
        extension
    }

    for i, filename in ipairs(possible_filenames) do
        local icon = lookup_icon({icon = filename, icon_sizes = (arg.icon_sizes or all_icon_sizes)})
        if icon then
            return icon
        end
    end

    -- If we don't find ad icon, then pretend is a plain text file
    return lookup_icon({ icon = 'txt', icon_sizes = arg.icon_sizes or all_icon_sizes })
end

--- Load system MIME types
-- @return A table with file extension <--> MIME type mapping
function load_mime_types()
    if #mime_types == 0 then
        for line in io.lines('/etc/mime.types') do
            if not line:find('^#') then
                local parsed = {}
                for w in line:gmatch('[^%s]+') do
                    table.insert(parsed, w)
                end
                if #parsed > 1 then 
                    for i = 2, #parsed do
                        mime_types[parsed[i]] = parsed[1]:gsub('/', '-')
                    end
                end
            end
        end
    end
end

--- Parse a .desktop file
-- @param file The .desktop file
-- @param requested_icon_sizes A list of icon sizes (optional). If this list is given, it will be used as a priority list for icon sizes when looking up for icons. If you want large icons, for example, you can put '128' as the first item in the list.
-- @return A table with file entries.
function parse_desktop_file(arg)
    local program = { show = true, file = arg.file }
    local file_data = parse_sectioned_file(arg)
    if file_data['Desktop Entry'] then
        for key in pairs(file_data['Desktop Entry']) do
            program[key] = file_data['Desktop Entry'][key]
        end
    end

    -- Don't show the program if NoDisplay is true
    -- Only show the program if there is not OnlyShowIn attribute
    -- or if it's equal to 'awesome'
    if program.NoDisplay == "true" or program.OnlyShowIn ~= nil and program.OnlyShowIn ~= "awesome" then
        program.show = false
    end

    -- Look up for a icon.
    if program.Icon then
        program.icon_path = lookup_icon({ icon = program.Icon, icon_sizes = (arg.icon_sizes or all_icon_sizes) })
        if program.icon_path ~= nil and not file_exists(program.icon_path) then
           program.icon_path = nil
        end
    end

    -- Split categories into a table.
    if program.Categories then
        program.categories = {}
        for category in program.Categories:gmatch('[^;]+') do
            table.insert(program.categories, category)
        end
    end

    if program.Exec then
        local cmdline = program.Exec:gsub('%%c', program.Name)
        cmdline = cmdline:gsub('%%[fmuFMU]', '')
        cmdline = cmdline:gsub('%%k', program.file)
        if program.icon_path then
            cmdline = cmdline:gsub('%%i', '--icon ' .. program.icon_path)
        else
            cmdline = cmdline:gsub('%%i', '')
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
function parse_desktop_files(arg)
    local programs = {}
    local files = get_lines('find '.. arg.dir ..' -name "*.desktop" 2>/dev/null')
    for file in files do
        arg.file = file
        table.insert(programs, parse_desktop_file(arg))
    end
    return programs
end

--- Parse a directory files and subdirs
-- @param dir The directory.
-- @param icons_size, The icons sizes, optional.
-- @return A table with all .desktop entries.
function parse_dirs_and_files(arg)
    local files = {}
    local paths = get_lines('find '..arg.dir..' -maxdepth 1 -type d')
    for path in paths do
        if path:match("[^/]+$") then
            local file = {}
            file.filename = path:match("[^/]+$")
            file.path = path
            file.show = true
            file.icon = lookup_icon({ icon = "folder", icon_sizes = (arg.icon_sizes or all_icon_sizes) })
            table.insert(files, file)
        end
    end
    local paths = get_lines('find '..arg.dir..' -maxdepth 1 -type f')
    for path in paths do
        if not path:find("%.desktop$") then
            local file = {}
            file.filename = path:match("[^/]+$")
            file.path = path
            file.show = true
            file.icon = lookup_file_icon({ filename = file.filename, icon_sizes = (arg.icon_sizes or all_icon_sizes) })
            table.insert(files, file)
        end
    end
    return files
end

function parse_theme_index_file(arg)
    local theme_index = { inherits = nil, sizes = {}, paths = {} }
    local file_data = parse_sectioned_file(arg)
    local paths
    if file_data['Icon Theme'] then
        if file_data['Icon Theme']['Inherits'] then
            theme_index.inherits = string_split(file_data['Icon Theme']['Inherits'], "%s*,%s*")
        end
        if file_data['Icon Theme']['Directories'] then
            paths = string_split(file_data['Icon Theme']['Directories'], "%s*,%s*")
        end
    end
    if paths then
        local sizes = {}
        for i, path in ipairs(paths) do
            if file_data[path] and file_data[path]['Size'] then
                local type = file_data[path]['Type']
                if (not type or type:lower() == 'threshold' or type:lower() == 'fixed') then
                    local size = file_data[path]['Size']
                    if not theme_index.paths[size] then
                        theme_index.paths[size] = {}
                    end
                    if not sizes[size] then
                        table.insert(theme_index.sizes, size)
                        sizes[size] = true
                    end
                    table.insert(theme_index.paths[size], path)
                end
            end
        end
        table.sort(theme_index.sizes, function(a, b)
            return tonumber(a) > tonumber(b)
        end)
    end
    return theme_index
end

function parse_sectioned_file(arg)
    local data = {}
    local current_section
    for line in io.lines(arg.file) do
        line:gsub("^%s*%[([^%]]+)%]%s*$", function(section)
            current_section = section
            data[section] = {}
        end)
        line:gsub("^%s*(%w+)%s*=%s*(.+)%s*$", function(key, value)
            if current_section then
                data[current_section][key] = value
            end
        end)
    end
    return data
end

function scan_theme_data(icon_themes, theme_data)
    if not theme_data then
        theme_data = {}
    end
    for i, theme in ipairs(icon_themes) do
        if not theme_data.themes then
            theme_data.themes = { ordered = {}, lookup = {} }
        end
        if not theme_data.sizes then
            theme_data.sizes = { ordered = {}, lookup = {} }
        end
        if not theme_data.paths then
            theme_data.paths = {}
        end
        if theme_data.themes.lookup[theme] then
            return theme_data
        end
        if not theme_data.themes.lookup[theme] then
            theme_data.themes.lookup[theme] = true
            table.insert(theme_data.themes.ordered, theme)
            for j, icon_path in ipairs(all_icon_paths) do
                local theme_path = icon_path .. theme
                if directory_exists(theme_path) then
                    local theme_index_file = theme_path .. '/index.theme'
                    local sizes, paths, inherited_themes
                    if file_exists(theme_index_file) then
                        local theme_index = parse_theme_index_file({ file = theme_index_file })
                        sizes = theme_index.sizes
                        paths = theme_index.paths
                        if theme_index.inherits then
                            inherited_themes = theme_index.inherits
                        end
                    else
                        sizes, paths = find_all_icon_paths(theme_path)
                    end
                    if sizes and paths then
                        for k, size in ipairs(sizes) do
                            if not theme_data.sizes.lookup[theme] then
                                theme_data.sizes.lookup[theme] = {}
                            end
                            if not theme_data.sizes.lookup[theme][size] then
                                theme_data.sizes.lookup[theme][size] = true
                                if not theme_data.sizes.ordered[theme] then
                                    theme_data.sizes.ordered[theme] = {}
                                end
                                table.insert(theme_data.sizes.ordered[theme], size)
                            end
                            for l, path in ipairs(paths[size]) do
                                if not theme_data.paths[theme] then
                                    theme_data.paths[theme] = {}
                                end
                                if not theme_data.paths[theme][size] then
                                    theme_data.paths[theme][size] = {}
                                end
                                table.insert(theme_data.paths[theme][size], theme_path .. '/' .. path .. '/')
                            end
                        end
                    end
                    if inherited_themes then
                        theme_data = scan_theme_data(inherited_themes, theme_data)
                    end
                end
            end
        end
    end
    return theme_data
end

function find_all_icon_paths(icon_theme_directory)
    local sizes = {}
    local paths = {}
    for i, size in ipairs(all_icon_sizes) do
        local size_dir = size .. 'x' .. size
        local size_path = icon_theme_directory .. '/' .. size_dir
        if directory_exists(size_path) then
            for j, icon_type in ipairs(all_icon_types) do
                local icon_dir = size_dir .. '/' .. icon_type
                local icon_path = icon_theme_directory .. '/' .. icon_dir
                if directory_exists(icon_path) then
                    if not paths[size] then
                        paths[size] = {}
                    end
                    table.insert(sizes, size)
                    table.insert(paths[size], icon_dir .. '/')
                end
            end
        end
    end
    return sizes, paths
end

_init_all_icon_paths()
