-- TODO
-- Add error filtering here!

local e=epoe
local Tag=e.Should_TagHuman -- or "EPOE"

---------------
-- Clientside Console UI
---------------
local epoe_filtering=CreateClientConVar("epoe_filtering", "1", true, false)
local epoe_filtering_dbg=CreateClientConVar("epoe_filtering_dbg", "0", true, false)

e.filters=e.filters or {
	hasany=false,
	full={},
	find={},
	regex={}
}

local full=e.filters.full
local find=e.filters.find
local regex=e.filters.regex

local function add(str,k)
	
	local strtype=str:sub(1,1)
	local count=tonumber(str:sub(2,2))
	local data = str:sub(3,-1)
	
	if not count then return false end
	
	if strtype=='!' then -- full
		full[data] = count
	elseif strtype=='"' then -- string
	
		assert(data~="","empty string")
		table.insert(find,{data,count})
		
	elseif strtype=='^' then -- regex
	
		local ok,err=pcall(string.find,"test",str)
		if not ok then
			ErrorNoHalt"EPOE Regex parse failure: " e.internalPrint("Filters: Line "..k..": Error in regex:"..tostring(err))
			return false
		end
		table.insert(regex,{data,count})
		
	elseif strtype=='#' or strtype=='-' or strtype=='/' then -- regex
		-- comment
	else
		e.internalPrint("Filters: Line "..k..": Match type "..strtype.." is unknown!")
		return false
	end
	e.filters.hasany = true
	return true
end
local function ADD(X,Y)
	concommand.Add("epoe_filter_"..X,function(_,cmd,_,filter)
		local x=filter:sub(2,2)
		filter=filter:sub(1,1)..filter:sub(3,-1)
		if x~=" " then
			Msg"[EPOE] "print"Syntax: epoe_filter_* N PARAMSTR (N is skip extra messages count)"
			return
		end
		
		if not add(Y..filter,-1) then
			Msg"[EPOE] "print"Filter add failed"
			return
		end
		e.internalPrint("Added filter with extraskips="..filter:sub(1,1).." and filterstr '"..Y..filter.."'")
		if cmd:find"write" then
			file.Append("epoe_filters.txt",Y..filter..'\n')
		end
	end , nil,"epoe_filter_"..X..' <skip extra messages count, use 0 by default> <match string>')
end
ADD("exact","!")
ADD("partial",'"')
ADD("regex","^")
ADD("write_exact","!")
ADD("write_partial",'"')
ADD("write_regex","^")

local function Reload()

	table.Empty( full )
	table.Empty( find )
	table.Empty( regex )
	e.filters.hasany = false
	
	local data=file.Read("epoe_filters.txt",'DATA')
	if not data then return end
	local i=0
	for k,str in pairs(string.Explode("\n",data)) do
		str=string.TrimLeft(str) -- we may have spaces on right side
		if str:len()>1 then
			if add(str,k) then
				i=i+1
			end
		end
	end
	if epoe_filtering:GetBool() and i>1 then
		timer.Simple(0,function()
			e.AddText(Color(255,255,255),"[EPOE] Filters: ",Color(255,255,255,255),"Loaded "..i.."filters.")
		end)
	end
end
Reload()

concommand.Add("epoe_filters_reload",Reload)
concommand.Add("epoe_filters_panic",function()
	table.Empty( full )
	table.Empty( find )
	table.Empty( regex )
	e.filters.hasany = false
	file.Delete("epoe_filters.txt",'DATA')
end)

local skipnext=0
local sfind=string.find
local function ShouldFilter(txt,flags)
	if skipnext>0 then
		skipnext=skipnext-1
		--print("SKIP",txt)
		return true
	end
	
	--exact match
	local count=full[txt]
	if count then
		skipnext=count or 0
		return true
	end

	-- string match
	if #find>0 then
		for _,t in next,find do
			local str=t[1]
			if sfind(txt,str,1,true) then
				skipnext=t[2]
				return true
			end
		end
	end
	
	if #regex>0 then
		for _,t in ipairs(regex) do
			local str=t[1]
			if sfind(txt,str) then
				skipnext=t[2]
				return true
			end
		end
	end
	
end

local skipshit
hook.Add(Tag,Tag,function(txt,flags)
	if not epoe_filtering:GetBool()
	or not e.filters.hasany
	or skipshit
	then
		return
	end

	if ShouldFilter(txt,flags) then
		if epoe_filtering_dbg:GetBool() then
			skipshit=true
			e.MsgC(Color(255,4,3),"~")
			skipshit=false
		end
		return false
	end
end)
