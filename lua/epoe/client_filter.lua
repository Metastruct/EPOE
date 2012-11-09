-- TODO
-- Add error filtering here!

local e=epoe
local Tag=e.Should_TagHuman -- or "EPOE"
local push=table.insert
---------------
-- Clientside Console UI
---------------
local epoe_filtering=CreateClientConVar("epoe_filtering", "1", true, false)

e.filters=e.filters or {
	hasany=false,
	full={},
	find={},
	regex={}
}

local full=e.filters.full
local find=e.filters.find
local regex=e.filters.regex

local function add(str)
	local strtype=str:sub(1,1) 
	if strtype=='!' then -- full
		push(full,str:sub(2,-1))
	elseif strtype=='"' then -- string
		str = str:match[[^"(.+)"$]] or str:match[[^"(.+)$]]
		assert(str!=nil)
		push(find,str)
	elseif strtype=='^' then -- regex
		str=str:sub(2,-1)
		local ok,err=pcall(string.find,"test",str)
		if not ok then ErrorNoHalt
			"EPOE Regex parse failure: "
		timer.Simple(0,e.internalPrint,"Filters: Line "..k..": Error in regex:"..tostring(err))
			return false
		end
		push(regex,str)
	elseif strtype=='#' or strtype=='-' or strtype=='/'   then -- regex
		-- comment
	else
		timer.Simple(0,e.internalPrint,"Filters: Line "..k..": Match type "..strtype.." is unknown!")
		return false
	end
	return true
end

local function Reload() 

	table.Empty( full )
	table.Empty( find )
	table.Empty( regex )

	local data=file.Read("epoe_filters.txt")
	if not data then return end
	local i=0
	for k,str in pairs(string.Explode("\n",data)) do
		str=string.TrimLeft(str) -- we may have spaces on right side
		if str:len()>0 then
			if add(str) then
				i=i+1
			end
		end
	end
	if i>0 then
		e.filters.hasany=true
	end
	if epoe_filtering:GetBool() and i>1 then
		timer.Simple(0,e.AddText,Color(255,255,255),"[EPOE] Filters: ",Color(255,255,255,255),"Loaded "..i.."filters.")
	end
end
Reload()

concommand.Add("epoe_filter_reload",Reload)

local sfind=string.find
hook.Add(Tag,Tag,function(txt,flags)
	if not epoe_filtering:GetBool() or not e.filters.hasany then return end

	if #full>0 and full[txt] 			then return false end

	if #find>0 then
		for _,str in ipairs(find) do
			if sfind(txt,str,1,true) 	then return false end end
	end

	if #regex>0 then
		for _,str in ipairs(regex) do
			if sfind(txt,str) 			then return false end end
	end
end)