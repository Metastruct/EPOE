-- EPOE Server Code

require ( "hook" )

local G=_G

local IsValid=IsValid
local assert=assert
local error=error
local pairs=pairs
local pcall=pcall
local tostring=tostring
local tonumber=tonumber
local CreateConVar=CreateConVar
local rawget=rawget
local setmetatable=setmetatable
local RunStringEx=RunStringEx
local FrameTime=FrameTime
local Color=Color
local len=string.len
local next=next
local concommand=concommand
local player=player
local select=select
local net=net
local timer=timer
local string=string
local player=player
local util=util
local math=math
local hook=hook
local ipairs=ipairs
local unpack=unpack
local table=table
local bit=bit

-- inform the client of the version
CreateConVar( "epoe_version", "2.61", FCVAR_NOTIFY )
-- TODO: Move these on clientside
--local epoe_client_traces=CreateConVar("epoe_client_traces","0")
--local epoe_server_traces=CreateConVar("epoe_server_traces","0")
--local epoe_client_errors=CreateConVar("epoe_client_errors","1")
local epoe_relay_msgall = CreateConVar("epoe_relay_msgall","0")

module( "epoe" )
util.AddNetworkString(Tag)

-- How many usermessages can we send in a tick
-- TOO BIG: might flood out admins
local ift = 1 / FrameTime() -- should return tickrate
ift=ift>100 and 100 or ift<16 and 16 or ift
MSGS_IN_TICK = math.ceil ( (6*ift)/(1/33) ) -- OLD: 6
MSGS_IN_TICK = MSGS_IN_TICK>50 and 50 or MSGS_IN_TICK<1 and 1 or MSGS_IN_TICK

-- Constants
local recover_time = FrameTime() -- 0 == skip one tick

-- Store global old print functions. Original ones.
G._Msg=G._Msg or G.Msg
G._MsgC=G._MsgC or G.MsgC
G._MsgN=G._MsgN or G.MsgN
G._print=G._print or G.print
G._MsgAll=G._MsgAll or G.MsgAll
G._ErrorNoHalt=G._ErrorNoHalt or G.ErrorNoHalt
-- Yes, this is a function, not to be confused with "error"
G._Error=G._Error or G.Error


-- Store local real messages, real ones
RealMsg=G._Msg
RealMsgC=G._MsgC
RealMsgN=G._MsgN
RealPrint=G._print
RealMsgAll=G._MsgAll
RealErrorNoHalt=G._ErrorNoHalt
RealError=G._Error -- Caps-error, not lowercase error
Realerror=G.error


------------------ SUBS SYSTEM ------------------

	-- Subscribed people
	Sub = _M.Sub or {
		-- pl = true,
	}
	
	transmit = false
	HasNoSubs = false
	
	function GetTransmit()
		if transmit == false then
		
			transmit = {}
			
			local uids = {}
			for k,v in next,player.GetHumans() do
				uids[v:UserID()]=v
			end
			
			local gotsubs
			for k,v in next,Sub do
				local pl = uids[k]
				if pl then
					table.insert(transmit,pl)
					gotsubs = true
				end
			end
			if gotsubs then
				HasNoSubs = false
			else
				HasNoSubs = true
			end
		end
		return transmit
	end
	
	function RevalidateTransmit()
		transmit = false
		GetTransmit()
	end
	
	function AddSub(pl)
		if !pl or !pl.IsValid or !pl:IsValid() or !pl:IsPlayer() then
			return
		end
		local uid = pl:UserID()
		
		if Sub[uid] then return end
		Sub[uid] = true
		RevalidateTransmit()
		
		Transmit(IS_EPOE,"_S",pl)
	end

	function DelSub(pl,notrans)
		if !pl or !pl.IsValid or !pl:IsValid() or !pl:IsPlayer() then
			return
		end
		local uid = pl:UserID()
		
		if not Sub[uid] then return end
		
		Sub[uid] = nil
		RevalidateTransmit()
		
		if notrans then return end
		
		Transmit(IS_EPOE,"_US",pl)
	end

	-- Could probably remove this.
	function OnEntityRemoved(pl)
		if pl:IsPlayer() then
			DelSub(pl,true)
		end
	end
	hook.Add('EntityRemoved',TagHuman,OnEntityRemoved)

	-- Override for admin mods :o
	function CanSubscribe(pl,unsubscribe)
		--RealPrint( tostring(pl)..(unsubscribe and "unsubscribed from" or "subscribed to").." EPOE" )
		return pl:IsAdmin("epoe")
	end

	function OnSubCmd(pl,_,argz)
		if not (pl and pl.IsValid and pl:IsValid()) then return end

		local wantsub=util.tobool(argz[1] or "0")

		if wantsub then
			if CanSubscribe(pl) then
				AddSub(pl)
			else
				Transmit(IS_EPOE,"_NA",pl)
			end
		else
			DelSub(pl)
			CanSubscribe(pl,true)
		end

	end
	concommand.Add(Tag,OnSubCmd)

	function GetSubscribers()
		return Sub
	end

-------------------------------------------------



-- Prevent local errors from screwing our system
InEPOE=true

-- Holds the messages that are to be sent to clients
local Messages = _M.GetTable and _M.GetTable() or FIFO() -- shared.lua
function GetTable()	return Messages end -- Now you can print epoe table, not this table.


-- Flood Protection, TODO: flood protect flood protection
function Recover()
	EnableTick()
	Messages:clear() -- We were in flood protection mode. Don't continue doing it...

	InEPOE = false

	local payload={ flag=IS_EPOE,
	msg="Queue reset! (Over "..tostring(MaxQueue or "unknown").." messages pushed triggering safeguards)" }
	Messages:push(payload)

end

do -- Ultra fuckup protection
	function RecoverCatastrophe(n)
		EnableTick()

		InEPOE = false

		local payload={ flag=IS_EPOE,
		msg="!!! Catastrophic EPOE error %s. Some messages have been lost! !!!." }
		payload.msg=payload.msg:format(tostring(n))
		Messages:push(payload)

	end


	local recover_count = 0
	local recover_count_max = 5
	function InEPOEChecker()
		if InEPOE then
			if not recover_count then return end
			if recover_count > recover_count_max then 
				local Q=recover_count
				recover_count = false
				timer.Simple(15,function()
					recover_count_max = recover_count_max + 1
					recover_count = Q
				end)
				return
			end
			recover_count = recover_count + 1
			InEPOE = false
			RecoverCatastrophe(recover_count)
		end
	end
	timer.Create(TagHuman,0.3,0,InEPOEChecker)
end

local TickEnabled = false
function EnableTick()
	if TickEnabled then return end
	hook.Add('Tick',TagHuman,OnTick)
	TickEnabled = true
end
local EnableTick=EnableTick

function DisableTick()
	--RealMsgN(InEPOE and "IN EPOE",TickEnabled,"DisableTick")
	TickEnabled = false
	if not TickEnabled then return end
	hook.Remove('Tick',TagHuman)
end
local DisableTick=DisableTick

function HitMaxQueue()

	if Messages:len() > MaxQueue then

		DisableTick()
		Messages:clear()

		InEPOE=true
		timer.Simple(recover_time,Recover)

		return true

	end

end

------------------
-- Overrides
------------------
	function OnMsg(...)
		if InEPOE or HasNoSubs then pcall(RealMsg,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()

				
				local ok,str=pcall(ToStringEx,"",...) -- just to be sure

				if str then
					PushPayload( IS_MSG , str )
				end

				pcall(RealMsg,...)

			InEPOE=false
		end
	end

	function PushMsgC(color,...)
		
		local ok,str=pcall(ToStringEx,"",...)

		if str then
			local msgc_col = color
			PushPayload( IS_MSGC , str, msgc_col )
		end
	end
	
	function OnMsgC(...)
		if InEPOE or HasNoSubs then pcall(RealMsgC,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()
				local last_col = col_white
				local vals={}
				for i=1,select('#',...) do
					local v=select(i,...)
					
					if IsColor(v) then
						if #vals>0 then PushMsgC(last_col,unpack(vals)) end
						vals={}
						last_col=v
					else
						table.insert(vals,v)
					end
					
				end
				
				if #vals>0 then
					PushMsgC(last_col,unpack(vals))
				end
				
				pcall(RealMsgC,...)

			InEPOE=false
		end
	end

	function OnMsgN(...)
		if InEPOE or HasNoSubs then pcall(RealMsgN,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()

				
				local ok,str=pcall(ToStringEx,"",...)
				if str then
					PushPayload( IS_MSGN , str )
				end

				pcall(RealMsgN,...)

			InEPOE=false
		end
	end

	function OnPrint(...)
		if InEPOE or HasNoSubs then pcall(RealPrint,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()

				
				local ok,str=pcall(ToStringEx," ",...)
				if str then
					PushPayload( IS_PRINT , str )
				end

				pcall(RealPrint,...)

			InEPOE=false
		end
	end
	
	function OnMsgAll(...)
		if InEPOE or HasNoSubs then pcall(RealMsgAll,...) else
			InEPOE = true
				
				if HitMaxQueue() then return end

				EnableTick()

				
				local ok,str=pcall(ToStringEx," ",...)
				if str and epoe_relay_msgall:GetBool() then
					PushPayload( IS_MSG , str )
				end

				pcall(RealMsgAll,...)

			InEPOE=false
		end
	end

	function OnLuaError(str)
		if InEPOE or HasNoSubs then return end

		InEPOE = true

			if HitMaxQueue() then return end

			EnableTick()

			PushPayload( IS_ERROR , tostring(str) )

		InEPOE=false
	end
	
	function OnClientLuaError(str)
		if InEPOE or HasNoSubs then return end

		InEPOE = true

			if HitMaxQueue() then return end

			EnableTick()

			PushPayload( IS_CERROR , tostring(str) )

		InEPOE=false
	end
	function OnLuaErrorNoHalt(...)
		if InEPOE or HasNoSubs then pcall(RealErrorNoHalt,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()

				
				local ok,str=pcall(ToStringEx," ",...)
				if str then
					PushPayload( IS_ERROR , str:gsub("\n$",""), false ) -- hack until I fix this for good
				end

				pcall(RealErrorNoHalt,...)

			InEPOE=false
		end
	end
	function OnError(...)
		if InEPOE or HasNoSubs then pcall(RealError,...) else
			InEPOE = true

				if HitMaxQueue() then return end

				EnableTick()

				local ok,str=pcall(ToStringEx," ",...)
				if str then
					PushPayload( IS_ERROR , str:gsub("\n$",""), false ) -- hack until I fix this for good
				end

				pcall(RealError,...)

			InEPOE = false
		end
	end
------------------

------------------
-- API
------------------
	local api = rawget(_M,"api") or {}
	
	function api.Msg(...)
	
		if HitMaxQueue() then return end

		EnableTick()

		
		local ok,str=pcall(ToStringEx,"",...) -- just to be sure

		if str then
			PushPayload( IS_MSG , str )
		end
		
	end

	local function PushMsgC(color,...)
		
		local ok,str=pcall(ToStringEx,"",...)

		if str then
			local msgc_col = color
			PushPayload( IS_MSGC , str, msgc_col )
		end
		
	end
	
	function api.MsgC(...)
		
		if HitMaxQueue() then return end
		EnableTick()
		
		local last_col = col_white
		local vals={}
		for i=1,select('#',...) do
			local v=select(i,...)
			
			if IsColor(v) then
				if #vals>0 then PushMsgC(last_col,unpack(vals)) end
				vals={}
				last_col=v
			else
				table.insert(vals,v)
			end
			
		end
		
		if #vals>0 then
			PushMsgC(last_col,unpack(vals))
		end
				
	end

	function api.MsgN(...)
	
		if HitMaxQueue() then return end
		EnableTick()

		local ok,str=pcall(ToStringEx,"",...)
		if str then
			PushPayload( IS_MSGN , str )
		end

	end

	function api.print(...)
	
		if HitMaxQueue() then return end

		EnableTick()

		
		local ok,str=pcall(ToStringEx," ",...)
		if str then
			PushPayload( IS_PRINT , str )
		end

	end
	
	function api.MsgAll(...)
		
		
		if HitMaxQueue() then return end

		EnableTick()

		local ok,str=pcall(ToStringEx," ",...)
		if str and epoe_relay_msgall:GetBool() then
			PushPayload( IS_MSG , str )
		end


	end
	
	function api.ClientLuaError(str)

		if HitMaxQueue() then return end

		EnableTick()

		PushPayload( IS_CERROR , tostring(str) )

	end
	
	function api.ErrorNoHalt(...)

		if HitMaxQueue() then return end

		EnableTick()

		
		local ok,str=pcall(ToStringEx," ",...)
		if str then
			PushPayload( IS_ERROR , str:gsub("\n$",""), false ) -- hack until I fix this for good
		end

	end
	
	function api.error(...)

		if HitMaxQueue() then return end

		EnableTick()

		local ok,str=pcall(ToStringEx," ",...)
		if str then
			PushPayload( IS_ERROR , str:gsub("\n$",""), false ) -- hack until I fix this for good
		end

	end
	
	-- _G api: Eprint, EMsg
	for k,v in next,api do
		G['E'..k] = v
	end
	
	_M.api = api
	
------------------


function SamePayload(a,b)
	if a==b then return true end -- nil or same message will pass this, hmm
	if not a or not b then return false end

	-- strip repeat flags for comparison
	--a.flag=a.flag BAND andnot(IS_REPEAT)
	--b.flag=b.flag BAND andnot(IS_REPEAT)

	return a.flag==b.flag and a.msg==b.msg
end

-- Check if the payload is same and make a new payload and push that instead
-- NOTE: Removed due to unforeseen behaviour causing more problems than fixes
function DoPush(payload)
	--[[local last = Messages:peek()
	if SamePayload(last,payload) then
		local newload={
			flag= payload.flag|IS_REPEAT,
			msg="" -- no message as previous message sent it
			}
		return Messages:push(newload)
	end]]

	Messages:push(payload)
end

-- Divides the payload to ok sized chunks and THEN sends it.
-- GMod13 needs this too as you don't want to receive 66*64KB every second in the mega worst case scenario
function PushPayload(flags,text,msgc_col)
	
	local txt,i=true,1
	local size=190 -- usermessage size. GMod13 might want bigger at some point :)
	local textlen=#text
	local first=true
	while txt and txt~="" do
	
		txt=text:sub(i,i+size-1)
		i=i+size
		if txt~="" or first then
			local curflags=flags
			if textlen>=i then
				curflags=bit.bor(flags,IS_SEQ) -- enable flag
			end
			local payload = {
				flag=curflags,
				msg=txt,
			}
			if msgc_col then
				payload.msgc_col = msgc_col
			end
			
			DoPush(payload)
		end
		first=false
		
		if i>63*1024 then -- let's stop here. You've done well enough...
			EnableTick()
			Messages:clear()
			InEPOE=false
			Messages:push{flag=IS_EPOE,msg="Cancelling messages, too many iterations."}
			return
		end
	end
end



function Transmit(flags,msg,targets,msgc_col)
	net.Start(Tag)
		net.WriteUInt(flags,8)

		-- seq does not have color
		if HasMsgCParams(flags) then
			msgc_col=msgc_col and IsColor(msgc_col) and msgc_col or col_error
			net.WriteUInt(msgc_col.r,8)
			net.WriteUInt(msgc_col.g,8)
			net.WriteUInt(msgc_col.b,8)
		end
		
		net.WriteString(msg)
	net.Send(targets==true and GetTransmit() or targets)
end

------------------
-- Transmit one from the queue
-- Return: true if queue is empty
------------------
function DoTransmit()

	local payload=Messages:pop()
	if payload==nil then return true end
	local flags=payload.flag or 0
	assert(flags>=0)
	assert(flags<=255)

	local msg=payload.msg or "EPOE ERROR"
	local msgc_col=payload.msgc_col
	
	Transmit(flags,msg,true,msgc_col)
end


------------------
-- What makes you tick!
------------------
function OnTick()
	if InEPOE then return end
	--RealMsgN(InEPOE and "IN EPOE","OnTick")
	InEPOE = true

		if HasNoSubs then
			Messages:clear()
		elseif !HitMaxQueue() and Messages:len()>0 then

			for i=1,MSGS_IN_TICK do

				if DoTransmit() then -- No more in queue
					DisableTick()
					break
				end

			end

		end

	InEPOE=false
end

-- Initialize EPOE
function Initialize() InEPOE=true

	G.Msg			= OnMsg
	G.MsgC			= OnMsgC
	G.MsgN			= OnMsgN
	G.print			= OnPrint
	G.MsgAll		= OnMsgAll
	
	G.ErrorNoHalt	= OnLuaErrorNoHalt
	G.Error	= OnError -- Similar if not same as ErrorNoHalt
	--G.error = OnLuaError
	
	local module_loaded = false
	
	
	local luaerror2_loaded = false--pcall(G.require,"luaerror2")
	
	if luaerror2_loaded then
		luaerror2_loaded = false
		hook.Add("LuaError", TagHuman,function()
			luaerror2_loaded = true
			return true
		end)
		RunStringEx("if_you_see_this__remove_luaerror2()","EPOE")
		hook.Remove("LuaError", TagHuman)
	end
		
	if not module_loaded and luaerror2_loaded then
		module_loaded = true
		local inhook = false
		hook.Add("LuaError", TagHuman,function(runtime, srcfile, srcline, err, stack)

			if inhook then return end
			inhook = true
				
			local stackinfo={}
			for level,info in ipairs(stack or {}) do
				local msg
				if info.what == "C" then
					msg = "C"
				else
					msg = tostring(info.short_src)..':'..tostring(info.currentline)..' \t('..tostring(info.name or "")..')'
				end
				
				if msg then
					table.insert(stackinfo,level..(level>9 and ' ' or '  ')..msg)
				end
			end
			err=err..(#stackinfo >0 and '\n\t'..table.concat(stackinfo,"\n\t")..'\n' or "")

			OnLuaError( err )
			
			inhook = false
		end)
		hook.Add("ClientLuaError",TagHuman,function(pl,err)
			if err and err:sub(1,9)=="\n[ERROR] " then
				err=err:sub(10,-1)
			elseif err then
				err=err:gsub("^\n",'')
			end
			
			err=err and err:gsub("\n$",'') -- temp
			
			OnClientLuaError(tostring(pl)..' ERROR: '..tostring(err))
		end)
	end
	
	local enginespew_loaded
	if not module_loaded then
		enginespew_loaded = pcall(G.require,"enginespew")
	end
	
	if not module_loaded and enginespew_loaded then
		module_loaded = true
		
		local incoming_clienterr
		hook.Add("EngineSpew",TagHuman,function(a,msg,c,d, r,g,b)
			if (!msg or (msg:sub(1,1)~="[" and msg:sub(1,2)~="\n[") or a~=0 or c~="" or d~=0  ) and not incoming_clienterr then return end
			if InEPOE then return end
			
			if incoming_clienterr then
				--RealPrint("CLERRSTOP: '"..msg.."'")
				--if not epoe_client_errors:GetBool() then return end
				local pl,userid=false,incoming_clienterr:match(".+|(%d*)|.-$")
				incoming_clienterr=false
				if userid then
					userid=tonumber(userid)
					for k,v in pairs(player.GetAll()) do
						if v:UserID()==userid then
							pl=v
							break
						end
					end
				end
				msg=msg and msg:gsub("^\n*","") -- trim newlines from beginning
				
				-- epoe_client_traces 1 = print everything from the error
				local newmsg = --[[not  epoe_client_traces:GetBool() and msg:match("%[ERROR%] (.-)\n") or]] tostring(msg:match("%[ERROR%] (.+)") or msg)
				
				-- Remove spaces and newlines from end since Garry loves adding those
				newmsg = newmsg:gsub("[\n ]+$","")
				
				OnClientLuaError( (pl and tostring(pl) or incoming_clienterr and tostring(incoming_clienterr) or "CLIENT").." ERR: "..newmsg )
				
				return
				
			end
			if msg:find("] Lua Error:",1,true) then
				--RealPrint("CLERRSTART: '"..msg.."'")
				incoming_clienterr=msg
				return
			end
			if msg:sub(1,9)=="\n[ERROR] " then -- Does it change if it's a workshop error? If it does, we're fucked.
				msg=msg:sub(10,-1)
				local newmsg = --[[not epoe_server_traces:GetBool() and msg:match("(.-)\n") or]] msg
				
				OnLuaError( newmsg )
				return
			end
		
		end)
	end
	
	InEPOE=false -- !!!!

	if module_loaded then
		if luaerror2_loaded then
			G.print	"[EPOE] Tested and operational! (Using LuaError2)"
		else
			G.print	"[EPOE] Tested and operational! (Using EngineSpew)"
		end
	else
		G.print	"[EPOE WARNING] Loaded, but EngineSpew/LuaError2 are not working! Errors will not show!"
	end

end

-- TODO: Initialize earlier to hook even module prints
Initialize()
