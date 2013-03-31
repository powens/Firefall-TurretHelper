-- Quality of Life Library : Revision 5
-- Lemon King

-- REF: Firefall Lua 5.1

require "strings"
require "table"
require "math"
--require "lib/lib_table"


lib_qol = {}
lib_qol.print = function(buffer, chatOutput)
	--if chatOutput is undefined broadcast will be used
	if type(chatOutput) ~= "string" then chatOutput = nil end
	Component.GenerateEvent("MY_CHAT_MESSAGE", {channel=chatOutput or "system", text=buffer})
end

lib_qol.table_wipe = function(t)
	t = {}
end

lib_qol.pack = function(...)
	return { ... }
end

lib_qol.unpack = function(tbl, i)
	-- Unpack Emulation using recursion
	if not type(tbl) == "table" then error("unpack(): Not a Table!") return nil end
    i = i or 1
    if tbl[i] then
        return tbl[i], lib_qol.unpack(tbl, i + 1)
    end	
end

lib_qol.select = function(index, ...)
	local list = { ... }
	local return_list = {}
	
	if index == 0 then error("select(): index out of range") return nil
	elseif index < 0 then index = #list warn("select(): index is less than zero")
	elseif index > #list then return nil 
	end

	for idx=index,#list do
		table.insert(return_list, list[idx])
	end
	
	return lib_qol.unpack(return_list)
end

lib_qol.string_join = function(delimiter, ...)
	if not type(delimiter) == "string" then 
		error("string.join(): Delimiter is not a string! Usage string.join(delimiter, string1, string2, ...)")
		return nil
	end
	local strings = { ... }
	local buffer = ""
	
	for idx,value in ipairs(strings) do
		if idx < #strings then
			buffer = buffer..value..delimiter
		else
			buffer = buffer..value
		end
	end

	return buffer
end

lib_qol.string_concat = function( ... )
	local strings = { ... }
	local buffer = ""
	for idx, value in ipairs(strings) do
		if not type(value) == "number" or type(value) == "string" then return nil end
		buffer = buffer..tostring(value)
	end

	return buffer
end

lib_qol.to_string_all = function( ... )
	local strings = { ... }
	for idx, value in ipairs(strings) do
		strings[idx] = tostring(value)
	end

	return lib_qol.unpack(strings)
end

-- Globals for any script calling lib_qol

-- Alias List equiv to WoW
--Tables
tinsert		= table.insert
tremove 	= table.remove
tsort		= table.sort	-- This function is sort in wow, but I'm calling it tsort here to fit with the format

-- Strings
format		= string.format
gsub		= string.gsub
strbyte		= string.byte
strchar		= string.char
strfind		= string.find
strlen		= string.len
strlower	= string.lower
strmatch	= string.match
strrep		= string.rep
strrev		= string.reverse
strsub		= string.sub
strupper	= string.upper
--tonumber	= string.tonumber
--tostring	= string.tostring

-- Math
abs			= math.abs
acos		= math.acos
asin		= math.asin 
atan		= math.asin
atan2		= math.atan2
ceil		= math.ceil
cos			= math.cos
deg			= math.deg
exp			= math.exp
floor		= math.floor
fmod		= math.fmod or math.mod
frexp		= math.frexp
ldexp		= math.ldexp
loge		= math.log		--log is used to dump information to console so loge is the new alt
log10		= math.log10
max			= math.max
min			= math.min
mod			= math.fmod or math.mod
rad			= math.rad
random		= math.random
sin			= math.sin
sqrt		= math.sqrt
tan			= math.tan


-- Custom (QoL Table)
table.wipe 			= lib_qol.table_wipe
twipe				= lib_qol.table_wipe
pack				= lib_qol.pack		-- Emulates Lua 5.2
unpack				= lib_qol.unpack	-- Emulates Lua 5.1
table.pack			= lib_qol.pack
table.unpack		= lib_qol.unpack	-- Emulates Lua 5.2
select				= lib_qol.select

string.join 		= lib_qol.string_join
string.concat 		= lib_qol.string_concact
string.tostringall 	= lib_qol.to_string_all 
strjoin 			= lib_qol.string_join
strconcat			= lib_qol.string_concact
tostringall 		= lib_qol.to_string_all

print 				= lib_qol.print