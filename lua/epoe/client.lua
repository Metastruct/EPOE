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
local CreateClientConVar=CreateClientConVar
module( "epoe" )

------------------------------------
-- Receiving
------------------------------------



local data={ -- flags for receiving..
IS_EPOE=1,
IS_ERROR=2,
IS_PRINT=4,
IS_MSG=8,
IS_MSGN=16,
IS_SEQ=32
}

-- Hold long messages for us...
local Buffer=""



--      say !lua epoe.AddSub(me) local a="QWERTYUIOP" print(string.rep(a,100))

-- Handle incoming messages
function OnUsermessage(umsg)
	local flags=umsg:ReadChar()
	local str=umsg:ReadString()
	
	if HasFlag(flags,IS_SEQ) then -- Store long messages
		Buffer=Buffer..str
		return
	elseif #Buffer>0 then -- If we have stuff in buffer then this is the last message
		str=Buffer..str
		Buffer=''
	end
	
	local nl=NewLine(flags) -- newline flag? Add newline :o
	--[[
	local infostr=""
	for k,v in pairs(data) do
		if HasFlag(flags,v) then
			infostr=infostr..tostring(k)..' '
		end
	end
	infostr='( '..(nl=="" and "_L" or "NL") ..' '..infostr..')\t'
	]]

	--Msg(str..nl)
	if HasFlag(flags,IS_EPOE) then
		
		if str=="_S" then
			subscribed=true
				internalPrint("Subscribed to EPOE!")
			return
		elseif str=="_US" then
			subscribed=false
			internalPrint("Unsubscribed from EPOE!")
			return
		elseif str=="_NA" then
			if AutologinRetry() then return end -- Some servers got delayed admins?
			internalPrint("Could not login: You need to be admin to use EPOE!")
			return
		end
	end
	hook.Call(TagHuman,nil,str..nl,flags)
end

usermessage.Hook(Tag,OnUsermessage)

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

-- Need to do it inInitPostEntity or it may fuck up. Maybe even later?
hook.Add('InitPostEntity',TagHuman..'_autologin',function()
	if autologin:GetBool() then RunConsoleCommand("cmd",Tag,"1") end
end)

local tries=0
function AutologinRetry()
	tries=tries+1
	if tries > 2 then return true end
	timer.Simple(3,RunConsoleCommand,"cmd",Tag,"1")
	internalPrint("Retrying autologin.")
end


------------------------------------
-- Logging ?
------------------------------------


------------------------------------
-- Printing to EPOE from client.
------------------------------------

function Msg(...)
	local noerr,str=pcall(ToString,{...}) -- just to be sure
	if str then
		hook.Call(TagHuman,nil,str,!noerr and IS_EPOE or 0)
	else
		error"???"
	end
end

function Print(...)
	local noerr,str=pcall(ToString,{...}) -- just to be sure
	if str then
		hook.Call(TagHuman,nil,str.."\n",!noerr and IS_EPOE or 0)
	else
		error"???"
	end
end

print = Print

function AddText(...)
	for k, v in pairs({...}) do
		if type(v) == "string" then
			hook.Call(TagHuman, nil, v .. "\n", 0)
		elseif type(v) == "table" and v.r and v.g and v.b then
			hook.Call(TagHuman, nil, "", 0, v)
		end
		
		hook.Call(TagHuman, nil, "\n", 0)
	end
end

-- What was I thinking

function internalPrint(...)
	local noerr,str=pcall(ToString,{...}) -- just to be sure
	if str then
		hook.Call(TagHuman,nil,str,IS_EPOE)
	else
		error"???"
	end
end