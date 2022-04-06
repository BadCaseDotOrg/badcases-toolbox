metadataDumper = {
    --[[
	---------------------------------------
	
	metadataDumper.getVersion()
	
	---------------------------------------
	]] --
    getVersion = function()
        while (nil) do
            local getVersionVal = {}
            if (getVersionVal.getVersionVal) then
                getVersionVal.getVersionVal = (getVersionVal.getVersionVal(getVersionVal))
            end
        end
        gg.toast(script_title ..
                     "\n\nℹ️ Getting Unity Version ℹ️\n\nGetting Unity version for global-metadata.dat repair.")
        gg.setRanges(gg.REGION_CODE_APP)
        gg.clearResults()
        gg.searchNumber("32h;30h;0~~0;0~~0;2Eh;0~~0;2Eh;66h::11", gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 16)
        local version = gg.getResults(1, 8)
        local count = 1
        local offset = 0
        local version_table = {}
        repeat
            version_table[count] = {}
            version_table[count].address = version[1].address + offset
            version_table[count].flags = gg.TYPE_BYTE
            offset = offset + 1
            count = count + 1
        until (count == 5)
        local name_table = gg.getValues(version_table)
        local name_string = ""
        for i, v in pairs(name_table) do
            name_string = name_string .. string.char(v.value)
        end
        for i, v in pairs(metadataDumper.uv_a) do
            for index, value in pairs(v.versions) do
                if string.find(value, name_string) then
                    version_1 = v.headers[1]
                    version_2 = v.headers[2]
                end
            end
        end
        return {version_1, version_2}
    end,
    --[[
	---------------------------------------
	
	metadataDumper.getRanges()
	
	---------------------------------------
	]] --
    getRanges = function(address)
        local ranges = gg.getRangesList()
        for i, v in pairs(ranges) do
            if v.start <= address and v["end"] > address then
                range_start = v.start
                range_end = v["end"]
            end
        end
        return {range_start, range_end}
    end,
    --[[
	---------------------------------------
	
	metadataDumper.checkHeader()
	
	---------------------------------------
	]] --
    checkHeader = function(range_start)
        while (nil) do
            local checkHeaderVal = {}
            if (checkHeaderVal.checkHeaderVal) then
                checkHeaderVal.checkHeaderVal = (checkHeaderVal.checkHeaderVal(checkHeaderVal))
            end
        end
        gg.toast(script_title .. "\n\nℹ️ Checking Header ℹ️\n\nChecking for valid global-metadata.dat header.")
        local header_table = {}
        header_table[1] = {}
        header_table[1].address = range_start
        header_table[1].flags = gg.TYPE_BYTE
        header_table[2] = {}
        header_table[2].address = range_start + 1
        header_table[2].flags = gg.TYPE_BYTE
        header_table[3] = {}
        header_table[3].address = range_start + 2
        header_table[3].flags = gg.TYPE_BYTE
        header_table[4] = {}
        header_table[4].address = range_start + 3
        header_table[4].flags = gg.TYPE_BYTE
        header_table[5] = {}
        header_table[5].address = range_start + 4
        header_table[5].flags = gg.TYPE_DWORD
        header_table[6] = {}
        header_table[6].address = range_start + 8
        header_table[6].flags = gg.TYPE_DWORD
        header_values = gg.getValues(header_table)
        if header_values[1].value ~= -81 or header_values[1].value ~= 27 or header_values[1].value ~= -79 or
            header_values[1].value ~= -6 then
            header_values[1].value = "AFh"
            header_values[2].value = "1Bh"
            header_values[3].value = "B1h"
            header_values[4].value = "FAh"
            address_edit_table_1 = {
                [1] = {
                    ["address"] = header_table[1].address,
                    ["edit"] = "AFh",
                    ["type"] = gg.TYPE_BYTE
                },
                [2] = {
                    ["address"] = header_table[2].address,
                    ["edit"] = "1Bh",
                    ["type"] = gg.TYPE_BYTE
                },
                [3] = {
                    ["address"] = header_table[3].address,
                    ["edit"] = "B1h",
                    ["type"] = gg.TYPE_BYTE
                },
                [4] = {
                    ["address"] = header_table[4].address,
                    ["edit"] = "FAh",
                    ["type"] = gg.TYPE_BYTE
                }
            }
        end
        local header_values = gg.getValues(header_table)
        if header_values[5].value == 24 or header_values[5].value == 27 then
        else
            local version = metadataDumper.getVersion()
            header_values[5].value = version[1]
            header_values[6].value = version[2]
            address_edit_table_2 = {
                [1] = {
                    ["address"] = header_table[5].address,
                    ["edit"] = version[1],
                    ["type"] = gg.TYPE_DWORD
                },
                [2] = {
                    ["address"] = header_table[6].address,
                    ["edit"] = version[2],
                    ["type"] = gg.TYPE_DWORD
                }
            }
        end
        local header_values = gg.getValues(header_table)
        if header_values[6].value == 264 or header_values[6].value == 272 or header_values[6].value == 256 then
        else
            local version = metadataDumper.getVersion()
            header_values[5].value = version[1]
            header_values[6].value = version[2]
            address_edit_table_3 = {
                [1] = {
                    ["address"] = header_table[5].address,
                    ["edit"] = version[1],
                    ["type"] = gg.TYPE_DWORD
                },
                [2] = {
                    ["address"] = header_table[6].address,
                    ["edit"] = version[2],
                    ["type"] = gg.TYPE_DWORD
                }
            }
        end
        if address_edit_table_1 then
            address_edit_table = address_edit_table_1
            metadataDumper.writeValues()
        end
        if address_edit_table_2 then
            address_edit_table = address_edit_table_2
            metadataDumper.writeValues()
        end
        if address_edit_table_3 then
            address_edit_table = address_edit_table_3
            metadataDumper.writeValues()
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.methodOne()
	
	---------------------------------------
	]] --
    methodOne = function()
        while (nil) do
            local methodOneVal = {}
            if (methodOneVal.methodOneVal) then
                methodOneVal.methodOneVal = (methodOneVal.methodOneVal(methodOneVal))
            end
        end
        gg.toast(script_title .. "\n\nℹ️ Running search method 1 for global-metadata.dat ℹ️")
        gg.clearResults()
        gg.searchNumber("AFh;1Bh;B1h;FAh::5", gg.TYPE_BYTE, false, nil, nil, nil, 1)
        local meta_start = gg.getResults(1)
        if gg.getResultsCount() == 0 then
            metadataDumper.methodTwo()
        else
            metadataDumper.gm_dumped = true
            gg.clearResults()
            range_data = metadataDumper.getRanges(meta_start[1].address)
            metadataDumper.dumpMeta(meta_start[1].address, range_data[2])
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.methodTwo()
	
	---------------------------------------
	]] --
    methodTwo = function()
        while (nil) do
            local methodTwoVal = {}
            if (methodTwoVal.methodTwoVal) then
                methodTwoVal.methodTwoVal = (methodTwoVal.methodTwoVal(methodTwoVal))
            end
        end
        gg.toast(script_title .. "\n\nℹ️ Running search method 2 for global-metadata.dat ℹ️")
        gg.clearResults()
        gg.searchNumber("0~24;256~272::5", gg.TYPE_DWORD)
        gg.refineNumber("24", gg.TYPE_DWORD)
        local rtable = gg.getResults(gg.getResultsCount())
        gg.clearResults()
        results = {}
        for i, v in pairs(rtable) do
            local start_address = v.address
            local current_address = v.address
            local end_address = start_address + 44
            local value_table = {}
            local tindex = 1
            repeat
                value_table[tindex] = {}
                value_table[tindex].address = current_address
                value_table[tindex].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                tindex = tindex + 1
            until (current_address == end_address)
            value_table = gg.getValues(value_table)
            if value_table[3].value > value_table[2].value and 
				value_table[4].value > value_table[3].value and
                value_table[5].value > value_table[4].value and 
				value_table[6].value > value_table[5].value and
                value_table[7].value > value_table[6].value and 
				value_table[8].value > value_table[7].value and
                value_table[9].value < value_table[8].value and 
				value_table[10].value > value_table[9].value then
                table.insert(results, start_address)
            end
        end
        if #results == 1 then
            metadataDumper.gm_dumped = true
            local meta_start = results[1] - 4
            range_data = metadataDumper.getRanges(meta_start)
            metadataDumper.checkHeader(meta_start)
            metadataDumper.dumpMeta(meta_start, range_data[2])
        else
            metadataDumper.methodThree()
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.methodThree()
	
	---------------------------------------
	]] --
    methodThree = function()
        while (nil) do
            local methodThreeVal = {}
            if (methodThreeVal.methodThreeVal) then
                methodThreeVal.methodThreeVal = (methodThreeVal.methodThreeVal(methodThreeVal))
            end
        end
        gg.toast(script_title .. "\n\nℹ️ Running search method 3 for global-metadata.dat ℹ️")
        gg.clearResults()
        gg.searchNumber("27h;28h;29h;2Ch;2Dh;2Eh;2Fh::7", gg.TYPE_BYTE, false, nil, nil, nil, 1)
        local sm1 = gg.getResults(1)
        if gg.getResultsCount() == 0 then
            gg.alert(script_title .. "\n\nℹ️ No results ℹ️\n\nTry other methods if you have not already.")
        else
            metadataDumper.gm_dumped = true
            gg.clearResults()
            range_data = metadataDumper.getRanges(sm1[1].address)
            true_start = metadataDumper.getMetaStart(range_data[1])
            metadataDumper.checkHeader(true_start)
            metadataDumper.dumpMeta(true_start, range_data[2])
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.getMetaStart()
	
	---------------------------------------
	]] --
    getMetaStart = function(range_start)
        while (nil) do
            local getMetaStartVal = {}
            if (getMetaStartVal.getMetaStartVal) then
                getMetaStartVal.getMetaStartVal = (getMetaStartVal.getMetaStartVal(getMetaStartVal))
            end
        end
        repeat
            start_address = range_start
            current_address = range_start
            end_address = start_address + 44
            value_table = {}
            tindex = 1
            repeat
                value_table[tindex] = {}
                value_table[tindex].address = current_address
                value_table[tindex].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                tindex = tindex + 1
            until (current_address == end_address)
            value_table = gg.getValues(value_table)
            if value_table[5].value > value_table[4].value and 
				value_table[4].value > 0 and 
				value_table[5].value > 0 and
                value_table[6].value > value_table[5].value and 
				value_table[5].value > 0 and 
				value_table[6].value > 0 then
                meta_found = true
                return metadataDumper.hex_o(range_start)
            else
                range_start = range_start + 0x10000
            end
        until (meta_found == true)
    end,
    hex_o = function(n)
        return "0x" .. string.upper(string.format("%x", n))
    end,
    hexnx = function(n)
        return string.format("%X", n)
    end,
    --[[
	---------------------------------------
	
	metadataDumper.dumpMeta()
	
	---------------------------------------
	]] --
    dumpMeta = function(range_start, range_end)
        while (nil) do
            local dumpMetaVal = {}
            if (dumpMetaVal.dumpMetaVal) then
                dumpMetaVal.dumpMetaVal = (dumpMetaVal.dumpMetaVal(dumpMetaVal))
            end
        end
        gg.dumpMemory(metadataDumper.hex_o(range_start), metadataDumper.hex_o(range_end),
            dataPath .. game_path .. "/dump/", gg.DUMP_SKIP_SYSTEM_LIBS)
        local file = io.open(dataPath .. game_path .. "/dump/" .. gg.getTargetPackage() .. "-" .. metadataDumper.hexnx(range_start) .. "-" .. metadataDumper.hexnx(range_end) .. ".bin", "r")
        if file == nil then
            ::choose_file::
            gg.alert(script_title .. "\n\nℹ️ Additional Data Dumped ℹ️\n\nThe file may need to be trimmed, select the most recent bin file in the default directory.")
            local bin_filename = gg.prompt({script_title .. "\n\nℹ️ Select Newest .bin File ℹ️"}, {
                [1] = dataPath .. game_path .. "/dump/"
            }, {
                [1] = "file"
            })
            if bin_filename == nil then
                goto choose_file
            end
            if string.find(bin_filename[1], "%.bin") then
                local file = assert(io.open(bin_filename[1], "r"))
                local content = file:read("*a")
                file:close()
                if string.find(content, "^\xAF\x1B\xB1\xFA") then
                    trimmed_content = content
                else
                    trimmed_content = string.gsub(content, ".+(\xAF\x1B\xB1\xFA.+)", "%1")
                end
                local file = io.open(dataPath .. game_path .. "/dump/global-metadata.dat", "w+")
                file:write(trimmed_content)
                file:close()
                local file = io.open(dataPath .. game_path .. "/dump/global-metadata dump address.txt", "w+")
                file:write(metadataDumper.hexnx(range_start))
                file:close()
            end
            gg.alert(script_title .. "\n\nℹ️ File Trimmed ℹ️\n\nSaved to: " .. dataPath .. game_path .. "/dump/global-metadata.dat ")
        else
            local meta_content = file:read("*a")
            file:close()
            local file = io.open(dataPath .. game_path .. "/dump/global-metadata.dat", "w+")
            file:write(meta_content)
            file:close()
            local file = io.open(dataPath .. game_path .. "/dump/global-metadata dump address.txt", "w+")
            file:write(metadataDumper.hexnx(range_start))
            file:close()
            metadataDumper.overwriteValues()
            gg.alert(script_title .. "\n\nℹ️ Data Dumped ℹ️\n\nSaved to: " .. dataPath .. game_path .. "/dump/global-metadata.dat ")
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.getWriteLocation()
	
	---------------------------------------
	]] --
    getWriteLocation = function()
        while (nil) do
            local getWriteLocationVal = {}
            if (getWriteLocationVal.getWriteLocationVal) then
                getWriteLocationVal.getWriteLocationVal = (getWriteLocationVal.getWriteLocationVal(getWriteLocationVal))
            end
        end
        if write_location == nil then
            write_location = range_data[2] - 16
        end
        return write_location
    end,
    overwriteValues = function()
        local wl = metadataDumper.getWriteLocation()
        address_edit_table = {
            [1] = {
                ["address"] = wl,
                ["edit"] = 0,
                ["type"] = gg.TYPE_DWORD
            },
            [2] = {
                ["address"] = wl + 4,
                ["edit"] = 0,
                ["type"] = gg.TYPE_DWORD
            },
            [3] = {
                ["address"] = wl + 8,
                ["edit"] = 0,
                ["type"] = gg.TYPE_DWORD
            }
        }
        metadataDumper.writeValues()
    end,
    --[[
	---------------------------------------
	
	metadataDumper.writeValues()
	
	---------------------------------------
	]] --
    writeValues = function()
        while (nil) do
            local writeValuesVal = {}
            if (writeValuesVal.writeValuesVal) then
                writeValuesVal.writeValuesVal = (writeValuesVal.writeValuesVal(writeValuesVal))
            end
        end
        local wl = metadataDumper.getWriteLocation()
        local temp_table = {}
        if #address_edit_table == 4 then
            temp_table[1] = {}
            temp_table[1].address = wl
            temp_table[1].flags = address_edit_table[1].type
            temp_table[1].value = address_edit_table[1].edit
            temp_table[2] = {}
            temp_table[2].address = wl + 1
            temp_table[2].flags = address_edit_table[2].type
            temp_table[2].value = address_edit_table[2].edit
            temp_table[3] = {}
            temp_table[3].address = wl + 2
            temp_table[3].flags = address_edit_table[3].type
            temp_table[3].value = address_edit_table[3].edit
            temp_table[4] = {}
            temp_table[4].address = wl + 3
            temp_table[4].flags = address_edit_table[4].type
            temp_table[4].value = address_edit_table[4].edit
            gg.setValues(temp_table)
            gg.copyMemory(wl, address_edit_table[1]["address"], 4)
            temp_table[1].value = 0
            temp_table[2].value = 0
            temp_table[3].value = 0
            temp_table[4].value = 0
            gg.setValues(temp_table)
            gg.setValues(temp_table)
        end
        if #address_edit_table == 2 then
            temp_table[1] = {}
            temp_table[1].address = wl + 4
            temp_table[1].flags = address_edit_table[1].type
            temp_table[1].value = address_edit_table[1].edit
            temp_table[2] = {}
            temp_table[2].address = wl + 8
            temp_table[2].flags = address_edit_table[2].type
            temp_table[2].value = address_edit_table[2].edit
            gg.setValues(temp_table)
            gg.copyMemory(metadataDumper.getWriteLocation() + 4, address_edit_table[1].address, 8)
            temp_table[1].value = 0
            temp_table[2].value = 0
            gg.setValues(temp_table)
            gg.setValues(temp_table)
        end
        if #address_edit_table == 3 then
            temp_table[1] = {}
            temp_table[1].address = wl + 4
            temp_table[1].flags = address_edit_table[1].type
            temp_table[1].value = address_edit_table[1].edit
            temp_table[2] = {}
            temp_table[2].address = wl + 8
            temp_table[2].flags = address_edit_table[2].type
            temp_table[2].value = address_edit_table[2].edit
            temp_table[3] = {}
            temp_table[3].address = wl + 12
            temp_table[3].flags = address_edit_table[2].type
            temp_table[3].value = address_edit_table[2].edit
            gg.setValues(temp_table)
            gg.copyMemory(metadataDumper.getWriteLocation() + 4, address_edit_table[1].address, 12)
            gg.setValues(temp_table)
        end
    end,
    --[[
	---------------------------------------
	
	metadataDumper.dumpGlobalMetadata()
	
	---------------------------------------
	]] --
    dumpGlobalMetadata = function()
        while (nil) do
            local dumpGlobalMetadataVal = {}
            if (dumpGlobalMetadataVal.dumpGlobalMetadataVal) then
                dumpGlobalMetadataVal.dumpGlobalMetadataVal = (dumpGlobalMetadataVal.dumpGlobalMetadataVal(dumpGlobalMetadataVal))
            end
        end
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_DATA | gg.REGION_C_BSS | gg.REGION_OTHER)
        metadataDumper.methodOne()
        if metadataDumper.gm_dumped == false then
            metadataDumper.methodTwo()
        end
        if metadataDumper.gm_dumped == false then
            metadataDumper.methodThree()
        end
    end,
    uv_a = {{
        ["versions"] = {"2017", "2018"},
        ["headers"] = {"24", "272"}
    }, {
        ["versions"] = {"2019"},
        ["headers"] = {"24", "264"}
    }, {
        ["versions"] = {"2020"},
        ["headers"] = {"27", "256"}
    }},
    gm_dumped = false
}
target_package = gg.getTargetPackage()
metadataDumper.dumpGlobalMetadata()
