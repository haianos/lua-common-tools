--[[
    pp-colors -- Pretty Print colors
    Utility to create pretty messages and configure them
    Enea Scioni <enea.scioni@kuleuven.be>
    
Usage: 
  tab = {
    info = 'cyan',
    err  = 'red',
    warn = 'yellow',
    hi   = 'bold'
  }
  colorize=require('pp-colors').colorme(tab)
  print(colorize('info','cat'))
  print(colorize('err','dog'))
  print(colorize('warn','mouse'))
--]]

local ac=require('ansicolors')

M = {}

local function greenmsg(...)
   return ac.green(table.concat({...}, ' '))
end

local function bgreenmsg(...)
   return ac.bright(ac.green(table.concat({...}, ' ')))
end

local function yellowmsg(...)
   return ac.yellow(table.concat({...}, ' '))
end

local function byellowmsg(...)
   return ac.bright(ac.yellow(table.concat({...}, ' ')))
end

local function redmsg(...)
   return ac.red(table.concat({...}, ' '))
end

local function bredmsg(...)
   return ac.bright(redmsg(...))
end

local function cyanmsg(...)
   return ac.cyan(table.concat({...}, ' '))
end

local function bmsg(...)
  return ac.bright(ac.white(table.concat({...}, ' ')))
end

local function magentamsg(...)
  return ac.magenta(table.concat({...}, ' '))
end

local function bmagentamsg(...)
  return ac.bright(magentamsg(...))
end

local function colorme(config)
  local fnc = {
    red     = redmsg,
    bred    = bredmsg,
    green   = greenmsg,
    bgreen  = bgreenmsg,
    yellow  = yellowmsg,
    byellow = byellowmsg,
    magenta = bmagentamsg,
    cyan    = cyanmsg,
    bold    = bmsg
  }
  
  local _colortab = config
  --tc: type color, str to colorize
  local function _colorme(tc,str)
    if _colortab[tc] and fnc[_colortab[tc]] then return fnc[_colortab[tc]](str) end
    return str
  end
  return _colorme
end

-- Export....
M.colorme    = colorme

return M
