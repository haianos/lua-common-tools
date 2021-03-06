--
-- 2015, Enea Scioni         <enea.scioni@unife.it>
-- 2013, Markus Klotzbuecher <markus.klotzbuecher@mech.kuleuven.be>
-- Useful code snips
-- some own ones, some collected from the lua wiki
--

local type, pairs, ipairs, setmetatable, getmetatable, assert, table,
   print, tostring, string, io, unpack, error, load, pcall, debug, xpcall = type,
   pairs, ipairs, setmetatable, getmetatable, assert, table, print,
   tostring, string, io, unpack, error, load, pcall, debug, xpcall

module('utils')

-- increment major on API breaks
-- increment minor on non breaking changes
VERSION=0.998

function append(car, ...)
   assert(type(car) == 'table')
   local new_array = {}

   for i,v in pairs(car) do
      table.insert(new_array, v)
   end
   for _, tab in ipairs({...}) do
      for k,v in pairs(tab) do
         table.insert(new_array, v)
      end
   end
   return new_array
end

function tab2str( tbl )

   local function val_to_str ( v )
      if "string" == type( v ) then
         v = string.gsub( v, "\n", "\\n" )
         if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
         end
         return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
      else
         return "table" == type( v ) and tab2str( v ) or tostring( v )
      end
   end

   local function key_to_str ( k )
      if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
         return k
      else
         return "[" .. val_to_str( k ) .. "]"
      end
   end

   if type(tbl) ~= 'table' then return tostring(tbl) end

   local result, done = {}, {}
   for k, v in ipairs( tbl ) do
      table.insert( result, val_to_str( v ) )
      done[ k ] = true
   end
   for k, v in pairs( tbl ) do
      if not done[ k ] then
         table.insert( result, key_to_str( k ) .. "=" .. val_to_str(v))
      end
   end
   return "{" .. table.concat( result, "," ) .. "}"
end

--- Wrap a long string.
-- source: http://lua-users.org/wiki/StringRecipes
-- @param str string to wrap
-- @param limit maximum line length
-- @param indent regular indentation
-- @param indent1 indentation of first line
function wrap(str, limit, indent, indent1)
   indent = indent or ""
   indent1 = indent1 or indent
   limit = limit or 72
   local here = 1-#indent1
   return indent1..str:gsub("(%s+)()(%S+)()",
                            function(sp, st, word, fi)
                               if fi-here > limit then
                                  here = st - #indent
                                  return "\n"..indent..word
                               end
                            end)
end


function pp(...)
   if type(val) == 'table' then print(tab2str(val))
   else print(val) end
end

function lpad(str, len, char, strlen)
   strlen = strlen or #str
   if char == nil then char = ' ' end
   return string.rep(char, len - strlen) .. str
end

function rpad(str, len, char, strlen)
   strlen = strlen or #str
   if char == nil then char = ' ' end
   return str .. string.rep(char, len - strlen)
end

-- Trim functions: http://lua-users.org/wiki/CommonFunctions
-- Licensed under the same terms as Lua itself.--DavidManura
function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))    -- from PiL2 20.4
end

-- remove leading whitespace from string.
function ltrim(s) return (s:gsub("^%s*", "")) end

-- remove trailing whitespace from string.
function rtrim(s)
   local n = #s
   while n > 0 and s:find("^%s", n) do n = n - 1 end
   return s:sub(1, n)
end

--- Strip ANSI color escape sequence from string.
-- @param str string
-- @return stripped string
-- @return number of replacements
function strip_ansi(str) return string.gsub(str, "\27%[%d+m", "") end

--- Convert string to string of fixed lenght.
-- Will either pad with whitespace if too short or will cut of tail if
-- too long. If dots is true add '...' to truncated string.
-- @param str string
-- @param len lenght to set to.
-- @param dots boolean, if true append dots to truncated strings.
-- @return processed string.
function strsetlen(str, len, dots)
   if string.len(str) > len and dots then
      return string.sub(str, 1, len - 4) .. "... "
   elseif string.len(str) > len then
      return string.sub(str, 1, len)
   else return rpad(str, len, ' ') end
end

function stderr(...)
   io.stderr:write(...)
   io.stderr:write("\n")
end

function stdout(...)
   print(...)
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- basename("aaa") -> "aaa"
-- basename("aaa.bbb.ccc") -> "ccc"
function basename(n)
   if not string.find(n, '[\\.]') then
      return n
   else
      local t = split(n, "[\\.]")
      return t[#t]
   end
end

function car(tab)
   return tab[1]
end

function cdr(tab)
   local new_array = {}
   for i = 2, table.getn(tab) do
      table.insert(new_array, tab[i])
   end
   return new_array
end

function cons(car, cdr)
   local new_array = {car}
  for _,v in cdr do
     table.insert(new_array, v)
  end
  return new_array
end

function flatten(t)
   function __flatten(res, t)
      if type(t) == 'table' then
         for k,v in ipairs(t) do __flatten(res, v) end
      else
         res[#res+1] = t
      end
      return res
   end

   return __flatten({}, t)
end

function deepcopy(object)
   local lookup_table = {}
   local function _copy(object)
      if type(object) ~= "table" then
            return object
      elseif lookup_table[object] then
         return lookup_table[object]
      end
      local new_table = {}
      lookup_table[object] = new_table
      for index, value in pairs(object) do
         new_table[_copy(index)] = _copy(value)
      end
      return setmetatable(new_table, getmetatable(object))
   end
   return _copy(object)
end

function imap(f, tab)
   local newtab = {}
   if tab == nil then return newtab end
   for i,v in ipairs(tab) do
      local res = f(v,i)
      newtab[#newtab+1] = res
   end
   return newtab
end

function map(f, tab)
   local newtab = {}
   if tab == nil then return newtab end
   for i,v in pairs(tab) do
      local res = f(v,i)
      table.insert(newtab, res)
   end
   return newtab
end

function filter(f, tab)
   local newtab= {}
   if not tab then return newtab end
   for i,v in pairs(tab) do
      if f(v,i) then
         table.insert(newtab, v)
      end
   end
   return newtab
end

function foreach(f, tab)
   if not tab then return end
   for i,v in pairs(tab) do f(v,i) end
end

function foldr(func, val, tab)
   if not tab then return val end
   for i,v in pairs(tab) do
      val = func(val, v)
   end
   return val
end

--- Pre-order tree traversal.
-- @param fun function to apply to each node
-- @param root root to start from
-- @param pred predicate that nodes must be satisfied for function application.
-- @return table of return values
function maptree(fun, root, pred)
   local res = {}
   local function __maptree(tab)
      foreach(function(v, k)
                 if not pred or pred(v) then
                    res[#res+1] = fun(v, tab, k)
                 end
                 if type(v) == 'table' then __maptree(v) end
              end, tab)
   end
   __maptree(root)
   return res
end

-- O' Scheme, where art thou?
-- turn operator into function
function AND(a, b) return a and b end

-- and which takes table
function andt(...)
   local res = true
   local tab = {...}
   for _,t in ipairs(tab) do
      res = res and foldr(AND, true, t)
   end
   return res
end

function eval(str)
   return assert(loadstring(str))()
end

function unrequire(m)
   package.loaded[m] = nil
   _G[m] = nil
end

-- Compare two values (potentially recursively).
-- @param t1 value 1
-- @param t2 value 2
-- @return true if the same, false otherwise.
function table_cmp(t1, t2)
   local function __cmp(t1, t2)
      -- t1 _and_ t2 are not tables
      if not (type(t1) == 'table' and type(t2) == 'table') then
         if t1 == t2 then return true
         else return false end
      elseif type(t1) == 'table' and type(t2) == 'table' then
         if #t1 ~= #t2 then return false
         else
            -- iterate over all keys and compare against k's keys
            for k,v in pairs(t1) do
               if not __cmp(t1[k], t2[k]) then
                  return false
               end
            end
            return true
         end
      else -- t1 and t2 are not of the same type
         return false
      end
   end
   return __cmp(t1,t2) and __cmp(t2,t1)
end

function table_has(t, x)
   for _,e in ipairs(t) do
      if e==x then return true end
   end
   return false
end

--- Return a new table with unique elements.
function table_unique(t)
   local res = {}
   for i,v in ipairs(t) do
      if not table_has(res, v) then res[#res+1]=v end
   end
   return res
end

--- Convert arguments list into key-value pairs.
-- The return table is indexable by parameters (i.e. ["-p"]) and the
-- value is an array of zero to many option parameters.
-- @param standard Lua argument table
-- @return key-value table
function proc_args(args)
   local function is_opt(s) return string.sub(s, 1, 1) == '-' end
   local res = { [0]={} }
   local last_key = 0
   for i=1,#args do
      if is_opt(args[i]) then -- new key
         last_key = args[i]
         res[last_key] = {}
      else -- option parameter, append to existing tab
         local list = res[last_key]
         list[#list+1] = args[i]
      end
   end
   return res
end

--- Simple advice functionality
-- If oldfun is not nil then returns a closure that invokes both
-- oldfun and newfun. If newfun is called before or after oldfun
-- depends on the where parameter, that can take the values of
-- 'before' or 'after'.
-- If oldfun is nil, newfun is returned.
-- @param where string <code>before</code>' or <code>after</code>
-- @param oldfun (can be nil)
-- @param newfunc
function advise(where, oldfun, newfun)
   assert(where == 'before' or where == 'after',
          "advise: Invalid value " .. tostring(where) .. " for where")

   if oldfun == nil then return newfun end

   if where == 'before' then
      return function (...) newfun(...); oldfun(...); end
   else
      return function (...) oldfun(...); newfun(...); end
   end
end

--- Check wether a file exists.
-- @param fn filename to check.
-- @return true or false
function file_exists(fn)
   local f=io.open(fn);
   if f then io.close(f); return true end
   return false
end

--- From Book  "Lua programming gems", Chapter 2, pg. 26.
function memoize (f)
   local mem = {}                       -- memoizing table
   setmetatable(mem, {__mode = "kv"})   -- make it weak
   return function (x)                  -- new version of ’f’, with memoizing
             local r = mem[x]
             if r == nil then   -- no previous result?
                r = f(x)        -- calls original function
                mem[x] = r      -- store result for reuse
             end
             return r
          end
end

--- call thunk every s+ns seconds.
function gen_do_every(s, ns, thunk, gettime)
   local next = { sec=0, nsec=0 }
   local cur = { sec=0, nsec=0 }
   local inc = { sec=s, nsec=ns }

   return function()
             cur.sec, cur.nsec = gettime()

             if time.cmp(cur, next) == 1 then
                thunk()
                next.sec, next.nsec = time.add(cur, inc)
             end
          end
end

--- Expand parameters in string template.
-- @param tpl string containing $NAME parameters.
-- @param params table of NAME=value pairs for substitution.
-- @param warn optionally warn if there are nonexpanded parameters.
-- @return new string
-- @return number of unexpanded parameters
function expand(tpl, params, warn)
   if warn==nil then warn=true end
   local unexp = 0

   -- expand
   for name,val in pairs(params) do tpl=string.gsub(tpl, "%$"..name, val) end

   -- check for unexpanded
   local _,_,res= string.find(tpl, "%$([%a%d_]+)")
   if res then
      if warn then print("expand: warning, no param for variable $" .. res) end
      unexp = unexp + 1
   end

   return tpl, unexp
end

local function pcall_bt(func, ...)
   return xpcall(func, debug.traceback, ...)
end

--- Evaluate a chunk of code in a constrained environment.
-- @param unsafe_code code string
-- @param optional environment table.
-- @return true or false depending on success
-- @return function or error message
function eval_sandbox(unsafe_code, env)
   env = env or {}
--    print(unsafe_code)
   local unsafe_fun, msg = load(unsafe_code, nil, 't', env)
   if not unsafe_fun then return false, msg end
   return pcall_bt(unsafe_fun)
end


--- Preprocess the given string.
-- Lines starting with @ are executed as Lua code
-- Other lines are passed through verbatim, expect those contained in
-- $(...) which are evaluated and the result inserted.
--
-- @param str string to preprocess
-- @param env environment for sandbox (default {})
-- @param verbose print verbose error message in case of failure
-- @return preprocessed result.
function preproc(str, env, verbose)
   local chunk = {"__res={}\n" }
   local lines = split(str, "\n")

   for _,line in ipairs(lines) do
      -- line = trim(line)
      local s,e = string.find(line, "^%s*@")
      if s then
         chunk[#chunk+1] = string.sub(line, e+1) .. "\n"
      else
         local last = 1
         for text, expr, index in string.gmatch(line, "(.-)$(%b())()") do
            last = index
            if text ~= "" then
               -- write part before expression
               chunk[#chunk+1] = string.format('__res[#__res+1] = %q\n ', text)
            end
            -- write expression
            chunk[#chunk+1] = string.format('__res[#__res+1] = %s\n', expr)
         end
         -- write remainder of line (without further $()
         chunk[#chunk+1] = string.format('__res[#__res+1] = %q\n', string.sub(line, last).."\n")
      end
   end
   chunk[#chunk+1] = "return table.concat(__res, '')\n"
   local ret, str = eval_sandbox(table.concat(chunk), env)
   if not ret and verbose then
      print("preproc failed: start of error report")
      local code_dump = table.concat(chunk)
      for i,l in ipairs(split(code_dump, "\n")) do print(tostring(i)..":\t"..string.format("%q", l)) end
      print(str.."\npreproc failed: end of error message")
   end
   return ret, str
end

--- Convert a string to a hex representation of a string.
-- @param str string to convert
-- @param space space between values (default: "")
-- @return hex string
function str_to_hexstr(str,spacer)
   return string.lower(
      (string.gsub(str,"(.)",
                   function (c)
                      return string.format("%02X%s",string.byte(c), spacer or "")
                   end ) ) )
end

--- Return the maximum of two numbers
-- @param x1
-- @param x2
-- @return the maximum
function max(x1, x2) if x1>x2 then return x1; else return x2; end end

--- Return the minimum of two numbers
-- @param x1
-- @param x2
-- @return the minimum
function min(x1, x2) if x1>x2 then return x2; else return x1; end end

--- Convert a list as lua array (lua-table,index numbers) to a set
--  (as lua-table, key existance)
-- The return table is indexable by parameters (i.e. ["-p"]) and the
-- value is an array of zero to many option parameters.
-- @param standard Lua array/list as table
-- @return set lua as table
function list2set(list)
    local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

--- returns number of element in a table
function list_size(list)
  local count = 0
  for i,v in pairs(list) do count =  count +1 end
  return count
end

--- Identation utility: generate a sequence of patterns in string
-- @param spaces string to be repeated
-- @param index number of repetitions
-- @return  string
function gen_spaces(space,idx)
  local str = ''
  for i=1,idx do
    str = str..space
  end
  return str
end

--- Read a Target file
-- @param file filename
-- @return file (as string)
-- @todo move to generic utils
function read_file(file)
   local f = assert(io.open(file, "rb"))
   local data = f:read("*all")
   f:close()
   return data
end

--- Merge values of T2 in T1
-- @param T1 target (table)
-- @param T2 origin (table)
-- @param preserve original value if key is conflicting. (boolean, default true)
function merge_tab(t1,t2,preserve)
  local preserve = preserve or true
  for i,v in pairs(t2) do
    if not t1[i] or (not preserve) then t1[i] = v end
  end
end
