gg.clearList()
il2cppFields = {
    savePath = pluginsDataPath .. "badcase_il2cpp_fields_data/",
    --    il2cppFields.checkConfigFileGame()
    checkConfigFileGame = function()
        dofile(il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. ".cfg")
    end,
    --    il2cppFields.saveConfig()
    saveConfig = function()
        bc.saveTable("il2cppFields.savedEditsTable", il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. ".cfg")
    end,
    --    il2cppFields.checkMethodTypes()
    checkMethodTypes = function()
        dofile(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    f_hex = function(n)
        return "0x" .. string.format("%x", n)
    end,
    saveTypes = function()
        Il2Cpp.saveTypes(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
    end,
    checkDumpedFields = function()
        dofile(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_fields.lua")
    end,
    saveDumpedFields = function()
        bc.saveTable("Il2Cpp.dumpTable", il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_fields.lua")
    end,
    --    il2cppFields.loadFields(class, continue)
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
            class_string_search = gg.prompt({bc.Prompt("Enter Class Name", "ℹ️")}, {class}, {"text"})
        end
        if class_string_search ~= nil or continue == true then
            if continue == true then
            else
                working_class = class_string_search[1]
                gg.setRanges(gg.REGION_OTHER)
                gg.clearResults()
                gg.searchNumber(Il2Cpp.createSearch(class_string_search[1]), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
                string_address = gg.getResults(1, 1)
            end
            if gg.getResultsCount() > 0 or continue == true then
                if continue == true then
                    goto do_more
                end
                string_address = string_address[1].address
                gg.clearResults()
                -- gg.setRanges(gg.REGION_C_ALLOC)
                gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
                gg.searchNumber(string_address, flag_type)
                class_headers = gg.getResults(gg.getResultsCount())
                for i, v in pairs(class_headers) do
                    class_headers[i].address = class_headers[i].address - Il2Cpp.ClassApiNameOffset
                end
                gg.clearResults()
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
                    namespace_string_address[1].address = v.class_address + Il2Cpp.ClassApiNameSpaceOffset
                    namespace_string_address[1].flags = flag_type
                    namespace_string_address = gg.getValues(namespace_string_address)
                    namespace_name = Il2Cpp.getString(namespace_string_address[1].value)
                    namespace_names[i] = namespace_name .. " Pointers(" .. found_classes_sorted[i].pointers_to .. ")"
                    found_classes_sorted[i].namespace = namespace_name
                end
                ::pick_ns::
                choose_namespace = gg.choice(namespace_names, nil, bc.Choice("Select Namespace", "If the class you want has no active instances then got to a place in the game the values would be used and try again.", "ℹ️"))
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
                    field_count[1].address = class_header + Il2Cpp.ClassApiCountFields
                    field_count[1].flags = gg.TYPE_DWORD
                    field_count = gg.getValues(field_count)
                    field_count = field_count[1].value
                    local fields_pointer = {}
                    fields_pointer[1] = {}
                    fields_pointer[1].address = class_header + Il2Cpp.ClassApiFieldsLink
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
                    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
                    -- gg.setRanges(gg.REGION_C_ALLOC)
                    local getall
                    for i = 1, field_count do
                        local field_name_pointer = {}
                        field_name_pointer[1] = {}
                        field_name_pointer[1].address = fields_start + offset
                        field_name_pointer[1].flags = flag_type
                        field_name_pointer = gg.getValues(field_name_pointer)
                        local field_type = ""
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
                            if Il2Cpp.method_types[tostring(final_type)] then
                                field_type = Il2Cpp.method_types[tostring(final_type)]
                            else
                                field_type = tostring(final_type)
                            end
                        end
                        local field_offset = {}
                        field_offset[1] = {}
                        field_offset[1].address = field_name_pointer[1].address + Il2Cpp.FieldApiOffset
                        field_offset[1].flags = gg.TYPE_DWORD
                        field_offset = gg.getValues(field_offset)
                        field_offset = field_offset[1].value
                        offset = offset + Il2Cpp.ClassApiFieldsStep
                        local field_name = Il2Cpp.getString(field_name_pointer[1].value)
                        if Il2Cpp.method_types[tostring(field_type)] == "Single" then
                            value_type = gg.TYPE_FLOAT
                        elseif Il2Cpp.method_types[tostring(field_type)] == "Double" then
                            value_type = gg.TYPE_DOUBLE
                        elseif (field_offset % 2 ~= 0) then
                            value_type = gg.TYPE_BYTE
                        else
                            value_type = gg.TYPE_DWORD
                        end
                        local ask_type = false
                        if Il2Cpp.method_types[tostring(field_type)] then
                            type_menu = Il2Cpp.method_types[tostring(field_type)]
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
                gg.clearResults()
                gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)
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
                    select_field_menu = gg.choice(select_field_items, nil, bc.Choice(#sorted_instance_headers .. " Instances Found", "Class Name: " .. class_string_search[1], "ℹ️"))
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
                        local type_menu = gg.choice(type_menu_items, nil, bc.Choice("Select Edit Type", "", "ℹ️"))
                        if type_menu == nil then
                            goto pick_type
                        else
                            value_type = gg_types[type_menu]
                            for i, v in pairs(sorted_instance_headers) do
                                load_field_values[i] = v
                                load_field_values[i].address = v.value + tonumber(fields[select_field_menu].field_offset)
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
                bc.Alert("No Class Instances Found", "", "ℹ️")
                select_field_menu = nil
                load_field_values = {}
                none_found = false
            else
                if select_field_menu ~= nil then
                    select_field_menu = nil
                    gg.setVisible(true)
                    bc.Alert(#load_field_values .. " Instances Added To Save List", "", "ℹ️")
                    load_field_values = {}
                end
            end
        end
    end,
    --    il2cppFields.editFields()
    editFields = function()
        local save_list_selected = gg.getSelectedListItems()
        local save_edit_values = {
            class_name = working_class,
            field_name = working_field_name,
            value_type = save_list_selected[1].flags
        }
        local menu_items = {script_title .. "\n\nℹ️ Create Edit ℹ\n" .. il2cppFields.gg_flags[save_list_selected[1].flags] .. " " .. save_list_selected[1].name, "Freeze", "Edit All Instances (Only select one)", "Edit All Instances Address + 4 X4 (Only select one)", "Edit All Instances Address + 8 X8 (Only select one)", "Edit All Instances With Selected Value (Only select one)", "Edit All Instances = To Value Below (Only select one)",
            "Edit All Instances ~= To Value Below (Only select one)", "Edit All Instances <= To Value Below (Only select one)", "Edit All Instances >= To Value Below (Only select one)", "Edit All Instances In Range Below (Only select one)", "Edit All Instances NOT In Range Below (Only select one)", "Enter Number Or Number Range (0~100)"}
        local mF = false
        local cB = "checkbox"
        local menu_values = {save_list_selected[1].value, mF, mF, mF, mF, mF, mF, mF, mF, mF, mF, ""}
        local menu_types = {"number", cB, cB, cB, cB, cB, cB, cB, cB, cB, cB, "number"}
        ::edit_menu::
        local menu = gg.prompt(menu_items, menu_values, menu_types)
        if menu ~= nil then
            local selectedCount = 0
            local emptyInput1 = false
            local emptyInput2 = false
            for i, v in pairs(menu) do
                if i == 1 and v == "" then
                    emptyInput1 = true
                end
                if i > 2 and type(v) == "boolean" and v == true then
                    if i > 5 and menu[#menu] == "" then
                        emptyInput2 = true
                    end
                    selectedCount = selectedCount + 1
                end
            end
            if selectedCount > 1 or emptyInput1 == true or emptyInput2 == true then
                local errorHeader
                local errorMessage
                if selectedCount > 1 then
                    errorHeader = "Too Many Options Selected"
                    errorMessage = "Only select 1 of the options labeled (Only select one)."
                elseif emptyInput1 == true then
                    errorHeader = "Empty Input"
                    errorMessage = "You must enter a value to edit the fields to in the first text input."
                elseif emptyInput2 == true then
                    errorHeader = "Empty Input"
                    errorMessage = "You must enter a value in the second text input for your selected option."
                end
                bc.Alert(errorHeader, errorMessage, "⚠️")
                goto edit_menu
            end
            local editValue = tonumber(menu[1])
            local mustEqual
            if menu[#menu]:find("~") then
                mustEqual = menu[#menu]
            else
                mustEqual = tonumber(menu[#menu])
            end
            if menu[2] == true then -- Freeze
                save_edit_values.freeze = true
            else
                save_edit_values.freeze = false
            end
            if menu[3] == true then -- Edit All Instances (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].value = editValue
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all"
                save_edit_values.edit_value = editValue
            end
            if menu[4] == true then -- Edit All Instances Address + 4 X4 (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].address = save_list_all[i].address + 4
                    if editValue == 0 then
                        save_list_all[i].value = save_list_all[i].value
                    else
                        save_list_all[i].value = editValue .. "X4"
                    end
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.setValues(save_list_all)
                save_edit_values.edit_type = "edit_all_x4"
                save_edit_values.edit_value = editValue
            end
            if menu[4] == true then -- Edit All Instances Address + 8 X8 (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    save_list_all[i].address = save_list_all[i].address + 8
                    if editValue == 0 then
                        save_list_all[i].value = save_list_all[i].value
                    else
                        save_list_all[i].value = editValue .. "X8"
                    end
                    save_list_all[i].freeze = save_edit_values.freeze
                end
                gg.setValues(save_list_all)
                save_edit_values.edit_type = "edit_all_x8"
                save_edit_values.edit_value = editValue
            end
            if menu[6] == true then -- Edit All Instances With Selected Value (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value == save_list_selected[1].value then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_equal"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = save_list_selected[1].value
            end
            if menu[7] == true then -- Edit All Instances = To Value Below (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value == mustEqual then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_equal"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            if menu[8] == true then -- Edit All Instances ~= To Value Below (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value ~= mustEqual then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_that_do_not_equal"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            if menu[9] == true then -- Edit All Instances <= To Value Below (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value <= mustEqual then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_less_equal"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            if menu[10] == true then -- Edit All Instances >= To Value Below (Only select one)
                local save_list_all = gg.getListItems()
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value >= mustEqual then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_greater_equal"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            if menu[11] == true then -- Edit All Instances In Range Below (Only select one)
                local save_list_all = gg.getListItems()
                local minValue = tonumber(menu[#menu]:gsub("(.+)~.+", "%1"))
                local maxValue = tonumber(menu[#menu]:gsub(".+~(.+)", "%1"))
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value >= minValue and save_list_all[i].value <= maxValue then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_in_range"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            if menu[12] == true then -- Edit All Instances NOT In Range Below (Only select one)
                local save_list_all = gg.getListItems()
                local minValue = tonumber(menu[#menu]:gsub("(.+)~.+", "%1"))
                local maxValue = tonumber(menu[#menu]:gsub(".+~(.+)", "%1"))
                for i, v in pairs(save_list_all) do
                    if save_list_all[i].value < minValue or save_list_all[i].value > maxValue then
                        save_list_all[i].value = editValue
                        save_list_all[i].freeze = save_edit_values.freeze
                    end
                end
                gg.setValues(save_list_all)
                gg.addListItems(save_list_all)
                save_edit_values.edit_type = "edit_all_not_in_range"
                save_edit_values.edit_value = editValue
                save_edit_values.must_equal = mustEqual
            end
            save_edit_values.edit_namespace = edit_namespace
            ::enter_name::
            local name_edit = gg.prompt({bc.Prompt("Enter Name For Edit", "ℹ️")}, {save_edit_values.field_name}, {"text"})
            if name_edit == nil then
                goto enter_name
            end
            save_edit_values.edit_name = name_edit[1]
            il2cppFields.savedEditsTable[#il2cppFields.savedEditsTable + 1] = save_edit_values
            making_edit = true
            bc.Alert("Value Has Been Set", "Test to verify it is working and then press the floating GG button to either Save or Discard edit.", "ℹ️")
        end
    end,
    --    il2cppFields.doSavedEdit(saved_edit_table)
    doSavedEdit = function(saved_edit_table)
        local header_offset
        if arch.x64 then
            header_offset = 16
        else
            header_offset = 8
        end
        gg.clearList()
        local class_name = saved_edit_table.class_name
        local field_name = saved_edit_table.field_name
        local namespace_name = saved_edit_table.edit_namespace
        gg.setRanges(gg.REGION_OTHER)
        gg.clearResults()
        gg.searchNumber(Il2Cpp.createSearch(class_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
        local class_string = gg.getResults(1, 1)
        local namespace_string
        if namespace_name ~= "" then
            gg.clearResults()
            gg.searchNumber(Il2Cpp.createSearch(namespace_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
            namespace_string = gg.getResults(1, 1)
            namespace_string = Il2Cpp.ggHex(namespace_string[1].address, false)
        else
            if Il2Cpp.getString(range_start - 55) == "NULL" then
                namespace_string = Il2Cpp.ggHex(range_start - 56, false)
            else
                namespace_string = Il2Cpp.ggHex(range_start - 19, false)
            end
        end
        gg.clearResults()
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        gg.searchNumber(Il2Cpp.ggHex(class_string[1].address, false) .. ";" .. namespace_string .. "::9", flag_type)
        local results = gg.getResults(1)
        local class_header = results[1].address - header_offset
        local field_count = {{
            address = class_header + Il2Cpp.ClassApiCountFields,
            flags = gg.TYPE_DWORD
        }}
        field_count = gg.getValues(field_count)
        field_count = field_count[1].value
        local field_pointer = {{
            address = class_header + Il2Cpp.ClassApiFieldsLink,
            flags = flag_type
        }}
        field_pointer = gg.getValues(field_pointer)
        field_pointer = Il2Cpp.ggHex(field_pointer[1].value)
        local correct_field
        for i = 1, field_count do
            local checkString = {{
                address = field_pointer,
                flags = flag_type
            }}
            checkString = gg.getValues(checkString)
            checkString = Il2Cpp.getString(checkString[1].value)
            if field_name == checkString then
                correct_field = field_pointer
                break
            end
            field_pointer = field_pointer + Il2Cpp.ClassApiFieldsStep
        end
        local field_offset = {{
            address = correct_field + Il2Cpp.FieldApiOffset,
            flags = gg.TYPE_DWORD
        }}
        field_offset = gg.getValues(field_offset)
        field_offset = field_offset[1].value
        gg.clearResults()
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchNumber(class_header, flag_type)
        local results = gg.getResults(gg.getResultsCount())
        load_field_values = {}
        local value_type = saved_edit_table.value_type
        for i, v in pairs(results) do
            load_field_values[i] = v
            load_field_values[i].address = v.address + field_offset
            load_field_values[i].flags = value_type
        end
        gg.addListItems(load_field_values)
        if saved_edit_table.edit_type == "edit_all_x4" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].address = save_list_all[i].address + 4
                if tonumber(saved_edit_table.edit_value) == 0 then
                    save_list_all[i].value = save_list_all[i].value
                else
                    save_list_all[i].value = saved_edit_table.edit_value .. "X4"
                end
                save_list_all[i].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_x8" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].address = save_list_all[i].address + 8
                if tonumber(saved_edit_table.edit_value) == 0 then
                    save_list_all[i].value = save_list_all[i].value
                else
                    save_list_all[i].value = saved_edit_table.edit_value .. "X8"
                end
                save_list_all[i].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_indexes" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(saved_edit_table.edit_indexes) do
                save_list_all[v].value = saved_edit_table.edit_value
                save_list_all[v].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_that_equal" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if v.value == saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all" then
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                save_list_all[i].value = saved_edit_table.edit_value
                save_list_all[i].freeze = saved_edit_table.freeze
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_that_do_not_equal" then -- Edit All Instances ~= To Value Below (Only select one)
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if save_list_all[i].value ~= saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_less_equal" then -- Edit All Instances <= To Value Below (Only select one)
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if save_list_all[i].value <= saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_greater_equal" then -- Edit All Instances >= To Value Below (Only select one)
            local save_list_all = gg.getListItems()
            for i, v in pairs(save_list_all) do
                if save_list_all[i].value >= saved_edit_table.must_equal then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_in_range" then -- Edit All Instances In Range Below (Only select one)
            local save_list_all = gg.getListItems()
            local minValue = tonumber(saved_edit_table.must_equal:gsub("(.+)~.+", "%1"))
            local maxValue = tonumber(saved_edit_table.must_equal:gsub(".+~(.+)", "%1"))
            for i, v in pairs(save_list_all) do
                if save_list_all[i].value >= minValue and save_list_all[i].value <= maxValue then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        if saved_edit_table.edit_type == "edit_all_not_in_range" then -- Edit All Instances NOT In Range Below (Only select one)
            local save_list_all = gg.getListItems()
            local minValue = tonumber(saved_edit_table.must_equal:gsub("(.+)~.+", "%1"))
            local maxValue = tonumber(saved_edit_table.must_equal:gsub(".+~(.+)", "%1"))
            for i, v in pairs(save_list_all) do
                if save_list_all[i].value < minValue or save_list_all[i].value > maxValue then
                    save_list_all[i].value = saved_edit_table.edit_value
                    save_list_all[i].freeze = saved_edit_table.freeze
                end
            end
            gg.setValues(save_list_all)
            gg.addListItems(save_list_all)
        end
        fields = {}
        bc.Toast("Edits Made ", "ℹ️")
        il2cppFields.home()
    end,
    --    il2cppFields.deleteEdit()
    deleteEdit = function()
        local menu_names = {}
        for i, v in pairs(il2cppFields.savedEditsTable) do
            menu_names[i] = v.edit_name
        end
        local menu = gg.multiChoice(menu_names, nil, script_title .. "\n\nℹ️ Select Edits To Delete ℹ")
        if menu ~= nil then
            local confirm = gg.choice({"✅ Yes delete the edits", "❌ No"}, nil, bc.Choice("Deleting Edits", "Are you sure you want to delete these edits, this can not be undone? ", "⚠️"))
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
                    bc.Toast("Edits Deleted ", "✅")
                end
            end
        end
    end,
    --    il2cppFields.exportEdits()
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
            local path1 = il2cppFields.savePath .. "/" .. gg.getTargetPackage() .. "_"
            local path2 = os.date()
            local path3 = "_export.json"
            local filePath
            ::path::
            filePath = path1 .. path2 .. path3
            local file = io.open(filePath, "w+")
            if file == nil then
                path2 = os.time()
                goto path
            end
            file:write(json.encode(to_export))
            file:close()
            bc.Alert("Edits Exported", filePath, "✅")
        end
    end,
    --    il2cppFields.importEdits()
    importEdits = function()
        local menu = gg.prompt({bc.Prompt("Select JSON File", "ℹ️")}, {
            [1] = il2cppFields.savePath .. "/"
        }, {
            [1] = "file"
        })
        if menu == nil then
        end
        if menu ~= nil and menu[1]:find("%.json") then
            local import_table = bc.readFile(menu[1], true)
            for i, v in pairs(import_table) do
                il2cppFields.savedEditsTable[#il2cppFields.savedEditsTable + 1] = v
            end
            il2cppFields.saveConfig()
            bc.Toast("Edits Imported ", "✅")
        end
    end,
    --    il2cppFields.home()
    plugin_title = "Plugin: Il2Cpp Fields",
    home = function(passed_data)
        pM.returnHome = true
        pM.returnPluginTable = "il2cppFields"
        if passed_data then
            il2cppFields.loadFields(passed_data)
        elseif il2cppFields.scanning == true then
            il2cppFields.scanHome()
        else
            if making_edit == true then
                local menu = gg.choice({"✅ Save Edit", "🗑️ Discard Edit"}, nil, bc.Choice("Testing Edit", "Save or discard the current edit?", "⚠️"))
                if menu ~= nil then
                    if menu == 1 then
                        il2cppFields.saveConfig()
                        making_edit = false
                        bc.Toast("Edit saved ", "✅")
                    end
                    if menu == 2 then
                        table.remove(il2cppFields.savedEditsTable, #il2cppFields.savedEditsTable)
                        making_edit = false
                        bc.Toast("Edit discarded ", "🗑️")
                    end
                    il2cppFields.home()
                end
            end
            if #gg.getSelectedListItems() > 0 then
                il2cppFields.editFields()
            elseif fields and #fields > 0 then
                local menu = gg.choice({"Yes", "No"}, nil, bc.Choice("Editing Fields", "Continue editing fields?", "ℹ️"))
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
                local menu = gg.choice(menu_items, nil, bc.Choice(il2cppFields.plugin_title, "", "ℹ️"))
                if menu ~= nil then
                    if menu < #menu_items - 7 then
                        il2cppFields.doSavedEdit(il2cppFields.savedEditsTable[menu])
                    end
                    if menu == #menu_items - 7 then
                        il2cppFields.loadFields()
                    end
                    if menu == #menu_items - 6 then
                        pM.callPlugin(pluginsDataPath .. "plugin_bc_dump_search.lua")
                        il2cppFields.home()
                    end
                    if menu == #menu_items - 5 then
                        il2cppFields.scanHome()
                        il2cppFields.scanning = true
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
                        Il2Cpp.dumpTable = nil
                        pM.returnHome = false
                    end
                end
            end
        end
    end,
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
    cleanOldStrings = function()
        for i, v in pairs(il2cppFields.savedEditsTable) do
            il2cppFields.savedEditsTable[i].class_name = v.class_name:gsub(string.char(0), "")
            il2cppFields.savedEditsTable[i].field_name = v.field_name:gsub(string.char(0), "")
            il2cppFields.savedEditsTable[i].edit_namespace = v.edit_namespace:gsub(string.char(0), "")
        end
    end,
    setup = function()
        if il2cppFields.arch.x64 then
            flag_type = gg.TYPE_QWORD
            ARM = "ARM8"
        else
            flag_type = gg.TYPE_DWORD
            ARM = "ARM7"
        end
        if pcall(il2cppFields.checkConfigFileGame) == false then
            bc.createDirectory(il2cppFields.savePath)
            il2cppFields.savedEditsTable = {}
            il2cppFields.saveConfig()
        else
            il2cppFields.cleanOldStrings()
        end
        pcall(il2cppFields.checkMethodTypes)
        Il2Cpp.scriptSettings = {false, false, false, false, false, false, false, false}
        ::set_settings::
        local settingsMenu = gg.prompt({"Filter Class Results (Faster Class Scan)", "Re-Dump Fields and Types", "Manually Select Unity Build", "Alternate Get Strings (If Freezes At Start)", "Debug", "Custom Unity Build"}, {true, false, false, false, false, false}, {"checkbox", "checkbox", "checkbox", "checkbox", "checkbox", "checkbox"})
        if settingsMenu == nil then
            goto set_settings
        else
            if settingsMenu[1] == true then
                Il2Cpp.scriptSettings[4] = true
            end
            if settingsMenu[2] == true then
                if pcall(il2cppFields.checkMethodTypes) == true then
                    os.remove(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_method_types.lua")
                    Il2Cpp.method_types = nil
                end
                if pcall(il2cppFields.checkDumpedFields) == true then
                    os.remove(il2cppFields.savePath .. gg.getTargetPackage() .. "_" .. gg.getTargetInfo().versionCode .. "_fields.lua")
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
            if settingsMenu[6] == true then
                Il2Cpp.scriptSettings[9] = true
            end
        end
        Il2Cpp.configureScript(Il2Cpp.scriptSettings)
        if not Il2Cpp.method_types then
            ::menu2::
            local menu = gg.choice({"Yes (SLOW)", "No (Faster)"}, nil, bc.Choice("Getting Fields", "Do you want to try and get additional field types from memory? All fields will be retrieved regardless. ", "ℹ️"))
            if menu == nil then
                goto menu2
            else
                if menu == 1 then
                    gg.clearResults()
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
                    il2cppFields.saveTypes()
                end
                if menu == 2 then
                    Il2Cpp.getMethodTypes()
                    il2cppFields.saveTypes()
                end
            end
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
    current_fields = {},
    retrieved_field_types = {},
    load_instance_values = function(address, offset, field_type, field_name, current_class)
        local gg_flags = {
            ["Char"] = gg.TYPE_BYTE,
            ["Byte"] = gg.TYPE_BYTE,
            ["SByte"] = gg.TYPE_BYTE,
            ["Double"] = gg.TYPE_DOUBLE,
            ["Int16"] = gg.TYPE_DWORD,
            ["Int32"] = gg.TYPE_DWORD,
            ["Int64"] = gg.TYPE_DWORD,
            ["UInt16"] = gg.TYPE_DWORD,
            ["UInt32"] = gg.TYPE_DWORD,
            ["UInt64"] = gg.TYPE_DWORD,
            ["Single"] = gg.TYPE_FLOAT
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
        local menu = gg.prompt({"Search Term", "Additional Search Term", "Case Sensitive", "Class Names", "Field Names", "Field Types", "Image Names", "Namespace Names", "Parent Class Names"}, {"", "", true, true, true, true, true, true, true}, {"text", "text", "checkbox", "checkbox", "checkbox", "checkbox", "checkbox", "checkbox", "checkbox"})
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
                                if v.fields then
                                    for index, value in pairs(v.fields) do
                                        local class_value
                                        if ind == 5 then
                                            class_value = value.field_name
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
                                            class_value = tostring(value.field_type)
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

                                if class_vals[ind] then
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
    scanHome = function()
        if #gg.getSelectedListItems() == 1 then
            current_class = gg.getSelectedListItems()[1].name
            il2cppFields.scanning = false
            il2cppFields.home(current_class:gsub(".+class.. . .(.+).,.+class_header.+", "%1"))
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
                    pcall(il2cppFields.checkDumpedFields)
                end
                if menu == 1 and not Il2Cpp.dumpTable then
                    gg.clearList()
                    Il2Cpp.scriptSettings[1] = true
                    Il2Cpp.scan()
                    il2cppFields.saveDumpedFields()
                    il2cppFields.scanHome()
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
                    il2cppFields.search()
                end
                if menu == 3 and #menu_items == 4 then
                    gg.clearList()
                    gg.addListItems(search_list)
                end
                if menu == #menu_items then
                    il2cppFields.scanning = false
                    il2cppFields.home()
                end
            end
        end
    end,
    --    il2cppFields.about()
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
    end
}

il2cppFields.setup()
gg.clearList()

pM.returnHome = true
pM.returnPluginTable = "il2cppFields"
bc.Alert("Plugin Loaded", "if launched directly press the floating [Sx] button to open the menu.", "ℹ️")
