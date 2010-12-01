local insert=table.insert
local remove=table.remove
local Empty=table.Empty
local setmetatable=setmetatable

local umsg=umsg
local humans=player.GetHumans()
local ValidEntity=ValidEntity
local RecipientFilter=RecipientFilter
local error=error
local pairs=pairs
local hook=hook
local table=table
local pcall=pcall
local concommand=concommand
local tostring=tostring
local type=type
local string=string

Msg('-- EPOE 2.0 -- Loading '..(SERVER and "server -- " or "client --\n" ))


module( "epoe" )

-- Consts
Tag='E\''
TagHuman='EPOE'

IS_EPOE=1
IS_ERROR=2
IS_PRINT=4
IS_MSG=8
IS_MSGN=16
IS_SEQ=32

function HasFlag(byte,flag)
	local a = (byte or 0)&flag
	return a==flag
end

-- If the flag type includes newline add it here.
function NewLine(flags)


	-- Seq= don't add anything  and  Msg has no newline :)
	if HasFlag(flags,IS_SEQ) or HasFlag(flags,IS_MSG) or HasFlag(flags,IS_EPOE) or HasFlag(flags,IS_ERROR) then 
		return ""
	end
	
	-- print , MsgN , error
	return "\n"
	
end

-- enginespew
SPEW_WARNING=1

-- Maximum amount of messages in queue. Prevents deadloops.
MaxQueue=2048

-- How many umsgs can we send in a tick
UMSGS_IN_TICK = 3 -- Quite safe. Doesn't overflow admins D:


------------
-- Stack
------------
	local class = {}
	local mt = {__index = class}



	function FIFO()

		
		return setmetatable( {} , mt )
	end

	function LILO()

		
		return setmetatable( {lilo=true} , mt )
	end


	-- Push
	function mt.__add(a,b)	
		insert( a , b )
		return a
	end

	-- Pop
	function mt:__unm()
		return remove( self , self.lilo and #self or 1 )
	end

	-- Pop
	function class:pop()
		return remove( self , self.lilo and #self or 1 )
	end

	function class.push(a,b)
		insert( a , b )
		return a
	end

	function class:len()
		return #self
	end

	function class:length()
		return #self
	end

	function class:clear()
		return Empty( self )
	end
	
-- ToString
function ToString(t)
		local 		nl,tab  = "",  ""

		local function MakeTable ( t, nice, indent, done)
			local str = ""
			local done = done or {}
			local indent = indent or 0
			local idt = ""
			if nice then idt = string.rep ("\t", indent) end

			local sequential = table.IsSequential(t)

			for key, value in pairs (t) do

				str = str .. idt .. tab .. tab

				if not sequential then
					if type(key) == "number" or type(key) == "boolean" then 
						key ='['..tostring(key)..']' ..tab..'='
					else
						key = tostring(key) ..tab..'='
					end
				else
					key = ""
				end

				if type (value) == "table" and not done [value] then

					done [value] = true
					str = str .. key .. tab .. nl
					.. MakeTable (value, nice, indent + 1, done)
					str = str .. idt .. tab .. tab ..tab .. tab .. nl

				else
					
					if 	type(value) == "string" then 
						value = tostring(value)
					elseif  type(value) == "Vector" then
						value = 'Vector('..value.x..','..value.y..','..value.z..')'
					elseif  type(value) == "Angle" then
						value = 'Angle('..value.pitch..','..value.yaw..','..value.roll..')'
					else
						value = tostring(value)
					end
					
					str = str .. key .. tab .. value .. " ".. nl

				end

			end
			return str
		end
		local str = ""
		--if n then str = n.. tab .."=" .. tab end
		str = str .. nl .. MakeTable ( t, nice)
		return str
	end	