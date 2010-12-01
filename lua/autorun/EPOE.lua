if epoe then
	-- Prevent hooks from calling

	
	if SERVER then	
		epoe.InEPOE=true -- just leave it be there...
		epoe.DisableTick()
		epoe=nil
		package.loaded.epoe=nil
		include('epoe/server.lua')
	else -- TODO
		include('epoe/client.lua')
	end
	
	return
	
end
	
include('epoe/shared.lua')

if SERVER then

	AddCSLuaFile("autorun/epoe.lua")
	
	AddCSLuaFile("epoe/client.lua")
	AddCSLuaFile("epoe/client_ui.lua")
	AddCSLuaFile("epoe/shared.lua")
	
	include('epoe/server.lua')
	
else

	include('epoe/client.lua')
	include('epoe/client_ui.lua')

end