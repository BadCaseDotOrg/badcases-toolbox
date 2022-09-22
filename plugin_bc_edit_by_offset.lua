editByOffset = {
    originalValues = {},
    savedEditsTable = {},
    getFromActiveTab = function(activeTab)
        local offset
        if activeTab == 1 then
            local results = gg.getResults(1)
            offset = gg.getSelectedResults()[1].address - BASEADDR
        elseif activeTab == 2 then
            offset = gg.getSelectedListItems()[1].address - BASEADDR
        elseif activeTab == 3 then
            offset = gg.getSelectedElements()[1] - BASEADDR
        end
        return offset
    end,
    createEdit = function()
        local targetSource = gg.choice({"Enter A Offset", "Get From Active Tab"})
        if targetSource ~= nil then
            local editOffset
            if targetSource == 1 then
                local offsetMenu = gg.prompt({"Enter Offset"}, {"0x"}, {"number"})
                if offsetMenu ~= nil and offsetMenu[1] ~= "0x" then
                    editOffset = offsetMenu[1]
                end
            end
            if targetSource == 2 then
                local activeTab = gg.getActiveTab()
                editOffset = editByOffset.getFromActiveTab(activeTab)
            end
            if editOffset ~= nil then
                local edits
                local menu_type = {"Boolean", "Integer", "Single (float simple)", "Single (float complex)", "Double", "End Function", "Hook Function", "Call Function", "Manual Edit"}
                local edit_type = gg.choice(menu_type, nil, bc.Choice("Select Type Of Edit", "", "ℹ️"))
                if edit_type ~= nil then
                    if edit_type == 1 then
                        edits = Il2Cpp.getBoolEdit()
                    end
                    if edit_type == 2 then
                        edits = Il2Cpp.getIntEdit()
                    end
                    if edit_type == 3 then
                        edits = Il2Cpp.getSimpleFloatEdit()
                    end
                    if edit_type == 4 then
                        ::set_value::
                        local set_val = gg.prompt({bc.Prompt("Set Float Value", "ℹ️")}, nil, {"number"})
                        if set_val ~= nil then
                            edits = Il2Cpp.getComplexFloatEdit(set_val[1], "Single")
                        end
                    end
                    if edit_type == 5 then
                        ::set_value::
                        local set_val = gg.prompt({bc.Prompt("Set Double Value", "ℹ️")}, nil, {"number"})
                        if set_val ~= nil then
                            edits = Il2Cpp.getComplexFloatEdit(set_val[1], "Double")
                        end
                    end
                    if edit_type == 6 then
                        edits = {{"~A BX LR"}, {"~A8 RET"}}
                    end
                    if edit_type == 7 then
                        edits = {}
                    end
                    if edit_type == 8 then
                        editByOffset.createHookCall(editOffset)
                    end
                    if edit_type == 9 then
                        local editPrompt = gg.prompt({"Enter your edits separated by a ;"}, nil, {"text"})
                        if editPrompt ~= nil then
                            edits = {Il2Cpp.mySplit(editPrompt[1], ";")}
                        else
                            return nil
                        end
                    end
                end
                if hooking ~= true or (edit_type ~= 8 and hooking == true) then
                    if edits ~= nil then
                        local editAddress = Il2Cpp.ggHex(BASEADDR + editOffset)
                        local editsARM7 = edits[1]
                        if editsARM7 == nil then
                            editsARM7 = {}
                        end
                        local editsARM8 = edits[2]
                        if editsARM8 == nil then
                            editsARM8 = {}
                        end
                        if arch.x64 then
                            edits = editsARM8
                        else
                            edits = editsARM7
                        end
                        local tempTable = {}
                        for i, v in ipairs(edits) do
                            tempTable[i] = {
                                address = editAddress,
                                flags = gg.TYPE_DWORD
                            }
                            editAddress = Il2Cpp.ggHex(editAddress + 4)
                        end
                        gg.loadResults(tempTable)
                        local results = gg.getResults(gg.getResultsCount())
                        if not editByOffset.originalValues[editOffset] then
                            editByOffset.originalValues[editOffset] = gg.getResults(gg.getResultsCount())
                        end
                        for i, v in ipairs(results) do
                            if arch.x64 then
                                results[i].value = editsARM8[i]
                            else
                                results[i].value = editsARM7[i]
                            end
                        end
                        local hookAppend = ""
                        if #edits == 0 then
                            hookAppend = " (Create edit and set called method)"
                        end
                        ::name_edit::
                        local editName = gg.prompt({"Name for edit: "}, {editOffset .. hookAppend}, {"text"})
                        if editName == nil then
                            editName = {editOffset}
                        end
                        editByOffset.savedEditsTable[#editByOffset.savedEditsTable + 1] = {
                            editName = editName[1],
                            editsARM7 = editsARM7,
                            editsARM8 = editsARM8,
                            libName = Il2Cpp.lib_name
                        }
                        if edit_type == 7 then
                            editByOffset.savedEditsTable[#editByOffset.savedEditsTable].hook = true
                            hooking = true
                        end
                        if arch.x64 then
                            editByOffset.savedEditsTable[#editByOffset.savedEditsTable].editOffsetARM8 = editOffset
                        else
                            editByOffset.savedEditsTable[#editByOffset.savedEditsTable].editOffsetARM7 = editOffset
                        end
                        if edit_type ~= 7 then
                            if arch.x64 then
                                editByOffset.createSetValues(editOffset, editByOffset.savedEditsTable[#editByOffset.savedEditsTable].editsARM8)
                            else
                                editByOffset.createSetValues(editOffset, editByOffset.savedEditsTable[#editByOffset.savedEditsTable].editsARM7)
                            end
                            bc.saveTable("editByOffset.savedEditsTable", editByOffset.filePath .. gg.getTargetPackage() .. ".lua")
                            editByOffset.savedEditsTable[#editByOffset.savedEditsTable].active = true
                        else
                            bc.Alert("Hook Has Been Saved", "You now need to find the method you want to call and select this hook.", "✅")
                        end
                    end
                else
                    hooking = false
                end
            end
        end
    end,
    -- editByOffset.createHookCall(il2cpp_address,class_name,method_name)
    createHookCall = function(callOffset)
        local hooksMenu = {}
        local savedTableIndex = {}
        for i, v in ipairs(editByOffset.savedEditsTable) do
            if v.hook then
                hooksMenu[#hooksMenu + 1] = v.editName
                savedTableIndex[#savedTableIndex + 1] = i
            end
        end
        ::menu::
        local menu = gg.choice(hooksMenu, nil, bc.Choice(editByOffset.plugin_title, "Select hooked method.", "ℹ️"))
        if menu == nil then
            goto menu
        else
            local hookedAddress
            if arch.x64 then
                hookedAddress = editByOffset.savedEditsTable[savedTableIndex[menu]].editOffsetARM8
            else
                hookedAddress = editByOffset.savedEditsTable[savedTableIndex[menu]].editOffsetARM7
            end
            local calledAddress = callOffset
            local call_offset
            if tonumber(hookedAddress) > tonumber(calledAddress) then
                local check_offset = tonumber(hookedAddress) - tonumber(calledAddress)
                if check_offset / 1002400 < 32 then
                    call_offset = "-" .. hex_o(check_offset)
                end
            else
                local check_offset = tonumber(calledAddress) - tonumber(hookedAddress)
                if arch.x64 then
                    call_offset = hex_o(check_offset)
                else
                    call_offset = "+" .. hex_o(check_offset)
                end
            end
            if call_offset == nil then
                bc.Alert("Too Far Apart", "These methods are too far apart, try hooking a different method.", "⚠️")
            else
                editByOffset.savedEditsTable[savedTableIndex[menu]].editsARM7 = {"~A B " .. call_offset}
                editByOffset.savedEditsTable[savedTableIndex[menu]].editsARM8 = {"~A8 B [PC,#" .. call_offset .. "]"}
                editByOffset.savedEditsTable[savedTableIndex[menu]].editName = editByOffset.savedEditsTable[savedTableIndex[menu]].editName:gsub(" %(Create edit and set called method%)", "")
                if arch.x64 then
                    editByOffset.createSetValues(hex_o(hookedAddress), editByOffset.savedEditsTable[savedTableIndex[menu]].editsARM8)
                else
                    editByOffset.createSetValues(hex_o(hookedAddress), editByOffset.savedEditsTable[savedTableIndex[menu]].editsARM7)
                end
                bc.saveTable("editByOffset.savedEditsTable", editByOffset.filePath .. gg.getTargetPackage() .. ".lua")
                editByOffset.savedEditsTable[savedTableIndex[menu]].active = true
                bc.Alert("Method Hooked", "The method has been hooked and will call the designated method.", "✅")
            end
        end
    end,
    createSetValues = function(address, edits)
        local address_table = {}
        local offset = 0
        local count = 1
        repeat
            address_table[count] = {}
            address_table[count].address = address + BASEADDR + offset
            address_table[count].flags = gg.TYPE_DWORD
            address_table[count].value = edits[count]
            offset = offset + 4
            count = count + 1
        until (count == #edits + 1)
        if not editByOffset.originalValues[address] then
            editByOffset.originalValues[address] = gg.getResults(gg.getResultsCount())
        end
        gg.setValues(address_table)
    end,
    deleteEdits = function()
        local menu_items = {}
        local checkboxes = {}
        for i, v in ipairs(editByOffset.savedEditsTable) do
            menu_items[i] = v.editName
            checkboxes[i] = "checkbox"
        end
        local menu = gg.prompt(menu_items, nil, checkboxes)
        if menu ~= nil then
            local tempTable = {}
            for i, v in ipairs(menu) do
                if v == false then
                    tempTable[#tempTable + 1] = editByOffset.savedEditsTable[i]
                end
            end
            editByOffset.savedEditsTable = tempTable
            bc.saveTable("editByOffset.savedEditsTable", editByOffset.filePath .. gg.getTargetPackage() .. ".lua")
        end
    end,
    doSavedEdit = function(editIndex)
        local edits
        local editOffset
        if arch.x64 then
            edits = editByOffset.savedEditsTable[editIndex].editsARM8
            editOffset = editByOffset.savedEditsTable[editIndex].editOffsetARM8
        else
            edits = editByOffset.savedEditsTable[editIndex].editsARM7
            editOffset = editByOffset.savedEditsTable[editIndex].editOffsetARM7
        end
        if editByOffset.savedEditsTable[editIndex].active == true then
            gg.setValues(editByOffset.originalValues[editOffset])
            editByOffset.savedEditsTable[editIndex].active = false
        else
            local editAddress = Il2Cpp.ggHex(BASEADDR + editOffset)
            local tempTable = {}
            for i, v in ipairs(edits) do
                tempTable[i] = {
                    address = editAddress,
                    flags = gg.TYPE_DWORD
                }
                editAddress = Il2Cpp.ggHex(editAddress + 4)
            end
            gg.loadResults(tempTable)
            local results = gg.getResults(gg.getResultsCount())
            if not editByOffset.originalValues[editOffset] then
                editByOffset.originalValues[editOffset] = gg.getResults(gg.getResultsCount())
            end
            for i, v in ipairs(results) do
                results[i].value = edits[i]
            end
            editByOffset.savedEditsTable[editIndex].active = true
            gg.setValues(results)
        end
    end,
    plugin_title = "Plugin: Lib Edits By Offset",
    home = function(passed_data)
        pluginManager.returnHome = true
        pluginManager.returnPluginTable = "editByOffset"
        if passed_data then
            gg.alert(passed_data)
        else
            if editByOffset.savedEditsTable == nil then
                editByOffset.savedEditsTable = {}
            end
            local menu_items = {}
            for i, v in ipairs(editByOffset.savedEditsTable) do
                if editByOffset.savedEditsTable[i].active == true then
                    menu_items[i] = "✅ " .. v.editName
                else
                    menu_items[i] = "▶️ " .. v.editName
                end
            end
            menu_items[#menu_items + 1] = "➕ Create Edit"
            menu_items[#menu_items + 1] = "🗑️ Delete Edit(s)"
            menu_items[#menu_items + 1] = "❌ Exit Plugin"
            local menu = gg.choice(menu_items, nil, bc.Choice(editByOffset.plugin_title, "", "ℹ️"))
            if menu ~= nil then
                if editByOffset.savedEditsTable == nil then
                    editByOffset.savedEditsTable = {}
                end
                if menu <= #editByOffset.savedEditsTable then

                    editByOffset.doSavedEdit(menu)

                end
                if menu == #editByOffset.savedEditsTable + 1 then
                    editByOffset.createEdit()
                end
                if menu == #editByOffset.savedEditsTable + 2 then
                    editByOffset.deleteEdits()
                end
                if menu == #menu_items then
                    pluginManager.returnHome = false
                end
            end
        end
    end,
    filePath = pluginsDataPath .. "bc_edit_by_offset_data/"
}
local status, retval = pcall(bc.readFile, editByOffset.filePath .. gg.getTargetPackage() .. ".lua");
if status == false then
    dH.createDirectory()
    bc.createDirectory(editByOffset.filePath)
else
    dofile(editByOffset.filePath .. gg.getTargetPackage() .. ".lua")
end
pluginManager.returnHome = true
if not Il2Cpp.lib_name then
    Il2Cpp.selectLibrary()
end
pluginManager.returnPluginTable = "editByOffset"
editByOffset.home()
