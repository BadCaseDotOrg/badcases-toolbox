scriptCreator = {
    --[[
	---------------------------------------
	
	scriptCreator.home()
	
	---------------------------------------
	]] --
    home = function()
        local menu = gg.choice({"🆕 Create Script Function", 
								"➕ Add Edit To Function",
                                "➖ Remove Edit From Function", 
								"☰ Menu Editor", 
								"🔤 Set Script Title",
                                "💾 Export script", 
								"❌ Exit"}, 
								nil,
								script_title .. "\n\nℹ️ Script Creator ℹ️")
        if menu ~= nil then
            if menu == 1 then
                scriptCreator.createFunction()
                scriptCreator.home()
            end
            if menu == 2 then
                scriptCreator.addEditToFunction()
                scriptCreator.home()
            end
            if menu == 3 then
                scriptCreator.removeEditFromFunction()
                scriptCreator.home()
            end
            if menu == 4 then
                scriptCreator.menuEditor()
                scriptCreator.home()
            end
            if menu == 5 then
                scriptCreator.nameScript()
                scriptCreator.home()
            end
            if menu == 6 then
                scriptCreator.exportScript()
            end
            if menu == 7 then
                pluginManager.returnHome = false
            end
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.nameScript()
	
	---------------------------------------
	]] --
    nameScript = function()
        local menu = gg.prompt({script_title .. "\n\nℹ️ Enter a title for your script. ℹ️"}, nil, {"text"})
        if menu ~= nil then
            scriptCreator.scriptName = menu[1]
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.createFunction()
	
	---------------------------------------
	]] --
    createFunction = function()
        local menu_items = scriptCreator.getEditsMenu()
        if #menu_items > 0 then
            local menu = gg.multiChoice(menu_items)
            if menu ~= nil then
                local functionEdits = {}
                for k, v in pairs(menu) do
                    functionEdits[#functionEdits + 1] = scriptCreator.allEdits[k]
                end
                local nameMenu = gg.prompt({script_title .. "\n\nℹ️ Enter a name for your function. ℹ️"}, nil, {"text"})
                if nameMenu then
                    scriptCreator.scriptFunctions[#scriptCreator.scriptFunctions + 1] = {
                        menu_name = nameMenu[1],
                        edits = functionEdits
                    }
                    gg.toast(script_title .. "\n\nℹ️ Function Created ℹ️")
                end
            end
        else
            gg.alert(script_title .. "\n\nℹ️ Load the plugins you want to create your script from first. ℹ️")
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.addEditToFunction()
	
	---------------------------------------
	]] --
    addEditToFunction = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil,
            script_title .. "\n\nℹ️ Select function to add edit to. ℹ️")
        if menu ~= nil then
            local editsMenu = gg.multiChoice(scriptCreator.getEditsMenu())
            if editsMenu ~= nil then
                for k, v in pairs(editsMenu) do
                    scriptCreator.scriptFunctions[menu].edits[#scriptCreator.scriptFunctions[menu].edits + 1] = scriptCreator.allEdits[k]
                end
                gg.toast(script_title .. "\n\nℹ️ Edit Added To Function ℹ️")
            end
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.removeEditFromFunction()
	
	---------------------------------------
	]] --
    removeEditFromFunction = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil,
            script_title .. "\n\nℹ️ Select function to remove edit from. ℹ️")
        if menu ~= nil then
            local functionEdits = {}
            for i, v in pairs(scriptCreator.scriptFunctions[menu].edits) do
                functionEdits[i] = v.edit_name
            end
            local editMenu = gg.choice(functionEdits, nil,
                script_title .. "\n\nℹ️ Select edit to remove from function. ℹ️")
            if editMenu ~= nil then
                table.remove(scriptCreator.scriptFunctions[menu].edits, editMenu)
                gg.toast(script_title .. "\n\nℹ️ Edit Removed From Function ℹ️")
            end
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.getEditsMenu()
	
	---------------------------------------
	]] --
    getEditsMenu = function()
        scriptCreator.allEdits = {}
        local menuNames = {}
        if il2cppEdits then
            for i, v in pairs(il2cppEdits.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v
                menuNames[#menuNames + 1] = v.edit_name .. "(method edit)"
            end
        end
        if il2cppFields then
            for i, v in pairs(il2cppFields.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v
                menuNames[#menuNames + 1] = v.edit_name .. "(field edit)"
            end
        end
        if staticValueFinder and #staticValueFinder.savedEditsTable > 0 then
            for i, v in pairs(staticValueFinder.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v.edit_table
                menuNames[#menuNames + 1] = v.edit_table.edit_name .. "(static value search edit)"
            end
        end
        return menuNames
    end,
    --[[
	---------------------------------------
	
	scriptCreator.allEdits()
	
	---------------------------------------
	]] --
    allEdits = {},
    scriptFunctions = {},
    getFunctionsMenu = function()
        local menuNames = {}
        for i, v in pairs(scriptCreator.scriptFunctions) do
            menuNames[#menuNames + 1] = v.menu_name
        end
        return menuNames
    end,
    --[[
	---------------------------------------
	
	scriptCreator.menuEditorRemove()
	
	---------------------------------------
	]] --
    menuEditorRemove = function(current_index)
        ::confirm::
        local confirm_menu = gg.choice({"✅ Yes (Delete function)", "❌ No get me out of here."}, nil, script_title .. "\n\n⚠️ Warning ⚠️\n\nYou are about to delete this function from your script.\n\nDo you wish to continue?")
        if confirm_menu == nil then
            goto confirm
        else
            if confirm_menu == 1 then
                table.remove(scriptCreator.scriptFunctions, current_index)
                gg.toast(script_title .. "\n\nℹ️ Function Deleted ℹ️")
            end
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.menuEditorMoveUp()
	
	---------------------------------------
	]] --
    menuEditorMoveUp = function(current_index)
        local temp_index = #scriptCreator.scriptFunctions + 2
        scriptCreator.scriptFunctions[temp_index] = scriptCreator.scriptFunctions[current_index - 1]
        scriptCreator.scriptFunctions[current_index - 1] = scriptCreator.scriptFunctions[current_index]
        scriptCreator.scriptFunctions[current_index] = scriptCreator.scriptFunctions[temp_index]
        scriptCreator.scriptFunctions[temp_index] = nil
    end,
    --[[
	---------------------------------------
	
	scriptCreator.menuEditorMoveDown()
	
	---------------------------------------
	]] --
    menuEditorMoveDown = function(current_index)
        local temp_index = #scriptCreator.scriptFunctions + 2
        scriptCreator.scriptFunctions[temp_index] = scriptCreator.scriptFunctions[current_index + 1]
        scriptCreator.scriptFunctions[current_index + 1] = scriptCreator.scriptFunctions[current_index]
        scriptCreator.scriptFunctions[current_index] = scriptCreator.scriptFunctions[temp_index]
        scriptCreator.scriptFunctions[temp_index] = nil
    end,
    --[[
	---------------------------------------
	
	scriptCreator.menuEditorRename()
	
	---------------------------------------
	]] --
    menuEditorRename = function(current_index)
        local menu = gg.prompt({script_title .. "\n\nℹ️ Edit Function Name ℹ️"}, {scriptCreator.scriptFunctions[current_index].menu_name}, {"text"})
        if menu ~= nil then
            scriptCreator.scriptFunctions[current_index].menu_name = menu[1]
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.menuEditor()
	
	---------------------------------------
	]] --
    menuEditor = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil,
            script_title .. "\n\nℹ️ Select script menu item. ℹ️")
        if menu ~= nil then
            local doWithMenu = gg.choice({"⬆️ Move Up", 
										  "⬇️ Move Down", 
										  "🗑️ Remove Function",
                                          "📝 Edit Function Name", 
										  "🔙 Back To Menu Editor"}, 
										  nil, 
										  script_title .. "\n\nℹ️ " .. scriptCreator.scriptFunctions[menu].menu_name .. " ℹ️")
            if doWithMenu ~= nil then
                if doWithMenu == 1 then
                    scriptCreator.menuEditorMoveUp(menu)
                    scriptCreator.menuEditor()
                end
                if doWithMenu == 2 then
                    scriptCreator.menuEditorMoveDown(menu)
                    scriptCreator.menuEditor()
                end
                if doWithMenu == 3 then
                    scriptCreator.menuEditorRemove(menu)
                    scriptCreator.menuEditor()
                end
                if doWithMenu == 4 then
                    scriptCreator.menuEditorRename(menu)
                    scriptCreator.menuEditor()
                end
                if doWithMenu == 5 then
                    scriptCreator.menuEditor()
                end
            end
        end
    end,
    --[[
	---------------------------------------
	
	scriptCreator.exportScript(scriptName)
	
	---------------------------------------
	]] --
    exportScript = function(scriptName)
        ::check_name::
        if not scriptCreator.scriptName then
            scriptCreator.nameScript()
            goto check_name
        end
        local scriptExportTable = {
			'script_title = "' .. scriptCreator.scriptName .. '"',
			'scriptFunctions = ' .. tostring(scriptCreator.scriptFunctions), 
			'emojis = {}',
			'for i,v in pairs (scriptFunctions) do', 
			'emojis[i] = "🔘"', 
			'end',
			'revert_table = {}', 
			'arch = gg.getTargetInfo()',
			'stringsStart = "109;115;99;111;114;108;105;98;46;100;108;108;77;111;100;117;108;101::20"',
			'stringsEnd = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12"',
			'function getRange()', 
			'    gg.setRanges(gg.REGION_OTHER)',
			'    gg.setVisible(false)',
			'    gg.toast(script_title .. "\\n\\nℹ️ Configuring Script ℹ️")',
			'    gg.clearResults()', 
			'    ::try_ca::',
			'    gg.searchNumber(stringsStart, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)',
			'    if gg.getResultsCount() == 0 then', 
			'        gg.setRanges(gg.REGION_C_ALLOC)',
			'        goto try_ca', 
			'    end', 
			'    local start_search = gg.getResults(1)',
			'    gg.clearResults()', 
			'    range_start = start_search[1].address',
			'    for i, v in pairs(gg.getRangesList()) do',
			'        if v["start"] < range_start and v["end"] > range_start then',
			'            metadata_end = v["end"]', 
			'            break', 
			'        end', 
			'    end',
			'    gg.searchNumber(stringsEnd, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, nil, 1)',
			'    local end_search = gg.getResults(1)', 
			'    range_end = end_search[1].address',
			'    gg.clearResults()', 
			'end',
			'methodNameEditsFound = {}',
			'activeMethodNameEdits = {}',
			'function setMethodValues(function_index, edit_index)',
			'	 if not range_start then',
			'		 getRange()',
			'	 end',
			'    if revert_table[function_index] and revert_table[function_index][edit_index] and (activeMethodNameEdits[function_index] and activeMethodNameEdits[function_index][edit_index]) then',
			'        gg.setValues(revert_table[function_index][edit_index])',
			'        activeMethodNameEdits[function_index][edit_index] = nil',
			'        gg.toast("❌ " .. scriptFunctions[function_index].menu_name .. " Disabled ❌")',
			'    else',
			'        if not activeMethodNameEdits[function_index] then',
			'            activeMethodNameEdits[function_index] = {}',
			'        end',
			'        activeMethodNameEdits[function_index][edit_index] = true',
			'        if arch.x64 then',
			'            edits_arch = "arm8_edits"',
			'        else',
			'            edits_arch = "arm7_edits"',
			'        end',
			'        local method_name = scriptFunctions[function_index].edits[edit_index].method_name',
			'        local class_name = scriptFunctions[function_index].edits[edit_index].class_name',
			'        local addresses = {}',
			'        if methodNameEditsFound[function_index] and methodNameEditsFound[function_index][edit_index] then',
			'            addresses = methodNameEditsFound[function_index][edit_index]',
			'        else',
			'            addresses = findMethod(method_name, class_name)',
			'        end',
			'        local edits = scriptFunctions[function_index].edits[edit_index][edits_arch]',
			'        for i, v in pairs(addresses) do',
			'            local address_table = {}',
			'            local offset = 0',
			'            local count = 1',
			'            repeat',
			'                address_table[count] = {}',
			'                if methodNameEditsFound[function_index] and methodNameEditsFound[function_index][edit_index] then',
			'                    address_table[count].address = v.address',
			'                else',
			'                    address_table[count].address = v + offset',
			'                end',
			'                address_table[count].flags = gg.TYPE_DWORD',
			'                address_table[count].value = edits[count]',
			'                offset = offset + 4',
			'                count = count + 1',
			'            until (count == #edits + 1)',
			'            if not revert_table[function_index] then',
			'                revert_table[function_index] = {}',
			'            end',
			'            if not methodNameEditsFound[function_index] then',
			'                methodNameEditsFound[function_index] = {}',
			'            end',
			'            if not revert_table[function_index][edit_index] then',
			'                revert_table[function_index][edit_index] = {}',
			'                methodNameEditsFound[function_index][edit_index] = {}',
			'                for i, v in pairs(gg.getValues(address_table)) do',
			'                    revert_table[function_index][edit_index][#revert_table[function_index][edit_index] + 1] = v',
			'                    methodNameEditsFound[function_index][edit_index][#methodNameEditsFound[function_index][edit_index] + 1] = v',
			'                end',
			'            end',
			'            gg.setValues(address_table)',
			'        end',
			'        gg.toast("✅ " .. scriptFunctions[function_index].menu_name .. " Enabled ✅")',
			'    end',
			'end',
			'function home()', 
			'    local menuNames = {}',
			'    for i, v in pairs(scriptFunctions) do',
			'        menuNames[i] = emojis[i].." ".. v.menu_name', 
			'    end',
			'    menuNames[#menuNames +1] = "❌ Exit"',
			'    local menu = gg.choice(menuNames,nil,script_title)', 
			'    if menu ~= nil then',
			'        if menu == #menuNames then', 
			'            os.exit()', 
			'        else',
			'            setValues(menu)', 
			'        end', 
			'    end', 
			'end',
			'function setValues(function_index)', 
			'    if emojis[function_index] == "🔘" then',
			'        emojis[function_index] = "✅" ', 
			'    else',
			'        emojis[function_index] = "🔘" ', 
			'    end',
			'    for i, v in pairs(scriptFunctions[function_index].edits) do',
			'        if v.method_name then', 
			'            setMethodValues(function_index, i)',
			'        elseif v.field_name then',
			'            setFieldValues(v,function_index, i)', 
			'        else',
			'            setSVFValues(v,function_index, i)', 
			'        end', 
			'    end', 
			'end',
			'function findMethod(method_name, passed_class_name)', 
			'    if arch.x64 then',
			'        p_offset = 16', 
			'        p_offset2 = 8',
			'        flag_type = gg.TYPE_QWORD', 
			'    else', 
			'        p_offset = 8',
			'        p_offset2 = 4', 
			'        flag_type = gg.TYPE_DWORD', 
			'    end',
			'    method_name_address = searchDump(method_name)', 
			'    gg.clearResults()',
			'    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_HEAP)',
			'    gg.searchNumber(method_name_address, flag_type)',
			'    local results = gg.getResults(gg.getResultsCount())',
			'    local methods_found = {}', 
			'    local il2cpp_addresses = {}',
			'    for i, v in pairs(results) do', 
			'        local get_class_pointer_1 = {}',
			'        get_class_pointer_1[1] = {}',
			'        get_class_pointer_1[1].address = v.address + p_offset2',
			'        get_class_pointer_1[1].flags = flag_type',
			'        get_class_pointer_1 = gg.getValues(get_class_pointer_1)',
			'        local get_class_pointer_2 = {}', 
			'        get_class_pointer_2[1] = {}',
			'        get_class_pointer_2[1].address = get_class_pointer_1[1].value + p_offset',
			'        get_class_pointer_2[1].flags = flag_type',
			'        get_class_pointer_2 = gg.getValues(get_class_pointer_2)',
			'        local get_class_start = {}', 
			'        get_class_start[1] = {}',
			'        get_class_start[1].address = get_class_pointer_2[1].value',
			'        get_class_start[1].flags = gg.TYPE_BYTE',
			'        gg.loadResults(get_class_start)',
			'        get_class_start = gg.getValues(get_class_start)',
			'        local get_class = {}', 
			'        local offset = 0',
			'        local count = 1', 
			'        repeat', 
			'            get_class[count] = {}',
			'            get_class[count].address = get_class_pointer_2[1].value + offset',
			'            get_class[count].flags = gg.TYPE_BYTE', 
			'            count = count + 1',
			'            offset = offset + 1', 
			'        until (count == 100)',
			'        get_class = gg.getValues(get_class)', 
			'        local class_name = ""',
			'        for index, value in pairs(get_class) do',
			'            class_name = class_name .. string.char(value.value)',
			'            if value.value == 0 then', 
			'                break', 
			'            end',
			'        end', 
			'        if class_name == passed_class_name then',
			'            local get_il2cpp_address = {}',
			'            get_il2cpp_address[1] = {}',
			'            get_il2cpp_address[1].address = v.address - p_offset',
			'            get_il2cpp_address[1].flags = flag_type',
			'            get_il2cpp_address = gg.getValues(get_il2cpp_address)',
			'            il2cpp_addresses[#il2cpp_addresses + 1] = get_il2cpp_address[1].value',
			'        end', 
			'    end', 
			'    return il2cpp_addresses', 
			'end',
			'function refineResults(search_string)',
			'    local first_search_string = "0;" .. string.byte(string.sub(search_string, 1, 1)) .. "::2"',
			'    gg.refineNumber(first_search_string, gg.TYPE_BYTE)',
			'    local second_search_string = string.byte(string.sub(search_string, 1, 1))',
			'    gg.refineNumber(second_search_string, gg.TYPE_BYTE)',
			'    local search_results = gg.getResults(gg.getResultsCount())',
			'    return search_results[1].address', 
			'end', 
			'function searchDump(search_string)',
			'    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)', 
			'    if search_string then',
			'        gg.clearResults()',
			'        gg.searchNumber(createSearch(search_string), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)',
			'        if gg.getResultsCount() > 0 then',
			'            return refineResults(search_string)', 
			'        end', 
			'    end', 
			'end',
			'function createSearch(search_string)', 
			'    local byte_search = "0;"',
			'    for c in search_string:gmatch "." do',
			'        byte_search = byte_search .. string.byte(c) .. ";"', 
			'    end',
			'    byte_search = byte_search .. "0::" .. #search_string + 2',
			'    return byte_search', 
			'end', 
			'function f_hex(n)',
			'    return "0x" .. string.format("%x", n)', 
			'end',
			'setFields = {}',
			'function setFieldValues(saved_edit_table, function_index, edit_index)',
			'	 if not range_start then',
			'		 getRange()',
			'	 end',
			'    if not setFields[function_index] then',
			'        setFields[function_index] = {}',
			'        setFields[function_index][edit_index] = false',
			'    elseif setFields[function_index] and not setFields[function_index][edit_index] then',
			'        setFields[function_index][edit_index] = false',
			'    end',
			'    if setFields[function_index][edit_index] == true and revert_table[function_index]',
			'        and revert_table[function_index][edit_index] then',
			'        gg.setValues(revert_table[function_index][edit_index])',
			'        setFields[function_index][edit_index] = false',
			'        gg.toast("❌ " .. scriptFunctions[function_index].menu_name .. " Disabled ❌")',
			'    else',
			'        setFields[function_index][edit_index] = true',
			'        local string_address = {}',
			'        local class_headers = {}',
			'        local get_number_of_fields = {}',
			'        local first_field_address = {}',
			'        local field_data = ""',
			'        local field_name_pointer = ""',
			'        local type_pointer = ""',
			'        local class_pointer = ""',
			'        local field_offset = ""',
			'        local current_address = ""',
			'        local get_field_name = {}',
			'        local offset = 0',
			'        local count = 1',
			'        local field_data = {}',
			'        local field_name = ""',
			'        local get_type = {}',
			'        local field_type = {}',
			'        local pointers_to_instances = {}',
			'        if not class then',
			'            class = ""',
			'        end',
			'        if arch.x64 then',
			'            flag_type = gg.TYPE_QWORD',
			'        else',
			'            flag_type = gg.TYPE_DWORD',
			'        end',
			'        gg.clearList()',
			'        working_class = saved_edit_table.class_name',
			'        gg.setRanges(gg.REGION_OTHER)',
			'        gg.clearResults()',
			'        gg.searchNumber(createSearch(saved_edit_table.class_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)',
			'        string_address = gg.getResults(1, 1)',
			'        if gg.getResultsCount() == 0 then',
			'            none_found = true',
			'            goto none',
			'        end',
			'        string_address = string_address[1].address',
			'        gg.clearResults()',
			'        gg.setRanges(gg.REGION_C_ALLOC)',
			'        gg.searchNumber(string_address, flag_type)',
			'        class_headers = gg.getResults(gg.getResultsCount())',
			'        if gg.getResultsCount() == 0 then',
			'            none_found = true',
			'            goto none',
			'        end',
			'        for i, v in pairs(class_headers) do',
			'            if arch.x64 then',
			'                class_headers[i].address = class_headers[i].address - 16',
			'                namespace_offset = 24',
			'            else',
			'                class_headers[i].address = class_headers[i].address - 8',
			'                namespace_offset = 12',
			'            end',
			'        end',
			'        gg.setRanges(gg.REGION_ANONYMOUS)',
			'        gg.loadResults(class_headers)',
			'        gg.searchPointer(0)',
			'        instance_headers = gg.getResults(gg.getResultsCount())',
			'        found_classes = {}',
			'        for i, v in ipairs(instance_headers) do',
			'            if not found_classes[tostring(v.value)] then',
			'                found_classes[tostring(v.value)] = 0',
			'            else',
			'                found_classes[tostring(v.value)] = found_classes[tostring(v.value)] + 1',
			'            end',
			'        end',
			'        found_classes_sorted = {}',
			'        for k, v in pairs(found_classes) do',
			'            found_classes_sorted[#found_classes_sorted + 1] = {',
			'                class_address = k,',
			'                pointers_to = v',
			'            }',
			'        end',
			'        namespace_names = {}',
			'        for i, v in ipairs(found_classes_sorted) do',
			'            namespace_string_address = {}',
			'            namespace_string_address[1] = {}',
			'            namespace_string_address[1].address = v.class_address + namespace_offset',
			'            namespace_string_address[1].flags = flag_type',
			'            namespace_string_address = gg.getValues(namespace_string_address)',
			'            namespace_string_address = namespace_string_address[1].value',
			'            get_namespace_name = {}',
			'            offset = 0',
			'            count = 1',
			'            repeat',
			'                get_namespace_name[count] = {}',
			'                get_namespace_name[count].address = namespace_string_address + offset',
			'                get_namespace_name[count].flags = gg.TYPE_BYTE',
			'                count = count + 1',
			'                offset = offset + 1',
			'            until (count == 100)',
			'            get_namespace_name = gg.getValues(get_namespace_name)',
			'            namespace_name = ""',
			'            for index, value in pairs(get_namespace_name) do',
			'                if value.value >= 0 and value.value <= 255 then',
			'                    namespace_name = namespace_name .. string.char(value.value)',
			'                end',
			'                if value.value == 0 then',
			'                    break',
			'                end',
			'            end',
			
			'            if namespace_name == saved_edit_table.edit_namespace then',
			'                gg.refineNumber(found_classes_sorted[i].class_address, flag_type)',
			'                instance_headers = gg.getResults(gg.getResultCount())',
			'                break',
			'            end',
			'        end',
			'        if gg.getResultsCount() == 0 then',
			'            none_found = true',
			'            goto none',
			'        end',
			'        class_header = instance_headers[1].value',
			'        first_field_address = {}',
			'        first_field_address[1] = {}',
			'        if arch.x64 then',
			'            first_field_address[1].address = class_header + 0x80',
			'        else',
			'            first_field_address[1].address = class_header + 0x40',
			'        end',
			'        first_field_address[1].flags = flag_type',
			'        first_field_address = gg.getValues(first_field_address)',
			'        first_field_address = first_field_address[1].value',
			'        if arch.x64 then',
			'            get_num_fields_start = first_field_address + 24',
			'            get_num_fields_offset = 32',
			'        else',
			'            get_num_fields_start = first_field_address + 12',
			'            get_num_fields_offset = 20',
			'        end',
			'        num_offset = 0',
			'        num_field_data = {}',
			'        for i = 1, 1000 do',
			'            num_field_data[i] = {}',
			'            num_field_data[i].address = get_num_fields_start + num_offset',
			'            num_field_data[i].flags = gg.TYPE_DWORD',
			'            num_offset = num_offset + get_num_fields_offset',
			'        end',
			'        num_field_data = gg.getValues(num_field_data)',
			'        field_counter = 0',
			'        last_field_offset = 0',
			'        for i, v in pairs(num_field_data) do',
			'            if v.value >= last_field_offset or v.value == 0 then',
			'                if v.value >= last_field_offset then',
			'                    last_field_offset = v.value',
			'                end',
			'                field_counter = field_counter + 1',
			'            else',
			'                break',
			'            end',
			'        end',
			'        field_data = ""',
			'        field_name_pointer = ""',
			'        type_pointer = ""',
			'        class_pointer = ""',
			'        field_offset = ""',
			'        fields = {}',
			'        number_of_fields = field_counter',
			'        current_address = first_field_address',
			'        for i = 1, number_of_fields do',
			'            if arch.x64 then',
			'                field_data = {}',
			'                field_data[1] = {}',
			'                field_data[1].address = current_address',
			'                field_data[1].flags = gg.TYPE_QWORD',
			'                current_address = current_address + 4',
			'                field_data[2] = {}',
			'                field_data[2].address = current_address',
			'                field_data[2].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[3] = {}',
			'                field_data[3].address = current_address',
			'                field_data[3].flags = gg.TYPE_QWORD',
			'                current_address = current_address + 4',
			'                field_data[4] = {}',
			'                field_data[4].address = current_address',
			'                field_data[4].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[5] = {}',
			'                field_data[5].address = current_address',
			'                field_data[5].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[6] = {}',
			'                field_data[6].address = current_address',
			'                field_data[6].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[7] = {}',
			'                field_data[7].address = current_address',
			'                field_data[7].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[8] = {}',
			'                field_data[8].address = current_address',
			'                field_data[8].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data = gg.getValues(field_data)',
			'                field_name_pointer = field_data[1].value',
			'                type_pointer = field_data[3].value',
			'                class_pointer = field_data[5].value',
			'                field_offset = field_data[7].value',
			'            else',
			'                field_data = {}',
			'                field_data[1] = {}',
			'                field_data[1].address = current_address',
			'                field_data[1].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[2] = {}',
			'                field_data[2].address = current_address',
			'                field_data[2].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[3] = {}',
			'                field_data[3].address = current_address',
			'                field_data[3].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[4] = {}',
			'                field_data[4].address = current_address',
			'                field_data[4].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data[5] = {}',
			'                field_data[5].address = current_address',
			'                field_data[5].flags = gg.TYPE_DWORD',
			'                current_address = current_address + 4',
			'                field_data = gg.getValues(field_data)',
			'                field_name_pointer = field_data[1].value',
			'                type_pointer = field_data[2].value',
			'                class_pointer = field_data[3].value',
			'                field_offset = field_data[4].value',
			'            end',
			'            get_field_name = {}',
			'            offset = 0',
			'            count = 1',
			'            repeat',
			'                get_field_name[count] = {}',
			'                get_field_name[count].address = field_name_pointer + offset',
			'                get_field_name[count].flags = gg.TYPE_BYTE',
			'                count = count + 1',
			'                offset = offset + 1',
			'            until (count == 100)',
			'            get_field_name = gg.getValues(get_field_name)',
			'            field_name = ""',
			'            for index, value in pairs(get_field_name) do',
			'                if value.value >= 0 and value.value <= 255 then',
			'                    field_name = field_name .. string.char(value.value)',
			'                end',
			'                if value.value == 0 then',
			'                    break',
			'                end',
			'            end',
			'            get_type = {}',
			'            get_type[1] = {}',
			'            get_type[1].address = type_pointer',
			'            get_type[1].flags = gg.TYPE_DWORD',
			'            field_type = gg.getValues(get_type)',
			'            field_type = field_type[1].value',
			'            value_type = saved_edit_table.value_type',
			'            if value_type and field_offset and string.find(field_name, "[A-Za-z]") then',
			'                type_menu = "?" .. field_type .. "?"',
			'                type_menu = value_type',
			'                fields[#fields + 1] = {',
			'                    field_name = field_name,',
			'                    field_offset = f_hex(field_offset),',
			'                    field_type = value_type,',
			'                    type_menu = type_menu',
			'                }',
			'            end',
			'        end',
			'        gg.loadResults(instance_headers)',
			'        gg.searchPointer(0)',
			'        pointers_to_instances = gg.getResults(gg.getResultsCount())',
			'        sorted_instance_headers = {}',
			'        added_headers = {}',
			'        for i, v in pairs(pointers_to_instances) do',
			'            if not added_headers[v.value] then',
			'                added_headers[v.value] = v.value',
			'                table.insert(sorted_instance_headers, v)',
			'            end',
			'        end',
			'        gg.loadResults(sorted_instance_headers)',
			'        sorted_instance_headers = gg.getResults(gg.getResultsCount())',
			'        for i, v in pairs(fields) do',
			
			'            if saved_edit_table.field_name == v.field_name then',
			'                edit_offset = v.field_offset',
			'                edit_type = v.field_type',
			'                break',
			'            end',
			'        end',
			'        load_field_values = {}',
			'        for i, v in pairs(sorted_instance_headers) do',
			'            load_field_values[i] = v',
			'            load_field_values[i].address = v.value + edit_offset',
			'            load_field_values[i].flags = edit_type',
			'        end',
			'        gg.setValues(load_field_values)',
			'        gg.addListItems(load_field_values)',
			'        if not revert_table[function_index] then',
			'            revert_table[function_index] = {}',
			'        end',
			'        if not revert_table[function_index][edit_index] then',
			'            revert_table[function_index][edit_index] = {}',
			'            for i, v in pairs(gg.getListItems()) do',
			'                revert_table[function_index][edit_index][#revert_table[function_index][edit_index] + 1] = v',
			'            end',
			'        end',
			'        if saved_edit_table.edit_type == "edit_all_x4" then',
			'            local save_list_all = gg.getListItems()',
			'            for i, v in pairs(save_list_all) do',
			'                save_list_all[i].address = save_list_all[i].address + 4',
			'                save_list_all[i].value = saved_edit_table.edit_value .. "X4"',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'            gg.setValues(save_list_all)',
			'            gg.addListItems(save_list_all)',
			'        elseif saved_edit_table.edit_type == "edit_indexes" then',
			'            local save_list_all = gg.getListItems()',
			'            for i, v in pairs(saved_edit_table.edit_indexes) do',
			'                save_list_all[v].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'            gg.setValues(save_list_all)',
			'            gg.addListItems(save_list_all)',
			'        elseif saved_edit_table.edit_type == "edit_all_that_equal" then',
			'            local save_list_all = gg.getListItems()',
			'            for i, v in pairs(save_list_all) do',
			'                if v.value == saved_edit_table.must_equal then',
			'                    save_list_all[i].value = saved_edit_table.edit_value',
			'                    save_list_all[i].freeze = saved_edit_table.freeze',
			'                end',
			'            end',
			'            gg.setValues(save_list_all)',
			'            gg.addListItems(save_list_all)',
			'        elseif saved_edit_table.edit_type == "edit_all" then',
			'            local save_list_all = gg.getListItems()',
			'            for i, v in pairs(save_list_all) do',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'            gg.setValues(save_list_all)',
			'            gg.addListItems(save_list_all)',
			'        end',
			'        fields = {}',
			'        ::none::',
			'        if none_found == true then',
			'            gg.alert(script_title .. "\\n\\nℹ️ No Class Instances Found ℹ️")',
			'            none_found = false',
			'        else',
			'            gg.toast(script_title .. "\\n\\nℹ️ Edits Made ℹ️")',
			'        end',
			'    end',
			'end',
			'function setSVFValues(edit_table,function_index, edit_index)',
			'    local search_table = edit_table.search_table',
			'    local searchFlag = edit_table.flags',
			'    local searchRange = edit_table.search_range',
			'    local offset = edit_table.offset', 
			'    local edit_to = edit_table.edit',
			'    local edit_to_flags = edit_table.edit_flags',
			'    local edit_name = edit_table.edit_name',
			'    local expected_range = edit_table.expected_range',
			'    local freeze = edit_table.freeze', 
			'    local searchString = ""',
			'    for i, v in ipairs(search_table) do', 
			'        if i < #search_table then',
			'            searchString = searchString .. v .. ";"', 
			'        end', 
			'    end',
			'    searchString = searchString .. "::" .. searchRange',
			'    gg.setRanges(gg.getRanges())', 
			'    gg.clearResults()',
			'    gg.searchNumber(searchString, searchFlag)', 
			'    repeat',
			'        table.remove(search_table, #search_table)',
			'        local refineString = ""', 
			'        for i, v in ipairs(search_table) do',
			'            refineString = refineString .. v',
			'            if #search_table > 1 then',
			'                refineString = refineString .. ";"', 
			'            end',
			'        end', 
			'        if #search_table > 1 then',
			'            refineString = refineString .. "::"', 
			'        end',
			'        gg.refineNumber(refineString, searchFlag)',
			'    until (#search_table == 0)',
			'    local results = gg.getResults(gg.getResultsCount())',
			'    for i, v in pairs(results) do',
			'        results[i].address = results[i].address + offset',
			'        results[i].flags = edit_to_flags', 
			'    end', 
			'    gg.loadResults(results)',
			'    if expected_range ~= nil then',
			'        gg.refineNumber(expected_range , edit_to_flags)', 
			'    end',
			'    local results = gg.getResults(gg.getResultsCount())',
			'    for i, v in ipairs(results) do', 
			'        v.value = edit_to',
			'        v.freeze = freeze', 
			'    end', 
			'    if freeze == true then',
			'        gg.addListItems(results)', 
			'    else', 
			'        gg.setValues(results)',
			'    end', 
			'    gg.toast("✅ " .. edit_name .. " ✅")', 
			'end',
			'needToConfigure = false', 
			'for i,v in pairs (scriptFunctions) do',
			'   for index,value in pairs (v.edits) do',
			'       if v.method_name or v.field_name then', 
			'       needToConfigure = true',
			'       end', 
			'   end', 
			'end', 
			'if needToConfigure == true then', 
			'   getRange()',
			'end', 
			'home()',
			'print("⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚")',
			'print("⧚⧚⧚           Script Created With")',
			'print("⧚⧚⧚  🧰  BadCase\'s Toolbox 🧰")', 
			'print("⧚⧚⧚")',
			'print("⧚⧚⧚")', 
			'print("⧚⧚⧚                       Website")',
			'print("⧚⧚⧚                   BadCase.org")', 
			'print("⧚⧚⧚")',
			'print("⧚⧚⧚                Telegram Group")',
			'print("⧚⧚⧚    t.me/BadCaseDotOrgSupport")', 
			'print("⧚⧚⧚")',
			'print("⧚⧚⧚            Donate With PayPal")',
			'print("⧚⧚⧚      paypal.me/BadCaseDotOrg")', 
			'print("⧚⧚⧚")',
			'print("⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚⧚")',
			'while true do', 
			'    if gg.isVisible() then', 
			'        gg.setVisible(false)',
			'        home()', 
			'    end', 
			'    gg.sleep(100)', 
			'end'
		}
        local final_script_string = ""
        for i, v in pairs(scriptExportTable) do
            final_script_string = final_script_string .. v .. "\n"
        end
        dumpHandler.createDirectory()
        file = io.open(dataPath .. game_path .. "/scripts/" .. gg.getTargetPackage() .. "." .. scriptCreator.getTimestamp() .. ".lua", "w+")
        file:write(final_script_string)
        file:close()
        gg.alert(script_title .. "\n\nℹ️ Script exported to " .. dataPath .. game_path .. "/scripts/ ℹ️")
    end,
    --[[
	---------------------------------------
	
	scriptCreator.getTimestamp()
	
	---------------------------------------
	]] --
    getTimestamp = function()
        return os.date("%b_%d_%Y_%H.%M")
    end
}

pluginManager.returnHome = true
pluginManager.returnPluginTable = "scriptCreator"
scriptCreator.home()
