local e=epoe -- Why not just module("epoe") like elsewhere?
local TagHuman=e.TagHuman

---------------
-- Clientside Console UI
---------------
local epoe_toconsole=CreateClientConVar("epoe_toconsole", "1", true, false)
local epoe_toconsole_colors=CreateClientConVar("epoe_toconsole_colors", "1", true, false)

hook.Add(TagHuman,TagHuman..'_CLI',function(Text,flags,col)
	flags=flags or 0
	if e.HasFlag(flags,e.IS_EPOE) then
		e.ShowGUI() -- Force it
		e.GUI:Activity()
		Msg("[EPOE] ")print(Text)		
		return
	end

	if if e.HasFlag(flags,e.IS_MSGC) and VERSION>150 and epoe_toconsole_colors:GetBool() then
		if col then
			MsgC(col,Text)
			return
		end
	end
	
	-- TODO: Colors
	if epoe_toconsole:GetBool() then
		Msg(Text)
	end
end)