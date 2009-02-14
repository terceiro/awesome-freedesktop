-- Grab environment

local io = io
local string = string
local table = table
local os = os

module("freedesktop.utils", package.seeall)

function lookup_icon(icon)
    if string.sub(icon, 1, 1) == '/' and (string.find(icon, '.+%.png') or string.find(icon, '.+%.xpm')) then
        -- icons with absolute path and supported (AFAICT) formats
        return icon
    else
        if (os.execute('test -f /usr/share/pixmaps/' .. icon) == 0) and (string.find(icon, '.+%.png') or string.find(icon, '.+%.xpm')) then
            return '/usr/share/pixmaps/' .. icon
        elseif os.execute('test -f /usr/share/pixmaps/' .. icon .. '.png') == 0 then
            return '/usr/share/pixmaps/' .. icon .. '.png'
        elseif os.execute('test -f /usr/share/pixmaps/' .. icon .. '.xpm') == 0 then
            return '/usr/share/pixmaps/' .. icon .. '.xpm'
        end
        -- TODO: icons without absolute path and not present in
        -- /usr/share/pixmaps must be looked up according to freedesktop icon
        -- theme specification (?)
    end
end

function parse(dir)
    local programs = {}
    local files = io.popen('find '..dir..' -maxdepth 1 -name "*.desktop"'):lines()
    for file in files do
        local program = { show = true, desktop_file = file }
        for line in io.lines(file) do

            -- command line
            if string.sub(line, 1, 5) == 'Exec=' then
                program.cmdline = string.sub(line, 6, -1)
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
                program.icon = lookup_icon(icon)
            end

            -- detect programas that need a terminal
            if line == 'Terminal=true' then
                program.needs_terminal = true
            end
        end

        if program.cmdline then
            local cmdline = string.gsub(program.cmdline, '%%c', program.name)
            cmdline = string.gsub(cmdline, '%%[fuFU]', '')
            cmdline = string.gsub(cmdline, '%%k', program.desktop_file)
            if program.icon then
                cmdline = string.gsub(cmdline, '%%i', '--icon ' .. program.icon)
            end
            if program.needs_terminal then
                -- TODO add a parameter for the terminal wanted
                cmdline = 'xterm -e ' .. cmdline
            end
            program.cmdline = cmdline
        end

        table.insert(programs, program)
    end

    return programs
end
