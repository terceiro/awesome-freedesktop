-- Grab environment

local io = io
local string = string
local table = table
local os = os

module("freedesktop")

-- the categories and their synonims where shamelessly copied from lxpanel
-- source code.

menu = {}
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

for file in io.popen('find /usr/share/applications/ -type f'):lines() do
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
      if not menu[target_category] then
        menu[target_category] = {}
      end

      local cmdline = string.gsub(program.cmdline, '%%c', program.name)
      cmdline = string.gsub(cmdline, '%%[fuFU]', '')
      cmdline = string.gsub(cmdline, '%%k', program.desktop_file)
      if program.icon then
        cmdline = string.gsub(cmdline, '%%i', '--icon ' .. program.icon)
      end
      if program.needs_terminal then
        cmdline = 'x-terminal-emulator -e ' .. cmdline
      end

      
      table.insert(menu[target_category], { program.name, cmdline, program.icon })
    end
  end

end

-- TODO change the icons to use lookup_icon function when it supports looking
-- inside icon themes.
menu.root = {
  { "Accessories", menu["Accessories"], '/usr/share/icons/gnome/16x16/categories/applications-accessories.png' },
  { "Development", menu["Development"], '/usr/share/icons/gnome/16x16/categories/applications-development.png' },
  { "Education", menu["Education"], '/usr/share/icons/gnome/16x16/categories/applications-science.png' },
  { "Games", menu["Games"], '/usr/share/icons/gnome/16x16/categories/applications-games.png' },
  { "Graphics", menu["Graphics"], '/usr/share/icons/gnome/16x16/categories/applications-graphics.png' },
  { "Internet", menu["Internet"], '/usr/share/icons/gnome/16x16/categories/applications-internet.png' },
  { "Multimedia", menu["Multimedia"], '/usr/share/icons/gnome/16x16/categories/applications-multimedia.png' },
  { "Office", menu["Office"], '/usr/share/icons/gnome/16x16/categories/applications-office.png' },
  { "Other", menu["Other"], '/usr/share/icons/gnome/16x16/categories/applications-other.png' },
  { "Settings", menu["Settings"], '/usr/share/icons/gnome/16x16/categories/applications-utilities.png' },
  { "System Tools", menu["System-Tools"], '/usr/share/icons/gnome/16x16/categories/applications-system.png' },
}
