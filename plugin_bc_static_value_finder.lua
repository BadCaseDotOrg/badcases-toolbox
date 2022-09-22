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
            local values = range
            local fixedRange = range * 4
            local startAddress = address - fixedRange
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
            local values = range
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
            if #staticValueFinder.desiredValue ~= 1 then
                bc.Alert("Nothing Selected", "Select the desired value in your search results first", "⚠️")
                goto done
            end
            local edit_type = staticValueFinder.desiredValue[1].flags
            local menu_range = 50
            local menu_above = true
            local menu_under = false
            local menu = {}
            local edit_index = 0
            if staticValueFinder.settings then
                menu[1] = staticValueFinder.settings.range
            else
                menu = gg.prompt({"Search Range"}, {menu_range, nil}, {"number"})
            end
            if menu ~= nil then
                local range = menu[1]
                staticValueFinder.getAbove(staticValueFinder.desiredValue[1].address, range)
                edit_index = #staticValueFinder.dwordTable + 1
                staticValueFinder.getUnder(staticValueFinder.desiredValue[1].address, range)
                staticValueFinder.getOtherTypes()
                staticValueFinder[setName] = {
                    dword = staticValueFinder.dwordTable,
                    qword = staticValueFinder.qwordTable,
                    float = staticValueFinder.floatTable,
                    double = staticValueFinder.doubleTable,
                    xor = staticValueFinder.xorTable
                }
                local ggTypes = {
                    [1] = "dword",
                    [2] = "qword",
                    [3] = "float",
                    [4] = "double",
                    [5] = "xor"
                }
                staticValueFinder[setName].desiredValue = staticValueFinder.desiredValue
                for index, value in pairs(ggTypes) do
                    for i, v in pairs(staticValueFinder[setName][value]) do
                        if staticValueFinder[setName].desiredValue[1].address > v.address then
                            staticValueFinder[setName][value][i].offset = staticValueFinder[setName].desiredValue[1].address - v.address
                        else
                            staticValueFinder[setName][value][i].offset = tonumber("-" .. v.address - staticValueFinder[setName].desiredValue[1].address)
                        end
                    end
                end
                local file = io.open(staticValueFinder.savePath .. "/" .. gg.getTargetPackage() .. setName .. ".lua", "w+")
                file:write("staticValueFinder." .. setName .. " = " .. tostring(staticValueFinder[setName]) .. "\nstaticValueFinder.settings = {range = " .. range .. ", flags = " .. edit_type .. ", index = " .. edit_index .. "}\nstaticValueFinder." .. setName .. ".desiredValue = " .. tostring(staticValueFinder.desiredValue))
                file:close()
                if staticValueFinder.closeGameAfterSearch == true then
                    bc.Alert("Values Saved", "Restart the game, find your value again and run the next search. ", "ℹ️")
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
        compareSet = function(ggType)
            local matches = {}
            local added = {}
            for i, v in ipairs(staticValueFinder.setOne[ggType]) do
                for index, value in ipairs(staticValueFinder.setTwo[ggType]) do
                    if not added[value.address] and v.offset == value.offset and v.value == value.value then
                        matches[#matches + 1] = value
                        added[value.address] = true
                    end
                end
            end
            local added = {}
            local matches_next = {}
            for i, v in ipairs(matches) do
                for index, value in ipairs(staticValueFinder.setThree[ggType]) do
                    if not added[value.address] and v.offset == value.offset and v.value == value.value then
                        matches_next[#matches_next + 1] = value
                        added[value.address] = true
                    end
                end
            end
            return matches_next
        end,
        compareSets = function()
            staticValueFinder.dwordMatches = staticValueFinder.compareSet("dword")
            staticValueFinder.floatMatches = staticValueFinder.compareSet("float")
            staticValueFinder.doubleMatches = staticValueFinder.compareSet("double")
            staticValueFinder.qwordMatches = staticValueFinder.compareSet("qword")
            local tempTable = staticValueFinder.dwordMatches
            staticValueFinder.isComparing = true
            staticValueFinder.createEdit(tempTable)
        end,
        matchesTable = {},
        isComparing = false,
        createEdit = function(matchTable)
            local first_match = 0
            local first_match_address
            local first_match_type = ""
            local last_match = 0
            local search_table = {}
            local range_table = {}
            local gg_table = {}
            if #matchTable > 2 then
                local save_to_table = {}
                save_to_table.search_table = {}
                local menu_checkboxes = {}
                local menu_true = {}
                local menu_items = {}
                local types = {
                    [64] = "E",
                    [16] = "F",
                    [4] = "D",
                    [32] = "Q",
                    [8] = "X"
                }
                for i, v in ipairs(matchTable) do
                    search_table[#search_table + 1] = v.value .. types[v.flags]
                    range_table[#range_table + 1] = v.address - matchTable[1].address
                end
                for index, value in ipairs(search_table) do
                    local temp_value = value
                    menu_checkboxes[index] = "checkbox"
                    menu_true[index] = true
                    if index == 1 then
                        menu_items[index] = temp_value .. " (Must Include)"
                    else
                        menu_items[index] = temp_value
                    end
                end
                local lastTrue
                local customizeSearchMenu = gg.prompt(menu_items, menu_true, menu_checkboxes)
                if customizeSearchMenu ~= nil then
                    local temp_search_table = {}
                    local temp_range_table = {}
                    for index, value in pairs(search_table) do
                        if customizeSearchMenu[index] == true or index == 1 then
                            local temp_value = value
                            temp_search_table[#temp_search_table + 1] = value
                            temp_range_table[#temp_range_table + 1] = range_table[index]
                            lastTrue = index
                        end
                    end
                    search_table = temp_search_table
                    range_table = temp_range_table
                end
                local searchRange = matchTable[#matchTable].address - matchTable[1].address
                searchRange = searchRange + 5
                local searchString = ""
                for i, v in ipairs(search_table) do
                    if i < 65 then
                        searchString = searchString .. v .. ";"
                    end
                end
                searchString = searchString .. "::" .. searchRange
                save_to_table.search_table = search_table
                save_to_table.range_table = range_table
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
                gg.copyText(searchString)
                gg.searchNumber(searchString, searchFlag)
                for i = 1, #search_table - 2 do
                    local refineString = ""
                    for index = 1, #search_table - i do
                        refineString = refineString .. search_table[index]
                        refineString = refineString .. ";"
                    end
                    refineString = refineString .. "::" .. range_table[#range_table - i] + 5
                    if refineString ~= "" then
                        gg.refineNumber(refineString, searchFlag)
                    end
                end
                local sorted_results = {}
                ::next::
                local results = gg.getResults(gg.getResultsCount())
                for i, v in pairs(results) do
                    if i == 1 then
                        table.insert(sorted_results, results[1])
                    end
                    if i > 1 and results[i].address - results[i].address < searchRange then
                        results[i] = nil
                    else
                        results[1] = nil
                        gg.loadResults(results)
                        goto next
                    end
                end
                results = sorted_results
                local offset = 0
                local export_offset = 0
                if staticValueFinder.desiredValue[1].address > matchTable[1].address then
                    offset = staticValueFinder.desiredValue[1].address - matchTable[1].address
                    export_offset = offset
                    for i, v in pairs(results) do
                        results[i].address = results[i].address + offset
                        results[i].flags = staticValueFinder.settings.flags
                    end
                else
                    offset = matchTable[1].address - staticValueFinder.desiredValue[1].address
                    export_offset = tonumber("-" .. offset)
                    for i, v in pairs(results) do
                        results[i].address = results[i].address - offset
                        results[i].flags = staticValueFinder.settings.flags
                    end
                end
                gg.loadResults(results)
                local results = gg.getResults(gg.getResultsCount())
                ::edit_menu::
                local menu = gg.prompt({
                    bc.Prompt("Create Edit", "ℹ️").."\nSet name for edit:", 
                    "Set value to:", 
                    "Freeze", 
                    "Edit All Instances (Only select one)", 
                    "Edit All Instances Address + 4 X4 (Only select one)", 
                    "Edit All Instances Address + 8 X8 (Only select one)", 
                    "Edit All Instances = To Value Below (Only select one)", 
                    "Edit All Instances ~= To Value Below (Only select one)", 
                    "Edit All Instances <= To Value Below (Only select one)",
                    "Edit All Instances >= To Value Below (Only select one)", 
                    "Edit All Instances In Range Below (Only select one)", 
                    "Edit All Instances NOT In Range Below (Only select one)", 
                    "Enter Number Or Number Range (0~100)"
                }, {
                    "Edit " .. #staticValueFinder.savedEditsTable + 1, results[1].value, 
                    false, 
                    true, 
                    false, 
                    false, 
                    false, 
                    false, 
                    false, 
                    false, 
                    false, 
                    false, 
                    ""
                }, {
                    "text", 
                    "number", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "checkbox", 
                    "number"
                })
                if menu ~= nil then
                    local prep_edit = menu[2]
                    local edit_type
                    local edit_type_index
                    local edit_types = {
                        [4] = "edit_all",
                        [5] = "edit_all_x4",
                        [6] = "edit_all_x8",
                        [7] = "edit_all_that_equal",
                        [8] = "edit_all_that_do_not_equal",
                        [9] = "edit_all_less_equal",
                        [10] = "edit_all_greater_equal",
                        [11] = "edit_all_in_range",
                        [12] = "edit_all_not_in_range"
                    }
                    local edit_type_checks = {
                        [4] = function()
                            return true
                        end,
                        [5] = function()
                            return true
                        end,
                        [6] = function()
                            return true
                        end,
                        [7] = function(resultValue)
                            if resultValue == tonumber(menu[13]) then
                                return true
                            end
                        end,
                        [8] = function(resultValue)
                            if resultValue ~= tonumber(menu[13]) then
                                return true
                            end
                        end,
                        [9] = function(resultValue)
                            if resultValue <= tonumber(menu[13]) then
                                return true
                            end
                        end,
                        [10] = function(resultValue)
                            if resultValue >= tonumber(menu[13]) then
                                return true
                            end
                        end,
                        [11] = function(resultValue)
                            local minValue = menu[13]:gsub("(.+)~.+", "%1")
                            minValue = tonumber(minValue)
                            local maxValue = menu[13]:gsub(".+~(.+)", "%1")
                            maxValue = tonumber(maxValue)
                            if resultValue >= minValue and resultValue <= maxValue then
                                return true
                            end
                        end,
                        [12] = function(resultValue)
                            local minValue = menu[13]:gsub("(.+)~.+", "%1")
                            minValue = tonumber(minValue)
                            local maxValue = menu[13]:gsub(".+~(.+)", "%1")
                            maxValue = tonumber(maxValue)
                            if resultValue < minValue or resultValue > maxValue then
                                return true
                            end
                        end
                    }
                    local trueCount = 0
                    local emptyVar = false
                    for i, v in ipairs(menu) do
                        if i >= 4 and i <= 12 and v == true then
                            trueCount = trueCount + 1
                            edit_type = edit_types[i]
                            edit_type_index = i
                            if i > 6 and menu[13] == "" then
                                emptyVar = true
                            end
                        end
                    end
                    if emptyVar == true then
                        bc.Alert("Empty Field", "You must enter a value in the bottom field when using this option.", "⚠️")
                        goto edit_menu
                    end
                    if trueCount > 1 then
                        bc.Alert("Too Many Options", "Only select one of the options labeled (Only select one)", "⚠️")
                        goto edit_menu
                    end
                    if trueCount == 0 then
                        bc.Alert("No Options", "Select one of the options labeled (Only select one)", "⚠️")
                        goto edit_menu
                    end
                    if menu[5] == true then
                        prep_edit = prep_edit .. "X4"
                    end
                    if menu[6] == true then
                        prep_edit = prep_edit .. "X8"
                    end
                    for i, v in pairs(results) do
                        if edit_type_checks[edit_type_index](results[i].value) == true then
                            results[i].value = prep_edit
                            if menu[3] == true then
                                results[i].freeze = menu[3]
                            end
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
                    save_to_table.edit_type = edit_type
                    save_to_table.edit_type_variable = menu[13]
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
                bc.Alert("Value Set", "Test to verify it is working and then press the floating GG button to either Save or Discard edit.", "ℹ️")
            else
                bc.Alert("Not Enough Values", "Not enough static values were found to create a search, startover and user a larger range.", "⚠️")
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
        readyCheck = function()

        end,
        compareMenu = function()
            if not staticValueFinder.setOne.dword then
                local menu = gg.choice({"🔍 Run First Search"}, nil, bc.Choice("Select A Value", "Select the desired value in your search results and run the search.", "ℹ️"))
                if menu ~= nil then
                    staticValueFinder.closeGameAfterSearch = true
                    staticValueFinder.doingFirstSearch = true
                    staticValueFinder.searchForValues("setOne")
                end
            elseif staticValueFinder.doingSecondSearch == true or staticValueFinder.doingFirstSearch == true then
                bc.Alert("Values Saved", "Restart the game and run the next search.", "ℹ️")
            elseif not staticValueFinder.setTwo.dword then
                local menu = gg.choice({"🔍 Run Second Search", "🗑️ Start Over"}, nil, bc.Choice("Select A Value", "Select the desired value in your search results and run the search or start over.", "ℹ️"))
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
                local menu = gg.choice({"🔍 Run Third Search", "🗑️ Start Over"}, nil, bc.Choice("Select A Value", "Select the desired value in your search results and run the search or start over.", "ℹ️"))
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
                local menu = gg.choice({"🔍 ReRun Third Search", "➕ Create Search and Edit", "🗑️ Start Over"}, nil, bc.Choice("Searches Complete", "Create search and edit or start over.", "ℹ️"))
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
                local menu = gg.choice({"✅ Save Edit", "🗑️ Discard Edit"}, nil, bc.Choice("Save Or Discard", "Save or discard this edit.", "ℹ️"))
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
                local menu = gg.choice(menu_items, nil, bc.Choice("nStatic Value Finder", "", "ℹ️"))
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
            local range_table = staticValueFinder.savedEditsTable[edit_index].edit_table.range_table
            local searchFlag = staticValueFinder.savedEditsTable[edit_index].edit_table.flags
            local searchRange = staticValueFinder.savedEditsTable[edit_index].edit_table.search_range
            local offset = staticValueFinder.savedEditsTable[edit_index].edit_table.offset
            local edit_to = staticValueFinder.savedEditsTable[edit_index].edit_table.edit
            local edit_to_flags = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_flags
            local edit_name = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_name
            local freeze = staticValueFinder.savedEditsTable[edit_index].edit_table.freeze
            local edit_type = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_type
            local edit_type_variable = staticValueFinder.savedEditsTable[edit_index].edit_table.edit_type_variable
            local searchString = ""
            for i, v in ipairs(search_table) do
                if i < 65 then
                    searchString = searchString .. v .. ";"
                end
            end
            searchString = searchString .. "::" .. searchRange
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
            gg.copyText(searchString)
            gg.searchNumber(searchString, searchFlag)
            for i = 1, #search_table - 2 do
                local refineString = ""
                for index = 1, #search_table - i do
                    refineString = refineString .. search_table[index]
                    refineString = refineString .. ";"
                end
                refineString = refineString .. "::" .. range_table[#range_table - i] + 5
                if refineString ~= "" then
                    gg.refineNumber(refineString, searchFlag)
                end
            end
            local sorted_results = {}
            ::next::
            local results = gg.getResults(gg.getResultsCount())
            for i, v in pairs(results) do
                if i == 1 then
                    table.insert(sorted_results, results[1])
                end
                if i > 1 and results[i].address - results[i].address < searchRange then
                    results[i] = nil
                else
                    results[1] = nil
                    gg.loadResults(results)
                    goto next
                end
            end
            results = sorted_results
            for i, v in pairs(results) do
                results[i].address = results[i].address + offset
                results[i].flags = edit_to_flags
            end
            results = gg.getValues(results)
            local edit_type_checks = {
                edit_all = function()
                    return true
                end,
                edit_all_x4 = function()
                    return true
                end,
                edit_all_x8 = function()
                    return true
                end,
                edit_all_that_equal = function(resultValue)
                    if resultValue == tonumber(edit_type_variable) then
                        return true
                    end
                end,
                edit_all_that_do_not_equal = function(resultValue)
                    if resultValue ~= tonumber(edit_type_variable) then
                        return true
                    end
                end,
                edit_all_less_equal = function(resultValue)
                    if resultValue <= tonumber(edit_type_variable) then
                        return true
                    end
                end,
                edit_all_greater_equal = function(resultValue)
                    if resultValue >= tonumber(edit_type_variable) then
                        return true
                    end
                end,
                edit_all_in_range = function(resultValue)
                    local minValue = edit_type_variable:gsub("(.+)~.+", "%1")
                    minValue = tonumber(minValue)
                    local maxValue = edit_type_variable:gsub(".+~(.+)", "%1")
                    maxValue = tonumber(maxValue)
                    if resultValue >= minValue and resultValue <= maxValue then
                        return true
                    end
                end,
                edit_all_not_in_range = function(resultValue)
                    local minValue = edit_type_variable:gsub("(.+)~.+", "%1")
                    minValue = tonumber(minValue)
                    local maxValue = edit_type_variable:gsub(".+~(.+)", "%1")
                    maxValue = tonumber(maxValue)
                    if resultValue < minValue or resultValue > maxValue then
                        return true
                    end
                end
            }
            for i, v in ipairs(results) do
                if edit_type_checks[edit_type](v.value) == true then
                    v.value = edit_to
                    v.freeze = freeze
                end
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
            local menu = gg.choice(menu_items, nil, bc.Choice("Fix Edit", "Select edit to fix.", "ℹ️"))
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
            local menu = gg.multiChoice(menu_items, nil, bc.Choice("Select Edits", "Select edits to delete.", "ℹ️"))
            if menu ~= nil then
                local confirm = gg.choice({"✅ Yes delete the edits", "❌ No"}, nil, bc.Choice("Confirm Delete", "Are you sure you want to delete these edits, this can not be undone?", "⚠️"))
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
