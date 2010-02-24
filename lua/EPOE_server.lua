/* 

	Enhanced Perception Of Errors
	Idea taken from ENE(Z)
	
	Copyright (C) 2010        Python1320, CapsAdmin
	
*/

-- Overrides, don't reoverride.
_Msg=_Msg     or Msg
_MsgN=_MsgN   or MsgN
_print=_print or print

-- Let us receive errors from EPOE
local _ErrorNoHalt=ErrorNoHalt
local function ErrorNoHalt(...)
	timer.Simple(0.01,_ErrorNoHalt,...)
end

local _Msg=_Msg
local _MsgN=_MsgN
local _print=_print

if !EPOE then error("Could not load EPOE Server (EPOE not found)") end

EPOE.Subs = EPOE.Subs or {}
local Subscribers=EPOE.Subs


// Prevent deadloops
local Hooked = false


// Safeguards
EPOE.MAX_IN_TICK=350 -- Maximum number of calls during a tick before the queue is discarded
EPOE.MAX_QUEUE=500 -- Maximum number of entries in the queue. Low for many lua coders?

/* Deadloop protection */
	local lasttime=CurTime()
	local count=0
/* ============ */

// Last in last out queue type
EPOE.Queue=EPOE.Queue or {}
local queue=EPOE.Queue

EPOE.TRAMPOLINE_LOCK = false

EPOE.MAX_IN_TICK=EPOE.MAX_IN_TICK-1

-- This function should not fatal error in any scenario!!!
local humans=player.GetHumans
local function trampoline(ttype,...) 
		
		if !EPOE
		or !Hooked
		--RELOCATED or (EPOE.TRAMPOLINE_LOCK and lasttime==CurTime())
		or #humans() == 0
		or !EPOE.HasSubscribers()
		then return end

		
		
		if lasttime==CurTime() then
				
				if EPOE.TRAMPOLINE_LOCK then return end
				
				count=count+1
				if count > EPOE.MAX_IN_TICK then
					EPOE.KillQueue()
					EPOE.TRAMPOLINE_LOCK=true
					ErrorNoHalt('EPOE: Deadloop protection! During CurTime() the trampoline was ran '..tostring(count) ..'>'..tostring(EPOE.MAX_IN_TICK)..' times! (Locking the trampoline for the rest of the tick + killing queue)')
					return
				end
				
		else
			count=0
			lasttime=CurTime()
			EPOE.TRAMPOLINE_LOCK=nil
		end
		
		--(DEBUG)_D("trampoline! ",ttype,"\"",...,"\"")
		
		local MsgTable={...}
		
		if #MsgTable==0 then
			--(DEBUG)_D("	TBLEMPTY")
			return
		end

		local lastmsg=MsgTable[#MsgTable]
		
		// Testing if it is a newline script after all.
		if type(lastmsg) == "string" then
			if ttype==EPOE.T_NoEnd and string.sub(lastmsg,#lastmsg)=='\n' then
				--(DEBUG)_D("	Type change",ttype,"->",EPOE.T_HasEnd)
				ttype=EPOE.T_HasEnd
			end
		end
		
		for k,v in pairs(MsgTable) do
			if type(v) == "string" then
				MsgTable[k]=string.Trim(v,'\n')
			end
			if type(v) == "function" then
				MsgTable[k]=tostring(v) -- TODO
			end
		end
		if !pcall(function()
			EPOE.QueuePush(glon.encode(	{ttype,			MsgTable		}	))
		end) then ErrorNoHalt"TODO:FIXME:ERROR: GLON ENCODE FAILURE" end
		-- 							{newline_type,	message_table	}
		
		
		--Hooked=true
		
end


function EPOE.QueuePush(var) // last in last out
	--(DEBUG)_D("Queue+")
	queue[#queue+1]=var
	hook.Add('Tick',EPOE.Tag,EPOE.Tick)
end

function EPOE.QueuePop() // last in last out
	local var=queue[1]
	table.remove( queue, 1 )
	if var == nil then return false end
	--(DEBUG)_D("Queue-")
	--hook.Add('Tick',EPOE.Tag,EPOE.Tick)
	return var
end

function EPOE.KillQueue()
	while #queue>0 do
		EPOE.QueuePop()
	end
	--(DEBUG)_D("Queue----")
end

function EPOE.Tick()
	local _Hooked=Hooked Hooked=false
	if #queue==0 then 
		--(DEBUG)_D("Removing tick hook")
		hook.Remove('Tick',EPOE.Tag)
		Hooked=_Hooked
		return
	end
	
	if #queue>EPOE.MAX_QUEUE then
		EPOE.KillQueue()
		Hooked=_Hooked
		ErrorNoHalt"Tick queue kill"
		return
	end
	
	EPOE.Limbo(EPOE.QueuePop())
	
	Hooked=_Hooked
end

function EPOE.Limbo(var)
	if !var then return end
	local hasplayers=false
	local rp=RecipientFilter()
	for ply,status in pairs(Subscribers) do
		if EPOE.ValidReceiver(ply) then
			rp:AddPlayer(ply)
			--(DEBUG)_D("Adding to ply",ply)
			hasplayers=true
		else
			--(DEBUG)_D("Not valid rcv",ply,status)
		end
	end
	if hasplayers then
		EPOE.Send(rp,var)
	end
	
end

function EPOE.InitHooks()
	Hooked=false
	--(DEBUG)_D("Hooking")
	require'luaerror'
	
	Msg  =	function(...) trampoline(EPOE.T_NoEnd,...) _Msg(...) 	end
	MsgN =	function(...) trampoline(EPOE.T_HasEnd,...)  	_MsgN(...) 	end
	print=	function(...) trampoline(EPOE.T_HasEnd,...) 		_print(...) end

	hook.Add("LuaError",EPOE.Tag,function(msg) trampoline(EPOE.T_HasEnd,msg) end)
	
	--(DEBUG)_D("Hooked")
	Hooked=true
end


function EPOE.RemoveHooks()
	Hooked=false
	--(DEBUG)_D("UnHooking")
	Msg=_Msg
	MsgN=_MsgN
	print=_print
	hook.Remove("LuaError",EPOE.Tag)
	--(DEBUG)_D("UnHooked")
end


// TODO FIXME WARNING YADDA YADDA: CHECK FOR MSG SIZE :|
function EPOE.Send(rp,str)
	local _Hooked=Hooked
	Hooked=false
	
	--(DEBUG)_D("Sending msg")
	if string.len(str) > 250 then --TODO
		ErrorNoHalt"EPOE: Too long message, not sending"
	end
	
	umsg.Start(EPOE.Tag,rp)
		umsg.String(str)
	umsg.End()
	--(DEBUG)_D("Done")
	
	Hooked=_Hooked
end

function EPOE.Subscribe_cmd(ply,_,args)
	local mode=args[1]
	if ply and ply:IsValid() and ply:IsPlayer() and args[1] then
		if  ply:IsSuperAdmin() and (mode == "1" || mode == "subscribe" || mode == "sub") then
			EPOE.Subscribe(ply)
			ply:ChatPrint("EPOE: Subscribed")
			_print("EPOE: "..tostring(ply).." Subscribed!")
		elseif mode == "0" || mode == "unsubscribe" || mode == "unsub"  then
			if Subscribers[ply] then
				EPOE.Subscribe(ply,true)
				ply:ChatPrint("EPOE: Unsubscribed")
				_print("EPOE: "..tostring(ply).." Unsubscribed!")
			end
		else
			--(DEBUG)_D("Err cmd",cmd,ply,mode)
		end
	else
		--(DEBUG)_D("Err cmd 2",cmd,ply,mode)
	end
end
concommand.Add( EPOE.TagHuman, EPOE.Subscribe_cmd )

function EPOE.Subscribe(ply,unsubscribe)
	if ply and ply:IsValid() and ply:IsPlayer() then
		if !unsubscribe then
			Subscribers[ply] = true
		else
			Subscribers[ply] = nil
		end
		return true
	else
		return false
	end
	
end


function EPOE.HasSubscribers() --wtf?
	for _,_ in pairs(Subscribers) do
		return true
	end
	return false
end


function EPOE.ValidReceiver(ply)
	if ply
	and ply:IsValid()
	and Subscribers[ply]
	and Subscribers[ply] == true
	--and ply:IsPlayer()
	--and !ply:IsBot()
	then
		return true
	else
		--(DEBUG)_D("Not valid receiver",ply)
		return false
	end
end
