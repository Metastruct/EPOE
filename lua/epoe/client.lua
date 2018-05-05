local insert=table.insert
local remove=table.remove
local Empty=table.Empty
local setmetatable=setmetatable
local net=net
local IsValid=IsValid
local error=error
local select=select
local next=next
local unpack=unpack
local player=player
local pairs=pairs
local hook=hook
local table=table
local pcall=pcall
local concommand=concommand
local tostring=tostring
local type=type
local string=string
local usermessage=usermessage
local rawget=rawget
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


module( "epoe" )

------------------------------------
-- Receiving
------------------------------------


-- Messages can come in multiple parts
-- TODO: If message gets aborted serverside this will fuck up, royally.
local Buffer=""

local lastmsg="<SHOULD NOT SEE>"
local lastflags=0
-- Handle incoming messages
function ProcessMessage(flags,str,col)

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
			internalPrint("No Access to server")
			return
		end
	end

	-- We are going to add the newline here instead of letting the handlers take care of it so you can just print the stuff and be done with it
	str=str..NewLine(flags)

	-- If we should not let's just return :x
	if not isEpoe and hook.Call(Should_TagHuman,nil,str,flags)==false then
		return
	end
	
	-- PRE-hook for modifying or completely rewriting the text
	local t = PreEPOE{txt=str,flags=flags,color=col}
	if not t then return end
	
	Output(t.txt or str,t.flags or flags,t.color or col)
end

function Output(str,flags,col)
	hook.Run(TagHuman,str,flags,col)
end

function OnMessage(len)
	local flags = net.ReadUInt(8)
	local msgc_col
	if HasMsgCParams(flags) then
		local r,g,b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
		msgc_col = Color(r or 0,g or 255,b or 255,255)
	end
	local str = net.ReadString()
	ProcessMessage(flags,str,msgc_col)
end

net.Receive(Tag,function(len) OnMessage(len) end)


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

function MODULE._internalMsgC(col,...)
	if not col or not col.r then return end
	local ok,str=pcall(ToStringEx,"",...)
	if not ok then internalPrint(str) return end
	if not str then return end

	ProcessMessage(IS_MSGC,str,col)
end

function MODULE.MsgC(...)

	local last_col = col_white
	local vals={} -- todo: use unpack(n,a,b)
	for i=1,select('#',...) do
		local v=select(i,...)
		
		if IsColor(v) then
			if next(vals) then _internalMsgC(last_col,unpack(vals)) end
			vals={}
			last_col=v
		else
			table.insert(vals,v)
		end
		
	end
	
	if next(vals) then
		_internalMsgC(last_col,unpack(vals))
	end
	
end

function MODULE.AddText(...)
	local col=Color(255,255,255,255)
	for k, v in pairs({...}) do
		if type(v) == "table" and type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
			col=Color(v.r,v.g,v.b,255)
		else
			local ok,str=pcall(ToStringEx,"",v)
			ProcessMessage(IS_MSGC,str,col)
		end
	end
end


------------------
-- API
------------------
local api = rawget(MODULE,"api") or {}

api.Msg = MODULE.Msg
api.MsgC = MODULE.MsgC
api.MsgN = MODULE.MsgN
api.print = MODULE.print
api.ErrorNoHalt = MODULE.Err
api.error = function(e,n)
	MODULE.Err(e)
	error(e,(n or 1)+1)
end

-- _G api: Eprint, EMsg
for k,v in next,api do
	G['E'..k] = v
end

MODULE.api = api

function MODULE.setenv(env)
	local t={}
	for k,v in next,api do
		t[k]=v
	end
	local fenv = G.setmetatable({  }, { __index = G.setmetatable(t, { __index = env or G.getfenv(2) or G }) })
	G.setfenv(2, fenv)
end
