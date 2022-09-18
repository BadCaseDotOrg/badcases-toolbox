classFieldSearcher = {
    --[[
	---------------------------------------
	
	classFieldSearcher.home()
	
	---------------------------------------
	]] --
    home = function()
        local start_address = gg.getResults(1)
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)
        gg.loadResults(store_val)

        gg.searchPointer(1000)
        local pointers_to = gg.getResults(gg.getResultsCount())
        local field_offset = 0x0
        for i, v in pairs(pointers_to) do
            pointers_to[i].address = v.value
        end
        table.insert(pointers_to, start_address[1])
        gg.loadResults(pointers_to)

        os.exit()
        local pointers_to = gg.getResults(gg.getResultsCount())
        for i, v in pairs(pointers_to) do
            if v.address == start_address[1].address then
                local class_pointer = {pointers_to[i - 1]}
                field_offset = hex_o(pointers_to[i].address - pointers_to[i - 1].address)
                gg.loadResults(class_pointer)
                break
            end
        end
        local class_pointer = gg.getResults(1)

        local class_name_pointer = {}
        class_name_pointer[1] = {}
        class_name_pointer[1].address = class_pointer[1].value + Il2Cpp.ClassApiNameOffset
        class_name_pointer[1].flags = flag_type
        local class_name_address = gg.getValues(class_name_pointer)
        class_name_address = class_name_address[1].value
        get_class_name = {}
        offset = 0
        for i = 1, 100 do
            get_class_name[i] = {}
            get_class_name[i].address = class_name_address + offset
            get_class_name[i].flags = gg.TYPE_BYTE
            offset = offset + 1
        end
        get_class_name = gg.getValues(get_class_name)
        class_name = ""
        for index, value in pairs(get_class_name) do
            if value.value > 0 and value.value <= 255 then
                class_name = class_name .. string.char(value.value)
            end
            if value.value == 0 then
                break
            end
        end
        local fields_pointer = {}
        fields_pointer[1] = {}
        fields_pointer[1].address = class_pointer[1].value + Il2Cpp.ClassApiFieldsLink
        fields_pointer[1].flags = flag_type
        local fields_pointer_address = gg.getValues(fields_pointer)

        local fields_start = {}
        fields_start[1] = {}
        fields_start[1].address = fields_pointer_address[1].value
        fields_start[1].flags = gg.TYPE_DWORD
        gg.loadResults(fields_start)
        fields_start = gg.getResults(1)
        gg.clearResults()
        local try_x_count = 0
        ::try_x::
        gg.searchNumber(tonumber(field_offset), gg.TYPE_DWORD, false, gg.SIGN_EQUAL, fields_start[1].address, fields_start[1].address + 1000, 1)
        local field_found = gg.getResults(1)

        if gg.getResultsCount() == 0 then
            if try_x_count < 2 then
                try_x_count = try_x_count + 1
                field_offset = hex_o(tonumber(field_offset) - 4)
                goto try_x
            end
        end
        local field_name_pointer = {}
        field_name_pointer[1] = {}

        field_name_pointer[1].address = field_found[1].address - Il2Cpp.FieldApiOffset
        field_name_pointer[1].flags = gg.TYPE_DWORD
        field_name_pointer = gg.getValues(field_name_pointer)
        get_field_name = {}
        offset = 0
        for i = 1, 100 do
            get_field_name[i] = {}
            get_field_name[i].address = field_name_pointer[1].value + offset
            get_field_name[i].flags = gg.TYPE_BYTE
            offset = offset + 1
        end
        get_field_name = gg.getValues(get_field_name)
        field_name = ""
        for index, value in pairs(get_field_name) do
            if value.value > 0 and value.value <= 255 then
                field_name = field_name .. string.char(value.value)
            end
            if value.value == 0 then
                break
            end
        end
        gg.loadResults(start_address)
        ::dowith::
        local menu = gg.choice({"Copy Field Info", "Send To Il2Cpp Fields Plugin"}, nil, script_title .. "\n\nℹ️ Class/Field search result. ℹ️\nClass Name: " .. class_name .. "\nField Name: " .. field_name .. "\nField Offset: " .. field_offset)
        if menu == nil then
            goto dowith
        else
            if menu == 1 then
                gg.copyText("Class Name: " .. class_name .. "\nField Name: " .. field_name .. "\nField Offset: " .. field_offset)
            end
            if menu == 2 then
                pluginManager.defaultHandler("class_results", class_name)
            end
        end
    end
}
store_val = gg.getResults(1)
Il2Cpp.scriptSettings = {false, false, false, false, false, false, false, false}
Il2Cpp.setAPIVariables()
gg.loadResults(store_val)
classFieldSearcher.home()
