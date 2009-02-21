-- Grab environment

local io = io
local table = table
local ipairs = ipairs

module("freedesktop.utils")

terminal = 'xterm'

icon_theme = nil

all_icon_sizes = { '16x16', '22x22', '24x24', '32x32', '36x36', '48x48', '64x64', '72x72', '96x96', '128x128' }

local mime_types = {}

function file_exists(filename)
    local file = io.open(filename, 'r')
    local result = (file ~= nil)
    if result then
        file:close()
    end
    return result
end

function lookup_application_icon(arg)
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

function lookup_directory_icon(arg)
    local icon_path = {}
    local icon_theme_paths = {}
    if icon_theme then
        table.insert(icon_theme_paths, '/usr/share/icons/' .. icon_theme .. '/')
        -- TODO also look in parent icon themes, as in freedesktop.org specification
    end
    table.insert(icon_theme_paths, '/usr/share/icons/hicolor/') -- fallback theme cf spec

    for i, icon_theme_directory in ipairs(icon_theme_paths) do
        for j, size in ipairs(arg.icon_sizes or all_icon_sizes) do
            table.insert(icon_path, icon_theme_directory .. size .. '/places/')
        end
    end

    for i, directory in ipairs(icon_path) do
        local filepath_png = directory .. arg.type .. '.png'
        local filepath_xpm = directory .. arg.type .. '.xpm'
        if (file_exists(filepath_png)) then return filepath_png end
        if (file_exists(filepath_xpm)) then return filepath_xpm end
    end

    if type ~= 'folder' then
        return lookup_directory_icon({ 
            type = 'folder', 
            icon_sizes = arg.icon_sizes or all_icon_sizes
        })
    end
end

function lookup_file_icon(arg)
    load_mime_types()

    local extension = arg.filename:match('%a+$')
    local mime = mime_types[extension] or ''
    local mime_family = mime:match('^%a+') or ''

    local icon_path = {}
    local icon_theme_paths = {}
    if icon_theme then
        table.insert(icon_theme_paths, '/usr/share/icons/' .. icon_theme .. '/')
        -- TODO also look in parent icon themes, as in freedesktop.org specification
    end
    table.insert(icon_theme_paths, '/usr/share/icons/hicolor/') -- fallback theme cf spec

    for i, icon_theme_directory in ipairs(icon_theme_paths) do
        for j, size in ipairs(arg.icon_sizes or all_icon_sizes) do
            table.insert(icon_path, icon_theme_directory .. size .. '/mimetypes/')
        end
    end

    for i, directory in ipairs(icon_path) do

        -- possible icons in a typical gnome theme (i.e. Tango icons)
        local possible_filenames = { 
            mime,
            'gnome-mime-' .. mime,
            mime_family,
            'gnome-mime-' .. mime_family,
            extension
        }

        for i, filename in ipairs(possible_filenames) do
            local filepath_png = directory .. filename .. '.png'
            local filepath_xpm = directory .. filename .. '.xpm'
            if (file_exists(filepath_png)) then return filepath_png end
            if (file_exists(filepath_xpm)) then return filepath_xpm end
        end
    end

    -- If we don't find ad icon, then pretend is a plain text file
    if extension ~= 'txt' then
        return lookup_file_icon({ 
            filename = 'dummy.txt', 
            icon_sizes = arg.icon_sizes or all_icon_sizes
        })
    end

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
-- @param requested_icon_sizes A list of icon sizes (optional). If this list is given, it will be used as a priority list for icon sizes when looking up for icons. If you want large icons, for example, you can put '128x128' as the first item in the list.
-- @return A table with file entries.
function parse_desktop_file(arg)
    local program = { show = true, file = arg.file }
    for line in io.lines(arg.file) do
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
        program.icon_path = lookup_application_icon({ icon = program.Icon, icon_sizes = (arg.icon_sizes or all_icon_sizes) })
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
function parse_desktop_files(arg)
    local programs = {}
    local files = io.popen('find '.. arg.dir ..' -maxdepth 1 -name "*.desktop"'):lines()
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
    local paths = io.popen('find '..arg.dir..' -maxdepth 1 -type d'):lines()
    for path in paths do
        if path:match("[^/]+$") then
            local file = {}
            file.filename = path:match("[^/]+$")
            file.path = path
            file.show = true
            file.icon = lookup_directory_icon({ type="folder", icon_sizes = arg.icon_sizes or all_icon_sizes })
            table.insert(files, file)
        end
    end
    local paths = io.popen('find '..arg.dir..' -maxdepth 1 -type f'):lines()
    for path in paths do
        if not path:find("\.desktop$") then
            local file = {}
            file.filename = path:match("[^/]+$")
            file.path = path
            file.show = true
            file.icon = lookup_file_icon({ filename = file.filename, icon_sizes = arg.icon_sizes or all_icon_sizes })
            table.insert(files, file)
        end
    end
    return files
end

