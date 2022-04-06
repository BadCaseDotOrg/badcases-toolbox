libDumper = {
    --[[
	---------------------------------------
	
	libDumper.dumpFile()
	
	---------------------------------------
	]] --
    dumpFile = function(start_address, end_address)
        local start_address_fname = string.lower(string.sub(start_address, 3))
        local end_address_fname = string.lower(string.sub(end_address, 3))
        gg.dumpMemory(tonumber(start_address), tonumber(end_address),
            gg.EXT_STORAGE .. "/BC_DATA/" .. game_path .. "/dump/", gg.DUMP_SKIP_SYSTEM_LIBS)
        gg.alert(script_title .. "\n\nℹ️ Data Dumped ℹ️\n\nSaved to: " .. gg.EXT_STORAGE .. "/BC_DATA/" .. game_path .. "/dump/ ")
    end,
    --[[
	---------------------------------------
	
	libDumper.selectLib()
	
	---------------------------------------
	]] --
    selectLib = function()
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
									libDumper.hex_o(get_size_array[6]) .. "\nEnd Address: " ..
									libDumper.hex_o(get_size_array[1]) .. "\nSize: " .. size_display ..
									"\n〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️〰️"
                    else
                        menu_string = "━━━━━━━━━━━━\nName: " .. v["name"] .. "\nRange: " ..
                                    v.state .. "\nStart Address: " .. libDumper.hex_o(get_size_array[6]) ..
                                    "\nEnd Address: " .. libDumper.hex_o(get_size_array[1]) .. "\nSize: " ..
                                    size_display .. "\n━━━━━━━━━━━━"
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
        local h = gg.choice(lib_selector, nil, script_title .. "\n\nℹ️ Select Library To Dump ℹ️")
        if h == nil then
            goto end_select
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
        gg.toast(script_title .. "\n\n✅ " .. fixed_lib_name .. " Selected ✅")
        libDumper.dumpFile(BASEADDR, ENDADDR)
        ::end_select::
    end,
    hex_o = function(n)
        return "0x" .. string.upper(string.format("%x", n))
    end
}

libDumper.selectLib()
