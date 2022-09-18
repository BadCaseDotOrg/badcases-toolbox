scriptCreator = {
    -- scriptCreator.home()
    home = function()
        local menu = gg.choice({"🆕 Create Script Function", "➕ Add Edit To Function", "➖ Remove Edit From Function", "☰ Menu Editor", "🔤 Set Script Title", "💾 Export script", "❌ Exit"}, nil, script_title .. "\n\nℹ️ Script Creator ℹ️")
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
    -- scriptCreator.nameScript()
    nameScript = function()
        local menu = gg.prompt({script_title .. "\n\nℹ️ Enter a title for your script. ℹ️"}, nil, {"text"})
        if menu ~= nil then
            scriptCreator.scriptName = menu[1]
        end
    end,
    -- scriptCreator.createFunction()
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
    -- scriptCreator.addEditToFunction()
    addEditToFunction = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil, script_title .. "\n\nℹ️ Select function to add edit to. ℹ️")
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
    -- scriptCreator.removeEditFromFunction()
    removeEditFromFunction = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil, script_title .. "\n\nℹ️ Select function to remove edit from. ℹ️")
        if menu ~= nil then
            local functionEdits = {}
            for i, v in pairs(scriptCreator.scriptFunctions[menu].edits) do
                functionEdits[i] = v.edit_name
            end
            local editMenu = gg.choice(functionEdits, nil, script_title .. "\n\nℹ️ Select edit to remove from function. ℹ️")
            if editMenu ~= nil then
                table.remove(scriptCreator.scriptFunctions[menu].edits, editMenu)
                gg.toast(script_title .. "\n\nℹ️ Edit Removed From Function ℹ️")
            end
        end
    end,
    -- scriptCreator.getEditsMenu()
    getEditsMenu = function()
        scriptCreator.allEdits = {}
        local menuNames = {}
        if il2cppEdits then
            for i, v in ipairs(il2cppEdits.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v
                menuNames[#menuNames + 1] = v.edit_name .. "(method edit)"
            end
        end
        if il2cppFields then
            for i, v in ipairs(il2cppFields.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v
                menuNames[#menuNames + 1] = v.edit_name .. "(field edit)"
            end
        end
        if staticValueFinder and #staticValueFinder.savedEditsTable > 0 then
            for i, v in ipairs(staticValueFinder.savedEditsTable) do
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v.edit_table
                menuNames[#menuNames + 1] = v.edit_table.edit_name .. "(static value search edit)"
            end
        end
        if editByOffset and #editByOffset.savedEditsTable > 0 then
            for i, v in ipairs(editByOffset.savedEditsTable) do
                v.active = nil
                scriptCreator.allEdits[#scriptCreator.allEdits + 1] = v
                menuNames[#menuNames + 1] = v.editName .. "(lib offset edit)"
            end
        end
        return menuNames
    end,
    -- scriptCreator.allEdits()
    allEdits = {},
    scriptFunctions = {},
    getFunctionsMenu = function()
        local menuNames = {}
        for i, v in pairs(scriptCreator.scriptFunctions) do
            menuNames[#menuNames + 1] = v.menu_name
        end
        return menuNames
    end,
    -- scriptCreator.menuEditorRemove()
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
    -- scriptCreator.menuEditorMoveUp()
    menuEditorMoveUp = function(current_index)
        local temp_index = #scriptCreator.scriptFunctions + 2
        scriptCreator.scriptFunctions[temp_index] = scriptCreator.scriptFunctions[current_index - 1]
        scriptCreator.scriptFunctions[current_index - 1] = scriptCreator.scriptFunctions[current_index]
        scriptCreator.scriptFunctions[current_index] = scriptCreator.scriptFunctions[temp_index]
        scriptCreator.scriptFunctions[temp_index] = nil
    end,
    -- scriptCreator.menuEditorMoveDown()
    menuEditorMoveDown = function(current_index)
        local temp_index = #scriptCreator.scriptFunctions + 2
        scriptCreator.scriptFunctions[temp_index] = scriptCreator.scriptFunctions[current_index + 1]
        scriptCreator.scriptFunctions[current_index + 1] = scriptCreator.scriptFunctions[current_index]
        scriptCreator.scriptFunctions[current_index] = scriptCreator.scriptFunctions[temp_index]
        scriptCreator.scriptFunctions[temp_index] = nil
    end,
    -- scriptCreator.menuEditorRename()
    menuEditorRename = function(current_index)
        local menu = gg.prompt({script_title .. "\n\nℹ️ Edit Function Name ℹ️"}, {scriptCreator.scriptFunctions[current_index].menu_name}, {"text"})
        if menu ~= nil then
            scriptCreator.scriptFunctions[current_index].menu_name = menu[1]
        end
    end,
    -- scriptCreator.menuEditor()
    menuEditor = function()
        local menu = gg.choice(scriptCreator.getFunctionsMenu(), nil, script_title .. "\n\nℹ️ Select script menu item. ℹ️")
        if menu ~= nil then
            local doWithMenu = gg.choice({"⬆️ Move Up", "⬇️ Move Down", "🗑️ Remove Function", "📝 Edit Function Name", "🔙 Back To Menu Editor"}, nil, script_title .. "\n\nℹ️ " .. scriptCreator.scriptFunctions[menu].menu_name .. " ℹ️")
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
    addTranslations = function()
    local translateTable = {}
    ::add_more::
    local menu = gg.choice ({"📥 Import smodin.io JSON","📋 Copy Menu Names To Clipboard","📋 Copy smodin.io Translator Link To Clipboard","👁️ Hide Script","❌ Done Adding Translations"},nil,script_title .. "\n\nℹ️ Translation Menu ℹ️")
    if menu == nil then
        goto add_more
    else
        if menu == 1 then
            local filePrompt = gg.prompt ({"Select smodin.io JSON File"},{gg.EXT_STORAGE.."/Download/"},{"file"})
            local file = io.open(filePrompt[1], "r")
            local content = file:read("*a")
            file:close()
            local tempTable = json.decode (content)
            for i,v in pairs (tempTable) do
                v.text = Il2Cpp.mySplit(v.text, "\n")
                table.insert (translateTable,v)
            end
            goto add_more
        end
        if menu == 2 then
            local menuNames = ""
            for i,v in ipairs (scriptCreator.scriptFunctions) do
                 menuNames = menuNames..v.menu_name.."\n"
            end
            gg.copyText (menuNames)
            goto add_more
        end
        if menu == 3 then
            gg.copyText ("https://smodin.io/translate-one-text-into-multiple-languages")
            goto add_more
        end
        if menu == 4 then
            gg.sleep(10000)
            goto add_more
        end
        if menu == 5 then
            return translateTable
        end
    end
end,
    -- scriptCreator.exportScript(scriptName)
    exportScript = function(scriptName)
        ::check_name::
        if not scriptCreator.scriptName then
            scriptCreator.nameScript()
            goto check_name
        end
        local translateTable
        local translateMenu = gg.choice({"✅ Yes","❌ No"},nil,script_title .. "\n\nℹ️ Do you want to add translations to other languages for your menus? ℹ️")
        if translateMenu ~= nil then
            if translateMenu == 1 then
                translateTable = scriptCreator.addTranslations()
            end
        end
		local scriptExportTable = {
			'script_title = "' .. scriptCreator.scriptName .. '"',
			'scriptFunctions = ' .. tostring(scriptCreator.scriptFunctions), 
			'translateTable = ' .. tostring(translateTable), 
			'Il2Cpp = {}',
			'Il2Cpp.Il2cppApi = ' .. tostring(Il2Cpp.Il2cppApi[Il2Cpp.unity_version]), 
			'editByOffset = {}',
			'editByOffset.originalValues = {}',
			'emojis = {}',
			'revert_table = {}',
			'setFields = {}',
			'arch = gg.getTargetInfo()',
			'needToConfigure = false',
			'',
			'for i, v in pairs(scriptFunctions) do',
			'    emojis[i] = "🔘"',
			'end',
			'',
			'if arch.x64 then',
			'    flag_type = gg.TYPE_QWORD',
			'    Il2Cpp.ARM = "ARM8"',
			'else',
			'    flag_type = gg.TYPE_DWORD',
			'    Il2Cpp.ARM = "ARM7"',
			'end',
			'',
			'if Il2Cpp.Il2cppApi ~= nil then',
			'    Il2Cpp.FieldApiOffset = Il2Cpp.Il2cppApi.FieldApiOffset[Il2Cpp.ARM]',
			'    Il2Cpp.FieldApiType = Il2Cpp.Il2cppApi.FieldApiType[Il2Cpp.ARM]',
			'    Il2Cpp.FieldApiClassOffset = Il2Cpp.Il2cppApi.FieldApiClassOffset[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiNameOffset = Il2Cpp.Il2cppApi.ClassApiNameOffset[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiMethodsStep = Il2Cpp.Il2cppApi.ClassApiMethodsStep[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiCountMethods = Il2Cpp.Il2cppApi.ClassApiCountMethods[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiMethodsLink = Il2Cpp.Il2cppApi.ClassApiMethodsLink[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiFieldsLink = Il2Cpp.Il2cppApi.ClassApiFieldsLink[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiFieldsStep = Il2Cpp.Il2cppApi.ClassApiFieldsStep[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiCountFields = Il2Cpp.Il2cppApi.ClassApiCountFields[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiParentOffset = Il2Cpp.Il2cppApi.ClassApiParentOffset[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiNameSpaceOffset = Il2Cpp.Il2cppApi.ClassApiNameSpaceOffset[Il2Cpp.ARM]',
			'    Il2Cpp.ClassApiStaticFieldDataOffset = Il2Cpp.Il2cppApi.ClassApiStaticFieldDataOffset[Il2Cpp.ARM]',
			'    Il2Cpp.MethodsApiClassOffset = Il2Cpp.Il2cppApi.MethodsApiClassOffset[Il2Cpp.ARM]',
			'    Il2Cpp.MethodsApiNameOffset = Il2Cpp.Il2cppApi.MethodsApiNameOffset[Il2Cpp.ARM]',
			'    Il2Cpp.MethodsApiParamCount = Il2Cpp.Il2cppApi.MethodsApiParamCount[Il2Cpp.ARM]',
			'    Il2Cpp.MethodsApiReturnType = Il2Cpp.Il2cppApi.MethodsApiReturnType[Il2Cpp.ARM]',
			'    Il2Cpp.typeDefinitionsSize = Il2Cpp.Il2cppApi.typeDefinitionsSize',
			'    Il2Cpp.typeDefinitionsOffset = Il2Cpp.Il2cppApi.typeDefinitionsOffset',
			'    Il2Cpp.stringOffset = Il2Cpp.Il2cppApi.stringOffset',
			'    Il2Cpp.TypeApiType = Il2Cpp.Il2cppApi.TypeApiType[Il2Cpp.ARM]',
			'end',
			'',
			'function getRange()',
			'    local stringsStart = ":" .. string.char(0) .. "mscorlib.dll" .. string.char(0)',
			'    local stringsEnd = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12"',
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
			'',
			'function hex_o(n)',
			'    return "0x" .. string.upper(string.format("%x", n))',
			'end',
			'',
			'function createHookCall(editTable, function_index, editIndex)',
			'    if scriptFunctions[function_index].edits[editIndex].enabled == true then',
			'        gg.setValues(scriptFunctions[function_index].edits[editIndex].orignal_values)',
			'        scriptFunctions[function_index].edits[editIndex].enabled = false',
			'    else',
			'        local hookedMethod = editTable.method_name',
			'        local hookedClass = editTable.class_name',
			'        local hookedAddress = findMethod(hookedMethod, hookedClass)[1]',
			'        local calledMethod = editTable.called.method_name',
			'        local calledClass = editTable.called.class_name',
			'        local calledAddress = findMethod(calledMethod, calledClass)[1]',
			'        local call_offset',
			'        if tonumber(hookedAddress) > tonumber(calledAddress) then',
			'            local check_offset = tonumber(hookedAddress) - tonumber(calledAddress)',
			'            call_offset = "-" .. hex_o(check_offset)',
			'        else',
			'            local check_offset = tonumber(calledAddress) - tonumber(hookedAddress)',
			'            if file_ext == "ARM8" then',
			'                call_offset = hex_o(check_offset)',
			'            else',
			'                call_offset = "+" .. hex_o(check_offset)',
			'            end',
			'        end',
			'        scriptFunctions[function_index].edits[editIndex].edits = {{"~A B " .. call_offset}, {"~A8 B [PC,#" .. call_offset .. "]"}}',
			'        local editHook = {{',
			'            address = hookedAddress,',
			'            flags = gg.TYPE_DWORD',
			'        }}',
			'        if not scriptFunctions[function_index].edits[editIndex].orignal_values then',
			'            gg.loadResults(editHook)',
			'            scriptFunctions[function_index].edits[editIndex].orignal_values = gg.getResults(gg.getResultsCount())',
			'        end',
			'        if arch.x64 then',
			'            editHook[1].value = scriptFunctions[function_index].edits[editIndex].edits[2][1]',
			'        else',
			'            editHook[1].value = scriptFunctions[function_index].edits[editIndex].edits[1][1]',
			'        end',
			'        gg.setValues(editHook)',
			'        scriptFunctions[function_index].edits[editIndex].enabled = true',
			'    end',
			'end',
			'',
			'function setMethodValues(function_index, edit_index)',
			'    if arch.x64 then',
			'        edits_arch = "arm8_edits"',
			'    else',
			'        edits_arch = "arm7_edits"',
			'    end',
			'    local edits = scriptFunctions[function_index].edits[edit_index][edits_arch]',
			'    if scriptFunctions[function_index].edits[edit_index].enabled == true then',
			'        gg.setValues(scriptFunctions[function_index].edits[edit_index].orignal_values)',
			'        scriptFunctions[function_index].edits[edit_index].enabled = false',
			'    else',
			'        if not scriptFunctions[function_index].edits[edit_index].orignal_values then',
			'            local addresses = findMethod(scriptFunctions[function_index].edits[edit_index].method_name, scriptFunctions[function_index].edits[edit_index].class_name)',
			'            local tempTable = {}',
			'            for i, v in ipairs(edits) do',
			'                tempTable[i] = {',
			'                    address = addresses[1],',
			'                    flags = gg.TYPE_DWORD',
			'                }',
			'                addresses[1] = addresses[1] + 4',
			'            end',
			'            gg.loadResults(tempTable)',
			'            local results = gg.getResults(gg.getResultsCount())',
			'            scriptFunctions[function_index].edits[edit_index].addresses = gg.getResults(gg.getResultsCount())',
			'            scriptFunctions[function_index].edits[edit_index].orignal_values = gg.getResults(gg.getResultsCount())',
			'        end',
			'        for i, v in ipairs(edits) do',
			'            scriptFunctions[function_index].edits[edit_index].addresses[i].value = v',
			'        end',
			'        gg.setValues(scriptFunctions[function_index].edits[edit_index].addresses)',
			'        scriptFunctions[function_index].edits[edit_index].enabled = true',
			'    end',
			'end',
			'',
			'function home()',
			'    local menuNames = {}',
			'    for i, v in pairs(scriptFunctions) do',
			'        menuNames[i] = emojis[i] .. " " .. v.menu_name',
			'    end',
			'    if translateTable ~= nil then',
			'        menuNames[#menuNames + 1] = "🌐 Change Language"',
			'    end',
			'    menuNames[#menuNames + 1] = "❌ Exit"',
			'    local menu = gg.choice(menuNames, nil, script_title)',
			'    if menu ~= nil then',
			'        if menu == #menuNames then',
			'            os.exit() ',
			'        elseif translateTable ~= nil and menu == #menuNames - 1 then',
			'             changeLang()',
			'        else',
			'            setValues(menu)',
			'        end',
			'    end',
			'end',
			'',
			'function changeLang()',
			'    local languages = {}',
			'    for i,v in ipairs (translateTable) do',
			'        languages[i] = v.language',
			'    end',
			'    local menu = gg.choice (languages,nil,"Select language")',
			'    if menu ~= nil then',
			'        for i,v in ipairs (scriptFunctions) do',
			'            scriptFunctions[i].menu_name = translateTable[menu].text[i]',
			'        end',
			'    end',
			'    home()',
			'end',
			'',
			'function setValues(function_index)',
			'    local status',
			'    if emojis[function_index] == "🔘" then',
			'        emojis[function_index] = "✅"',
			'        status = "Enabled"',
			'    else',
			'        emojis[function_index] = "🔘"',
			'        status = "Disabled"',
			'    end',
			'    for i, v in pairs(scriptFunctions[function_index].edits) do',
			'        if v.method_name and v.hook then',
			'            createHookCall(v, function_index, i)',
			'        elseif v.method_name then',
			'            setMethodValues(function_index, i)',
			'        elseif v.field_name then',
			'            if status == "Enabled" then',
			'                setFieldValues(v, function_index, i)',
			'            end',
			'        elseif v.editName then',
			'            setLibOffsetValues(v, function_index, i)',
			'        else',
			'            setSVFValues(v, function_index, i)',
			'        end',
			'    end',
			'    gg.toast(emojis[function_index] .. " " .. scriptFunctions[function_index].menu_name .. " " .. status .. " " .. emojis[function_index])',
			'end',
			'',
			'function fix(class_name, passed_class_name, index)',
			'    return "Result " .. index .. " Checked"',
			'end',
			'',
			'function findMethod(method_name, passed_class_name)',
			'    if arch.x64 then',
			'        p_offset = 16',
			'        p_offset2 = 8',
			'    else',
			'        p_offset = 8',
			'        p_offset2 = 4',
			'    end',
			'    method_name_address = searchMetaData(method_name)',
			'    gg.clearResults()',
			'    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)',
			'    gg.searchNumber(method_name_address, flag_type)',
			'    local results = gg.getResults(gg.getResultsCount())',
			'    local methods_found = {}',
			'    local il2cpp_addresses = {}',
			'    for i, v in pairs(results) do',
			'        local classPointer = {}',
			'        classPointer[1] = {}',
			'        classPointer[1].address = v.address + p_offset2',
			'        classPointer[1].flags = flag_type',
			'        classPointer = gg.getValues(classPointer)',
			'        classPointer[1].address = classPointer[1].value + Il2Cpp.ClassApiNameOffset',
			'        classPointer = gg.getValues(classPointer)',
			'        local class_name = getIl2CppString(classPointer[1].value)',
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
			'',
			'function searchMetaData(search_string)',
			'    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)',
			'    if search_string then',
			'        gg.clearResults()',
			'        gg.searchNumber(createSearch(search_string), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)',
			'        local results = gg.getResults(1, 1)',
			'        return results[1].address',
			'    end',
			'end',
			'',
			'function createSearch(search_string)',
			'    local textSearch = ":" .. string.char(0) .. search_string .. string.char(0)',
			'    return textSearch',
			'end',
			'',
			'function setFieldValues(saved_edit_table, function_index, edit_index)',
			'    local header_offset',
			'    if arch.x64 then',
			'        header_offset = 16',
			'    else',
			'        header_offset = 8',
			'    end',
			'    gg.clearList()',
			'    local class_name = saved_edit_table.class_name',
			'    local field_name = saved_edit_table.field_name',
			'    local namespace_name = saved_edit_table.edit_namespace',
			'    gg.setRanges(gg.REGION_OTHER)',
			'    gg.clearResults()',
			'    gg.searchNumber(createSearch(class_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)',
			'    local class_string = gg.getResults(1, 1)',
			'    local namespace_string',
			'    if namespace_name ~= "" then',
			'        gg.clearResults()',
			'        gg.searchNumber(createSearch(namespace_name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)',
			'        namespace_string = gg.getResults(1, 1)',
			'        namespace_string = ggHex(namespace_string[1].address, false)',
			'    else',
			'        namespace_string = ggHex(range_start - 19, false)',
			'    end',
			'    gg.clearResults()',
			'    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)',
			'    gg.searchNumber(ggHex(class_string[1].address, false) .. ";" .. namespace_string .. "::9", flag_type)',
			'    local results = gg.getResults(1)',
			'    local class_header = results[1].address - header_offset',
			'    local field_count = {{',
			'        address = class_header + Il2Cpp.ClassApiCountFields,',
			'        flags = gg.TYPE_DWORD',
			'    }}',
			'    field_count = gg.getValues(field_count)',
			'    field_count = field_count[1].value',
			'    local field_pointer = {{',
			'        address = class_header + Il2Cpp.ClassApiFieldsLink,',
			'        flags = flag_type',
			'    }}',
			'    field_pointer = gg.getValues(field_pointer)',
			'    field_pointer = ggHex(field_pointer[1].value)',
			'    local correct_field',
			'    for i = 1, field_count do',
			'        local checkString = {{',
			'            address = field_pointer,',
			'            flags = flag_type',
			'        }}',
			'        checkString = gg.getValues(checkString)',
			'        checkString = getIl2CppString(checkString[1].value)',
			'        if field_name == checkString then',
			'            correct_field = field_pointer',
			'            break',
			'        end',
			'        field_pointer = field_pointer + Il2Cpp.ClassApiFieldsStep',
			'    end',
			'    local field_offset = {{',
			'        address = correct_field + Il2Cpp.FieldApiOffset,',
			'        flags = gg.TYPE_DWORD',
			'    }}',
			'    field_offset = gg.getValues(field_offset)',
			'    field_offset = field_offset[1].value',
			'    gg.clearResults()',
			'    gg.setRanges(gg.REGION_ANONYMOUS)',
			'    gg.searchNumber(class_header, flag_type)',
			'    local results = gg.getResults(gg.getResultsCount())',
			'    load_field_values = {}',
			'    local value_type = saved_edit_table.value_type',
			'    for i, v in pairs(results) do',
			'        load_field_values[i] = v',
			'        load_field_values[i].address = v.address + field_offset',
			'        load_field_values[i].flags = value_type',
			'    end',
			'    gg.addListItems(load_field_values)',
			'    if saved_edit_table.edit_type == "edit_all_x4" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            save_list_all[i].address = save_list_all[i].address + 4',
			'            if tonumber(saved_edit_table.edit_value) == 0 then',
			'                save_list_all[i].value = save_list_all[i].value',
			'            else',
			'                save_list_all[i].value = saved_edit_table.edit_value .. "X4"',
			'            end',
			'            save_list_all[i].freeze = saved_edit_table.freeze',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_indexes" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(saved_edit_table.edit_indexes) do',
			'            save_list_all[v].value = saved_edit_table.edit_value',
			'            save_list_all[v].freeze = saved_edit_table.freeze',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_that_equal" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            if v.value == saved_edit_table.must_equal then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            save_list_all[i].value = saved_edit_table.edit_value',
			'            save_list_all[i].freeze = saved_edit_table.freeze',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_that_do_not_equal" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            if save_list_all[i].value ~= saved_edit_table.must_equal then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_less_equal" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            if save_list_all[i].value <= saved_edit_table.must_equal then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_greater_equal" then',
			'        local save_list_all = gg.getListItems()',
			'        for i, v in pairs(save_list_all) do',
			'            if save_list_all[i].value >= saved_edit_table.must_equal then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_in_range" then',
			'        local save_list_all = gg.getListItems()',
			'        local minValue = tonumber(saved_edit_table.must_equal:gsub("(.+)~.+", "%1"))',
			'        local maxValue = tonumber(saved_edit_table.must_equal:gsub(".+~(.+)", "%1"))',
			'        for i, v in pairs(save_list_all) do',
			'            if save_list_all[i].value >= minValue and save_list_all[i].value <= maxValue then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    if saved_edit_table.edit_type == "edit_all_not_in_range" then',
			'        local save_list_all = gg.getListItems()',
			'        local minValue = tonumber(saved_edit_table.must_equal:gsub("(.+)~.+", "%1"))',
			'        local maxValue = tonumber(saved_edit_table.must_equal:gsub(".+~(.+)", "%1"))',
			'        for i, v in pairs(save_list_all) do',
			'            if save_list_all[i].value < minValue or save_list_all[i].value > maxValue then',
			'                save_list_all[i].value = saved_edit_table.edit_value',
			'                save_list_all[i].freeze = saved_edit_table.freeze',
			'            end',
			'        end',
			'        gg.setValues(save_list_all)',
			'        gg.addListItems(save_list_all)',
			'    end',
			'    fields = {}',
			'end',
			'',
			'function ggHex(n, zero)',
			'    if type(n) ~= "table" then',
			'        local dwordValueToHex = string.format("%x", n)',
			'        if #dwordValueToHex == 8 or #dwordValueToHex == 10 or #dwordValueToHex == 12 then',
			'            if zero == false then',
			'                return dwordValueToHex .. "h"',
			'            else',
			'                return "0x" .. dwordValueToHex',
			'            end',
			'        else',
			'            local sub = #dwordValueToHex / 2',
			'            sub = tonumber("-" .. sub)',
			'            dwordValueToHex = dwordValueToHex:sub(sub)',
			'            if zero == false then',
			'                return dwordValueToHex .. "h"',
			'            else',
			'                return "0x" .. dwordValueToHex',
			'            end',
			'        end',
			'    else',
			'        return nil',
			'    end',
			'end',
			'',
			'function getIl2CppString(address)',
			'    local tempString = ""',
			'    repeat',
			'        local character = {{',
			'            address = address,',
			'            flags = gg.TYPE_BYTE',
			'        }}',
			'        character = gg.getValues(character)',
			'        if character[1].value ~= 0 then',
			'            tempString = tempString .. string.char(character[1].value)',
			'        end',
			'        address = address + 1',
			'    until (character[1].value == 0)',
			'    return tempString',
			'end',
			'',
			'function setSVFValues(edit_table, function_index, edit_index)',
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
			'        gg.refineNumber(expected_range, edit_to_flags)',
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
			'',
			'function getLib(libName)',
			'	lib_size = 0',
			'	lib_index = ""',
			'	if #gg.getRangesList(libName) == 0 then',
			'		if libName:find(".so") then',
			'			if arch.x64 then',
			'				libName = "split_config.arm64_v8a.apk"',
			'			else',
			'				libName = "split_config.armeabi_v7a.apk"',
			'			end',
			'		elseif libName:find(".apk") then',
			'			libname = "libil2cpp.so"',
			'		end',
			'	end',
			'	for i, v in pairs(gg.getRangesList(libName)) do',
			'		if v["end"] - v["start"] > lib_size and v["state"] == "Xa" then',
			'			lib_size = v["end"] - v["start"]',
			'			lib_index = i',
			'		end',
			'	end',
			'	BASEADDR = gg.getRangesList(libName)[lib_index].start',
			'end',
			'',
			'function setLibOffsetValues(edit_table, function_index, edit_index)',
			'    if not BASEADDR then',
			'        getLib(scriptFunctions[function_index].edits[edit_index].libName)',
			'    end',
			'    local edits',
			'    local editOffset',
			'    if arch.x64 then',
			'        edits = scriptFunctions[function_index].edits[edit_index].editsARM8',
			'        editOffset = scriptFunctions[function_index].edits[edit_index].editOffsetARM8',
			'    else',
			'        edits = scriptFunctions[function_index].edits[edit_index].editsARM7',
			'        editOffset = scriptFunctions[function_index].edits[edit_index].editOffsetARM7',
			'    end',
			'    if scriptFunctions[function_index].edits[edit_index].active == true then',
			'        gg.setValues(editByOffset.originalValues[editOffset])',
			'        scriptFunctions[function_index].edits[edit_index].active = false',
			'    else',
			'        local editAddress = ggHex(BASEADDR + editOffset)',
			'        local tempTable = {}',
			'        for i, v in ipairs(edits) do',
			'            tempTable[i] = {',
			'                address = editAddress,',
			'                flags = gg.TYPE_DWORD',
			'            }',
			'            editAddress = ggHex(editAddress + 4)',
			'        end',
			'        gg.loadResults(tempTable)',
			'        local results = gg.getResults(gg.getResultsCount())',
			'        if not editByOffset.originalValues[editOffset] then',
			'            editByOffset.originalValues[editOffset] = gg.getResults(gg.getResultsCount())',
			'        end',
			'        for i, v in ipairs(results) do',
			'            results[i].value = edits[i]',
			'        end',
			'        scriptFunctions[function_index].edits[edit_index].active = true',
			'        gg.setValues(results)',
			'    end',
			'end',
			'',
			'for i, v in pairs(scriptFunctions) do',
			'    for index, value in pairs(v.edits) do',
			'        if value.method_name or value.field_name then',
			'            needToConfigure = true',
			'        end',
			'    end',
			'end',
			'',
			'if needToConfigure == true then',
			'    getRange()',
			'end',
			'',
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
			'',
			'while true do',
			'    if gg.isVisible() then',
			'        gg.setVisible(false)',
			'        home()',
			'    end',
			'    gg.sleep(100)',
			'end',
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
    -- scriptCreator.getTimestamp()
    getTimestamp = function()
        return os.date("%b_%d_%Y_%H.%M")
    end
}

pluginManager.returnHome = true
pluginManager.returnPluginTable = "scriptCreator"
scriptCreator.home()

------WebKitFormBoundaryqAhb3D8CD