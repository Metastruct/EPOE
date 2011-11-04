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


local data={ -- flags for receiving.. Also added on shared.lua!
	IS_EPOE=1,
	IS_ERROR=2,
	IS_PRINT=4,
	IS_MSG=8,
	IS_MSGN=16,
	IS_SEQ=32,
	IS_MSGC=64,
}

-- Messages can come in multiple parts
-- TODO: If message gets aborted serverside this will fuck up, royally.
local Buffer=""

-- Handle incoming messages
function OnUsermessage(umsg)
	local flags=umsg:ReadChar()
	local str=umsg:ReadString()
	
	if HasFlag(flags,IS_SEQ) then -- Store long messages
		Buffer=Buffer..str
		return
	elseif #Buffer>0 then -- Data in buffer and no SEQ flag. We have something to print! TODO: See above todo.
		str=Buffer..str
		Buffer=''
	end
	
	local nl=NewLine(flags) -- message type specific newline handling

	if HasFlag(flags,IS_EPOE) then
		
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
	internalPrint("Retrying autologin...")
end


------------------------------------
-- Printing to EPOE from client.
------------------------------------

function Msg(...)
	local noerr,str=pcall(ToString,{...}) 
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
		if type(v) == "table" and type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
			hook.Call(TagHuman, nil, nil, nil, v)
		else
			hook.Call(TagHuman, nil, tostring(v), nil, true)
		end		
	end
end

function internalPrint(...)
	local noerr,str=pcall(ToString,{...}) -- just to be sure
	if !str then
		return
	end
	hook.Call(TagHuman,nil,str,IS_EPOE)
end