
CreateClientConVar("epoe_autoplace", 0, true, false)
CreateClientConVar("epoe_autoplace_margin", 2, true, false)

timer.Create("epoe_autoplace", 1, 0, function()
	if not epoe or not epoe.GUI then return end
    local place = math.floor(GetConVarNumber("epoe_autoplace") or 0)
    if place < 1 or place > 9 then return end
	epoe.GUI:SetSize(surface.ScreenWidth() / 2, surface.ScreenHeight() / 3)
	local margin = math.floor(GetConVarNumber("epoe_autoplace_margin") or 0)
    local x, y = (place - 1) % 3 / 2, math.floor((place - 1) / 3) % 3 / 2
    local width, height = epoe.GUI:GetSize()
    local offset_x, offset_y = surface.ScreenWidth() - width - margin * 2, surface.ScreenHeight() - height - margin * 2
    epoe.GUI:SetPos(margin + offset_x * x, margin + offset_y * y)
end)
