if epoe then -- Implements reloading it all
	-- Prevent hooks from calling


	if SERVER then
		pcall(function() --  in case it's something very weird
			epoe.InEPOE=true -- Disables EPOE functionality
			epoe.DisableTick()
		end)
		epoe=nil
		package.loaded.epoe=nil

	else -- TODO

		pcall(function()
			epoe.InEPOE=true
			e.GUI:Remove()
		end)
	end

end

include('epoe/shared.lua')


if SERVER then

	AddCSLuaFile("autorun/epoe_init.lua")

	AddCSLuaFile("epoe/client.lua")
	AddCSLuaFile("epoe/client_ui.lua")
	AddCSLuaFile("epoe/client_gui.lua")
	AddCSLuaFile("epoe/client_filter.lua")
	AddCSLuaFile("epoe/shared.lua")
	AddCSLuaFile("epoe/autoplace.lua")

	include('epoe/server.lua')

else
	include('epoe/client.lua')
	include('epoe/client_ui.lua')
	include("epoe/client_gui.lua")
	include('epoe/autoplace.lua')
	include("epoe/client_filter.lua")
end
