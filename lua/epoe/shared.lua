local insert=table.insert
local remove=table.remove
local Empty=table.Empty
local setmetatable=setmetatable

local player=player
local IsValid=IsValid
local error=error
local pairs=pairs
local hook=hook
local CLIENT=CLIENT
local SERVER=SERVER
local table=table
local pcall=pcall
local math=math
local concommand=concommand
local tostring=tostring
local type=type
local string=string
local select=select
local FrameTime=FrameTime
local assert=assert
local getmetatable=debug.getmetatable
local G=_G
local bit=bit
local next=next
local select=select
local type=type
local Color=Color

module( "epoe" )

-- Consts
Tag='E\''
TagHuman='EPOE'
Should_TagHuman='Should'..TagHuman

-- Clientside only for now
PreEPOE = CLIENT and function(t)
	local ret = hook.Run("PreEPOE",t)
	if ret == false then return end
	return t
end or nil

flags = { -- One byte overhead for signaling this all. Need to add two with anything more.
	IS_EPOE=	2^0,
	IS_ERROR=	2^1,
	IS_PRINT=	2^2,
	IS_MSG=		2^3,

	IS_MSGN=	2^4,
	IS_SEQ=		2^5,
	IS_CERROR=	2^6,
	IS_MSGC=	2^7,
}

-- Add them to the module as variables
for name,byte in pairs(flags) do
	assert(byte>=0)
	assert(byte<=255) -- Increase (user/net)messages from char to short if you're going to change this for some reason
	_M[name]=byte
end

function andnot(bit)
	return 255-bit
end

function DebugFlags(flag)
	local a={}
	for name,byte in pairs(flags) do
		if HasFlag(flag,byte) then
			table.insert(a,name)
		end
	end
	return table.concat(a,", ")
end

function HasFlag(byte,flag)
	local a = bit.band(byte or 0,flag)
	return a==flag
end

-- seq does not have color as it has already been transmitted
function HasMsgCParams(flags)
	return HasFlag(flags,IS_MSGC) and not HasFlag(flags,IS_SEQ)
end

-- Certain messages don't need a newline.
function NewLine(flags)
	if HasFlag(flags,IS_SEQ)
	or HasFlag(flags,IS_MSG)
	or HasFlag(flags,IS_MSGC)
--	or HasFlag(flags,IS_ERROR)
	or HasFlag(flags,IS_EPOE)
	then
		return ""
	end
	return "\n"

end

-- enginespew const
SPEW_WARNING=1

-- Safeguard for super big tables and queue filling faster than emptying. Increase if it becomes a problem with big tables.
MaxQueue = 2048+1024
MSGS_IN_TICK = 6

------------
-- Small stack implementation
-- Sigh complexity from LILO with no gain...
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

	function class:peek()
		return self[self.lilo and #self or 1]
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

function ToString(t) -- depreciated
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
	str = str .. nl .. MakeTable ( t, nice)

	return str:sub(1,-2) -- remove last redundant space
end


function ToStringTableInfo(t)
	local num=0
	local nonnum=0
	local tables
	local meta=getmetatable(t)
	local str=tostring(t)
	str=str:gsub("table: ","table:( ")
	for k,v in pairs(t) do
		local ktype=type(k)
		if ktype=="number" then
			num=num+1
		elseif ktype=="table" then
			nonnum=nonnum+1
			tables=true
		else
			nonnum=nonnum+1
		end
		if type(v) == "table" then
			tables=true
		end
	end
	if nonnum>0 then
		str=str..', !#'..nonnum
	end
	if num>0 then
		local nums=#t
		if nums==num then
			str=str..', #'..num
		else
			str=str..', #'..num..'/'..nums
		end
	end
	/*if num>0 and nonnum>0 then
		str=str..', count='..(num+nonnum)
	end*/
	if meta then
		str=str..', meta'
	end
	if tables then
		str=str..', subtables'
	end
	str=str..' )'
	return str
end

function ToStringEx(delim,...)
	local res=""
	local count=select('#',...)
	count=count==0 and 1 or count
	for n=1,count do
		local e = select(n,...)
		if type(e)=="table" then
			e=ToStringTableInfo(e)
		elseif e == nil then
			e=type(select(n,...))
		else
		    e=tostring(e)
		end
		res = res .. (n==1 and "" or delim) .. e
	end
	return res
end


col_white=Color(255,255,255,255)
col_error=Color(255,1,254,255)
function IsColor(val)
	
	if type(val)~="table" then return false end
	
	local 	r = val.r
			g = val.g
			b = val.b
			
	if not r or type(r)~="number"
	or not g or type(g)~="number"
	or not b or type(b)~="number"
	then return false end
	
	return true
	
end
