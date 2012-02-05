local function DoClient()
	include('epoe/client.lua')
	include('epoe/client_ui.lua')
	include('epoe/client_gui.lua')
	include('epoe/autoplace.lua')
	include("epoe/client_filter.lua")
end

local function DoServer()
	include('epoe/server.lua')
end
if epoe then -- Implements reloading it all
	-- Prevent hooks from calling


	if SERVER then
		pcall(function() --  in case it's something very weird
			epoe.InEPOE=true -- Disables EPOE functionality
			epoe.DisableTick()
		end)
		epoe=nil
		package.loaded.epoe=nil

		DoServer()

	else -- TODO

		pcall(function()
			epoe.InEPOE=true
			e.GUI:Remove()
		end)

		DoClient()

	end

	return

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

	DoServer()

else
	DoClient()
end
