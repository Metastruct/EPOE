

local G=_G


local umsg=umsg
--local humans=player.GetHumans
local ValidEntity=ValidEntity
local RecipientFilter=RecipientFilter
local error=error
local pairs=pairs
local hook=hook
local table=table
local pcall=pcall
local concommand=concommand
local tostring=tostring
local timer=timer
local len=string.len
local util=util
module( "epoe" )



-- Store global old print functions. Original ones.
G._Msg=G._Msg or G.Msg
G._MsgN=G._MsgN or G.MsgN
G._print=G._print or G.print

-- Store local real messages, real ones
RealMsg=G.Msg
RealMsgN=G.MsgN
RealPrint=G.print


-- Hack
local function ErrorNoHalt(...)
	G.timer.Simple(0.01,G.ErrorNoHalt,...)
end



------------------ SUBS SYSTEM ------------------

	-- Subscribed people
	Sub = {
	 -- Player={stream1,stream2}
	}

	HasNoSubs=true

	function AddSub(pl)
		if ValidEntity(pl) and pl:IsPlayer() then
			HasNoSubs=false
			Sub[pl]=true
			umsg.Start(Tag,pl)	umsg.Char(IS_EPOE)	umsg.String("_S") --[[_S=Subscribe]]	umsg.End()
		end
	end

	function DelSub(pl)
		Sub[pl]=false
		CalculateSubs()
		umsg.Start(Tag,pl)	umsg.Char(IS_EPOE)	umsg.String("_US") --[[_US=Unsubscribe]]	umsg.End()
	end

	function CalculateSubs()
		if table.Count(Sub)==0 then 
			HasNoSubs=true
			DisableTick()
		else
			HasNoSubs=false 
		end
	end

	function OnEntityRemoved(pl)
		if !ValidEntity(pl) then return end
		if 	pl:IsPlayer() then
			DelSub(pl)
		end
	end
	hook.Add('EntityRemoved',TagHuman,OnEntityRemoved)

	-- Override for admin mods :o
	function CanSubscribe(pl)
		return pl:IsAdmin()
	end

	function OnSubCmd(pl,_,argz)
		if not ValidEntity(pl) then return end -- Consoles can't subscribe. Sorry :(
		
		local wantsub=util.tobool(argz[1] or "0")
		
		if wantsub then
			if CanSubscribe(pl) then
				AddSub(pl)
			else
				-- uhoh
				umsg.Start(Tag,pl)	umsg.Char(IS_EPOE)	umsg.String("_NA") --[[_NA=Not admin]]	umsg.End()
			end
		else
			DelSub(pl)
		end
		
	end
	concommand.Add(Tag,OnSubCmd)


	
-- Refresh pretty much everything for us :\ TODO: Clarify
RF=RecipientFilter()
function Refresh()
	--RealMsgN(InEPOE and "IN EPOE","Refresh")
	RF:RemoveAllPlayers()
	CalculateSubs()
	if HasNoSubs then return end
	for pl,_ in pairs(Sub) do
		if ValidEntity(pl) then
			RF:AddPlayer(pl)
		end
		
	end
end



-------------------------------------------------



-- Prevent local errors from screwing our system
InEPOE=true
	
-- Holds the messages that are to be sent to clients
Messages=FIFO() -- shared.lua


-- Protection
function Recover()
	--RealMsgN(InEPOE and "IN EPOE","Recover")
	EnableTick()
	Messages:clear()
	InEPOE=false
	local payload={
		flag=IS_EPOE,
		msg="Warning! Exceeded max queue ("..tostring(MaxQueue or "unknown").."). Aborting messages."
	}
					
	Messages:push(payload)
end

function HitMaxQueue()

	if Messages:len() > MaxQueue then
	
		--RealMsgN(InEPOE and "IN EPOE","HitMaxQueue")
		
		DisableTick()
		Messages:clear()
		InEPOE=true
		timer.Simple(0.1,Recover)
		
		return true
	
	end
	
end

------------------
-- Overrides
------------------
	function OnMsg(...)	
		if InEPOE or HasNoSubs then RealMsg(...) else
			InEPOE = true	
				
				if HitMaxQueue() then return end
				
				EnableTick()
				
				local data={...}
				local err,str=pcall(ToString,data) -- just to be sure
				
				if str then
					PushPayload( IS_MSG , str )
				end
				
				RealMsg(...)
			
			InEPOE=false
		end
	end

	function OnMsgN(...)
		if InEPOE or HasNoSubs then RealMsgN(...) else
			InEPOE = true	
				
				if HitMaxQueue() then return end
				
				EnableTick()
			
				local data={...}
				local err,str=pcall(ToString,data)
				if str then
					PushPayload( IS_MSGN , str )
				end
			
				RealMsgN(...)
			
			InEPOE=false
		end
	end

	function OnPrint(...)
		if InEPOE or HasNoSubs then RealPrint(...) else
			InEPOE = true	
					
				if HitMaxQueue() then return end

				EnableTick()
			
				local data={...}
				local err,str=pcall(ToString,data)
				if str then
					PushPayload( IS_PRINT , str )
				end
			
				RealPrint(...)
			
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
	
------------------
	

local function DivideStr(str,pos)

	local cur,remaining = str:sub(1,pos),str:sub(pos,#str-pos)
	--RealMsgN("DivideStr: o:".."'"..str.."' c:'"..cur.."' r:'"..remaining.."'")
	return cur,remaining
end

-- Make sure our message is less than 200 bytes to make it sendable.
-- If it isn't divide it to parts
function PushPayload(flags,s)
	
	
	local str=""
	local remaining=s
	for i=0,512 do -- while true sounds too dangerous and let's break if stuff like this happens
		str,remaining=DivideStr(remaining,190) -- Max 200 bytes. Hmm...
		if len(remaining)==0 then -- RealMsgN("PushPayload loop (normal op)")
			Messages:push {
				flag=flags, -- Byte
				msg=str -- arbitrary
			}			
			return
		else -- RealMsgN("PushPayload loop longmsg")
			Messages:push {
				flag=flags|IS_SEQ,
				msg=str

			}		
		end
		
	end
	
	-- In case this happened.
	
	EnableTick()
	Messages:clear()
	InEPOE=false			
	Messages:push{flag=IS_EPOE,msg="Warning! PushPayload tried to iterated over 512 times, cancelling queue."}
	
	
	
end

------------------
-- Transmit one from the queue
------------------
function OnBeingTransmit()
	--RealMsgN(InEPOE and "IN EPOE","OnBeingTransmit")
	local payload=Messages:pop()
	if payload==nil then return true end -- Nothing in queue

	umsg.Start(Tag,RF)
		umsg.Char(payload.flag or 0)
		umsg.String(payload.msg or "EPOE ERROR")
	umsg.End()
	
	
end


------------------
-- Ticking (sending messages)
------------------
	function OnTick()
		if InEPOE then return end
		--RealMsgN(InEPOE and "IN EPOE","OnTick")
		InEPOE = true
			
			Refresh()
			if HasNoSubs then 
				Messages:clear() 
			elseif !HitMaxQueue() and Messages:len()>0 then 
			
				for i=1,UMSGS_IN_TICK do 
					
					if OnBeingTransmit() then -- No more in queue
						DisableTick()
						break
					end
					
				end
			
			end
		
		InEPOE=false
	end

	function EnableTick()
		--RealMsgN(InEPOE and "IN EPOE","EnableTick")
		hook.Add('Tick',TagHuman,OnTick)
	end

	function DisableTick()
		--RealMsgN(InEPOE and "IN EPOE","DisableTick")
		hook.Remove('Tick',TagHuman,OnTick)
	end


-- Initialize EPOE
function Initialize()
	InEPOE=true
	
		G.print	"Hooking --"
		G.require	"enginespew"
		
		G.Msg   =	OnMsg
		G.MsgN  =	OnMsgN
		G.print =	OnPrint

		local inhook = false -- This may error for whatever reason and when it does let's not crash the server.
		hook.Add("EngineSpew", TagHuman, function(spewType, msg, group, level) 
			if inhook then return end -- Error once, disable forever...
			inhook = true
			
			if spewType == 1 --[[SPEW_WARNING]] then -- Add dynamic filter?	
				if hook.Call("PreEpoe", GAMEMODE, msg) ~= false then
					OnLuaError( msg ) 
				else
					return false
				end
			end
			inhook = false
		end )
		
	
	InEPOE=false
end

Initialize() -- InitPostEntity? No. | Need to hook as early as possible. Maybe even earlier than currently to grab all prints from modules? Screw the modules..