gg.clearList()
il2cppFields = {
    --[[
	---------------------------------------
	
	il2cppFields.createDirectory()
	
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
        il2cppFields.method_types = {}
        for i, v in pairs(il2cppFields.get_method_searches) do
            gg.setRanges(gg.REGION_OTHER)
            gg.clearResults()
            gg.searchNumber(":" .. string.char(0) .. v[2] .. string.char(0), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
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
                local final_type
                if #tostring(get_type2[1].value) > 6 then
                    if il2cppFields.arch.x64 then
                        get_type2[1].flags = gg.TYPE_QWORD
                        get_type2 = gg.getValues(get_type2)
                    end
                    local get_type3 = {}
                    get_type3[1] = {}
                    get_type3[1].address = get_type2[1].value
                    get_type3[1].flags = gg.TYPE_DWORD
                    get_type3 = gg.getValues(get_type3)
                    for index = 1, 10 do
                        il2cppFields.method_types[tostring(get_type3[1].value + index)] = v[1]
                    end
                    final_type = get_type3[1].value
                else
                    final_type = get_type2[1].value
                end
                il2cppFields.method_types[tostring(final_type)] = v[1]
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
            else
                working_class = class_string_search[1]
                gg.setRanges(gg.REGION_OTHER)
                gg.clearResults()
                gg.searchNumber(il2cppFields.createSearch(class_string_search[1]), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
                    range_start, range_end)
                string_address = gg.getResults(1, 1)
            end
            if gg.getResultsCount() > 0 or continue == true then
                if continue == true then
                    goto do_more
                end
                string_address = string_address[1].address
                gg.clearResults()
                gg.setRanges(gg.REGION_C_ALLOC)
                gg.searchNumber(string_address, flag_type)
                class_headers = gg.getResults(gg.getResultsCount())
                for i, v in pairs(class_headers) do
                    if il2cppFields.arch.x64 then
                        class_headers[i].address = class_headers[i].address - 16
                        namespace_offset = 24
                    else
                        class_headers[i].address = class_headers[i].address - 8
                        namespace_offset = 12
                    end
                end
                gg.setRanges(gg.REGION_ANONYMOUS)
                gg.loadResults(class_headers)
                gg.searchPointer(0)
                instance_headers = gg.getResults(gg.getResultsCount())
                found_classes = {}
                for i, v in ipairs(instance_headers) do
                    if not found_classes[tostring(v.value)] then
                        found_classes[tostring(v.value)] = 0
                    else
                        found_classes[tostring(v.value)] = found_classes[tostring(v.value)] + 1
                    end
                end
                found_classes_sorted = {}
                for k, v in pairs(found_classes) do
                    found_classes_sorted[#found_classes_sorted + 1] = {
                        class_address = k,
                        pointers_to = v
                    }
                end
                namespace_names = {}
                for i, v in ipairs(found_classes_sorted) do
                    namespace_string_address = {}
                    namespace_string_address[1] = {}
                    namespace_string_address[1].address = v.class_address + namespace_offset
                    namespace_string_address[1].flags = flag_type
                    namespace_string_address = gg.getValues(namespace_string_address)
                    namespace_string_address = namespace_string_address[1].value
                    get_namespace_name = {}
                    offset = 0
                    count = 1
                    repeat
                        get_namespace_name[count] = {}
                        get_namespace_name[count].address = namespace_string_address + offset
                        get_namespace_name[count].flags = gg.TYPE_BYTE
                        count = count + 1
                        offset = offset + 1
                    until (count == 100)
                    get_namespace_name = gg.getValues(get_namespace_name)
                    namespace_name = ""
                    for index, value in pairs(get_namespace_name) do
                        if value.value >= 0 and value.value <= 255 then
                            namespace_name = namespace_name .. string.char(value.value)
                        end
                        if value.value == 0 then
                            break
                        end
                    end
                    namespace_names[i] = namespace_name .. " Pointers(" .. found_classes_sorted[i].pointers_to .. ")"
                    found_classes_sorted[i].namespace = namespace_name
                end
                ::pick_ns::
                choose_namespace = gg.choice(namespace_names, nil, script_title .. "\n\nℹ️ Select Namespace ℹ️\nIf the class you want has no active instances then got to a place in the game the values would be used and try again.")
                if choose_namespace == nil then
                else
                    edit_namespace = found_classes_sorted[choose_namespace].namespace
                    gg.refineNumber(found_classes_sorted[choose_namespace].class_address, flag_type)
                    instance_headers = gg.getResults(gg.getResultCount())
                end
                if gg.getResultsCount() > 0 and choose_namespace ~= nil then
                    class_header = instance_headers[1].value
                    il2cppFields.current_fields = {}
                    ::above::
                    local field_count = {}
                    field_count[1] = {}
                    field_count[1].address = class_header + il2cppFields.fieldOffsets.fieldCount
                    field_count[1].flags = gg.TYPE_DWORD
                    field_count = gg.getValues(field_count)
                    field_count = field_count[1].value
                    local fields_pointer = {}
                    fields_pointer[1] = {}
                    fields_pointer[1].address = class_header + il2cppFields.fieldOffsets.fieldPointer
                    fields_pointer[1].flags = flag_type
                    local fields_pointer_address = gg.getValues(fields_pointer)
                    local fields_start = {}
                    fields_start[1] = {}
                    fields_start[1].address = fields_pointer_address[1].value
                    fields_start[1].flags = flag_type
                    fields_start = gg.getValues(fields_start)
                    fields_start = fields_start[1].address
                    local offset = 0
                    gg.clearResults()
                    gg.setRanges(gg.REGION_C_ALLOC)
                    local getall
                    ::menu2::
                    local menu = gg.choice({"Yes (SLOW)", "No (Faster)"}, nil, script_title .. "\n\nℹ️ Do you want to try and get additional field types from memory? All fields will be retrieved regardless.  ℹ️")
                    if menu == nil then
                        goto menu2
                    else
                        if menu == 1 then
                            getall = true
                            if not getFieldsPointerSearch then
                                gg.searchNumber(
                                    range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. "::13",
                                    flag_type)
                                getFieldsPointerSearch = gg.getResults(gg.getResultsCount())
                            end
                        end
                    end
                    for i = 1, field_count do
                        local field_name_pointer = {}
                        field_name_pointer[1] = {}
                        field_name_pointer[1].address = fields_start + offset
                        field_name_pointer[1].flags = flag_type
                        field_name_pointer = gg.getValues(field_name_pointer)
                        local field_type = ""
                        if getall == true then
                            gg.loadResults(getFieldsPointerSearch)
                            gg.refineNumber(field_name_pointer[1].value .. ";0~~0::5", flag_type, nil, nil, nil, nil, 1)
                            type_pointer = gg.getResults(1, 1)
                            if #type_pointer > 0 then
                                if il2cppFields.retrieved_field_types[tostring(type_pointer[1].value)] then
                                    field_type = il2cppFields.retrieved_field_types[tostring(type_pointer[1].value)]
                                else
                                    local first_letter = {}
                                    first_letter[1] = {}
                                    first_letter[1].address = type_pointer[1].value
                                    first_letter[1].flags = gg.TYPE_BYTE
                                    first_letter = gg.getValues(first_letter)
                                    local count = 0
                                    repeat
                                        local current_letter = {}
                                        current_letter[1] = {}
                                        current_letter[1].address = first_letter[1].address + count
                                        current_letter[1].flags = gg.TYPE_BYTE
                                        current_letter = gg.getValues(current_letter)
                                        count = count + 1
                                        if current_letter[1].value > 0 and current_letter[1].value <= 255 then
                                            field_type = field_type .. string.char(current_letter[1].value)
                                        end
                                    until (current_letter[1].value == 0)
                                end
                            end
                        end
                        if #field_type > 2 then
                            il2cppFields.retrieved_field_types[tostring(type_pointer[1].value)] = field_type
                        else
                            local get_type = {}
                            get_type[1] = {}
                            if il2cppFields.arch.x64 then
                                get_type[1].address = fields_start + offset + 8
                            else
                                get_type[1].address = fields_start + offset + 4
                            end
                            get_type[1].flags = flag_type
                            get_type = gg.getValues(get_type)
                            local get_type2 = {}
                            get_type2[1] = {}
                            get_type2[1].address = get_type[1].value
                            get_type2[1].flags = gg.TYPE_DWORD
                            get_type2 = gg.getValues(get_type2)
                            final_type = get_type2[1].value
                            if #tostring(final_type) > 6 then
                                if il2cppFields.arch.x64 then
                                    get_type2[1].flags = gg.TYPE_QWORD
                                    get_type2 = gg.getValues(get_type2)
                                end
                                local get_type3 = {}
                                get_type3[1] = {}
                                get_type3[1].address = get_type2[1].value
                                get_type3[1].flags = gg.TYPE_DWORD
                                get_type3 = gg.getValues(get_type3)
                                get_type3 = get_type3[1].value
                                final_type = get_type3
                            end
                            if il2cppFields.method_types[tostring(final_type)] then
                                field_type = il2cppFields.method_types[tostring(final_type)]
                            else
                                field_type = tostring(final_type)
                            end
                        end
                        local field_offset = {}
                        field_offset[1] = {}
                        field_offset[1].address = field_name_pointer[1].address + il2cppFields.fieldOffsets.fieldOffset
                        field_offset[1].flags = gg.TYPE_DWORD
                        field_offset = gg.getValues(field_offset)
                        field_offset = field_offset[1].value
                        offset = offset + il2cppFields.fieldOffsets.fieldNext
                        local first_letter = {}
                        first_letter[1] = {}
                        first_letter[1].address = field_name_pointer[1].value
                        first_letter[1].flags = gg.TYPE_BYTE
                        first_letter = gg.getValues(first_letter)
                        local field_name = ""
                        local count = 0
                        repeat
                            local current_letter = {}
                            current_letter[1] = {}
                            current_letter[1].address = first_letter[1].address + count
                            current_letter[1].flags = gg.TYPE_BYTE
                            current_letter = gg.getValues(current_letter)
                            count = count + 1
                            if current_letter[1].value > 0 and current_letter[1].value <= 255 then
                                field_name = field_name .. string.char(current_letter[1].value)
                            end
                        until (current_letter[1].value == 0)
                        if il2cppFields.method_types[tostring(field_type)] == "float" then
                            value_type = gg.TYPE_FLOAT
                        elseif il2cppFields.method_types[tostring(field_type)] == "double" then
                            value_type = gg.TYPE_DOUBLE
                        elseif (field_offset % 2 ~= 0) then
                            value_type = gg.TYPE_BYTE
                        else
                            value_type = gg.TYPE_DWORD
                        end
                        local ask_type = false
                        if il2cppFields.method_types[tostring(field_type)] then
                            type_menu = il2cppFields.method_types[tostring(field_type)]
                        else
                            ask_type = true
                        end
                        if not fields then
                            fields = {}
                        end
                        fields[#fields + 1] = {
                            field_name = field_name,
                            field_offset = il2cppFields.f_hex(field_offset),
                            field_type = value_type,
                            type_menu = field_type,
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
                if choose_namespace ~= nil then
                    for i, v in pairs(fields) do
                        select_field_items[i] = "🔘 " .. v.type_menu .. " " .. v.field_name .. " " .. v.field_offset
                    end
                end
                ::do_more::
                if choose_namespace ~= nil then
                    gg.loadResults(sorted_instance_headers)
                    select_field_menu = gg.choice(select_field_items, nil,
                        script_title .. "\n\nℹ️ " .. #sorted_instance_headers .. " Instances Found ℹ️\nClass Name: " .. class_string_search[1])
                    if select_field_menu ~= nil then
                        working_offset = fields[select_field_menu].field_offset
                        working_field_name = fields[select_field_menu].field_name
                        load_field_values = {}
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
                        ::pick_type::
                        local type_menu = gg.choice(type_menu_items)
                        if type_menu == nil then
                            goto pick_type
                        else
                            value_type = gg_types[type_menu]
                            for i, v in pairs(sorted_instance_headers) do
                                load_field_values[i] = v
                                load_field_values[i].address =
                                    v.value + tonumber(fields[select_field_menu].field_offset)
                                load_field_values[i].flags = value_type
                                load_field_values[i].name = "Instance " .. i .. ": " .. select_field_items[select_field_menu]
                            end
                            gg.addListItems(load_field_values)
                        end
                    end
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
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.editFields()
	
	---------------------------------------
	]] --
    editFields = function()
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
        menu_items[#menu_items + 1] = script_title .. "\n\nℹ️ Create Edit ℹ\n"
                                          .. il2cppFields.gg_flags[save_list_selected[1].flags] .. " "
                                          .. save_list_selected[1].name
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
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_x4"
                save_edit_values.edit_value = menu[1]
            elseif menu[#menu - 4] == true then
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].value = menu[1]
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.setValues(save_list_all)
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
                gg.setValues(save_list_all)
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
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_equal"
                save_edit_values.edit_value = menu[1]
                save_edit_values.must_equal = menu[#menu]
            else
                for i, v in pairs(save_list_selected) do
                    save_list_selected[i].value = menu[1]
                    save_list_selected[i].freeze = save_edit_values.freeze
                end
                gg.setValues(save_list_selected)
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
            save_edit_values.edit_namespace = edit_namespace
            ::enter_name::
            local name_edit = gg.prompt({script_title .. "\n\nℹ️ Enter Name For Edit ℹ"},
                {save_edit_values.field_name}, {"text"})
            if name_edit == nil then
                goto enter_name
            end
            save_edit_values.edit_name = name_edit[1]
            il2cppFields.savedEditsTable[#il2cppFields.savedEditsTable + 1] = save_edit_values
            making_edit = true
            gg.alert(script_title
                         .. "\n\nℹ️ Value has been set. ℹ️ \nTest to verify it is working and then press the floating GG button to either Save or Discard edit.")
        end
    end,
    --[[
	---------------------------------------
	
	il2cppFields.doSavedEdit(saved_edit_table)
	
	---------------------------------------
	]] --
    doSavedEdit = function(saved_edit_table)
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
        gg.searchNumber(il2cppFields.createSearch(saved_edit_table.class_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
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
        if gg.getResultsCount() == 0 then
            none_found = true
            goto none
        end
        for i, v in pairs(class_headers) do
            if il2cppFields.arch.x64 then
                class_headers[i].address = class_headers[i].address - 16
                namespace_offset = 24
            else
                class_headers[i].address = class_headers[i].address - 8
                namespace_offset = 12
            end
        end
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.loadResults(class_headers)
        gg.searchPointer(0)
        instance_headers = gg.getResults(gg.getResultsCount())
        found_classes = {}
        for i, v in ipairs(instance_headers) do
            if not found_classes[tostring(v.value)] then
                found_classes[tostring(v.value)] = 0
            else
                found_classes[tostring(v.value)] = found_classes[tostring(v.value)] + 1
            end
        end
        found_classes_sorted = {}
        for k, v in pairs(found_classes) do
            found_classes_sorted[#found_classes_sorted + 1] = {
                class_address = k,
                pointers_to = v
            }
        end
        namespace_names = {}
        for i, v in ipairs(found_classes_sorted) do
            namespace_string_address = {}
            namespace_string_address[1] = {}
            namespace_string_address[1].address = v.class_address + namespace_offset
            namespace_string_address[1].flags = flag_type
            namespace_string_address = gg.getValues(namespace_string_address)
            namespace_string_address = namespace_string_address[1].value
            get_namespace_name = {}
            offset = 0
            count = 1
            repeat
                get_namespace_name[count] = {}
                get_namespace_name[count].address = namespace_string_address + offset
                get_namespace_name[count].flags = gg.TYPE_BYTE
                count = count + 1
                offset = offset + 1
            until (count == 100)
            get_namespace_name = gg.getValues(get_namespace_name)
            namespace_name = ""
            for index, value in pairs(get_namespace_name) do
                if value.value >= 0 and value.value <= 255 then
                    namespace_name = namespace_name .. string.char(value.value)
                end
                if value.value == 0 then
                    break
                end
            end
            if namespace_name == saved_edit_table.edit_namespace then
                gg.refineNumber(found_classes_sorted[i].class_address, flag_type)
                instance_headers = gg.getResults(gg.getResultCount())
                break
            end
        end
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
        gg.setValues(load_field_values)
        gg.addListItems(load_field_values)
        if saved_edit_table.edit_type == "edit_all_x4" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].address = save_list_all[i].address + 4
                save_list_all[i].value = saved_edit_table.edit_value .. "X4"
                save_list_all[i].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_indexes" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(saved_edit_table.edit_indexes) do
                save_list_all[v].value = saved_edit_table.edit_value
                save_list_all[v].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_all_that_equal" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if v.value == saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        elseif saved_edit_table.edit_type == "edit_all" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].value = saved_edit_table.edit_value
                save_list_all[i].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
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
            local confirm = gg.choice({"✅ Yes delete the edits", "❌ No"}, nil, script_title
                .. "\n\nℹ️ Are you sure? ℹ\nAre you sure you want to delete these edits,  this can not be undone? ")
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
            local file = io.open(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.date()
                                     .. "_export.json", "w+")
            if file == nil then
                file = io.open(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_" .. os.time()
                                   .. "_export.json", "w+")
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppFields.savePath .. "/"
                             .. gg.getTargetPackage() .. "_" .. os.time() .. "_export.json")
            else
                gg.alert(script_title .. "\n\n✅ Edits Exported ✅\n\n" .. il2cppFields.savePath .. "/"
                             .. gg.getTargetPackage() .. "_" .. os.date() .. "_export.json")
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
        elseif il2cppFields.scanning == true then
            il2cppFields.scanHome()
        else
            if making_edit == true then
                local menu = gg.choice({"✅ Save Edit", "🗑️ Discard Edit"}, nil,
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
                menu_items[#menu_items + 1] = "🔍 Class Scanner"
                menu_items[#menu_items + 1] = "⤴️ Import Edits"
                menu_items[#menu_items + 1] = "⤵️ Export Edits"
                menu_items[#menu_items + 1] = "🗑️ Delete Edits"
                menu_items[#menu_items + 1] = "ℹ️ About Script"
                menu_items[#menu_items + 1] = "❌ Exit Script"
                local menu = gg.choice(menu_items, nil, script_title)
                if menu ~= nil then
                    if menu < #menu_items - 7 then
                        il2cppFields.doSavedEdit(il2cppFields.savedEditsTable[menu])
                    end
                    if menu == #menu_items - 7 then
                        il2cppFields.loadFields()
                    end
                    if menu == #menu_items - 6 then
                        pluginManager.callPlugin(pluginsDataPath .. "plugin_bc_dump_search.lua")
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 5 then
                        il2cppFields.scanHome()
                        il2cppFields.scanning = true
                        -- il2cppFields.home()
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
                    end
                end
            end
        end
    end,
    get_method_searches = {{"bool", "System.IConvertible.ToBoolean"}, {"char", "System.IConvertible.ToChar"},
        {"sbyte", "System.IConvertible.ToSByte"}, {"byte", "System.IConvertible.ToByte"},
        {"short", "System.IConvertible.ToInt16"}, {"ushort", "System.IConvertible.ToUInt16"},
        {"int", "System.IConvertible.ToInt32"}, {"uint", "System.IConvertible.ToUInt32"},
        {"long", "System.IConvertible.ToInt64"}, {"ulong", "System.IConvertible.ToUInt64"},
        {"float", "System.IConvertible.ToSingle"}, {"double", "System.IConvertible.ToDouble"},
        {"Decimal", "System.IConvertible.ToDecimal"}, {"void", "GetObjectData"}},
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
    arch = gg.getTargetInfo(),
    gg_hex = function(n)
        if il2cppFields.arch.x64 then
            return "0x" .. string.format('%16x', n):sub(-10)
        else
            return "0x" .. string.format('%08x', n):sub(-8)
        end
    end,
    other_ranges = {},
    fieldOffsets = {},
    offsetsAPI = {
        [24] = {
            fieldOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            fieldType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            fieldClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            fieldPointer = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            fieldNext = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            fieldCount = {
                ARM8 = 0x11C,
                ARM7 = 0xA8
            }
        },
        [27] = {
            fieldOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            fieldType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            fieldClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            fieldPointer = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            fieldNext = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            fieldCount = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            }
        },
        [29] = {
            fieldOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            fieldType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            fieldClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            fieldPointer = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            fieldNext = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            fieldCount = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            }
        }
    },
    unityVersions = {{
        search = ":" .. string.char(0) .. "2022.",
        version = 29
    }, {
        search = ":" .. string.char(0) .. "2021.1",
        version = 27
    }, {
        search = ":" .. string.char(0) .. "2020.2",
        version = 27
    }, {
        search = ":" .. string.char(0) .. "2020.1",
        version = 24
    }, {
        search = ":" .. string.char(0) .. "2019.",
        version = 24
    }, {
        search = ":" .. string.char(0) .. "2018.",
        version = 24
    }, {
        search = ":" .. string.char(0) .. "2017.",
        version = 24
    }},
    setup = function()
        if il2cppFields.arch.x64 then
            flag_type = gg.TYPE_QWORD
            ARM = "ARM8"
        else
            flag_type = gg.TYPE_DWORD
            ARM = "ARM7"
        end
        gg.setRanges(gg.REGION_C_ALLOC)
        for i, v in ipairs(il2cppFields.unityVersions) do
            gg.clearResults()
            gg.searchNumber(v.search)
            local check_version = gg.getResults(1)
            if #check_version > 0 then
                local check_f = {}
                for index = 1, 12 do
                    check_f[index] = {}
                    check_f[index].address = check_version[1].address + index
                    check_f[index].flags = gg.TYPE_BYTE
                end
                check_f = gg.getValues(check_f)
                for index, value in ipairs(check_f) do
                    if value.value == 102 then
                        found = true
                    end
                end
                if found == true then
                    il2cppFields.fieldOffsets.fieldOffset = il2cppFields.offsetsAPI[v.version].fieldOffset[ARM]
                    il2cppFields.fieldOffsets.fieldType = il2cppFields.offsetsAPI[v.version].fieldType[ARM]
                    il2cppFields.fieldOffsets.fieldClassOffset =
                        il2cppFields.offsetsAPI[v.version].fieldClassOffset[ARM]
                    il2cppFields.fieldOffsets.fieldPointer = il2cppFields.offsetsAPI[v.version].fieldPointer[ARM]
                    il2cppFields.fieldOffsets.fieldNext = il2cppFields.offsetsAPI[v.version].fieldNext[ARM]
                    il2cppFields.fieldOffsets.fieldCount = il2cppFields.offsetsAPI[v.version].fieldCount[ARM]
                    break
                end
            end
        end
        if not il2cppFields.fieldOffsets.fieldOffset then
            il2cppFields.fieldOffsets.fieldOffset = il2cppFields.offsetsAPI[24].fieldOffset[ARM]
            il2cppFields.fieldOffsets.fieldType = il2cppFields.offsetsAPI[24].fieldType[ARM]
            il2cppFields.fieldOffsets.fieldClassOffset = il2cppFields.offsetsAPI[24].fieldClassOffset[ARM]
            il2cppFields.fieldOffsets.fieldPointer = il2cppFields.offsetsAPI[24].fieldPointer[ARM]
            il2cppFields.fieldOffsets.fieldNext = il2cppFields.offsetsAPI[24].fieldNext[ARM]
            il2cppFields.fieldOffsets.fieldCount = il2cppFields.offsetsAPI[24].fieldCount[ARM]
        end
        for i, v in pairs(gg.getRangesList()) do
            if v.state == "O" then
                table.insert(il2cppFields.other_ranges, {
                    start = v["start"],
                    ["end"] = v["end"]
                })
            end
        end
    end,
    check_if_other = function(address)
        local found = false
        if address ~= "0x00000000" then
            for i, v in ipairs(il2cppFields.other_ranges) do
                if tonumber(address) >= tonumber(v["start"]) and tonumber(address) <= tonumber(v["end"]) then
                    found = true
                    break
                end
            end
        end
        return found
    end,
    class_names = {},
    namespace_names = {},
    image_names = {},
    firstPointerSearch = {},
    scan = function()
        ::menu1::
        local menu = gg.choice({"Find All Classes", "Only Find Classes With No Namespace"}, nil, script_title .. "\n\nℹ️ Class Scanner ℹ️")
        if menu == nil then
            goto menu1
        end
        if not il2cppFields.fieldOffsets.fieldOffset then
            il2cppFields.setup()
        end
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC)
        local startingSearches = {
            ["ARM7"] = {
                [1] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_end .. "::5",
                [2] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_start + 10 .. "::5"
            },
            ["ARM8"] = {
                [1] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_end .. "::13",
                [2] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_start + 10 .. "::13"
            }
        }
        if menu == 1 then
            first_search_string = startingSearches[ARM][1]
        end
        if menu == 2 then
            first_search_string = startingSearches[ARM][2]
        end
        gg.searchNumber(first_search_string, flag_type)
        il2cppFields.firstPointerSearch = gg.getResults(gg.getResultsCount())
        check_table = {}
        local add_value = true
        for i, v in ipairs(il2cppFields.firstPointerSearch) do
            if add_value == true then
                table.insert(check_table, v)
                add_value = false
            else
                add_value = true
            end
        end
        gg.loadResults(check_table)
        sorted_check_table = {}
        for i, v in ipairs(check_table) do
            if i % 100 == 0 then
                gg.toast(i .. " of " .. #check_table .. " pointers checked")
            end
            local check_class = {}
            check_class[1] = {}
            if il2cppFields.arch.x64 then
                check_class[1].address = v.address - 16
                check_class[1].flags = gg.TYPE_QWORD
                check_class[2] = {}
                check_class[2].address = v.address
                check_class[2].flags = gg.TYPE_QWORD
                check_class[3] = {}
                check_class[3].address = v.address + 8
                check_class[3].flags = gg.TYPE_QWORD
                check_class[4] = {}
                check_class[4].address = v.address + il2cppFields.fieldOffsets.fieldPointer - 16
                check_class[4].flags = gg.TYPE_QWORD
                check_class[5] = {}
                check_class[5].address = v.address + il2cppFields.fieldOffsets.fieldCount - 16
                check_class[5].flags = gg.TYPE_DWORD
            else
                check_class[1].address = v.address - 8
                check_class[1].flags = gg.TYPE_DWORD
                check_class[2] = {}
                check_class[2].address = v.address
                check_class[2].flags = gg.TYPE_DWORD
                check_class[3] = {}
                check_class[3].address = v.address + 4
                check_class[3].flags = gg.TYPE_DWORD
                check_class[4] = {}
                check_class[4].address = v.address + il2cppFields.fieldOffsets.fieldPointer - 8
                check_class[4].flags = gg.TYPE_DWORD
                check_class[5] = {}
                check_class[5].address = v.address + il2cppFields.fieldOffsets.fieldCount - 8
                check_class[5].flags = gg.TYPE_DWORD
            end
            check_class = gg.getValues(check_class)
            if #tostring(check_class[1].value) > 8 and #tostring(check_class[2].value) > 8
                and #tostring(check_class[4].value) > 8 then
                local field_count
                if check_class[5].value > 0 and check_class[5].value < 10000 then
                    field_count = check_class[5].value
                end
                local get_image = {}
                local get_namespace = {}
                if field_count ~= nil then
                    if il2cppFields.image_names[tostring(check_class[1].address)] then
                        get_image = il2cppFields.image_names[tostring(check_class[1].address)]
                    else
                        get_image[1] = {}
                        get_image[1].address = check_class[1].value
                        get_image[1].flags = flag_type
                        get_image = gg.getValues(get_image)
                        get_image = get_image[1].value
                        il2cppFields.image_names[tostring(check_class[1].address)] = get_image
                    end
                    if #tostring(check_class[3].value) > 8 then
                        if il2cppFields.namespace_names[tostring(check_class[3].value)] then
                            get_namespace = il2cppFields.namespace_names[tostring(check_class[3].value)]
                        else
                            get_namespace = check_class[3].value
                            il2cppFields.namespace_names[tostring(check_class[3].value)] = get_namespace
                        end
                    end
                    local class_name
                    if il2cppFields.class_names[tostring(check_class[2].value)] then
                        class_name = il2cppFields.class_names[tostring(check_class[2].value)]
                    else
                        class_name = il2cppFields.get_class_name(il2cppFields.gg_hex(check_class[2].value))
                        il2cppFields.class_names[tostring(check_class[2].value)] = class_name
                    end
                    local add_to_list = {}
                    add_to_list.address = check_class[1].address
                    add_to_list.flags = flag_type
                    add_to_list.name = "Image: " .. il2cppFields.get_class_name(il2cppFields.gg_hex(get_image)) .. "\n"
                    if type(get_namespace) == "number" then
                        add_to_list.name = add_to_list.name .. "Namespace: " .. il2cppFields.get_class_name(il2cppFields.gg_hex(get_namespace)) .. "\n"
                    end
                    add_to_list.name = add_to_list.name .. "Class: " .. class_name .. "\nFields: " .. field_count
                    gg.addListItems({add_to_list})
                end
            end
        end
        class_list = gg.getListItems()
        gg.alert(script_title .. "\n\nℹ️ Class Scan Complete ℹ️\n\nSelect 1 item in the Save List and press the floating [Sx] button to search for instances of the class.\n\nOr select nothing and press the floating [Sx] button to search for keywords or rescan.")
    end,
    get_class_name = function(address)
        local class_name = ""
        if address ~= "0x00000000" then
            local first_letter = {}
            first_letter[1] = {}
            first_letter[1].address = address
            first_letter[1].flags = gg.TYPE_BYTE
            first_letter = gg.getValues(first_letter)
            local get_class_name_table = {}
            offset = 0
            for i = 1, 100 do
                get_class_name_table[i] = {}
                get_class_name_table[i].address = first_letter[1].address + offset
                get_class_name_table[i].flags = gg.TYPE_BYTE
                offset = offset + 1
            end
            get_class_name_table = gg.getValues(get_class_name_table)
            class_name = ""
            for index, value in pairs(get_class_name_table) do
                if value.value > 0 and value.value <= 255 then
                    class_name = class_name .. string.char(value.value)
                end
                if value.value == 0 then
                    break
                end
            end
        end
        return class_name
    end,
    current_fields = {},
    retrieved_field_types = {},
    s_b_s = ":mscorlib.dll <Module>",
    e_b_s = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12",
    getRange = function()
        gg.setRanges(gg.REGION_OTHER)
        gg.setVisible(false)
        gg.toast("\n\nℹ️ Configuring Script ℹ️")
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
    load_instance_values = function(address, offset, field_type, field_name, current_class)
        local gg_flags = {
            ["char"] = gg.TYPE_BYTE,
            ["byte"] = gg.TYPE_BYTE,
            ["sbyte"] = gg.TYPE_BYTE,
            ["double"] = gg.TYPE_DOUBLE,
            ["int"] = gg.TYPE_DWORD,
            ["short"] = gg.TYPE_DWORD,
            ["long"] = gg.TYPE_DWORD,
            ["uint"] = gg.TYPE_DWORD,
            ["ushort"] = gg.TYPE_DWORD,
            ["ulong"] = gg.TYPE_DWORD,
            ["float"] = gg.TYPE_FLOAT
        }
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.clearResults()
        gg.searchNumber(address, flag_type)
        local current_instances = gg.getResults(gg.getResultsCount())
        for i, v in ipairs(current_instances) do
            current_instances[i].address = current_instances[i].address + offset
            if current_instances[i].address % 4 ~= 0 then
                current_instances[i].flags = gg.TYPE_BYTE
            elseif gg_flags[field_type] then
                current_instances[i].flags = gg_flags[field_type]
            else
                current_instances[i].flags = gg.TYPE_DWORD
            end
            current_instances[i].name = current_class .. "\n" .. field_type .. " " .. field_name .. " " .. offset
        end
        gg.clearList()
        gg.addListItems(current_instances)
    end,
    search = function()
        search_list = {}
        local menu = gg.prompt({"Search Term", "Case Sensitive", "Search Image Instead Of Class"}, {"", true, false}, {"text", "checkbox", "checkbox"})
        if menu ~= nil then
            for i, v in ipairs(class_list) do
                if menu[3] == false then
                    if menu[2] == false then
                        if string.lower(v.name):find("class.+" .. string.lower(menu[1])) then
                            table.insert(search_list, v)
                        end
                    elseif v.name:find("Class.+" .. menu[1]) then
                        table.insert(search_list, v)
                    end
                else
                    if menu[2] == false then
                        if string.lower(v.name):find("image.+" .. string.lower(menu[1])) then
                            table.insert(search_list, v)
                        end
                    elseif v.name:find("Image.+" .. menu[1]) then
                        table.insert(search_list, v)
                    end
                end
            end
        end
        gg.clearList()
        gg.addListItems(search_list)
    end,
    scanHome = function()
        if #gg.getSelectedListItems() == 1 then
            current_class = gg.getSelectedListItems()[1].name
            il2cppFields.scanning = false
            il2cppFields.home(current_class:gsub(".+Class: (.+)\nField.+", "%1"))
        else
            local menu_items = {}
            menu_items[1] = "🔍 Scan/Rescan For Classes"
            if class_list then
                menu_items[2] = "🔄 Reload Class List"
                menu_items[3] = "🔎 Search Class List"
            end
            if search_list then
                menu_items[4] = "🔄 Reload Last Search Result"
            end
            menu_items[#menu_items + 1] = "🏠 Back"
            local menu = gg.choice(menu_items, nil, script_title .. "\n\nℹ️ Class Scanner ℹ️")
            if menu ~= nil then
                if menu == 1 then
                    gg.clearList()
                    il2cppFields.scan()
                end
                if menu == 2 and (#menu_items == 4 or #menu_items == 5) then
                    gg.clearList()
                    gg.addListItems(class_list)
                elseif menu == 2 then
                    il2cppFields.scanning = false
                    il2cppFields.home()
                end
            end
            if menu == 3 then
                il2cppFields.search()
            end
            if menu == 4 and #menu_items == 5 then
                gg.clearList()
                gg.addListItems(search_list)
            elseif menu == 4 then
                il2cppFields.scanning = false
                il2cppFields.home()
            end
            if menu == 5 then
                il2cppFields.scanning = false
                il2cppFields.home()
            end
        end
    end
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
