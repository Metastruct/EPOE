---------------
-- Clientside UI
---------------
local e=epoe
local TagHuman=e.TagHuman

---------------
-- Graphical UI
---------------


--[[

---------------------------
-- Feature requests for control RichText
---------------------------


      RichText:SetTextPadding() -- THe text lines have a huge gap between them
      RichText:SetFont("TitleFont") -- Does not do anything
      RichText:SetWrap(false) -- Does not do anything
      RichText:OnMousePressed() -- Does not get called. 
      
      RichText:SetVerticalScrollbarEnabled(true) -- How to make it so that shows only when required?
      -- We also can't scroll the RichText unlike the chatbox apparently.
	  RichText:AddClickableText(text,callback)
      RichText:GetSelectedText()
	  
      Override for RightClick context menu
      RichText:SelectText() or :Search() and :SearchNext() ?
	  RichText:Scroll() 
	  RichText:SetTextFading() -- Like in chatbox
	  
-- ]]

local gradient = surface.GetTextureID( "VGUI/gradient_up" )


local PANEL={}
function PANEL:Init()

	-- Activity fade
	self.LastActivity = RealTime()
	self.keepactive = 	false
	
	self:SetFocusTopLevel( true )
	self:SetCursor( "sizeall" )
	
	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )	

	self:DockPadding( 3, 3, 3, 3 )
	self.uppermenu=vgui.Create( "DPanelList", self )
	local List=self.uppermenu
		
		List:SetSpacing( 5 ) 
		List:SetPadding( 2 ) 
		List:SetTall( 24 )
		
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
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 18 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )
		local Button = vgui.Create( "DButton" )
			Button:SetText( "Logout" )
			function Button:DoClick()
				epoe.DelSub()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 18 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )

		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Autologin" )
			checkbox:SetConVar( "epoe_autologin" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 20 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Timestamp" )
			checkbox:SetConVar( "epoe_timestamps" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 20 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "printconsole" )
			checkbox:SetConVar( "epoe_toconsole" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 20 )
		List:AddItem( checkbox ) 
		local checkbox = vgui.Create( "DCheckBoxLabel" )
			checkbox:SetText( "Show On Activity" )
			checkbox:SetConVar( "epoe_show_on_activity" )
			--checkbox:SetValue( 1 )
			checkbox:SizeToContents() checkbox:SetTall( 20 )
		List:AddItem( checkbox )
		local Button = vgui.Create( "DButton" )
			Button:SetText( "Clear" )
			function Button:DoClick()
				e.ClearLog()
			end
			Button:SizeToContents() Button:SetDrawBorder(false)  Button:SetTall( 18 ) Button:SetWide( Button:GetWide(  ) + 6 ) -- gah
		List:AddItem( Button )

		
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
	function self.RichText:PerformLayout() -- Fucking cheats. But it looks better, it should? Who needs a scrollbar anyways...
		self:SetPos(-7,-4) 
		self:SetWide(self:GetParent():GetWide()+9+(e.GUI.being_hovered and 0 or 15)) -- HACKHACK :x
		self:SetTall(self:GetParent():GetTall()+2) -- scrollbar?
	end
		--[[ WHY DONT THESE WORK??
		function self.RichText:OnMousePressed()
			print"DERP"
		end
		function self.RichText:DoClick()
			print"DERP"
		end
		function self.RichText:OnMouseReleased()
			print"DERP"
		end --]]
		
	--self.RichText:AppendText("EPOE UI Loaded!")
	
end

---------------------
-- Text manipulation
---------------------
-- We don't want a newline appended right away so we hack it up..
local appendNL=false
function PANEL:AppendText(txt)
	if appendNL then
		txt='\n'..txt
	end
	if txt:sub(-1)=="\n" then
		appendNL=true
		txt = txt:sub(1,txt:len()-1)
	else
		appendNL=false
	end
	
	self.RichText:AppendText(txt)
end

function PANEL:Clear()
	self.RichText:SetText "" -- whee
end


function PANEL:SetColor(r,g,b)
	self.RichText:InsertColorChange(r,g,b,255)
end

---------------------
-- Visuals
---------------------
function PANEL:PerformLayout()
	self.RichText:InvalidateLayout()
end

function PANEL:Paint() 
	--surface.SetDrawColor(40 ,40 ,40,150)
	--surface.SetTexture(gradient)
	--surface.DrawTexturedRect(0,self:GetTall()-40,self:GetWide(),40)
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
		self.uppermenu:Dock(TOP)
		self.uppermenu:SetVisible(true)
		self:InvalidateLayout()
	else
		self.being_hovered = false
		self.uppermenu:Dock(NODOCK)
		self.uppermenu:SetVisible(false)
		self:InvalidateLayout()
	end
end

local stayup=CreateClientConVar("epoe_ui_holdtime","5",true,false)--seconds
local fadespeed=3--seconds
function PANEL:Think()
	
	-- Hiding for gmod camera..
	if hook.Call('HUDShouldDraw',GAMEMODE,"CHud"..TagHuman)==false then self:SetAlpha(0) return end
	
	if (self.Dragging) then
	
		local x = gui.MouseX() - self.Dragging[1]
		local y = gui.MouseY() - self.Dragging[2]

		--if ( self:GetScreenLock() ) then
		
			x = math.Clamp( x, 0, ScrW() - self:GetWide() )
			y = math.Clamp( y, 0, ScrH() - self:GetTall() )
		
		--end
		
		self:SetPos( x, y )
	
	end
	
	
	if ( self.Sizing ) then
	
		local x = gui.MouseX() - self.Sizing[1]
		local y = gui.MouseY() - self.Sizing[2]	
		
		if ( x < 170 ) then x = 170 end
		if ( y < 30 ) then y = 30 end
	
		self:SetSize( x, y )
		self:SetCursor( "sizenwse" )
		return
	
	end
	
	if ( self.Hovered &&
         --self.m_bSizable &&
	     gui.MouseX() > (self.x + self:GetWide() - 20) &&
	     gui.MouseY() > (self.y + self:GetTall() - 20) ) then	

		self:SetCursor( "sizenwse" )
		return
		
	end
	
	if ( self.Hovered && gui.MouseY() < (self.y + 20) ) then
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



function PANEL:OnMousePressed( mc )

	--if ( self.m_bSizable ) then
	
		--if ( gui.MouseX() > (self.x + self:GetWide() - 20) &&
		--	gui.MouseY() > (self.y + self:GetTall() - 20) ) then			
	if mc == MOUSE_RIGHT or ( gui.MouseX() > (self.x + self:GetWide() - 20) &&
			gui.MouseY() > (self.y + self:GetTall() - 20) ) then	
		self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
		self:MouseCapture( true )
		return
	else
		
	--end
	
	--if ( gui.MouseY() < (self.y + 20) ) then
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

function PANEL:OnCursorEntered( )
	self.being_hovered = true
end

function PANEL:OnCursorExited( )
	self.being_hovered = false
end

function PANEL:ToggleActive(set)
	if set==nil then
		self.keepactive=!self.keepactive
	else	
		self.keepactive=set
	end
	
	--print("epoe.GUI.keepactive = ",self.keepactive)
	
end

function PANEL:IsActive()

	if self.keepactive or self.being_hovered or self:HasFocus() or vgui.FocusedHasParent( self ) then return true end
	
end

-- Bring up if something happened.
function PANEL:Activity()
	--print("Activity")
	self:SetAlpha(255)
	self.LastActivity=RealTime()
end
PANEL.OnCursorMoved=PANEL.Activity

derma.DefineControl( "EPOEUI", "EPOE's User Interface", PANEL, "EditablePanel" )
--------------------------
-- End of control. TODO: Make multipurpose? D:
--------------------------

function e.CreateGUI()
	if !ValidPanel(e.GUI) then 
		--local x,y=cookie.GetNumber()
		e.GUI=vgui.Create('EPOEUI')
		e.GUI:SetCookieName("EPOE_GUI")
		local w = tonumber( e.GUI:GetCookie("w") ) or ScrW()*0.5
		local h = tonumber( e.GUI:GetCookie("h") ) or ScrH()*0.25
		local x = tonumber( e.GUI:GetCookie("x") ) or ScrW()*0.5 - e.GUI:GetWide()*0.5
		local y = tonumber( e.GUI:GetCookie("y") ) or ScrH() - e.GUI:GetTall()
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

local threshold=0.2
local lastclick=0
local keepactive=false
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
		
		
	else --if cmd=="-epoe" then
		gui.EnableScreenClicker(false)
		-- Do we really even need this? Naw..
		--if keepactive then
		--	return
		--end
		--e.ShowGUI(false)
		e.GUI:ButtonHolding(false)
	end
end

concommand.Add('+epoe',epoe_toggle)
concommand.Add('-epoe',epoe_toggle)


----------------------------
-- Hooking, timestamps, activity showing
----------------------------

local c_timestamps = CreateClientConVar("epoe_timestamps", 			"1", true, false)
local c_onactivity = CreateClientConVar("epoe_show_on_activity", 	"1", true, false)
local notimestamp  = false

hook.Add( TagHuman, TagHuman..'_GUI', function(newText,flags)
	flags = flags or 0
	if ValidPanel( e.GUI ) then
		
		if c_onactivity:GetBool() then
			e.ShowGUI()
			e.GUI:Activity()
		end
		
		if e.HasFlag(flags,e.IS_EPOE) then
			e.GUI:SetColor(255,100,100)
			e.GUI:AppendText("[EPOE] ")
			e.GUI:SetColor(255,250,250)
			e.GUI:AppendText(newText.."\n")
			return
		end
		
		if c_timestamps:GetBool() then
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
		
		
		e.GUI:AppendText(newText)
	end
end)


---------------
-- Clientside Console UI
---------------
local c_printconsole=CreateClientConVar("epoe_toconsole", "1", true, false)

hook.Add(TagHuman,TagHuman..'_CLI',function(Text,flags)
	flags=flags or 0
	if e.HasFlag(flags,e.IS_EPOE) then
		e.ShowGUI() -- Force :3
		e.GUI:Activity()
		Msg("[EPOE] ")print(Text)		
		return
	end
	
	if c_printconsole:GetBool() then
		Msg(Text)
	end
end)