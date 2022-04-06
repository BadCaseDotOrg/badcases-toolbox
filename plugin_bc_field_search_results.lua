fieldSearchResults = {
    --[[
	---------------------------------------
	
	fieldSearchResults.home()
	
	---------------------------------------
	]] --
    home = function()
        local results = {}
        local class_names = {}
        for i, v in pairs(dumpSearcher.fieldResults) do
            local name_string = "Namespace: " .. dump_cs_table[v[1]].namespace .. "\n"
            if dump_cs_table[v[1]].class then
                name_string = name_string .. "Class Name: " .. dump_cs_table[v[1]].class .. "\n"
            elseif dump_cs_table[v[1]].struct then
                name_string = name_string .. "Struct Name: " .. dump_cs_table[v[1]].struct .. "\n"
            end
            name_string = name_string .. "Field Name: " .. dump_cs_table[v[1]].fields[v[2]].field_name .. "\n"
            name_string = name_string .. "Field Type: " .. dump_cs_table[v[1]].fields[v[2]].field_type .. "\n"
            name_string = name_string .. "Field Offset: " .. dump_cs_table[v[1]].fields[v[2]].field_offset .. "\n"
            results[#results + 1] = name_string
            if dump_cs_table[v[1]].class then
                class_names[#class_names + 1] = string.gsub(dump_cs_table[v[1]].class, ".+ class (.+) .+", "%1"):gsub(" // TypeDefIndex.+", ""):gsub("(.+) : .+", "%1"):gsub("(.+), .+", "%1"):gsub(" :", "")
            elseif dump_cs_table[v[1]].struct then
                class_names[#class_names + 1] = string.gsub(dump_cs_table[v[1]].struct, ".+ struct (.+) .+", "%1"):gsub(" // TypeDefIndex.+", ""):gsub("(.+) : .+", "%1"):gsub("(.+), .+", "%1"):gsub(" :", "")
            end
        end
        local results_menu = gg.choice(results, nil, script_title .. "\n\nℹ️ Field search results. ℹ️")
        if results_menu ~= nil then
            gg.toast(script_title .. "\n\nℹ️ Loading Plugin ℹ️")
            pluginManager.defaultHandler("class_results", class_names[results_menu])
        end
    end
}

fieldSearchResults.home()
