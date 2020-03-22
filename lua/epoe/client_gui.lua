
local e=epoe -- we cant be in epoe table or we'd need to add locals here on everything too
local TagHuman=e.TagHuman

-- For reloading
if ValidPanel(e.GUI) then e.GUI:Remove() end

local gradient = surface.GetTextureID( "VGUI/gradient_up" )

local epoe_font = CreateClientConVar("epoe_font", "BudgetLabel", true, false)
local epoe_draw_background = CreateClientConVar("epoe_draw_background", 			"1", true, false)
local epoe_show_in_screenshots = CreateClientConVar("epoe_show_in_screenshots", "0", true, false)
local epoe_keep_active = CreateClientConVar("epoe_keep_active", "0", true, false)
local epoe_max_alpha = CreateClientConVar("epoe_max_alpha", "255", true, false)
local epoe_always_clickable = CreateClientConVar("epoe_always_clickable", "0", true, false)
local epoe_links_mode = CreateClientConVar("epoe_links_mode", "1", true, false)
local epoe_parse_steamids = CreateClientConVar("epoe_parse_steamids", "1", true, false)

--- HELPER ---
local function CheckFor(tbl,a,b)
	local a_len=#a
	local res,endpos=true,1
	while res and endpos < a_len do
		res,endpos=a:find(b,endpos)
		if res then
			tbl[#tbl+1]={res,endpos}
		end
	end
end

local function make_url(url)

	if epoe_parse_steamids:GetBool() then
		if url:find"^76561[0123]%d%d%d%d+$" then
			return 'http://steamcommunity.com/profiles/'..url
		end

		if url:find"^STEAM_0%:[01]:%d+$" then
			local sid = util.SteamIDTo64(url)
			if sid then return 'http://steamcommunity.com/profiles/'..sid end
		end
	end

end

local function SORT1(a, b)
	return a[1] < b[1]
end
local function AppendTextLink(a, callback)

	local result = { }

	local checkpatterns = {
		"https?://[^%s%\"]+",
		"ftp://[^%s%\"]+",
		"steam://[^%s%\"]+"
	}

	if epoe_parse_steamids:GetBool() then
		table.insert(checkpatterns, "76561[0123]%d%d%d%d+")
		table.insert(checkpatterns, "STEAM_0%:[01]:%d+")
	end

	hook.Run("EPOEAddLinkPatterns", checkpatterns)

	for _, patt in pairs(checkpatterns) do
		CheckFor(result, a, patt)
	end

	if #result == 0 then
		return false
	end

	table.sort(result, SORT1)
	local _l, _r
	for k, tbl in next,result do
		local l, r = tbl[1], tbl[2]
		if not _l then
			_l, _r = tbl[1], tbl[2]
			continue
		end

		if l < _r then
			table.remove(result, k)
		end

		_l, _r = tbl[1], tbl[2]
	end

	local function TEX(str)
		callback(false, str)
	end

	local function LNK(str)
		callback(true, str, make_url(str))
	end

	local offset = 1
	local right
	for _, tbl in pairs(result) do
		local l, r = tbl[1], tbl[2]
		local link = a:sub(l, r)
		local left = a:sub(offset, l - 1)
		right = a:sub(r + 1, -1)
		offset = r + 1
		TEX(left)
		LNK(link)
	end

	TEX(right)
	return true
end



--------------






local PANEL={}
function PANEL:Init()

	-- Activity fade
	self.LastActivity = RealTime()

	self:SetFocusTopLevel( true )
	self:SetCursor( "sizeall" )

	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )

	self:DockPadding( 3, 6, 3, 3 )

	local Cfg=vgui.Create( "DHorizontalScroller", self )

		Cfg:DockMargin(-8,0,-8,4)
		Cfg:SetOverlap( -4 )
		Cfg:SetTall(16)
		Cfg:Dock( TOP )

		function Cfg:Paint()
			surface.SetDrawColor(40 ,40 ,40,196)
			surface.SetTexture( gradient )
			surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall())

			surface.SetDrawColor(40 ,40 ,40,196)
			surface.DrawRect(0,0,self:GetWide(),self:GetTall())
			return true
		end

		Cfg.OnMousePressed=function(_,...) self.OnMousePressed(self,...) end
		Cfg.OnMouseReleased=function(_,...) self.OnMouseReleased(self,...) end

		local Button = vgui.Create( "DButton" , self )
			Button:SetText( "Login" )
			function Button:DoClick()
				epoe.AddSub()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		Cfg:AddPanel( Button )
		local Button = vgui.Create( "DButton" , self )
			Button:SetText( "Logout" )
			function Button:DoClick()
				epoe.DelSub()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		Cfg:AddPanel( Button )
		local Button = vgui.Create( "DButton" , self )
			Button:SetText( "Clear" )
			function Button:DoClick()
				e.ClearLog()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		Cfg:AddPanel( Button )


		local function CheckBox(txt,cvar)
			local checkbox = vgui.Create( "DCheckBoxLabel" , self )
				checkbox:SetText( txt )
				checkbox:SetConVar( cvar )
				checkbox:SizeToContents()

				checkbox:SetMouseInputEnabled( true )
				checkbox:SetKeyboardInputEnabled( true )
				function checkbox.OnMouseReleased( _, mousecode )
					self.pressing= false
					return checkbox.Button:Toggle()
				end
				function checkbox.OnMousePressed( checkbox, mousecode )
					self.pressing= true
				--	return checkbox.Button.OnMousePressed( checkbox.Button, mousecode )
				end
				checkbox.Button.OnMouseReleased=checkbox.OnMouseReleased
				checkbox.Label.OnMouseReleased=checkbox.OnMouseReleased
				checkbox.Button.OnMousePressed=checkbox.OnMousePressed
				checkbox.Label.OnMousePressed=checkbox.OnMousePressed

				checkbox.m_iIndent=-16
				checkbox.Button:SetAlpha(0)
				checkbox:SetWide(checkbox:GetWide() -8 )
				checkbox.Paint=function(checkbox,w,h)
					if checkbox.Label:IsHovered() or checkbox:IsHovered() or checkbox.Button:IsHovered() then
						surface.SetDrawColor(255,255,255,self.pressing and 150 or 55)
						surface.DrawRect(0,h-2,w,2)
					end
					if checkbox:GetChecked() then
						surface.SetDrawColor(109+9,207+9,246+9,100)
						surface.DrawRect(0,h-2,w,2)
					end
				end

				checkbox:SetTall( 16 )
			Cfg:AddPanel( checkbox )
		end
		CheckBox("autologin","epoe_autologin")
		CheckBox("time","epoe_timestamps")
		CheckBox("to console","epoe_toconsole")
		CheckBox("show on activity","epoe_show_on_activity")
		CheckBox("no autoscroll","epoe_disable_autoscroll")
		CheckBox("stay active","epoe_keep_active")
		CheckBox("no HUD mode","epoe_always_clickable")
		CheckBox("background","epoe_draw_background")
		CheckBox("screenshots","epoe_show_in_screenshots")

		local FontChooser = vgui.Create("DComboBox", Cfg )
		local function AddFont(txt,name)
			local ok=pcall(function() surface.SetFont(name) end)
			if ok then
				FontChooser:AddChoice(txt,name)
			end
		end

		AddFont("Fixed","BudgetLabel")
		AddFont("Fixed Shadow","DefaultFixedDropShadow")
		AddFont("Fixed Tiny","DebugFixed")

		AddFont("Even smaller","DebugFixedSmall")

		AddFont("Smallest","HudHintTextSmall")
		AddFont("Smaller","ConsoleText")
		AddFont("Small","DefaultSmall")
		AddFont("Chat","ChatFont")

		AddFont("Big","Default")
		AddFont("Bigger","HDRDemoText")

		AddFont("Huge","DermaLarge")
		AddFont("Huger","DermaLarge")

		AddFont("TEST","BUTOFCOURSE")

		function FontChooser.Think(FontChooser)
			FontChooser:ConVarStringThink()
		end

		function FontChooser.PerformLayout(FontChooser,w,h)
			DComboBox.PerformLayout(FontChooser,w,h)

			FontChooser:SizeToContents()
			FontChooser:SetTall(16)
			FontChooser:SetWide(FontChooser:GetWide()+32)

			Cfg:InvalidateLayout()
		end

		-- we're overriding big time
		function FontChooser.OnSelect(FontChooser,_,_,font)
			self.RichText:SetFontInternal(font)
			local _ = self.RichText.SetUnderlineFont and self.RichText:SetUnderlineFont(font)
			RunConsoleCommand("epoe_font",font)
		end
		FontChooser:SetConVar("epoe_font")
		FontChooser:SizeToContents()
		FontChooser:SetTall(16)
		FontChooser:SetWide(FontChooser:GetWide()+32)
		Cfg:AddPanel( FontChooser )

		-- FEEL FREE TO CHANGE/FIX/REMOVE( :( ) THIS
		local ok,err = pcall(function()
			local PlaceChooser = vgui.Create("DComboBox", Cfg )
			PlaceChooser:AddChoice("Wherever", "0")
			PlaceChooser:AddChoice("Top Left", "1")
			PlaceChooser:AddChoice("Top", "2")
			PlaceChooser:AddChoice("Top Right", "3")
			PlaceChooser:AddChoice("Left", "4")
			PlaceChooser:AddChoice("Center", "5")
			PlaceChooser:AddChoice("Right", "6")
			PlaceChooser:AddChoice("Bottom Left", "7")
			PlaceChooser:AddChoice("Bottom", "8")
			PlaceChooser:AddChoice("Bottom Right", "9")
			function PlaceChooser:Think()
				self:ConVarStringThink()
				PlaceChooser:SizeToContents()
				PlaceChooser:SetTall(16)
				PlaceChooser:SetWide(PlaceChooser:GetWide()+32)
			end

			function PlaceChooser:OnSelect(index, value, data)
				LocalPlayer():ConCommand("epoe_autoplace " .. (index - 1))
			end
			PlaceChooser:ChooseOptionID((GetConVarNumber("epoe_autoplace") or 0) + 1)
			PlaceChooser:SizeToContents()
			PlaceChooser:SetTall(16)
			PlaceChooser:SetWide(PlaceChooser:GetWide()+32)
			Cfg:AddPanel( PlaceChooser )
		end)
		if not ok then ErrorNoHalt(err) end
	self.uppermenu=Cfg


	self.canvas=vgui.Create('EditablePanel',self)
	local canvas=self.canvas
	canvas:Dock(FILL)

	self.RichText = vgui.Create('RichText',canvas)
	local RichText=self.RichText
		RichText:InsertColorChange(255,255,255,255)
		RichText:SetPaintBackgroundEnabled( false )
		RichText:SetPaintBorderEnabled( false )
		RichText:SetMouseInputEnabled(true)
		-- We'll keep it visible constantly but clip it off to make the richtext behave how we want
		RichText:SetVerticalScrollbarEnabled(true)

		RichText:Dock(FILL)
		function RichText.HideScrollbar()
			RichText.__background=false
			RichText:DockMargin(0,0,-20,0)
		end
		function RichText.ShowScrollbar()
			RichText.__background=true
			RichText:DockMargin(0,0,0,0)
		end
		RichText:HideScrollbar()
		function RichText:Paint()
			if self.__background then
				surface.SetDrawColor(70,70,70,40)
				surface.DrawOutlinedRect(0,0,self:GetWide(),self:GetTall())
			end
		end


		local function linkhack(self,id)
			self:InsertClickableTextStart( id )
			self:AppendText' '
			self:InsertClickableTextEnd()
			self:AppendText' '
		end

		RichText.AddLink=function(richtext,func,func2)
			-- warning: infinitely growing list. fix!
			richtext.__links=richtext.__links or {}
			local id = table.insert(richtext.__links,func2)
			richtext.__links[id]=func2

			local cbid = "cb_"..tostring(id)
			linkhack(richtext,cbid)

			richtext:InsertClickableTextStart(cbid)
				func(richtext)
			richtext:InsertClickableTextEnd()
		end
		RichText.ActionSignal=function(richtext,key,value)
			if key~="TextClicked" then return end

			local id = value:match("cb_(.+)",1,true)
			id=tonumber(id)
			local callback = id and richtext.__links[id]
			if callback then
				callback(richtext,value)
				return
			end
		end
	self:ButtonHolding(false)
end

function PANEL:PostInit()
	self.RichText:SetVerticalScrollbarEnabled(true)

	local ok = pcall(function()
		self.RichText:SetFontInternal( epoe_font:GetString() )

		local _ = self.RichText.SetUnderlineFont and self.RichText:SetUnderlineFont(epoe_font:GetString())
	end)

	if not ok then
		RunConsoleCommand("epoe_font","BudgetLabel")
		self.RichText:SetFontInternal( "BudgetLabel" )
	end

end


---------------------
-- Text manipulation
---------------------
-- We don't want a newline appended right away so we hack it up..
PANEL.__appendNL=false
function PANEL:AppendText(txt)
	if self.__appendNL then
		self.RichText:AppendText "\n"
	end
	if txt:sub(-1)=="\n" then
		self.__appendNL=true
		txt = txt:sub(1,txt:len()-1)
	else
		self.__appendNL=false
	end

	-- fix crashing from big texts
	-- limit around 512,000
	if #txt > 510000 then
		txt = txt:sub(1, 510000) .. "..."
	end

	self.RichText:AppendText(txt)
end

function PANEL:AppendTextX(txt)
	local lmode = epoe_links_mode:GetInt()
	if lmode==0 then
		return self:AppendText(txt)
	end

	local function func(link,url,real_url)
		if url:len()==0 then return end
		real_url = real_url or url
		if link then
			self.RichText:AddLink(
				function()
					self:ResetLastColor()
					self:AppendText(url)
				end,
				function()
					local lmode = epoe_links_mode:GetInt()
					if lmode >= 2 then
						SetClipboardText(real_url)
						-- should probably print this on EPOE?
						if lmode==2 then
							LocalPlayer():ChatPrint("Copied to clipboard: "..real_url.." ")
						end
					end
					if lmode==1 or lmode>2 then
						local handled = hook.Run("EPOEOpenLink", real_url)

						if not handled then
							gui.OpenURL(real_url)
						end
					end
				end
			)
		else
			self:AppendText(url)
		end
	end

	local res = AppendTextLink(txt,func)
	if not res then
		self:AppendText(txt)
	end
end


function PANEL:Clear()
	self.RichText:SetText ""
	self.RichText:GotoTextEnd()
end


function PANEL:SetColor(r,g,b)
	self.RichText:InsertColorChange(r,g,b,255)
	self.RichText.lr = r
	self.RichText.lg = g
	self.RichText.lb = b
end

function PANEL:ResetLastColor(r,g,b)
	local r = self.RichText.lr or r or 255
	local g = self.RichText.lg or g or 255
	local b = self.RichText.lb or b or 255
	self.RichText:InsertColorChange(r,g,b,255)
end
---------------------
-- Visuals
---------------------
--[[function PANEL:PerformLayout()
	self.RichText:InvalidateLayout()
end]]--

function PANEL:Paint(w,h)
	-- cvar callback ffs
	if self.Last_SetRenderInScreenshots ~= epoe_show_in_screenshots:GetBool() then
		local new = epoe_show_in_screenshots:GetBool()
		self.Last_SetRenderInScreenshots = new
		self:SetRenderInScreenshots(new)
	end

	if self.__repeatact then
		if self.__repeatact>RealTime() then

			surface.SetDrawColor(180,230 ,255,196)
			surface.DrawRect(0,0,3,6)
		else
			self.__repeatact = false
		end
	end

	if not self.__holding and not epoe_draw_background:GetBool() and not self.being_hovered then return end

	if self.__holding then
		surface.SetDrawColor(40 ,40 ,40,196)
		local q=16+4
		surface.DrawRect(0,q,w,h-q)

		-- header
			surface.SetDrawColor(90,90,90,255)
			surface.DrawRect(0,0,w,16)
		if self.__highlight then
			surface.SetDrawColor(35 ,35 ,35,255)
		else
			surface.SetDrawColor(30 ,30 ,30,255)
		end
			surface.DrawRect(1,1,w-2,16-2)

		local txt="EPOE - Enhanced Perception Of Errors"
		surface.SetFont"DebugFixed"
		local w,h=surface.GetTextSize(txt)
		surface.SetTextPos(3,8-h*0.5)
		if self.__highlight then
			surface.SetTextColor(255,255,255,255)
		else
			surface.SetTextColor(150,150,150,255)
		end
		surface.DrawText(txt)
	else
		surface.SetDrawColor(40 ,40 ,40,196)
		surface.DrawRect(0,0,w,h)
	end
	return true
end

---------------------
-- Functionality
---------------------
function PANEL:ButtonHolding(isHolding)
	self.__holding=isHolding
	if isHolding then
		self:DockPadding( 8, 16+4, 8, 8 )
		self.being_hovered = true
		self.RichText:ShowScrollbar()
		self.uppermenu:Dock(TOP)
		self.uppermenu:SetVisible(true)
		self:FixPosition()
		self:InvalidateLayout()
		self:SetParent()
	else
		self.being_hovered = false
		self.RichText:HideScrollbar()
		self.uppermenu:Dock(NODOCK)
		self:DockPadding( 0,0,0,0 )
		self.uppermenu:SetVisible(false)
		self:InvalidateLayout()
		if not epoe_always_clickable:GetBool() then
			self:ParentToHUD()
		end
	end
end


local epoe_ui_holdtime=CreateClientConVar("epoe_ui_holdtime","5",true,false)--seconds
local remainvisible=CreateClientConVar("epoe_ui_obeydrawing","1",true,false)
local fadespeed=CreateClientConVar("epoe_ui_fadespeed","3",true,false)--seconds
function PANEL:Think()

	if not self.__starthack then
		self.__starthack=true
		self:PostInit()
	end

	local mx = gui.MouseX()
	local my = gui.MouseY()

	local px, py = self:GetPos()

	if
		mx > px and
		mx < px + self:GetWide() and
		my > py and
		my < py + self:GetTall()
	then
		self.being_hovered = true
		--self.RichText:PerformLayout()
	else
		--self.RichText:PerformLayout()
		self.being_hovered = false
	end


	-- Hiding for gmod camera..
	if remainvisible:GetBool() and hook.Call('HUDShouldDraw',GAMEMODE,"CHud"..TagHuman)==false and not self.being_hovered then self:SetAlpha(0) return end
	if (self.Dragging) then



		local x = mx - self.Dragging[1]
		local y = my - self.Dragging[2]

		--if ( self:GetScreenLock() ) then

			x = math.Clamp( x, 0, ScrW() - self:GetWide() )
			y = math.Clamp( y, 0, ScrH() - self:GetTall() )

		--end

		self:SetPos( x, y )

	end


	if ( self.Sizing ) then

		local x = mx - self.Sizing[1]
		local y = my - self.Sizing[2]

		if ( x < 100 ) then x = 100 end
		if ( y < 18 ) then y = 18 end

		self:SetSize( x, y )
		self:SetCursor( "sizenwse" )
		return

	end

	if ( self.Hovered and
		 --self.m_bSizable and
		 mx > (self.x + self:GetWide() - 20) and
		 my > (self.y + self:GetTall() - 20) ) then

		self:SetCursor( "sizenwse" )
		return

	end

	if ( self.Hovered and my < (self.y + 20) ) then
		self:SetCursor( "sizeall" )
		self.__highlight=true
		return
	end

	self.__highlight=false

	self:SetCursor( "arrow" )
	if self:IsActive() then self:Activity() end

	local inactive_time = RealTime() - self.LastActivity
	--print("inactive_time",inactive_time)
	local epoe_ui_holdtime=epoe_ui_holdtime:GetInt()
	local fadespeed=fadespeed:GetInt()
	inactive_time = ( inactive_time - epoe_ui_holdtime ) * ( 255 / fadespeed )
	--print("inactive_time post",inactive_time)

	local alpha = 255 - ( (inactive_time >= 255 and 255) or (inactive_time <= 0 and 0) or inactive_time )
	if alpha<=0 then
		self:SetVisible(false)
		self:SetAlpha(255)
	end

	local alphascale = 255
	if not self.__highlight and not self.__holding then
		alphascale = epoe_max_alpha:GetInt()
		alphascale = alphascale >255 and 255 or alphascale<0 and 0 or alphascale
		alphascale=alphascale/255
	end
	self:SetAlpha(math.ceil(alpha*alphascale))
end

function PANEL:OnMousePressed( mc )

	if mc == MOUSE_RIGHT or ( gui.MouseX() > (self.x + self:GetWide() - 20) and
			gui.MouseY() > (self.y + self:GetTall() - 20) ) then
		self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
		self:MouseCapture( true )
		return
	else
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		return
	end

end
function PANEL:FixPosition()
	local x,y=self:GetPos()
	local w,h=self:GetSize()
	local sw,sh=ScrW(),ScrH()
	local failed=false
	if w > sw then
		failed=true
		w=sw
	end
	if h > sh then
		failed=true
		h=sh
	end
	if x > sw then
		failed=true
		x=0
	end
	if y > sh then
		failed=true
		y=0
	end
	if x+w > sw then
		failed=true
		x=sw-w
	end
	if y+h > sh then
		failed=true
		y=sh-h
	end

	if failed then
		self:SetPos(x,y)
		self:SetSize(w,h)
		--self.RichText:AppendText"GUI: Recovered position after invalid values\n"
	end
end

function PANEL:OnMouseReleased()

	self.Dragging = nil
	self.Sizing = nil

	self:FixPosition()
	local x,y=self:GetPos()
	e.GUI:SetCookie("w",self:GetWide())
	e.GUI:SetCookie("h",self:GetTall())
	e.GUI:SetCookie("x",x)
	e.GUI:SetCookie("y",y)

	self:MouseCapture( false )

end

function PANEL:ToggleActive()
	local state=epoe_keep_active:GetBool()

	RunConsoleCommand("epoe_keep_active",state and "0" or "1")

	e.internalPrint(state and "Fading Enabled" or "Fading Disabled")

end

function PANEL:IsActive()

	if epoe_keep_active:GetBool() or self.being_hovered or self:HasFocus() or vgui.FocusedHasParent( self ) then return true end

end

-- Bring up if something happened.
function PANEL:Activity()
	self:SetAlpha(255)
	self.LastActivity=RealTime()
end
PANEL.OnCursorMoved=PANEL.Activity

function PANEL:Repeat()
		self.__repeatact = RealTime()+0.01
end


vgui.Register( "EPOEUI", PANEL, "EditablePanel" )



function e.CreateGUI()
	if not ValidPanel(e.GUI) then
		e.GUI=vgui.Create('EPOEUI')
		if not ValidPanel(e.GUI) then
			return
		end
		e.GUI:SetCookieName("epoe2_gui")
		local w = tonumber( e.GUI:GetCookie("w") ) or ScrW()*0.5
		local h = tonumber( e.GUI:GetCookie("h") ) or ScrH()*0.25
		local x = tonumber( e.GUI:GetCookie("x") ) or ScrW()*0.5 - w*0.5
		local y = tonumber( e.GUI:GetCookie("y") ) or ScrH() - h

		e.GUI:SetSize(w,h)
		e.GUI:SetPos(x,y)
	end
end

function e.ShowGUI(show)
	e.CreateGUI()
	e.GUI:SetVisible(show==nil or show)
	e.GUI:Activity()
end

function e.ClearLog()
	if ValidPanel( e.GUI ) then
		e.GUI:Clear()
	end
end
concommand.Add('epoe_clearlog', e.ClearLog)

-- Debug
concommand.Add('epoe_ui_remove',function()
	if ValidPanel(e.GUI) then e.GUI:Remove() end
end)

local threshold  = 0.35 -- I'm sorry if you can't click this fast!
local lastclick  = 0

local function epoe_toggle(_,cmd,args)
	if cmd=="+epoe" then

		gui.EnableScreenClicker(true)
		e.ShowGUI() -- also creates it
		local egui=e.GUI
		if ValidPanel(egui) then

			local x,y=egui:LocalToScreen( )
			x,y=x+egui:GetWide()*0.5,y+10
			gui.SetMousePos(x,y)

			if lastclick+threshold>RealTime() then -- Doubleclick
				lastclick = 0 -- reset
				e.GUI:ToggleActive()
			else
				lastclick=RealTime()
			end

			e.GUI:ButtonHolding(true)

		end
	else
		gui.EnableScreenClicker(false)
		e.GUI:ButtonHolding(false)
	end
end

concommand.Add('+epoe',epoe_toggle)
concommand.Add('-epoe',epoe_toggle)


----------------------------
-- Hooking, timestamps, activity showing
----------------------------

local epoe_timestamps = CreateClientConVar("epoe_timestamps", 			"1", true, false)
local epoe_timestamp_format = CreateClientConVar("epoe_timestamp_format", 			"%H:%M", true, false)
local epoe_show_on_activity = CreateClientConVar("epoe_show_on_activity", 	"1", true, false)
local epoe_disable_autoscroll = CreateClientConVar("epoe_disable_autoscroll", 	"0", true, false)
local notimestamp  = false

local prevtext
hook.Add( TagHuman, TagHuman..'_GUI', function(newText,flags,c)
	flags = flags or 0

	-- create the gui (if possible) so we can print epoe.api prints also regardless of subscription status
	local ok,err  = pcall(e.CreateGUI)
	if not ok then ErrorNoHalt(err..'\n') end

	if ValidPanel( e.GUI ) then
		local epoemsg = e.HasFlag(flags,e.IS_EPOE)

		if epoemsg then
			e.ShowGUI() -- Force it
			e.GUI:Activity()
		end

		if epoemsg or epoe_show_on_activity:GetBool() then
			e.ShowGUI()
			local same = prevtext==newText
			prevtext=newText
			if same then
				e.GUI:Repeat()
			end
			e.GUI:Activity()
		end

		if epoe_timestamps:GetBool() then
			if not notimestamp then
				e.GUI:SetColor(100,100,100)	e.GUI:AppendText(			"[")

				local formatted_stamp = os.date(epoe_timestamp_format:GetString())
				e.GUI:SetColor(255,255,255)	e.GUI:AppendText(formatted_stamp)

				e.GUI:SetColor(100,100,100)	e.GUI:AppendText(			"] ")
			end
			notimestamp = not ( newText:Right(1)=="\n" ) -- negation hard
		end

		if epoemsg then
			e.GUI:SetColor(255,100,100)
			e.GUI:AppendText("[EPOE] ")
			e.GUI:SetColor(255,250,250)
			e.GUI:AppendTextX(newText.."\n")
			notimestamp = false
			return
		end

		-- did I really write this. Oh well...
		if e.HasFlag(flags,e.IS_MSGC) and c and type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" then
			e.GUI:SetColor(c.r, c.g, c.b)
		elseif e.HasFlag(flags,e.IS_ERROR) then
			e.GUI:SetColor(255,80,80)
		elseif e.HasFlag(flags,e.IS_CERROR) then
			e.GUI:SetColor( 234,111,111)
		elseif e.HasFlag(flags,e.IS_MSGN) or e.HasFlag(flags,e.IS_MSG) then
			e.GUI:SetColor( 255,181,80)
		else
			e.GUI:SetColor(255,255,255)
		end

		e.GUI:AppendTextX(newText)

		if not epoe_disable_autoscroll:GetBool() and not e.GUI.being_hovered then
			e.GUI.RichText:GotoTextEnd()
		end

	end
end)
