-- Usage example of the verbose log Lua module

vlog = require('vlog')

-- Get a new validation log structure
vres = vlog.create_vres()
--[[
it is also possible to pass some options,
such as if you want colorful pretty prints
```
vres: = vlog.create_vres{color=true})
```
--]]

-- Give a context to the log system
vres:push_context('LV1')

-- Add a message of type 'info' (other types are 'warn' or 'err')
vres:add_msg('info', {txt='just an info'})

-- change context, first removing and then adding a new one
vres:pop_context()
vres:push_context('LVA')
vres:add_msg('warn',{txt='just a warning'})

--[[
    contexts are hierarchical.
   Lets add LV2 in LV1
--]]
vres:pop_context()
vres:push_context('LV1')
vres:push_context('LV2')

-- and add another info message
vres:add_msg('info',{txt='yet another info'})

-- now, lets add an error!
vres:add_msg('err',{txt='uupss!'})

---- Adding stuff was easy, isn't it?
-- Now lets try to see the result
print(vres)

--[[ 
If that was too informative, we can always filter out
the results by level ('info','err','warn') or by position,
such as 'inner'
--]]
print('----------------------------')
print('Results by level type (INFO)')
print(vres:result('info'))
print('----------------------------')
print('Results by positional type (inner)')
print(vres:result('inner'))

--[[
However, the previous `result` only give us a string.
What about if we want to manipulate the message?
Use the `filter` to get a table of results!
--]]
myres = vres:filter('err')
-- you can always convert it to a string by
print('----------------------------')
print('Filtered results')
print(vlog.msg2str(myres[1]))

-- To clear our validation structure, lets create a new one
-- or clean up the current
vres:clear()

-- That's all, folks! Have fun! :-)
print("That's all, folks! Have fun! :-)")