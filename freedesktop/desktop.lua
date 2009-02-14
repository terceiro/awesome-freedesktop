local wibox = wibox
local widget = widget
local screen = screen
local image = image
local button = button
local awful = require("awful")
local utils = require("freedesktop.utils")

module("freedesktop.desktop", package.seeall)

local current_pos = {} 
local iconsize = {width = 150, height = 30}

function add_icon(settings) 

	local s = settings.screen

	if not current_pos[s] then
		current_pos[s] = { x = (screen[s].geometry.width - iconsize.width - 20), y = 40  }
	end

	caption = widget({ type = "textbox", align = "right" })
	caption.text = settings.label .. " "
	caption:buttons({
		button({ }, 1, settings.click) 
	})

	icon = nil
	if settings.icon then
		icon = widget({ type = "imagebox", align = "right" })
		icon.image = image(settings.icon)
		icon:buttons({
			button({ }, 1, settings.click) 
		})
	end

	desktop = wibox({ position = "floating", screen = s })
	desktop.widgets = {
					caption,
					icon
	}

	desktop:geometry({
		width = iconsize.width, height = iconsize.height, 
		y = current_pos[s].y, x = current_pos[s].x 
	}) 

	current_pos[s].y = current_pos[s].y + iconsize.height + 20
	desktop.screen = s
end

function add_desktop_icons(screen)
	for i, program in ipairs(utils.parse('~/Desktop'))  do
		if program.show then
			add_icon({
				label = program.name,
				icon = program.icon,
				screen = screen,
				click = function () awful.util.spawn(program.cmdline) end
			})
		end
	end
end

