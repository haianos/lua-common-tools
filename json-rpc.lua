--
--   json-rpc:
--     simple rpc implementation and helpers
-- Author: Enea Scioni, <enea.scioni@kuleuven.be>
-- KU Leuven, Belgium
--------------------------------------------------
--
-- Requirements: json
--------------------------------------------------

local json = require('json')
local utils = require('utils')
local M = {}

-- population with error objects,
-- it can be extended with add_errobj
local error_objects = {
  parse_error       = { err_code=-32700, err_message="Parse error"},
  invalid_request   = { err_code=-32600, err_message="Invalid Request"},
  method_not_found  = { err_code=-32601, err_message="Method not found"},
  invalid_params    = { err_code=-32602, err_message="Invalid params"},
  internal_error    = { err_code=-32603, err_message="Internal error"},
  server_error      = { err_code=-32000, err_message="Server error"}
}

local id_counter = 0

-- Get an error object, if exists
-- @param ename name of the error object
-- @returns true, error object (nil otherwise)
local function get_errobj(ename)
  local eobj = error_objects[ename]
  if not eobj then
    return nil --error object not found
  end
  return eobj
end

-- Add a custom error object
-- @param ename error name (used into code)
-- @param eobj error object
-- @returns true if the error object has been registered, false otherwise
-- An error object is a table having the fields `err_code` and `err_message`
-- `err_code` and `ename` must be unique.
local function add_errobj(ename,eobj)
  if (not eobj.err_code) or (not eobj.err_message) then
    return false
  end
  if error_objects[ename] then return false end
  for i,v in pairs(error_objects) do
    if v.err_code == eobj.err_code then return false end
  end
  error_objects[ename] = eobj
  return true
end

-- json encoding functors
local function encode_rpc(fnc,...)
  return json.encode(fnc(...))
end

-- Generates a jsonized string for a notification
-- @rcall: remote call
-- @params: your parameters
--   no functions are admitted as parameters
local function notification(rcall,...)
  local req = {}
  req['jsonrpc'] = 2.0
  req['method']  = rcall
  req['params']  = {...}
  return req
end

-- Generates a jsonized string for a request
-- @rcall: remote call
-- @params:
local function request(rcall,...)
  local req = notification(rcall,...)
  req['params']  = {...}
  req['id']      = id_counter
  id_counter     = id_counter + 1
  return req
end

-- Generates a successful response
-- @param req request
-- @param result
-- @returns response (table)
local function response(req,...)
  local res = {}
  local args = {...}
  res['jsonrpc'] = req['jsonrpc']
  res['id']      = req['id']
  if #args == 1 then res['results'] = args[1]
  elseif #args > 1 then res['results'] = args end
  return res
end

-- Generates a failed response
-- @param req original request
-- @param ename error name
-- @param result
-- @returns response (table)
local function response_error(req,ename,...)
  local res  = {}
  res['jsonrpc'] = req['jsonrpc']
  local eobj =  get_errobj(ename) or get_errobj(internal_error)
  local extra = {...}
  res['error']   = {
      code    = eobj.err_code,
      message = eobj.err_message,
  }
  if #extra == 1    then res['data'] = extra[1]
  elseif #extra > 1 then res['data'] = extra end
  if (eobj.err_code == -32700) or (eobj.err_code == -32600) then
    res['id'] = json.utils.null()
  else
    res['id'] = req['id']
  end
  return res
end

----- The following are utilities 
-- for client/server implementation

-- Generates a response from a request
-- @param methods available in the server
-- @param request request string
local function server_response(methods,request)
  local req = request
  if type(request) == 'string' then
    req = json.decode(request)
  end
  local fnc = methods[req['method']]
  if not fnc then -- method not found
    return jsonrpc.response_error(req,'method_not_found')
  end
  local ret = {pcall(fnc,unpack(req['params']))}
  if not ret[1] then 
    return jsonrpc.response_error(req,'invalid_params',ret[2])
  end
  if not req['id'] then return true end -- notification only
  return jsonrpc.response(req,unpack(utils.subrange(ret,2,#ret)))
end

M.add_errobj      = add_errobj
M.get_errobj      = get_errobj
M.request         = function(rcall,...) return encode_rpc(request,rcall,...) end
M.notification    = function(rcall,...) return encode_rpc(notification,rcall,...) end
M.response        = function(req,...)   if type(req) =='string' then return encode_rpc(response,json.decode(req),...) end; return encode_rpc(response,req,...) end
M.response_error  = function(req,ename,...) if type(req) =='string' then print(req); return encode_rpc(response_error,json.decode(req),ename,...) end; 
return encode_rpc(response_error,req,ename,...) end
M.server_response = server_response
return M
