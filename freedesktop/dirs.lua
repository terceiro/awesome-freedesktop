-- -*- lua-indent-level: 4; indent-tabs-mode: nil -*-
-- Grab environment

local string = string
local io = io
local os = os
local table = table
local type = type
local ipairs = ipairs
local pairs = pairs

module("freedesktop.dirs")

local _xdg_dirs = {}
local _xdg_home = {}

local xdg_default_dirs = {
    DATA   = "/usr/local/share:/usr/share",
    CONFIG = "/etc/xdg",
}

local xdg_default_home = {
    CACHE  = ".cache/",
    CONFIG = ".config/",
    DATA   = ".local/share/",
}

local function xdg_dirs(d)
    local env = os.getenv('XDG_' .. d .. '_DIRS')
    local ret = {}
    if not env or env == "" then
        env = xdg_default_dirs[d]
    end
    for i in string.gmatch(env, "[^:]+") do
        i = string.gsub(i,'/*$', '')
        table.insert(ret, i .. '/')
    end
    _xdg_dirs[d] = ret
    return ret
end    

function xdg_config_dirs()
    if _xdg_dirs['CONFIG'] then
        return _xdg_dirs['CONFIG']
    end
    return xdg_dirs('CONFIG')
end

function xdg_data_dirs()
    if _xdg_dirs['DATA'] then
        return _xdg_dirs['DATA']
    end
    return xdg_dirs("DATA")
end

local function xdg_home(d)
    local ret = os.getenv('XDG_' .. d .. '_HOME')
    if not ret or ret == "" then
        local home = string.gsub(os.getenv('HOME'),'/*$', '')
        ret = home .. '/' .. xdg_default_home[d]
    end
    _xdg_home[d] = ret
    return ret
end

function xdg_cache_home()
    if _xdg_home['CACHE'] then
        return _xdg_home['CACHE']
    end
    return xdg_home('CACHE')
end

function xdg_config_home()
    if _xdg_home['CONFIG'] then
        return _xdg_home['CONFIG']
    end
    return xdg_home('CONFIG')
end

function xdg_data_home()
    if _xdg_home['DATA'] then
        return _xdg_home['DATA']
    end
    return xdg_home('DATA')
end
