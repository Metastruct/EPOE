local e=epoe -- Why not just module("epoe") like elsewhere?
local TagHuman=e.TagHuman

---------------
-- Clientside Console UI
---------------
local epoe_toconsole=CreateClientConVar("epoe_toconsole", "1", true, false)

hook.Add(TagHuman,TagHuman..'_CLI',function(Text,flags)
	flags=flags or 0
	if e.HasFlag(flags,e.IS_EPOE) then
		e.ShowGUI() -- Force it
		e.GUI:Activity()
		Msg("[EPOE] ")print(Text)		
		return
	end
	
	-- TODO: Colors
	if epoe_toconsole:GetBool() then
		Msg(Text)
	end
end)