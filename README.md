About
=====

This project aims to add support for freedesktop.org compliant desktop entries
and menu.

Installation
============

Just drop freedesktop/ folder in your ~/.config/awesome/ directory.

Main features
=============

  * a freedesktop.org-compliant (or almost) applications menu
  * a freedesktop.org-compliant (or almost) desktop
  * a (yet limited) icon lookup function.

Icon themes
===========

You can choose any icon theme that's installed in /usr/share/icons/. To define
your icon theme, you can do the following before you require
"freedesktop.menu", but after you require "freedesktop.utils" (see example
usage below):

  freedesktop.utils.icon_theme = 'gnome'

You can also use more than one icon theme, by assigning a Lua table containing
a list of themes.

  freedesktop.utils.icon_theme = { 'Mist', 'gnome' }

When you use a list of icon themes, icons will be looked up in themes list in
the order you specified. The first theme containing the desired icon will be
used (that happens once for each icon). Note that if the icon theme already
specifies another icon theme as fallback, that is already taken care of for
you.

Usage example
=============

You can use the freedesktop module in your awesome configuration
(~/.config/awesome/rc.lua) like the example below. If you are a Debian user,
you can also uncomment the two lines that insert the Debian menu together with
the rest of the items.

  -- applications menu
  require('freedesktop.utils')
  freedesktop.utils.terminal = terminal  -- default: "xterm"
  freedesktop.utils.icon_theme = 'gnome' -- look inside /usr/share/icons/, default: nil (don't use icon theme)
  require('freedesktop.menu')
  -- require("debian.menu")

  menu_items = freedesktop.menu.new()
  myawesomemenu = {
     { "manual", terminal .. " -e man awesome", freedesktop.utils.lookup_icon({ icon = 'help' }) },
     { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua", freedesktop.utils.lookup_icon({ icon = 'package_settings' }) },
     { "restart", awesome.restart, freedesktop.utils.lookup_icon({ icon = 'gtk-refresh' }) },
     { "quit", awesome.quit, freedesktop.utils.lookup_icon({ icon = 'gtk-quit' }) }
  }
  table.insert(menu_items, { "awesome", myawesomemenu, beautiful.awesome_icon })
  table.insert(menu_items, { "open terminal", terminal, freedesktop.utils.lookup_icon({icon = 'terminal'}) })
  -- table.insert(menu_items, { "Debian", debian.menu.Debian_menu.Debian, freedesktop.utils.lookup_icon({ icon = 'debian-logo' }) })

  mymainmenu = awful.menu.new({ items = menu_items, width = 150 })

  mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })


  -- desktop icons
  require('freedesktop.desktop')
  for s = 1, screen.count() do
        freedesktop.desktop.add_applications_icons({screen = s, showlabels = true})
        freedesktop.desktop.add_dirs_and_files_icons({screen = s, showlabels = true})
  end

License
=======

Copyright © 2009-2011 Antonio Terceiro <terceiro@softwarelivre.org>

This code is licensed under the same terms as Awesome itself.
