gg.clearList()
il2cppFields = {
    --[[
	---------------------------------------
	
	il2cppFields.createDirectory()
	
	---------------------------------------
	]] --
    createDirectory = function()
        while (nil) do
            local createDirectoryVal = {}
            if (createDirectoryVal.createDirectoryVal) then
                createDirectoryVal.createDirectoryVal = (createDirectoryVal.createDirectoryVal(createDirectoryVal))
            end
        end
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
        gg.dumpMemory(create_start, create_end, il2cppFields.savePath, gg.DUMP_SKIP_SYSTEM_LIBS)
    end,
    savePath = pluginsDataPath .. "badcase_il2cpp_fields_data/",
    --[[
	---------------------------------------
	
	il2cppFields.checkConfigFileGame()
	
	---------------------------------------
	]] --
    checkConfigFileGame = function()
        dofile(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. ".cfg")
    end,
    --[[
	---------------------------------------
	
	il2cppFields.saveConfig()
	
	---------------------------------------
	]] --
    saveConfig = function()
        local file = io.open(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. ".cfg", "w+")
        file:write("il2cppFields.savedEditsTable = " .. tostring(il2cppFields.savedEditsTable))
        file:close()
    end,
    --[[
	---------------------------------------
	
	il2cppFields.getRange()
	
	---------------------------------------
	]] --
    getRange = function()
        while (nil) do
            local getRangeVal = {}
            if (getRangeVal.getRangeVal) then
                getRangeVal.getRangeVal = (getRangeVal.getRangeVal(getRangeVal))
            end
        end
        gg.setRanges(gg.REGION_OTHER)
        gg.setVisible(false)
        gg.toast(script_title .. "\n\nℹ️ Configuring Script ℹ️")
        gg.clearResults()
        ::try_ca::
        gg.searchNumber(il2cppFields.s_b_s, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)
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
        gg.searchNumber(il2cppFields.e_b_s, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, nil, 1)
        local end_search = gg.getResults(1)
        range_end = end_search[1].address
        gg.clearResults()
    end,
    --[[
	---------------------------------------
	
	il2cppFields.createSearch()
	
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
        byte_search = byte_search .. "0"
        if #search_string > 1 then
            byte_search = byte_search .. "::" .. #search_string + 2
        end
        return byte_search
    end,
    --[[
	---------------------------------------
	
	il2cppFields.getMethodTypes()
	
	---------------------------------------
	]] --
    getMethodTypes = function()
        while (nil) do
            local getMethodTypesVal = {}
            if (getMethodTypesVal.getMethodTypesVal) then
                getMethodTypesVal.getMethodTypesVal = (getMethodTypesVal.getMethodTypesVal(getMethodTypesVal))
            end
        end
        for i, v in pairs(il2cppFields.get_method_searches) do
            gg.setRanges(gg.REGION_OTHER)
            gg.clearResults()
            gg.searchNumber(il2cppFields.createSearch(v[2]), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
            local string_address = gg.getResults(1, 1)
            string_address = string_address[1].address
            gg.clearResults()
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.searchNumber(string_address, flag_type, nil, nil, nil, nil, 1)
            local method_data = gg.getResults(1)
            if gg.getResultsCount() > 0 then
                local get_type = {}
                get_type[1] = {}
                if il2cppFields.arch.x64 then
                    get_type[1].address = method_data[1].address + 16
                else
                    get_type[1].address = method_data[1].address + 8
                end
                get_type[1].flags = flag_type
                get_type = gg.getValues(get_type)
                local get_type2 = {}
                get_type2[1] = {}
                get_type2[1].address = get_type[1].value
                get_type2[1].flags = gg.TYPE_DWORD
                get_type2 = gg.getValues(get_type2)
                if #tostring(get_type2[1].value) > 8 then
                    get_type2 = {}
                    get_type2[1] = {}
                    get_type2[1].address = get_type[1].value + 4
                    get_type2[1].flags = gg.TYPE_DWORD
                    get_type2 = gg.getValues(get_type2)
                    for index = 1, 10 do
                        il2cppFields.method_types[tostring(get_type2[1].value + index)] = v[1]
                    end
                end
                il2cppFields.method_types[tostring(get_type2[1].value)] = v[1]
            end
        end
        local file = io.open(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua", "w+")
        file:write("il2cppFields.method_types = " .. tostring(il2cppFields.method_types))
        file:close()
    end,
    --[[
	---------------------------------------
	
	il2cppFields.checkMethodTypes()
	
	---------------------------------------
	]] --
    checkMethodTypes = function()
        dofile(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    f_hex = function(n)
        return "0x" .. string.format("%x", n)
    end,
    --[[
	---------------------------------------
	
	il2cppFields.loadFields(class, continue)
	
	---------------------------------------
	]] --
    loadFields = function(class, continue)
        while (nil) do
            local loadFieldsVal = {}
            if (loadFieldsVal.loadFieldsVal) then
                loadFieldsVal.loadFieldsVal = (loadFieldsVal.loadFieldsVal(loadFieldsVal))
            end
        end
        local string_address = {}
        local class_headers = {}
        local get_number_of_fields = {}
        local first_field_address = {}
        local field_data = ""
        local field_name_pointer = ""
        local type_pointer = ""
        local class_pointer = ""
        local field_offset = ""
        local current_address = ""
        local get_field_name = {}
        local offset = 0
        local count = 1
        local field_data = {}
        local field_name = ""
        local get_type = {}
        local field_type = {}
        local pointers_to_instances = {}
        if not class then
            class = ""
        end
        gg.clearList()
        if not continue then
            class_string_search = gg.prompt({script_title .. "\n\nℹ️ Enter Class Name ℹ️"}, {class}, {"text"})
        end
        if class_string_search ~= nil or continue == true then
            if continue == true then
                goto do_more
            end
            working_class = class_string_search[1]
            gg.setRanges(gg.REGION_OTHER)
            gg.clearResults()
            gg.searchNumber(il2cppFields.createSearch(class_string_search[1]), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
                range_start, range_end)
            string_address = gg.getResults(1, 1)
            if gg.getResultsCount() == 0 then
                none_found = true
                goto none
            end
            string_address = string_address[1].address
            gg.clearResults()
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.searchNumber(string_address, flag_type)
            class_headers = gg.getResults(gg.getResultsCount())
            for i, v in pairs(class_headers) do
                if il2cppFields.arch.x64 then
                    class_headers[i].address = class_headers[i].address - 16
                else
                    class_headers[i].address = class_headers[i].address - 8
                end
            end
            gg.setRanges(gg.REGION_ANONYMOUS)
            gg.loadResults(class_headers)
            gg.searchPointer(0)
            instance_headers = gg.getResults(gg.getResultsCount())
            if gg.getResultsCount() == 0 then
                none_found = true
                goto none
            end
            class_header = instance_headers[1].value
            first_field_address = {}
            first_field_address[1] = {}
            if il2cppFields.arch.x64 then
                first_field_address[1].address = class_header + 0x80
            else
                first_field_address[1].address = class_header + 0x40
            end
            first_field_address[1].flags = flag_type
            first_field_address = gg.getValues(first_field_address)
            first_field_address = first_field_address[1].value
            if il2cppFields.arch.x64 then
                get_num_fields_start = first_field_address + 24
                get_num_fields_offset = 32
            else
                get_num_fields_start = first_field_address + 12
                get_num_fields_offset = 20
            end
            num_offset = 0
            num_field_data = {}
            for i = 1, 1000 do
                num_field_data[i] = {}
                num_field_data[i].address = get_num_fields_start + num_offset
                num_field_data[i].flags = gg.TYPE_DWORD
                num_offset = num_offset + get_num_fields_offset
            end
            num_field_data = gg.getValues(num_field_data)
            field_counter = 0
            last_field_offset = 0
            break_count = 0
            for i, v in pairs(num_field_data) do
                if v.value >= last_field_offset or v.value == 0 then
                    if v.value >= last_field_offset then
                        break_count = 0
                        last_field_offset = v.value
                    end
                    field_counter = field_counter + 1
                else
                    break_count = break_count + 1
                    if break_count == 2 then
                        break
                    end
                end
            end
            field_data = ""
            field_name_pointer = ""
            type_pointer = ""
            class_pointer = ""
            field_offset = ""
            fields = {}
            number_of_fields = field_counter
            current_address = first_field_address
            for i = 1, number_of_fields do
                if il2cppFields.arch.x64 then
                    field_data = {}
                    field_data[1] = {}
                    field_data[1].address = current_address
                    field_data[1].flags = gg.TYPE_QWORD
                    current_address = current_address + 4
                    field_data[2] = {}
                    field_data[2].address = current_address
                    field_data[2].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[3] = {}
                    field_data[3].address = current_address
                    field_data[3].flags = gg.TYPE_QWORD
                    current_address = current_address + 4
                    field_data[4] = {}
                    field_data[4].address = current_address
                    field_data[4].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[5] = {}
                    field_data[5].address = current_address
                    field_data[5].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[6] = {}
                    field_data[6].address = current_address
                    field_data[6].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[7] = {}
                    field_data[7].address = current_address
                    field_data[7].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[8] = {}
                    field_data[8].address = current_address
                    field_data[8].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data = gg.getValues(field_data)
                    field_name_pointer = field_data[1].value
                    type_pointer = field_data[3].value
                    class_pointer = field_data[5].value
                    field_offset = field_data[7].value
                else
                    field_data = {}
                    field_data[1] = {}
                    field_data[1].address = current_address
                    field_data[1].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[2] = {}
                    field_data[2].address = current_address
                    field_data[2].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[3] = {}
                    field_data[3].address = current_address
                    field_data[3].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[4] = {}
                    field_data[4].address = current_address
                    field_data[4].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data[5] = {}
                    field_data[5].address = current_address
                    field_data[5].flags = gg.TYPE_DWORD
                    current_address = current_address + 4
                    field_data = gg.getValues(field_data)
                    field_name_pointer = field_data[1].value
                    type_pointer = field_data[2].value
                    class_pointer = field_data[3].value
                    field_offset = field_data[4].value
                end
                get_field_name = {}
                offset = 0
                count = 1
                repeat
                    get_field_name[count] = {}
                    get_field_name[count].address = field_name_pointer + offset
                    get_field_name[count].flags = gg.TYPE_BYTE
                    count = count + 1
                    offset = offset + 1
                until (count == 100)
                get_field_name = gg.getValues(get_field_name)
                field_name = ""
                for index, value in pairs(get_field_name) do
                    if value.value >= 0 and value.value <= 255 then
                        field_name = field_name .. string.char(value.value)
                    end
                    if value.value == 0 then
                        break
                    end
                end
                get_type = {}
                get_type[1] = {}
                get_type[1].address = type_pointer
                get_type[1].flags = gg.TYPE_DWORD
                field_type = gg.getValues(get_type)
                field_type = field_type[1].value
                if #tostring(field_type) > 8 then
                    get_type = {}
                    get_type[1] = {}
                    get_type[1].address = type_pointer + 4
                    get_type[1].flags = gg.TYPE_DWORD
                    field_type = gg.getValues(get_type)
                    field_type = field_type[1].value
                end
                if il2cppFields.method_types[tostring(field_type)] == "float" then
                    value_type = gg.TYPE_FLOAT
                elseif il2cppFields.method_types[tostring(field_type)] == "double" then
                    value_type = gg.TYPE_DOUBLE
                elseif (field_offset % 2 ~= 0) then
                    value_type = gg.TYPE_BYTE
                else
                    value_type = gg.TYPE_DWORD
                end
                if value_type and field_offset and string.find(field_name, "[A-Za-z]") then
                    type_menu = "?" .. field_type .. "?"
                    local ask_type = false
                    if il2cppFields.method_types[tostring(field_type)] then
                        type_menu = il2cppFields.method_types[tostring(field_type)]
                    else
                        ask_type = true
                    end
                    fields[#fields + 1] = {
                        field_name = field_name,
                        field_offset = il2cppFields.f_hex(field_offset),
                        field_type = value_type,
                        type_menu = type_menu,
                        ask_type = ask_type
                    }
                end
            end
            gg.loadResults(instance_headers)
            gg.searchPointer(0)
            pointers_to_instances = gg.getResults(gg.getResultsCount())
            sorted_instance_headers = {}
            added_headers = {}
            for i, v in pairs(pointers_to_instances) do
                if not added_headers[v.value] then
                    added_headers[v.value] = v.value
                    table.insert(sorted_instance_headers, v)
                end
            end
            gg.loadResults(sorted_instance_headers)
            sorted_instance_headers = gg.getResults(gg.getResultsCount())
            select_field_items = {}
            for i, v in pairs(fields) do
                select_field_items[i] = "🔘 " .. v.type_menu .. " " .. v.field_name .. " " .. v.field_offset
            end
            ::do_more::
            gg.loadResults(sorted_instance_headers)
            select_field_menu = gg.choice(select_field_items, nil, script_title .. "\n\nℹ️ " .. #sorted_instance_headers .. " Instances Found ℹ️\nClass Name: " .. class_string_search[1])
            if select_field_menu ~= nil then
                working_offset = fields[select_field_menu].field_offset
                working_field_name = fields[select_field_menu].field_name
                load_field_values = {}
                if fields[select_field_menu].ask_type == true then
                    local gg_types = {
                        [1] = 4,
                        [2] = 16,
                        [3] = 64,
                        [4] = 2,
                        [5] = 1,
                        [6] = 32,
                        [7] = 8
                    }
                    local type_menu_items = {
                        [1] = "TYPE_DWORD",
                        [2] = "TYPE_FLOAT",
                        [3] = "TYPE_DOUBLE",
                        [4] = "TYPE_WORD",
                        [5] = "TYPE_BYTE",
                        [6] = "TYPE_QWORD",
                        [7] = "TYPE_XOR"
                    }
                    local type_menu = gg.choice(type_menu_items)
                    if type_menu ~= nil then
                        value_type = gg_types[type_menu]
                    end
                end
                for i, v in pairs(sorted_instance_headers) do
                    load_field_values[i] = v
                    load_field_values[i].address = v.value + fields[select_field_menu].field_offset
                    load_field_values[i].flags = fields[select_field_menu].field_type
                    load_field_values[i].name = "Instance " .. i .. ": " .. select_field_items[select_field_menu]
                end
                gg.addListItems(load_field_values)
            end
        end
        ::none::
        if none_found == true then
            gg.alert(script_title .. "\n\nℹ️ No Class Instances Found ℹ️")
            select_field_menu = nil
            load_field_values = {}
            none_found = false
        else
            if select_field_menu ~= nil then
                select_field_menu = nil
                gg.setVisible(true)
                gg.alert(script_title .. "\n\nℹ️ " .. #load_field_values .. " Instances Added To Save List ℹ️")
                load_field_values = {}
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.editFields()
	
	---------------------------------------
	]] --
    editFields = function()
        while (nil) do
            local editFieldsVal = {}
            if (editFieldsVal.editFieldsVal) then
                editFieldsVal.editFieldsVal = (editFieldsVal.editFieldsVal(editFieldsVal))
            end
        end

        local menu_items = {}
        local menu_names = {}
        local menu_values = {}
        local menu_types = {}
        local save_list_selected = gg.getSelectedListItems()
        local save_edit_values = {
            class_name = working_class,
            field_name = working_field_name,
            value_type = save_list_selected[1].flags
        }
        menu_items[#menu_items + 1] = script_title .. "\n\nℹ️ Create Edit ℹ\n" .. il2cppFields.gg_flags[save_list_selected[1].flags] .. " " .. save_list_selected[1].name
        menu_values[#menu_values + 1] = save_list_selected[1].value
        menu_types[#menu_types + 1] = "number"
        menu_names[#menu_names + 1] = save_list_selected[1].name
        menu_items[#menu_items + 1] = "Freeze"
        menu_items[#menu_items + 1] = "Edit All Instances (Only select one)"
        menu_items[#menu_items + 1] = "Edit All Instances Address + 4 X4 (Only select one)"
        menu_items[#menu_items + 1] = "Edit All Instances With Same Initial Value (Only select one)"
        menu_items[#menu_items + 1] = "Edit All Instances That Have Value Below (Only select one)"
        menu_items[#menu_items + 1] = "Edit Instances That Have This Value"
        menu_values[#menu_values + 1] = false
        menu_types[#menu_types + 1] = "checkbox"
        menu_values[#menu_values + 1] = false
        menu_types[#menu_types + 1] = "checkbox"
        menu_values[#menu_values + 1] = false
        menu_types[#menu_types + 1] = "checkbox"
        menu_values[#menu_values + 1] = false
        menu_types[#menu_types + 1] = "checkbox"
        menu_values[#menu_values + 1] = false
        menu_types[#menu_types + 1] = "checkbox"
        menu_values[#menu_values + 1] = ""
        menu_types[#menu_types + 1] = "number"
        local menu = gg.prompt(menu_items, menu_values, menu_types)
        if menu ~= nil then
            if menu[#menu - 5] == true then
                save_edit_values.freeze = true
            else
                save_edit_values.freeze = false
            end
            if menu[#menu - 3] == true then
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].address = save_list_all[i].address + 4
                    save_list_all[i].value = menu[1] .. "X4"
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_x4"
                save_edit_values.edit_value = menu[1]
            elseif menu[#menu - 4] == true then
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].value = menu[1]
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all"
                save_edit_values.edit_value = menu[1]
            elseif menu[#menu - 2] == true then
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value == save_list_selected[1].value then
                        save_list_all[i].value = menu[1]
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_equal"
                save_edit_values.edit_value = menu[1]
                save_edit_values.must_equal = save_list_selected[1].value
            elseif menu[#menu - 1] == true then
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value == menu[#menu] then
                        save_list_all[i].value = menu[1]
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_equal"
                save_edit_values.edit_value = menu[1]
                save_edit_values.must_equal = menu[#menu]
            else
                for i, v in pairs(save_list_selected) do
                    save_list_selected[i].value = menu[1]
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.addListItems(save_list_selected)
                local save_edit_indexes = {}
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_selected) do
                    for index, value in pairs(save_list_all) do
                        if v.address == value.address then
                            table.insert(save_edit_indexes, index)
                        end
                    end
                end
                save_edit_values.edit_type = "edit_indexes"
                save_edit_values.edit_value = menu[1]
                save_edit_values.edit_indexes = save_edit_indexes
            end
            ::enter_name::
            local name_edit = gg.prompt({script_title .. "\n\nℹ️ Enter Name For Edit ℹ"}, {save_edit_values.field_name}, {"text"})
            if name_edit == nil then
                goto enter_name
            end
            save_edit_values.edit_name = name_edit[1]
            il2cppFields.savedEditsTable[#il2cppFields.savedEditsTable + 1] = save_edit_values
            making_edit = true
            gg.alert(script_title .. "\n\nℹ️ Value has been set. ℹ️ \nTest to verify it is working and then press the floating GG button to either Save or Discard edit.")
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.doSavedEdit(saved_edit_table)
	
	---------------------------------------
	]] --
    doSavedEdit = function(saved_edit_table)
        while (nil) do
            local doSavedEditVal = {}
            if (doSavedEditVal.doSavedEditVal) then
                doSavedEditVal.doSavedEditVal = (doSavedEditVal.doSavedEditVal(doSavedEditVal))
            end
        end
        local string_address = {}
        local class_headers = {}
        local get_number_of_fields = {}
        local first_field_address = {}
        local field_data = ""
        local field_name_pointer = ""
        local type_pointer = ""
        local class_pointer = ""
        local field_offset = ""
        local current_address = ""
        local get_field_name = {}
        local offset = 0
        local count = 1
        local field_data = {}
        local field_name = ""
        local get_type = {}
        local field_type = {}
        local pointers_to_instances = {}
        if not class then
            class = ""
        end
        gg.clearList()
        working_class = saved_edit_table.class_name
        gg.setRanges(gg.REGION_OTHER)
        gg.clearResults()
        gg.searchNumber(il2cppFields.createSearch(saved_edit_table.class_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
        string_address = gg.getResults(1, 1)
        if gg.getResultsCount() == 0 then
            none_found = true
            goto none
        end
        string_address = string_address[1].address
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.searchNumber(string_address, flag_type)
        class_headers = gg.getResults(gg.getResultsCount())
        if gg.getResultsCount() == 0 then
            none_found = true
            goto none
        end
        for i, v in pairs(class_headers) do
            if il2cppFields.arch.x64 then
                class_headers[i].address = class_headers[i].address - 16
            else
                class_headers[i].address = class_headers[i].address - 8
            end
        end
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.loadResults(class_headers)
        gg.searchPointer(0)
        instance_headers = gg.getResults(gg.getResultsCount())
        if gg.getResultsCount() == 0 then
            none_found = true
            goto none
        end
        class_header = instance_headers[1].value
        first_field_address = {}
        first_field_address[1] = {}
        if il2cppFields.arch.x64 then
            first_field_address[1].address = class_header + 0x80
        else
            first_field_address[1].address = class_header + 0x40
        end
        first_field_address[1].flags = flag_type
        first_field_address = gg.getValues(first_field_address)
        first_field_address = first_field_address[1].value
        if il2cppFields.arch.x64 then
            get_num_fields_start = first_field_address + 24
            get_num_fields_offset = 32
        else
            get_num_fields_start = first_field_address + 12
            get_num_fields_offset = 20
        end
        num_offset = 0
        num_field_data = {}
        for i = 1, 1000 do
            num_field_data[i] = {}
            num_field_data[i].address = get_num_fields_start + num_offset
            num_field_data[i].flags = gg.TYPE_DWORD
            num_offset = num_offset + get_num_fields_offset
        end
        num_field_data = gg.getValues(num_field_data)
        field_counter = 0
        last_field_offset = 0
        for i, v in pairs(num_field_data) do
            if v.value >= last_field_offset or v.value == 0 then
                if v.value >= last_field_offset then
                    last_field_offset = v.value
                end
                field_counter = field_counter + 1
            else
                break
            end
        end
        field_data = ""
        field_name_pointer = ""
        type_pointer = ""
        class_pointer = ""
        field_offset = ""
        fields = {}
        number_of_fields = field_counter
        current_address = first_field_address
        for i = 1, number_of_fields do
            if il2cppFields.arch.x64 then
                field_data = {}
                field_data[1] = {}
                field_data[1].address = current_address
                field_data[1].flags = gg.TYPE_QWORD
                current_address = current_address + 4
                field_data[2] = {}
                field_data[2].address = current_address
                field_data[2].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[3] = {}
                field_data[3].address = current_address
                field_data[3].flags = gg.TYPE_QWORD
                current_address = current_address + 4
                field_data[4] = {}
                field_data[4].address = current_address
                field_data[4].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[5] = {}
                field_data[5].address = current_address
                field_data[5].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[6] = {}
                field_data[6].address = current_address
                field_data[6].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[7] = {}
                field_data[7].address = current_address
                field_data[7].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[8] = {}
                field_data[8].address = current_address
                field_data[8].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data = gg.getValues(field_data)
                field_name_pointer = field_data[1].value
                type_pointer = field_data[3].value
                class_pointer = field_data[5].value
                field_offset = field_data[7].value
            else
                field_data = {}
                field_data[1] = {}
                field_data[1].address = current_address
                field_data[1].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[2] = {}
                field_data[2].address = current_address
                field_data[2].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[3] = {}
                field_data[3].address = current_address
                field_data[3].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[4] = {}
                field_data[4].address = current_address
                field_data[4].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data[5] = {}
                field_data[5].address = current_address
                field_data[5].flags = gg.TYPE_DWORD
                current_address = current_address + 4
                field_data = gg.getValues(field_data)
                field_name_pointer = field_data[1].value
                type_pointer = field_data[2].value
                class_pointer = field_data[3].value
                field_offset = field_data[4].value
            end
            get_field_name = {}
            offset = 0
            count = 1
            repeat
                get_field_name[count] = {}
                get_field_name[count].address = field_name_pointer + offset
                get_field_name[count].flags = gg.TYPE_BYTE
                count = count + 1
                offset = offset + 1
            until (count == 100)
            get_field_name = gg.getValues(get_field_name)
            field_name = ""
            for index, value in pairs(get_field_name) do
                if value.value >= 0 and value.value <= 255 then
                    field_name = field_name .. string.char(value.value)
                end
                if value.value == 0 then
                    break
                end
            end
            get_type = {}
            get_type[1] = {}
            get_type[1].address = type_pointer
            get_type[1].flags = gg.TYPE_DWORD
            field_type = gg.getValues(get_type)
            field_type = field_type[1].value
            if #tostring(field_type) > 8 then
                get_type = {}
                get_type[1] = {}
                get_type[1].address = type_pointer + 4
                get_type[1].flags = gg.TYPE_DWORD
                field_type = gg.getValues(get_type)
                field_type = field_type[1].value
            end
            if il2cppFields.method_types[tostring(field_type)] == "float" then
                value_type = gg.TYPE_FLOAT
            elseif il2cppFields.method_types[tostring(field_type)] == "double" then
                value_type = gg.TYPE_DOUBLE
            elseif (field_offset % 2 ~= 0) then
                value_type = gg.TYPE_BYTE
            else
                value_type = gg.TYPE_DWORD
            end
            if value_type and field_offset and string.find(field_name, "[A-Za-z]") then
                type_menu = "?" .. field_type .. "?"
                if il2cppFields.method_types[tostring(field_type)] then
                    type_menu = il2cppFields.method_types[tostring(field_type)]
                end
                fields[#fields + 1] = {
                    field_name = field_name,
                    field_offset = il2cppFields.f_hex(field_offset),
                    field_type = value_type,
                    type_menu = type_menu
                }
            end
        end
        gg.loadResults(instance_headers)
        gg.searchPointer(0)
        pointers_to_instances = gg.getResults(gg.getResultsCount())
        sorted_instance_headers = {}
        added_headers = {}
        for i, v in pairs(pointers_to_instances) do
            if not added_headers[v.value] then
                added_headers[v.value] = v.value
                table.insert(sorted_instance_headers, v)
            end
        end
        gg.loadResults(sorted_instance_headers)
        sorted_instance_headers = gg.getResults(gg.getResultsCount())
        for i, v in pairs(fields) do
            if saved_edit_table.field_name == v.field_name then
                edit_offset = v.field_offset
                edit_type = v.field_type
            end
        end
        load_field_values = {}
        for i, v in pairs(sorted_instance_headers) do
            load_field_values[i] = v
            load_field_values[i].address = v.value + edit_offset
            load_field_values[i].flags = edit_type
        end
        gg.addListItems(load_field_values)
        if saved_edit_table.edit_type == "edit_all_x4" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].address = save_list_all[i].address + 4
                save_list_all[i].value = saved_edit_table.edit_value .. "X4"
                save_list_all[i].freeze = save_edit_values.freeze
            end
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_indexes" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(saved_edit_table.edit_indexes) do
                save_list_all[v].value = saved_edit_table.edit_value
                save_list_all[i].freeze = save_edit_values.freeze
            end
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_all_that_equal" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if v.value == saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = save_edit_values.freeze
                end
            end
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_all" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].value = saved_edit_table.edit_value
                save_list_all[i].freeze = save_edit_values.freeze
            end
            gg.addListItems(save_list_all)
        end
        fields = {}
        ::none::
        if none_found == true then
            gg.alert(script_title .. "\n\nℹ️ No Class Instances Found ℹ️")
            none_found = false
        else
            gg.toast(script_title .. "\n\nℹ️ Edits Made ℹ️")
            il2cppFields.home()
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.deleteEdit()
	
	---------------------------------------
	]] --
    deleteEdit = function()
        local menu_names = {}
        for i, v in pairs(il2cppFields.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local menu = gg.multiChoice(menu_names, nil, script_title .. "\n\nℹ️ Select Edits To Delete ℹ")
        if menu ~= nil then
            local confirm = gg.choice({"✅ Yes delete the edits", 
									   "❌ No"}, 
									   nil, 
									   script_title .. "\n\nℹ️ Are you sure? ℹ\nAre you sure you want to delete these edits,  this can not be undone? ")
            if confirm ~= nil then
                if confirm == 1 then
                    for k, v in pairs(il2cppFields.savedEditsTable) do
                        for key, value in pairs(menu) do
                            if k == key then
                                il2cppFields.savedEditsTable[k] = "delete"
                            end
                        end
                    end
                    ::get_next::
                    local count = 1
                    local do_until = #il2cppFields.savedEditsTable + 1
                    for i, v in pairs(il2cppFields.savedEditsTable) do
                        count = count + 1
                        if type(v) == "string" then
                            table.remove(il2cppFields.savedEditsTable, i)
                            break
                        end
                    end
                    if count < do_until then
                        goto get_next
                    end
                    il2cppFields.saveConfig()
                    gg.toast("✅ Edits Deleted ✅")
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.exportEdits()
	
	---------------------------------------
	]] --
    exportEdits = function()
        local menu_names = {}
        for i, v in pairs(il2cppFields.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local to_export = {}
        local menu = gg.multiChoice(menu_names, nil, script_title .. "\n\nℹ️ Select edits to export. ℹ️")
        if menu ~= nil then
            for k, v in pairs(menu) do
                to_export[#to_export + 1] = il2cppFields.savedEditsTable[k]
            end
            local file = io.open(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.date() .. "_export.json", "w+")
            if file == nil then
                file = io.open(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.time() .. "_export.json", "w+")
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.time() .. "_export.json")
            else
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.date() .. "_export.json")
            end
            file:write(json.encode(to_export))
            file:close()
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.importEdits()
	
	---------------------------------------
	]] --
    importEdits = function()
        local menu = gg.prompt({script_title .. "\n\nℹ️ Select JSON ℹ️"}, {
            [1] = il2cppFields.savePath .. "/"
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
                il2cppFields.savedEditsTable[#il2cppFields.savedEditsTable + 1] = v
            end
            il2cppFields.saveConfig()
            gg.toast("✅ Edits Imported ✅")
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.about()
	
	---------------------------------------
	]] --
    about = function()
        gg.alert(script_title .. [[


ℹ️ About Script ℹ️

This script allows users to edit field offset values in instances of Il2Cpp classes by entering a class name, this means no offsets are needed. As long as class and field names are not changed in the game the edits will continue working even after a game updates.

➕ Create Edit (Enter Class Name)
Here you will enter a known class name to search for instances and create an edit. Edits you create for a game are added to the main menu above this menu item.

➕ Create Edit (Search Il2CppDumper Dump)
Here you can load a Il2CppDumper dump.cs and search for keywords to find class names, search for instances and create an edit. Edits you create for a game are added to the main menu above this menu item.

⤴️ Import Edits
Here you can import edits created and exported by other users of this script.
 
⤵️ Export Edits
Here you can export edits you have created to share them with other users of the script.

🗑️ Delete Edit
Here you can delete edits for a game and remove them from the main menu.
]])
    end,
    --[[
	---------------------------------------
	
	il2cppFields.home()
	
	---------------------------------------
	]] --
    home = function(passed_data)
        pluginManager.returnHome = true
        pluginManager.returnPluginTable = "il2cppFields"
        if passed_data then
            il2cppFields.loadFields(passed_data)
        else
            if making_edit == true then
                local menu = gg.choice({"✅ Save Edit", 
										"🗑️ Discard Edit"}, 
										nil,
										script_title .. "\n\nℹ️ Save or Discard edit. ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        il2cppFields.saveConfig()
                        making_edit = false
                        gg.toast("✅ Edit saved ✅")
                    end
                    if menu == 2 then
                        table.remove(il2cppFields.savedEditsTable, #il2cppFields.savedEditsTable)
                        making_edit = false
                        gg.toast("🗑️ Edit discarded 🗑️")
                    end
                    il2cppFields.home()
                end
            end
            if #gg.getSelectedListItems() > 0 then
                il2cppFields.editFields()
            elseif fields and #fields > 0 then
                local menu = gg.choice({"Yes", "No"}, nil, script_title .. "\n\nℹ️ Continue editing fields? ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        il2cppFields.loadFields(nil, true)
                    end
                    if menu == 2 then
                        fields = {}
                        class_string_search = nil
                        il2cppFields.home()
                    end
                end
            else
                local menu_items = {}
                for i, v in pairs(il2cppFields.savedEditsTable) do
                    menu_items[i] = "▶️ " .. v.edit_name
                end
                menu_items[#menu_items + 1] = "➕ Create Edit (Enter Class Name)"
                menu_items[#menu_items + 1] = "➕ Create Edit (Search Il2CppDumper Dump)"
                menu_items[#menu_items + 1] = "⤴️ Import Edits"
                menu_items[#menu_items + 1] = "⤵️ Export Edits"
                menu_items[#menu_items + 1] = "🗑️ Delete Edits"
                menu_items[#menu_items + 1] = "ℹ️ About Script"
                menu_items[#menu_items + 1] = "❌ Exit Script"
                local menu = gg.choice(menu_items, nil, script_title)
                if menu ~= nil then
                    if menu < #menu_items - 6 then
                        il2cppFields.doSavedEdit(il2cppFields.savedEditsTable[menu])
                    end
                    if menu == #menu_items - 6 then
                        il2cppFields.loadFields()
                    end
                    if menu == #menu_items - 5 then
                        pluginManager.callPlugin(pluginsDataPath .. "plugin_bc_dump_search.lua")
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 4 then
                        il2cppFields.importEdits()
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 3 then
                        il2cppFields.exportEdits()
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 2 then
                        il2cppFields.deleteEdit()
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 1 then
                        il2cppFields.about()
                        il2cppFields.home()
                    end
                    if menu == #menu_items then
                        pluginManager.returnHome = false
                        -- pluginManager.home()
                    end
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
							{"void", "GetObjectData"}},
    method_types = {},
    gg_flags = {
        [1] = "TYPE_BYTE",
        [64] = "TYPE_DOUBLE",
        [4] = "TYPE_DWORD",
        [16] = "TYPE_FLOAT",
        [32] = "TYPE_QWORD",
        [2] = "TYPE_WORD",
        [8] = "TYPE_XOR"
    },
    s_b_s = "109;115;99;111;114;108;105;98;46;100;108;108;77;111;100;117;108;101::20",
    e_b_s = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12",
    arch = gg.getTargetInfo()
}
if il2cppFields.arch.x64 then
    flag_type = gg.TYPE_QWORD
else
    flag_type = gg.TYPE_DWORD
end
il2cppFields.getRange()
if pcall(il2cppFields.checkConfigFileGame) == false then
    il2cppFields.createDirectory()
    il2cppFields.savedEditsTable = {}
    il2cppFields.saveConfig()
end

if pcall(il2cppFields.checkMethodTypes) == false then
    il2cppFields.getMethodTypes()
end

pluginManager.returnHome = true
pluginManager.returnPluginTable = "il2cppFields"
gg.alert(script_title .. "\n\nℹ️ Plugin loaded, if launched directly press the floating [Sx] button to open the menu. ℹ️")
