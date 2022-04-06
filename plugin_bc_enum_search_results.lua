enumSearchResults = {
    --[[
	---------------------------------------
	
	enumSearchResults.home()
	
	---------------------------------------
	]] --
    home = function()
        local cleaned_table = {}
        local added_table = {}
        for i, v in pairs(dumpSearcher.enumResults) do
            if not added_table[v[1]] then
                added_table[v[1]] = true
                local name_string = ""
                for index, value in pairs(dump_cs_table[v[1]].fields) do
                    if name_string == "" then
                        name_string = value.enum_type .. "\n"
                    end
                    name_string = name_string .. value.enum_name .. " = " .. value.enum_value .. "\n"
                end
                cleaned_table[#cleaned_table + 1] = name_string
            end
        end
        local results_menu = gg.choice(cleaned_table, nil, script_title .. "\n\nℹ️ Enum search results. ℹ️")
        if results_menu ~= nil then
            gg.copyText(cleaned_table[results_menu])
            gg.toast(script_title .. "\n\nℹ️ List Copied To Clipboard ℹ️")
        end
    end
}

enumSearchResults.home()
