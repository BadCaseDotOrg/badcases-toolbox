methodSearchResults = {
    --[[
	---------------------------------------
	
	methodSearchResults.home()
	
	---------------------------------------
	]] --
    home = function()
        pluginManager.returnHome = true
        pluginManager.returnPluginTable = "methodSearchResults"
        if results_loaded ~= true then
            gg.clearList()
            local results = {}
            if dumpSearcher.methodResults then
                for i, v in pairs(dumpSearcher.methodResults) do
                    local name_string = "Namespace: " .. dump_cs_table[v[1]].namespace .. "\n"
                    if dump_cs_table[v[1]].class then
                        name_string = name_string .. "Class Name: " .. dump_cs_table[v[1]].class .. "\n"
                    end
                    if dump_cs_table[v[1]].struct then
                        name_string = name_string .. "Struct Name: " .. dump_cs_table[v[1]].struct .. "\n"
                    end
                    name_string = name_string .. "Method Name: " .. dump_cs_table[v[1]].methods[v[2]].method_name .. "\n"
                    name_string = name_string .. "Offset: " .. dump_cs_table[v[1]].methods[v[2]].method_offset .. "\n"
                    results[i] = {
                        address = dump_cs_table[v[1]].methods[v[2]].method_offset + BASEADDR,
                        flags = gg.TYPE_DWORD,
                        name = name_string
                    }
                end
                gg.addListItems(results)
                gg.alert(script_title .. "\n\nℹ️ " .. #results .. " results have been added to your save list. ℹ️")
                results_loaded = true
            else
                gg.alert(script_title .. "\n\nℹ️ You must have search results from Search Dump.cs first. ℹ️")
                pluginManager.returnHome = false
                pluginManager.home()
            end
        elseif #gg.getSelectedListItems() == 1 then
            local passed_data = gg.getSelectedListItems()[1].name:gsub(".+Method Name: (.+){ }.+", "%1"):gsub(".+ (.+)[%(].+", "%1")
            gg.toast(script_title .. "\n\nℹ️ Loading Plugin ℹ️")
            pluginManager.callPlugin(pluginsDataPath .. "plugin_bc_il2cpp_edits.lua", "il2cppEdits", passed_data)
        else
            results_loaded = false
            pluginManager.returnHome = false
            pluginManager.home()
        end
    end
}

pluginManager.returnHome = true
pluginManager.returnPluginTable = "methodSearchResults"
methodSearchResults.home()
