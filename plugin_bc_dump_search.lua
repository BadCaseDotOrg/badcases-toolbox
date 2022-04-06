dumpHandler.loadDumpData()
dumpSearcher = {
    methodResults = {},
    enumResults = {},
    fieldResults = {},
    --[[
	---------------------------------------
	
	dumpSearcher.caseSensitive()
	
	---------------------------------------
	]] --
    caseSensitive = function(passed_string, is_case_sensitive)
        if is_case_sensitive == false then
            passed_string = string.lower(passed_string)
        end
        return passed_string
    end,
    --[[
	---------------------------------------
	
	dumpSearcher.searchDump()
	
	---------------------------------------
	]] --
    searchDump = function(search_prompt, stype_array)
        local is_case_sensitive = search_prompt[4]
        local all_search_terms = search_prompt[5]
        local search_namespaces = search_prompt[6]
        local search_classes = search_prompt[7]
        local search_methods = search_prompt[8]
        local search_fields = search_prompt[9]
        local search_enums = search_prompt[10]
        local search_term_one = dumpSearcher.caseSensitive(search_prompt[1], is_case_sensitive)
        local search_term_two = dumpSearcher.caseSensitive(search_prompt[2], is_case_sensitive)
        local search_term_three = dumpSearcher.caseSensitive(search_prompt[3], is_case_sensitive)
        local search_term_one_matches = {}
        local search_term_two_matches = {}
        local search_term_three_matches = {}
        if all_search_terms == true then
            for i, v in pairs(dump_cs_table) do
                local search_term_one_found = false
                local search_term_two_found = false
                if #search_term_two == 0 then
                    search_term_two_found = true
                end
                local search_term_three_found = false
                if #search_term_three == 0 then
                    search_term_three_found = true
                end
                local search_term_one_match_types = {}
                local search_term_two_match_types = {}
                local search_term_three_match_types = {}
                if search_namespaces == true then
                    local current_namespace = v.namespace
                    if is_case_sensitive == false then
                        current_namespace = dumpSearcher.caseSensitive(current_namespace, is_case_sensitive)
                    end
                    if current_namespace:find(search_term_one) then
                        search_term_one_found = true
                        search_term_one_match_types["namespace"] = 1
                    end
                    if current_namespace:find(search_term_two) and #search_term_two > 0 then
                        search_term_two_found = true
                        search_term_two_match_types["namespace"] = 1
                    end
                    if current_namespace:find(search_term_three) and #search_term_three > 0 then
                        search_term_three_found = true
                        search_term_three_match_types["namespace"] = 1
                    end
                end
                if search_classes == true and (v.class or v.struct) then
                    local current_class = ""
                    if v.class then
                        current_class = v.class
                    else
                        current_class = v.struct
                    end
                    if is_case_sensitive == false then
                        current_class = dumpSearcher.caseSensitive(current_class, is_case_sensitive)
                    end
                    if current_class:find(search_term_one) then
                        search_term_one_found = true
                        search_term_one_match_types["class_struct"] = 1
                    end
                    if current_class:find(search_term_two) and #search_term_two > 0 then
                        search_term_two_found = true
                        search_term_two_match_types["class_struct"] = 1
                    end
                    if current_class:find(search_term_three) and #search_term_three > 0 then
                        search_term_three_found = true
                        search_term_three_match_types["class_struct"] = 1
                    end
                end
                if search_fields == true and v.fields and (v.class or v.struct) then
                    local current_fields = tostring(v.fields):gsub("-- table%([0-9a-z]+%)", "")
                    if is_case_sensitive == false then
                        current_fields = dumpSearcher.caseSensitive(current_fields, is_case_sensitive)
                    end
                    if current_fields:find(search_term_one) then
                        search_term_one_found = true
                        search_term_one_match_types["field"] = 1
                    end
                    if current_fields:find(search_term_two) and #search_term_two > 0 then
                        search_term_two_found = true
                        search_term_two_match_types["field"] = 1
                    end
                    if current_fields:find(search_term_three) and #search_term_three > 0 then
                        search_term_three_found = true
                        search_term_three_match_types["field"] = 1
                    end
                end
                if search_enums == true and v.fields and v.enum then
                    local current_fields = tostring(v.fields):gsub("-- table%([0-9a-z]+%)", "")
                    if is_case_sensitive == false then
                        current_fields = dumpSearcher.caseSensitive(current_fields, is_case_sensitive)
                    end
                    if current_fields:find(search_term_one) then
                        search_term_one_found = true
                        search_term_one_match_types["enum"] = 1
                    end
                    if current_fields:find(search_term_two) and #search_term_two > 0 then
                        search_term_two_found = true
                        search_term_two_match_types["enum"] = 1
                    end
                    if current_fields:find(search_term_three) and #search_term_three > 0 then
                        search_term_three_found = true
                        search_term_three_match_types["enum"] = 1
                    end
                end
                if search_term_one_found == true and search_term_two_found == true and search_term_three_found == true then
                    if search_term_one_match_types["enum"] or search_term_two_match_types["enum"] or
                        search_term_three_match_types["enum"] then
                        for index, value in pairs(v.fields) do
                            if value.enum_name:find(search_term_one) or (value.enum_name:find(search_term_two) and #search_term_two > 0) or (value.enum_name:find(search_term_three) and #search_term_three > 0) then
                                table.insert(dumpSearcher.enumResults, {i, index})
                            end
                        end
                    end
                    if search_term_one_match_types["field"] or search_term_two_match_types["field"] or
                        search_term_three_match_types["field"] then
                        for index, value in pairs(v.fields) do
                            if value.field_name:find(search_term_one) or (value.field_name:find(search_term_two) and #search_term_two > 0) or (value.field_name:find(search_term_three) and #search_term_three > 0) then
                                table.insert(dumpSearcher.fieldResults, {i, index})
                            end
                        end
                    end
                end
                if search_methods == true and v.methods then
                    for index, value in pairs(v.methods) do
                        local found_in_method = false
                        local current_method = tostring(value):gsub("-- table%([0-9a-z]+%)", "")
                        if is_case_sensitive == false then
                            current_method = dumpSearcher.caseSensitive(current_method, is_case_sensitive)
                        end
                        local search_term_one_found_loc = false
                        local search_term_two_found_loc = false
                        local search_term_three_found_loc = false
                        if current_method:find(search_term_one) then
                            search_term_one_found_loc = true
                            if search_term_two_found == true and search_term_three_found == true then
                                table.insert(dumpSearcher.methodResults, {i, index})
                                if search_term_two_match_types["field"] or search_term_three_match_types["field"] then
                                    for ind, val in pairs(v.fields) do
                                        if (val.field_name:find(search_term_two) and #search_term_two > 0) or (val.field_name:find(search_term_three) and #search_term_three > 0) then
                                            table.insert(dumpSearcher.fieldResults, {i, ind})
                                        end
                                    end
                                end
                            end
                        end
                        if current_method:find(search_term_two) then
                            search_term_two_found_loc = true
                            if (search_term_one_found == true or search_term_one_found_loc == true) and
                                (search_term_three_found == true or search_term_three_found_loc == true) then
                                table.insert(dumpSearcher.methodResults, {i, index})
                                if search_term_one_match_types["field"] or search_term_three_match_types["field"] then
                                    for ind, val in pairs(v.fields) do
                                        if (val.field_name:find(search_term_one) and #search_term_one > 0) or (val.field_name:find(search_term_three) and #search_term_three > 0) then
                                            table.insert(dumpSearcher.fieldResults, {i, ind})
                                        end
                                    end
                                end
                            end
                        end
                        if current_method:find(search_term_three) then
                            search_term_three_found_loc = true
                            if (search_term_one_found == true or search_term_one_found_loc == true) and
                                (search_term_two_found == true or search_term_two_found_loc == true) then
                                table.insert(dumpSearcher.methodResults, {i, index})
                                if search_term_one_match_types["field"] or search_term_two_match_types["field"] then
                                    for ind, val in pairs(v.fields) do
                                        if (val.field_name:find(search_term_one) and #search_term_one > 0) or (val.field_name:find(search_term_two) and #search_term_two > 0) then
                                            table.insert(dumpSearcher.fieldResults, {i, ind})
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif all_search_terms == false then
            for i, v in pairs(dump_cs_table) do
                if search_namespaces == true then
                    local current_namespace = v.namespace
                    if is_case_sensitive == false then
                        current_namespace = dumpSearcher.caseSensitive(current_namespace, is_case_sensitive)
                    end
                    if current_namespace:find(search_term_one) or (#search_term_two > 0 and current_namespace:find(search_term_two)) or (#search_term_three > 0 and current_namespace:find(search_term_three)) then
                        if (v.class or v.struct) and v.methods then
                            for index, value in pairs(v.methods) do
                                table.insert(dumpSearcher.methodResults, {i, index})
                            end
                        end
                        if (v.class or v.struct) and v.fields then
                            for index, value in pairs(v.fields) do
                                table.insert(dumpSearcher.fieldResults, {i, index})
                            end
                        end
                        if v.enum and v.fields then
                            for index, value in pairs(v.fields) do
                                table.insert(dumpSearcher.enumResults, {i, index})
                            end
                        end
                    end
                end
                if search_classes == true and (v.class or v.struct) then
                    local current_class = ""
                    if v.class then
                        current_class = v.class
                    else
                        current_class = v.struct
                    end
                    if is_case_sensitive == false then
                        current_class = dumpSearcher.caseSensitive(current_class, is_case_sensitive)
                    end
                    if current_class:find(search_term_one) or
                        (#search_term_two > 0 and current_class:find(search_term_two)) or (#search_term_three > 0 and current_class:find(search_term_three)) then
                        if (v.class or v.struct) and v.methods then
                            for index, value in pairs(v.methods) do
                                table.insert(dumpSearcher.methodResults, {i, index})
                            end
                        end
                        if (v.class or v.struct) and v.fields then
                            for index, value in pairs(v.fields) do
                                table.insert(dumpSearcher.fieldResults, {i, index})
                            end
                        end
                    end
                end
                if search_methods == true and v.methods then
                    for index, value in pairs(v.methods) do
                        local current_method = value.method_name
                        if is_case_sensitive == false then
                            current_method = dumpSearcher.caseSensitive(current_method, is_case_sensitive)
                        end
                        if current_method:find(search_term_one) or (#search_term_two > 0 and current_method:find(search_term_two)) or (#search_term_three > 0 and current_method:find(search_term_three)) then
                            table.insert(dumpSearcher.methodResults, {i, index})
                        end
                    end
                end
                if search_fields == true and v.fields and (v.class or v.struct) then
                    for index, value in pairs(v.fields) do
                        local current_field = value.field_name
                        if is_case_sensitive == false then
                            current_field = dumpSearcher.caseSensitive(current_field, is_case_sensitive)
                        end
                        if current_field:find(search_term_one) or (#search_term_two > 0 and current_field:find(search_term_two)) or (#search_term_three > 0 and current_field:find(search_term_three)) then
                            table.insert(dumpSearcher.fieldResults, {i, index})
                        end
                    end
                end
                if search_enums == true and v.fields and v.enum then
                    for index, value in pairs(v.fields) do
                        local current_field = value.enum_name
                        if is_case_sensitive == false then
                            current_field = dumpSearcher.caseSensitive(current_field, is_case_sensitive)
                        end
                        if current_field:find(search_term_one) or (#search_term_two > 0 and current_field:find(search_term_two)) or (#search_term_three > 0 and current_field:find(search_term_three)) then
                            table.insert(dumpSearcher.enumResults, {i, index})
                        end
                    end
                end

            end
        end
        local cleaned_methods = {}
        for i, v in pairs(dumpSearcher.methodResults) do
            local method_found = false
            for index, value in pairs(cleaned_methods) do
                if v[1] == value[1] and v[2] == value[2] then
                    method_found = true
                    break
                end
            end
            if method_found == false then
                table.insert(cleaned_methods, v)
            end
        end
        dumpSearcher.methodResults = cleaned_methods
        local cleaned_methods = {}
        for i, v in pairs(dumpSearcher.fieldResults) do
            local method_found = false
            for index, value in pairs(cleaned_methods) do
                if v[1] == value[1] and v[2] == value[2] then
                    method_found = true
                    break
                end
            end
            if method_found == false then
                table.insert(cleaned_methods, v)
            end
        end
        dumpSearcher.fieldResults = cleaned_methods
        local cleaned_methods = {}
        for i, v in pairs(dumpSearcher.enumResults) do
            local method_found = false
            for index, value in pairs(cleaned_methods) do
                if v[1] == value[1] then
                    method_found = true
                    break
                end
            end
            if method_found == false then
                table.insert(cleaned_methods, v)
            end
        end
        dumpSearcher.enumResults = cleaned_methods
        if #stype_array > 0 then
            local type_keys = {}
            for i, v in pairs(stype_array) do
                type_keys[v] = 1
            end
            local sort_method_types = {}
            for i, v in pairs(dumpSearcher.methodResults) do
                if type_keys[dump_cs_table[v[1]]["methods"][v[2]].method_type] then
                    table.insert(sort_method_types, v)
                end
            end
            dumpSearcher.methodResults = sort_method_types
            local sort_field_types = {}
            for i, v in pairs(dumpSearcher.fieldResults) do
                if type_keys[dump_cs_table[v[1]]["fields"][v[2]].field_type] then
                    table.insert(sort_field_types, v)
                end
            end
            dumpSearcher.fieldResults = sort_field_types
        end
        local search_results = gg.choice({"🔘 Method Results (" .. #dumpSearcher.methodResults .. ")",
                                          "🔘 Field Results (" .. #dumpSearcher.fieldResults .. ")",
                                          "🔘 Enum Results (" .. #dumpSearcher.enumResults .. ")"},
										  nil,
										  script_title .. "\n\nℹ️ Search Results ℹ️")
        if search_results ~= nil then
            local handler = ""
            if search_results == 1 then
                handler = "method_results"
            end
            if search_results == 2 then
                handler = "field_results"
            end
            if search_results == 3 then
                handler = "enum_results"
            end
            pluginManager.defaultHandler(handler)
        end
    end,
    --[[
	---------------------------------------
	
	dumpSearcher.searchPrompt()
	
	---------------------------------------
	]] --
    searchPrompt = function(sterm1, sterm2, batch)
        dumpSearcher.methodResults = {}
        dumpSearcher.enumResults = {}
        dumpSearcher.fieldResults = {}
        local temp_types = bc_toolbox_method_types
        local search_prompt_types = gg.multiChoice(temp_types, nil, script_title .. "\n\nℹ️ Select Method Types (select none for all) ℹ️")
        if search_prompt_types ~= nil then
            search_all = true
            stype_array = {}
            for k, value in pairs(search_prompt_types) do
                if search_prompt_types[k] == true then
                    search_all = false
                end
            end
            if search_all == false then
                for k, value in pairs(search_prompt_types) do
                    if search_prompt_types[k] == true then
                        table.insert(stype_array, bc_toolbox_method_types[k])
                    end
                end
            end
            local search_prompt = gg.prompt({script_title ..
											 "\n\nℹ️ Search Term 1 ℹ  ⬇️ Scroll Down ⬇️", 
											 "ℹ️ Search Term 2 ℹ",
                                             "ℹ️ Search Term 3 ℹ", 
											 "Case sensitive",
                                             "Must contain all search terms", 
											 "Search namespaces", 
											 "Search classes",
                                             "Search methods", 
											 "Search fields", 
											 "Search enums"}, 
											 {
											 [1] = sterm1,
											 [2] = sterm2,
											 [4] = true,
											 [5] = true,
											 [6] = true,
											 [7] = true,
											 [8] = true,
											 [9] = true,
											 [10] = true
											 }, {
											 [1] = "text",
											 [2] = "text",
											 [3] = "text",
											 [4] = "checkbox",
											 [5] = "checkbox",
											 [6] = "checkbox",
											 [7] = "checkbox",
											 [8] = "checkbox",
											 [9] = "checkbox",
											 [10] = "checkbox"
											 })
            if search_prompt ~= nil then
                dumpSearcher.searchDump(search_prompt, stype_array)
            end
        end
    end,
    --[[
	---------------------------------------
	
	dumpSearcher.removeNamespaces()
	
	---------------------------------------
	]] --
    removeNamespaces = function()
        local namespaceNameAsKey = {}
        local fixedNamespaceTable = {}
        for i, v in pairs(dump_cs_table) do
            if v.namespace and v.namespace ~= "// Namespace: " then
                if v.namespace:find("// Namespace: ") then
                    local cleaned_class_name = v.namespace:gsub("// Namespace: (.+)", "%1")
                    if cleaned_class_name:find("^[a-zA-Z0-9]") then
                        namespaceNameAsKey[cleaned_class_name] = cleaned_class_name
                    end
                else
                    namespaceNameAsKey[v.namespace] = v.namespace
                end
            end
        end
        for k, value in pairs(namespaceNameAsKey) do
            fixedNamespaceTable[#fixedNamespaceTable + 1] = value
        end
        table.sort(fixedNamespaceTable)
        local selectNamespaceMenu = gg.multiChoice(fixedNamespaceTable)
        if selectNamespaceMenu ~= nil then
            for i, v in pairs(dump_cs_table) do
                for index, value in pairs(selectNamespaceMenu) do
                    if v.namespace and v.namespace:find("// Namespace: " .. fixedNamespaceTable[index]) then
                        dump_cs_table[i] = "remove"
                    elseif v.namespace and v.namespace:find(fixedNamespaceTable[index]) then
                        dump_cs_table[i] = "remove"
                    end
                end
            end
            local temp_dump_cs_table = {}
            for i, v in pairs(dump_cs_table) do
                if type(v) == "table" then
                    temp_dump_cs_table[#temp_dump_cs_table + 1] = v
                end
            end
            dump_cs_table = temp_dump_cs_table
            gg.toast(script_title .. "\n\nℹ️ Namespaces Removed ℹ️")
            dumpHandler.saveJSON()
            gg.toast(script_title .. "\n\nℹ️ Dump Data Updated ℹ️")
        end
    end,
    --[[
	---------------------------------------
	
	dumpSearcher.home()
	
	---------------------------------------
	]] --
    home = function()
        if save_dump == true then
            save_dump = false
            gg.sleep(300)
            dumpHandler.saveJSON()
        end
        local menu = gg.choice({"🔍 Search", 
								"➖ Remove Namespaces", 
								"🔄 Reprocess dump.cs"}, 
								nil,
								script_title .. "\n\nℹ️ Search Dump.cs ℹ️")
        if menu ~= nil then
            if menu == 1 then
                dumpSearcher.searchPrompt()
            end
            if menu == 2 then
                dumpSearcher.removeNamespaces()
                dumpSearcher.home()
            end
            if menu == 3 then
                gg.toast(script_title .. "\n\nℹ️ Reprocessing dump.cs ℹ️")
                dumpHandler.importDump()
                dumpSearcher.home()
            end
        end
    end
}
dumpSearcher.home()
