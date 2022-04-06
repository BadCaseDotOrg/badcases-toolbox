if pluginManager.installingPlugin == true then
    pluginManager.installingPluginName = "Static Value Finder"
    pluginManager.installingPluginTable = "staticValueFinder"
else
    staticValueFinder = {
        dwordTable = {},
        qwordTable = {},
        floatTable = {},
        doubleTable = {},
        xorTable = {},
        desiredValue = {},
        getAbove = function(address, range)
            local values = range / 4
            local startAddress = address - range
            for i = 1, values do
                staticValueFinder.dwordTable[#staticValueFinder.dwordTable + 1] = {
                    address = startAddress,
                    flags = gg.TYPE_DWORD
                }
                startAddress = startAddress + 4
            end
        end,
        getUnder = function(address, range)
            local startAddress = address + 4
            local values = range / 4
            for i = 1, values do
                staticValueFinder.dwordTable[#staticValueFinder.dwordTable + 1] = {
                    address = startAddress,
                    flags = gg.TYPE_DWORD
                }
                startAddress = startAddress + 4
            end
        end,
        getOtherTypes = function()
            staticValueFinder.dwordTableOriginal = gg.getValues(staticValueFinder.dwordTable)
            for i, v in ipairs(staticValueFinder.dwordTable) do
                local temp_var = staticValueFinder.dwordTable[i]
                staticValueFinder.qwordTable[i] = temp_var
                staticValueFinder.qwordTable[i].flags = gg.TYPE_QWORD
            end
            staticValueFinder.qwordTable = gg.getValues(staticValueFinder.qwordTable)
            for i, v in ipairs(staticValueFinder.dwordTable) do
                local temp_var = staticValueFinder.dwordTable[i]
                staticValueFinder.floatTable[i] = temp_var
                staticValueFinder.floatTable[i].flags = gg.TYPE_FLOAT
            end
            staticValueFinder.floatTable = gg.getValues(staticValueFinder.floatTable)
            for i, v in ipairs(staticValueFinder.dwordTable) do
                local temp_var = staticValueFinder.dwordTable[i]
                staticValueFinder.doubleTable[i] = temp_var
                staticValueFinder.doubleTable[i].flags = gg.TYPE_DOUBLE
            end
            staticValueFinder.doubleTable = gg.getValues(staticValueFinder.doubleTable)
            for i, v in ipairs(staticValueFinder.dwordTable) do
                local temp_var = staticValueFinder.dwordTable[i]
                staticValueFinder.xorTable[i] = temp_var
                staticValueFinder.xorTable[i].flags = gg.TYPE_XOR
            end
            staticValueFinder.xorTable = gg.getValues(staticValueFinder.xorTable)
            staticValueFinder.dwordTable = gg.getValues(staticValueFinder.dwordTableOriginal)
        end,
        searchForValues = function(setName)
            staticValueFinder.desiredValue = gg.getSelectedResults()
            local edit_type = staticValueFinder.desiredValue[1].flags
            if #staticValueFinder.desiredValue ~= 1 then
                gg.alert(script_title .. "\n\nℹ️ Select the desired value in your search results first ℹ️")
                goto done
            end
            local menu_range = 50
            local menu_above = true
            local menu_under = false
            local menu = {}
            local edit_index = 0
            if staticValueFinder.settings then
                menu[1] = staticValueFinder.settings.range
            else
                menu = gg.prompt({"Range", "Expected Value Range (Optional)\nExample: 1~100"}, {menu_range, nil}, {"number", "number"})
            end
            if menu ~= nil then
                local range = menu[1]
                local expectedValueRange = menu[2]
                local fixedRange = range % 4
                fixedRange = range - fixedRange
                staticValueFinder.getAbove(staticValueFinder.desiredValue[1].address, fixedRange)
                edit_index = #staticValueFinder.dwordTable + 1
                staticValueFinder.getUnder(staticValueFinder.desiredValue[1].address, fixedRange)
                staticValueFinder.getOtherTypes()
                staticValueFinder[setName] = {
                    dword = staticValueFinder.dwordTable,
                    qword = staticValueFinder.qwordTable,
                    float = staticValueFinder.floatTable,
                    double = staticValueFinder.doubleTable,
                    xor = staticValueFinder.xorTable
                }
                local file = io.open(staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. setName .. ".lua", "w+")
                if not expectedValueRange then
                    expectedValueRange = staticValueFinder.settings.expected_range
                end
                file:write("staticValueFinder." .. setName .. " = " .. tostring(staticValueFinder[setName]) .. "\nstaticValueFinder.settings = {range = " .. fixedRange .. ", flags = " .. edit_type .. ", index = " .. edit_index .. ", expected_range = '" .. expectedValueRange .. "'}")
                file:close()
                if staticValueFinder.closeGameAfterSearch == true then
                    gg.alert(script_title .. "\n\nℹ️ Restart the game, find your value again and run the next search. ℹ️")
                end
            end
            ::done::
        end,
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
            gg.dumpMemory(create_start, create_end, staticValueFinder.savePath, gg.DUMP_SKIP_SYSTEM_LIBS)
            local file = io.open(staticValueFinder.savePath .. "/created", "w+")
            file:write("created")
            file:close()
        end,
        checkFile = function(filename)
            local file = assert(io.open(filename, "r"))
            local content = file:read("*a")
            file:close()
        end,
        loadFile = function(filename)
            dofile(filename)
        end,
        savePath = pluginsDataPath .. "badcase_static_value_finder/",
        startOver = function()
            staticValueFinder.settings = nil
            staticValueFinder.setOne = {}
            staticValueFinder.setTwo = {}
            staticValueFinder.setThree = {}
            pcall(os.remove, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setOne.lua")
            pcall(os.remove, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setTwo.lua")
            pcall(os.remove, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setThree.lua")
        end,
        closeGameAfterSearch = false,
        doingFirstSearch = false,
        doingSecondSearch = false,
        setOne = {},
        setTwo = {},
        setThree = {},
        compareSets = function()
            for i, v in ipairs(staticValueFinder.setOne.dword) do
                staticValueFinder.matchesTable[i] = {} -- remove for others
                staticValueFinder.matchesTable[i].dword = {}
                local matches = {}
                if v.value == staticValueFinder.setTwo.dword[i].value then
                    matches.one_and_two = true
                    matches.one_and_two_value = v.value
                else
                    matches.one_and_two = false
                end
                if v.value == staticValueFinder.setThree.dword[i].value then
                    matches.one_and_three = true
                    matches.one_and_three_value = v.value
                else
                    matches.one_and_three = false
                end
                if staticValueFinder.setThree.dword[i].value == staticValueFinder.setTwo.dword[i].value then
                    matches.two_and_three = true
                    matches.two_and_three_value = v.value
                else
                    matches.two_and_three = false
                end
                staticValueFinder.matchesTable[i].dword = matches
            end
            for i, v in ipairs(staticValueFinder.setOne.qword) do
                staticValueFinder.matchesTable[i].qword = {}
                local matches = {}
                if v.value == staticValueFinder.setTwo.qword[i].value then
                    matches.one_and_two = true
                    matches.one_and_two_value = v.value
                else
                    matches.one_and_two = false
                end
                if v.value == staticValueFinder.setThree.qword[i].value then
                    matches.one_and_three = true
                    matches.one_and_three_value = v.value
                else
                    matches.one_and_three = false
                end
                if staticValueFinder.setThree.qword[i].value == staticValueFinder.setTwo.qword[i].value then
                    matches.two_and_three = true
                    matches.two_and_three_value = v.value
                else
                    matches.two_and_three = false
                end
                staticValueFinder.matchesTable[i].qword = matches
            end
            for i, v in ipairs(staticValueFinder.setOne.float) do
                staticValueFinder.matchesTable[i].float = {}
                local matches = {}
                if v.value == staticValueFinder.setTwo.float[i].value then
                    matches.one_and_two = true
                    matches.one_and_two_value = v.value
                else
                    matches.one_and_two = false
                end
                if v.value == staticValueFinder.setThree.float[i].value then
                    matches.one_and_three = true
                    matches.one_and_three_value = v.value
                else
                    matches.one_and_three = false
                end
                if staticValueFinder.setThree.float[i].value == staticValueFinder.setTwo.float[i].value then
                    matches.two_and_three = true
                    matches.two_and_three_value = v.value
                else
                    matches.two_and_three = false
                end
                staticValueFinder.matchesTable[i].float = matches
            end
            for i, v in ipairs(staticValueFinder.setOne.double) do
                staticValueFinder.matchesTable[i].double = {}
                local matches = {}
                if v.value == staticValueFinder.setTwo.double[i].value then
                    matches.one_and_two = true
                    matches.one_and_two_value = v.value
                else
                    matches.one_and_two = false
                end
                if v.value == staticValueFinder.setThree.double[i].value then
                    matches.one_and_three = true
                    matches.one_and_three_value = v.value
                else
                    matches.one_and_three = false
                end
                if staticValueFinder.setThree.double[i].value == staticValueFinder.setTwo.double[i].value then
                    matches.two_and_three = true
                    matches.two_and_three_value = v.value
                else
                    matches.two_and_three = false
                end
                staticValueFinder.matchesTable[i].double = matches
            end
            for i, v in ipairs(staticValueFinder.setOne.xor) do
                staticValueFinder.matchesTable[i].xor = {}
                local matches = {}
                if v.value == staticValueFinder.setTwo.xor[i].value then
                    matches.one_and_two = true
                    matches.one_and_two_value = v.value
                else
                    matches.one_and_two = false
                end
                if v.value == staticValueFinder.setThree.xor[i].value then
                    matches.one_and_three = true
                    matches.one_and_three_value = v.value
                else
                    matches.one_and_three = false
                end
                if staticValueFinder.setThree.xor[i].value == staticValueFinder.setTwo.xor[i].value then
                    matches.two_and_three = true
                    matches.two_and_three_value = v.value
                else
                    matches.two_and_three = false
                end
                staticValueFinder.matchesTable[i].xor = matches
            end
            staticValueFinder.isComparing = true
            staticValueFinder.createEdit()
        end,
        matchesTable = {},
        isComparing = false,
        createEdit = function()
            local first_match = 0
            local first_match_type = ""
            local last_match = 0
            local search_table = {}
            for i, v in ipairs(staticValueFinder.matchesTable) do
                if v.dword.one_and_two == true and v.dword.one_and_three == true and v.dword.two_and_three == true then
                    local should_add = true
                    if first_match == 0 and value == 0 then
                        should_add = false
                    elseif first_match == 0 then
                        first_match = i
                        first_match_type = "dword"
                    end
                    if should_add == true then
                        local value = v.dword.one_and_two_value
                        if first_match_type ~= "dword" then
                            value = value .. "D"
                        end
                        if value ~= search_table[#search_table - 1] then
                            search_table[#search_table + 1] = value
                            last_match = i
                        end
                    end
                elseif v.float.one_and_two == true and v.float.one_and_three == true and v.float.two_and_three == true then
                    local should_add = true
                    if first_match == 0 and value == 0 then
                        should_add = false
                    elseif first_match == 0 then
                        first_match = i
                        first_match_type = "float"
                    end
                    if should_add == true then
                        local value = v.float.one_and_two_value
                        if first_match_type ~= "float" then
                            value = value .. "F"
                        end
                        if value ~= search_table[#search_table - 1] then
                            search_table[#search_table + 1] = value
                            last_match = i
                        end
                    end
                elseif v.qword.one_and_two == true and v.qword.one_and_three == true and v.qword.two_and_three == true then
                    local should_add = true
                    if first_match == 0 and value == 0 then
                        should_add = false
                    elseif first_match == 0 then
                        first_match = i
                        first_match_type = "qword"
                    end
                    if should_add == true then
                        local value = v.qword.one_and_two_value
                        if first_match_type ~= "qword" then
                            value = value .. "Q"
                        end
                        if value ~= search_table[#search_table - 1] then
                            search_table[#search_table + 1] = value
                            last_match = i
                        end
                    end
                elseif v.xor.one_and_two == true and v.xor.one_and_three == true and v.xor.two_and_three == true then
                    local should_add = true
                    if first_match == 0 and value == 0 then
                        should_add = false
                    elseif first_match == 0 then
                        first_match = i
                        first_match_type = "xor"
                    end
                    if should_add == true then
                        local value = v.xor.one_and_two_value
                        if first_match_type ~= "xor" then
                            value = value .. "X"
                        end
                        if value ~= search_table[#search_table - 1] then
                            search_table[#search_table + 1] = value
                            last_match = i
                        end
                    end
                end
                if #search_table == 64 then
                    break
                end
            end
            if #search_table > 2 then
                local save_to_table = {}
                save_to_table.search_table = {}
                local menu_checkboxes = {}
                local menu_true = {}
                local menu_items = {}
                for index, value in ipairs(search_table) do
                    local temp_value = value
                    save_to_table.search_table[index] = temp_value
                    menu_checkboxes[index] = "checkbox"
                    menu_true[index] = true
                    if index == 1 then
                        menu_items[index] = temp_value .. " (Must Include)"
                    else
                        menu_items[index] = temp_value
                    end
                end
                local customizeSearchMenu = gg.prompt(menu_items, menu_true, menu_checkboxes)
                if customizeSearchMenu ~= nil then
                    local temp_search_table = {}
                    for i, v in ipairs(search_table) do
                        if customizeSearchMenu[i] == true or i == 1 then
                            local temp_value = v
                            temp_search_table[#temp_search_table + 1] = v
                        end
                    end
                    search_table = temp_search_table
                end
                local searchRange = last_match - first_match
                searchRange = searchRange * 4 + 5
                local searchString = ""
                for i, v in ipairs(search_table) do
                    searchString = searchString .. v .. ";"
                end
                searchString = searchString .. "::" .. searchRange
                gg.copyText(searchString)
                local gg_flags = {
                    ["double"] = gg.TYPE_DOUBLE,
                    ["dword"] = gg.TYPE_DWORD,
                    ["float"] = gg.TYPE_FLOAT,
                    ["qword"] = gg.TYPE_QWORD,
                    ["xor"] = gg.TYPE_XOR
                }
                local searchFlag = gg_flags[first_match_type]
                gg.setRanges(gg.getRanges())
                gg.clearResults()
                gg.searchNumber(searchString, searchFlag)
                repeat
                    table.remove(search_table, #search_table)
                    local refineString = ""
                    for i, v in ipairs(search_table) do
                        refineString = refineString .. v
                        if #search_table > 1 then
                            refineString = refineString .. ";"
                        end
                    end
                    if #search_table > 1 then
                        refineString = refineString .. "::"
                    end
                    gg.refineNumber(refineString, searchFlag)
                until (#search_table == 0)
                local results = gg.getResults(gg.getResultsCount())
                local offset = 0
                local export_offset = 0
                if staticValueFinder.settings.index > first_match then
                    offset = staticValueFinder.settings.index - first_match
                    offset = offset * 4
                    export_offset = offset
                    for i, v in pairs(results) do
                        results[i].address = results[i].address + offset
                        results[i].flags = staticValueFinder.settings.flags
                    end
                else
                    offset = first_match - staticValueFinder.settings.index
                    offset = offset * 4 + 4
                    export_offset = tonumber("-" .. offset)
                    for i, v in pairs(results) do
                        results[i].address = results[i].address - offset
                        results[i].flags = staticValueFinder.settings.flags
                    end
                end
                gg.loadResults(results)
                if staticValueFinder.settings.expected_range then
                    gg.refineNumber(staticValueFinder.settings.expected_range, staticValueFinder.settings.flags)
                end
                local results = gg.getResults(gg.getResultsCount())
                local menu = gg.prompt({script_title .. "\n\nℹ️ Create Edit ℹ️\nSet name for edit:",
                                        "Set value to:", 
										"Freeze value:", 
										"X4 edit (Only Select One)",
                                        "X8 edit (Only Select One)"},
										{
										"Edit " .. #staticValueFinder.savedEditsTable + 1, 
										results[1].value, 
										false, 
										false, 
										false},
										{
										"text", 
										"number", 
										"checkbox", 
										"checkbox", 
										"checkbox"})
                if menu ~= nil then
                    local prep_edit = menu[2]
                    if menu[4] == true then
                        prep_edit = prep_edit .. "X4"
                    end
                    if menu[5] == true then
                        prep_edit = prep_edit .. "X8"
                    end
                    for i, v in pairs(results) do
                        results[i].value = prep_edit
                        if menu[3] == true then
                            results[i].freeze = menu[3]
                        end
                    end
                    if menu[3] == true then
                        gg.addListItems(results)
                    end
                    gg.setValues(results)
                    save_to_table.edit_name = menu[1]
                    save_to_table.offset = export_offset
                    save_to_table.search_range = searchRange
                    save_to_table.flags = searchFlag
                    save_to_table.edit = prep_edit
                    save_to_table.edit_flags = staticValueFinder.settings.flags
                    save_to_table.freeze = menu[3]
                    save_to_table.expected_range = staticValueFinder.settings.expected_range
                end
                staticValueFinder.savedEditsTable[#staticValueFinder.savedEditsTable + 1] = {
                    edit_table = save_to_table,
                    setOne = staticValueFinder.setOne,
                    setTwo = staticValueFinder.setTwo,
                    setThree = staticValueFinder.setThree,
                    settings = staticValueFinder.settings
                }
                staticValueFinder.makingEdit = true
                staticValueFinder.isComparing = false
                gg.alert(script_title .. "\n\nℹ️ Value has been set. ℹ️ \nTest to verify it is working and then press the floating GG button to either Save or Discard edit.")
            else
                gg.alert(script_title .. "\n\nℹ️ Not enough static values were found to create a search, startover and user a larger range. ℹ️")
            end
        end,
        makingEdit = false,
        currentEdit = {},
        saveConfig = function()
            local file = io.open(staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. ".cfg", "w+")
            file:write("staticValueFinder.savedEditsTable = " .. tostring(staticValueFinder.savedEditsTable))
            file:close()
        end,
        checkConfigFileGame = function()
            dofile(staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. ".cfg")
        end,
        compareMenu = function()
            if not staticValueFinder.setOne.dword then
                local menu = gg.choice({"🔍 Run First Search"}, nil, script_title .. "\n\nℹ️ Select the desired value in your search results and run the search. ℹ️")
                if menu ~= nil then
                    staticValueFinder.closeGameAfterSearch = true
                    staticValueFinder.doingFirstSearch = true
                    staticValueFinder.searchForValues("setOne")
                end
            elseif staticValueFinder.doingSecondSearch == true or staticValueFinder.doingFirstSearch == true then
                gg.alert("restart the game and run the next search")
            elseif not staticValueFinder.setTwo.dword then
                local menu = gg.choice({"🔍 Run Second Search", "🗑️ Start Over"}, nil, script_title .. "\n\nℹ️ Select the desired value in your search results and run the search or start over. ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        staticValueFinder.closeGameAfterSearch = true
                        staticValueFinder.doingSecondSearch = true
                        staticValueFinder.searchForValues("setTwo")
                    end
                    if menu == 2 then
                        staticValueFinder.startOver()
                    end
                end
            elseif not staticValueFinder.setThree.dword then
                local menu = gg.choice({"🔍 Run Third Search", "🗑️ Start Over"}, nil, script_title .. "\n\nℹ️ Select the desired value in your search results and run the search or start over. ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        staticValueFinder.searchForValues("setThree")
                        staticValueFinder.home()
                    end
                    if menu == 2 then
                        staticValueFinder.startOver()
                    end
                end
            else
                local menu = gg.choice({"🔍 ReRun Third Search", 
										"➕ Create Search and Edit", 
										"🗑️ Start Over"},
										nil, 
										script_title .. "\n\nℹ️ Create search and edit or start over. ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        staticValueFinder.setThree = {}
                        staticValueFinder.searchForValues("setThree")
                        staticValueFinder.home()
                    end
                    if menu == 2 then
                        staticValueFinder.compareSets()
                    end
                    if menu == 3 then
                        staticValueFinder.startOver()
                    end
                end
            end
        end,
        home = function()
            if staticValueFinder.makingEdit == true then
                local menu = gg.choice({"✅ Save Edit", 
										"🗑️ Discard Edit"}, 
										nil,
										script_title .. "\n\nℹ️ Save or Discard edit. ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        staticValueFinder.saveConfig()
                        staticValueFinder.makingEdit = false
                        gg.toast("✅ Edit saved ✅")
                    end
                    if menu == 2 then
                        table.remove(staticValueFinder.savedEditsTable, #staticValueFinder.savedEditsTable)
                        staticValueFinder.makingEdit = false
                        gg.toast("🗑️ Edit discarded 🗑️")
                    end
                    staticValueFinder.home()
                end
            elseif staticValueFinder.setOne.dword then
                staticValueFinder.compareMenu()
            else
                local menu_items = {}
                for i, v in ipairs(staticValueFinder.savedEditsTable) do
                    menu_items[i] = "▶️ " .. v.edit_table.edit_name
                end
                menu_items[#menu_items + 1] = "🔍 Find Static Values"
                menu_items[#menu_items + 1] = "🛠️ Fix Saved Search/Edit"
                menu_items[#menu_items + 1] = "🗑️ Delete Saved Edit"
                menu_items[#menu_items + 1] = "❌ Exit"
                local menu = gg.choice(menu_items, nil, script_title .. "\n\nStatic Value Finder")
                if menu ~= nil then
                    if menu == #menu_items then
                        pluginManager.returnHome = false
                    elseif menu == #menu_items - 1 then
                        staticValueFinder.deleteEdit()
                    elseif menu == #menu_items - 2 then
                        staticValueFinder.fixSearchEdit()
                    elseif menu == #menu_items - 3 then
                        staticValueFinder.compareMenu()
                    else
                        staticValueFinder.doEdit(menu)
                    end
                end
            end
        end,
        doEdit = function(edit_index)
            local search_table = staticValueFinder.savedEditsTable[edit_index].edit_table.search_table
            local searchFlag = staticValueFinder.savedEditsTable[edit_index].edit_table.flags
            local searchRange = staticValueFinder.savedEditsTable[edit_index].edit_table.search_range
            local offset = staticValueFinder.savedEditsTable[edit_index].edit_table.offset
            local edit_to = staticValueFinder.savedEditsTable[edit_index].edit_table.edit
            local edit_to_flags = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_flags
            local edit_name = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_name
            local freeze = staticValueFinder.savedEditsTable[edit_index].edit_table.freeze
            local expected_range = staticValueFinder.savedEditsTable[edit_index].edit_table.expected_range
            local searchString = ""
            local temp_search_table = {}
            for i, v in ipairs(search_table) do
                local temp_val = v
                temp_search_table[i] = temp_val
            end
            for i, v in ipairs(temp_search_table) do
                searchString = searchString .. v .. ";"
            end
            searchString = searchString .. "::" .. searchRange
            gg.setRanges(gg.getRanges())
            gg.clearResults()
            gg.searchNumber(searchString, searchFlag)
            repeat
                table.remove(temp_search_table, #temp_search_table)
                local refineString = ""
                for i, v in ipairs(temp_search_table) do
                    refineString = refineString .. v
                    if #temp_search_table > 1 then
                        refineString = refineString .. ";"
                    end
                end
                if #temp_search_table > 1 then
                    refineString = refineString .. "::"
                end
                gg.refineNumber(refineString, searchFlag)
            until (#temp_search_table == 0)
            local results = gg.getResults(gg.getResultsCount())
            for i, v in pairs(results) do
                results[i].address = results[i].address + offset
                results[i].flags = edit_to_flags
            end
            gg.loadResults(results)
            if expected_range then
                gg.refineNumber(expected_range, edit_to_flags)
            end
            local results = gg.getResults(gg.getResultsCount())
            for i, v in ipairs(results) do
                v.value = edit_to
                v.freeze = freeze
            end
            if freeze == true then
                gg.addListItems(results)
            else
                gg.setValues(results)
            end
            gg.toast("✅ " .. edit_name .. " ✅")
        end,
        fixSearchEdit = function()
            local menu_items = {}
            for i, v in ipairs(staticValueFinder.savedEditsTable) do
                menu_items[i] = "▶️ " .. v.edit_table.edit_name
            end
            local menu = gg.choice(menu_items, nil, script_title .. "\n\nℹ️ Select Search/Edit to fix. ℹ️")
            if menu ~= nil then
                staticValueFinder.settings = staticValueFinder.savedEditsTable[menu].settings
                staticValueFinder.setOne = staticValueFinder.savedEditsTable[menu].setOne
                staticValueFinder.setTwo = staticValueFinder.savedEditsTable[menu].setTwo
                staticValueFinder.setThree = {}
                staticValueFinder.closeGameAfterSearch = false
                staticValueFinder.compareMenu()
            end
        end,
        deleteEdit = function()
            local menu_items = {}
            for i, v in ipairs(staticValueFinder.savedEditsTable) do
                menu_items[i] = "▶️ " .. v.edit_table.edit_name
            end
            local menu = gg.multiChoice(menu_items, nil,
                script_title .. "\n\nℹ️ Select Search/Edits to delete. ℹ️")
            if menu ~= nil then
                local confirm = gg.choice({"✅ Yes delete the edits", 
											"❌ No"}, 
											nil, 
											script_title .. "\n\nℹ️ Are you sure? ℹ\nAre you sure you want to delete these edits, this can not be undone? ")
                if confirm ~= nil then
                    if confirm == 1 then
                        for k, v in pairs(staticValueFinder.savedEditsTable) do
                            for key, value in pairs(menu) do
                                if k == key then
                                    staticValueFinder.savedEditsTable[k] = "delete"
                                end
                            end
                        end
                        ::get_next::
                        local count = 1
                        local do_until = #staticValueFinder.savedEditsTable + 1
                        for i, v in pairs(staticValueFinder.savedEditsTable) do
                            count = count + 1
                            if type(v) == "string" then
                                table.remove(staticValueFinder.savedEditsTable, i)
                                break
                            end
                        end
                        if count < do_until then
                            goto get_next
                        end
                        staticValueFinder.saveConfig()
                        gg.toast("✅ Edits Deleted ✅")
                    end
                end
            end
        end
    }

    if pcall(staticValueFinder.checkFile, staticValueFinder.savePath .. "/created") == false then
        staticValueFinder.createDirectory()
    end
    if pcall(staticValueFinder.checkConfigFileGame) == false then
        staticValueFinder.savedEditsTable = {}
        staticValueFinder.saveConfig()
    end

    if pcall(staticValueFinder.checkFile, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setOne.lua") == false then
        staticValueFinder.closeGameAfterSearch = true
    end

    pcall(staticValueFinder.loadFile, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setOne.lua")
    pcall(staticValueFinder.loadFile, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setTwo.lua")
    pcall(staticValueFinder.loadFile, staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. "setThree.lua")

    pluginManager.returnHome = true
    pluginManager.returnPluginTable = "staticValueFinder"
    staticValueFinder.home()
end
