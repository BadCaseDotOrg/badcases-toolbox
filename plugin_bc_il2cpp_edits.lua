il2cppEdits = {
    savePath = pluginsDataPath .. "badcase_il2cpp_edits_data/",
    checkConfig = function()
        rerun = false
        if pcall(il2cppEdits.checkForConfigFile) == false then
            bc.createDirectory(il2cppEdits.savePath)
            local file = io.open(il2cppEdits.savePath .. gg.getTargetPackage() .. ".cfg", "w+")
            local data_string = "il2cppEdits.savedEditsTable = {}"
            file:write(data_string)
            file:close()
            rerun = true
        end
        if rerun == true then
            il2cppEdits.checkConfig()
        end
    end,
    checkForConfigFile = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. ".cfg")
    end,
    --    il2cppEdits.refineResults(search_string)
    refineResults = function(search_string)
        local first_search_string = "0;" .. string.byte(string.sub(search_string, 1, 1)) .. "::2"
        gg.refineNumber(first_search_string, gg.TYPE_BYTE)
        local second_search_string = string.byte(string.sub(search_string, 1, 1))
        gg.refineNumber(second_search_string, gg.TYPE_BYTE)
        local search_results = gg.getResults(gg.getResultsCount())
        return search_results[1].address
    end,
    --    il2cppEdits.searchDump(search_string)
    searchDump = function(search_string)
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        if search_string then
            gg.clearResults()
            gg.searchNumber(Il2Cpp.createSearch(search_string), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
            if gg.getResultsCount() > 0 then
                return il2cppEdits.refineResults(search_string)
            end
        end
    end,
    --    il2cppEdits.saveMethodTypes()
    saveTypes = function()
        Il2Cpp.saveTypes(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    --    il2cppEdits.getMethods(method_name, get_first)
    getMethods = function(method_name, get_first)
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
                local class_name = Il2Cpp.getString(get_class_pointer_2[1].value)
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
                if Il2Cpp.method_types[tostring(method_type)] then
                    method_type = Il2Cpp.method_types[tostring(method_type)]
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
            ::not_found::
            if cfound == true then
                bc.Toast(#methods_found .. " method(s) found for the string " .. method_name,"ℹ️")
                return methods_found
            else
                ::not_found::
                bc.Toast("No methods were found for that string.","ℹ️")
            end
        end
    end,
    --    il2cppEdits.setDumpMethod(method_name, method_type, class_name)
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
    --    il2cppEdits.getBoolEdit()
    getBoolEdit = function()
        local arm7Edit = {
            isTrue = {"~A MOV R0, #1", "~A BX LR"},
            isFalse = {"~A MOV R0, #0", "~A BX LR"}
        }
        local arm8Edit = {
            isTrue = {"~A8 MOV W0, #1", "~A8 RET"},
            isFalse = {"~A8 MOV W0, WZR", "~A8 RET"}
        }
        local menu = gg.choice({"True", "False"},nil, bc.Choice("Set Boolean Edit", "", "ℹ️"))
        if menu ~= nil then
            if menu == 1 then
                return {arm7Edit.isTrue, arm8Edit.isTrue}
            end
            if menu == 2 then
                return {arm7Edit.isFalse, arm8Edit.isFalse}
            end
        end
    end,
    --    il2cppEdits.getIntEdit()
    getIntEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        ::set_val::
        local menu = gg.prompt({bc.Prompt("Enter Number -255 to 65535","ℹ️")}, {nil}, {"number"})
        if menu ~= nil then
            if tonumber(menu[1]) < -256 or tonumber(menu[1]) > 65535 then
                bc.Alert("Set A Valid Number", "Set a valid number from -255 to 65535.", "⚠️")
                goto set_val
            end
            if tonumber(menu[1]) == 0 then
                edits_arm8[1] = "~A8 MOV W0, WZR"
            else
                edits_arm8[1] = "~A8 MOV W0, #" .. menu[1]
            end
            edits_arm8[2] = "~A8 RET"
            if menu[1]:find("[-]") then
                edits_arm7[1] = "~A MVN R0, #" .. menu[1]:gsub("[-]", "")
                edits_arm7[2] = "~A BX LR"
            else
                edits_arm7[1] = "~A MOVW R0, #" .. menu[1]
                edits_arm7[2] = "~A BX LR"
            end
            return {edits_arm7, edits_arm8}
        end
    end,
    --    il2cppEdits.getComplexFloatEdit(target, method_type)
    getComplexFloatEdit = function(target, method_type)
        target = tonumber(target)
        local float_edits_arm7 = {}
        local float_edits_arm8 = {}
        if target <= 65535 and target >= 0 then
            if method_type == "Single" then
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
            elseif method_type == "Double" then
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
            if method_type == "Single" then
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
            elseif method_type == "Double" then
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
                    if method_type == "Single" then
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
                    elseif method_type == "Double" then
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
                bc.Alert("Value Is Too High", "Set lower than 429503283.", "⚠️")
            end
            if target < 0 then
                bc.Alert("Value Is Too Low", "Set to 0 or higher.", "⚠️")
            end
        end
        if float_edits_arm7 and float_edits_arm8 then
            return {float_edits_arm7, float_edits_arm8}
        end
    end,
    --    il2cppEdits.simpleFloatsTable
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
    --    il2cppEdits.getSimpleFloatEdit()
    getSimpleFloatEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        local menu_table = {}
        for i, v in pairs(il2cppEdits.simpleFloatsTable["ARM7"]) do
            menu_table[#menu_table + 1] = v.float_value
        end
        local menu = gg.choice(menu_table, nil, bc.Choice("Select Float Value", "", "ℹ️"))
        if menu ~= nil then
            edits_arm7[1] = il2cppEdits.simpleFloatsTable["ARM7"][menu].hex_edits
            edits_arm7[2] = "~A BX LR"
            edits_arm8[1] = il2cppEdits.simpleFloatsTable["ARM8"][menu].hex_edits
            edits_arm8[2] = "~A8 RET"
            return {edits_arm7, edits_arm8}
        end
    end,
    last_search = "",
    last_search_2 = "",
    case_sensitive = true,
    all_terms = true,
    --    il2cppEdits.createEdit(method_name, dbsearch, search_term_2)
    createEdit = function(method_name, dbsearch, search_term_2)
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
        local menu = gg.prompt({bc.Prompt("Enter A Method Name","ℹ️").."\nFor \"public bool get_IsUnlocked() { }\" you would enter \"get_IsUnlocked\""}, {method_name}, {"text"})
        if menu ~= nil then
            il2cppEdits.last_search = menu[1]
            local methods = il2cppEdits.getMethods(menu[1])
            if methods ~= nil then
                local methods_menu_items = {}
                for i, v in pairs(methods) do
                    methods_menu_items[#methods_menu_items + 1] = "〰️〰️〰️〰️〰️〰️〰️〰️\nClass Name: " .. v.class_name .. "\nMethod Name: " .. v.method_name .. "\nMethod Type: " .. v.method_type .. "\n〰️〰️〰️〰️〰️〰️〰️〰️"
                end
                local methods_menu = gg.choice(methods_menu_items, nil,bc.Choice("Select Method To Edit", "", "ℹ️"))
                if methods_menu ~= nil then
                    local class_name = methods[methods_menu].class_name
                    local method_name = methods[methods_menu].method_name
                    local il2cpp_address = methods[methods_menu].il2cpp_address
                    il2cppEdits.create_edit_table = {
                        class_name = class_name,
                        method_name = method_name
                    }
                    ::select_edit_type::
                    local menu_type = {"Boolean", "Integer", "Single (float)", "Double"}
                    local edit_type = gg.choice(menu_type, nil, bc.Choice("Select Type Of Edit", "", "ℹ️"))
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
                                local set_val = gg.prompt({bc.Prompt("Set Float Value (Max " .. max_value .. ")","ℹ️")}, nil, {"number"})
                                if set_val ~= nil and tonumber(set_val[1]) <= max_value then
                                    edits = il2cppEdits.getComplexFloatEdit(set_val[1], "Single")
                                elseif set_val ~= nil and tonumber(set_val[1]) > max_value then
                                    bc.Alert("Value Is Too High", "", "⚠️")
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
                                local set_val = gg.prompt({bc.Prompt("Set Double Value (Max " .. max_value .. ")","ℹ️")}, nil, {"number"})
                                if set_val ~= nil and tonumber(set_val[1]) <= max_value then
                                    edits = il2cppEdits.getComplexFloatEdit(set_val[1], "Double")
                                elseif set_val ~= nil and tonumber(set_val[1]) > max_value then
                                    bc.Alert("Value Is Too High", "", "⚠️")
                                    goto set_value
                                end
                            else
                                bc.Alert("Not Enough Room", "Not enough room for double edit.", "⚠️")
                            end
                        end
                    end
                    if not edits then
                        goto select_edit_type
                    end
                    making_edit = true
                    ::enter_name::
                    local name_menu = gg.prompt({bc.Prompt("Enter Name For Edit","ℹ️")}, {method_name}, {"text"})
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
                    bc.Alert("Value Has Been Set", "Test to verify it is working and then press the floating GG button to either Save or Discard edit.", "✅")
                end
            end
        end
    end,
    --    il2cppEdits.createSetValues(address, edits)
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
    --    il2cppEdits.getValues(address)
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
    --    il2cppEdits.findMethod(method_name, passed_class_name)
    findMethod = function(method_name, passed_class_name)
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
            local class_name = Il2Cpp.getString(get_class_pointer_2[1].value)
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
    --    il2cppEdits.setValues(index)
    setValues = function(index)
        if il2cppEdits.revert_table[index] then
            gg.setValues(il2cppEdits.revert_table[index])
            il2cppEdits.revert_table[index] = nil
            bc.Toast(il2cppEdits.savedEditsTable[index].edit_name .. " Disabled ","❌")
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
            bc.Toast(il2cppEdits.savedEditsTable[index].edit_name .. " Enabled ","✅")
        end
    end,
    --    il2cppEdits.saveConfig()
    saveConfig = function()
        bc.saveTable("il2cppEdits.savedEditsTable",il2cppEdits.savePath .. "/" .. gg.getTargetPackage() .. ".cfg")
    end,
    --    il2cppEdits.deleteEdit()
    deleteEdit = function()
        local menu_names = {}
        for i, v in pairs(il2cppEdits.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local menu = gg.multiChoice(menu_names, nil, "Select edits to delete")
        if menu ~= nil then
            local confirm = gg.choice({"✅ Yes delete the edits", "❌ No"}, nil, bc.Choice("Deleting Edits", "Are you sure you want to delete these edits,  this can not be undone?", "⚠️"))
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
                    bc.Toast("Edits Deleted ","✅")
                end
            end
        end
    end,
    --    il2cppEdits.exportEdits()
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
            local path1 = il2cppEdits.savePath .. "/" .. gg.getTargetPackage() .. "_"
            local path2 = os.date()
            local path3 = "_export.json"
            local filePath 
            ::path::
            filePath = path1..path2..path3
            local file = io.open(filePath, "w+")
            if file == nil then
                path2 = os.time()
                goto path
            end
            bc.Alert("Edits Exported", filePath, "✅")
            file:write(json.encode(to_export))
            file:close()
        end
    end,
    --    il2cppEdits.importEdits()
    importEdits = function()
        local menu = gg.prompt({
            bc.Prompt("Select JSON File","ℹ️")
        }, {
            [1] = il2cppEdits.savePath
        }, {
            [1] = "file"
        })
        if menu == nil then
        end
        if menu ~= nil and menu[1]:find( "%.json") then
            local import_table = bc.readFile(menu[1], true)
            for i, v in pairs(import_table) do
                il2cppEdits.savedEditsTable[#il2cppEdits.savedEditsTable + 1] = v
            end
            il2cppEdits.saveConfig()
            bc.Toast("Edits Imported ","✅")
        end
    end,
    --   il2cppEdits.home(passed_data)
    home = function(passed_data)
        pM.returnHome = true
        pM.returnPluginTable = "il2cppEdits"
        if passed_data then
            il2cppEdits.createEdit(passed_data)
        elseif il2cppEdits.scanning == true then
            il2cppEdits.scanHome()
        elseif making_edit == true then
            local menu = gg.choice({"✅ Save Edit", "🗑️ Discard Edit"}, nil, bc.Choice("Testing Edit", "Save or discard edit?", "⚠️"))
            if menu ~= nil then
                if menu == 1 then
                    il2cppEdits.saveConfig()
                    making_edit = false
                    bc.Toast("Edit saved ","✅")
                end
                if menu == 2 then
                    gg.setValues(il2cppEdits.create_revert_table)
                    table.remove(il2cppEdits.savedEditsTable, #il2cppEdits.savedEditsTable)
                    making_edit = false
                    bc.Toast("Edit discarded ","🗑️")
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
            menu_names[#menu_names + 1] = "🔍 Class Scanner"
            menu_names[#menu_names + 1] = "⤴️ Import Edits"
            menu_names[#menu_names + 1] = "⤵️ Export Edits"
            menu_names[#menu_names + 1] = "🗑️ Delete Edit"
            menu_names[#menu_names + 1] = "ℹ️ About Script"
            menu_names[#menu_names + 1] = "❌ Exit Script"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                if menu == #menu_names then
                    Il2Cpp.dumpTable = nil
                    pM.returnHome = false
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
                    il2cppEdits.scanHome()
                elseif menu == #menu_names - 6 then
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
    search = function()
        search_list = {}
        local menu = gg.prompt({
            "Search Term", 
            "Additional Search Term", 
            "Case Sensitive", 
            "Class Names", 
            "Method Names", 
            "Method Types", 
            "Image Names", 
            "Namespace Names", 
            "Parent Class Names"
        }, {
            "", 
            "", 
            true, 
            true, 
            true, 
            true, 
            true, 
            true, 
            true
        }, {
            "text", 
            "text", 
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox"
        })
        if menu ~= nil then
            local search_string = menu[1]
            local search_string2
            if #menu[2] > 0 then
                search_string2 = menu[2]
                if menu[3] == false then
                    search_string2 = string.lower(search_string2)
                end
            end
            if menu[3] == false then
                search_string = string.lower(search_string)
            end
            for i, v in ipairs(Il2Cpp.dumpTable) do
                local search_string_found = false
                local search_string2_found = false
                local class_vals = {
                    [4] = v.class,
                    [7] = v.image,
                    [8] = v.namespace,
                    [9] = v.parent_class
                }
                for ind, val in ipairs(menu) do
                    if ind > 3 then
                        if ind == 5 or ind == 6 then
                            if val == true then
                                if v.methods then
                                    for index, value in pairs(v.methods) do
                                        local class_value
                                        if ind == 5 then
                                            class_value = value.method_name
                                            if menu[3] == false then
                                                class_value = string.lower(class_value)
                                            end
                                            if class_value:find(search_string) then
                                                search_string_found = true
                                            end
                                            if search_string2 and class_value:find(search_string2) then
                                                search_string2_found = true
                                            end
                                        end
                                        if ind == 6 then
                                            class_value = value.method_type
                                            if menu[3] == false then
                                                class_value = string.lower(class_value)
                                            end
                                            if class_value:find(search_string) then
                                                search_string_found = true
                                            end
                                            if search_string2 and class_value:find(search_string2) then
                                                search_string2_found = true
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            if val == true then
                                local class_value = class_vals[ind]
                                if menu[3] == false then
                                    class_value = string.lower(class_value)
                                end
                                if class_value:find(search_string) then
                                    search_string_found = true
                                end
                                if search_string2 and class_value:find(search_string2) then
                                    search_string2_found = true
                                end
                            end
                        end
                    end
                end
                if (search_string2 and search_string_found == true and search_string2_found == true) or (not search_string2 and (search_string_found == true or search_string2_found == true)) then
                    table.insert(search_list, {
                        address = v.class_header,
                        flags = flag_type,
                        name = tostring(v)
                    })
                end
            end
        end
        gg.clearList()
        gg.addListItems(search_list)
    end,
    getMethodsFromClass = function(class)
        local menu_items = {}
        menu_items.display = {}
        menu_items.search = {}
        for i, v in pairs(class.methods) do
            menu_items.display[i] = v.method_type .. " " .. v.method_name
            menu_items.search[i] = v.method_name
        end
        return menu_items
    end,
    scanHome = function()
        il2cppEdits.scanning = true
        if #gg.getSelectedListItems() == 1 then
            current_class = gg.getSelectedListItems()[1].name
            il2cppEdits.scanning = false
            local class_header = tonumber(gg.getSelectedListItems()[1].address)
            local class
            if search_list then
                for i, v in pairs(search_list) do
                    if class_header == v.class_header then
                        class = v
                        break
                    end
                end
            else
                for i, v in pairs(Il2Cpp.dumpTable) do
                    if class_header == v.class_header then
                        class = v
                        break
                    end
                end
            end
            local menu_items = il2cppEdits.getMethodsFromClass(class)
            local menu = gg.choice(menu_items.display,nil, bc.Choice("Select Method", "", "ℹ️"))
            if menu ~= nil then
                il2cppEdits.home(menu_items.search[menu])
            end
        else
            local menu_items = {}
            if not Il2Cpp.dumpTable then
                menu_items[1] = "🔍 Scan For Classes"
            end
            if Il2Cpp.dumpTable then
                menu_items[1] = "🔄 Reload Class List"
                menu_items[2] = "🔎 Search Class List"
            end
            if search_list then
                menu_items[3] = "🔄 Reload Last Search Result"
            end
            menu_items[#menu_items + 1] = "🏠 Back"
            local menu = gg.choice(menu_items, nil, bc.Choice("Class Scanner", "", "ℹ️"))
            if menu ~= nil then
                if not Il2Cpp.dumpTable then
                    pcall(il2cppEdits.checkDumpedMethods)
                end
                if menu == 1 and not Il2Cpp.dumpTable then
                    gg.clearList()
                    Il2Cpp.scriptSettings[2] = true
                    Il2Cpp.scan()
                    il2cppEdits.saveDumpedMethods()
                    il2cppEdits.scanHome()
                elseif menu == 1 and Il2Cpp.dumpTable then
                    gg.clearList()
                    local classes = {}
                    for i, v in pairs(Il2Cpp.dumpTable) do
                        classes[#classes + 1] = {
                            address = v.class_header,
                            flags = flag_type,
                            name = tostring(v)
                        }
                    end
                    gg.addListItems(classes)
                end
                if menu == 2 then
                    il2cppEdits.search()
                end
                if menu == 3 and #menu_items == 4 then
                    gg.clearList()
                    gg.addListItems(search_list)
                end
                if menu == #menu_items then
                    il2cppEdits.scanning = false
                    il2cppEdits.home()
                end
            end
        end
    end,
    --    il2cppEdits.checkMethodTypes()
    checkMethodTypes = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    --    il2cppEdits.getMethodTypes()
    getMethodTypes = function()
        if pcall(il2cppEdits.checkMethodTypes) == false then
            if not Il2Cpp.method_types then
                ::menu2::
                local menu = gg.choice({"Yes (SLOW)", "No (Faster)"}, nil, bc.Choice("Getting Method Types", "Do you want to try and get additional field types from memory? All fields will be retrieved regardless.", "ℹ️"))
                if menu == nil then
                    goto menu2
                else
                    if menu == 1 then
                        if Il2Cpp.followTypePointers == true then
                            if Il2Cpp.arch.x64 then
                                Il2Cpp.getMethodTypes()
                            else
                                Il2Cpp.getTypes27()
                                Il2Cpp.getMethodTypes()
                            end
                        elseif Il2Cpp.unity_version == "v24" then
                            Il2Cpp.getTypes24()
                        else
                            Il2Cpp.getTypes24X()
                            if Il2Cpp.arch.x64 and Il2Cpp.unity_version == "v24.5" then
                                Il2Cpp.getAdditionalTypes()
                            end
                        end
                        il2cppEdits.saveTypes()
                    end
                    if menu == 2 then
                        Il2Cpp.getMethodTypes()
                        il2cppEdits.saveTypes()
                    end
                end
            end
        end
    end,
    arch = gg.getTargetInfo(),
    savedEditsTable = {},
    checkDumpedMethods = function()
        dofile(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_methods.lua")
    end,
    saveDumpedMethods = function()
        bc.saveTable("Il2Cpp.dumpTable",il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_methods.lua")
    end,
    setup = function()
        il2cppEdits.checkConfig()
        if il2cppEdits.arch.x64 then
            flag_type = gg.TYPE_QWORD
            ARM = "ARM8"
        else
            flag_type = gg.TYPE_DWORD
            ARM = "ARM7"
        end
        Il2Cpp.scriptSettings = {false, false, false, false, false, false, false, false}
        ::set_settings::
        local settingsMenu = gg.prompt({
            "Filter Class Results (Faster Class Scan)", 
            "Re-Dump Methods and Types", 
            "Manually Select Unity Build", 
            "Alternate Get Strings (If Freezes At Start)", 
            "Debug"
        }, {
            true, 
            false, 
            false, 
            false, 
            false
        }, {
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox", 
            "checkbox"
        })
        if settingsMenu == nil then
            goto set_settings
        else
            if settingsMenu[1] == true then
                Il2Cpp.scriptSettings[4] = true
            end
            if settingsMenu[2] == true then
                if pcall(il2cppEdits.checkMethodTypes) == true then
                    os.remove(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
                    Il2Cpp.method_types = nil
                end
                if pcall(il2cppEdits.checkDumpedMethods) == true then
                    os.remove(il2cppEdits.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_methods.lua")
                    Il2Cpp.dumpTable = nil
                end
            end
            if settingsMenu[3] == true then
                Il2Cpp.scriptSettings[5] = true
            end
            if settingsMenu[4] == true then
                Il2Cpp.scriptSettings[6] = true
            end
            if settingsMenu[5] == true then
                Il2Cpp.scriptSettings[7] = true
            end
        end
        Il2Cpp.configureScript(Il2Cpp.scriptSettings)
        if pcall(il2cppEdits.checkMethodTypes) == false then
            il2cppEdits.getMethodTypes()
        end
    end,
        --    il2cppEdits.about()
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
}

il2cppEdits.setup()
gg.clearList()

pM.returnHome = true
pM.returnPluginTable = "il2cppEdits"
bc.Alert("Plugin loaded", "If launched directly press the floating [Sx] button to open the menu.", "ℹ️")
