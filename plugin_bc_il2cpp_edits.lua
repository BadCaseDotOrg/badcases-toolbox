il2cppEdits = {
    --[[
	---------------------------------------
	
	il2cppEdits.createDirectory()
	
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
        gg.dumpMemory(create_start, create_end, il2cppEdits.savePath, gg.DUMP_SKIP_SYSTEM_LIBS)
    end,
    savePath = pluginsDataPath .. "badcase_il2cpp_edits_data/",
    ------------------------------------------------------------
    -- Global Variables--
    ------------------------------------------------------------
    clocks = {
        [1] = '🕦',
        [2] = '🕚',
        [3] = '🕥',
        [4] = '🕙',
        [5] = '🕤',
        [6] = '🕘',
        [7] = '🕣',
        [8] = '🕗',
        [9] = '🕢',
        [10] = '🕖',
        [11] = '🕡',
        [12] = '🕕',
        [13] = '🕠',
        [14] = '🕔',
        [15] = '🕟',
        [16] = '🕓',
        [17] = '🕞',
        [18] = '🕒',
        [19] = '🕝',
        [20] = '🕑',
        [21] = '🕜',
        [22] = '🕐',
        [23] = '🕧',
        [24] = '🕛'
    },
    --[[
	---------------------------------------
	
	il2cppEdits.tickClock()
	
	---------------------------------------
	]] --
    tickClock = function()
        local clock_string = ""
        local clocks_to_show = 10
        local clock_count = 0
        repeat
            clock_string = clock_string .. il2cppEdits.clocks[1]
            clock_count = clock_count + 1
        until (clock_count == clocks_to_show)
        table.insert(il2cppEdits.clocks, 1, il2cppEdits.clocks[#il2cppEdits.clocks])
        table.remove(il2cppEdits.clocks, #il2cppEdits.clocks)
        gg.toast(clock_string)
    end,
    stringsStart = "109;115;99;111;114;108;105;98;46;100;108;108;77;111;100;117;108;101::20",
    stringsEnd = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12",
    revert_table = {},
    create_revert_table = {},
    create_edit_table = {},
    parsed_strings_table = {},
    started = false,
    --[[
	---------------------------------------
	
	il2cppEdits.bc_cpp_check_cfg_file()
	
	---------------------------------------
	]] --
    bc_cpp_check_cfg_file = function()
        rerun = false
        if pcall(il2cppEdits.bc_cpp_check_cfg_file_game) == false then
            il2cppEdits.createDirectory()
            local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. ".cfg", "w+")
            local data_string = "il2cppEdits.savedEditsTable = {}"
            file:write(data_string)
            file:close()
            rerun = true
        end
        if rerun == true then
            il2cppEdits.bc_cpp_check_cfg_file()
        end
    end,
    bc_cpp_check_cfg_file_game = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. ".cfg")
    end,
    -----------------------------------------------------------------
    -- Get Global Metadata String Start/End--
    -----------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.getRange()
	
	---------------------------------------
	]] --
    getRange = function() -- get_strings_start_end
        gg.setRanges(gg.REGION_OTHER)
        gg.setVisible(false)
        gg.toast(script_title .. "\n\nℹ️ Configuring Script ℹ️")
        gg.clearResults()
        ::try_ca::
        gg.searchNumber(il2cppEdits.stringsStart, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)
        if gg.getResultsCount() == 0 then
            gg.setRanges(gg.REGION_C_ALLOC)
            goto try_ca
        end
        local start_search = gg.getResults(1)
        gg.clearResults()
        range_start = start_search[1].address
        for i, v in pairs(gg.getRangesList()) do
            if v["start"] < range_start and v["end"] > range_start then
                metadata_end = v["end"]
                break
            end
        end
        gg.searchNumber(il2cppEdits.stringsEnd, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, nil, 1)
        local end_search = gg.getResults(1)
        range_end = end_search[1].address
        gg.clearResults()
    end,
    ------------------------------------------------------------
    -- Search Functions--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.createSearch(search_string)
	
	---------------------------------------
	]] --
    createSearch = function(search_string)
        byte_search = "0;"
        for c in search_string:gmatch "." do
            if #search_string > 1 then
                byte_search = byte_search .. string.byte(c) .. ";"
            else
                byte_search = byte_search .. string.byte(c)
            end
        end
        if il2cppEdits.started == false then
            byte_search = byte_search .. "0"
            il2cppEdits.started = true
        end
        if #search_string > 1 then
            byte_search = byte_search .. "::" .. #search_string + 2
        end
        return byte_search
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.refineResults(search_string)
	
	---------------------------------------
	]] --
    refineResults = function(search_string)
        local first_search_string = "0;" .. string.byte(string.sub(search_string, 1, 1)) .. "::2"
        gg.refineNumber(first_search_string, gg.TYPE_BYTE)
        local second_search_string = string.byte(string.sub(search_string, 1, 1))
        gg.refineNumber(second_search_string, gg.TYPE_BYTE)
        local search_results = gg.getResults(gg.getResultsCount())
        return search_results[1].address
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.searchDump(search_string)
	
	---------------------------------------
	]] --
    searchDump = function(search_string)
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        if search_string then
            gg.clearResults()
            gg.searchNumber(il2cppEdits.createSearch(search_string), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start,
                range_end)
            if gg.getResultsCount() > 0 then
                return il2cppEdits.refineResults(search_string)
            end
        end
    end,
    ------------------------------------------------------------
    -- Get All Methods And Classnames--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.saveDataBase()
	
	---------------------------------------
	]] --
    saveDataBase = function()
        local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_db.lua", "w+")
        file:write("il2cppEdits.parsed_strings_table = " .. tostring(il2cppEdits.parsed_strings_table))
        file:close()
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.saveMethodTypes()
	
	---------------------------------------
	]] --
    saveMethodTypes = function()
        local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua", "w+")
        file:write("il2cppEdits.method_types = " .. tostring(il2cppEdits.method_types))
        file:close()
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.getMethods(method_name, get_first)
	
	---------------------------------------
	]] --
    getMethods = function(method_name, get_first)
        while (nil) do
            local getMethodsVal = {}
            if (getMethodsVal.getMethodsVal) then
                getMethodsVal.getMethodsVal = (getMethodsVal.getMethodsVal(getMethodsVal))
            end
        end
        if il2cppEdits.arch.x64 then
            p_offset = 16
            p_offset2 = 8
            flag_type = gg.TYPE_QWORD
        else
            p_offset = 8
            p_offset2 = 4
            flag_type = gg.TYPE_DWORD
        end
        if method_name then
            local cfound = false
            method_name_address = il2cppEdits.searchDump(method_name)
            gg.clearResults()
            gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_HEAP)
            if get_first == true and method_name_address ~= nil then
                gg.searchNumber(method_name_address, flag_type, nil, nil, nil, nil, 1)
            elseif method_name_address ~= nil then
                gg.searchNumber(method_name_address, flag_type)
            end
            local results = gg.getResults(gg.getResultsCount())
            local methods_found = {}
            for i, v in pairs(results) do
                local get_class_pointer_1 = {}
                get_class_pointer_1[1] = {}
                get_class_pointer_1[1].address = v.address + p_offset2
                get_class_pointer_1[1].flags = flag_type
                get_class_pointer_1 = gg.getValues(get_class_pointer_1)
                local get_class_pointer_2 = {}
                get_class_pointer_2[1] = {}
                get_class_pointer_2[1].address = get_class_pointer_1[1].value + p_offset
                get_class_pointer_2[1].flags = flag_type
                get_class_pointer_2 = gg.getValues(get_class_pointer_2)
                local get_class_start = {}
                get_class_start[1] = {}
                get_class_start[1].address = get_class_pointer_2[1].value
                get_class_start[1].flags = gg.TYPE_BYTE
                gg.loadResults(get_class_start)
                get_class_start = gg.getValues(get_class_start)
                local get_class = {}
                local offset = 0
                local count = 1
                repeat
                    get_class[count] = {}
                    get_class[count].address = get_class_pointer_2[1].value + offset
                    get_class[count].flags = gg.TYPE_BYTE
                    count = count + 1
                    offset = offset + 1
                until (count == 100)
                get_class = gg.getValues(get_class)
                local class_name = ""
                for index, value in pairs(get_class) do
                    if value.value >= 0 and value.value <= 255 then
                        class_name = class_name .. string.char(value.value)
                    end
                    if value.value == 0 then
                        break
                    end
                end
                if string.find(class_name, " ") or 
					string.find(class_name, "") or 
					string.find(class_name, "") or
                    string.find(class_name, "\r\n") or 
					string.find(class_name, "\r") or 
					string.find(class_name, "\n") or
                    string.find(class_name, "") or 
					string.find(class_name, '"') then
                    class_name = ""
                end
                if #class_name > 1 then
                    cfound = true
                end
                local get_il2cpp_address = {}
                get_il2cpp_address[1] = {}
                get_il2cpp_address[1].address = v.address - p_offset
                get_il2cpp_address[1].flags = flag_type
                get_il2cpp_address = gg.getValues(get_il2cpp_address)
                il2cpp_address = get_il2cpp_address[1].value
                local get_method_type_1 = {}
                get_method_type_1[1] = {}
                get_method_type_1[1].address = v.address + p_offset
                get_method_type_1[1].flags = flag_type
                get_method_type_1 = gg.getValues(get_method_type_1)
                local get_method_type_2 = {}
                get_method_type_2[1] = {}
                get_method_type_2[1].address = get_method_type_1[1].value
                get_method_type_2[1].flags = flag_type
                get_method_type_2 = gg.getValues(get_method_type_2)
                local method_type = get_method_type_2[1].value
                if #tostring(method_type) > 8 then
                    get_method_type_2 = {}
                    get_method_type_2[1] = {}
                    get_method_type_2[1].address = get_method_type_1[1].value + 4
                    get_method_type_2[1].flags = flag_type
                    get_method_type_2 = gg.getValues(get_method_type_2)
                    method_type = get_method_type_2[1].value
                end
                if il2cppEdits.method_types[tostring(method_type)] then
                    method_type = il2cppEdits.method_types[tostring(method_type)]
                end
                if method_type == 0 then
                    cfound = false
                end
                methods_found[#methods_found + 1] = {}
                methods_found[#methods_found].class_name = class_name
                methods_found[#methods_found].method_name = method_name
                methods_found[#methods_found].il2cpp_address = il2cpp_address
                methods_found[#methods_found].method_type = method_type
                if not get_first then
                    il2cppEdits.setDumpMethod(method_name, method_type, class_name)
                end
            end
            if not get_first then
                il2cppEdits.saveDataBase()
            end
            ::not_found::
            if cfound == true then
                gg.toast(script_title .. "\n\nℹ️ " .. #methods_found .. " method(s) found for the string " .. method_name .. " ℹ️")
                return methods_found
            else
                ::not_found::
                gg.toast(script_title .. "\n\nℹ️ No Results ℹ️\nNo methods were found for that string, it has been removed from the database.")
                il2cppEdits.removeFromDataBase(method_name)
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.setDumpMethod(method_name, method_type, class_name)
	
	---------------------------------------
	]] --
    setDumpMethod = function(method_name, method_type, class_name)
        for i, v in pairs(il2cppEdits.parsed_strings_table) do
            if v.il2cpp_string == method_name then
                il2cppEdits.parsed_strings_table[i].method_type = method_type
                if il2cppEdits.parsed_strings_table[i].class_names then
                    local found = false
                    for index, value in pairs(il2cppEdits.parsed_strings_table[i].class_names) do
                        if value == class_name then
                            found = true
                        end
                    end
                    if found == false then
                        il2cppEdits.parsed_strings_table[i].class_names[#il2cppEdits.parsed_strings_table[i].class_names + 1] = class_name
                    end
                else
                    il2cppEdits.parsed_strings_table[i].class_names = {}
                    il2cppEdits.parsed_strings_table[i].class_names[#il2cppEdits.parsed_strings_table[i].class_names + 1] = class_name
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.getBoolEdit()
	
	---------------------------------------
	]] --
    getBoolEdit = function()
        local arm7Edit = {
            isTrue = {"~A MOV R0, #1", "~A BX LR"},
            isFalse = {"~A MOV R0, #0", "~A BX LR"}
        }
        local arm8Edit = {
            isTrue = {"~A8 MOV W0, #1", "~A8 RET"},
            isFalse = {"~A8 MOV W0, WZR", "~A8 RET"}
        }
        local menu = gg.choice({"True", "False"})
        if menu ~= nil then
            if menu == 1 then
                return {arm7Edit.isTrue, arm8Edit.isTrue}
            end
            if menu == 2 then
                return {arm7Edit.isFalse, arm8Edit.isFalse}
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.getIntEdit()
	
	---------------------------------------
	]] --
    getIntEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        ::set_val::
        local menu = gg.prompt({"enter number -255 to 65535 "}, {nil}, {"number"})
        if menu ~= nil then
            if tonumber(menu[1]) < -256 or tonumber(menu[1]) > 65535 then
                gg.alert("ℹ️ Set A Valid Number ℹ️\n\nSet a valid number from -255 to 65535")
                goto set_val
            end
            if tonumber(menu[1]) == 0 then
                edits_arm8[1] = "~A8 MOV W0, WZR"
            else
                edits_arm8[1] = "~A8 MOV W0, #" .. menu[1]
            end
            edits_arm8[2] = "~A8 RET"
            if string.find(menu[1], "[-]") then
                edits_arm7[1] = "~A MVN R0, #" .. string.gsub(menu[1], "[-]", "")
                edits_arm7[2] = "~A BX LR"
            else
                edits_arm7[1] = "~A MOVW R0, #" .. menu[1]
                edits_arm7[2] = "~A BX LR"
            end
            return {edits_arm7, edits_arm8}
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.getComplexFloatEdit(target, method_type)
	
	---------------------------------------
	]] --
    getComplexFloatEdit = function(target, method_type)
        while (nil) do
            local getComplexFloatEditVal = {}
            if (getComplexFloatEditVal.getComplexFloatEditVal) then
                getComplexFloatEditVal.getComplexFloatEditVal = (getComplexFloatEditVal.getComplexFloatEditVal(getComplexFloatEditVal))
            end
        end
        target = tonumber(target)
        local float_edits_arm7 = {}
        local float_edits_arm8 = {}
        if target <= 65535 and target >= 0 then
            if method_type == "float" then
                float_edits_arm7[1] = "~A MOVW R0, #" .. target
                float_edits_arm7[2] = "100A00EEr" -- VMOV S0, R0
                float_edits_arm7[3] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                float_edits_arm7[4] = "100A10EEr" -- VMOV R0, S0
                float_edits_arm7[5] = "1EFF2FE1r" -- BX LR
                if target == 0 then
                    float_edits_arm8[1] = "~A8 MOV W0, WZR"
                else
                    float_edits_arm8[1] = "~A8 MOV W0, #" .. target
                end
                float_edits_arm8[2] = "0000271Er" -- FMOV S0, W0
                float_edits_arm8[3] = "00D8215Er" -- SCVTF S0, S0
                float_edits_arm8[4] = "0000261Er" -- FMOV W0, S0
                float_edits_arm8[5] = "C0035FD6r" -- RET
            elseif method_type == "double" then
                float_edits_arm7[1] = "~A MOVW R0, #" .. target
                float_edits_arm7[2] = "~A VMOV S0, R0"
                float_edits_arm7[3] = "~A VCVT.F64.U32 D0, S0"
                float_edits_arm7[4] = "~A VMOV R0, R1, D0"
                float_edits_arm7[5] = "1EFF2FE1r" -- BX LR
                if target == 0 then
                    float_edits_arm8[1] = "~A8 MOV W0, WZR"
                else
                    float_edits_arm8[1] = "~A8 MOV W0, #" .. target
                end
                float_edits_arm8[2] = "~A8 SCVTF D0, W0"
                float_edits_arm8[3] = "C0035FD6r" -- RET
            end
        end
        if target <= 131072 and target >= 65537 then
            float_val_2 = target - 65535
            if method_type == "float" then
                float_edits_arm7[1] = "~A MOVW R0, #65535"
                float_edits_arm7[2] = "~A MOVW R1, #" .. float_val_2
                float_edits_arm7[3] = "010080E0r" -- ADD R0, R0, R1
                float_edits_arm7[4] = "100A00EEr" -- VMOV S0, R0
                float_edits_arm7[5] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                float_edits_arm7[6] = "100A10EEr" -- VMOV R0, S0
                float_edits_arm7[7] = "1EFF2FE1r" -- BX LR
                float_edits_arm8[1] = "~A8 MOV W0, #65535"
                float_edits_arm8[2] = "~A8 MOV W1, #" .. float_val_2
                float_edits_arm8[3] = "0000010Br" -- ADD W0, W0, W1
                float_edits_arm8[4] = "0000271Er" -- FMOV S0, W0
                float_edits_arm8[5] = "00D8215Er" -- SCVTF S0, S0
                float_edits_arm8[6] = "0000261Er" -- FMOV W0, S0
                float_edits_arm8[7] = "C0035FD6r" -- RET
            elseif method_type == "double" then
                float_edits_arm7[1] = "~A MOVW R0, #65535"
                float_edits_arm7[2] = "~A MOVW R1,  #" .. float_val_2
                float_edits_arm7[3] = "~A ADD R0, R0, R1"
                float_edits_arm7[4] = "~A VMOV S0, R0"
                float_edits_arm7[5] = "~A VCVT.F64.U32 D0, S0"
                float_edits_arm7[6] = "~A VMOV R0, R1, D0"
                float_edits_arm7[7] = "1EFF2FE1r" -- BX LR
                float_edits_arm8[1] = "~A8 MOV W0, #65535"
                float_edits_arm8[2] = "~A8 MOV W1,  #" .. float_val_2
                float_edits_arm8[3] = "~A8 ADD W0, W0, W1"
                float_edits_arm8[4] = "~A8 SCVTF D0, W0"
                float_edits_arm8[5] = "C0035FD6r" -- RET
            end
        end
        if target > 131072 and target < 429503284 then
            for i = 2, 65536 do
                rem = target % i
                mult = i
                sub_total = rem * mult
                add_to = target - sub_total
                if add_to <= 65536 and add_to > 0 then
                    if method_type == "float" then
                        float_edits_arm7[1] = "~A MOVW R0, #" .. rem
                        float_edits_arm7[2] = "~A MOVW R1, #" .. mult
                        float_edits_arm7[3] = "900100E0r" -- MUL R0, R0, R1
                        float_edits_arm7[4] = "~A MOVW R1, #" .. add_to
                        float_edits_arm7[5] = "010080E0r" -- ADD R0, R0, R1
                        float_edits_arm7[6] = "100A00EEr" -- VMOV S0, R0
                        float_edits_arm7[7] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                        float_edits_arm7[8] = "100A10EEr" -- VMOV R0, S0
                        float_edits_arm7[9] = "1EFF2FE1r" -- BX LR
                        float_edits_arm8[1] = "~A8 MOV W0, #" .. rem
                        float_edits_arm8[2] = "~A8 MOV W1, #" .. mult
                        float_edits_arm8[3] = "007C011Br" -- MUL W0, W0, W1
                        float_edits_arm8[4] = "~A8 MOV W1, #" .. add_to
                        float_edits_arm8[5] = "0000010Br" -- ADD W0, W0, W1
                        float_edits_arm8[6] = "0000271Er" -- FMOV S0, W0
                        float_edits_arm8[7] = "00D8215Er" -- SCVTF S0, S0
                        float_edits_arm8[8] = "0000261Er" -- FMOV W0, S0
                        float_edits_arm8[9] = "C0035FD6r" -- RET
                    elseif method_type == "double" then
                        float_edits_arm7[1] = "~A MOVW R0, #" .. rem
                        float_edits_arm7[2] = "~A MOVW R1,  #" .. mult
                        float_edits_arm7[3] = "~A MUL R0, R0, R1"
                        float_edits_arm7[4] = "~A MOVW R1,  #" .. add_to
                        float_edits_arm7[5] = "~A ADD R1, R0, R1"
                        float_edits_arm7[6] = "~A VMOV S0, R0"
                        float_edits_arm7[7] = "~A VCVT.F64.U32 D0, S0"
                        float_edits_arm7[8] = "~A VMOV R0, R1, D0"
                        float_edits_arm7[9] = "1EFF2FE1r" -- BX LR
                        float_edits_arm8[1] = "~A8 MOV W0, #" .. rem
                        float_edits_arm8[2] = "~A8 MOV W1,  #" .. mult
                        float_edits_arm8[3] = "~A8 MUL W0, W0, W1"
                        float_edits_arm8[4] = "~A8 MOV W1,  #" .. add_to
                        float_edits_arm8[5] = "~A8 ADD W0, W0, W1"
                        float_edits_arm8[6] = "~A8 SCVTF D0, W0"
                        float_edits_arm8[7] = "C0035FD6r" -- RET
                    end
                    break
                end
            end
            if target > 429503283 then
                gg.alert("⚠️ Value is too high, set lower than 429503283 ⚠️")
            end
            if target < 0 then
                gg.alert("⚠️ Value is too low, set to 0 or higher ⚠️")
            end
        end
        if float_edits_arm7 and float_edits_arm8 then
            return {float_edits_arm7, float_edits_arm8}
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.simpleFloatsTable
	
	---------------------------------------
	]] --
    simpleFloatsTable = {
        ["ARM7"] = {{
            ["hex_edits"] = "0101A0E3r",
            ["float_value"] = 2
        }, {
            ["hex_edits"] = "4104A0E3r",
            ["float_value"] = 8
        }, {
            ["hex_edits"] = "4204A0E3r",
            ["float_value"] = 32
        }, {
            ["hex_edits"] = "4304A0E3r",
            ["float_value"] = 128
        }, {
            ["hex_edits"] = "1103A0E3r",
            ["float_value"] = 512
        }, {
            ["hex_edits"] = "4504A0E3r",
            ["float_value"] = 2048
        }, {
            ["hex_edits"] = "4604A0E3r",
            ["float_value"] = 8192
        }, {
            ["hex_edits"] = "4704A0E3r",
            ["float_value"] = 32768
        }, {
            ["hex_edits"] = "1203A0E3r",
            ["float_value"] = 131072
        }, {
            ["hex_edits"] = "4904A0E3r",
            ["float_value"] = 524288
        }, {
            ["hex_edits"] = "0502A0E3r",
            ["float_value"] = 8589934592
        }, {
            ["hex_edits"] = "5104A0E3r",
            ["float_value"] = 34359738368
        }, {
            ["hex_edits"] = "5204A0E3r",
            ["float_value"] = 137438953472
        }, {
            ["hex_edits"] = "5304A0E3r",
            ["float_value"] = 549755813888
        }, {
            ["hex_edits"] = "1503A0E3r",
            ["float_value"] = 2199023255552
        }, {
            ["hex_edits"] = "5504A0E3r",
            ["float_value"] = 8796093022208
        }, {
            ["hex_edits"] = "5604A0E3r",
            ["float_value"] = 35184372088832
        }, {
            ["hex_edits"] = "5704A0E3r",
            ["float_value"] = 140737488355328
        }, {
            ["hex_edits"] = "1603A0E3r",
            ["float_value"] = 562949953421312
        }, {
            ["hex_edits"] = "5904A0E3r",
            ["float_value"] = 2251799813685248
        }, {
            ["hex_edits"] = "0602A0E3r",
            ["float_value"] = 36893488147419103000
        }},
        ["ARM8"] = {{
            ["hex_edits"] = "0000A852r",
            ["float_value"] = 2
        }, {
            ["hex_edits"] = "0020A852r",
            ["float_value"] = 8
        }, {
            ["hex_edits"] = "0040A852r",
            ["float_value"] = 32
        }, {
            ["hex_edits"] = "0060A852r",
            ["float_value"] = 128
        }, {
            ["hex_edits"] = "0080A852r",
            ["float_value"] = 512
        }, {
            ["hex_edits"] = "00A0A852r",
            ["float_value"] = 2048
        }, {
            ["hex_edits"] = "00C0A852r",
            ["float_value"] = 8192
        }, {
            ["hex_edits"] = "00E0A852r",
            ["float_value"] = 32768
        }, {
            ["hex_edits"] = "0000A952r",
            ["float_value"] = 131072
        }, {
            ["hex_edits"] = "0020A952r",
            ["float_value"] = 524288
        }, {
            ["hex_edits"] = "0000AA52r",
            ["float_value"] = 8589934592
        }, {
            ["hex_edits"] = "0020AA52r",
            ["float_value"] = 34359738368
        }, {
            ["hex_edits"] = "0040AA52r",
            ["float_value"] = 137438953472
        }, {
            ["hex_edits"] = "0060AA52r",
            ["float_value"] = 549755813888
        }, {
            ["hex_edits"] = "0080AA52r",
            ["float_value"] = 2199023255552
        }, {
            ["hex_edits"] = "00A0AA52r",
            ["float_value"] = 8796093022208
        }, {
            ["hex_edits"] = "00C0AA52r",
            ["float_value"] = 35184372088832
        }, {
            ["hex_edits"] = "00E0AA52r",
            ["float_value"] = 140737488355328
        }, {
            ["hex_edits"] = "0000AB52r",
            ["float_value"] = 562949953421312
        }, {
            ["hex_edits"] = "0020AB52r",
            ["float_value"] = 2251799813685248
        }, {
            ["hex_edits"] = "0000AC52r",
            ["float_value"] = 36893488147419103000
        }}
    },
    --[[
	---------------------------------------
	
	il2cppEdits.getSimpleFloatEdit()
	
	---------------------------------------
	]] --
    getSimpleFloatEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        local menu_table = {}
        for i, v in pairs(il2cppEdits.simpleFloatsTable["ARM7"]) do
            menu_table[#menu_table + 1] = v.float_value
        end
        local menu = gg.choice(menu_table, nil, "ℹ️ Select Float Value ℹ️")
        if menu ~= nil then
            edits_arm7[1] = il2cppEdits.simpleFloatsTable["ARM7"][menu].hex_edits
            edits_arm7[2] = "~A BX LR"
            edits_arm8[1] = il2cppEdits.simpleFloatsTable["ARM8"][menu].hex_edits
            edits_arm8[2] = "~A8 RET"
            return {edits_arm7, edits_arm8}
        end
    end,
    ------------------------------------------------------------
    -- Create Edit--
    ------------------------------------------------------------
    last_search = "",
    last_search_2 = "",
    case_sensitive = true,
    all_terms = true,
    --[[
	---------------------------------------
	
	il2cppEdits.createEdit()
	
	---------------------------------------
	]] --
    createEdit = function(method_name, dbsearch, search_term_2)
        while (nil) do
            local createEditVal = {}
            if (createEditVal.createEditVal) then
                createEditVal.createEditVal = (createEditVal.createEditVal(createEditVal))
            end
        end
        if not case_s then
            case_s = il2cppEdits.case_sensitive
        end
        if not all_t then
            all_t = il2cppEdits.all_terms
        end
        if not dbsearch then
            dbsearch = false
        end
        if not search_term_2 then
            search_term_2 = il2cppEdits.last_search_2
        end
        if not method_name then
            method_name = il2cppEdits.last_search
        end
        local menu = gg.prompt({script_title .. "\n\nℹ️ Enter a method name. ℹ️\nFor \"public bool get_IsUnlocked() { }\" you would enter \"get_IsUnlocked\"",
                                "Search For String Instead", 
								"Case Sensitive", 
								"Must Include All Search Strings",
                                "Secondary Search String"}, 
								{
								method_name, 
								dbsearch, 
								case_s, 
								all_t, 
								search_term_2},
								{
								"text", 
								"checkbox", 
								"checkbox", 
								"checkbox", 
								"text"})
        if menu ~= nil then
            il2cppEdits.last_search = menu[1]
            if menu[2] == true then
                local search_term_1 = menu[1]
                local search_term_2 = menu[5]
                case_s = menu[3]
                all_t = menu[4]
                menu[1] = il2cppEdits.searchDataBase(search_term_1, search_term_2, case_s, all_t)
            end
            local methods = il2cppEdits.getMethods(menu[1])
            if methods ~= nil then
                local methods_menu_items = {}
                for i, v in pairs(methods) do
                    methods_menu_items[#methods_menu_items + 1] = "〰️〰️〰️〰️〰️〰️〰️〰️\nClass Name: " .. v.class_name .. "\nMethod Name: " .. v.method_name .. "\nMethod Type: " .. v.method_type .. "\n〰️〰️〰️〰️〰️〰️〰️〰️"
                end
                local methods_menu = gg.choice(methods_menu_items, nil,
                    script_title .. "\n\nℹ️ Select method to edit. ℹ️")
                if methods_menu ~= nil then
                    local class_name = methods[methods_menu].class_name
                    local method_name = methods[methods_menu].method_name
                    local il2cpp_address = methods[methods_menu].il2cpp_address
                    il2cppEdits.create_edit_table = {
                        class_name = class_name,
                        method_name = method_name
                    }
                    ::select_edit_type::
                    local menu_type = {"bool", "int", "float", "double"}
                    local edit_type = gg.choice(menu_type, nil,
                        script_title .. "\n\nℹ️ Select type of edit to load. ℹ️")
                    if edit_type ~= nil then
                        if edit_type == 1 then
                            edits = il2cppEdits.getBoolEdit()
                        end
                        if edit_type == 2 then
                            edits = il2cppEdits.getIntEdit()
                        end
                        if edit_type == 3 then
                            local space_limit = il2cppEdits.getValues(il2cpp_address)
                            if #space_limit[1] >= 9 then
                                max_value = 429503284
                            elseif #space_limit[1] >= 7 then
                                max_value = 131072
                            elseif #space_limit[1] >= 5 then
                                max_value = 65535
                            else
                                max_value = 0
                            end
                            if max_value > 0 then
                                ::set_value::
                                local set_val = gg.prompt({"Set float value (Max " .. max_value .. ")"}, nil, {"number"})
                                if set_val ~= nil and tonumber(set_val[1]) <= max_value then
                                    edits = il2cppEdits.getComplexFloatEdit(set_val[1], "float")
                                elseif set_val ~= nil and tonumber(set_val[1]) > max_value then
                                    gg.alert("value too high")
                                    goto set_value
                                end
                            else
                                edits = il2cppEdits.getSimpleFloatEdit()
                            end
                        end
                        if edit_type == 4 then
                            local space_limit = il2cppEdits.getValues(il2cpp_address)
                            if #space_limit[1] >= 9 then
                                max_value = 429503284
                            elseif #space_limit[1] >= 7 then
                                max_value = 131072
                            elseif #space_limit[1] >= 5 then
                                max_value = 65535
                            end
                            if max_value > 0 then
                                ::set_value::
                                local set_val = gg.prompt({"Set double value (Max " .. max_value .. ")"}, nil, {"number"})
                                if set_val ~= nil and tonumber(set_val[1]) <= max_value then
                                    edits = il2cppEdits.getComplexFloatEdit(set_val[1], "double")
                                elseif set_val ~= nil and tonumber(set_val[1]) > max_value then
                                    gg.alert("value too high")
                                    goto set_value
                                end
                            else
                                gg.alert("not enough room for double edit")
                            end
                        end
                    end
                    if not edits then
                        goto select_edit_type
                    end
                    making_edit = true
                    ::enter_name::
                    local name_menu = gg.prompt({script_title .. "\n\nℹ️ Enter name for edit. ℹ️"}, {method_name}, {"text"})
                    if name_menu == nil then
                        goto enter_name
                    end
                    il2cppEdits.savedEditsTable[#il2cppEdits.savedEditsTable + 1] = {
                        edit_name = name_menu[1],
                        class_name = class_name,
                        method_name = method_name,
                        arm7_edits = edits[1],
                        arm8_edits = edits[2]
                    }
                    if il2cppEdits.arch.x64 then
                        il2cppEdits.createSetValues(il2cpp_address, edits[2])
                    else
                        il2cppEdits.createSetValues(il2cpp_address, edits[1])
                    end
                    gg.alert(script_title .. "\n\nℹ️ Value has been set. ℹ️ \nTest to verify it is working and then press the floating GG button to either Save or Discard edit.")
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.removeFromDataBase()
	
	---------------------------------------
	]] --
    removeFromDataBase = function(string_name)
        for i, v in pairs(il2cppEdits.parsed_strings_table) do
            if v.il2cpp_string == string_name then
                table.remove(il2cppEdits.parsed_strings_table, i)
                break
            end
        end
    end,
    ------------------------------------------------------------
    -- Set Values For Creating Function--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.createSetValues(address, edits)
	
	---------------------------------------
	]] --
    createSetValues = function(address, edits)
        local address_table = {}
        local offset = 0
        local count = 1
        repeat
            address_table[count] = {}
            address_table[count].address = address + offset
            address_table[count].flags = gg.TYPE_DWORD
            address_table[count].value = edits[count]
            offset = offset + 4
            count = count + 1
        until (count == #edits + 1)
        il2cppEdits.create_revert_table = gg.getValues(address_table)
        il2cppEdits.revert_table[#il2cppEdits.savedEditsTable] = gg.getValues(address_table)
        gg.setValues(address_table)
    end,
    ------------------------------------------------------------
    -- Get Current Values From Memory--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.getValues(address)
	
	---------------------------------------
	]] --
    getValues = function(address)
        local lib_edit_table = {}
        local offset = 0x0
        local count = 1
        repeat
            lib_edit_table[count] = {}
            lib_edit_table[count].address = address + offset
            lib_edit_table[count].flags = flag_type
            offset = offset + 0x4
            count = count + 1
        until (count == 21)
        local values = gg.getValues(lib_edit_table)
        local edits_table = {}
        local edit_notes_table = {}
        for i, v in pairs(values) do
            edit_notes_table[#edit_notes_table + 1] = ""
            if il2cppEdits.arch.x64 then
                edits_table[#edits_table + 1] = "~A8 " .. gg.disasm(gg.ASM_ARM64, v.address, v.value)
                if edits_table[#edits_table]:find("RET") then
                    break
                end
            else
                edits_table[#edits_table + 1] = "~A " .. gg.disasm(gg.ASM_ARM, v.address, v.value)
                if edits_table[#edits_table]:find("BX") then
                    break
                end
            end
        end
        return {edits_table, edit_notes_table}
    end,
    ----------------------------------------------------------------
    -- Find Method For Enabling Saved Edit--
    ----------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.findMethod(method_name, passed_class_name)
	
	---------------------------------------
	]] --
    findMethod = function(method_name, passed_class_name)
        while (nil) do
            local findMethodVal = {}
            if (findMethodVal.findMethodVal) then
                findMethodVal.findMethodVal = (findMethodVal.findMethodVal(findMethodVal))
            end
        end
        if il2cppEdits.arch.x64 then
            p_offset = 16
            p_offset2 = 8
            flag_type = gg.TYPE_QWORD
        else
            p_offset = 8
            p_offset2 = 4
            flag_type = gg.TYPE_DWORD
        end
        method_name_address = il2cppEdits.searchDump(method_name)
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_HEAP)
        gg.searchNumber(method_name_address, flag_type)
        local results = gg.getResults(gg.getResultsCount())
        local methods_found = {}
        for i, v in pairs(results) do
            local get_class_pointer_1 = {}
            get_class_pointer_1[1] = {}
            get_class_pointer_1[1].address = v.address + p_offset2
            get_class_pointer_1[1].flags = flag_type
            get_class_pointer_1 = gg.getValues(get_class_pointer_1)
            local get_class_pointer_2 = {}
            get_class_pointer_2[1] = {}
            get_class_pointer_2[1].address = get_class_pointer_1[1].value + p_offset
            get_class_pointer_2[1].flags = flag_type
            get_class_pointer_2 = gg.getValues(get_class_pointer_2)
            local get_class_start = {}
            get_class_start[1] = {}
            get_class_start[1].address = get_class_pointer_2[1].value
            get_class_start[1].flags = gg.TYPE_BYTE
            gg.loadResults(get_class_start)
            get_class_start = gg.getValues(get_class_start)
            local get_class = {}
            local offset = 0
            local count = 1
            repeat
                get_class[count] = {}
                get_class[count].address = get_class_pointer_2[1].value + offset
                get_class[count].flags = gg.TYPE_BYTE
                count = count + 1
                offset = offset + 1
            until (count == 100)
            get_class = gg.getValues(get_class)
            local class_name = ""
            for index, value in pairs(get_class) do
                class_name = class_name .. string.char(value.value)
                if value.value == 0 then
                    break
                end
            end
            if class_name == passed_class_name then
                local get_il2cpp_address = {}
                get_il2cpp_address[1] = {}
                get_il2cpp_address[1].address = v.address - p_offset
                get_il2cpp_address[1].flags = flag_type
                get_il2cpp_address = gg.getValues(get_il2cpp_address)
                il2cpp_address = get_il2cpp_address[1].value
            end
        end
        return il2cpp_address
    end,
    ------------------------------------------------------------
    -- Set Values For Saved Edit--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.setValues(index)
	
	---------------------------------------
	]] --
    setValues = function(index)
        if il2cppEdits.revert_table[index] then
            gg.setValues(il2cppEdits.revert_table[index])
            il2cppEdits.revert_table[index] = nil
            gg.toast("❌ " .. il2cppEdits.savedEditsTable[index].edit_name .. " Disabled ❌")
        else
            if il2cppEdits.arch.x64 then
                edits_arch = "arm8_edits"
            else
                edits_arch = "arm7_edits"
            end
            local method_name = il2cppEdits.savedEditsTable[index].method_name
            local class_name = il2cppEdits.savedEditsTable[index].class_name
            local address = il2cppEdits.findMethod(method_name, class_name)
            local edits = il2cppEdits.savedEditsTable[index][edits_arch]
            local address_table = {}
            local offset = 0
            local count = 1
            repeat
                address_table[count] = {}
                address_table[count].address = address + offset
                address_table[count].flags = gg.TYPE_DWORD
                address_table[count].value = edits[count]
                offset = offset + 4
                count = count + 1
            until (count == #edits + 1)
            il2cppEdits.revert_table[index] = gg.getValues(address_table)
            gg.setValues(address_table)
            gg.toast("✅ " .. il2cppEdits.savedEditsTable[index].edit_name .. " Enabled ✅")

        end
    end,
    ------------------------------------------------------------
    -- Save Edit--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.saveConfig()
	
	---------------------------------------
	]] --
    saveConfig = function()
        local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. ".cfg", "w+")
        file:write("il2cppEdits.savedEditsTable = " .. tostring(il2cppEdits.savedEditsTable))
        file:close()
    end,
    ------------------------------------------------------------
    -- Delete Edits--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.deleteEdit()
	
	---------------------------------------
	]] --
    deleteEdit = function()
        local menu_names = {}
        for i, v in pairs(il2cppEdits.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local menu = gg.multiChoice(menu_names, nil, "Select edits to delete")
        if menu ~= nil then
            local confirm = gg.choice({"✅ Yes delete the edits", "❌ No"}, nil, script_title .. "\n\nℹ️ Are you sure? ℹ\nAre you sure you want to delete these edits,  this can not be undone? ")
            if confirm ~= nil then
                if confirm == 1 then
                    for k, v in pairs(il2cppEdits.savedEditsTable) do
                        for key, value in pairs(menu) do
                            if k == key then
                                il2cppEdits.savedEditsTable[k] = "delete"
                            end
                        end
                    end
                    ::get_next::
                    local count = 1
                    local do_until = #il2cppEdits.savedEditsTable + 1
                    for i, v in pairs(il2cppEdits.savedEditsTable) do
                        count = count + 1
                        if type(v) == "string" then
                            table.remove(il2cppEdits.savedEditsTable, i)
                            break
                        end
                    end
                    if count < do_until then
                        goto get_next
                    end
                    il2cppEdits.saveConfig()
                    gg.toast("✅ Edits Deleted ✅")
                end
            end
        end
    end,
    ------------------------------------------------------------
    -- Export Edits--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.exportEdits()
	
	---------------------------------------
	]] --
    exportEdits = function()
        local menu_names = {}
        for i, v in pairs(il2cppEdits.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local to_export = {}
        local menu = gg.multiChoice(menu_names, nil, script_title .. "\n\nℹ️ Select edits to export. ℹ️")
        if menu ~= nil then
            for k, v in pairs(menu) do
                to_export[#to_export + 1] = il2cppEdits.savedEditsTable[k]
            end
            local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. os.date() .. "_export.json", "w+")
            if file == nil then
                file =
                    io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. os.time() .. "_export.json", "w+")
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. os.time() .. "_export.json")
            else
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. os.date() .. "_export.json")
            end
            file:write(json.encode(to_export))
            file:close()
        end
    end,
    ------------------------------------------------------------
    -- Import Edits--
    ------------------------------------------------------------
    --[[
	---------------------------------------
	
	il2cppEdits.importEdits()
	
	---------------------------------------
	]] --
    importEdits = function()
        local menu = gg.prompt({script_title .. "\n\nℹ️ Select JSON ℹ️"}, {
            [1] = il2cppEdits.savePath
        }, {
            [1] = "file"
        })
        if menu == nil then
        end
        if menu ~= nil and string.find(menu[1], "%.json") then
            local file = assert(io.open(menu[1], "r"))
            local content = file:read("*a")
            file:close()
            local import_table = json.decode(content)
            for i, v in pairs(import_table) do
                il2cppEdits.savedEditsTable[#il2cppEdits.savedEditsTable + 1] = v
            end
            il2cppEdits.saveConfig()
            gg.toast("✅ Edits Imported ✅")
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.createSearchDataBase()
	
	---------------------------------------
	]] --
    createSearchDataBase = function()
        string_address = range_start
        current_string_address = string_address
        stop_at = range_end - range_start
        max_proc = 100000
        ::next_batch::
        local strings_table = {}
        string_count = 1
        repeat
            strings_table[string_count] = {}
            strings_table[string_count].address = string_address
            strings_table[string_count].flags = gg.TYPE_BYTE
            string_count = string_count + 1
            string_address = string_address + 1
        until (string_address == range_start + max_proc or string_address == stop_at)
        strings_table = gg.getValues(strings_table)
        current_string = ""
        for i, v in pairs(strings_table) do
            if v.value == 0 then
                if #current_string > 2 and current_string:find("[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]") then
                    if string.find(current_string, " ") or 
						string.find(current_string, "") or
                        string.find(current_string, "") or 
						string.find(current_string, "\r\n") or
                        string.find(current_string, "\r") or 
						string.find(current_string, "\n") or
                        string.find(current_string, "") or 
						string.find(current_string, '"') then
                    else
                        il2cppEdits.parsed_strings_table[#il2cppEdits.parsed_strings_table + 1] = {
                            il2cpp_string = current_string
                        }
                    end
                end
                current_string_address = v.address + 1
                current_string = ""
            else
                if v.value >= 0 and v.value <= 255 then
                    current_string = current_string .. string.char(v.value)
                end
            end
        end
        if range_end - range_start > max_proc then
            il2cppEdits.tickClock()
            max_proc = max_proc + 100000
            goto next_batch
        end
        local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_db.lua", "w+")
        file:write("il2cppEdits.parsed_strings_table = " .. tostring(il2cppEdits.parsed_strings_table))
        file:close()
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.searchDataBase(search_term_1, search_term_2, case_s, all_t)
	
	---------------------------------------
	]] --
    searchDataBase = function(search_term_1, search_term_2, case_s, all_t)
        if #il2cppEdits.parsed_strings_table == 0 then
            gg.alert(script_title .. "\n\nℹ️ Wait while the search database is created. ℹ️")
            il2cppEdits.createSearchDataBase()
        end
        if method_types_ran ~= true then
            gg.toast(script_title .. "\n\nℹ️ Getting Method Types ℹ️")
            il2cppEdits.getMethodTypes()
        end
        local search_results = {}
        local search_results_menu = {}
        for i, v in pairs(il2cppEdits.parsed_strings_table) do
            if (case_s == false and all_t == true and
                string.find(string.lower(v.il2cpp_string), string.lower(search_term_1)) and
                string.find(string.lower(v.il2cpp_string), string.lower(search_term_2))) or
                (case_s == true and all_t == true and string.find(v.il2cpp_string, search_term_1) and
                    string.find(v.il2cpp_string, search_term_2)) or
                (case_s == false and all_t == false and
                    (string.find(string.lower(v.il2cpp_string), string.lower(search_term_1)) or
                        string.find(string.lower(v.il2cpp_string), string.lower(search_term_2)))) or
                (case_s == true and all_t == false and
                    (string.find(v.il2cpp_string, search_term_1) or string.find(v.il2cpp_string, search_term_2))) then
                local menu_string = ""
                if v.class_names then
                    menu_string = menu_string .. "ℹ ️Class Names: "
                    for index, value in pairs(v.class_names) do
                        menu_string = menu_string .. value .. ", "
                    end
                    menu_string = menu_string .. "\n"
                end
                if v.method_type and v.class_names then
                    menu_string = menu_string .. "ℹ️ Method Name: " .. v.il2cpp_string .. "\n"
                else
                    menu_string = menu_string .. "❓ " .. v.il2cpp_string .. " ❓\n"
                end
                if v.method_type then
                    menu_string = menu_string .. "ℹ️ Method Type: " .. v.method_type .. "\n"
                end
                search_results[#search_results + 1] = v.il2cpp_string
                search_results_menu[#search_results_menu + 1] = menu_string
            end
        end
        search_results_menu[#search_results_menu + 1] = "Process all search results"
        local menu = gg.choice(search_results_menu, nil,
            script_title .. "\n\nℹ️ Select a string to find methods for. ℹ️")
        if menu == #search_results_menu then
            local confirm = gg.choice({"✅ Yes", "❌ No"}, nil, script_title ..
                "\n\nℹ️ Confirm Process All ℹ️\nThis can take a long time with a large number of results. Are you sure you want to continue?")
            if confirm == 1 then
                for index, value in pairs(search_results) do
                    il2cppEdits.getMethods(value)
                end
                gg.alert(script_title .. "\n\nℹ️ Done Processing All ℹ️")
                il2cppEdits.case_sensitive = case_s
                il2cppEdits.all_terms = all_t
                il2cppEdits.createEdit(search_term_1, true, search_term_2)
            end
        else
            return search_results[menu]
        end
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.about()
	
	---------------------------------------
	]] --
    about = function()
        gg.alert(script_title .. [[


ℹ️ About Script ℹ️

This script allows users to create Il2Cpp edits by method name, this means no offsets are needed. As long as method names are not changed in the game the edits will continue working even after a game updates.

➕ Create Edit
Here you will enter a known method name or search for a method name and create an edit for it. Edits you create for a game are added to the main menu above this menu item.

⤴️ Import Edits
Here you can import edits created and exported by other users of this script.
 
⤵️ Export Edits
Here you can export edits you have created to share them with other users of the script.

🗑️ Delete Edit
Here you can delete edits for a game and remove them from the main menu.
]])
    end,
    check_db = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_db.lua")
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.home(passed_data)
	
	---------------------------------------
	]] --
    home = function(passed_data)
        pluginManager.returnHome = true
        pluginManager.returnPluginTable = "il2cppEdits"
        if passed_data then
            il2cppEdits.createEdit(passed_data)
        elseif making_edit == true then
            local menu = gg.choice({"✅ Save Edit", "🗑️ Discard Edit"}, nil, script_title .. "\n\nℹ️ Save or Discard edit. ℹ️")
            if menu ~= nil then
                if menu == 1 then
                    il2cppEdits.saveConfig()
                    making_edit = false
                    gg.toast("✅ Edit saved ✅")
                end
                if menu == 2 then
                    gg.setValues(il2cppEdits.create_revert_table)
                    table.remove(il2cppEdits.savedEditsTable, #il2cppEdits.savedEditsTable)
                    making_edit = false
                    gg.toast("🗑️ Edit discarded 🗑️")
                end
                il2cppEdits.home()
            end
        else
            local menu_names = {}
            for i, v in pairs(il2cppEdits.savedEditsTable) do
                if il2cppEdits.revert_table[i] then
                    menu_names[i] = "✅ " .. v.edit_name
                else
                    menu_names[i] = "▶️ " .. v.edit_name
                end
            end
            menu_names[#menu_names + 1] = "➕ Create Edit"
            menu_names[#menu_names + 1] = "⤴️ Import Edits"
            menu_names[#menu_names + 1] = "⤵️ Export Edits"
            menu_names[#menu_names + 1] = "🗑️ Delete Edit"
            menu_names[#menu_names + 1] = "ℹ️ About Script"
            menu_names[#menu_names + 1] = "❌ Exit Script"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                if menu == #menu_names then
                    pluginManager.returnHome = false
                    -- pluginManager.home()
                elseif menu == #menu_names - 1 then
                    il2cppEdits.about()
                elseif menu == #menu_names - 2 then
                    il2cppEdits.deleteEdit()
                    il2cppEdits.home()
                elseif menu == #menu_names - 3 then
                    il2cppEdits.exportEdits()
                    il2cppEdits.home()
                elseif menu == #menu_names - 4 then
                    il2cppEdits.importEdits()
                    il2cppEdits.home()
                elseif menu == #menu_names - 5 then
                    local result, error = pcall(il2cppEdits.createEdit)
                    if result == false then
                        gg.alert(error)
                    end
                else
                    il2cppEdits.setValues(menu)
                    il2cppEdits.home()
                end
            end
        end
    end,
    get_method_searches = {{"bool", "System.IConvertible.ToBoolean"}, 
							{"char", "System.IConvertible.ToChar"},
							{"sbyte", "System.IConvertible.ToSByte"},
							{"byte", "System.IConvertible.ToByte"},
                            {"short", "System.IConvertible.ToInt16"}, 
							{"ushort", "System.IConvertible.ToUInt16"},
                            {"int", "System.IConvertible.ToInt32"}, 
							{"uint", "System.IConvertible.ToUInt32"},
                            {"long", "System.IConvertible.ToInt64"}, 
							{"ulong", "System.IConvertible.ToUInt64"},
                            {"float", "System.IConvertible.ToSingle"}, 
							{"double", "System.IConvertible.ToDouble"},
                            {"Decimal", "System.IConvertible.ToDecimal"}, 
							{"DateTime", "System.IConvertible.ToDateTime"},
                            {"void", "GetObjectData"}},
    method_types = {},
    --[[
	---------------------------------------
	
	il2cppEdits.checkMethodTypes()
	
	---------------------------------------
	]] --
    checkMethodTypes = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    --[[
	---------------------------------------
	
	il2cppEdits.getMethodTypes()
	
	---------------------------------------
	]] --
    getMethodTypes = function()
        if pcall(il2cppEdits.checkMethodTypes) == false then
            method_types_ran = true
            for i, v in pairs(il2cppEdits.get_method_searches) do
                il2cppEdits.tickClock()
                local methods = il2cppEdits.getMethods(v[2], true)
                if #methods > 0 then
                    il2cppEdits.method_types[tostring(methods[1].method_type)] = v[1]
                end
            end
            il2cppEdits.saveMethodTypes()
        end
    end,
    arch = gg.getTargetInfo(),
    savedEditsTable = {}
}

pcall(il2cppEdits.check_db)
il2cppEdits.bc_cpp_check_cfg_file()
il2cppEdits.getRange()
if pcall(il2cppEdits.checkMethodTypes) == false then
    il2cppEdits.getMethodTypes()
end

pluginManager.returnHome = true
pluginManager.returnPluginTable = "il2cppEdits"
gg.alert(script_title .. "\n\nℹ️ Plugin loaded, if launched directly press the floating [Sx] button to open the menu. ℹ️")
