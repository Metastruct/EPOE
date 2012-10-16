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
local ToStringEx=ToStringEx
local type=type
local string=string
local usermessage=usermessage
local Msg=Msg
local MsgN=MsgN
local print=print
local timer=timer
local ErrorNoHalt=ErrorNoHalt
local RunConsoleCommand=RunConsoleCommand
local cookie=cookie
local util=util
local G=_G
local MsgC=MsgC
local Color=Color
local CreateClientConVar=CreateClientConVar
local GM13=VERSION>150

module( "epoe" )

------------------------------------
-- Receiving
------------------------------------


-- Messages can come in multiple parts
-- TODO: If message gets aborted serverside this will fuck up, royally.
local Buffer=""

local lastmsg="<EPOE BROKEN>"
local lastflags=0
-- Handle incoming messages
function ProcessMessage(flags,str)	
--[[
	-- Process repeat messages
	if HasFlag(flags,IS_REPEAT) then
		if str:len()>0 then
			internalPrint("WARNING: IS_REPEAT defined but message was: '"..str.."'")
		end
		local newflags=lastflags|IS_REPEAT
		if flags!=newflags then
			internalPrint("WARNING: IS_REPEAT defined but flags were different: rcv= '"..DebugFlags(flags)..' last='..DebugFlags(lastflags).."'")
		end
		str=lastmsg
		flags=newflags
	end
	lastmsg=str
	lastflags=flags
	]]

	-- Process sequences (aka long messages)
	if HasFlag(flags,IS_SEQ) then -- Store long messages
		Buffer=Buffer..str
		return
	elseif #Buffer>0 then -- Data in buffer and no SEQ flag. We have something to print! TODO: See above todo.
		str=Buffer..str
		Buffer=''
	end


	-- process epoe messages
	local isEpoe=HasFlag(flags,IS_EPOE)
	if isEpoe then

		if str=="_S" then
			subscribed=true
				internalPrint("Subscribed")
			return
		elseif str=="_US" then
			subscribed=false
			internalPrint("Unsubscribed")
			return
		elseif str=="_NA" then
			if AutologinRetry() then return end -- Some servers got delayed admins?
			internalPrint("No Access - Not admin?")
			return
		end
	end

	-- Handle color appending in a hacky way
	local col
	local big=252 -- AGH GM13??
	if HasFlag(flags,IS_MSGC) then
		local colbytes,newstr=str:match("^(...)(.*)$")
		local r,g,b=string.byte(colbytes,1)-1,string.byte(colbytes,2)-1,string.byte(colbytes,3)-1
		
		/*if GM13 then -- FIXME QUICK... FIX THIS WHOLE SHIT
			r,g,b=r*2,g*2,b*2
		end*/
		-- your monitor is not going to miss that one bit for each color I hope
		r,g,b=r>=big and 255 or r,
			  g>=big and 255 or g,
			  b>=big and 255 or b
		
		col=Color(r,g,b,255)
		str = newstr
	end

	-- We are going to add the newline here instead of letting the handlers take care of it so you can just print the stuff and be done with it
	str=str..NewLine(flags)

	-- If we should not let's just return :x
	if not isEpoe and hook.Call(Should_TagHuman,nil,str,flags)==false then
		return
	end
	hook.Call(TagHuman,nil,str,flags,col)
end

function OnUsermessage(umsg)
	local flags = umsg:ReadChar()
	flags=flags+128
	local str  = umsg:ReadString()
	ProcessMessage(flags,str)
end

usermessage.Hook(Tag,OnUsermessage)


------------------------------------
-- EPOE Messages
------------------------------------
function internalPrint(...)
	local noerr,str=pcall(ToStringEx,"",...) -- just to be sure
	if !str then
		return
	end
	hook.Call(TagHuman,nil,str,IS_EPOE)
end

------------------------------------
-- Subscribing
------------------------------------

subscribed=false


function AddSub()
	if subscribed then 	internalPrint("Already subscribed.") return end
	RunConsoleCommand("cmd",Tag,"1")
end
concommand.Add('epoe_login',AddSub,nil,"Login to EPOE stream")

function DelSub()
	if !subscribed then 	internalPrint("Not subscribed.") return end
	RunConsoleCommand("cmd",Tag,"0")
end
concommand.Add('epoe_logout',DelSub,nil,"Logout from EPOE stream")


------------------------------------
-- Automatic login
------------------------------------

local autologin = CreateClientConVar("epoe_autologin","0",true,false)
hook.Add('InitPostEntity',TagHuman..'_autologin',function()
	if autologin:GetBool() then AddSub() end
end)

local tries=0
function AutologinRetry()
	tries=tries+1
	if tries > 2 then return true end
	timer.Simple(3,AddSub)
	internalPrint("Retrying autologin...")
end


------------------------------------
-- Printing to EPOE from client.
------------------------------------
local MODULE=_M
function MODULE.Msg(...)
	local ok,str=pcall(ToStringEx,"",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_MSG,str)
end

function MODULE.MsgN(...)
	local ok,str=pcall(ToStringEx,"",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_MSGN,str)
end

function MODULE.Print(...)
	local ok,str=pcall(ToStringEx," ",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_PRINT,str)

end

MODULE.print = MODULE.Print

function MODULE.Err(...)
	local ok,str=pcall(ToStringEx," ",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_ERROR,str)
end

MODULE.errornohalt = MODULE.Err

function MODULE.MsgC(col,...)
	if not col or not col.r then return end
	local ok,str=pcall(ToStringEx,"",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_MSGC,ColorToStr(col)..str)
end

function MODULE.AddText(...)
	local col=Color(255,255,255,255)
	for k, v in pairs({...}) do
		if type(v) == "table" and type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
			col=Color(v.r,v.g,v.b,255)
		else
			local ok,str=pcall(ToStringEx,"",{v})
			ProcessMessage(IS_MSGC,ColorToStr(col)..(ok and str or ToStringEx("",v)))
		end
	end
end
