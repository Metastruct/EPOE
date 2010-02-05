/* 

	Enhanced perception for errors
	Idea taken from ENE(Z)
	
	Copyright (C) Python1320, CapsAdmin
	
*/


_Msg=_Msg     or Msg
_MsgN=_MsgN   or MsgN
_print=_print or print


local _Msg=_Msg
local _MsgN=_MsgN
local _print=_print

if !EPOE then _print("Could not load EPOE server (EPOE not loaded)") return end

EPOE.Subs = EPOE.Subs or {}
local Subscribers=EPOE.Subs


// Prevent deadloops
local Hooked = false


// Our safeguards :)
EPOE.MAX_IN_TICK=250
EPOE.MAX_QUEUE=500

/* Deadloop protection */
local lasttime=CurTime()
local count=0
/* ============ */

// LILO
EPOE.Queue=EPOE.Queue or {}
local queue=EPOE.Queue

EPOE.TramplineLock = false

EPOE.MAX_IN_TICK=EPOE.MAX_IN_TICK-1

local humans=player.GetHumans
local function trampoline(ttype,...) 
		if not EPOE then --(DEBUG)_D("EPOE vanished")
			return end
		if not Hooked then --(DEBUG)_D("Nothooked")
			return end
		if #humans() == 0 or !EPOE.HasSubscribers() then --(DEBUG)_D("NoSubs")
			return end
			
		
		if EPOE.TramplineLock then return end
		
		if lasttime==CurTime() then
				count=count+1
				if count > EPOE.MAX_IN_TICK then
					_MsgN('EPOE: Deadloop protection! During CurTime() the trampoline was ran '..tostring(count) ..'>'..tostring(EPOE.MAX_IN_TICK)..' times! (Locking the trampoline for the rest of the tick + killing queue)')
					EPOE.KillQueue()
					EPOE.TramplineLock=true
					return
				end
		else
			count=0
			lasttime=CurTime()
			EPOE.TramplineLock=false
		end
		
	
		
		

		--(DEBUG)_D("Trampoline! ",ttype,"\"",...,"\"")
		
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
		end
		
		EPOE.QueuePush(glon.encode({ttype,MsgTable}))
		
		
		Hooked=true
end


function EPOE.QueuePush(var) // last in last out
	--(DEBUG)_D("Queue+")
	queue[#queue+1]=var
	hook.Add('Tick',EPOE.Tag,EPOE.Tick)
end

function EPOE.QueuePop() // last in last out
	local var=queue[1]
	if var == nil then return false end
	table.remove( queue, 1 )
	--(DEBUG)_D("Queue-")
	--hook.Add('Tick',EPOE.Tag,EPOE.Tick)
	return var
end

function EPOE.KillQueue()
	queue = {}
	--(DEBUG)_D("Queue----")
end


function EPOE.Tick()
	local _Hooked=Hooked
	Hooked=false
	if #queue==0 then 
		--(DEBUG)_D("Removing tick hook")
		hook.Remove('Tick',EPOE.Tag)
		Hooked=_Hooked
		return
	end
	
	if #queue>EPOE.MAX_QUEUE then
		EPOE.KillQueue()
		--(DEBUG)_D("Killing queue!!!!")
		return
	end
	
	EPOE.Limbo(EPOE.QueuePop())
	
	
	Hooked=_Hooked
end

function EPOE.Limbo(var)
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
	MsgN=MsgN
	print=print
	hook.Remove("LuaError",EPOE.Tag)
	--(DEBUG)_D("UnHooked")
end


// TODO FIXME WARNING YADDA YADDA: CHECK FOR MSG SIZE :|
function EPOE.Send(rp,str)
	local _Hooked=Hooked
	Hooked=false
	
	--(DEBUG)_D("Sending msg")
	umsg.Start(EPOE.Tag,rp)
		umsg.String(str)
	umsg.End()
	--(DEBUG)_D("Done")
	
	Hooked=_Hooked
end

function EPOE.Subscribe(ply,_,args)
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
concommand.Add( EPOE.TagHuman, EPOE.Subscribe )


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
