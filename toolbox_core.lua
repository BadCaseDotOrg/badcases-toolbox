--
-- json.lua
--
-- Copyright (c) 2019 rxi
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
json = {
    _version = "0.1.2"
}

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

local escape_char_map = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t"
}

local escape_char_map_inv = {
    ["\\/"] = "/"
}
for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
end

local function escape_char(c)
    return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

local function encode_nil(val)
    return "null"
end

local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then
        error("circular reference")
    end

    stack[val] = true

    if rawget(val, 1) ~= nil or next(val) == nil then
        -- Treat as array -- check keys are valid and it is not sparse
        local n = 0
        for k in pairs(val) do
            if type(k) ~= "number" then
                error("invalid table: mixed or invalid key types")
            end
            n = n + 1
        end
        if n ~= #val then
            error("invalid table: sparse array")
        end
        -- Encode
        for i, v in ipairs(val) do
            table.insert(res, encode(v, stack))
        end
        stack[val] = nil
        return "[" .. table.concat(res, ",") .. "]"

    else
        -- Treat as an object
        for k, v in pairs(val) do
            if type(k) ~= "string" then
                error("invalid table: mixed or invalid key types")
            end
            table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
        end
        stack[val] = nil
        return "{" .. table.concat(res, ",") .. "}"
    end
end

local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end

local function encode_number(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
end

local type_func_map = {
    ["nil"] = encode_nil,
    ["table"] = encode_table,
    ["string"] = encode_string,
    ["number"] = encode_number,
    ["boolean"] = tostring
}

encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
end

function json.encode(val)
    return (encode(val))
end

-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[select(i, ...)] = true
    end
    return res
end

local space_chars = create_set(" ", "\t", "\r", "\n")
local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals = create_set("true", "false", "null")

local literal_map = {
    ["true"] = true,
    ["false"] = false,
    ["null"] = nil
}

local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
            return i
        end
    end
    return #str + 1
end

local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
            line_count = line_count + 1
            col_count = 1
        end
    end
    error(string.format("%s at line %d col %d", msg, line_count, col_count))
end

local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error(string.format("invalid unicode codepoint '%x'", n))
end

local function parse_unicode_escape(s)
    local n1 = tonumber(s:sub(3, 6), 16)
    local n2 = tonumber(s:sub(9, 12), 16)
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
end

local function parse_string(str, i)
    local has_unicode_escape = false
    local has_surrogate_escape = false
    local has_escape = false
    local last
    for j = i + 1, #str do
        local x = str:byte(j)

        if x < 32 then
            decode_error(str, j, "control character in string")
        end

        if last == 92 then -- "\\" (escape char)
            if x == 117 then -- "u" (unicode escape sequence)
                local hex = str:sub(j + 1, j + 5)
                if not hex:find("%x%x%x%x") then
                    decode_error(str, j, "invalid unicode escape in string")
                end
                if hex:find("^[dD][89aAbB]") then
                    has_surrogate_escape = true
                else
                    has_unicode_escape = true
                end
            else
                local c = string.char(x)
                if not escape_chars[c] then
                    decode_error(str, j, "invalid escape char '" .. c .. "' in string")
                end
                has_escape = true
            end
            last = nil

        elseif x == 34 then -- '"' (end of string)
            local s = str:sub(i + 1, j - 1)
            if has_surrogate_escape then
                s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
            end
            if has_unicode_escape then
                s = s:gsub("\\u....", parse_unicode_escape)
            end
            if has_escape then
                s = s:gsub("\\.", escape_char_map_inv)
            end
            return s, j + 1

        else
            last = x
        end
    end
    decode_error(str, i, "expected closing quote for string")
end

local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
end

local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
end

local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
            i = i + 1
            break
        end
        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "]" then
            break
        end
        if chr ~= "," then
            decode_error(str, i, "expected ']' or ','")
        end
    end
    return res, i
end

local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
            i = i + 1
            break
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
            decode_error(str, i, "expected string for key")
        end
        key, i = parse(str, i)
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
            decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        val, i = parse(str, i)
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "}" then
            break
        end
        if chr ~= "," then
            decode_error(str, i, "expected '}' or ','")
        end
    end
    return res, i
end

local char_func_map = {
    ['"'] = parse_string,
    ["0"] = parse_number,
    ["1"] = parse_number,
    ["2"] = parse_number,
    ["3"] = parse_number,
    ["4"] = parse_number,
    ["5"] = parse_number,
    ["6"] = parse_number,
    ["7"] = parse_number,
    ["8"] = parse_number,
    ["9"] = parse_number,
    ["-"] = parse_number,
    ["t"] = parse_literal,
    ["f"] = parse_literal,
    ["n"] = parse_literal,
    ["["] = parse_array,
    ["{"] = parse_object
}

parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
end

function json.decode(str)
    if type(str) ~= "string" then
        error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res
end

-- ‐-------------------------
-- End of json.lua
----------------------------

------------------------ 
----Select Lib Start----
------------------------
function select_lib()
    local lib_name_gen_script = {}
    local lib_selector = {}
    local lib_selector_start = {}
    local lib_selector_end = {}
    local check_libs = gg.getRangesList()
    for k, v in pairs(check_libs) do
        if string.match(check_libs[k]["name"], "%.dat") or 
			string.match(check_libs[k]["name"], "%[stack%]") or
            string.match(check_libs[k]["name"], "/vendor/") or 
			string.match(check_libs[k]["name"], "/system/") or
            string.match(check_libs[k]["name"], "/dev/") or 
			string.match(check_libs[k]["name"], "%[heap%]") or
            string.match(check_libs[k]["name"], "%.art") or 
			string.match(check_libs[k]["name"], "anon_inode:") or
            string.match(check_libs[k]["name"], "deleted") or 
			string.match(check_libs[k]["name"], "anon:") or
            string.match(check_libs[k]["name"], "%.ttf") or 
			string.match(check_libs[k]["name"], ".") == nil then
            check_libs[k] = nil
        elseif check_libs[k]["name"]:find(".so$") then
            get_size_array = {}
            for i, v in pairs(check_libs[k]) do
                table.insert(get_size_array, v)
            end
            local file_size = tonumber(get_size_array[1]) - tonumber(get_size_array[6])
            local file_start = tonumber(get_size_array[6])
            local file_end = tonumber(get_size_array[1])
            if file_size < 5120000 then
                check_libs[k] = nil
            else
                local divide_by = "1024000"
                local size_math = tonumber(file_size) / tonumber(divide_by)
                local size_display = size_math .. "MB"
                table.insert(lib_name_gen_script, check_libs[k]["name"])
                local flibname = check_libs[k]["name"]
                if string.find(v["name"], "libil2cpp.so") or string.find(v["name"], "split_config.armeabi_v7a.apk") or
                    string.find(v["name"], "split_config.arm64_v8a.apk") then
                    menu_string = "〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️\nName: " ..
                                    v["name"] .. "\nRange: " .. v.state .. "\nStart Address: " ..
                                    hex_o(get_size_array[6]) .. "\nEnd Address: " .. hex_o(get_size_array[1]) ..
                                    "\nSize: " .. size_display .. "\n〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️"
                else
                    menu_string = "━━━━━━━━━━━━\nName: " .. v["name"] .. "\nRange: " .. v.state ..
								"\nStart Address: " .. hex_o(get_size_array[6]) .. "\nEnd Address: " ..
								hex_o(get_size_array[1]) .. "\nSize: " .. size_display .. "\n━━━━━━━━━━━━"
                end
                if string.find(flibname, "-") and string.find(flibname, "==") then
                    local lib_search = string.find(flibname, "-")
                    local lib_search2 = string.find(flibname, "==")
                    local libname_part1 = string.sub(flibname, 1, lib_search - 1)
                    local libname_part2 = string.sub(flibname, lib_search2 + 2)
                    table.insert(lib_selector, menu_string)
                else
                    table.insert(lib_selector, menu_string)
                end
                table.insert(lib_selector_start, file_start)
                table.insert(lib_selector_end, file_end)
            end
        end
    end
    ::select_lib::
    local h = gg.choice(lib_selector, nil, script_title .. "\n\nℹ️ Select libil2cpp.so Library ℹ️")
    if h == nil then
        goto select_lib
    else
        local lib_name = lib_name_gen_script[h]
        for str in string.gmatch(lib_name, "([^/]+)") do
            fixed_lib_name = str
        end
        BASEADDR = lib_selector_start[h]
        if lib_selector[h + 2] and string.gsub(lib_selector[h], "(.+so ).+", "%1") == string.gsub(lib_selector[h + 2], "(.+so ).+", "%1") then
            ENDADDR = lib_selector_end[h + 2]
        elseif string.gsub(lib_selector[h], "(.+so ).+", "%1") == string.gsub(lib_selector[h + 1], "(.+so ).+", "%1") then
            ENDADDR = lib_selector_end[h + 1]
        else
            ENDADDR = lib_selector_end[h]
        end
    end
    gg.toast("✅ " .. fixed_lib_name .. " Selected ✅")
    ::end_select::
end

function hex_o(n)
    return "0x" .. string.upper(string.format("%x", n))
end

function hexnx(n)
    return string.format("%X", n)
end

------------------------
-----Select Lib End-----
------------------------

script_title = "🧰 BadCase's Toolbox 🧰\nGame: " .. gg.getTargetInfo().label .. "\nPackage: " .. gg.getTargetPackage()
dataPath = gg.EXT_STORAGE .. "/BC_DATA/"
pluginsDataPath = gg.EXT_STORAGE .. "/BC_DATA/plugins/"
configDataPath = gg.EXT_STORAGE .. "/BC_DATA/config/"
arch = gg.getTargetInfo()
game_path = gg.getTargetPackage()
dump_cs_table = {}
bc_toolbox_method_types = {}
bc_toolbox_method_types_all = {}
save_dump = false
dumpHandler = {
    --[[
	---------------------------------------
	
	dumpHandler.createDirectory()
	
	---------------------------------------
	]] --
    createDirectory = function()
        directory_created = true
        for i, v in pairs(gg.getRangesList()) do
            if v["end"] - v.start < 10240 then
                if not string.find(v["name"], "deleted") then
                    create_start = v.start
                    create_end = v["end"]
                    break
                end
            end
        end
        gg.dumpMemory(create_start, create_end, dataPath .. game_path .. "/", gg.DUMP_SKIP_SYSTEM_LIBS)
        gg.dumpMemory(create_start, create_end, dataPath .. game_path .. "/scripts/", gg.DUMP_SKIP_SYSTEM_LIBS)
    end,
    --[[
	---------------------------------------
	
	dumpHandler.importDump()
	
	---------------------------------------
	]] --
    importDump = function()
        local startTime = os.time()
        local fileName = gg.prompt({"ℹ️ Select Dump.cs ℹ️"}, nil, {"file"})
        if fileName ~= nil then
            local tempDumpTable = {}
            local file = assert(io.open(fileName[1], "r"))
            local content = file:read("*a")
            file:close()
            local delimiter = "\n"
            for match in (content .. delimiter):gmatch("(.-)" .. delimiter) do
                table.insert(tempDumpTable, match);
            end
            local temp_dump_cs_table = {}
            if tempDumpTable[1]:find("/%*") then
                local current_namespace = "Global"
                local capturing_fields = false
                local capturing_enums = false
                local capturing_methods = false
                local capturing_properties = false
                for i, v in pairs(tempDumpTable) do
                    if v:find("^namespace .+") then
                        current_namespace = v:gsub("^namespace (.+)", "%1")
                    end
                    if v:find("	.+ class .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            class = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find(".+ class .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            class = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find("	.+ struct .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            struct = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find(".+ struct .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            struct = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find("	.+ enum .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        capturing_enums = true
                        table.insert(temp_dump_cs_table, {
                            enum = current_class,
                            namespace = current_namespace
                        })
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    elseif v:find(".+ enum .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        capturing_enums = true
                        table.insert(temp_dump_cs_table, {
                            enum = current_class,
                            namespace = current_namespace
                        })
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    end
                    if capturing_fields == true and (v:find("}") or v:find("// [A-Z]")) then
                        capturing_fields = false
                    end
                    if v:find("// Fields") then
                        capturing_fields = true
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    end
                    if capturing_methods == true and v:find("}") then
                        capturing_methods = false
                    end
                    if v:find("// Methods") then
                        capturing_methods = true
                        if not temp_dump_cs_table[#temp_dump_cs_table].methods then
                            temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        end
                    end
                    if capturing_enums == true and v:find("}") then
                        capturing_enums = false
                    end
                    if capturing_properties == true and v:find("// [A-Z]") then
                        capturing_properties = false
                    end
                    if v:find("// Properties") then
                        capturing_properties = true
                        if not temp_dump_cs_table[#temp_dump_cs_table].methods then
                            temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        end
                    end
                    if capturing_properties == true and v:find("CompilerGenerated") then
                        method_name_get = v:gsub("(.+ )(.+) {.+", "%1get_%2() { }")
                        method_type_get = v:gsub(".+ (.+) (.+ {).+", "%1"):gsub("[>?%[%]]", "")
                        method_offset_get = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+ .+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_get,
                            method_name = method_name_get,
                            method_type = method_type_get
                        })
                        method_name_set = v:gsub("(.+ )(.+) (.+) {.+", "%1void set_%3(%2 value) { }")
                        method_type_set = "void"
                        method_offset_set = v:gsub(".+} // (.+)", "%1"):gsub(".+-.+ (.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_set,
                            method_name = method_name_set,
                            method_type = method_type_set
                        })
                    elseif capturing_properties == true and v:find("{ get; }") then
                        method_name_get = v:gsub("(.+ )(.+) {.+", "%1get_%2() { }")
                        method_type_get = v:gsub(".+ (.+) (.+ {).+", "%1"):gsub("[>?%[%]]", "")
                        method_offset_get = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_get,
                            method_name = method_name_get,
                            method_type = method_type_get
                        })
                    elseif capturing_properties == true and v:find("{ set; }") then
                        method_name_set = v:gsub("(.+ )(.+) (.+) {.+", "%1void set_%3(%2 value) { }")
                        method_type_set = "void"
                        method_offset_set = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_set,
                            method_name = method_name_set,
                            method_type = method_type_set
                        })
                    end
                    if capturing_methods == true and v:find("%); // 0x") then
                        local method_offset = v:gsub(".+// (.+)-.+", "%1")
                        local method_name = v:gsub("(.+);.+", "%1"):gsub("	", "")
                        local method_type = ""
                        if method_name:find(" static ") or method_name:find(" override ") or
                            method_name:find(" internal ") or method_name:find(" virtual ") then
                            method_type = method_name:gsub(".+ .+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        else
                            method_type = method_name:gsub(".+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset,
                            method_name = method_name,
                            method_type = method_type
                        })
                    end
                    if capturing_enums == true and v:find("[A-Za-z0-9]+ =") then
                        local enum_value = v:gsub(".+ = (.+)", "%1"):gsub(",", "")
                        local enum_name = v:gsub("([A-Za-z]+) = .+", "%1"):gsub("	", "")
                        local enum_type = ""
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                            enum_type = enum_type,
                            enum_value = enum_value,
                            enum_name = enum_name
                        })
                    end
                    if capturing_fields == true and v:find("; // 0x") then
                        local field_type = ""
                        local field_offset = ""
                        local field_name = ""
                        if v:find(" static ") or v:find(" readonly ") then
                            field_type = v:gsub(".+ .+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                            field_offset = v:gsub(".+ .+ .+ .+; // (0x.+)", "%1")
                            field_name = v:gsub(".+ .+ .+ (.+); // 0x.+", "%1"):gsub("	", "")
                        else
                            field_type = v:gsub(".+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                            field_offset = v:gsub(".+ .+ .+; // (0x.+)", "%1")
                            field_name = v:gsub(".+ .+ (.+); // 0x.+", "%1"):gsub("	", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                            field_type = field_type,
                            field_offset = field_offset,
                            field_name = field_name
                        })
                    end
                end
            else
                for i, v in pairs(tempDumpTable) do
                    if v:find(" Namespace:") then
                        capturing = false
                        capturing_fields = false
                        capturing_methods = false
                        if tempDumpTable[i + 1]:find(".+ class .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                class = tempDumpTable[i + 1]
                            }
                        elseif tempDumpTable[i + 1]:find(".+ struct .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                struct = tempDumpTable[i + 1]
                            }
                        elseif tempDumpTable[i + 1]:find(".+ enum .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                enum = tempDumpTable[i + 1]
                            }
                        end
                    end
                    if capturing == true and v:find("// Methods") then
                        temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        capturing_methods = true
                        capturing_fields = false
                    end
                    if v:find("// Properties") then
                        capturing_fields = false
                    end
                    if capturing_fields == true then
                        if #v > 0 and v:find(" // 0x") and temp_dump_cs_table[#temp_dump_cs_table].class then
                            local field_type = ""
                            local field_offset = ""
                            local field_name = ""
                            if v:find(" static ") or v:find(" readonly ") then
                                field_type = v:gsub(".+ .+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                                field_offset = v:gsub(".+ .+ .+ .+; // (0x.+)", "%1")
                                field_name = v:gsub(".+ .+ .+ (.+); // 0x.+", "%1")
                            else
                                field_type = v:gsub(".+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                                field_offset = v:gsub(".+ .+ .+; // (0x.+)", "%1")
                                field_name = v:gsub(".+ .+ (.+); // 0x.+", "%1")
                            end
                            table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                                field_type = field_type,
                                field_offset = field_offset,
                                field_name = field_name
                            })
                        elseif #v > 0 and v:find(" %= ") and temp_dump_cs_table[#temp_dump_cs_table].enum then
                            local field_type = ""
                            local field_value = ""
                            local field_name = ""
                            field_type = v:gsub(".+ const (.+) .+ %= [%-0-9]+;", "%1"):gsub("[	*%[%]]", "")
                            field_value = v:gsub(".+ const .+ .+ %= ([%-0-9]+);", "%1")
                            field_name = v:gsub(".+ const .+ (.+) %= [%-0-9]+;", "%1")
                            table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                                enum_type = field_type,
                                enum_value = field_value,
                                enum_name = field_name
                            })
                        end
                    end
                    if capturing_methods == true and v:find("	// RVA:") and v:find(" VA: ") and v:find("MoveNext") ==
                        nil then
                        capturing_fields = false
                        local method_offset = tempDumpTable[i]:gsub(".+// RVA: (0x[A-Z0-9]+) Offset: .+", "%1")
                        local method_name = tempDumpTable[i + 1]:gsub("	", "")
                        local method_type = ""
                        if method_name:find(" static ") or method_name:find(" override ") or
                            method_name:find(" internal ") or method_name:find(" virtual ") then
                            method_type = method_name:gsub(".+ .+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]",
                                "")
                        else
                            method_type = method_name:gsub(".+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset,
                            method_name = method_name,
                            method_type = method_type
                        })
                    end
                    if capturing == true and tempDumpTable[i]:find("// Fields") then
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                        capturing_fields = true
                    end
                end
            end
            dump_cs_table = temp_dump_cs_table
        end
        save_dump = true
    end,
    --[[
	---------------------------------------
	
	dumpHandler.saveJSON()
	
	---------------------------------------
	]] --
    saveJSON = function()
        file = io.open(dataPath .. game_path .. "/processed_dump_" .. gg.getTargetInfo().versionName .. ".json", "w+")
        file:write(json.encode(dump_cs_table))
        file:close()
    end,
    --[[
	---------------------------------------
	
	dumpHandler.loadJSON()
	
	---------------------------------------
	]] --
    loadJSON = function()
        local file = assert(io.open(dataPath .. game_path .. "/processed_dump_" .. gg.getTargetInfo().versionName .. ".json", "r"))
        local content = file:read("*a")
        file:close()
        dump_cs_table = json.decode(content)
    end,
    --[[
	---------------------------------------
	
	dumpHandler.loadDumpData()
	
	---------------------------------------
	]] --
    loadDumpData = function()
        if #dump_cs_table == 0 then
            select_lib()
            if pcall(dumpHandler.loadJSON) == false then
                dumpHandler.createDirectory()
                dumpHandler.importDump()
            end
            local temp_types = {}
            for i, v in pairs(dump_cs_table) do
                if v.methods then
                    for index, value in pairs(v.methods) do
                        if not temp_types[value.method_type] then
                            temp_types[value.method_type] = value.method_type
                        end
                    end
                end
            end
            for k, v in pairs(temp_types) do
                table.insert(bc_toolbox_method_types_all, v)
                if v:find("[A-Z]") then
                else
                    table.insert(bc_toolbox_method_types, v)
                end
            end
        end
    end
}

pluginManager = {
    --[[
	---------------------------------------
	
	pluginManager.configMenu()
	
	---------------------------------------
	]] --
    configMenu = function()
        local menu = gg.choice({"↕️ Change Menu Order", 
								"🔢 Set Menu Item Limit",
                                "🔗 Configure Default Plugins", 
								"📥 Install Plugin", 
								"✏️ Rename Plugin",
                                "✅ Enable/Disable Plugins"}, 
								nil, 
								script_title .. "\n\nℹ️ Plugin Manager ℹ️")
        if menu ~= nil then
            if menu == 1 then
                pluginManager.menuOrder()
                pluginManager.configMenu()
            end
            if menu == 2 then
                pluginManager.menuLimit()
                pluginManager.configMenu()
            end
            if menu == 3 then
                pluginManager.defaultPlugins()
                pluginManager.configMenu()
            end
            if menu == 4 then
                pluginManager.installPlugin()
                pluginManager.configMenu()
            end
            if menu == 5 then
                pluginManager.renamePlugin()
                pluginManager.configMenu()
            end
            if menu == 6 then
                pluginManager.togglePlugins()
                pluginManager.configMenu()
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.callPlugin(plugin_path, function_table, passed_data)
	
	---------------------------------------
	]] --
    callPlugin = function(plugin_path, function_table, passed_data)
        if _G[function_table] then
            _G[function_table].home(passed_data)
        else
            dofile(plugin_path)
            if passed_data ~= nil then
                _G[function_table].home(passed_data)
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.defaultHandler(handler, passed_data)
	
	---------------------------------------
	]] --
    defaultHandler = function(handler, passed_data)
        for i, v in pairs(pluginManager.toolboxPlugins) do
            if v.default_handler == handler then
                pluginManager.callPlugin(v.plugin_path, v.function_table, passed_data)
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.initPluginManager()
	
	---------------------------------------
	]] --
    initPluginManager = function()
        local file = assert(io.open(configDataPath .. "plugin_manager.json", "r"))
        local content = file:read("*a")
        file:close()
        pluginManager.toolboxPlugins = json.decode(content)
        dofile(configDataPath .. "plugin_manager_config.lua")
    end,
    --[[
	---------------------------------------
	
	pluginManager.initAllPluginManager()
	
	---------------------------------------
	]] --
    initAllPluginManager = function()
        local file = assert(io.open(configDataPath .. "plugin_manager_all_plugins.json", "r"))
        local content = file:read("*a")
        file:close()
        pluginManager.toolboxAllPlugins = json.decode(content)
    end,
    --[[
	---------------------------------------
	
	pluginManager.menuOrder()
	
	---------------------------------------
	]] --
    menuOrder = function()
        if pcall(check_plugin_manager) == false then
            pluginManager.savePlugins()
        end
        local slider_range = ' [1; ' .. #pluginManager.toolboxPlugins .. ']'
        local sliders = {}
        local numbers = {}
        local menu = {}
        for i, v in pairs(pluginManager.toolboxPlugins) do
            sliders[i] = v.menu_name .. slider_range
            numbers[i] = "number"
            menu[i] = i
        end
        sliders[1] = script_title .. "\n\nℹ️ Set order of main menu items below. ℹ️\n\n" .. sliders[1]
        ::duplicate_index::
        menu = gg.prompt(sliders, menu, numbers)
        if menu ~= nil then
            local check_duplicate_indexes = {}
            for i, v in pairs(menu) do
                if check_duplicate_indexes[v] then
                    gg.alert(script_title .. "\n\nℹ️ Duplicate Indexes Found ℹ️")
                    goto duplicate_index
                else
                    check_duplicate_indexes[v] = v
                end
            end
            local temp_plugins = {}
            for i, v in pairs(menu) do
                temp_plugins[tonumber(v)] = pluginManager.toolboxPlugins[i]
            end
            pluginManager.toolboxPlugins = temp_plugins
            pluginManager.savePlugins()
            gg.toast(script_title .. "\n\nℹ️ Menu order set. ℹ️")
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.defaultPlugins()
	
	---------------------------------------
	]] --
    defaultPlugins = function()
        local handler_indexes = {
            method = "",
            field = "",
            enum = "",
            class = ""
        }
        local method_results_handler = "Method search result handler:\n"
        for i, v in pairs(pluginManager.toolboxPlugins) do
            if v.default_handler == "method_results" then
                handler_indexes.method = i
                method_results_handler = method_results_handler .. v.menu_name
            end
        end
        local field_results_handler = "Field search result handler:\n"
        for i, v in pairs(pluginManager.toolboxPlugins) do
            if v.default_handler == "field_results" then
                handler_indexes.field = i
                field_results_handler = field_results_handler .. v.menu_name
            end
        end
        local enum_results_handler = "Enum search result handler:\n"
        for i, v in pairs(pluginManager.toolboxPlugins) do
            if v.default_handler == "enum_results" then
                handler_indexes.enum = i
                enum_results_handler = enum_results_handler .. v.menu_name
            end
        end
        local class_results_handler = "Class/Field search result handler:\n"
        for i, v in pairs(pluginManager.toolboxPlugins) do
            if v.default_handler == "class_results" then
                handler_indexes.class = i
                class_results_handler = class_results_handler .. v.menu_name
            end
        end
        local handlerMenu = gg.choice({method_results_handler, 
										field_results_handler, 
										enum_results_handler,
                                        class_results_handler}, 
										nil,
										script_title .. "\n\nℹ️ Set default plugins. ℹ️")
        if handlerMenu ~= nil then
            local handler_types = {
                [1] = "method",
                [2] = "field",
                [3] = "enum",
                [4] = "class"
            }
            local handler_names = {
                [1] = "method_results",
                [2] = "field_results",
                [3] = "enum_results",
                [4] = "class_results"
            }
            local plugins_menu_items = {}
            for i, v in pairs(pluginManager.toolboxPlugins) do
                plugins_menu_items[i] = v.menu_name
            end
            local selectHandlerMenu = gg.choice(plugins_menu_items, nil,
                script_title .. "\n\nℹ️ Select default plugin ℹ️")
            if selectHandlerMenu ~= nil then
                pluginManager.toolboxPlugins[handler_indexes[handler_types[handlerMenu]]].default_handler = nil
                pluginManager.toolboxPlugins[selectHandlerMenu].default_handler = handler_names[handlerMenu]
                pluginManager.savePlugins()
                gg.toast(script_title .. "\n\nℹ️ Default plugin set. ℹ️")
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.installPlugin()
	
	---------------------------------------
	]] --
    installPlugin = function()
        local selectPluginLua = gg.prompt({script_title .. "\n\nℹ️ Select plugin to install. ℹ️"}, {gg.EXT_STORAGE .. "/Download/"}, {"file"})
        if selectPluginLua ~= nil and selectPluginLua ~= gg.EXT_STORAGE .. "/Download/" then
            pluginManager.installingPlugin = true
            dofile(selectPluginLua[1])
            pluginManager.installingPlugin = false
            local installMenu = gg.prompt({script_title .. "\n\nℹ️ Installing Plugin ℹ️\n\nMenu name for Plugin ", 
										  "Name of function table containing plugins home() menu."},
										  {
										  pluginManager.installingPluginName, 
										  pluginManager.installingPluginTable}, 
										  {
										  "text", 
										  "text"})
            if installMenu ~= nil then
                if #installMenu[1] > 0 and #installMenu[2] > 0 then
                    local filename = selectPluginLua[1]:gsub(".+/(.+)", "%1")
                    local allready_installed = false
                    for i, v in pairs(pluginManager.toolboxPlugins) do
                        if pluginsDataPath .. filename == v.plugin_path then
                            allready_installed = true
                        end
                    end
                    if allready_installed == true then
                        gg.alert(script_title .. "\n\nℹ️ A plugin with this filename is already installed try renaming the lua file first if you are sure it is a different plugin. ℹ️")
                        goto done
                    end
                    os.rename(selectPluginLua[1], pluginsDataPath .. filename)
                    local temp_plugin = {
                        function_table = installMenu[2],
                        menu_name = installMenu[1],
                        plugin_path = pluginsDataPath .. filename
                    }
                    table.insert(pluginManager.toolboxPlugins, temp_plugin)
                    pluginManager.savePlugins()
                    pluginManager.initAllPluginManager()
                    table.insert(pluginManager.toolboxAllPlugins, temp_plugin)
                    pluginManager.saveAllPlugins()
                    gg.toast(script_title .. "\n\nℹ️ Plugin has been installed. ℹ️")
                end
            end
        end
        ::done::
    end,
    --[[
	---------------------------------------
	
	pluginManager.removePlugin()
	
	---------------------------------------
	]] --
    removePlugin = function()
        local plugins_menu_items = {}
        for i, v in pairs(pluginManager.toolboxPlugins) do
            plugins_menu_items[i] = v.menu_name
        end
        local removePluginMenu = gg.choice(plugins_menu_items, nil,
            script_title .. "\n\nℹ️ Select plugin to uninstall. ℹ️")
        if removePluginMenu ~= nil then
            local confirmRemove = gg.choice({"✅ Yes", 
											 "❌ No"}, 
											 nil, 
											 script_title .. "\n\nℹ️ Remove the " .. plugins_menu_items[removePluginMenu] .. " plugin? ℹ️")
            if confirmRemove ~= nil then
                if confirmRemove == 1 then
                    table.remove(pluginManager.toolboxPlugins, removePluginMenu)
                    pluginManager.savePlugins()
                    gg.toast(script_title .. "\n\nℹ️ Plugin has been removed from the menu. ℹ️")
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.savePlugins()
	
	---------------------------------------
	]] --
    savePlugins = function()
        file = io.open(configDataPath .. "plugin_manager.json", "w+")
        file:write(json.encode(pluginManager.toolboxPlugins))
        file:close()
    end,
    --[[
	---------------------------------------
	
	pluginManager.saveAllPlugins()
	
	---------------------------------------
	]] --
    saveAllPlugins = function()
        file = io.open(configDataPath .. "plugin_manager_all_plugins.json", "w+")
        file:write(json.encode(pluginManager.toolboxAllPlugins))
        file:close()
    end,
    --[[
	---------------------------------------
	
	pluginManager.saveMenuLimit()
	
	---------------------------------------
	]] --
    saveMenuLimit = function()
        file = io.open(configDataPath .. "plugin_manager_config.lua", "w+")
        file:write("pluginManager.menuItemLimit = " .. pluginManager.menuItemLimit)
        file:close()
    end,
    --[[
	---------------------------------------
	
	pluginManager.renamePlugin()
	
	---------------------------------------
	]] --
    renamePlugin = function()
        local plugins_menu_items = {}
        for i, v in pairs(pluginManager.toolboxPlugins) do
            plugins_menu_items[i] = v.menu_name
        end
        local renamePluginMenu = gg.choice(plugins_menu_items, nil, script_title .. "\n\nℹ️ Select plugin to rename. ℹ️")
        if renamePluginMenu ~= nil then
            local renamePrompt = gg.prompt({script_title .. "\n\nℹ️ Enter a new menu name for the plugin. ℹ️"},
                {plugins_menu_items[renamePluginMenu]}, {"text"})
            if renamePrompt ~= nil then
                pluginManager.toolboxPlugins[renamePluginMenu].menu_name = renamePrompt[1]
                pluginManager.savePlugins()
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.menuLimit()
	
	---------------------------------------
	]] --
    menuLimit = function()
        local menu = gg.prompt({script_title .. "\n\nℹ️ Set limit for number of items per menu. ℹ️\n\nSet menu item limit [0; 20]"}, {pluginManager.menuItemLimit}, {'number'})
        if menu ~= nil then
            pluginManager.menuItemLimit = menu[1]
            pluginManager.saveMenuLimit()
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.togglePlugins()
	
	---------------------------------------
	]] --
    togglePlugins = function()
        if not pluginManager.toolboxAllPlugins then
            pluginManager.initAllPluginManager()
        end
        local menu_names = {}
        local menu_checkboxes = {}
        local menu_values = {}
        local menu_paths = {}
        for i, v in pairs(pluginManager.toolboxAllPlugins) do
            menu_names[i] = v.menu_name
            menu_checkboxes[i] = "checkbox"
            menu_values[i] = false
            menu_paths[i] = v.plugin_path
            for index, value in pairs(pluginManager.toolboxPlugins) do
                if v.plugin_path == value.plugin_path then
                    menu_values[i] = true
                end
            end
        end
        local menu = gg.prompt(menu_names, menu_values, menu_checkboxes)
        if menu ~= nil then
            for i, v in pairs(menu) do
                if v == true and menu_values[i] == false then
                    table.insert(pluginManager.toolboxPlugins, pluginManager.toolboxAllPlugins[i])
                    pluginManager.savePlugins()
                end
                if v == false and menu_values[i] == true then
                    for index, value in pairs(pluginManager.toolboxPlugins) do
                        if value.plugin_path == menu_paths[i] then
                            table.remove(pluginManager.toolboxPlugins, index)
                            pluginManager.savePlugins()
                        end
                    end
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	pluginManager.toolboxPlugins
	
	---------------------------------------
	]] --
    toolboxPlugins = {{
        function_table = "staticValueFinder",
        menu_name = "🕵️‍ Static Value Finder",
        plugin_path = pluginsDataPath .. "plugin_bc_static_value_finder.lua"
    }, {
        menu_name = "💾 Global-Metadata Dumper",
        plugin_path = pluginsDataPath .. "plugin_bc_metadata_dumper.lua"
    }, {
        menu_name = "💾 Lib Dumper",
        plugin_path = pluginsDataPath .. "plugin_bc_lib_dumper.lua"
    }, {
        menu_name = "🔎 Class Field Searcher",
        plugin_path = pluginsDataPath .. "plugin_bc_class_field_search.lua"
    }, {
        function_table = "dumpSearcher",
        menu_name = "🔍 Search Dump.cs",
        plugin_path = pluginsDataPath .. "plugin_bc_dump_search.lua"
    }, {
        function_table = "methodSearchResults",
        default_handler = "method_results",
        menu_name = "🗒️ Method Search Results",
        menu_count_table = "dumpSearcher.methodResults",
        plugin_path = pluginsDataPath .. "plugin_bc_method_search_results.lua"
    }, {
        function_table = "fieldSearchResults",
        default_handler = "field_results",
        menu_name = "🗒️ Field Search Results",
        menu_count_table = "dumpSearcher.fieldResults",
        plugin_path = pluginsDataPath .. "plugin_bc_field_search_results.lua"
    }, {
        function_table = "enumSearchResults",
        default_handler = "enum_results",
        menu_name = "🗒️ Enum Search Results",
        menu_count_table = "dumpSearcher.enumResults",
        plugin_path = pluginsDataPath .. "plugin_bc_enum_search_results.lua"
    }, {
        function_table = "il2cppFields",
        default_handler = "class_results",
        menu_name = "📝 BadCase's Il2Cpp Fields",
        plugin_path = pluginsDataPath .. "plugin_bc_il2cpp_fields.lua"
    }, {
        function_table = "il2cppEdits",
        menu_name = "📝 BadCase's Il2Cpp Edits by Name",
        plugin_path = pluginsDataPath .. "plugin_bc_il2cpp_edits.lua"
    }, {
        function_table = "scriptCreator",
        menu_name = "🏗️ Script Creator",
        plugin_path = pluginsDataPath .. "plugin_bc_script_creator.lua"
    }, {
        function_table = "saveListManager",
        menu_name = "📑 Save List Manager",
        plugin_path = pluginsDataPath .. "plugin_bc_save_list.lua"
    }},
    menuItemLimit = 0,
    returnHome = false,
    returnPluginTable = "",
    --[[
	---------------------------------------
	
	pluginManager.home(menu_number)
	
	---------------------------------------
	]] --
    home = function(menu_number)
        if pluginManager.returnHome == true then
            _G[pluginManager.returnPluginTable].home()
        elseif pluginManager.menuItemLimit == 0 then
            local menu_names = {}
            for i, v in pairs(pluginManager.toolboxPlugins) do
                menu_names[i] = v.menu_name
                if v.menu_count_table and _G[v.menu_count_table:gsub("(.+)%..+", "%1")] then
                    menu_names[i] = menu_names[i] .. " (" .. #_G[v.menu_count_table:gsub("(.+)%..+", "%1")][v.menu_count_table:gsub(".+%.(.+)", "%1")] .. ")"
                end
            end
            menu_names[#menu_names + 1] = "⚙️ Plugin Manager"
            menu_names[#menu_names + 1] = "❌ Exit"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                if menu == #menu_names then
                    os.exit()
                elseif menu == #menu_names - 1 then
                    pluginManager.configMenu()
                else
                    local status, retval = pcall(pluginManager.callPlugin,
                        pluginManager.toolboxPlugins[menu].plugin_path,
                        pluginManager.toolboxPlugins[menu].function_table);
                    if status == false then
                        local error_menu = gg.alert(retval, "OK", "Copy Error")
                        if error_menu ~= nil then
                            if error_menu == 2 then
                                gg.copyText(retval)
                            end
                        end
                    end
                end
            end
        else
            local current_menu = 1
            if menu_number ~= nil then
                current_menu = menu_number
            end
            local limit = current_menu - 1
            local menu_names = {}
            local total_plugins = #pluginManager.toolboxPlugins
            local menu_limit = pluginManager.menuItemLimit
            menu_count = total_plugins / menu_limit
            if total_plugins % menu_limit ~= 0 then
                menu_count = menu_count + 1
            end
            for i, v in pairs(pluginManager.toolboxPlugins) do
                if i <= pluginManager.menuItemLimit * current_menu and i > pluginManager.menuItemLimit * limit then
                    menu_names[#menu_names + 1] = v.menu_name
                    if v.menu_count_table and _G[v.menu_count_table:gsub("(.+)%..+", "%1")] then
                        menu_names[#menu_names] = menu_names[#menu_names] .. " (" .. #_G[v.menu_count_table:gsub("(.+)%..+", "%1")][v.menu_count_table:gsub(".+%.(.+)", "%1")] .. ")"
                    end
                end
                if #menu_names == pluginManager.menuItemLimit then
                    break
                end
            end
            if menu_count and current_menu == menu_count then
                menu_names[#menu_names + 1] = "🏠 Home Menu"
            elseif menu_count then
                menu_names[#menu_names + 1] = "⏭️ Next Menu"
            end
            menu_names[#menu_names + 1] = "⚙️ Plugin Manager"
            menu_names[#menu_names + 1] = "❌ Exit"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                local menuRange = pluginManager.menuItemLimit * limit
                if menu == #menu_names then
                    os.exit()
                elseif menu == #menu_names - 1 then
                    pluginManager.configMenu()
                elseif menu <= #menu_names - 3 then
                    if current_menu > 1 then
                        call_index = menu + pluginManager.menuItemLimit * limit
                    else
                        call_index = menu
                    end
                    local status, retval = pcall(pluginManager.callPlugin,
                        pluginManager.toolboxPlugins[call_index].plugin_path,
                        pluginManager.toolboxPlugins[call_index].function_table);
                    if status == false then
                        local error_menu = gg.alert(retval, "OK", "Copy Error")
                        if error_menu ~= nil then
                            if error_menu == 2 then
                                gg.copyText(retval)
                            end
                        end
                    end
                elseif menu >= #menu_names - 2 - menu_count and menu <= #menu_names - 2 then
                    if current_menu == menu_count then
                        pluginManager.home(1)
                    else
                        pluginManager.home(current_menu + 1)
                    end
                end
            end
        end
    end,
    whileLoop = {},
    doWhileLoop = function()
        for i, v in pairs(pluginManager.whileLoop) do
            local ms_to_sec = v.run_every / 1000
            if os.time() - v.last_run > ms_to_sec then
                _G[v.plugin_table][v.call_function]()
                v.last_run = os.time()
            end
        end
    end
}

if pcall(pluginManager.initPluginManager) == false then
    pluginManager.toolboxAllPlugins = pluginManager.toolboxPlugins
    pluginManager.saveAllPlugins()
    pluginManager.saveMenuLimit()
end
pluginManager.savePlugins()

pluginManager.home()

gg.showUiButton()

while true do
    pluginManager.doWhileLoop()
    if gg.isClickedUiButton() then
        pluginManager.home()
    end
    gg.sleep(100)
end
