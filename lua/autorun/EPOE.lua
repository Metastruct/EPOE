local Description=
/* 

	*/ "Extended Perception Of Errors" /*
	Idea taken from ENE(Z)
	
	Copyright (C) 2010        Python1320, CapsAdmin
	
*/


Msg("[EPOE "..(SERVER and "Server" or "Client").."] ")

if !llon then include'EPOE_LLON.lua' end
if !llon then
	ErrorNoHalt"llon not found? Falling back to glon."
	if !glon then require"glon" end
	if !glon then error"glon not found??" end
end

--if EPOE then ErrorNoHalt("Warning! MUST NOT Reload!") return end 
if EPOE then 
	ErrorNoHalt"Warning: Reloading EPOE! "
	EPOE.RELOADED=true
end

EPOE=EPOE or {}

-- usermessage name
EPOE.Tag='E\''

EPOE.TagHuman='EPOE'

-- Tags
EPOE.T_HasEnd=true
EPOE.T_NoEnd=false


-- Debug function
/*function _D(...)
	local Msg=_Msg or Msg
	local print=_print or print
	print(EPOE.Tag or "EOPE",...)
end*/




--[[ EPOE HOOK STRUCT:
	
	hook.Add('EPOE',-,function(STRING_MESSAGE,RAW_MESSAGE) end)

]]

-- Decode the message to a nice format. Taken from table-module, modded by CapsAdmin, adapted by Python1320.
-- TODO: FIXME: We need to revert back to old format or create own datastream and/or llon for encoding nonencodable objects.
function EPOE.ToString(t)
		local 		nl,tab  = "",  ""

		local function MakeTable ( t, nice, indent, done)
			local str = ""
			local done = done or {}
			local indent = indent or 0
			local idt = ""
			if nice then idt = string.rep ("\t", indent) end

			local sequential = table.IsSequential(t)

			for key, value in pairs (t) do

				str = str .. idt .. tab .. tab

				if not sequential then
					if type(key) == "number" or type(key) == "boolean" then 
						key ='['..tostring(key)..']' ..tab..'='
					else
						key = tostring(key) ..tab..'='
					end
				else
					key = ""
				end

				if type (value) == "table" and not done [value] then

					done [value] = true
					str = str .. key .. tab .. nl
					.. MakeTable (value, nice, indent + 1, done)
					str = str .. idt .. tab .. tab ..tab .. tab .. nl

				else
					
					if 	type(value) == "string" then 
						value = /*'"'..*/tostring(value)/*..'"'*/
					elseif  type(value) == "Vector" then
						value = 'Vector('..value.x..','..value.y..','..value.z..')'
					elseif  type(value) == "Angle" then
						value = 'Angle('..value.pitch..','..value.yaw..','..value.roll..')'
					else
						value = tostring(value)
					end
					
					str = str .. key .. tab .. value .. " ".. nl

				end

			end
			return str
		end
		local str = ""
		--if n then str = n.. tab .."=" .. tab end
		str = str .. nl .. MakeTable ( t, nice)
		return str
	end	

	
if SERVER then include	'EPOE_server.lua'
	if EPOE.InitHooks then EPOE.InitHooks() else
		error			"FAILED LOADING EPOE!"
	end	
		AddCSLuaFile	'EPOE.lua'
		
		AddCSLuaFile	'EPOE_LLON.lua'
		resource.AddSingleFile'resource/fonts/DejaVuSansMono.ttf'
		
		MsgN"Loaded."
		return

end 



EPOE.Subscribed=false
function EPOE.Subscribe(unsubscribe)
	if !unsubscribe then
		RunConsoleCommand(EPOE.TagHuman,'1')
		if !EPOE.Subscribed and EPOE.AddText then
			EPOE.AddText("[EPOE client] Subscribing...\n")			
		end
		EPOE.Subscribed=true
	else
		RunConsoleCommand(EPOE.TagHuman,'0')
		if EPOE.Subscribed and EPOE.AddText then
			EPOE.AddText("[EPOE client] UnSubscribing...\n")	
		end
		EPOE.Subscribed=false
	end
end


-- The client "CORE"
-- TODO: datastream?
function EPOE.RecvMsg(msg)
	
	local msg=msg:ReadString()
	msg=llon.decode(msg)
	local str=/*"E ("..tostring(msg[1]).."):"..*/EPOE.ToString(msg[2])
	str=str..((msg[1]==EPOE.T_HasEnd) and '\n' or '')
	
	hook.Call('EPOE',nil,str or nil,msg[2] or nil,msg[1] or nil)
	
end
usermessage.Hook(EPOE.Tag,EPOE.RecvMsg)

-- Taken from Wiremod/E2/TextEditor, sorry guys :s
-- Huge thanks towards the developer of this.
-- TODO: Ask permission before releasing EPOE.

local EDITOR = {}

local fadetime = CreateClientConVar("EPOE_UI_fadetime", 0.15, true, false)

local transparent = 255

EPOE.FONT = EPOE.FONT or "EPOE_FONT"
EPOE.FONT_BOLD = EPOE.FONT_BOLD or "EPOEB_FONT"
-- hacks..
if not file.Exists		'resource/fonts/DejaVuSansMono.ttf' then
	surface.CreateFont	("DejaVu Sans Mono", 12, 400, true,	false, EPOE.FONT)
	surface.CreateFont	("DejaVu Sans Mono", 12, 700, true,	false, EPOE.FONT_BOLD)
else
	ErrorNoHalt"EPOE: CAN NOT FIND FONT: resource/fonts/DejaVuSansMono.ttf"
	ErrorNoHalt"EPOE: FALLING BACK TO Courier New"
	surface.CreateFont("Courier New", 13, 400, true, false, EPOE.FONT)
	surface.CreateFont("Courier New", 13, 700, true, false, EPOE.FONT_BOLD)	
end


function EDITOR:Init()
	self:SetCursor("beam")
	
	surface.SetFont(EPOE.FONT)
	self.FontWidth, self.FontHeight = surface.GetTextSize(" ")
	
	self.Rows = {""}
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Size = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}
	
	self.Blink = RealTime()
	
	self.ScrollBar = vgui.Create("DVScrollBar", self)
	self.ScrollBar:SetUp(1, 1)
	self.ScrollBar.Paint = nil
	self.ScrollBar.PaintOver = nil
	self.ScrollBar:SetAlpha(0)
	self.ScrollBar:SetVisible(false)
	
	
	self.TextEntry = vgui.Create("TextEntry", self)
	self.TextEntry:SetMultiline(true)
	self.TextEntry:SetSize(0, 0)
	
	self.TextEntry.OnLoseFocus = function (self) self.Parent:_OnLoseFocus() end
	self.TextEntry.OnTextChanged = function (self) self.Parent:_OnTextChanged() end
	self.TextEntry.OnKeyCodeTyped = function (self, code) self.Parent:_OnKeyCodeTyped(code) end
	
	self.TextEntry.Parent = self
	
	self.LastClick = 0
end

function EDITOR:RequestFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:OnGetFocus()
	self.TextEntry:RequestFocus()
end

function EDITOR:CursorToCaret()
	local x, y = self:CursorPos()
	
	x = x - (self.FontWidth * 3 + 6)
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	
	local line = math.floor(y / self.FontHeight)
	local char = math.floor(x / self.FontWidth+0.5)
	
	line = line + self.Scroll[1]
	char = char + self.Scroll[2]
	
	if line > #self.Rows then line = #self.Rows end
	local length = string.len(self.Rows[line])
	if char > length + 1 then char = length + 1 end
	
	return { line, char }
end

function EDITOR:OnMousePressed(code)
	if input.IsKeyDown(KEY_LALT) then
		self:GetParent():OnMousePressed(code)
	end
	
	if code == MOUSE_LEFT then
		if((CurTime() - self.LastClick) < 1 and self.tmp and self:CursorToCaret()[1] == self.Caret[1] and self:CursorToCaret()[2] == self.Caret[2]) then
			self.Start = self:getWordStart(self.Caret)
			self.Caret = self:getWordEnd(self.Caret)
			self.tmp = false
			return
		end
		
		self.tmp = true
		
		self.LastClick = CurTime()
		self:RequestFocus()
		--self.Blink = RealTime()
		self.MouseDown = true
		
		self.Caret = self:CursorToCaret()
		if !input.IsKeyDown(KEY_LSHIFT) and !input.IsKeyDown(KEY_RSHIFT) then
			self.Start = self:CursorToCaret()
		end
	elseif code == MOUSE_RIGHT then
		local menu = DermaMenu()
		--[[
		if self:CanUndo() then
			menu:AddOption("Undo", function()
				self:DoUndo()
			end)
		end
		if self:CanRedo() then
			menu:AddOption("Redo", function()
				self:DoRedo()
			end)
		end]]
		--[[
		if self:CanUndo() or self:CanRedo() then
			menu:AddSpacer()
		end]]
		
		if self:HasSelection() then
			--[[menu:AddOption("Cut", function()
				if self:HasSelection() then
					self.clipboard = self:GetSelection()
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
					self:SetSelection()
				end
			end)]]
			menu:AddOption("Copy", function()
				if self:HasSelection() then
					self.clipboard = self:GetSelection()
					self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
					SetClipboardText(self.clipboard)
				end
			end)
		end
		--[[
		menu:AddOption("Paste", function()
			if self.clipboard then
				self:SetSelection(self.clipboard)
			else
				self:SetSelection()
			end
		end)
		
		if self:HasSelection() then
			menu:AddOption("Delete", function()
				self:SetSelection()
			end)
		end
		
		menu:AddSpacer()
		]]
		
		menu:AddOption("Select all", function()
			self:SelectAll()
		end)
		--[[
		menu:AddSpacer()
		
		menu:AddOption("Indent", function()
			self:Indent(false)
		end)
		menu:AddOption("Outdent", function()
			self:Indent(true)
		end)
		
		if self:HasSelection() then
			menu:AddSpacer()
			
			menu:AddOption("Comment Block", function()
				self:CommentSelection(false)
			end)
			menu:AddOption("Uncomment Block", function()
				self:CommentSelection(true)
			end)
		end
		]]
		
		menu:AddOption("Find text", function()
			self:FindWindow()
		end)
		
		menu:AddOption("Clear all", function()
			if EPOE then
				EPOE.Clear()
			end
		end)
		
		menu:AddSpacer()
		
		menu:AddOption("Close EPOE", function()
			RunConsoleCommand"EPOE_UI" -- :DD
		end)
		
		menu:AddOption("Close+UnSub", function()
			RunConsoleCommand"EPOE_UI" -- :DD
			if EPOE then
				EPOE.Subscribe(true)
			end
			
		end)


		menu:AddSpacer()
		
		menu:AddOption("Subscribe", function()
			EPOE.Subscribe()
		end)
		
		menu:AddOption("UnSubscribe", function()
			EPOE.Subscribe(true)
		end)		
		
		menu:Open()
	end
end

function EDITOR:OnMouseReleased(code)
	if !self.MouseDown then return end
	
	self:GetParent():OnMouseReleased()
	
	if code == MOUSE_LEFT then
		self.MouseDown = nil
		if(!self.tmp) then return end
		self.Caret = self:CursorToCaret()
	end
end

function EDITOR:SetText(text)
	if type(text)=="string" then 
		self.Rows = string.Explode("\n", text)
	elseif type(text)=="table" then
		self.Rows = text
	else
		ErrorNoHalt"EPOE TEXTBOX: INVALID INPUT"
		return
	end
	
	for k,v in pairs(self.Rows) do
		if true then
			self.Rows[k]=string.gsub(v,"\t","     ")
		end
	end
	
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
	end
	
	self.Caret = {1, 1}
	self.Start = {1, 1}
	self.Scroll = {1, 1}
	self.Undo = {}
	self.Redo = {}
	self.PaintRows = {}
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:GetValue()
	return string.Replace(table.concat(self.Rows, "\n"), "\r", "")
end
function EDITOR:OnCursorMoved()
	transparent = 255
end

function EDITOR:PaintLine(row)
	if row > #self.Rows then return end
	
	if !self.PaintRows[row] then
		self.PaintRows[row] = self:SyntaxColorLine(row)
	end
	
	local width, height = self.FontWidth, self.FontHeight
	
	if row == self.Caret[1] and self.TextEntry:HasFocus() then
		surface.SetDrawColor(48, 48, 48, transparent)
		surface.DrawRect(width * 3 + 5, (row - self.Scroll[1]) * height, self:GetWide() - (width * 3 + 5), height)
	end
	
	if self:HasSelection() then
		local start, stop = self:MakeSelection(self:Selection())
		local line, char = start[1], start[2]
		local endline, endchar = stop[1], stop[2]
		
		surface.SetDrawColor(0, 0, 160, transparent)
		local length = self.Rows[row]:len() - self.Scroll[2] + 1
		
		char = char - self.Scroll[2]
		endchar = endchar - self.Scroll[2]
		if char < 0 then char = 0 end
		if endchar < 0 then endchar = 0 end
		
		if row == line and line == endline then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (endchar - char), height)
		elseif row == line then
			surface.DrawRect(char * width + width * 3 + 6, (row - self.Scroll[1]) * height, width * (length - char + 1), height)
		elseif row == endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * endchar, height)
		elseif row > line and row < endline then
			surface.DrawRect(width * 3 + 6, (row - self.Scroll[1]) * height, width * (length + 1), height)
		end
	end
	
	draw.SimpleText(tostring(row), EPOE.FONT, width * 3, (row - self.Scroll[1]) * height, Color(128, 128, 128, transparent), TEXT_ALIGN_RIGHT)
	
	local offset = -self.Scroll[2] + 1
	for i,cell in ipairs(self.PaintRows[row]) do
		if offset < 0 then
			if cell[1]:len() > -offset then
				line = cell[1]:sub(1-offset)
				offset = line:len()
				
				if cell[2][2] then
					draw.SimpleText(line, EPOE.FONT_BOLD, width * 3 + 6, (row - self.Scroll[1]) * height, Color(cell[2][1].r,cell[2][1].g,cell[2][1].b,transparent))
				else
					draw.SimpleText(line, EPOE.FONT, width * 3 + 6, (row - self.Scroll[1]) * height, Color(cell[2][1].r,cell[2][1].g,cell[2][1].b,transparent))
				end
			else
				offset = offset + cell[1]:len()
			end
		else
			if cell[2][2] then
				draw.SimpleText(cell[1], EPOE.FONT_BOLD, offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, Color(cell[2][1].r,cell[2][1].g,cell[2][1].b,transparent))
			else
				draw.SimpleText(cell[1], EPOE.FONT, offset * width + width * 3 + 6, (row - self.Scroll[1]) * height, Color(cell[2][1].r,cell[2][1].g,cell[2][1].b,transparent))
			end
			
			offset = offset + cell[1]:len()
		end
	end
	
	
end

function EDITOR:PerformLayout()
	self.ScrollBar:SetSize(16, self:GetTall())
	self.ScrollBar:SetPos(self:GetWide() - 16, 0)
	
	self.Size[1] = math.floor(self:GetTall() / self.FontHeight) - 1
	self.Size[2] = math.floor((self:GetWide() - (self.FontWidth * 3 + 6) - 16) / self.FontWidth) - 1
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
end

function EDITOR:PaintTextOverlay()
	
	if self.TextEntry:HasFocus() and self.Caret[2] - self.Scroll[2] >= 0 then
		local width, height = self.FontWidth, self.FontHeight
		
		/*if (RealTime() - self.Blink) % 0.8 < 0.4 then
			surface.SetDrawColor(240, 240, 240, 255)
			surface.DrawRect((self.Caret[2] - self.Scroll[2]) * width + width * 3 + 6, (self.Caret[1] - self.Scroll[1]) * height, 1, height)
		end*/
		
		-- Bracket highlighting by: {Jeremydeath}
		local WindowText = self:GetValue()
		local LinePos = table.concat(self.Rows, "\n", 1, self.Caret[1]-1):len()
		local CaretPos = LinePos+self.Caret[2]+1
		
		local BracketPairs = { 
			["{"] = "}",
			["}"] = "{",
			["["] = "]",
			["]"] = "[",
			["("] = ")",
			[")"] = "("
		}
		
		local CaretChars = WindowText:sub(CaretPos-1, CaretPos)
		local BrackSt, BrackEnd = CaretChars:find("[%(%){}%[%]]")
		
		local Bracket = false
		if BrackSt and BrackSt != 0 then
			Bracket = CaretChars:sub(BrackSt or 0,BrackEnd or 0)
		end
		if Bracket and BracketPairs[Bracket] then
			local End = 0
			local EndX = 1
			local EndLine = 1
			local StartX = 1
			
			if Bracket == "(" or Bracket == "[" or Bracket == "{" then
				BrackSt,End = WindowText:find("%b"..Bracket..BracketPairs[Bracket], CaretPos-1)
				
				if BrackSt and End then
					local OffsetSt = 1
					
					local BracketLines = string.Explode("\n",WindowText:sub(BrackSt, End))
					
					EndLine = self.Caret[1]+#BracketLines-1
					
					EndX = End-LinePos-2
					if #BracketLines>1 then
						EndX = BracketLines[#BracketLines]:len()-1
					end
					
					if Bracket == "{" then
						OffsetSt = 0
					end
					
					if (CaretPos - BrackSt) >= 0 and (CaretPos - BrackSt) <= 1 then
						local width, height = self.FontWidth, self.FontHeight
						local StartX = BrackSt - LinePos - 2
						--surface.SetDrawColor(255, 0, 0, 0)
					--	surface.DrawRect((StartX-(self.Scroll[2]-1)) * width + width * 4 + OffsetSt - 1, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
				--		surface.DrawRect((EndX-(self.Scroll[2]-1)) * width + width * 3 + 6, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			elseif Bracket == ")" or Bracket == "]" or Bracket == "}" then
				BrackSt,End = WindowText:reverse():find("%b"..Bracket..BracketPairs[Bracket], -CaretPos)
				if BrackSt and End then
					local len = WindowText:len()
					End = len-End+1
					BrackSt = len-BrackSt+1
					local BracketLines = string.Explode("\n",WindowText:sub(End, BrackSt))
					
					EndLine = self.Caret[1]-#BracketLines+1
					
					local OffsetSt = -1
					
					EndX = End-LinePos-2
					if #BracketLines>1 then
						local PrevText = WindowText:sub(1, End):reverse()
						
						EndX = (PrevText:find("\n",1,true) or 2)-2
					end
					
					if Bracket != "}" then
						OffsetSt = 0
					end
					
					if (CaretPos - BrackSt) >= 0 and (CaretPos - BrackSt) <= 1 then
						local width, height = self.FontWidth, self.FontHeight
						local StartX = BrackSt - LinePos - 2
						-- surface.SetDrawColor(255, 0, 0, 0)
						-- surface.DrawRect((StartX-(self.Scroll[2]-1)) * width + width * 4 - 2, (self.Caret[1] - self.Scroll[1]) * height+1, width-2, height-2)
						-- surface.DrawRect((EndX-(self.Scroll[2]-1)) * width + width * 3 + 8 + OffsetSt, (EndLine - self.Scroll[1]) * height+1, width-2, height-2)
					end
				end
			end
		end
	end
end

function EDITOR:Paint()
	if !input.IsMouseDown(MOUSE_LEFT) then
		self:OnMouseReleased(MOUSE_LEFT)
	end

	if !self.PaintRows then
		self.PaintRows = {}
	end

	if self.MouseDown then
		self.Caret = self:CursorToCaret()
	end
		
	surface.SetDrawColor(0, 0, 0, transparent/1.5)
	surface.DrawRect(0, 0, self.FontWidth * 3 + 4, self:GetTall())
	
	surface.SetDrawColor(32, 32, 32, transparent/1.5)
	surface.DrawRect(self.FontWidth * 3 + 5, 0, self:GetWide() - (self.FontWidth * 3 + 5), self:GetTall())
	
	self.Scroll[1] = math.floor(self.ScrollBar:GetScroll() + 1)
	
	for i=self.Scroll[1],self.Scroll[1]+self.Size[1]+1 do
		self:PaintLine(i)
	end
	
	-- Paint the overlay of the text (bracket highlighting and carret postition)
	self:PaintTextOverlay()
	
	return true
end


function EDITOR:SetCaret(caret)
	self.Caret = self:CopyPosition(caret)
	self.Start = self:CopyPosition(caret)
	self:ScrollCaret()
end


function EDITOR:CopyPosition(caret)
	return { caret[1], caret[2] }
end

function EDITOR:MovePosition(caret, offset)
	local caret = { caret[1], caret[2] }
	
	if offset > 0 then
		while true do
			local length = string.len(self.Rows[caret[1]]) - caret[2] + 2
			if offset < length then
				caret[2] = caret[2] + offset
				break
			elseif caret[1] == #self.Rows then
				caret[2] = caret[2] + length - 1
				break
			else
				offset = offset - length
				caret[1] = caret[1] + 1
				caret[2] = 1
			end
		end
	elseif offset < 0 then
		offset = -offset
		
		while true do
			if offset < caret[2] then
				caret[2] = caret[2] - offset
				break
			elseif caret[1] == 1 then
				caret[2] = 1
				break
			else
				offset = offset - caret[2]
				caret[1] = caret[1] - 1
				caret[2] = string.len(self.Rows[caret[1]]) + 1
			end
		end
	end
	
	return caret
end


function EDITOR:HasSelection()
	return self.Caret[1] != self.Start[1] || self.Caret[2] != self.Start[2]
end

function EDITOR:Selection()
	return { { self.Caret[1], self.Caret[2] }, { self.Start[1], self.Start[2] } }
end

function EDITOR:MakeSelection(selection)
	local start, stop = selection[1], selection[2]

	if start[1] < stop[1] or (start[1] == stop[1] and start[2] < stop[2]) then
		return start, stop
	else
		return stop, start
	end
end


function EDITOR:GetArea(selection)
	local start, stop = self:MakeSelection(selection)
	
	if start[1] == stop[1] then
		return string.sub(self.Rows[start[1]], start[2], stop[2] - 1)
	else
		local text = string.sub(self.Rows[start[1]], start[2])
		
		for i=start[1]+1,stop[1]-1 do
			text = text .. "\n" .. self.Rows[i]
		end
		
		return text .. "\n" .. string.sub(self.Rows[stop[1]], 1, stop[2] - 1)
	end
end

function EDITOR:SetArea(selection, text, isundo, isredo, before, after)
	local start, stop = self:MakeSelection(selection)
	
	local buffer = self:GetArea(selection)
	
	if start[1] != stop[1] or start[2] != stop[2] then
		// clear selection
		self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. string.sub(self.Rows[stop[1]], stop[2])
		self.PaintRows[start[1]] = false
		
		for i=start[1]+1,stop[1] do
			table.remove(self.Rows, start[1] + 1)
			table.remove(self.PaintRows, start[1] + 1)
			self.PaintRows = {} // TODO: fix for cache errors
		end
		
		// add empty row at end of file (TODO!)
		if self.Rows[#self.Rows] != "" then
			self.Rows[#self.Rows + 1] = ""
			self.PaintRows[#self.Rows + 1] = false
		end
	end
	
	if !text or text == "" then
		self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
		
		self.PaintRows = {}
		
		self:OnTextChanged()
		
		if isredo then
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		elseif isundo then
			self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, after, before }
			return before
		else
			self.Redo = {}
			self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(start) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(start) }
			return start
		end
	end
	
	// insert text
	local rows = string.Explode("\n", text)
	
	local remainder = string.sub(self.Rows[start[1]], start[2])
	self.Rows[start[1]] = string.sub(self.Rows[start[1]], 1, start[2] - 1) .. rows[1]
	self.PaintRows[start[1]] = false
	
	for i=2,#rows do
		table.insert(self.Rows, start[1] + i - 1, rows[i])
		table.insert(self.PaintRows, start[1] + i - 1, false)
		self.PaintRows = {} // TODO: fix for cache errors
	end
	
	local stop = { start[1] + #rows - 1, string.len(self.Rows[start[1] + #rows - 1]) + 1 }
	
	self.Rows[stop[1]] = self.Rows[stop[1]] .. remainder
	self.PaintRows[stop[1]] = false
	
	// add empty row at end of file (TODO!)
	if self.Rows[#self.Rows] != "" then
		self.Rows[#self.Rows + 1] = ""
		self.PaintRows[#self.Rows + 1] = false
		self.PaintRows = {} // TODO: fix for cache errors
	end
	
	self.ScrollBar:SetUp(self.Size[1], #self.Rows - 1)
	
	self.PaintRows = {}
	
	self:OnTextChanged()
	
	if isredo then
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	elseif isundo then
		self.Redo[#self.Redo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, after, before }
		return before
	else
		self.Redo = {}
		self.Undo[#self.Undo + 1] = { { self:CopyPosition(start), self:CopyPosition(stop) }, buffer, self:CopyPosition(selection[1]), self:CopyPosition(stop) }
		return stop
	end
end


function EDITOR:GetSelection()
	return self:GetArea(self:Selection())
end

function EDITOR:SetSelection(text)
	self:SetCaret(self:SetArea(self:Selection(), text))
end

function EDITOR:OnTextChanged()
end

function EDITOR:_OnLoseFocus()
	if self.TabFocus then
		self:RequestFocus()
		self.TabFocus = nil
	end
end

-- removes the first 0-4 spaces from a string and returns it
local function unindent(line)
	--local i = line:find("%S")
	--if i == nil or i > 5 then i = 5 end
	--return line:sub(i)
	return line:match("^ ? ? ? ?(.*)$")
end

function EDITOR:_OnTextChanged()
	local ctrlv = false
	local text = self.TextEntry:GetValue()
	self.TextEntry:SetText("")
	
	if (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) and not (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
		-- ctrl+[shift+]key
		if input.IsKeyDown(KEY_V) then
			-- ctrl+[shift+]V
			ctrlv = true
		else
			-- ctrl+[shift+]key with key ~= V
			return
		end
	end
	
	if text == "" then return end
	if not ctrlv then
		if text == "\n" then return end
		if text == "}" and false then
			self:SetSelection(text)
			local row = self.Rows[self.Caret[1]]
			if string.match("{" .. row, "^%b{}.*$") then
				local newrow = unindent(row)
				self.Rows[self.Caret[1]] = newrow
				self.Caret[2] = self.Caret[2] + newrow:len()-row:len()
				self.Start[2] = self.Caret[2]
			end
			return
		end
	end
	
	self:SetSelection(text)
end

function EDITOR:OnMouseWheeled(delta)
	self.Scroll[1] = self.Scroll[1] - 4 * delta
	if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	if self.Scroll[1] > #self.Rows then self.Scroll[1] = #self.Rows end
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:ScrollDown()
	self.Scroll[1] = #self.Rows
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:OnShortcut()
end

function EDITOR:ScrollCaret()
	if self.Caret[1] - self.Scroll[1] < 2 then
		self.Scroll[1] = self.Caret[1] - 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end
	
	if self.Caret[1] - self.Scroll[1] > self.Size[1] - 2 then
		self.Scroll[1] = self.Caret[1] - self.Size[1] + 2
		if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
	end
	
	if self.Caret[2] - self.Scroll[2] < 4 then
		self.Scroll[2] = self.Caret[2] - 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end
	
	if self.Caret[2] - 1 - self.Scroll[2] > self.Size[2] - 4 then
		self.Scroll[2] = self.Caret[2] - 1 - self.Size[2] + 4
		if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
	end
	
	self.ScrollBar:SetScroll(self.Scroll[1] - 1)
end

function EDITOR:FindFunction(self,reversed,searchterm,MatchCase)
	//local reversed = self:GetParent().Reversed
	//local searchterm = self:GetParent().String:GetValue()
	if searchterm=="" then return end
	//local oldself = self
	//self = self:GetParent():GetParent()
	if !MatchCase then
		searchterm = string.lower(searchterm)
	end
	local Num,Row = 1,1
	local find = false
	local currentrow = Row
	if !reversed then
		if self.Caret[1] < self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] < self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num+1
		end
		for i=Row, #self.Rows do
			local row = self.Rows[i]
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = i
			Num=1
			if find then break end
		end
	else
		if self.Caret[1] > self.Start[1] then
			Row=self.Caret[1]
		else
			Row=self.Start[1]
		end
		if self.Caret[2] > self.Start[2] then
			Num=self.Caret[2]
		else
			Num=self.Start[2]
		end
		if (MatchCase and self:GetSelection()==searchterm) or (!MatchCase and string.lower(self:GetSelection())==searchterm) then
			Num=Num-1
		end
		searchterm = string.reverse(searchterm)
		Num=#self.Rows[Row] - Num +2
		for i=1, Row do
			local now = Row-i+1
			local row = self.Rows[now]
			row = string.reverse(row)
			if !MatchCase then
				row = string.lower(row)
			end
			find = string.find(row,searchterm,Num,true)
			currentrow = now
			Num=1
			if find then
				find = #self.Rows[now] - (find - 2) - #searchterm
				break
			end
		end
	end
	if find then
		self.Caret[1] = currentrow
		self.Caret[2] = find+#searchterm
		self.Start[1] = currentrow
		self.Start[2] = find
		self:ScrollCaret()
	/*
	else
		if self.eof && type(self.eof)=="Panel" && self.eof:IsValid() then
			self.eof:Close()
		end
		self.eof = vgui.Create("DFrame", oldself)
		local popup = self.eof
		popup:SetSize(200,100)
		popup:Center()
		popup:SetTitle("End of file")
		popup:MakePopup()
		popup.Text = vgui.Create("DLabel", popup)
		popup.Text:SetPos(20,20)
		popup.Text:SetSize(200,20)
		popup.Text:SetText("File end has been reached")
	//*/
	end
end

function EDITOR:ReplaceNextFunction(self,ToRep,RepWith,MatchCase)
	local oldcoords = {self.Caret[1],self.Caret[2],self.Start[1],self.Start[2]}
	if ToRep == "" then return end
	self:FindFunction(self,false,ToRep,MatchCase)
	if oldcoords[1]!=self.Caret[1] or oldcoords[2]!=self.Caret[2] or oldcoords[3]!=self.Start[1] or oldcoords[4]!=self.Start[2] then
		self:SetArea(self:Selection(),RepWith)
		self.Caret[2]=self.Caret[2]-(#ToRep-#RepWith)
		self:ScrollCaret()
	end
end

function EDITOR:ReplaceAllFunction(self,ToRep,RepWith,MatchCase)
	if ToRep == "" then return end
	if MatchCase then
		local text = string.gsub(self:GetValue(),ToRep,RepWith)
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},text)
		self:ScrollCaret()
		return
	end
	local originaltext = self:GetValue()
	local text = string.lower(originaltext)
	ToRep = string.lower(ToRep)
	local offset = #ToRep-#RepWith
	local totaloffset = 0
	local curpos = 1
	local chardiff = #ToRep
	local success = false
	repeat
		local find = string.find(text,ToRep,curpos,true)
		if find then
			success = true
			originaltext = string.sub(originaltext,1,find+totaloffset-1)..RepWith..string.sub(originaltext,find+totaloffset+#ToRep)
			totaloffset=totaloffset-offset
			curpos = find+chardiff
		end
	until !find
	if success then
		self:SetArea({{1,1},{#self.Rows, string.len(self.Rows[#self.Rows]) + 1}},originaltext)
		self:ScrollCaret()
	end
end

function EDITOR:FindWindow()
	// Does a find box already exist? Kill it
	if self.FW && type(self.FW)=="Panel" && self.FW:IsValid() then
		self.FW:Close()
	end
	
	// Create the frame, make it highlight the line and show cursor
	FW = vgui.Create("DFrame",self)
	self.FW = FW
	FW.OldThink = FW.Think
	FW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FW.OldClose = FW.Close
	FW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FW.Reversed = true
	FW:SetSize(250,100)
	FW:ShowCloseButton(true)
	FW:SetTitle("Search")
	FW:MakePopup()
	FW:Center()
	
	// Search Textbox
	FW.String = vgui.Create("DTextEntry",FW)
	FW.String:SetPos(10,30)
	FW.String:SetSize(230,20)
	FW.String:RequestFocus()
	FW.String.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			self:GetParent().Next.DoClick(self:GetParent().Next)
		end
	end
	
	// Forward Checkbox
	FW.Forw = vgui.Create("DCheckBox",FW)
	FW.Forw:SetPos(115,55)
	FW.Forw:SetValue(false)
	FW.Forw.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Back:SetValue(self:GetChecked())
			self:GetParent().Reversed = false
			self:SetValue(!self:GetChecked())
		end
	end
	
	// Backward Checkbox
	FW.Back = vgui.Create("DCheckBox",FW)
	FW.Back:SetPos(115,75)
	FW.Back:SetValue(true)
	FW.Back.OnMousePressed = function(self)
		if !self:GetChecked() then
			self:GetParent().Forw:SetValue(self:GetChecked())
			self:GetParent().Reversed = true
			self:SetValue(!self:GetChecked())
		end
	end
	
	// Case Sensitive Checkbox
	FW.Case = vgui.Create("DCheckBoxLabel",FW)
	FW.Case:SetPos(10,75)
	FW.Case:SetValue(false)
	FW.Case:SetText("Case Sensitive")
	FW.Case:SizeToContents()
	
	// Checkbox Labels
	local Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Forw:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Forward")
	Label = vgui.Create("DLabel",FW)
	local xpos, ypos = FW.Back:GetPos()
	Label:SetPos(xpos+20,ypos-3)
	Label:SetText("Backward")
	
	// Cancel Button
	FW.CloseB = vgui.Create("DButton",FW)
	FW.CloseB:SetText("Cancel")
	FW.CloseB:SetPos(190,75)
	FW.CloseB:SetSize(50,20)
	FW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end
	
	// Find Button
	FW.Next = vgui.Create("DButton",FW)
	FW.Next:SetText("Find")
	FW.Next:SetPos(190,52)
	FW.Next:SetSize(50,20)
	FW.Next.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:FindFunction(self,self.FW.Reversed,self.FW.String:GetValue(),self.FW.Case:GetChecked())
	end
end

function EDITOR:FindAndReplaceWindow()
	// Does a find box already exist? Kill it
	if self.FRW && type(self.FRW)=="Panel" && self.FRW:IsValid() then
		self.FRW:Close()
	end
	
	// Create the frame, make it highlight the line and show cursor
	FRW = vgui.Create("DFrame",self)
	self.FRW = FRW
	FRW.OldThink = FRW.Think
	FRW.Think = function(self)
		self:GetParent().ForceDrawCursor = true
		self:OldThink()
	end
	FRW.OldClose = FRW.Close
	FRW.Close = function(self)
		self:GetParent().ForceDrawCursor = false
		self:OldClose(self)
	end
	FRW:SetSize(250,142)
	FRW:ShowCloseButton(true)
	FRW:SetTitle("Replace")
	FRW:MakePopup()
	FRW:Center()
	
	// ToReplace Textentry
	FRW.ToRep = vgui.Create("DTextEntry",FRW)
	FRW.ToRep:SetPos(10,30)
	FRW.ToRep:SetSize(230,20)
	FRW.ToRep:RequestFocus()
	FRW.ToRep.OnKeyCodeTyped = function(self,code)
		if ( code == KEY_ENTER ) then
			//self:GetParent().Replace.DoClick(self:GetParent().Next)
			self:GetParent().RepWith:RequestFocus()
		end
	end
	
	// ReplaceWith Textentry
	FRW.RepWith = vgui.Create("DTextEntry",FRW)
	FRW.RepWith:SetPos(10,64)
	FRW.RepWith:SetSize(230,20)
	
	// Text Labels
	local Label = vgui.Create("DLabel",FRW)
	Label:SetPos(12,50)
	Label:SetText("Replace With:")
	Label:SizeToContents()
	
	// Case Sensitive Checkbox
	FRW.Case = vgui.Create("DCheckBoxLabel",FRW)
	FRW.Case:SetPos(10,117)
	FRW.Case:SetValue(false)
	FRW.Case:SetText("Case Sensitive")
	FRW.Case:SizeToContents()
	
	// Cancel Button
	FRW.CloseB = vgui.Create("DButton",FRW)
	FRW.CloseB:SetText("Cancel")
	FRW.CloseB:SetPos(190,115)
	FRW.CloseB:SetSize(50,20)
	FRW.CloseB.DoClick = function(self)
		self:GetParent():Close()
	end
	
	// Replace Button
	FRW.Replace = vgui.Create("DButton",FRW)
	FRW.Replace:SetText("Replace")
	FRW.Replace:SetPos(190,90)
	FRW.Replace:SetSize(50,21)
	FRW.Replace.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceNextFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
	end
	
	// Replace All Button
	FRW.ReplaceAll = vgui.Create("DButton",FRW)
	FRW.ReplaceAll:SetText("Replace All")
	FRW.ReplaceAll:SetPos(127,90)
	FRW.ReplaceAll:SetSize(60,21)
	FRW.ReplaceAll.DoClick = function(self)
		self = self:GetParent():GetParent()
		self:ReplaceAllFunction(self,self.FRW.ToRep:GetValue(),self.FRW.RepWith:GetValue(),self.FRW.Case:GetChecked())
	end
	
end


function EDITOR:CanUndo()
	return #self.Undo > 0
end

function EDITOR:DoUndo()
	if #self.Undo > 0 then
		local undo = self.Undo[#self.Undo]
		self.Undo[#self.Undo] = nil
		
		self:SetCaret(self:SetArea(undo[1], undo[2], true, false, undo[3], undo[4]))
	end
end

function EDITOR:CanRedo()
	return #self.Redo > 0
end

function EDITOR:DoRedo()
	if #self.Redo > 0 then
		local redo = self.Redo[#self.Redo]
		self.Redo[#self.Redo] = nil
		
		self:SetCaret(self:SetArea(redo[1], redo[2], false, true, redo[3], redo[4]))
	end
end

function EDITOR:SelectAll()
	self.Caret = {#self.Rows, string.len(self.Rows[#self.Rows]) + 1}
	self.Start = {1, 1}
	self:ScrollCaret()
end

function EDITOR:Indent(shift)
	-- TAB with a selection --
	-- remember scroll position
	local tab_scroll = self:CopyPosition(self.Scroll)
	
	-- normalize selection, so it spans whole lines
	local tab_start, tab_caret = self:MakeSelection(self:Selection())
	tab_start[2] = 1
	
	if (tab_caret[2] ~= 1) then
		tab_caret[1] = tab_caret[1] + 1
		tab_caret[2] = 1
	end
	
	-- remember selection
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	if shift then
		-- shift-TAB with a selection --
		local tmp = self:GetSelection():gsub("\n ? ? ? ?", "\n")
		
		-- makes sure that the first line is outdented
		self:SetSelection(unindent(tmp))
	else
		-- plain TAB with a selection --
		self:SetSelection("    " .. self:GetSelection():gsub("\n", "\n    "))
	end
	-- restore selection
	self.Caret = self:CopyPosition(tab_caret)
	self.Start = self:CopyPosition(tab_start)
	-- restore scroll position
	self.Scroll = self:CopyPosition(tab_scroll)
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

function EDITOR:CommentSelection(shift) -- Multi-line comment feature ((shift-)ctrl-k) (idea by Jeremydeath)
	if not self:HasSelection() then return end
	
	local comment_char = "--"
	
	-- Comment a selection --
	-- remember scroll position
	local scroll = self:CopyPosition(self.Scroll)
	
	-- normalize selection, so it spans whole lines
	local sel_start, sel_caret = self:MakeSelection(self:Selection())
	sel_start[2] = 1
	
	if (sel_caret[2] ~= 1) then
		sel_caret[1] = sel_caret[1] + 1
		sel_caret[2] = 1
	end
	
	-- remember selection
	self.Caret = self:CopyPosition(sel_caret)
	self.Start = self:CopyPosition(sel_start)
	-- (temporarily) adjust selection, so there is no empty line at its end.
	if (self.Caret[2] == 1) then
		self.Caret = self:MovePosition(self.Caret, -1)
	end
	if shift then
		-- shift-TAB with a selection --
		local tmp = string.gsub("\n"..self:GetSelection(), "\n"..comment_char, "\n")
		
		-- makes sure that the first line is outdented
		self:SetSelection(tmp:sub(2))
	else
		-- plain TAB with a selection --
		self:SetSelection(comment_char .. self:GetSelection():gsub("\n", "\n"..comment_char))
	end
	-- restore selection
	self.Caret = self:CopyPosition(sel_caret)
	self.Start = self:CopyPosition(sel_start)
	-- restore scroll position
	self.Scroll = self:CopyPosition(scroll)
	-- trigger scroll bar update (TODO: find a better way)
	self:ScrollCaret()
end

function EDITOR:ContextHelp()
	local word
	if self:HasSelection() then
		word = self:GetSelection()
	else
		local row, col = unpack(self.Caret)
		local line = self.Rows[row]
		if not line:sub(col, col):match("^[a-zA-Z0-9_]$") then
			col = col - 1
		end
		if not line:sub(col, col):match("^[a-zA-Z0-9_]$") then
			surface.PlaySound("buttons/button19.wav")
			return
		end
		
		-- TODO substitute this for getWordStart, if it fits.
		local startcol = col
		while startcol > 1 and line:sub(startcol-1, startcol-1):match("^[a-zA-Z0-9_]$") do
			startcol = startcol - 1
		end
		
		-- TODO substitute this for getWordEnd, if it fits.
		local _,endcol = line:find("[^a-zA-Z0-9_]", col)
		endcol = (endcol or 0) - 1
		
		word = line:sub(startcol, endcol)
	end
end

function EDITOR:_OnKeyCodeTyped(code)/*
	--self.Blink = RealTime()
	
	local alt = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
	if alt then return end
	
	local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
	local control = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
	
	-- allow ctrl-ins and shift-del (shift-ins, like ctrl-v, is handled by vgui)
	if not shift and control and code == KEY_INSERT then
		shift,control,code = true,false,KEY_C
	elseif shift and not control and code == KEY_DELETE then
		shift,control,code = false,true,KEY_X
	end
	
	if control then
		if code == KEY_A then
			self:SelectAll()
		elseif code == KEY_Z then
			self:DoUndo()
		elseif code == KEY_Y then
			self:DoRedo()
		elseif code == KEY_X then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
				self:SetSelection()
			end
		elseif code == KEY_C then
			if self:HasSelection() then
				self.clipboard = self:GetSelection()
				self.clipboard = string.Replace(self.clipboard, "\n", "\r\n")
				SetClipboardText(self.clipboard)
			end
		-- pasting is now handled by the textbox that is used to capture input
		--[[
		elseif code == KEY_V then
			if self.clipboard then
				self:SetSelection(self.clipboard)
			end
		]]
		elseif code == KEY_F then
			self:FindWindow()
		elseif code == KEY_H then
			--self:FindAndReplaceWindow()
		elseif code == KEY_K then
			self:CommentSelection(shift)
		elseif code == KEY_Q then
			self:GetParent():Close()
		elseif code == KEY_UP then
			self.Scroll[1] = self.Scroll[1] - 1
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
		elseif code == KEY_DOWN then
			self.Scroll[1] = self.Scroll[1] + 1
		elseif code == KEY_LEFT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:wordLeft(self.Caret)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:wordRight(self.Caret)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		--[[ -- old code that scrolls on ctrl-left/right:
		elseif code == KEY_LEFT then
			self.Scroll[2] = self.Scroll[2] - 1
			if self.Scroll[2] < 1 then self.Scroll[2] = 1 end
		elseif code == KEY_RIGHT then
			self.Scroll[2] = self.Scroll[2] + 1
		]]
		elseif code == KEY_HOME then
			self.Caret[1] = 1
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			self.Caret[1] = #self.Rows
			self.Caret[2] = 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		end
		
	else
	
		if code == KEY_ENTER then
			local row = self.Rows[self.Caret[1]]:sub(1,self.Caret[2]-1)
			local diff = (row:find("%S") or (row:len()+1))-1
			local tabs = string.rep("    ", math.floor(diff / 4))
			if false and (string.match("{" .. row .. "}", "^%b{}.*$") == nil) then tabs = tabs .. "    " end
			self:SetSelection("\n" .. tabs)
		elseif code == KEY_UP then
			if self.Caret[1] > 1 then
				self.Caret[1] = self.Caret[1] - 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_DOWN then
			if self.Caret[1] < #self.Rows then
				self.Caret[1] = self.Caret[1] + 1
				
				local length = string.len(self.Rows[self.Caret[1]])
				if self.Caret[2] > length + 1 then
					self.Caret[2] = length + 1
				end
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_LEFT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, -1)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_RIGHT then
			if self:HasSelection() and !shift then
				self.Start = self:CopyPosition(self.Caret)
			else
				self.Caret = self:MovePosition(self.Caret, 1)
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEUP then
			self.Caret[1] = self.Caret[1] - math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] - math.ceil(self.Size[1] / 2)
			if self.Caret[1] < 1 then self.Caret[1] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			if self.Scroll[1] < 1 then self.Scroll[1] = 1 end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_PAGEDOWN then
			self.Caret[1] = self.Caret[1] + math.ceil(self.Size[1] / 2)
			self.Scroll[1] = self.Scroll[1] + math.ceil(self.Size[1] / 2)
			if self.Caret[1] > #self.Rows then self.Caret[1] = #self.Rows end
			if self.Caret[1] == #self.Rows then self.Caret[2] = 1 end
			
			local length = string.len(self.Rows[self.Caret[1]])
			if self.Caret[2] > length + 1 then self.Caret[2] = length + 1 end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_HOME then
			local row = self.Rows[self.Caret[1]]
			local first_char = row:find("%S") or row:len()+1
			if self.Caret[2] == first_char then
				self.Caret[2] = 1
			else
				self.Caret[2] = first_char
			end
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_END then
			local length = string.len(self.Rows[self.Caret[1]])
			self.Caret[2] = length + 1
			
			self:ScrollCaret()
			
			if !shift then
				self.Start = self:CopyPosition(self.Caret)
			end
		elseif code == KEY_BACKSPACE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({self.Caret, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and string.len(buffer) > 0 and string.rep(" ", string.len(buffer)) == buffer then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, -1)}))
				end
			end
		elseif code == KEY_DELETE then
			if self:HasSelection() then
				self:SetSelection()
			else
				local buffer = self:GetArea({{self.Caret[1], self.Caret[2] + 4}, {self.Caret[1], 1}})
				if self.Caret[2] % 4 == 1 and string.rep(" ", string.len(buffer)) == buffer and string.len(self.Rows[self.Caret[1]]) >= self.Caret[2] + 4 - 1 then
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 4)}))
				else
					self:SetCaret(self:SetArea({self.Caret, self:MovePosition(self.Caret, 1)}))
				end
			end
		elseif code == KEY_F1 then
			self:ContextHelp()
		end
	end
	
	if code == KEY_TAB or (control and (code == KEY_I or code == KEY_O)) then
		if code == KEY_O then shift = not shift end
		if code == KEY_TAB and control then shift = not shift end
		if self:HasSelection() then
			self:Indent(shift)
		else
			-- TAB without a selection --
			if shift then
				local newpos = self.Caret[2]-4
				if newpos < 1 then newpos = 1 end
				self.Start = { self.Caret[1], newpos }
				if self:GetSelection():find("%S") then
					-- TODO: what to do if shift-tab is pressed within text?
					self.Start = self:CopyPosition(self.Caret)
				else
					self:SetSelection("")
				end
			else
				local count = (self.Caret[2] + 2) % 4 + 1
				self:SetSelection(string.rep(" ", count))
			end
		end
		-- signal that we want our focus back after (since TAB normally switches focus)
		if code == KEY_TAB then self.TabFocus = true end
	end
	
	if control then
		self:OnShortcut(code)
	end*/
end

// Auto-completion

function EDITOR:IsVarLine()
	local first = string.Explode(" ", self.Rows[self.Caret[1]])[1]
	if(first == "@inputs" or first == "@outputs" or first == "@persist") then return true end
	return false
end

function EDITOR:getWordStart(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=0,caret[2] do
		if(!line[caret[2]-i]) then return {caret[1],caret[2]-i+1} end
		if(line[caret[2]-i] >= "a" and line[caret[2]-i] <= "z" or line[caret[2]-i] >= "A" and line[caret[2]-i] <= "Z" or line[caret[2]-i] >= "0" and line[caret[2]-i] <= "9") then else return {caret[1],caret[2]-i+1} end
	end
	return {caret[1],1}
end

function EDITOR:getWordEnd(caret)
	local line = string.ToTable(self.Rows[caret[1]])
	if(#line < caret[2]) then return caret end
	for i=caret[2],#line do
		if(!line[i]) then return {caret[1],i} end
		if(line[i] >= "a" and line[i] <= "z" or line[i] >= "A" and line[i] <= "Z" or line[i] >= "0" and line[i] <= "9") then else return {caret[1],i} end
	end
	return {caret[1],#line+1}
end

-- helpers for ctrl-left/right
function EDITOR:wordLeft(caret)
	local row = self.Rows[caret[1]]
	if caret[2] == 1 then
		if caret[1] == 1 then return caret end
		caret = { caret[1]-1, #self.Rows[caret[1]-1] }
		row = self.Rows[caret[1]]
	end
	local pos = row:sub(1,caret[2]-1):match("[^%w@]()[%w@]+[^%w@]*$")
	caret[2] = pos or 1
	return caret
end

function EDITOR:wordRight(caret)
	local row = self.Rows[caret[1]]
	if caret[2] > #row then
		if caret[1] == #self.Rows then return caret end
		caret = { caret[1]+1, 1 }
		row = self.Rows[caret[1]]
		if row:sub(1,1) ~= " " then return caret end
	end
	local pos = row:match("[^%w@]()[%w@]",caret[2])
	caret[2] = pos or (#row+1)
	return caret
end

/***************************** Syntax highlighting ****************************/

function EDITOR:ResetTokenizer(row)
	self.line = self.Rows[row]
	self.position = 0
	self.character = ""
	self.tokendata = ""
end

function EDITOR:NextCharacter()
	if not self.character then return end
	
	self.tokendata = self.tokendata .. self.character
	self.position = self.position + 1
	
	if self.position <= self.line:len() then
		self.character = self.line:sub(self.position, self.position)
	else
		self.character = nil
	end
end

function EDITOR:NextPattern(pattern)
	if !self.character then return false end
	local startpos,endpos,text = self.line:find(pattern, self.position)
	
	if startpos ~= self.position then return false end
	local buf = self.line:sub(startpos, endpos)
	if not text then text = buf end
	
	self.tokendata = self.tokendata .. text
	
	
	self.position = endpos + 1
	if self.position <= #self.line then
		self.character = self.line:sub(self.position, self.position)
	else
		self.character = nil
	end
	return true
end

do -- E2 Syntax highlighting
	local function istype(tp)
		return false
	end
	
	-- keywords[name][nextchar!="("]
	local keywords = {
		-- keywords that can be followed by a "(":
		["if"]       = { [true] = true, [false] = true },
		["elseif"]   = { [true] = true, [false] = true },
		["while"]    = { [true] = true, [false] = true },
		["for"]      = { [true] = true, [false] = true },
		["error"]  = { [true] = true, [false] = true },
		["ErrorNoHalt"]  = { [true] = true, [false] = true },
		["Error"]  = { [true] = true, [false] = true },
		["quit"]  = { [true] = true, [false] = true },
		["do"]  	 = { [true] = true, [false] = true },
		
		-- keywords that cannot be followed by a "(":
		["else"]     = { [true] = true },
		["break"]    = { [true] = true },
		["return"]    = { [true] = true },
		["returned"]    = { [true] = true },
		["end"]    = { [true] = true },
		["continue"] = { [true] = true },
	}
	
	-- fallback for nonexistant entries:
	setmetatable(keywords, { __index=function(tbl,index) return {} end })
	
	local colors = {
		["directive"] = { Color(240, 240, 160), false},
		["number"]    = { Color(250, 200, 200), false},
		["function"]  = { Color(160, 160, 240), false},
		["notfound"]  = { Color(250, 150, 150), false},
		["variable"]  = { Color(160, 240, 160), false},
		["string"]    = { Color(255, 255, 255), false},
		["keyword"]   = { Color(160, 160, 255), false},
		["operator"]  = { Color(224, 224, 224), false},
		["comment"]   = { Color(230, 230, 230), false},
		["ppcommand"] = { Color(240,  96, 240), false},
		["typename"]  = { Color(240, 160,  96), false},
	}
	
	function EDITOR:SyntaxColorLine(row)
		-- cols[n] = { tokendata, color }
		local cols = {}
		
		self:ResetTokenizer(row)
		self:NextCharacter()
		

		while self.character do
			local tokenname = ""
			self.tokendata = ""
			
			-- eat all spaces
			self.NextPattern(" *")
			if !self.character then break end
			
			-- eat next token
			if self:NextPattern("^[0-9][0-9.e]*") then
				tokenname = "number"
				
			elseif self:NextPattern("^[a-z][a-zA-Z0-9_]*") then
				local sstr = string.Trim(self.tokendata)
				
				local char = self.character or ""
				local keyword = char != "("
				
				self:NextPattern(" *")
				
				if self.character == "]" then
					-- X[Y,typename]
					tokenname = istype(sstr) and "typename" or "notfound"
				elseif keywords[sstr][keyword] then
					tokenname = "keyword"
				else
					tokenname = "notfound"
				end
			
				
			elseif self:NextPattern("^[A-Z][a-zA-Z0-9_]*") then
				tokenname = "variable"
				
			elseif self.character == "'" then
				self:NextCharacter()
				while self.character and self.character != "'" do
					if self.character == "\\" then self:NextCharacter() end
					self:NextCharacter()
				end
				self:NextCharacter()
				
				tokenname = "string"

			elseif self.character == '"' then
				self:NextCharacter()
				while self.character and self.character != '"' do
					if self.character == "\\" then self:NextCharacter() end
					self:NextCharacter()
				end
				self:NextCharacter()
				
				tokenname = "string"
				
			elseif self:NextPattern("%-%-[^ ]*") then
					self:NextPattern(".*")
					tokenname = "comment"
			elseif self:NextPattern("//[^ ]*") then
					self:NextPattern(".*")
					tokenname = "comment"
			else
				self:NextCharacter()
				
				tokenname = "operator"
			end
			
			color = colors[tokenname]
			if #cols > 1 and color == cols[#cols][2] then
				cols[#cols][1] = cols[#cols][1] .. self.tokendata
			else
				cols[#cols + 1] = {self.tokendata, color}
			end
		end
		
		return cols
	end -- EDITOR:SyntaxColorLine
end -- do...

vgui.Register("EPOE", EDITOR, "Panel")






local cvar = CreateClientConVar("EPOE_UI_enable", 0, true, false)

function EPOE_UI()
	if EPOE.Frame and EPOE.Frame:IsValid() then 
		EPOE.Frame:Remove()
		return
	end
	EPOE.Frame=vgui.Create('EditablePanel')
	
	EPOE.Frame:SetPaintBackgroundEnabled( false )
	EPOE.Frame:SetPaintBorderEnabled( false )
	

	EPOE.Frame:SetPos(0,200)
	EPOE.Frame:SetZPos(-5) -- Lowerrr. Let's hope no "window" covers us though
	EPOE.Frame:SetSize(ScrW()/1.75,ScrH()/4)
	
	local restore=file.Read"EPOE_Cookie.txt"
	
	if restore and restore!="" then
		local tbl=llon.decode(restore)
		if tbl then
			EPOE.Frame:SetPos(tbl.x or 0,tbl.y or 0)
			EPOE.Frame:SetSize(tbl.w or 480,tbl.h or 320)
		end
	end
	
	function EPOE.Frame:Paint()
		--surface.SetDrawColor(32, 32, 32, 0)
		--surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
		if transparent>180 then
			surface.SetDrawColor(0, 0, 0, transparent	)
			surface.DrawOutlinedRect(1, 1, self:GetWide()-1, self:GetTall()-1)
		end
		
		transparent = math.Clamp(transparent - fadetime:GetFloat(), 0, 255)
		
	end
	
	
	function EPOE.Frame:Think()

		if (self.Dragging) then
		
			local x = gui.MouseX() - self.Dragging[1]
			local y = gui.MouseY() - self.Dragging[2]

			x = math.Clamp( x, 0, ScrW() - self:GetWide() )
			y = math.Clamp( y, 0, ScrH() - self:GetTall() )
			
			
			self:SetPos( x, y )
		
		end
		
		
		
		if ( self.Sizing ) then
		
			local x = gui.MouseX() - self.Sizing[1]
			local y = gui.MouseY() - self.Sizing[2]	

			x = math.Max( x, 200 )
			y = math.Max( y, 40 )
			
			self:SetSize( x, y )
			self:SetCursor( "sizenwse" )
			return
		
		end
		
		if ( input.IsKeyDown(KEY_LALT) && (self.Hovered || self.TextBox.Hovered) &&
			 gui.MouseX() > (self.x + self:GetWide() - 20) &&
			 gui.MouseY() > (self.y + self:GetTall() - 20) ) then	

			self:SetCursor( "sizenwse" )
			return
			
		end
		
		if ( input.IsKeyDown(KEY_LALT) && (self.Hovered || self.TextBox.Hovered) ) then
			self:SetCursor( "sizeall" )
		end
		
	end
	
	EPOE.TextBox=vgui.Create('EPOE',EPOE.Frame)
	EPOE.Frame.TextBox=EPOE.TextBox
	--self:SetCookie( "LeftWidth", self.m_iLeftWidth )
	--self:SetLeftWidth( self:GetCookieNumber( "LeftWidth", self:GetLeftWidth() ) )

	function EPOE.Frame:PerformLayout()
		self.TextBox:StretchToParent(1,1,1,1)
	end
	
	function EPOE.Frame:OnMousePressed()
		if ( gui.MouseX() > (self.x + self:GetWide() - 20) &&
			gui.MouseY() > (self.y + self:GetTall() - 20) ) then			

			self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
			self:MouseCapture( true )
			self.TextBox:MouseCapture( true )
			return
		end
			
		
		self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
		self:MouseCapture( true )
		self.TextBox:MouseCapture( true )
		return

	end
	function EPOE.Frame:OnMouseReleased()
		
		self.Dragging = nil
		self.Sizing = nil
		self:MouseCapture( false )
		self.TextBox:MouseCapture( false )
		local x,y=self:GetPos()
		file.Write("EPOE_Cookie.txt", llon.encode( {w=self:GetWide(),h=self:GetTall(),x=x,y=y} ) )
	end

	EPOE.Frame.OnCursorMoved = function() transparent = 255 end
	
	EPOE.Frame:SetMouseInputEnabled(true)
	--EPOE.Frame:SetKeyboardInputEnabled(true)
	EPOE.TextBox:SetMouseInputEnabled(true)
	--EPOE.TextBox:SetKeyboardInputEnabled(true)

	RunConsoleCommand("EPOE_UI_enable", "1")
	
	EPOE.Subscribe()
	
	EPOE.Clear()
end
concommand.Add('EPOE_UI',EPOE_UI)
concommand.Add('+epoe',function()
	if !EPOE.Frame or !EPOE.Frame:IsValid() then 
		EPOE_UI()
	else
		EPOE.Frame:SetVisible(true)
	end

end)
concommand.Add('-epoe',function()
	if !EPOE.Frame or !EPOE.Frame:IsValid() then 
		return
	else
		EPOE.Frame:SetVisible(false)
	end

end)

hook.Add("InitPostEntity", "EpoeCheck", function()
	if cvar:GetBool() then
		EPOE_UI()
	end
end)


hook.Add('EPOE','EPOEMsg',function(Text)
	Msg(Text)
end)

local MaxHistoryLines=502
local TextHistory=""




function EPOE.AddText(newText)
	
	TextHistory=TextHistory..tostring(--[[ Need tostring? ]]newText)
	
	local trim=string.Explode("\n",TextHistory)
	while (#trim >= MaxHistoryLines) do
		table.remove( trim, 1 ) -- oh wow that was simple , lol. new REV: I take that back :(
	end
	TextHistory=string.Implode("\n",trim or {"EPOE Failed :("})
	
	if EPOE.TextBox and EPOE.TextBox:IsValid() and (!EPOE.TextBox:HasSelection() or transparent < 10) then
		EPOE.TextBox:SetText(TextHistory) -- This now accepts strings and string tables :) But it's no use
		EPOE.TextBox:ScrollDown()
		transparent = 255
	else
		return false
	end
end


hook.Add('EPOE','EPOEMsgBox',function(newText)
	EPOE.AddText(newText)
end)
	
function EPOE.Clear()
	TextHistory=""
	EPOE.TextBox:SetText("")
	EPOE.AddText(Description.." Loaded!\n")
	EPOE.TextBox:ScrollDown()
end


concommand.Add('EPOE_CLEAR', EPOE.Clear)
MsgN				"Loaded."