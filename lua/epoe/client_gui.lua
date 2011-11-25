local e=epoe -- Why not just module("epoe") like elsewhere?
local TagHuman=e.TagHuman


local gradient = surface.GetTextureID( "VGUI/gradient_up" )

local epoe_font = CreateClientConVar("epoe_font", 			"ConsoleFont", true, false)
local epoe_draw_background = CreateClientConVar("epoe_draw_background", 			"1", true, false)


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
local function AppendTextLink(a,callback)

	local result={}
	CheckFor(result,a,"https?://[^%s%\"]+")
	CheckFor(result,a,"ftp://[^%s%\"]+")
	CheckFor(result,a,"steam://[^%s%\"]+")
	
	--todo
	--CheckFor(result,a,"^www%.[^%s%\"]+")
	--CheckFor(result,a,"[^%s%\"]www%.[^%s%\"]+")
	
	if #result == 0 then return false end
	
	table.sort(result,function(a,b) return a[1]<b[1] end)

	-- Fix overlaps
	local _l,_r
	for k,tbl in pairs(result) do
		
		local l,r=tbl[1],tbl[2]

		if not _l then 
			_l,_r=tbl[1],tbl[2]
			continue
		end
		
		if l<_r then table.remove(result,k) end
		
		_l,_r=tbl[1],tbl[2]
	end

	local function TEX(str) callback(false,str) end
	local function LNK(str) callback(true,str) end

	local offset=1
	local right
	for _,tbl in pairs(result) do
		local l,r=tbl[1],tbl[2]
		local link=a:sub(l,r)
		local left=a:sub(offset,l-1)
		right=a:sub(r+1,-1)
		offset=r+1
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
	self.keepactive = 	false
	
	self:SetFocusTopLevel( true )
	self:SetCursor( "sizeall" )
	
	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )	

	self:DockPadding( 3, 4, 3, 3 )
	local List=vgui.Create( "DPanelList", self )
		
		List:SetSpacing( 4 ) 
		List:SetPadding( 0 ) 
		List:SetTall( 18 )
		
		List:EnableHorizontal( true ) 
		
		List:Dock( TOP )
		List:SetPaintBackgroundEnabled( false )
		List:SetPaintBorderEnabled( false )		
		List:SetVerticalScrollbarEnabled( false ) -- ??
		List:EnableVerticalScrollbar( ) -- I would rather take the scrolling only but oh well.. 
		
		function List:Paint() 
			surface.SetDrawColor(40 ,40 ,40,196)
			surface.SetTexture( gradient )
			surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall())
			
			surface.SetDrawColor(40 ,40 ,40,196)
			surface.DrawRect(0,0,self:GetWide(),self:GetTall()) 
			return true 
		end
		
		List.OnMousePressed=function(_,...) self.OnMousePressed(self,...) end
		List.OnMouseReleased=function(_,...) self.OnMouseReleased(self,...) end
		
		local Button = vgui.Create( "DButton" )
			Button:SetText( "Login" )
			function Button:DoClick()
				epoe.AddSub()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )
		local Button = vgui.Create( "DButton" )
			Button:SetText( "Logout" )
			function Button:DoClick()
				epoe.DelSub()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )

		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Autologin" )
			checkbox:SetConVar( "epoe_autologin" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Timestamp" )
			checkbox:SetConVar( "epoe_timestamps" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "printconsole" )
			checkbox:SetConVar( "epoe_toconsole" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Show On Activity" )
			checkbox:SetConVar( "epoe_show_on_activity" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox )
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "No Autoscroll" )
			checkbox:SetConVar( "epoe_disable_autoscroll" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox )
		local Button = vgui.Create( "DButton" )
			Button:SetText( "Clear" )
			function Button:DoClick()
				e.ClearLog()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 16 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "BG" )
			checkbox:SetConVar( "epoe_draw_background" )
			checkbox:SizeToContents() checkbox:SetTall( 16 )
		List:AddItem( checkbox )	
		
		local FontChooser = vgui.Create(VERSION>=130 and "DComboBox" or "DMultiChoice", Frame )
		FontChooser:AddChoice("Default","Default")
		FontChooser:AddChoice("DebugFixed","DebugFixed")
		FontChooser:AddChoice("HudHintTextSmall","HudHintTextSmall")
		FontChooser:AddChoice("BudgetLabel","BudgetLabel")
		FontChooser:AddChoice("ConsoleText","ConsoleText")
		function FontChooser:OnSelect(_,_,font)
			e.GUI.RichText:SetFont(font)
		end
		FontChooser:SetConVar("epoe_font")
		FontChooser:SizeToContents()
		FontChooser:SetTall(16)
		FontChooser:SetWide(FontChooser:GetWide()+32)
		List:AddItem( FontChooser )	
	
	self.uppermenu=List

		
	self.canvas=vgui.Create('EditablePanel',self)
	local canvas=self.canvas
	canvas:Dock(FILL)
	
	self.RichText=vgui.Create('RichText',canvas)
		self.RichText:InsertColorChange(255,255,255,255)
		self.RichText:SetPaintBackgroundEnabled( false )
		self.RichText:SetPaintBorderEnabled( false )
		self.RichText:SetMouseInputEnabled(true)
		self.RichText:SetVerticalScrollbarEnabled(true) -- How to make it so that shows only when required?
		self.RichText:SetWrap(false) -- Does not work
		self.RichText:SetFont("TitleFont") -- Does not work
	function self.RichText:PerformLayout()
		self:SetPos(-7,-4) -- HACKHACK
		self:SetWide(self:GetParent():GetWide()+9+(e.GUI.being_hovered and 0 or 15)) -- HACKHACK :x
		self:SetTall(self:GetParent():GetTall()+2) -- scrollbar?
	end
	timer.Simple(0.1,function() 
		e.GUI.RichText:SetFont(epoe_font:GetString())
	end)
	
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
	
	self.RichText:AppendText(txt)
end

function PANEL:AppendTextX(txt)
	local function func(link,txt)
		if txt:len()==0 then return end
		if link then
			self.RichText:InsertClickableTextStart(txt)
			self:ResetLastColor(r,g,b)
		end
		self:AppendText(txt)
		if link then
			self.RichText:InsertClickableTextEnd()
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
function PANEL:PerformLayout()
	self.RichText:InvalidateLayout()
end

function PANEL:Paint()
	if not epoe_draw_background:GetBool() and not self.being_hovered then return end
	surface.SetDrawColor(40 ,40 ,40,196)
	surface.DrawRect(0,0,self:GetWide(),self:GetTall())
	return true
end

---------------------
-- Functionality
---------------------
function PANEL:ButtonHolding(isHolding)
	if isHolding then
		self.being_hovered = true
		self.RichText:PerformLayout()
		self.uppermenu:Dock(TOP)
		self.uppermenu:SetVisible(true)
		self:InvalidateLayout()
	else
		self.being_hovered = false
		self.RichText:PerformLayout()
		self.uppermenu:Dock(NODOCK)
		self.uppermenu:SetVisible(false)
		self:InvalidateLayout()
	end
end

local stayup=CreateClientConVar("epoe_ui_holdtime","5",true,false)--seconds
local fadespeed = 3--seconds
function PANEL:Think()
	
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
		self.RichText:PerformLayout()
	else
		self.RichText:PerformLayout()
		self.being_hovered = false
	end
		
	
	-- Hiding for gmod camera..
	if hook.Call('HUDShouldDraw',GAMEMODE,"CHud"..TagHuman)==false then self:SetAlpha(0) return end
	
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
		
		if ( x < 170 ) then x = 170 end
		if ( y < 30 ) then y = 30 end
	
		self:SetSize( x, y )
		self:SetCursor( "sizenwse" )
		return
	
	end
	
	if ( self.Hovered &&
         --self.m_bSizable &&
	     mx > (self.x + self:GetWide() - 20) &&
	     my > (self.y + self:GetTall() - 20) ) then	

		self:SetCursor( "sizenwse" )
		return
		
	end
	
	if ( self.Hovered && my < (self.y + 20) ) then
		self:SetCursor( "sizeall" )
		return
	end
	
	self:SetCursor( "arrow" )
	if self:IsActive() then self:Activity() end
	
	local inactive_time = RealTime() - self.LastActivity
	--print("inactive_time",inactive_time)
	local stayup=stayup:GetInt()
	inactive_time = ( inactive_time - stayup ) * ( 255 / fadespeed )
	--print("inactive_time post",inactive_time)
	
	local alpha = 255 - ( (inactive_time >= 255 and 255) or (inactive_time <= 0 and 0) or inactive_time )
	if alpha<=0 then
		self:SetVisible(false)
		self:SetAlpha(255)
	end
	
	self:SetAlpha(alpha)
end

-- woo clever..
local _Think=PANEL.Think
local errorz=false
PANEL.Think=function (a)
	if errorz then return end
	errorz=true
		_Think(a)
	errorz=false
end

function PANEL:OnMousePressed( mc )
		
	if mc == MOUSE_RIGHT or ( gui.MouseX() > (self.x + self:GetWide() - 20) &&
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

function PANEL:OnMouseReleased()

	self.Dragging = nil
	self.Sizing = nil
	local x,y=self:GetPos()
	e.GUI:SetCookie("w",self:GetWide())
	e.GUI:SetCookie("h",self:GetTall())
	e.GUI:SetCookie("x",x)
	e.GUI:SetCookie("y",y)
		
	self:MouseCapture( false )

end
 
function PANEL:ToggleActive(set)
	if set==nil then
		self.keepactive=!self.keepactive
	else	
		self.keepactive=set
	end
	e.internalPrint(self.keepactive and "Fading disabled" or "Fading enabled")
	
	
end

function PANEL:IsActive()

	if self.keepactive or self.being_hovered or self:HasFocus() or vgui.FocusedHasParent( self ) then return true end
	
end

-- Bring up if something happened.
function PANEL:Activity()

	self:SetAlpha(255)
	self.LastActivity=RealTime()
end
PANEL.OnCursorMoved=PANEL.Activity


derma.DefineControl( "EPOEUI", "EPOE2 GUI", PANEL, "EditablePanel" )



function e.CreateGUI()
	if !ValidPanel(e.GUI) then
		e.GUI=vgui.Create('EPOEUI')
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
local keepactive = false
local function epoe_toggle(_,cmd,args)
	if cmd=="+epoe" then
		
		gui.EnableScreenClicker(true)
		e.ShowGUI() -- also creates it
		if lastclick+threshold>RealTime() then -- Doubleclick
			lastclick = 0 -- reset
			keepactive=!keepactive
			e.GUI:ToggleActive(keepactive)
		else
			lastclick=RealTime()
		end
		
		e.GUI:ButtonHolding(true)
	
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
local epoe_show_on_activity = CreateClientConVar("epoe_show_on_activity", 	"1", true, false)
local epoe_disable_autoscroll = CreateClientConVar("epoe_disable_autoscroll", 	"0", true, false)
local notimestamp  = false

hook.Add( TagHuman, TagHuman..'_GUI', function(newText,flags,c)
	flags = flags or 0
	if ValidPanel( e.GUI ) then
		
		if epoe_show_on_activity:GetBool() then
			e.ShowGUI()
			e.GUI:Activity()
		end
		
		if c then
			if type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" then
				e.GUI:SetColor(c.r, c.g, c.b)
			end
			if newText then 
				e.GUI:AppendTextX(tostring(newText)) 
			end
			return
		end
		
		if e.HasFlag(flags,e.IS_EPOE) then
			e.GUI:SetColor(255,100,100)
			e.GUI:AppendText("[EPOE] ")
			e.GUI:SetColor(255,250,250)
			e.GUI:AppendTextX(newText.."\n")
			return
		end
		
		if epoe_timestamps:GetBool() then
			if !notimestamp then
				e.GUI:SetColor(100,100,100)	e.GUI:AppendText(			"[")
				e.GUI:SetColor(255,255,255)	e.GUI:AppendText(os.date(	"%H"))
				e.GUI:SetColor(100,100,100)	e.GUI:AppendText(			":")
				e.GUI:SetColor(255,255,255)	e.GUI:AppendText(os.date(	"%M"))
				e.GUI:SetColor(100,100,100)	e.GUI:AppendText(			"] ")
			end
			notimestamp = not ( newText:Right(1)=="\n" ) -- negation hard
		end
		-- HUGE TODO: Colors :X
		if e.HasFlag(flags,e.IS_ERROR) then
			e.GUI:SetColor(255,80,80)
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

