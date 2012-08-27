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
local select=select
local assert=assert
local GM13=VERSION>150

module( "epoe" )

-- Consts
Tag='E\''
TagHuman='EPOE'
Should_TagHuman='Should'..TagHuman

flags = { -- One byte overhead for signaling this all. Need to add two with anything more.
	IS_EPOE=	2^0,
	IS_ERROR=	2^1,
	IS_PRINT=	2^2,
	IS_MSG=		2^3,

	IS_MSGN=	2^4,
	IS_SEQ=		2^5,
	--IS_REPEAT=	2^6,
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
	local a = (byte or 0)&flag
	return a==flag
end

-- Certain messages don't need a newline.
function NewLine(flags)
	if HasFlag(flags,IS_SEQ) or HasFlag(flags,IS_MSG) or HasFlag(flags,IS_MSGC) or (HasFlag(flags,IS_ERROR) and not GM13) or HasFlag(flags,IS_EPOE)  then 
		return ""
	end
	return "\n"

end

-- enginespew const
SPEW_WARNING=1

-- Safeguard for super big tables and queue filling faster than emptying. Increase if it becomes a problem with big tables.
MaxQueue = 2048

-- How many usermessages can we send in a tick
-- 3 seems to be a good value
-- Warning, increasing tickrate without modifying this might be a lethal combination
UMSGS_IN_TICK = 3


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


---------------------------------------
-- for MsgC
-- TODO: Client version without loss
---------------------------------------
local big=252 -- AGH GM13??
function ColorToStr(color)
	local r,g,b=color.r,color.g,color.b

	r,g,b=
		r>=big and big or r<0 and 0 or r,
		g>=big and big or g<0 and 0 or g,
		b>=big and big or b<0 and 0 or b

	r,g,b=r+1,g+1,b+1
	return string.char(r)..string.char(g)..string.char(b)
end

function StrToColor(str)
	return Color(255,0,255,255) -- STUB
end


---------------------------------------
-- A bit customization for tostringing values. Looks nicer and is more useful (most often)
-- Infinite TODO: Make even more useful
-- TODO: Bail out on huge tables or we risk server lags
---------------------------------------
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
	str = str .. nl .. MakeTable ( t, nice)

	return str:sub(1,-2) -- remove last redundant space
end

function ToStringEx(delim,...)
	local res=""
	for n=1,select('#',...) do
		local e = select(n,...)
		if type(e)=="table" then
		e=ToString(e)
		else
		    e=tostring(e)
		end
		res = res .. (n==1 and "" or delim) .. e
	end
	return res
end