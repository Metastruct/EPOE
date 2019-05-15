local PAT1,PAT1_X,PAT2,PAT2_X,PAT3,PAT3_X=
	'lua%/[^%s%:]+%.lua% ?:% ?%d+',
	'(lua%/[^%s%:]+%.lua)% ?:% ?(%d+)',
	'includes%/[^%s%:]+%.lua% ?:% ?%d+',
	'(includes%/[^%s%:]+%.lua)% ?:% ?(%d+)',
	'gamemodes%/[^%s%:]+%.lua% ?:% ?%d+',
	'(gamemodes%/[^%s%:]+%.lua)% ?:% ?(%d+)'

local Tag='epoelinkx'

local epoe_lua_files_as_urls = CreateClientConVar("epoe_lua_files_as_urls","1",true)

hook.Add("EPOEAddLinkPatterns",Tag,function(t)
	
	if not epoe_lua_files_as_urls:GetBool() then return end
	
	table.insert(t,PAT1)
	table.insert(t,PAT2)
	table.insert(t,PAT3)
end)

local function ShowCode(c,p,l)
	
	--print("ShowCode",l,p,('%q'):format(c:sub(1,100)):gsub("\n","\\n"))
	
	chatgui.Lua.code:SetCode(c,p or "IDK")
	chatgui.Lua.code:GotoLine(tonumber(l or 1))
	chatgui:SetTab(2)
	chatgui:Show()
end

hook.Add("EPOEOpenLink",Tag,function(l)
	local f,line = l:match(PAT1_X)
	if not line then
		f,line = l:match(PAT2_X)
		if not line then
			f,line = l:match(PAT3_X)
		end
	end
	if not line then return end
	--print(('%q'):format(line))
	local e1 = file.Exists(f:gsub("^lua/",""):gsub("^gamemodes/",""),'LUA')
	local e2 = file.Exists(f,'GAME')
	
	if not e1 and not e2 then
		print("asking",('%q'):format(f),line)
		filebrowser.AskServer(f,{l=tonumber(line)})
	elseif e1 then
		file.ReadLuaCache(f,function(dat)
			if not dat then
				print( dat,e )
				return
			end
			print("line",line)
			ShowCode(dat,"cl/"..f:gsub("^lua/",""):gsub("^gamemodes/",""),tonumber(line))
		end)
	elseif e2 then
		print("OWN FILE")
		local dat = file.Read(f,'GAME')
		ShowCode(dat,f:gsub("^lua/",""):gsub("^gamemodes/",""),line)
	else
		error"wot"
	end
	
	return true
end)

hook.Add("filebrowser",Tag,function(dec,extra)
	if not extra or not extra.l or not dec.code then return end
	
	print("got code",#dec.code,"line",extra.l)
	ShowCode(dec.code, "sv/"..dec.path,extra.l)
	
	return true
end)
