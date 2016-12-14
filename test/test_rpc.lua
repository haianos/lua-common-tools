jsonrpc = require('json-rpc')

str = jsonrpc.request('full-update',2,3,4)
print(str)
str = jsonrpc.request('full-update',2,"gatto",{events='e_done'})
print(str)
--
str = jsonrpc.response(str,'ok')
print(str)

print('testing jsonrpc')
-- set of methods available
methods = {
  sum = function(a,b) return a+b end,
  sub = function(a,b) return a-b end,
  mul = function(a,b) return a*b end,
  div = function(a,b) return a/b end,
  several = function(a,b) return a/b, b/a end
}

str = jsonrpc.request('sum',2,3)
print(str)
req = json.decode(str)
-- server side
fnc = methods[req['method']]
res = ''
if not fnc then
  res = jsonrpc.response_error(str,'method_not_found')
else
  res = jsonrpc.response(str,fnc(unpack(req['params'])))
end
print('result is',res)
--
-- print('computation',methods[req['method']](unpack(req['params'])))
-- res = jsonrpc.response(str,methods[req['method']](unpack(req['params'])))
-- print(res)

------------
print('testing server_response')
res = jsonrpc.server_response(methods,str)
print('result is ok',res)
--
str = jsonrpc.request('sum',1,'gatto')
res = jsonrpc.server_response(methods,str)
print('result is invalid params',res)
--
    
    
str = jsonrpc.request('several',10,20)    
print('testing server_response')
res = jsonrpc.server_response(methods,str)
print('result is ok',res)
--
str = jsonrpc.request('several',1,'gatto')
res = jsonrpc.server_response(methods,str)
print('result is invalid params',res)
--