local epoe_autoplace = CreateClientConVar("epoe_autoplace", 0, true, false)
local epoe_autoplace_margin = CreateClientConVar("epoe_autoplace_margin", 0, true, false)
local epoe_autoplace_scale_x = CreateClientConVar("epoe_autoplace_scale_x", 0.5, true)
local epoe_autoplace_scale_y = CreateClientConVar("epoe_autoplace_scale_y", 0.25, true)

timer.Create("epoe_autoplace", 1, 0, function()
	if not epoe or not IsValid(epoe.GUI) then return end
	local place = math.floor(epoe_autoplace:GetFloat() or 0)
	if place < 1 or place > 9 then return end
	epoe.GUI:SetSize(surface.ScreenWidth() * epoe_autoplace_scale_x:GetFloat(), surface.ScreenHeight() * epoe_autoplace_scale_y:GetFloat())
	local margin = math.floor(epoe_autoplace_margin:GetFloat() or 0)
	local x, y = (place - 1) % 3 / 2, math.floor((place - 1) / 3) % 3 / 2
	local width, height = epoe.GUI:GetSize()
	local offset_x, offset_y = surface.ScreenWidth() - width - margin * 2, surface.ScreenHeight() - height - margin * 2
	epoe.GUI:SetPos(margin + offset_x * x, margin + offset_y * y)
end)
