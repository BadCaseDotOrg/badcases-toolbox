

function hex_o(n)
    return "0x" .. string.upper(string.format("%x", n))
end

function hexnx(n)
    return string.format("%X", n)
end

------------------------
-----Select Lib End-----
------------------------

script_title = "🧰 BadCase's Toolbox 🧰\nGame: " .. gg.getTargetInfo().label .. "\nPackage: " .. gg.getTargetPackage()
dataPath = gg.EXT_STORAGE .. "/BC_DATA/"
pluginsDataPath = gg.EXT_STORAGE .. "/BC_DATA/plugins/"
configDataPath = gg.EXT_STORAGE .. "/BC_DATA/config/"
arch = gg.getTargetInfo()
game_path = gg.getTargetPackage()
dump_cs_table = {}
bc_toolbox_method_types = {}
bc_toolbox_method_types_all = {}
save_dump = false

dH = {
	--    dumpHandler.createDirectory()
    --    dH.createDirectory()
    createDirectory = function()
        directory_created = true
        bc.createDirectory(dataPath .. game_path .. "/")
        bc.createDirectory(dataPath .. game_path .. "/scripts/")
    end,
    --    dH.importDump()
    importDump = function()
        local startTime = os.time()
        local fileName = gg.prompt({ bc.Prompt("Select Dump.cs","ℹ️")}, nil, { "file" })
        if fileName ~= nil then
            local tempDumpTable = {}
            local content = bc.readFile(fileName[1])
            local delimiter = "\n"
            for match in (content .. delimiter):gmatch("(.-)" .. delimiter) do
                table.insert(tempDumpTable, match);
            end
            local temp_dump_cs_table = {}
            if tempDumpTable[1]:find("/%*") then
                local current_namespace = "Global"
                local capturing_fields = false
                local capturing_enums = false
                local capturing_methods = false
                local capturing_properties = false
                for i, v in pairs(tempDumpTable) do
                    if v:find("^namespace .+") then
                        current_namespace = v:gsub("^namespace (.+)", "%1")
                    end
                    if v:find("	.+ class .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            class = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find(".+ class .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            class = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find("	.+ struct .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            struct = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find(".+ struct .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        table.insert(temp_dump_cs_table, {
                            struct = current_class,
                            namespace = current_namespace
                        })
                    elseif v:find("	.+ enum .+ // TypeDefIndex.+") then
                        current_class = v:gsub("(.+) // .+", "%1")
                        capturing_enums = true
                        table.insert(temp_dump_cs_table, {
                            enum = current_class,
                            namespace = current_namespace
                        })
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    elseif v:find(".+ enum .+ // TypeDefIndex.+") then
                        current_namespace = "Global"
                        current_class = v:gsub("(.+) // .+", "%1")
                        capturing_enums = true
                        table.insert(temp_dump_cs_table, {
                            enum = current_class,
                            namespace = current_namespace
                        })
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    end
                    if capturing_fields == true and (v:find("}") or v:find("// [A-Z]")) then
                        capturing_fields = false
                    end
                    if v:find("// Fields") then
                        capturing_fields = true
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                    end
                    if capturing_methods == true and v:find("}") then
                        capturing_methods = false
                    end
                    if v:find("// Methods") then
                        capturing_methods = true
                        if not temp_dump_cs_table[#temp_dump_cs_table].methods then
                            temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        end
                    end
                    if capturing_enums == true and v:find("}") then
                        capturing_enums = false
                    end
                    if capturing_properties == true and v:find("// [A-Z]") then
                        capturing_properties = false
                    end
                    if v:find("// Properties") then
                        capturing_properties = true
                        if not temp_dump_cs_table[#temp_dump_cs_table].methods then
                            temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        end
                    end
                    if capturing_properties == true and v:find("CompilerGenerated") then
                        method_name_get = v:gsub("(.+ )(.+) {.+", "%1get_%2() { }")
                        method_type_get = v:gsub(".+ (.+) (.+ {).+", "%1"):gsub("[>?%[%]]", "")
                        method_offset_get = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+ .+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_get,
                            method_name = method_name_get,
                            method_type = method_type_get
                        })
                        method_name_set = v:gsub("(.+ )(.+) (.+) {.+", "%1void set_%3(%2 value) { }")
                        method_type_set = "void"
                        method_offset_set = v:gsub(".+} // (.+)", "%1"):gsub(".+-.+ (.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_set,
                            method_name = method_name_set,
                            method_type = method_type_set
                        })
                    elseif capturing_properties == true and v:find("{ get; }") then
                        method_name_get = v:gsub("(.+ )(.+) {.+", "%1get_%2() { }")
                        method_type_get = v:gsub(".+ (.+) (.+ {).+", "%1"):gsub("[>?%[%]]", "")
                        method_offset_get = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_get,
                            method_name = method_name_get,
                            method_type = method_type_get
                        })
                    elseif capturing_properties == true and v:find("{ set; }") then
                        method_name_set = v:gsub("(.+ )(.+) (.+) {.+", "%1void set_%3(%2 value) { }")
                        method_type_set = "void"
                        method_offset_set = v:gsub(".+} // (.+)", "%1"):gsub("(.+)-.+", "%1")
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset_set,
                            method_name = method_name_set,
                            method_type = method_type_set
                        })
                    end
                    if capturing_methods == true and v:find("%); // 0x") then
                        local method_offset = v:gsub(".+// (.+)-.+", "%1")
                        local method_name = v:gsub("(.+);.+", "%1"):gsub("	", "")
                        local method_type = ""
                        if method_name:find(" static ") or method_name:find(" override ") or
                            method_name:find(" internal ") or method_name:find(" virtual ") then
                            method_type = method_name:gsub(".+ .+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        else
                            method_type = method_name:gsub(".+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset,
                            method_name = method_name,
                            method_type = method_type
                        })
                    end
                    if capturing_enums == true and v:find("[A-Za-z0-9]+ =") then
                        local enum_value = v:gsub(".+ = (.+)", "%1"):gsub(",", "")
                        local enum_name = v:gsub("([A-Za-z]+) = .+", "%1"):gsub("	", "")
                        local enum_type = ""
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                            enum_type = enum_type,
                            enum_value = enum_value,
                            enum_name = enum_name
                        })
                    end
                    if capturing_fields == true and v:find("; // 0x") then
                        local field_type = ""
                        local field_offset = ""
                        local field_name = ""
                        if v:find(" static ") or v:find(" readonly ") then
                            field_type = v:gsub(".+ .+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                            field_offset = v:gsub(".+ .+ .+ .+; // (0x.+)", "%1")
                            field_name = v:gsub(".+ .+ .+ (.+); // 0x.+", "%1"):gsub("	", "")
                        else
                            field_type = v:gsub(".+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                            field_offset = v:gsub(".+ .+ .+; // (0x.+)", "%1")
                            field_name = v:gsub(".+ .+ (.+); // 0x.+", "%1"):gsub("	", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                            field_type = field_type,
                            field_offset = field_offset,
                            field_name = field_name
                        })
                    end
                end
            else
                for i, v in pairs(tempDumpTable) do
                    if v:find(" Namespace:") then
                        capturing = false
                        capturing_fields = false
                        capturing_methods = false
                        if tempDumpTable[i + 1]:find(".+ class .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                class = tempDumpTable[i + 1]
                            }
                        elseif tempDumpTable[i + 1]:find(".+ struct .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                struct = tempDumpTable[i + 1]
                            }
                        elseif tempDumpTable[i + 1]:find(".+ enum .+") then
                            capturing = true
                            temp_dump_cs_table[#temp_dump_cs_table + 1] = {
                                namespace = tempDumpTable[i],
                                enum = tempDumpTable[i + 1]
                            }
                        end
                    end
                    if capturing == true and v:find("// Methods") then
                        temp_dump_cs_table[#temp_dump_cs_table].methods = {}
                        capturing_methods = true
                        capturing_fields = false
                    end
                    if v:find("// Properties") then
                        capturing_fields = false
                    end
                    if capturing_fields == true then
                        if #v > 0 and v:find(" // 0x") and temp_dump_cs_table[#temp_dump_cs_table].class then
                            local field_type = ""
                            local field_offset = ""
                            local field_name = ""
                            if v:find(" static ") or v:find(" readonly ") then
                                field_type = v:gsub(".+ .+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                                field_offset = v:gsub(".+ .+ .+ .+; // (0x.+)", "%1")
                                field_name = v:gsub(".+ .+ .+ (.+); // 0x.+", "%1")
                            else
                                field_type = v:gsub(".+ (.+) .+; // 0x.+", "%1"):gsub("[	*%[%]]", "")
                                field_offset = v:gsub(".+ .+ .+; // (0x.+)", "%1")
                                field_name = v:gsub(".+ .+ (.+); // 0x.+", "%1")
                            end
                            table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                                field_type = field_type,
                                field_offset = field_offset,
                                field_name = field_name
                            })
                        elseif #v > 0 and v:find(" %= ") and temp_dump_cs_table[#temp_dump_cs_table].enum then
                            local field_type = ""
                            local field_value = ""
                            local field_name = ""
                            field_type = v:gsub(".+ const (.+) .+ %= [%-0-9]+;", "%1"):gsub("[	*%[%]]", "")
                            field_value = v:gsub(".+ const .+ .+ %= ([%-0-9]+);", "%1")
                            field_name = v:gsub(".+ const .+ (.+) %= [%-0-9]+;", "%1")
                            table.insert(temp_dump_cs_table[#temp_dump_cs_table].fields, {
                                enum_type = field_type,
                                enum_value = field_value,
                                enum_name = field_name
                            })
                        end
                    end
                    if capturing_methods == true and v:find("	// RVA:") and v:find(" VA: ") and v:find("MoveNext") ==
                        nil then
                        capturing_fields = false
                        local method_offset = tempDumpTable[i]:gsub(".+// RVA: (0x[A-Za-z0-9]+) .+: .+", "%1")
                        local method_name = tempDumpTable[i + 1]:gsub("	", "")
                        local method_type = ""
                        if method_name:find(" static ") or method_name:find(" override ") or
                            method_name:find(" internal ") or method_name:find(" virtual ") then
                            method_type = method_name:gsub(".+ .+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]",
                                "")
                        else
                            method_type = method_name:gsub(".+ (.+) .+%(.+", "%1"):gsub("[	*%[%]]", ""):gsub("[>,]", "")
                        end
                        table.insert(temp_dump_cs_table[#temp_dump_cs_table].methods, {
                            method_offset = method_offset,
                            method_name = method_name,
                            method_type = method_type
                        })
                    end
                    if capturing == true and tempDumpTable[i]:find("// Fields") then
                        temp_dump_cs_table[#temp_dump_cs_table].fields = {}
                        capturing_fields = true
                    end
                end
            end
            dump_cs_table = temp_dump_cs_table
        end
        save_dump = true
    end,
    --    dH.saveJSON()
    saveJSON = function()
    bc.saveTable("dump_cs_table",dataPath .. game_path .. "/processed_dump_" .. gg.getTargetInfo().versionName .. ".json",true)
    end,
    --    dH.loadJSON()
    loadJSON = function()
        dump_cs_table = bc.readFile(dataPath .. game_path .. "/processed_dump_" .. gg.getTargetInfo().versionName .. ".json", true)
    end,
    --    dH.loadDumpData()
    loadDumpData = function()
        if #dump_cs_table == 0 then
            Il2Cpp.selectLibrary()
            if pcall(dH.loadJSON) == false then
                dH.createDirectory()
                dH.importDump()
            end
            local temp_types = {}
            for i, v in pairs(dump_cs_table) do
                if v.methods then
                    for index, value in pairs(v.methods) do
                        if value.method_type:find("-") or value.method_type:find(" [0-9]+ ")  or value.method_type:find("^[0-9]+$") then else
                            if not temp_types[value.method_type] then
                                temp_types[value.method_type] = value.method_type
                            end
                        end
                    end
                end
            end
            local always_add = { "Boolean", "Single", "Double", "Int16", "Int32", "Int64", "UInt16", "UInt32", "UInt64", "String", "Byte", "SByte", "Char", "Void" }
            for i, v in pairs(always_add) do
                bc_toolbox_method_types[#bc_toolbox_method_types + 1] = v
            end
            for k, v in pairs(temp_types) do
                local added = false
                table.insert(bc_toolbox_method_types_all, v)
                if v:find("[_]") then else
                    if added == false then
                        bc_toolbox_method_types[#bc_toolbox_method_types + 1] = v
                    end
                end
            end
        end
    end
}
dumpHandler = dH

pM = {
    --    pluginManager.configMenu()
    --    pM.configMenu()
    configMenu = function()
        local menu = gg.choice({
            "↕️ Change Menu Order",
            "🔢 Set Menu Item Limit",
            "🔗 Configure Default Plugins",
            "📥 Install Plugin",
            "✏️ Rename Plugin",
            "✅ Enable/Disable Plugins" 
        }, nil, bc.Choice("Plugin Manager", "", "ℹ️"))
        if menu ~= nil then
            if menu == 1 then
                pM.menuOrder()
                pM.configMenu()
            end
            if menu == 2 then
                pM.menuLimit()
                pM.configMenu()
            end
            if menu == 3 then
                pM.defaultPlugins()
                pM.configMenu()
            end
            if menu == 4 then
                pM.installPlugin()
                pM.configMenu()
            end
            if menu == 5 then
                pM.renamePlugin()
                pM.configMenu()
            end
            if menu == 6 then
                pM.togglePlugins()
                pM.configMenu()
            end
        end
    end,
    --    pM.callPlugin(plugin_path, function_table, passed_data)
    callPlugin = function(plugin_path, function_table, passed_data)
        if _G[function_table] then
            _G[function_table].home(passed_data)
        else
            dofile(plugin_path)
            if passed_data ~= nil then
                _G[function_table].home(passed_data)
            end
        end
    end,
    --    pM.defaultHandler(handler, passed_data)
    defaultHandler = function(handler, passed_data)
        for i, v in pairs(pM.toolboxPlugins) do
            if v.default_handler == handler then
                pM.callPlugin(v.plugin_path, v.function_table, passed_data)
            end
        end
    end,
    --    pM.initPluginManager()
    initPluginManager = function()
        pM.toolboxPlugins = bc.readFile(configDataPath .. "plugin_manager.json",true)
        dofile(configDataPath .. "plugin_manager_config.lua")
    end,
    --    pM.initAllPluginManager()
    initAllPluginManager = function()
        pM.toolboxAllPlugins = bc.readFile(configDataPath .. "plugin_manager_all_plugins.json",true)
    end,
    --    pM.menuOrder()
    menuOrder = function()
        if pcall(check_plugin_manager) == false then
            pM.savePlugins()
        end
        local slider_range = ' [1; ' .. #pM.toolboxPlugins .. ']'
        local sliders = {}
        local numbers = {}
        local menu = {}
        for i, v in pairs(pM.toolboxPlugins) do
            sliders[i] = v.menu_name .. slider_range
            numbers[i] = "number"
            menu[i] = i
        end
        sliders[1] = bc.Prompt("Set order of main menu items below. ","ℹ️").."\n\n" .. sliders[1]
        ::duplicate_index::
        menu = gg.prompt(sliders, menu, numbers)
        if menu ~= nil then
            local check_duplicate_indexes = {}
            for i, v in pairs(menu) do
                if check_duplicate_indexes[v] then
                    bc.Alert("Duplicate Indexes Found", "", "⚠️")
                    goto duplicate_index
                else
                    check_duplicate_indexes[v] = v
                end
            end
            local temp_plugins = {}
            for i, v in pairs(menu) do
                temp_plugins[tonumber(v)] = pM.toolboxPlugins[i]
            end
            pM.toolboxPlugins = temp_plugins
            pM.savePlugins()
            bc.Toast("Menu order set. ","ℹ️")
        end
    end,
    --    pM.defaultPlugins()
    defaultPlugins = function()
        local handler_indexes = {
            method = "",
            field = "",
            enum = "",
            class = ""
        }
        local method_results_handler = "Method search result handler:\n"
        for i, v in pairs(pM.toolboxPlugins) do
            if v.default_handler == "method_results" then
                handler_indexes.method = i
                method_results_handler = method_results_handler .. v.menu_name
            end
        end
        local field_results_handler = "Field search result handler:\n"
        for i, v in pairs(pM.toolboxPlugins) do
            if v.default_handler == "field_results" then
                handler_indexes.field = i
                field_results_handler = field_results_handler .. v.menu_name
            end
        end
        local enum_results_handler = "Enum search result handler:\n"
        for i, v in pairs(pM.toolboxPlugins) do
            if v.default_handler == "enum_results" then
                handler_indexes.enum = i
                enum_results_handler = enum_results_handler .. v.menu_name
            end
        end
        local class_results_handler = "Class/Field search result handler:\n"
        for i, v in pairs(pM.toolboxPlugins) do
            if v.default_handler == "class_results" then
                handler_indexes.class = i
                class_results_handler = class_results_handler .. v.menu_name
            end
        end
        local handlerMenu = gg.choice({ method_results_handler,
            field_results_handler,
            enum_results_handler,
            class_results_handler },
            nil,
            bc.Choice("Set Default Plugins", "", "ℹ️"))
        if handlerMenu ~= nil then
            local handler_types = {
                [1] = "method",
                [2] = "field",
                [3] = "enum",
                [4] = "class"
            }
            local handler_names = {
                [1] = "method_results",
                [2] = "field_results",
                [3] = "enum_results",
                [4] = "class_results"
            }
            local plugins_menu_items = {}
            for i, v in pairs(pM.toolboxPlugins) do
                plugins_menu_items[i] = v.menu_name
            end
            local selectHandlerMenu = gg.choice(plugins_menu_items, nil, bc.Choice("Select Default Plugins", "", "ℹ️"))
            if selectHandlerMenu ~= nil then
                pM.toolboxPlugins[handler_indexes[handler_types[handlerMenu]]].default_handler = nil
                pM.toolboxPlugins[selectHandlerMenu].default_handler = handler_names[handlerMenu]
                pM.savePlugins()
                bc.Toast("Default plugin set. ","ℹ️")
            end
        end
    end,
    --    pM.installPlugin()
    installPlugin = function()
        local selectPluginLua = gg.prompt({ bc.Prompt("Select Plugin To Install","ℹ️")}, { gg.EXT_STORAGE .. "/Download/" }, { "file" })
        if selectPluginLua ~= nil and selectPluginLua ~= gg.EXT_STORAGE .. "/Download/" then
            pM.installingPlugin = true
            dofile(selectPluginLua[1])
            pM.installingPlugin = false
            local installMenu = gg.prompt({ bc.Prompt("Installing Plugin","ℹ️") .. "\n\nMenu name for Plugin",
                "Name of function table containing plugins home() menu." },
                {
                    pM.installingPluginName,
                    pM.installingPluginTable },
                {
                    "text",
                    "text" })
            if installMenu ~= nil then
                if #installMenu[1] > 0 and #installMenu[2] > 0 then
                    local filename = selectPluginLua[1]:gsub(".+/(.+)", "%1")
                    local allready_installed = false
                    for i, v in pairs(pM.toolboxPlugins) do
                        if pluginsDataPath .. filename == v.plugin_path then
                            allready_installed = true
                        end
                    end
                    if allready_installed == true then
                        bc.Alert("File Name Conflict", "A plugin with this filename is already installed try renaming the lua file first if you are sure it is a different plugin.", "⚠️")
                        goto done
                    end
                    os.rename(selectPluginLua[1], pluginsDataPath .. filename)
                    local temp_plugin = {
                        function_table = installMenu[2],
                        menu_name = installMenu[1],
                        plugin_path = pluginsDataPath .. filename
                    }
                    table.insert(pM.toolboxPlugins, temp_plugin)
                    pM.savePlugins()
                    pM.initAllPluginManager()
                    table.insert(pM.toolboxAllPlugins, temp_plugin)
                    pM.saveAllPlugins()
                    bc.Toast("Plugin has been installed. ","ℹ️")
                end
            end
        end
        ::done::
    end,
    --    pM.removePlugin()
    removePlugin = function()
        local plugins_menu_items = {}
        for i, v in pairs(pM.toolboxPlugins) do
            plugins_menu_items[i] = v.menu_name
        end
        local removePluginMenu = gg.choice(plugins_menu_items, nil, bc.Choice("Select Plugin To Uninstall", "", "⚠️"))
        if removePluginMenu ~= nil then
            local confirmRemove = gg.choice({
                "✅ Yes",
                "❌ No" 
            },
                nil,
                bc.Choice("Removing Plugin", "Remove the " .. plugins_menu_items[removePluginMenu] .. " plugin?", "⚠️"))
            if confirmRemove ~= nil then
                if confirmRemove == 1 then
                    table.remove(pM.toolboxPlugins, removePluginMenu)
                    pM.savePlugins()
                    bc.Toast("Plugin has been removed from the menu. ","ℹ️")
                end
            end
        end
    end,
    --    pM.savePlugins()
    savePlugins = function()
        bc.saveTable("pM.toolboxPlugins",configDataPath .. "plugin_manager.json",true)
    end,
    --    pM.saveAllPlugins()
    saveAllPlugins = function()
        bc.saveTable("pM.toolboxAllPlugins",configDataPath .. "plugin_manager_all_plugins.json",true)
    end,
    --    pM.saveMenuLimit()
    saveMenuLimit = function()
        file = io.open(configDataPath .. "plugin_manager_config.lua", "w+")
        file:write("pM.menuItemLimit = " .. pM.menuItemLimit)
        file:close()
    end,
    --    pM.renamePlugin()
    renamePlugin = function()
        local plugins_menu_items = {}
        for i, v in pairs(pM.toolboxPlugins) do
            plugins_menu_items[i] = v.menu_name
        end
        local renamePluginMenu = gg.choice(plugins_menu_items, nil,   bc.Choice("Renaming Plugin", "Select plugin to rename.", "ℹ️"))
        if renamePluginMenu ~= nil then
            local renamePrompt = gg.prompt({ bc.Prompt("Enter a new menu name for the plugin. ","ℹ️")},
                { plugins_menu_items[renamePluginMenu] }, { "text" })
            if renamePrompt ~= nil then
                pM.toolboxPlugins[renamePluginMenu].menu_name = renamePrompt[1]
                pM.savePlugins()
            end
        end
    end,
    --    pM.menuLimit()
    menuLimit = function()
        local menu = gg.prompt({ bc.Prompt("Set limit for number of items per menu.","ℹ️") .. "\n\nSet menu item limit [0; 20]" }, { pM.menuItemLimit }, { 'number' })
        if menu ~= nil then
            pM.menuItemLimit = menu[1]
            pM.saveMenuLimit()
        end
    end,
    --    pM.togglePlugins()
    togglePlugins = function()
        if not pM.toolboxAllPlugins then
            pM.initAllPluginManager()
        end
        local menu_names = {}
        local menu_checkboxes = {}
        local menu_values = {}
        local menu_paths = {}
        for i, v in pairs(pM.toolboxAllPlugins) do
            menu_names[i] = v.menu_name
            menu_checkboxes[i] = "checkbox"
            menu_values[i] = false
            menu_paths[i] = v.plugin_path
            for index, value in pairs(pM.toolboxPlugins) do
                if v.plugin_path == value.plugin_path then
                    menu_values[i] = true
                end
            end
        end
        local menu = gg.prompt(menu_names, menu_values, menu_checkboxes)
        if menu ~= nil then
            for i, v in pairs(menu) do
                if v == true and menu_values[i] == false then
                    table.insert(pM.toolboxPlugins, pM.toolboxAllPlugins[i])
                    pM.savePlugins()
                end
                if v == false and menu_values[i] == true then
                    for index, value in pairs(pM.toolboxPlugins) do
                        if value.plugin_path == menu_paths[i] then
                            table.remove(pM.toolboxPlugins, index)
                            pM.savePlugins()
                        end
                    end
                end
            end
        end
    end,
    --    pM.toolboxPlugins
    toolboxPlugins = { {
    	function_table = "metadataDumper",
        menu_name = "💾 Global-Metadata Dumper",
        plugin_path = pluginsDataPath .. "plugin_bc_metadata_dumper.lua"
    }, {
    	function_table = "libDumper",
        menu_name = "💾 Lib Dumper",
        plugin_path = pluginsDataPath .. "plugin_bc_lib_dumper.lua"
    }, {
    	function_table = "bcpp_dumper",
        menu_name = "💩 BCppDumper",
        plugin_path = pluginsDataPath .. "plugin_bc_bcpp_dumper.lua"
    },  {
    	function_table = "classFieldSearcher",
        menu_name = "🔎 Class Field Searcher",
        plugin_path = pluginsDataPath .. "plugin_bc_class_field_search.lua" 
    }, {
        function_table = "dumpSearcher",
        menu_name = "🔍 Search Dump.cs",
        plugin_path = pluginsDataPath .. "plugin_bc_dump_search.lua"
    }, {
        function_table = "methodSearchResults",
        default_handler = "method_results",
        menu_name = "🗒️ Method Search Results",
        menu_count_table = "dumpSearcher.methodResults",
        plugin_path = pluginsDataPath .. "plugin_bc_method_search_results.lua"
    }, {
        function_table = "fieldSearchResults",
        default_handler = "field_results",
        menu_name = "🗒️ Field Search Results",
        menu_count_table = "dumpSearcher.fieldResults",
        plugin_path = pluginsDataPath .. "plugin_bc_field_search_results.lua"
    }, {
        function_table = "enumSearchResults",
        default_handler = "enum_results",
        menu_name = "🗒️ Enum Search Results",
        menu_count_table = "dumpSearcher.enumResults",
        plugin_path = pluginsDataPath .. "plugin_bc_enum_search_results.lua"
    }, {
        function_table = "il2cppFields",
        default_handler = "class_results",
        menu_name = "📝 BadCase's Il2Cpp Fields",
        plugin_path = pluginsDataPath .. "plugin_bc_il2cpp_fields.lua"
    }, {
        function_table = "il2cppEdits",
        menu_name = "📝 BadCase's Il2Cpp Edits by Name",
        plugin_path = pluginsDataPath .. "plugin_bc_il2cpp_edits.lua"
    },{
        function_table = "editByOffset",
        menu_name = "📝 Lib Edits By Offset", 
        plugin_path = pluginsDataPath .. "plugin_bc_edit_by_offset.lua"
    } , {
        function_table = "staticValueFinder",
        menu_name = "🕵️‍ Static Value Finder",
        plugin_path = pluginsDataPath .. "plugin_bc_static_value_finder.lua"
    }, {
        function_table = "saveListManager",
        menu_name = "📑 Save List Manager",
        plugin_path = pluginsDataPath .. "plugin_bc_save_list.lua"
    } , {
        function_table = "scriptCreator",
        menu_name = "🏗️ Script Creator",
        plugin_path = pluginsDataPath .. "plugin_bc_script_creator.lua"
    }},
    menuItemLimit = 0,
    returnHome = false,
    returnPluginTable = "",
    --    pM.home(menu_number)
    home = function(menu_number)
        if pM.returnHome == true then
            _G[pM.returnPluginTable].home()
        elseif pM.menuItemLimit == 0 then
            local menu_names = {}
            for i, v in pairs(pM.toolboxPlugins) do
                menu_names[i] = v.menu_name
                if v.menu_count_table and _G[v.menu_count_table:gsub("(.+)%..+", "%1")] then
                    menu_names[i] = menu_names[i] .. " (" .. #_G[v.menu_count_table:gsub("(.+)%..+", "%1")][v.menu_count_table:gsub(".+%.(.+)", "%1")] .. ")"
                end
            end
            menu_names[#menu_names + 1] = "⚙️ Plugin Manager"
            menu_names[#menu_names + 1] = "❌ Exit"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                if menu == #menu_names then
                    os.exit()
                elseif menu == #menu_names - 1 then
                    pM.configMenu()
                else
                    local status, retval = pcall(pM.callPlugin,
                        pM.toolboxPlugins[menu].plugin_path,
                        pM.toolboxPlugins[menu].function_table);
                    if status == false then
                        local error_menu = gg.alert(retval, "OK", "Copy Error")
                        if error_menu ~= nil then
                            if error_menu == 2 then
                                gg.copyText(retval)
                            end
                        end
                    end
                end
            end
        else
            local current_menu = 1
            if menu_number ~= nil then
                current_menu = menu_number
            end
            local limit = current_menu - 1
            local menu_names = {}
            local total_plugins = #pM.toolboxPlugins
            local menu_limit = pM.menuItemLimit
            menu_count = total_plugins / menu_limit
            if total_plugins % menu_limit ~= 0 then
                menu_count = menu_count + 1
            end
            for i, v in pairs(pM.toolboxPlugins) do
                if i <= pM.menuItemLimit * current_menu and i > pM.menuItemLimit * limit then
                    menu_names[#menu_names + 1] = v.menu_name
                    if v.menu_count_table and _G[v.menu_count_table:gsub("(.+)%..+", "%1")] then
                        menu_names[#menu_names] = menu_names[#menu_names] .. " (" .. #_G[v.menu_count_table:gsub("(.+)%..+", "%1")][v.menu_count_table:gsub(".+%.(.+)", "%1")] .. ")"
                    end
                end
                if #menu_names == pM.menuItemLimit then
                    break
                end
            end
            if menu_count and current_menu == menu_count then
                menu_names[#menu_names + 1] = "🏠 Home Menu"
            elseif menu_count then
                menu_names[#menu_names + 1] = "⏭️ Next Menu"
            end
            menu_names[#menu_names + 1] = "⚙️ Plugin Manager"
            menu_names[#menu_names + 1] = "❌ Exit"
            local menu = gg.choice(menu_names, nil, script_title)
            if menu ~= nil then
                local menuRange = pM.menuItemLimit * limit
                if menu == #menu_names then
                    os.exit()
                elseif menu == #menu_names - 1 then
                    pM.configMenu()
                elseif menu <= #menu_names - 3 then
                    if current_menu > 1 then
                        call_index = menu + pM.menuItemLimit * limit
                    else
                        call_index = menu
                    end
                    local status, retval = pcall(pM.callPlugin,
                        pM.toolboxPlugins[call_index].plugin_path,
                        pM.toolboxPlugins[call_index].function_table);
                    if status == false then
                        local error_menu = gg.alert(retval, "OK", "Copy Error")
                        if error_menu ~= nil then
                            if error_menu == 2 then
                                gg.copyText(retval)
                            end
                        end
                    end
                elseif menu >= #menu_names - 2 - menu_count and menu <= #menu_names - 2 then
                    if current_menu == menu_count then
                        pM.home(1)
                    else
                        pM.home(current_menu + 1)
                    end
                end
            end
        end
    end,
    whileLoop = {},
    doWhileLoop = function()
        for i, v in pairs(pM.whileLoop) do
            local ms_to_sec = v.run_every / 1000
            if os.time() - v.last_run > ms_to_sec then
                if v.do_pcall == true then
                    pcall(_G[v.plugin_table][v.call_function])
                else
                    _G[v.plugin_table][v.call_function]()
                end
                v.last_run = os.time()
            end
        end
    end
}
pluginManager = pM
Il2Cpp = {
    arch = gg.getTargetInfo(),
    ggHex = function(n, zero)
		if type(n) ~= "table" then
			local dwordValueToHex = string.format('%x', n)
			if #dwordValueToHex == 8 or #dwordValueToHex == 10 or #dwordValueToHex == 12 then
				if zero == false then
					return dwordValueToHex .. "h"
				else
					return "0x" .. dwordValueToHex
				end
			else
				local sub = #dwordValueToHex / 2
				sub = tonumber("-" .. sub)
				dwordValueToHex = dwordValueToHex:sub(sub)
				if zero == false then
					return dwordValueToHex .. "h"
				else
					return "0x" .. dwordValueToHex
				end
			end
		else
			return nil
		end
	end,
    utf8FromTable = function(t)
        local bytearr = {}
        for _, v in ipairs(t) do
            local utf8byte = v < 0 and (0xff + v + 1) or v
            if utf8byte ~= 0 then
                table.insert(bytearr, string.char(utf8byte))
            end
        end
        return table.concat(bytearr)
    end,
    mySplit = function(inputstr, sep)
        sep = sep or "%s"
        local t = {}
        for field, s in string.gmatch(inputstr, "([^" .. sep .. "]*)(" .. sep .. "?)") do
            table.insert(t, field)
            if s == "" then
            end
        end
        return t
    end,
    filters = {},
    class_names = {},
    namespace_names = {},
    image_names = {},
    Il2cppApi = {
        ["v24"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x114, 
                ARM7 = 0x9C
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x40
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80, 
                ARM7 = 0x34
            },
            ClassApiFieldsStep = {
                ARM8 = 0x28, 
                ARM7 = 0x18
            },
            ClassApiCountFields = {
                ARM8 = 0x118, 
                ARM7 = 0xA0
            },
            ClassApiParentOffset = {
                ARM8 = 0x58, 
                ARM7 = 0x24
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v24.1"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x110,
                ARM7 = 0xA8
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x114,
                ARM7 = 0xAC
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v24.2"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x118,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x11c,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v24.3"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x118,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x11c,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v24.4"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x118,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x11c,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v24.5"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x118,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x11c,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 92,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v27"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x11C,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 88,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v27.1"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x11C,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            typeDefinitionsSize = 88,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v27.2"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x11C,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiNameOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiParamCount = {
                ARM8 = 0x4A,
                ARM7 = 0x2A
            },
            MethodsApiReturnType = {
                ARM8 = 0x28,
                ARM7 = 0x14
            },
            typeDefinitionsSize = 88,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        },
        ["v29"] = {
            FieldApiOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            FieldApiType = {
                ARM8 = 0x8,
                ARM7 = 0x4
            },
            FieldApiClassOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiNameOffset = {
                ARM8 = 0x10,
                ARM7 = 0x8
            },
            ClassApiMethodsStep = {
                ARM8 = 3,
                ARM7 = 2
            },
            ClassApiCountMethods = {
                ARM8 = 0x11C,
                ARM7 = 0xA4
            },
            ClassApiMethodsLink = {
                ARM8 = 0x98,
                ARM7 = 0x4C
            },
            ClassApiFieldsLink = {
                ARM8 = 0x80,
                ARM7 = 0x40
            },
            ClassApiFieldsStep = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            ClassApiCountFields = {
                ARM8 = 0x120,
                ARM7 = 0xA8
            },
            ClassApiParentOffset = {
                ARM8 = 0x58,
                ARM7 = 0x2C
            },
            ClassApiNameSpaceOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            ClassApiStaticFieldDataOffset = {
                ARM8 = 0xB8,
                ARM7 = 0x5C
            },
            MethodsApiClassOffset = {
                ARM8 = 0x20,
                ARM7 = 0x10
            },
            MethodsApiNameOffset = {
                ARM8 = 0x18,
                ARM7 = 0xC
            },
            MethodsApiParamCount = {
                ARM8 = 0x52,
                ARM7 = 0x2E
            },
            MethodsApiReturnType = {
                ARM8 = 0x20,
                ARM7 = 0x14
            },
            typeDefinitionsSize = 88,
            typeDefinitionsOffset = 0xA0,
            stringOffset = 0x18,
            TypeApiType = {
                ARM8 = 0xA,
                ARM7 = 0x6
            }
        }
    },
    retrieveString = function(address, gettype)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local class_name = ""
        if address ~= "0x00000000" and address ~= nil then
            local first_letter = {}
            first_letter[1] = {}
            first_letter[1].address = address
            first_letter[1].flags = gg.TYPE_BYTE
            first_letter = gg.getValues(first_letter)
            local get_class_name_table = {}
            offset = 0
            for i = 1, 200 do
                get_class_name_table[i] = {}
                get_class_name_table[i].address = first_letter[1].address + offset
                get_class_name_table[i].flags = gg.TYPE_BYTE
                offset = offset + 1
            end
            get_class_name_table = gg.getValues(get_class_name_table)
            class_name = ""
            for index, value in pairs(get_class_name_table) do
                if value.value > 0 and value.value <= 255 then
                    if gettype == true and index == 1 then
                        if ((value.value >= 97 and value.value <= 122) or value.value == 95 or (value.value >= 48 and value.value <= 57)) then
                        else
                            break
                        end
                    end
                    class_name = class_name .. string.char(value.value)
                end
                if value.value == 0 then
                    break
                end
            end
        end
        if gettype == true and #class_name < 3 then
            class_name = ""
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return class_name
    end,
    s_b_s = ":" .. string.char(0) .. "mscorlib.dll" .. string.char(0),
    e_b_s = "00h;00h;0~~0;0~~0;0~~0;00h;0~~0;00h;0~~0;00h;FFh;FFh::12",
    getMetadataStringsRange = function()
        gg.setRanges(gg.REGION_OTHER)
        gg.clearResults()
        ::try_ca::
        gg.searchNumber(Il2Cpp.s_b_s, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)
        if gg.getResultsCount() == 0 and ca_range ~= true then
            ca_range = true
            gg.setRanges(gg.REGION_C_ALLOC)
            goto try_ca
        end
        if gg.getResultsCount() == 0 and ca_range == true then
            print("\n\nGlobal-Metadata Not Found\n\n")
        end
        local start_search = gg.getResults(1)
        gg.clearResults()
        range_start = start_search[1].address
        for i, v in pairs(gg.getRangesList()) do
            if v["start"] < range_start and v["end"] > range_start then
                metadata_end = v["end"]
                break
            end
        end
        gg.searchNumber(Il2Cpp.e_b_s, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, nil, 1)
        local end_search = gg.getResults(1)
        range_end = end_search[1].address
        gg.clearResults()
    end,
    unityAPIs = {
		{"5.3.0[a-z]", "v16", 24}, 
		{"5.3.1[a-z]", "v16", 24}, 
		{"5.3.2[a-z]", "v19", 24}, 
		{"5.3.3[a-z]", "v20", 24}, 
		{"5.3.4[a-z]", "v20", 24}, 
		{"5.3.5[a-z]", "v21", 24}, 
		{"5.3.8[a-z]", "v21", 24}, 
		{"5.4.", "v21", 24}, 
		{"5.5.", "v22", 24}, 
		{"5.6.", "v23", 24}, 
		{"2017.", "v24", 24}, 
		{"2018.1.", "v24", 24}, 
		{"2018.2.", "v24", 24}, 
		{"2018.3.", "v24.1", 25}, 
		{"2018.4.", "v24.1", 25}, 
		{"2019.1.", "v24.2", 24}, 
		{"2019.2.", "v24.2", 24}, 
		{"2019.3.0", "v24.2", 24}, 
		{"2019.3.1", "v24.2", 24},
        {"2019.3.2", "v24.2", 24}, 
		{"2019.3.3", "v24.2", 24}, 
		{"2019.3.4", "v24.2", 24}, 
		{"2019.3.5", "v24.2", 24}, 
		{"2019.3.6", "v24.2", 24}, 
		{"2019.3.7", "v24.3", 24}, 
		{"2019.3.8", "v24.3", 24}, 
		{"2019.3.9", "v24.3", 24}, 
		{"2019.4.[0-9][a-z]", "v24.3", 24}, 
		{"2019.4.1[0-4][a-z]", "v24.3", 24}, 
		{"2019.4.1[5-9][a-z]", "v24.4", 24}, 
		{"2019.4.20[a-z]", "v24.4", 24}, 
		{"2019.4.2[1-9][a-z]", "v24.5", 24}, 
		{"2019.4.3[0-9][a-z]", "v24.5", 24}, 
		{"2020.1.[0-9][a-z]", "v24.3", 24},
        {"2020.1.10[a-z]", "v24.3", 24}, 
		{"2020.1.1[1-9][a-z]", "v24.4", 24}, 
		{"2020.2.[0-3][a-z]", "v27", 27, true}, 
		{"2020.2.[4-9][a-z]", "v27.1", 27, true}, 
		{"2020.3.", "v27.1", 27, true}, 
		{"2021.", "v27.2", 27, true}, 
		{"2022.", "v29", 27}
	},
    selectBuild = function()
        local check_version
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_JAVA_HEAP | gg.REGION_OTHER | gg.REGION_CODE_APP)
        if Il2Cpp.scriptSettings[3] == true then
            gg.clearResults()
            gg.searchNumber("00h;35h;2Eh;49~57;2Eh;48~57;97~122;48~57;00h::9", gg.TYPE_BYTE)
            gg.refineNumber("00h", gg.TYPE_BYTE)
            check_version = gg.getResults(gg.getResultsCount())
            if gg.getResultsCount() == 0 then
                gg.searchNumber(":"..string.char(0).."20")
                gg.refineNumber("00h", gg.TYPE_BYTE)
                check_version = gg.getResults(gg.getResultsCount())
            end
        else
            gg.clearResults()
            gg.searchNumber(":"..string.char(0).."20")
            gg.refineNumber("00h", gg.TYPE_BYTE)
            check_version = gg.getResults(gg.getResultsCount())
        end
        possible_builds = {}
        if #check_version > 0 then
            for i, v in pairs(check_version) do
                local found = false
                local found2 = false
                local f = {}
                for index = 1, 14 do
                    f[index] = {}
                    f[index].address = check_version[i].address + index
                    f[index].flags = gg.TYPE_BYTE
                end
                f = gg.getValues(f)
                unity_version = ""
                if f[1].value >= 48 and f[1].value <= 57 and f[2].value >= 48 and f[2].value <= 57 and f[3].value >= 48 and f[3].value <= 57 and f[4].value >= 48 and f[4].value <= 57 and f[5].value == 0x2E then
                    local dec_count = 0
                    for index, value in ipairs(f) do
                        if value.value >= 97 and value.value <= 122 then
                            found = true
                        end
                        if value.value == 0 then
                            break
                        elseif ((value.value >= 97 and value.value <= 122) or value.value == 0x2E or (value.value >= 48 and value.value <= 57)) then
                            if value.value == 0x2E then
                                dec_count = dec_count + 1
                            end
                            if dec_count == 3 then
                                break
                            else
                                unity_version = unity_version .. string.char(value.value)
                            end
                        else
                            break
                        end
                    end
                    if found == true then
                        possible_builds[unity_version] = 0
                    end
                end
            end
        end
        local menu_items = {}
        for k, v in pairs(possible_builds) do
            table.insert(menu_items, k)
        end
        local menu_items_with_api = {}
        for index, value in ipairs(menu_items) do
            for i, v in ipairs(Il2Cpp.unityAPIs) do
                if value:find("^" .. v[1]) then
                    menu_items_with_api[index] = "Build: " .. menu_items[index] .. " API: " .. v[2]
                    break
                end
            end
        end
        ::choose::
        local menu = gg.choice(menu_items_with_api, nil, bc.Choice("Select Build", "Select the games Unity build.", "ℹ️"))
        if menu == nil then
            goto choose
        else
            Il2Cpp.setAPIVariables(menu_items[menu])
        end
    end,
    setAPIVariables = function(build_number)
    if Il2Cpp.arch.x64 then
            flag_type = gg.TYPE_QWORD
            Il2Cpp.ARM = "ARM8"
        else
            flag_type = gg.TYPE_DWORD
            Il2Cpp.ARM = "ARM7"
        end
        local check_version
        if not build_number then
            if Il2Cpp.scriptSettings[3] == true then
                gg.setRanges(gg.REGION_ANONYMOUS)
                gg.clearResults()
                gg.searchNumber("00h;35h;2Eh;49~57;2Eh;48~57;97~122;48~57;00h::9", gg.TYPE_BYTE, nil, nil, nil, nil, 1)
                check_version = gg.getResults(1)
                if gg.getResultsCount() == 0 then
                    gg.setRanges(gg.REGION_C_ALLOC)
                    ::try_a::
                    gg.searchNumber("00h;32h;30h;0~~0;0~~0;2Eh;0~~0;2Eh::9", gg.TYPE_BYTE, nil, nil, nil, nil, 1)
                    gg.refineNumber("00h;32h;30h;0~~0;0~~0;2Eh::6", gg.TYPE_BYTE)
                    check_version = gg.getResults(1)
                    if gg.getResultsCount() == 0 then
                        gg.setRanges(gg.REGION_ANONYMOUS)
                        goto try_a
                    end
                end
            else
                gg.setRanges(gg.REGION_C_ALLOC)
                ::try_a::
                gg.clearResults()
                gg.searchNumber("00h;32h;30h;0~~0;0~~0;2Eh;0~~0;2Eh::9", gg.TYPE_BYTE, nil, nil, nil, nil, 1)
                gg.refineNumber("00h;32h;30h;0~~0;0~~0;2Eh::6", gg.TYPE_BYTE)
                check_version = gg.getResults(1)
                if gg.getResultsCount() == 0 and trying_a ~= true then
                    trying_a = true
                    gg.setRanges(gg.REGION_ANONYMOUS)
                    goto try_a
                end
            end
            if #check_version > 0 then
                local check_f = {}
                for index = 1, 12 do
                    check_f[index] = {}
                    check_f[index].address = check_version[1].address + index
                    check_f[index].flags = gg.TYPE_BYTE
                end
                check_f = gg.getValues(check_f)
                unity_version = ""
                for index, value in ipairs(check_f) do
                    if value.value >= 97 and value.value <= 122 then
                        found = true
                    end
                    if value.value == 0 then
                        break
                    else
                        unity_version = unity_version .. string.char(value.value)
                    end
                end
                Il2Cpp.unity_version = ""
            end
        end
        if build_number then
            unity_version = build_number
        end
        for i, v in ipairs(Il2Cpp.unityAPIs) do
            if unity_version:find("^" .. v[1]) then
                unity_api_version = v[2]
                Il2Cpp.unity_version = v[2]
                Il2Cpp.followTypePointers = v[4]
                break
            end
        end
        local unity_info = "Unity Build: " .. unity_version .. "\nUnity API: " .. unity_api_version
        bc.Toast(unity_info,"ℹ️")
        print("\n\n" .. script_title .. "\n")
        local label = ""
        if gg.getTargetInfo() then
            label = gg.getTargetInfo().label
        end
        print(unity_info)
        if Il2Cpp.unity_version == "" then
            Il2Cpp.unity_version = "v24.2"
        end
        Il2Cpp.FieldApiOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].FieldApiOffset[Il2Cpp.ARM]

        Il2Cpp.FieldApiType = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].FieldApiType[Il2Cpp.ARM]

        Il2Cpp.FieldApiClassOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].FieldApiClassOffset[Il2Cpp.ARM]

        Il2Cpp.ClassApiNameOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiNameOffset[Il2Cpp.ARM]

        Il2Cpp.ClassApiMethodsStep = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiMethodsStep[Il2Cpp.ARM]

        Il2Cpp.ClassApiCountMethods = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiCountMethods[Il2Cpp.ARM]

        Il2Cpp.ClassApiMethodsLink = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiMethodsLink[Il2Cpp.ARM]

        Il2Cpp.ClassApiFieldsLink = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiFieldsLink[Il2Cpp.ARM]

        Il2Cpp.ClassApiFieldsStep = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiFieldsStep[Il2Cpp.ARM]

        Il2Cpp.ClassApiCountFields = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiCountFields[Il2Cpp.ARM]

        Il2Cpp.ClassApiParentOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiParentOffset[Il2Cpp.ARM]

        Il2Cpp.ClassApiNameSpaceOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiNameSpaceOffset[Il2Cpp.ARM]

        Il2Cpp.ClassApiStaticFieldDataOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].ClassApiStaticFieldDataOffset[Il2Cpp.ARM]

        Il2Cpp.MethodsApiClassOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].MethodsApiClassOffset[Il2Cpp.ARM]

        Il2Cpp.MethodsApiNameOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].MethodsApiNameOffset[Il2Cpp.ARM]

        Il2Cpp.MethodsApiParamCount = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].MethodsApiParamCount[Il2Cpp.ARM]

        Il2Cpp.MethodsApiReturnType = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].MethodsApiReturnType[Il2Cpp.ARM]

        Il2Cpp.typeDefinitionsSize = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].typeDefinitionsSize

        Il2Cpp.typeDefinitionsOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].typeDefinitionsOffset

        Il2Cpp.stringOffset = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].stringOffset

        Il2Cpp.TypeApiType = Il2Cpp.Il2cppApi[Il2Cpp.unity_version].TypeApiType[Il2Cpp.ARM]

    end,
    dumpedTypesTable = {},
    removeConsecutivePointers = function()
        local consecutive_pointer_counter = 1
        local last_result_address = 0x00000000
        local current_result_address
        for i, v in pairs(Il2Cpp.firstPointerSearch) do
            current_result_address = v.address
            if current_result_address - last_result_address == 4 then
                consecutive_pointer_counter = consecutive_pointer_counter + 1
                if deleting == true then
                    Il2Cpp.firstPointerSearch[i] = nil
                    goto next
                end
            else
                deleting = false
                consecutive_pointer_counter = 1
            end
            if consecutive_pointer_counter == 3 then
                Il2Cpp.firstPointerSearch[i] = nil
                Il2Cpp.firstPointerSearch[i - 1] = nil
                Il2Cpp.firstPointerSearch[i - 2] = nil
                deleting = true
            end
            ::next::
            last_result_address = current_result_address
        end
        gg.loadResults(Il2Cpp.firstPointerSearch)
        Il2Cpp.firstPointerSearch = gg.getResults(gg.getResultsCount())
    end,
    types_count = 0,
    scan = function()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        Il2Cpp.dumpTable = {}
        if not Il2Cpp.FieldApiOffset then
            Il2Cpp.configureScript()
        end
        gg.clearResults()
        if not Il2Cpp.method_types then
            if Il2Cpp.followTypePointers == true then
                if Il2Cpp.arch.x64 then
                    Il2Cpp.getAdditionalTypes()
                else
                    Il2Cpp.getTypes27()
                end
            elseif Il2Cpp.unity_version == "v24" then
                Il2Cpp.getTypes24()
            else
                Il2Cpp.getTypes24X()
                if Il2Cpp.arch.x64 and Il2Cpp.unity_version == "v24.5" then
                    Il2Cpp.getAdditionalTypes()
                end
            end
        end
        local dlls = {}
        for k, v in pairs(Il2Cpp.globalMetadataStrings) do
            if v:find("%.dll$") then
                table.insert(dlls, {
                    address = tonumber(k),
                    flags = gg.TYPE_BYTE
                })
            end
        end
        gg.clearResults ()
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        gg.loadResults(dlls)
        possible_classes = gg.getResults(gg.getResultsCount())
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        gg.searchPointer(0)
        possible_classes = gg.getResults(gg.getResultsCount())
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.searchPointer(0)
        possible_classes = gg.getResults(gg.getResultsCount())
        local temp_table = {}
        if Il2Cpp.scriptSettings[2] == true then
            for i, v in pairs(possible_classes) do
                possible_classes[i].address = possible_classes[i].address + Il2Cpp.ClassApiMethodsLink
            end
            possible_classes = gg.getValues(possible_classes)
            for i, v in pairs(possible_classes) do
                if #tostring(v.value) > 6 then
                    table.insert(temp_table, v)
                end
            end
            temp_table = gg.getValues(temp_table)
            for i, v in pairs(temp_table) do
                temp_table[i].address = temp_table[i].address - Il2Cpp.ClassApiMethodsLink
            end
            for i, v in pairs(possible_classes) do
                possible_classes[i].address = possible_classes[i].address - Il2Cpp.ClassApiMethodsLink
            end
            possible_classes = gg.getValues(possible_classes)
        end
        if Il2Cpp.scriptSettings[1] == true then
            local temp_table2 = {}
            for i, v in pairs(possible_classes) do
                possible_classes[i].address = possible_classes[i].address + Il2Cpp.ClassApiFieldsLink
            end
            possible_classes = gg.getValues(possible_classes)
            for i, v in pairs(possible_classes) do
                if #tostring(v.value) > 6 then
                    table.insert(temp_table2, v)
                end
            end
            temp_table2 = gg.getValues(temp_table2)
            for i, v in pairs(temp_table2) do
                temp_table2[i].address = temp_table2[i].address - Il2Cpp.ClassApiFieldsLink
            end
            temp_table2 = gg.getValues(temp_table2)
            for i, v in pairs(temp_table2) do
                table.insert(temp_table, v)
            end
        end
        gg.loadResults(temp_table)
        temp_table = nil
        possible_classes = gg.getResults(gg.getResultsCount())
        total_indexes = #possible_classes
        local get_indexes = 10000
        local current_skip = 0
        total_checked = 0
        repeat
            local check_indexes = gg.getResults(get_indexes, current_skip)
            Il2Cpp.checkForClasses(check_indexes)
            gg.loadResults(possible_classes)
            total_checked = total_checked + get_indexes
            current_skip = current_skip + get_indexes
        until (current_skip > total_indexes)
        if Il2Cpp.scriptSettings[8] == true then
            Il2Cpp.writeDump(Il2Cpp.dumpTable)
        end
        Il2Cpp.debugFuncEnd(debug_name)
        if Il2Cpp.isDebugging == true then
            print("\nDebug Data\n")
            for k, v in pairs(Il2Cpp.debugTimeTable) do
                print("Function: " .. k)
                print("Times Called: " .. v.count)
                if v.sub_count > 0 then
                    print("Times Called Secondary: " .. v.sub_count)
                end
                print("Total Execution Time: " .. v.total .. " Seconds")
                print("\n")
             end
        end
    end,
    checkForClasses = function(passed_check_table)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        passed_check_table = gg.getValues(passed_check_table)
        local full_check_table = {}
        for i, v in pairs(passed_check_table) do
            if Il2Cpp.isDebugging == true and #Il2Cpp.dumpTable >= test_classes then
                break
            end
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiNameOffset
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiNameSpaceOffset
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiParentOffset
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiFieldsLink
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiMethodsLink
            full_check_table[#full_check_table].flags = flag_type
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiCountFields
            full_check_table[#full_check_table].flags = gg.TYPE_DWORD
            full_check_table[#full_check_table + 1] = {}
            full_check_table[#full_check_table].address = v.address + Il2Cpp.ClassApiCountMethods
            full_check_table[#full_check_table].flags = gg.TYPE_DWORD
        end
        local current_index = 1
        full_check_table = gg.getValues(full_check_table)
        local last_toast = os.time()
        for i, v in pairs(full_check_table) do
            if Il2Cpp.isDebugging == true and #Il2Cpp.dumpTable >= test_classes then
                break
            end
            if i == current_index then
                if os.time() - last_toast > 10 then
                    bc.Toast(#Il2Cpp.dumpTable .. " Classes Found\n" .. i / 8 + total_checked .. " of " .. #possible_classes .. " Pointers Checked","ℹ️")
                    last_toast = os.time()
                end
                local check_class = {}
                check_class[1] = full_check_table[i]
                check_class[2] = full_check_table[i + 1]
                check_class[3] = full_check_table[i + 2]
                check_class[4] = full_check_table[i + 3]
                check_class[5] = full_check_table[i + 4]
                check_class[6] = full_check_table[i + 5]
                check_class[7] = full_check_table[i + 6]
                check_class[8] = full_check_table[i + 7]
                check_class = gg.getValues(check_class)
                if #tostring(check_class[5].value) > 8 or #tostring(check_class[6].value) > 8 then
                    local class_name = Il2Cpp.getString(check_class[2].value)
                    if class_name and #class_name > 0 then
                        local get_class = true
                        for i, v in pairs(Il2Cpp.filters) do
                            if not class_name or class_name:find(v) then
                                get_class = false
                            end
                        end
                        if get_class == true then
                            if Il2Cpp.isDebugging == true and test_classes_skip > 0 and skipped_class_count < test_classes_skip then
                                skipped_class_count = skipped_class_count + 1
                            else
                                local get_image = {}
                                get_image[1] = {}
                                get_image[1].address = check_class[1].value
                                get_image[1].flags = flag_type
                                get_image = gg.getValues(get_image)
                                get_image = Il2Cpp.getString(get_image[1].value)
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable + 1] = {}
                                local field_count = check_class[7].value
                                local method_count = check_class[8].value
                                if field_count > 10000 then
                                    field_count = "?"
                                end
                                if method_count > 10000 then
                                    method_count = "?"
                                end
                                local fields
                                if field_count ~= "?" and field_count > 0 and Il2Cpp.scriptSettings[1] == true and #tostring(check_class[5].value) > 8 then
                                    fields = Il2Cpp.getFields(check_class[5].value, field_count)
                                elseif field_count == "?" and Il2Cpp.scriptSettings[1] == true and #tostring(check_class[5].value) > 8 then
                                    field_count = Il2Cpp.getFieldCount(check_class[5].value)
                                    fields = Il2Cpp.getFields(check_class[5].value, field_count)
                                    Il2Cpp.dumpTable[#Il2Cpp.dumpTable].field_count = field_count
                                    Il2Cpp.dumpTable[#Il2Cpp.dumpTable].fields = fields
                                elseif field_count == "?" then
                                    field_count = 0
                                end
                                if field_count == "?" or fields == nil or (fields and #fields == 0) then
                                        Il2Cpp.dumpTable[#Il2Cpp.dumpTable].field_count = 0
                                end
                                local parent_class
                                parent_class = {}
                                parent_class[1] = {}
                                parent_class[1].address = check_class[4].value + Il2Cpp.ClassApiNameOffset
                                parent_class[1].flags = flag_type
                                parent_class = gg.getValues(parent_class)
                                parent_class = Il2Cpp.getString(parent_class[1].value)
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].image = get_image
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].namespace = Il2Cpp.getString(check_class[3].value)
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].class = class_name
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].parent_class = parent_class
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].field_count = field_count
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].method_count = method_count
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].fields = fields
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].class_header = check_class[1].address
                                local method_data
                                if method_count ~= "?" and method_count > 0 and Il2Cpp.scriptSettings[2] == true and #tostring(check_class[6].value) > 8 then
                                    method_data = Il2Cpp.getMethodDataWithCount(check_class[6].value, method_count)
                                elseif method_count == "?" and Il2Cpp.scriptSettings[2] == true and #tostring(check_class[6].value) > 8 then
                                    method_count = Il2Cpp.getMethodCount(check_class[6].value)
                                    method_data = Il2Cpp.getMethodDataWithCount(check_class[6].value, method_count)
                                    Il2Cpp.dumpTable[#Il2Cpp.dumpTable].method_count = method_count
                                elseif method_count == "?" then
                                    Il2Cpp.dumpTable[#Il2Cpp.dumpTable].method_count = 0
                                end
                                if method_count == "?" or method_data == nil or (method_data and #method_data == 0) then
                                        Il2Cpp.dumpTable[#Il2Cpp.dumpTable].method_count = 0
                                end
                                Il2Cpp.dumpTable[#Il2Cpp.dumpTable].methods = method_data
                                local add_to_list = {}
                                add_to_list.address = check_class[1].address
                                add_to_list.flags = flag_type
                                add_to_list.name = tostring(Il2Cpp.dumpTable[#Il2Cpp.dumpTable])
                                gg.addListItems({add_to_list})
                            end
                        end
                    end
                end
                current_index = current_index + 8
            end
        end  
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    writeDump = function(dumpTable)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local tab = "	"
        local versionCode = "?"
        if gg.getTargetInfo() then
            versionCode = gg.getTargetInfo().versionCode
        end
        local file = io.open(gg.EXT_STORAGE.."/Download/BCD_" .. gg.getTargetPackage() .. "_" .. versionCode .. "_" .. Il2Cpp.ARM .. ".cs", "w+")
        file:write("")
        file:close()
        local file = io.open(gg.EXT_STORAGE.."/Download/BCD_" .. gg.getTargetPackage() .. "_" .. versionCode .. "_" .. Il2Cpp.ARM .. ".cs", "a")
        for i, v in ipairs(dumpTable) do
            if v.image and #v.image > 0 then
                file:write("// Dll : " .. v.image .. "\n")
            else
                file:write("// Dll : \n")
            end
            if v.namespace and #v.namespace > 0 then
                file:write("// Namespace: " .. v.namespace .. "\n")
            else
                file:write("// Namespace: \n")
            end
            if v.parent_class and #v.parent_class > 0 then
                file:write("public static class " .. v.class .. " : " .. v.parent_class .. " // TypeDefIndex: 0000\n")
            else
                file:write("public static class " .. v.class .. " // TypeDefIndex: 0000\n")
            end
            file:write("{\n")
            file:write(tab .. "// Fields\n")
            if v.fields then
                for index, value in ipairs(v.fields) do
                    if value.field_type and value.field_name and value.field_offset then
                        file:write(tab .. "public " .. value.field_type .. " " .. value.field_name .. "; // " .. value.field_offset .. "\n")
                    end
                end
            end
            file:write("\n")
            file:write(tab .. "// Properties\n")
            file:write("\n")
            file:write(tab .. "// Methods\n")
            if v.methods then
                for index, value in ipairs(v.methods) do
                    if value.lib_offset and value.method_type and value.method_name then
                        local VA = Il2Cpp.ggHex(value.lib_offset + BASEADDR)
                        if VA:find("0x00000000") then
                        else
                            file:write(tab .. "// RVA: " .. value.lib_offset .. " VA: " .. VA .. "\n")
                            file:write(tab .. "public " .. value.method_type .. " " .. value.method_name .. "() {}\n")
                        end
                    end
                end
            end
            file:write("}\n")
            file:write("\n")
            file:write("\n")
        end
        file:close()
        dumpEndTime = os.time()
        totalTime = dumpEndTime - dumpStartTime
        totalTime = totalTime / 60
        totalDec = totalTime % 60
        print("\nTime: " .. totalTime .. "." .. totalDec .. " Minutes")
        print("Dump saved to /sdcard/Download/BCD_" .. gg.getTargetPackage() .. "_" .. versionCode .. "_" .. Il2Cpp.ARM .. ".cs")
        print("\n")
        
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getStringCalled = 0,
    newStringRetrieved = 0,
    getString = function(address, gettype)
        if address ~= 0 then
            local debug_name = debug.getinfo(2, "n").name        
            Il2Cpp.debugFuncStart(debug_name)
            if Il2Cpp.globalMetadataStrings[Il2Cpp.ggHex(address)] then
                Il2Cpp.debugFuncEnd(debug_name)
                return Il2Cpp.globalMetadataStrings[Il2Cpp.ggHex(address)]
            else
                if Il2Cpp.isDebugging == true then
                    Il2Cpp.debugTimeTable[debug_name].sub_count = Il2Cpp.debugTimeTable[debug_name].sub_count + 1
                end
                Il2Cpp.globalMetadataStrings[Il2Cpp.ggHex(address)] = Il2Cpp.retrieveString(address, gettype)
                
                Il2Cpp.debugFuncEnd(debug_name)
                return Il2Cpp.globalMetadataStrings[Il2Cpp.ggHex(address)]
            end
        end
    end,
    fieldNames = {},
    getFields = function(address, field_count)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        Il2Cpp.current_fields = {}
        ::above::
        fields_start = address
        local offset = 0
        gg.clearResults()
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        local getall = false
        local all_fields = {}
        local count = 1
        local offset
        local current_address = address
        for i = 1, field_count do
            all_fields[#all_fields + 1] = {}
            all_fields[#all_fields].address = current_address
            all_fields[#all_fields].flags = flag_type
            all_fields[#all_fields + 1] = {}
            all_fields[#all_fields].address = current_address + Il2Cpp.FieldApiType
            all_fields[#all_fields].flags = flag_type
            all_fields[#all_fields + 1] = {}
            all_fields[#all_fields].address = current_address + Il2Cpp.FieldApiOffset
            all_fields[#all_fields].flags = gg.TYPE_DWORD
            current_address = current_address + Il2Cpp.ClassApiFieldsStep
        end
        all_fields = gg.getValues(all_fields)
        local current_index = 1
        for i, v in pairs(all_fields) do
            if i == current_index then
                local field_name = Il2Cpp.getString(all_fields[i].value)
                local field_offset = "0x" .. string.format("%x", all_fields[i + 2].value)
                local field_type
                local final_type
                local get_type = {{
                    address = all_fields[i + 1].value,
                    flags = gg.TYPE_DWORD
                }}
                get_type = gg.getValues(get_type)
                final_type = get_type[1].value
                if #tostring(final_type) > 6 then
                    if Il2Cpp.arch.x64 then
                        get_type[1].flags = gg.TYPE_QWORD
                        get_type = gg.getValues(get_type)
                    end
                    local get_type2 = {{
                        address = get_type[1].value,
                        flags = gg.TYPE_DWORD
                    }}
                    get_type2 = gg.getValues(get_type2)
                    final_type = get_type2[1].value
                end
                if Il2Cpp.method_types[tostring(final_type)] then
                    field_type = Il2Cpp.method_types[tostring(final_type)]
                else
                    field_type = final_type
                end
                table.insert(Il2Cpp.current_fields, {
                    field_name = field_name,
                    field_offset = field_offset,
                    field_type = field_type
                })
                current_index = current_index + 3
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return Il2Cpp.current_fields
    end,
    savedTypes = {},
    getMethodCount = function(address)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local method_count = 0
        local check_pointers = {}
        local offset = 0
        for i = 1, 500 do
            check_pointers[i] = {
                address = address + offset,
                flags = flag_type
            }
            offset = offset + Il2Cpp.FieldApiType
        end
        check_pointers = gg.getValues(check_pointers)
        local lastChecked
        for i, v in ipairs(check_pointers) do
        if lastChecked == v.value then
        break
        end
            if Il2Cpp.checkIfCa(Il2Cpp.ggHex(v.value)) == true then
                method_count = method_count + 1
            else
                break
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return method_count
    end,
    getFieldCount = function (address)
            local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local field_count = 0
        local check_pointers = {}
        local offset = 0
        for i = 1, 500 do
            check_pointers[i] = {
                address = address + offset,
                flags = flag_type
            }
            offset = offset + Il2Cpp.ClassApiFieldsStep
        end
        check_pointers = gg.getValues(check_pointers)
        for i, v in ipairs(check_pointers) do
			if v.value == 0 then
				break
			end
            if Il2Cpp.checkIfO(Il2Cpp.ggHex(v.value)) == true then
                field_count = field_count + 1
            else
                break
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return field_count
    end,
    caRanges = {},
    getCaRanges = function()
        for i, v in pairs(gg.getRangesList()) do
            if v.state == "Ca" or v.state == "O"   then
                table.insert(Il2Cpp.caRanges, v)
            end
        end
    end,
    checkIfCa = function(address)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local found = false
        if address ~= "0x00000000" then
            for i, v in pairs(Il2Cpp.caRanges) do
				if tonumber(address)  ~= nil and v["start"] ~= nil and v["end"] ~= nil then
                    if tonumber(address) >= v["start"] and tonumber(address) <= v["end"] then
                        found = true
                        break
                    end
				end             
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return found
    end,
    checkIfO = function(address)
        local found = false
        if address ~= "0x00000000" then
            for i, v in pairs(gg.getRangesList()) do
                if v.state == "O" then
                    if tonumber(address)  ~= nil and v["start"] ~= nil and v["end"] ~= nil then
                        if tonumber(address) >= tonumber(v["start"]) and tonumber(address) <= tonumber(v["end"]) then
                            found = true
                            break
                        end
                    end
                end
            end
        end
        return found
    end,
    methodsNames = {},
    getMethodDataWithCountTime = 0,
    getMethodDataWithCount = function(address, method_count)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local method_pointers = {}
        local offset_step = Il2Cpp.FieldApiType
        local offset = 0
        for i = 1, method_count do
            method_pointers[i] = {
                address = address + offset,
                flags = flag_type
            }
            offset = offset + offset_step
        end
        method_pointers = gg.getValues(method_pointers)
        local method_names = {}
        local method_types = {}
        for i, v in pairs(method_pointers) do
            local get_name = {{
                address = v.value,
                flags = flag_type
            }, {
                address = v.value + Il2Cpp.MethodsApiNameOffset,
                flags = flag_type
            }, {
                address = v.value + Il2Cpp.MethodsApiReturnType,
                flags = flag_type
            }}
            get_name = gg.getValues(get_name)
            local method_type = {{
                address = get_name[3].value,
                flags = gg.TYPE_DWORD
            }}
            method_type = gg.getValues(method_type)
            if Il2Cpp.followTypePointers == true then
                method_type[1].flags = flag_type
                method_type = gg.getValues(method_type)
                local method_type2 = {{
                    address = method_type[1].value,
                    flags = gg.TYPE_DWORD
                }}
                method_type2 = gg.getValues(method_type2)
                method_type = method_type2[1].value
            else
                method_type = method_type[1].value
            end
            if Il2Cpp.method_types[tostring(method_type)] then
                method_type = Il2Cpp.method_types[tostring(method_type)]
            end
            local method_name = Il2Cpp.getString(get_name[2].value)
            local lib_offset = Il2Cpp.ggHex(get_name[1].value - BASEADDR)
            method_names[i] = {
                method_type = method_type,
                method_name = method_name,
                lib_offset = lib_offset
            }
        end
        Il2Cpp.debugFuncEnd(debug_name)
        return method_names
    end,
    debugTimeTable = {},
    selectLibrary = function()
        local lib_name_gen_script = {}
        local lib_selector = {}
        local lib_selector_start = {}
        local lib_selector_end = {}
        local check_libs = gg.getRangesList()
        for k, v in pairs(check_libs) do
            if (check_libs[k]["name"]:find(".so$") or check_libs[k]["name"]:find(".apk$")) then
                get_size_array = {}
                for i, v in pairs(check_libs[k]) do
                    table.insert(get_size_array, v)
                end
                local file_size = tonumber(get_size_array[1]) - tonumber(get_size_array[6])
                local file_start = tonumber(get_size_array[6])
                local file_end = tonumber(get_size_array[1])
                if file_size < 5120000 then
                    check_libs[k] = nil
                else
                    local divide_by = "1024000"
                    local size_math = tonumber(file_size) / tonumber(divide_by)
                    local size_display = size_math .. "MB"
                    local flibname = check_libs[k]["name"]
                    if flibname:find( "base.apk") then
                    else
                        table.insert(lib_name_gen_script, check_libs[k]["name"])
                        if flibname:find( "-") and flibname:find( "==") then
                            local lib_search = flibname:find( "-")
                            local lib_search2 = flibname:find( "==")
                            local libname_part1 = string.sub(flibname, 1, lib_search - 1)
                            libname_part2 = string.sub(flibname, lib_search2 + 2)
                        else
                            libname_part2 = flibname:gsub("/.+/.+/.+/.+/(.+)", "%1")
                        end
                        if v["name"]:find( "libil2cpp.so") or v["name"]:find( "split_config.armeabi_v7a.apk") or v["name"]:find( "split_config.arm64_v8a.apk") then
                            if v["name"]:find( "split_config.armeabi_v7a.apk") or v["name"]:find( "split_config.arm64_v8a.apk") then
                                is_split = true
                            end
                            local _ = utf8.char(8613)
                            local __ = utf8.char(9552)
                            local ___ = utf8.char(8615)
                            menu_string = ___..__..__..__..__..__..__..__..__..__..__..___.."\nName: " .. libname_part2 .. "\nRange: " .. v.state .. "\nSize: " .. size_display .. "\n".._..__..__..__..__..__..__..__..__..__..__.._
                            table.insert(lib_selector, menu_string)
                            table.insert(lib_selector_start, file_start)
                            table.insert(lib_selector_end, file_end)
                        else
                            menu_string = "Name: " .. libname_part2 .. "\nRange: " .. v.state .. "\nSize: " .. size_display
                            table.insert(lib_selector, menu_string)
                            table.insert(lib_selector_start, file_start)
                            table.insert(lib_selector_end, file_end)
                        end
                    end
                end
            end
        end
        ::select_lib::
        local h = gg.choice(lib_selector, nil, bc.Choice("Select libil2cpp.so Library", "", "ℹ️"))
        if h == nil then
            goto select_lib
        else
            local lib_name = lib_name_gen_script[h]
            for str in string.gmatch(lib_name, "([^/]+)") do
                fixed_lib_name = str
            end
            BASEADDR = lib_selector_start[h]
            if is_split == true then
                if lib_selector[h + 2] and lib_selector[h]:gsub("(.+apk ).+", "%1") == lib_selector[h + 2]:gsub("(.+apk ).+", "%1") then
                    ENDADDR = lib_selector_end[h + 2]
                elseif lib_selector[h]:gsub("(.+apk ).+", "%1") == lib_selector[h + 1]:gsub("(.+apk ).+", "%1") then
                    ENDADDR = lib_selector_end[h + 1]
                else
                    ENDADDR = lib_selector_end[h]
                end
            else
                if lib_selector[h + 2] and lib_selector[h]:gsub( "(.+so ).+", "%1") == lib_selector[h + 2]:gsub("(.+so ).+", "%1") then
                    ENDADDR = lib_selector_end[h + 2]
                elseif lib_selector[h + 1] and lib_selector[h]:gsub( "(.+so ).+", "%1") == lib_selector[h + 1]:gsub( "(.+so ).+", "%1") then
                    ENDADDR = lib_selector_end[h + 1]
                else
                    ENDADDR = lib_selector_end[h]
                end
            end
        end
        Il2Cpp.lib_name = fixed_lib_name
        bc.Toast(fixed_lib_name .. " Selected","ℹ️")
        ::end_select::
    end,
    removeStrings = {},
    getGlobalMetadataStrings = function()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        if Il2Cpp.globalMetadataStrings then
        return
        else
        Il2Cpp.globalMetadataStrings = {}
        end
        bc.Toast(" Dumping String Data ","ℹ️")
        local dump_start = 0
        local dump_end = 0
        gg.dumpMemory(range_start, range_end, gg.EXT_STORAGE.."/bc/", gg.DUMP_SKIP_SYSTEM_LIBS)
        for i, v in pairs(gg.getRangesList()) do
            if range_start > v.start and range_start < v["end"] then
				local dwordValueToHex =string.format('%x', v.start)
				if #dwordValueToHex == 8 or #dwordValueToHex == 10 or #dwordValueToHex == 12 then
					dump_start = dwordValueToHex
				else
					local sub = #dwordValueToHex / 2
					sub = tonumber("-"..sub)
					dwordValueToHex = dwordValueToHex:sub(sub)
					dump_start = dwordValueToHex
				end
				local dwordValueToHex =string.format('%x', v["end"])
				if #dwordValueToHex == 8 or #dwordValueToHex == 10 or #dwordValueToHex == 12 then
					dump_end = dwordValueToHex
				else
					local sub = #dwordValueToHex / 2
					sub = tonumber("-"..sub)
					dwordValueToHex = dwordValueToHex:sub(sub)
					dump_end = dwordValueToHex
				end          
                break
            end
        end
        lib_selector_end = {}
        gg.setRanges(gg.REGION_OTHER)
        local BUFSIZE = 4 ^ 13
        local f = io.input(gg.EXT_STORAGE.."/bc/" .. gg.getTargetPackage() .. "-" .. dump_start .. "-" .. dump_end .. ".bin")
        local start_capture = false
        trimmed_content = ""
        local trim_until = 31886460
        local current_size = 0
        while true do
            local rest = f:read(BUFSIZE)
            current_size = current_size + 67108864
            if rest and string.find(rest, "mscorlib.dll.<Module>") then
                start_capture = true
                bc.Toast("Strings Found","ℹ️")
            end
            if start_capture == true then
                if rest then
                    trimmed_content = trimmed_content .. rest
                    if current_size >= trim_until then
                        trimmed_content = trimmed_content:gsub( ".+(mscorlib.dll.<Module>.+)", "%1")
                        trimmed_content = string.sub(trimmed_content, 1, range_end - range_start)
                        break
                    end
                else
                    trimmed_content = trimmed_content:gsub(".+(mscorlib.dll.<Module>.+)", "%1")
                end
            end
        end
        gg.clearResults()
        ::tryca::
        gg.searchNumber('0', gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start - 1, range_end)
        bc.Toast(" Parsing String Data ","ℹ️")
        local cm_characters_all = gg.getResults(gg.getResultsCount())
        if gg.getResultsCount() == 0 then
            gg.setRanges(gg.REGION_C_ALLOC)
            goto tryca
        end
        local tstring = ""
        for i, v in pairs(cm_characters_all) do
            v.address = v.address + 1
        end
        cm_characters_all = gg.loadResults(cm_characters_all)
        cm_characters_all = gg.getResults(gg.getResultsCount())
        if cm_characters_all[1].value == 0 then
            table.remove(cm_characters_all, 1)
            cm_characters_all = gg.loadResults(cm_characters_all)
            cm_characters_all = gg.getResults(gg.getResultsCount())
        end
        names_table = Il2Cpp.mySplit(trimmed_content, "\x00")
        trimmed_content = nil
        local temp_string_starts = {}
        for i, v in pairs(cm_characters_all) do
            if names_table[i] then
                temp_string_starts[Il2Cpp.ggHex(v.address)] = names_table[i]
            end
        end
        Il2Cpp.globalMetadataStrings = temp_string_starts
        temp_string_starts = nil
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getGlobalMetadataStringsBig = function()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        Il2Cpp.globalMetadataStrings = {}
        local total_results = gg.getResultsCount()
        local get_results = 10000
        local skip_results = 0
        local add_skip_results = 9999
        repeat
            local string_seperators = gg.getResults(get_results, skip_results)
            local last_toast = os.time()
            for i, v in ipairs(string_seperators) do
                if os.time() - last_toast > 10 then
                    bc.Toast(i + skip_results .. " of " .. total_results .. " Strings Retrieved","ℹ️")
                    last_toast = os.time()
                end
                if i < #string_seperators then
                    local string_bytes = {}
                    local current_address = v.address
                    local letter_count = string_seperators[i + 1].address - v.address
                    for index = 1, letter_count do
                        string_bytes[index] = {}
                        string_bytes[index].address = current_address + index
                        string_bytes[index].flags = gg.TYPE_BYTE
                    end
                    string_bytes = gg.getValues(string_bytes)
                    local bytes_table = {}
                    for index, value in ipairs(string_bytes) do
                        bytes_table[index] = value.value
                    end
                    local string_text = Il2Cpp.utf8FromTable(bytes_table)
                    Il2Cpp.globalMetadataStrings[Il2Cpp.ggHex(v.address + 1)] = string_text
                end
            end
            skip_results = skip_results + add_skip_results
        until (skip_results > total_results)
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getTypes24 = function()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        Il2Cpp.method_types = {}
        bc.Toast("Finding Types","ℹ️")
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        local searches = {
            ["ARM7"] = {
                ["first"] = range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";0~~0;1D~100000D::13",
                ["refine"] = range_start .. "~" .. range_end .. ";0~~0;1D~100000D::9",
                ["refine2"] = range_start .. "~" .. range_end .. ";0~~0::5",
                ["second"] = "0D;" .. range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";1D~1000000D;0D~~0D;0D::21",
                ["second_refine"] = "0D;" .. range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";1D~1000000D::13",
                ["second_refine2"] = range_start .. "~" .. range_end .. ";1D~1000000D::5"
            },
            ["ARM8"] = {
                ["first"] = "0D;" .. range_start .. "~" .. range_end .. ";100D~300D;" .. range_start .. "~" .. range_end .. ";100D~300D;0~~0;100D~300D::25",
                ["refine"] = range_start .. "~" .. range_end .. ";100D~300D;" .. range_start .. "~" .. range_end .. ";100D~300D;0~~0::17",
                ["refine2"] = range_start .. "~" .. range_end .. ";0~~0::13",
                ["second"] = "0D;" .. range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";100D~300D;0D~~0D;0D::25",
                ["second_refine"] = "0D;" .. range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";100D~300D;0D~~0D::21",
                ["second_refine2"] = range_start .. "~" .. range_end .. ";" .. range_start .. "~" .. range_end .. ";100D~300D;0D~~0D::17"
            }
        }
        local first_search_string = searches[Il2Cpp.ARM]["first"]
        gg.clearResults()
        gg.searchNumber(first_search_string, flag_type)
        local refine = searches[Il2Cpp.ARM]["refine"]
        gg.refineNumber(refine, flag_type)
        if not Il2Cpp.arch.x64 then
            local refine2 = searches[Il2Cpp.ARM]["refine2"]
            gg.refineNumber(refine2, flag_type)
        end
        local results = gg.getResults(gg.getResultsCount())
        local checked = {}
        local current_index = 1
        for i, v in pairs(results) do
            if Il2Cpp.arch.x64 then
                if i == current_index then
                    current_index = current_index + 5
                    if not checked[tostring(v.value)] then
                        local get_type = {{
                            address = results[i + 4].value,
                            flags = gg.TYPE_DWORD
                        }}
                        get_type = gg.getValues(get_type)
                        local final_type = tostring(get_type[1].value)
                        if not Il2Cpp.method_types[final_type] then
							local getString = Il2Cpp.getString(v.value)
							if bc.isDirtyString(getString) == true then else
								Il2Cpp.method_types[final_type] = getString
								checked[tostring(v.value)] = true
							end
                        end
                    end
                end
            else
                if i % 2 ~= 0 then
                    if not checked[tostring(v.value)] then
                        local get_type = {{
                            address = results[i + 1].value + Il2Cpp.MethodsApiReturnType,
                            flags = flag_type
                        }}
                        get_type = gg.getValues(get_type)
                        local get_type2 = {{
                            address = get_type[1].value,
                            flags = flag_type
                        }}
                        get_type2 = gg.getValues(get_type2)
                        local final_type = tostring(get_type2[1].value)
                        if not Il2Cpp.method_types[final_type] then
							local getString = Il2Cpp.getString(v.value)
							if bc.isDirtyString(getString) == true then else
								Il2Cpp.method_types[final_type] = getString
								checked[tostring(v.value)] = true
                            end
                        end
                    end
                end
            end
        end
        bc.Toast("Finding Types","ℹ️")
        gg.clearResults()
        local second_search = searches[Il2Cpp.ARM]["second"]
        gg.searchNumber(second_search, flag_type)
        local refine = searches[Il2Cpp.ARM]["second_refine"]
        gg.refineNumber(refine, flag_type)
        local refine2 = searches[Il2Cpp.ARM]["second_refine2"]
        gg.refineNumber(refine2, flag_type)
        local results = gg.getResults(gg.getResultsCount())
        local current_index = 1
        for i, v in pairs(results) do
            if Il2Cpp.arch.x64 then
                if i == current_index then
                    current_index = current_index + 4
                    local final_type = tostring(results[i + 3].value)
                    if not Il2Cpp.method_types[final_type] then
                    local getString = Il2Cpp.getString(v.value)
                        if bc.isDirtyString(getString) == true then
                    else
                        Il2Cpp.method_types[final_type] = getString
                    end
                    end
                end
            else
                if i % 2 ~= 0 then
                    local final_type = tostring(results[i + 1].value)
                    if not Il2Cpp.method_types[final_type] then
                    local getString = Il2Cpp.getString(v.value)
                        if bc.isDirtyString(getString) == true then
                    else
                    
                        Il2Cpp.method_types[final_type] = getString
                        end
                    end
                end
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getTypes24X = function(check_indexes)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        Il2Cpp.method_types = {}
        gg.clearResults()
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        local searches = {
            ["ARM7"] = {
                ["all"] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_end .. "::5"
            },
            ["ARM8"] = {
                ["all"] = range_start .. "~" .. range_end .. ";" .. range_start - 200 .. "~" .. range_end .. "::13"
            }
        }
        first_search_string = searches[Il2Cpp.ARM]["all"]
        gg.clearResults()
        gg.searchNumber(first_search_string, flag_type)
        Il2Cpp.firstPointerSearch = gg.getResults(gg.getResultsCount())
        Il2Cpp.removeConsecutivePointers()
        check_table = {}
        local add_value = true
        for i, v in ipairs(Il2Cpp.firstPointerSearch) do
            if i % 2 ~= 0 then
                table.insert(check_table, v)
            end
        end
        gg.loadResults(check_table)
        sorted_check_table = {}
        if Il2Cpp.arch.x64 and Il2Cpp.unity_version == "v24.5" then
            check_table = gg.getResults(gg.getResultsCount())
            for i, v in pairs(check_table) do
                local get_type = {{
                    address = v.address + 16,
                    flags = flag_type
                }}
                get_type = gg.getValues(get_type)
                local get_type2 = {{
                    address = get_type[1].value,
                    flags = flag_type
                }}
                get_type2 = gg.getValues(get_type2)
                local final_type = get_type2[1].value

                if not Il2Cpp.method_types[tostring(final_type)] then
                    Il2Cpp.types_count = Il2Cpp.types_count + 1
                    local getString = Il2Cpp.getString(v.value)
                    if bc.isDirtyString(getString) == true then else
						Il2Cpp.method_types[tostring(final_type)] = getString
						for index = 1, 3 do
							Il2Cpp.method_types[tostring(final_type) + index] = getString
						end
                    end
                end
            end
        else
            check_table = gg.getResults(gg.getResultsCount())
            total_indexes = gg.getResultsCount()
            local get_indexes = 10000
            local current_skip = 0
            total_checked = 0
            repeat
                local check_indexes = gg.getResults(get_indexes, current_skip)
                local full_check_type_table = {}
                local offsets = {
                    ARM7 = {4, 8, 16},
                    ARM8 = {8, 16, 32}
                }
                for i, v in ipairs(check_indexes) do
                    full_check_type_table[#full_check_type_table + 1] = {}
                    full_check_type_table[#full_check_type_table].address = v.address
                    full_check_type_table[#full_check_type_table].flags = flag_type
                    full_check_type_table[#full_check_type_table + 1] = {}
                    full_check_type_table[#full_check_type_table].address = v.address + offsets[Il2Cpp.ARM][1]
                    full_check_type_table[#full_check_type_table].flags = flag_type
                    full_check_type_table[#full_check_type_table + 1] = {}
                    full_check_type_table[#full_check_type_table].address = v.address + offsets[Il2Cpp.ARM][2]
                    full_check_type_table[#full_check_type_table].flags = flag_type
                    full_check_type_table[#full_check_type_table + 1] = {}
                    full_check_type_table[#full_check_type_table].address = v.address + offsets[Il2Cpp.ARM][3]
                    full_check_type_table[#full_check_type_table].flags = flag_type
                end
                local current_index = 1
                full_check_type_table = gg.getValues(full_check_type_table)
                local last_toast = os.time()
                for i, v in ipairs(full_check_type_table) do
                    if os.time() - last_toast > 10 then
                        bc.Toast(Il2Cpp.types_count .. " Types Found\n" .. i / 4 + total_checked .. " of " .. total_indexes .. " Pointers Checked","ℹ️")
                        last_toast = os.time()
                    end
                    if i == current_index then
                        current_index = current_index + 4
                        if full_check_type_table[i + 2].value == full_check_type_table[i + 3].value then
                            local method_index = full_check_type_table[i + 2].value
                            if not Il2Cpp.method_types[tostring(method_index)] then
                                Il2Cpp.types_count = Il2Cpp.types_count + 1
                                local getString = Il2Cpp.getString(full_check_type_table[i].value)
								if bc.isDirtyString(getString) == true then else
									Il2Cpp.method_types[tostring(method_index)] = getString
									for index = 1, 3 do
										Il2Cpp.method_types[tostring(method_index) + index] = getString
									end
                                end
                            end
                        end
                    end
                end
                full_check_type_table = nil
                gg.loadResults(check_table)
                total_checked = total_checked + get_indexes
                current_skip = current_skip + get_indexes
            until (current_skip > total_indexes)
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getTypes27 = function()
        Il2Cpp.method_types = {}
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        local gm_range_start
        local gm_range_end
        for i, v in pairs(gg.getRangesList()) do
            if ca_range == true then
                if v.state == "Ca" then
                    if tonumber(range_start) >= tonumber(v["start"]) and tonumber(range_start) <= tonumber(v["end"]) then
                        gm_range_start = v["start"]
                        gm_range_end = v["end"]
                        break
                    end
                end
            else
                if v.state == "O" then
                    if tonumber(range_start) >= tonumber(v["start"]) and tonumber(range_start) <= tonumber(v["end"]) then
                        gm_range_start = v["start"]
                        gm_range_end = v["end"]
                        break
                    end
                end
            end
        end
        local searches = {
            ["ARM7"] = {
                ["first"] = "0D;0~~0;" .. gm_range_start .. "~" .. gm_range_end .. ";0D::17",
                ["refine"] = "0~~0;" .. gm_range_start .. "~" .. gm_range_end .. ";0D::13",
                ["refine2"] = "0D;" .. gm_range_start .. "~" .. gm_range_end .. ";0D::9",
                ["refine3"] = "0~~0;" .. gm_range_start .. "~" .. gm_range_end .. "::5"
            }
        }
        gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
        gg.clearResults()
        local first_search = searches[Il2Cpp.ARM]["first"]
        gg.searchNumber(first_search, flag_type)
        local refine = searches[Il2Cpp.ARM]["refine"]
        gg.refineNumber(refine, flag_type)
        local refine2 = searches[Il2Cpp.ARM]["refine2"]
        gg.refineNumber(refine2, flag_type, nil, gg.SIGN_NOT_EQUAL)
        local refine3 = searches[Il2Cpp.ARM]["refine3"]
        gg.refineNumber(refine3, flag_type)
        local results = gg.getResults(gg.getResultsCount())
        local type_counter = 0
        for i, v in pairs(results) do
            if i % 1000 == 0 then
                bc.Toast(type_counter .. " Types Found\n" .. i .. " of " .. #results .. " Pointers Checked","ℹ️")
            end
            if i < #results then
                local type_id = {{
                    address = results[i + 1].value,
                    flags = gg.TYPE_DWORD
                }}
                type_id = gg.getValues(type_id)
                type_id = type_id[1].value
                if #tostring(type_id) < 8 then
                    local getString = Il2Cpp.getString(v.value, true)
                    if getString ~= "" and getString ~= nil then
						if bc.isDirtyString(getString) == true then else
							type_counter = type_counter + 1
							Il2Cpp.method_types[tostring(type_id)] = getString
							for index = 1, 3 do
								Il2Cpp.method_types[tostring(type_id + index)] = getString
							end
						end
                    end
                end
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    newCustomBuild = function(editBuild)
        local unityBuilds = {
        	"v24",
            "v24.1",
            "v24.2",
            "v24.3",
            "v24.4",
            "v24.5",
            "v27",
            "v27.1",
            "v27.2",
            "v29"
        }
        ::choose::
        local menu
        if not editBuild then
            menu = gg.choice(unityBuilds,nil, bc.Choice("Select Build", "Select build to use as base for your custom build.", "ℹ️"))
        else
            menu = Il2Cpp.customUnityBuilds[editBuild]
        end
        if menu == nil then
            goto choose
        else
            local baseAPI
            if editBuild then
                baseAPI = menu
            else
                baseAPI = Il2Cpp.Il2cppApi[unityBuilds[menu]]
            end
            local followPointers
            for i, v in ipairs(Il2Cpp.unityAPIs) do
                if unityBuilds[menu] == v[2] then
                    followPointers = v[4]
                    break
                end
            end
            table.insert(Il2Cpp.unityAPIs,1, {"custom", "custom", "custom", followPointers})
            local apiMenuVarNames = {
                [1] = "FieldApiOffset",
                [2] = "FieldApiType",
                [3] = "FieldApiClassOffset",
                [4] = "ClassApiNameOffset",
                [5] = "ClassApiMethodsStep",
                [6] = "ClassApiCountMethods",
                [7] = "ClassApiMethodsLink",
                [8] = "ClassApiFieldsLink",
                [9] = "ClassApiFieldsStep",
                [10] = "ClassApiCountFields",
                [11] = "ClassApiParentOffset",
                [12] = "ClassApiNameSpaceOffset",
                [13] = "ClassApiStaticFieldDataOffset",
                [14] = "MethodsApiClassOffset",
                [15] = "MethodsApiNameOffset",
                [16] = "MethodsApiParamCount",
                [17] = "MethodsApiReturnType",
                [18] = "TypeApiType"
            }
            ::continue::
            local apiMenu = {
                [1] = "FieldApiOffset\nARM7: "..baseAPI.FieldApiOffset.ARM7.."\nARM8: "..baseAPI.FieldApiOffset.ARM8,
                [2] = "FieldApiType\nARM7: "..baseAPI.FieldApiType.ARM7.."\nARM8: "..baseAPI.FieldApiType.ARM8,
                [3] = "FieldApiClassOffset\nARM7: "..baseAPI.FieldApiClassOffset.ARM7.."\nARM8: "..baseAPI.FieldApiClassOffset.ARM8,
                [4] = "ClassApiNameOffset\nARM7: "..baseAPI.ClassApiNameOffset.ARM7.."\nARM8: "..baseAPI.ClassApiNameOffset.ARM8,
                [5] = "ClassApiMethodsStep\nARM7: "..baseAPI.ClassApiMethodsStep.ARM7.."\nARM8: "..baseAPI.ClassApiMethodsStep.ARM8,
                [6] = "ClassApiCountMethods\nARM7: "..baseAPI.ClassApiCountMethods.ARM7.."\nARM8: "..baseAPI.ClassApiCountMethods.ARM8,
                [7] = "ClassApiMethodsLink\nARM7: "..baseAPI.ClassApiMethodsLink.ARM7.."\nARM8: "..baseAPI.ClassApiMethodsLink.ARM8,
                [8] = "ClassApiFieldsLink\nARM7: "..baseAPI.ClassApiFieldsLink.ARM7.."\nARM8: "..baseAPI.ClassApiFieldsLink.ARM8,
                [9] = "ClassApiFieldsStep\nARM7: "..baseAPI.ClassApiFieldsStep.ARM7.."\nARM8: "..baseAPI.ClassApiFieldsStep.ARM8,
                [10] = "ClassApiCountFields\nARM7: "..baseAPI.ClassApiCountFields.ARM7.."\nARM8: "..baseAPI.ClassApiCountFields.ARM8,
                [11] = "ClassApiParentOffset\nARM7: "..baseAPI.ClassApiParentOffset.ARM7.."\nARM8: "..baseAPI.ClassApiParentOffset.ARM8,
                [12] = "ClassApiNameSpaceOffset\nARM7: "..baseAPI.ClassApiNameSpaceOffset.ARM7.."\nARM8: "..baseAPI.ClassApiNameSpaceOffset.ARM8,
                [13] = "ClassApiStaticFieldDataOffset\nARM7: "..baseAPI.ClassApiStaticFieldDataOffset.ARM7.."\nARM8: "..baseAPI.ClassApiStaticFieldDataOffset.ARM8,
                [14] = "MethodsApiClassOffset\nARM7: "..baseAPI.MethodsApiClassOffset.ARM7.."\nARM8: "..baseAPI.MethodsApiClassOffset.ARM8,
                [15] = "MethodsApiNameOffset\nARM7: "..baseAPI.MethodsApiNameOffset.ARM7.."\nARM8: "..baseAPI.ClassApiNameOffset.ARM8,
                [16] = "MethodsApiParamCount\nARM7: "..baseAPI.MethodsApiParamCount.ARM7.."\nARM8: "..baseAPI.MethodsApiParamCount.ARM8,
                [17] = "MethodsApiReturnType\nARM7: "..baseAPI.MethodsApiReturnType.ARM7.."\nARM8: "..baseAPI.MethodsApiReturnType.ARM8,
                [18] = "TypeApiType\nARM7: "..baseAPI.TypeApiType.ARM7.."\nARM8: "..baseAPI.TypeApiType.ARM8,
                [19] = "Done"
            }
            local buildMenu = gg.choice(apiMenu,nil,"")
            if buildMenu == nil then
                goto continue
            else
                if buildMenu == 19 then
                    Il2Cpp.Il2cppApi["custom"] = baseAPI
                    baseAPI.unityAPI = {"custom", "custom", "custom", followPointers}
                    Il2Cpp.saveCustomBuild(baseAPI)
                    return nil
                end
                local variableMenu = gg.prompt ({
                    apiMenuVarNames[buildMenu].. " ARM7",
                    apiMenuVarNames[buildMenu].. " ARM8" 
                },{
                    baseAPI[apiMenuVarNames[buildMenu]].ARM7, 
                    baseAPI[apiMenuVarNames[buildMenu]].ARM8
                },{
                    "number",
                    "number"
                })
                if variableMenu ~= nil then
                    baseAPI[apiMenuVarNames[buildMenu]].ARM7 = variableMenu[1]
                    baseAPI[apiMenuVarNames[buildMenu]].ARM8 = variableMenu[2]
                end
                goto continue
            end
        end
    end,
    saveCustomBuild = function(build)
        if not Il2Cpp.customUnityBuilds then
            Il2Cpp.customUnityBuilds = {}
        end
        Il2Cpp.customUnityBuilds[gg.getTargetPackage()] = build
        bc.saveTable("Il2Cpp.customUnityBuilds",configDataPath .. gg.getTargetPackage().."_customBuilds.lua",false,true)
    end,
    savedCustomBuild = function()
        local menu_items = {}
        for k,_ in pairs (Il2Cpp.customUnityBuilds) do
            menu_items[#menu_items + 1] = k
        end
        ::choose::
        local menu = gg.choice (menu_items,nil, bc.Choice("Select Build", "Select custom build to edit.", "ℹ️"))
        if menu == nil then
            goto choose
        else
            Il2Cpp.newCustomBuild(menu_items[menu])
        end
    end,
    loadCustomBuilds = function ()
        local status, retval = pcall(bc.readFile, configDataPath .. gg.getTargetPackage().."_customBuilds.lua");
        if status == true then
            dofile(configDataPath .. gg.getTargetPackage().."_customBuilds.lua")
            if Il2Cpp.customUnityBuilds[gg.getTargetPackage()] then
                table.insert(Il2Cpp.unityAPIs,1, Il2Cpp.customUnityBuilds[gg.getTargetPackage()].unityAPI)
                Il2Cpp.Il2cppApi["custom"] = Il2Cpp.customUnityBuilds[gg.getTargetPackage()]
            end
        end
    end,
    customBuild = function()
        ::choose::
        local menu = gg.choice ({"Create New Custom Build","Edit Saved Custom Build"},nil, bc.Choice("Custom Build Menu", "Create new or edit saved custom build.", "ℹ️"))
        if menu == nil then 
            goto choose
        else
            if menu == 1 then
                Il2Cpp.newCustomBuild()
            end
            if menu == 2 then
                Il2Cpp.savedCustomBuild()
            end
        end
    end,
    configureScript = function(choices)
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        ::set_menu::
        if choices then
			Il2Cpp.scriptSettings = choices
        else
			Il2Cpp.scriptSettings = gg.multiChoice({"Get Fields (Select at least one)", "Get Methods (Select at least one)", "Check For Old Unity Version (5.X.X)", "Filter Results", "Manually Select Unity Build", "Alternate Get Strings (If Freezes At Start)", "Debug Mode","Save Dump","Custom Unity Build"}, {true, true, false, true, false, false,false,true,false}, script_title)
        end
        if Il2Cpp.scriptSettings == nil then
            return false
        end
        if not Il2Cpp.arch then
            ::set_arm::
            local arch_menu = gg.choice({"ARM7", "ARM8"}, nil, bc.Choice("Select ARM", "Is this game ARM7 (32bit) or ARM8 (64bit)? ", "ℹ️"))
            if arch_menu == nil then
                goto set_arm
            else
                if arch_menu == 1 then
                    Il2Cpp.arch = {}
                end
                if arch_menu == 2 then
                    Il2Cpp.arch = {}
                    Il2Cpp.arch.x64 = true
                end
            end
        end
        if Il2Cpp.arch.x64 then
            flag_type = gg.TYPE_QWORD
            Il2Cpp.ARM = "ARM8"
        else
            flag_type = gg.TYPE_DWORD
            Il2Cpp.ARM = "ARM7"
        end
        if Il2Cpp.scriptSettings[4] == true then
            local menu = gg.multiChoice({"`", "[]"}, {true, true}, bc.Choice("Skip class names containing the below characters.", "", "ℹ️"))
            if menu ~= nil then
                if menu[1] == true then
                    Il2Cpp.filters[#Il2Cpp.filters + 1] = "`"
                end
                if menu[2] == true then
                    Il2Cpp.filters[#Il2Cpp.filters + 1] = "%[%]"
                end
            end
        end
        if Il2Cpp.scriptSettings[7] == true then
            ::get_classes::
            local menu = gg.prompt({"Number of classes to dump", "Number of classes to skip"}, {100, 0}, {"number", "number"})
            if menu == nil then
                goto get_classes
            else
                test_classes = tonumber(menu[1])
                test_classes_skip = tonumber(menu[2])
                skipped_class_count = 0
            end
            Il2Cpp.isDebugging = true
            local debug_name = debug.getinfo(2, "n").name        
            Il2Cpp.debugFuncStart(debug_name)
        end
        if not Il2Cpp.globalMetadataStrings then
			Il2Cpp.selectLibrary()
			Il2Cpp.getCaRanges()
			dumpStartTime = os.time()
			Il2Cpp.getMetadataStringsRange()
			local skipMe = false
			if Il2Cpp.Il2cppApi["custom"] then
			    ::choose::
			    local useSaved = gg.choice ({"Yes","No"},nil, bc.Choice("Custom Build Found", "A saved custom build was found for this game. Do you want to use it?", "ℹ️"))
			    if useSaved == nil then
			        goto choose
			    else
			        if useSaved == 1 then
			            skipMe = true
			            Il2Cpp.setAPIVariables("custom")
			        end
			    end
			end
			if skipMe == false then
			    if Il2Cpp.scriptSettings[5] == true then
				    Il2Cpp.selectBuild()
			    elseif Il2Cpp.scriptSettings[9] == true then
			        Il2Cpp.customBuild()
			        Il2Cpp.setAPIVariables("custom")
			    else
				    Il2Cpp.setAPIVariables()
			    end
			end
			local start_address = range_start - 1
			gg.clearResults()
			if ca_range == true then
				gg.setRanges(gg.REGION_C_ALLOC)
			else
				gg.setRanges(gg.REGION_OTHER)
			end
			gg.searchNumber("0", gg.TYPE_BYTE, nil, nil, start_address, range_end)
			local total_results = gg.getResultsCount()
			if Il2Cpp.scriptSettings[6] == true then
				Il2Cpp.getGlobalMetadataStringsBig()
			else
				Il2Cpp.getGlobalMetadataStrings()
			end
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    getAdditionalTypes = function()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        if not Il2Cpp.method_types then
        Il2Cpp.method_types = {}
        end
        for index, value in pairs(Il2Cpp.get_method_searches) do
            for k, v in pairs(Il2Cpp.globalMetadataStrings) do
                if v == value[2] then
                    local text_string = {{
                        address = k,
                        flags = gg.TYPE_BYTE
                    }}
                    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
                    gg.loadResults(text_string)
                    text_string_pointer = gg.getResults(1)
                    gg.clearResults()
                    gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
                    gg.loadResults(text_string)
                    gg.searchPointer(0)
                    text_string_pointer = gg.getResults(1)
                    if gg.getResultsCount() > 0 then
                        local get_type2 = {}
                        get_type2[1] = {}
                        get_type2[1].address = text_string_pointer[1].address + Il2Cpp.FieldApiClassOffset
                        get_type2[1].flags = flag_type
                        get_type2 = gg.getValues(get_type2)
                        local get_type3 = {}
                        get_type3[1] = {}
                        get_type3[1].address = get_type2[1].value
                        get_type3[1].flags = gg.TYPE_DWORD
                        get_type3 = gg.getValues(get_type3)
                        mid = get_type3[1].value
                        if not Il2Cpp.method_types[tostring(mid)] then
                            Il2Cpp.method_types[tostring(mid)] = value[1]
                            for ind = 1, 3 do
                                Il2Cpp.method_types[tostring(mid + ind)] = value[1]
                            end
                        end
                        break
                    end
                end
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    createSearch = function(search_string)
        local byte_search = ":" .. string.char(0) .. search_string .. string.char(0)
        return byte_search
    end,
    saveTypes = function(filename)
        local temp_table = {}
        for k, v in pairs(Il2Cpp.method_types) do
            if v:find("\\") then
            else
                temp_table[k] = v
            end
        end
        Il2Cpp.method_types = temp_table
        bc.saveTable("Il2Cpp.method_types",filename)
    end,
    getMethodTypes = function ()
        local debug_name = debug.getinfo(2, "n").name        
        Il2Cpp.debugFuncStart(debug_name)
        if not Il2Cpp.method_types then
            Il2Cpp.method_types = {}
        end
        for i, v in pairs(Il2Cpp.get_method_searches) do
            gg.setRanges(gg.REGION_OTHER)
            gg.clearResults()
            gg.searchNumber(":" .. string.char(0) .. v[2] .. string.char(0), gg.TYPE_BYTE, false, gg.SIGN_EQUAL, range_start, range_end)
            local string_address = gg.getResults(1, 1)
            if gg.getResultsCount() > 0 then
                string_address = string_address[1].address
                gg.clearResults()
                gg.setRanges(gg.REGION_OTHER | gg.REGION_C_ALLOC)
                gg.searchNumber(string_address, flag_type, nil, nil, nil, nil, 1)
                local method_data = gg.getResults(1)
                if gg.getResultsCount() > 0 then
                    local get_type = {}
                    get_type[1] = {}
                    if Il2Cpp.arch.x64 then
                        get_type[1].address = method_data[1].address + 16
                    else
                        get_type[1].address = method_data[1].address + 8
                    end
                    get_type[1].flags = flag_type
                    get_type = gg.getValues(get_type)
                    local get_type2 = {}
                    get_type2[1] = {}
                    get_type2[1].address = get_type[1].value
                    get_type2[1].flags = gg.TYPE_DWORD
                    get_type2 = gg.getValues(get_type2)
                    local final_type
                    if #tostring(get_type2[1].value) > 6 then
                        if Il2Cpp.arch.x64 then
                            get_type2[1].flags = gg.TYPE_QWORD
                            get_type2 = gg.getValues(get_type2)
                        end
                        local get_type3 = {}
                        get_type3[1] = {}
                        get_type3[1].address = get_type2[1].value
                        get_type3[1].flags = gg.TYPE_DWORD
                        get_type3 = gg.getValues(get_type3)
                        for index = 1, 10 do
                            Il2Cpp.method_types[tostring(get_type3[1].value + index)] = v[1]
                        end
                        final_type = get_type3[1].value
                    else
                        final_type = get_type2[1].value
                    end
                    Il2Cpp.method_types[tostring(final_type)] = v[1]
                end
            end
        end
        Il2Cpp.debugFuncEnd(debug_name)
    end,
    get_method_searches = {
        {"Boolean", "System.IConvertible.ToBoolean"}, 
        {"Int16", "System.IConvertible.ToInt16"}, 
        {"Int32", "System.IConvertible.ToInt32"}, 
        {"Int64", "System.IConvertible.ToInt64"}, 
        {"UInt16", "System.IConvertible.ToUInt16"}, 
        {"UInt32", "System.IConvertible.ToUInt32"}, 
        {"UInt64", "System.IConvertible.ToUInt64"}, 
        {"Single", "System.IConvertible.ToSingle"}, 
        {"Double", "System.IConvertible.ToDouble"}, 
        {"String", "ToString"}, 
        {"Void", "GetObjectData"},
        {"Char", "System.IConvertible.ToChar"}, 
        {"SByte", "System.IConvertible.ToSByte"}, 
        {"Byte", "System.IConvertible.ToByte"}, 
        {"Decimal", "System.IConvertible.ToDecimal"}, 
        {"Object", "System.IConvertible.ToType"}, 
        {"Vector2", "get_moveVector"}, 
        {"Vector3", "WorldToViewportPoint"}, 
        {"Vector4", "GetTextureScaleAndOffsetImpl"}, 
        {"DateTime", "System.IConvertible.ToDateTime"}, 
        {"GameObject", "get_gameObject"}, 
        {"Texture", "GetTextureImpl"}, 
        {"Color", "GetColorImpl"},
        {"Material", "get_materialForRendering"}, 
        {"Transform", "get_parentInternal"}, 
        {"Matrix4x4", "get_worldToLocalMatrix"}
    },
    debugFuncStart = function(debug_name)
        if Il2Cpp.isDebugging == true then
            if not Il2Cpp.debugTimeTable[debug_name] then
                Il2Cpp.debugTimeTable[debug_name] = {
                    count = 0,
                    sub_count = 0,
                    total = 0
                }
            end
            Il2Cpp.debugTimeTable[debug_name].count = Il2Cpp.debugTimeTable[debug_name].count + 1
            Il2Cpp.debugTimeTable[debug_name].start = os.time()
        end
    end,
    debugFuncEnd = function(debug_name)
        if Il2Cpp.isDebugging == true then
            Il2Cpp.debugTimeTable[debug_name].finished = os.time()
            local debug_time_total = Il2Cpp.debugTimeTable[debug_name].finished - Il2Cpp.debugTimeTable[debug_name].start
            Il2Cpp.debugTimeTable[debug_name].total = Il2Cpp.debugTimeTable[debug_name].total + debug_time_total
        end
    end,
    getBoolEdit = function()
        local arm7Edit = {
            isTrue = {"~A MOV R0, #1", "~A BX LR"},
            isFalse = {"~A MOV R0, #0", "~A BX LR"}
        }
        local arm8Edit = {
            isTrue = {"~A8 MOV W0, #1", "~A8 RET"},
            isFalse = {"~A8 MOV W0, WZR", "~A8 RET"}
        }
        local menu = gg.choice({"True", "False"},nil, bc.Choice("Set Boolean Edit", "", "ℹ️"))
        if menu ~= nil then
            if menu == 1 then
                return {arm7Edit.isTrue, arm8Edit.isTrue}
            end
            if menu == 2 then
                return {arm7Edit.isFalse, arm8Edit.isFalse}
            end
        end
    end,
    getIntEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        ::set_val::
        local menu = gg.prompt({bc.Prompt("Enter Number -255 to 65535","ℹ️")}, {nil}, {"number"})
        if menu ~= nil then
            if tonumber(menu[1]) < -256 or tonumber(menu[1]) > 65535 then
                bc.Alert("Set A Valid Number", "Set a valid number from -255 to 65535.", "⚠️")
                goto set_val
            end
            if tonumber(menu[1]) == 0 then
                edits_arm8[1] = "~A8 MOV W0, WZR"
            else
                edits_arm8[1] = "~A8 MOV W0, #" .. menu[1]
            end
            edits_arm8[2] = "~A8 RET"
            if menu[1]:find("[-]") then
                edits_arm7[1] = "~A MVN R0, #" .. menu[1]:gsub("[-]", "")
                edits_arm7[2] = "~A BX LR"
            else
                edits_arm7[1] = "~A MOVW R0, #" .. menu[1]
                edits_arm7[2] = "~A BX LR"
            end
            return {edits_arm7, edits_arm8}
        end
    end,
    getComplexFloatEdit = function(target, method_type)
        target = tonumber(target)
        local float_edits_arm7 = {}
        local float_edits_arm8 = {}
        if target <= 65535 and target >= 0 then
            if method_type == "Single" then
                float_edits_arm7[1] = "~A MOVW R0, #" .. target
                float_edits_arm7[2] = "100A00EEr" -- VMOV S0, R0
                float_edits_arm7[3] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                float_edits_arm7[4] = "100A10EEr" -- VMOV R0, S0
                float_edits_arm7[5] = "1EFF2FE1r" -- BX LR
                if target == 0 then
                    float_edits_arm8[1] = "~A8 MOV W0, WZR"
                else
                    float_edits_arm8[1] = "~A8 MOV W0, #" .. target
                end
                float_edits_arm8[2] = "0000271Er" -- FMOV S0, W0
                float_edits_arm8[3] = "00D8215Er" -- SCVTF S0, S0
                float_edits_arm8[4] = "0000261Er" -- FMOV W0, S0
                float_edits_arm8[5] = "C0035FD6r" -- RET
            elseif method_type == "Double" then
                float_edits_arm7[1] = "~A MOVW R0, #" .. target
                float_edits_arm7[2] = "~A VMOV S0, R0"
                float_edits_arm7[3] = "~A VCVT.F64.U32 D0, S0"
                float_edits_arm7[4] = "~A VMOV R0, R1, D0"
                float_edits_arm7[5] = "1EFF2FE1r" -- BX LR
                if target == 0 then
                    float_edits_arm8[1] = "~A8 MOV W0, WZR"
                else
                    float_edits_arm8[1] = "~A8 MOV W0, #" .. target
                end
                float_edits_arm8[2] = "~A8 SCVTF D0, W0"
                float_edits_arm8[3] = "C0035FD6r" -- RET
            end
        end
        if target <= 131072 and target >= 65537 then
            float_val_2 = target - 65535
            if method_type == "Single" then
                float_edits_arm7[1] = "~A MOVW R0, #65535"
                float_edits_arm7[2] = "~A MOVW R1, #" .. float_val_2
                float_edits_arm7[3] = "010080E0r" -- ADD R0, R0, R1
                float_edits_arm7[4] = "100A00EEr" -- VMOV S0, R0
                float_edits_arm7[5] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                float_edits_arm7[6] = "100A10EEr" -- VMOV R0, S0
                float_edits_arm7[7] = "1EFF2FE1r" -- BX LR
                float_edits_arm8[1] = "~A8 MOV W0, #65535"
                float_edits_arm8[2] = "~A8 MOV W1, #" .. float_val_2
                float_edits_arm8[3] = "0000010Br" -- ADD W0, W0, W1
                float_edits_arm8[4] = "0000271Er" -- FMOV S0, W0
                float_edits_arm8[5] = "00D8215Er" -- SCVTF S0, S0
                float_edits_arm8[6] = "0000261Er" -- FMOV W0, S0
                float_edits_arm8[7] = "C0035FD6r" -- RET
            elseif method_type == "Double" then
                float_edits_arm7[1] = "~A MOVW R0, #65535"
                float_edits_arm7[2] = "~A MOVW R1,  #" .. float_val_2
                float_edits_arm7[3] = "~A ADD R0, R0, R1"
                float_edits_arm7[4] = "~A VMOV S0, R0"
                float_edits_arm7[5] = "~A VCVT.F64.U32 D0, S0"
                float_edits_arm7[6] = "~A VMOV R0, R1, D0"
                float_edits_arm7[7] = "1EFF2FE1r" -- BX LR
                float_edits_arm8[1] = "~A8 MOV W0, #65535"
                float_edits_arm8[2] = "~A8 MOV W1,  #" .. float_val_2
                float_edits_arm8[3] = "~A8 ADD W0, W0, W1"
                float_edits_arm8[4] = "~A8 SCVTF D0, W0"
                float_edits_arm8[5] = "C0035FD6r" -- RET
            end
        end
        if target > 131072 and target < 429503284 then
            for i = 2, 65536 do
                rem = target % i
                mult = i
                sub_total = rem * mult
                add_to = target - sub_total
                if add_to <= 65536 and add_to > 0 then
                    if method_type == "Single" then
                        float_edits_arm7[1] = "~A MOVW R0, #" .. rem
                        float_edits_arm7[2] = "~A MOVW R1, #" .. mult
                        float_edits_arm7[3] = "900100E0r" -- MUL R0, R0, R1
                        float_edits_arm7[4] = "~A MOVW R1, #" .. add_to
                        float_edits_arm7[5] = "010080E0r" -- ADD R0, R0, R1
                        float_edits_arm7[6] = "100A00EEr" -- VMOV S0, R0
                        float_edits_arm7[7] = "C00AB8EEr" -- VCVT.F32.S32 S0, S0
                        float_edits_arm7[8] = "100A10EEr" -- VMOV R0, S0
                        float_edits_arm7[9] = "1EFF2FE1r" -- BX LR
                        float_edits_arm8[1] = "~A8 MOV W0, #" .. rem
                        float_edits_arm8[2] = "~A8 MOV W1, #" .. mult
                        float_edits_arm8[3] = "007C011Br" -- MUL W0, W0, W1
                        float_edits_arm8[4] = "~A8 MOV W1, #" .. add_to
                        float_edits_arm8[5] = "0000010Br" -- ADD W0, W0, W1
                        float_edits_arm8[6] = "0000271Er" -- FMOV S0, W0
                        float_edits_arm8[7] = "00D8215Er" -- SCVTF S0, S0
                        float_edits_arm8[8] = "0000261Er" -- FMOV W0, S0
                        float_edits_arm8[9] = "C0035FD6r" -- RET
                    elseif method_type == "Double" then
                        float_edits_arm7[1] = "~A MOVW R0, #" .. rem
                        float_edits_arm7[2] = "~A MOVW R1,  #" .. mult
                        float_edits_arm7[3] = "~A MUL R0, R0, R1"
                        float_edits_arm7[4] = "~A MOVW R1,  #" .. add_to
                        float_edits_arm7[5] = "~A ADD R1, R0, R1"
                        float_edits_arm7[6] = "~A VMOV S0, R0"
                        float_edits_arm7[7] = "~A VCVT.F64.U32 D0, S0"
                        float_edits_arm7[8] = "~A VMOV R0, R1, D0"
                        float_edits_arm7[9] = "1EFF2FE1r" -- BX LR
                        float_edits_arm8[1] = "~A8 MOV W0, #" .. rem
                        float_edits_arm8[2] = "~A8 MOV W1,  #" .. mult
                        float_edits_arm8[3] = "~A8 MUL W0, W0, W1"
                        float_edits_arm8[4] = "~A8 MOV W1,  #" .. add_to
                        float_edits_arm8[5] = "~A8 ADD W0, W0, W1"
                        float_edits_arm8[6] = "~A8 SCVTF D0, W0"
                        float_edits_arm8[7] = "C0035FD6r" -- RET
                    end
                    break
                end
            end
            if target > 429503283 then
                bc.Alert("Value Is Too High", "Set lower than 429503283.", "⚠️")
            end
            if target < 0 then
                bc.Alert("Value Is Too Low", "Set to 0 or higher.", "⚠️")
            end
        end
        if float_edits_arm7 and float_edits_arm8 then
            return {float_edits_arm7, float_edits_arm8}
        end
    end,
    simpleFloatsTable = {
        ["ARM7"] = {{
            ["hex_edits"] = "0101A0E3r",
            ["float_value"] = 2
        }, {
            ["hex_edits"] = "4104A0E3r",
            ["float_value"] = 8
        }, {
            ["hex_edits"] = "4204A0E3r",
            ["float_value"] = 32
        }, {
            ["hex_edits"] = "4304A0E3r",
            ["float_value"] = 128
        }, {
            ["hex_edits"] = "1103A0E3r",
            ["float_value"] = 512
        }, {
            ["hex_edits"] = "4504A0E3r",
            ["float_value"] = 2048
        }, {
            ["hex_edits"] = "4604A0E3r",
            ["float_value"] = 8192
        }, {
            ["hex_edits"] = "4704A0E3r",
            ["float_value"] = 32768
        }, {
            ["hex_edits"] = "1203A0E3r",
            ["float_value"] = 131072
        }, {
            ["hex_edits"] = "4904A0E3r",
            ["float_value"] = 524288
        }, {
            ["hex_edits"] = "0502A0E3r",
            ["float_value"] = 8589934592
        }, {
            ["hex_edits"] = "5104A0E3r",
            ["float_value"] = 34359738368
        }, {
            ["hex_edits"] = "5204A0E3r",
            ["float_value"] = 137438953472
        }, {
            ["hex_edits"] = "5304A0E3r",
            ["float_value"] = 549755813888
        }, {
            ["hex_edits"] = "1503A0E3r",
            ["float_value"] = 2199023255552
        }, {
            ["hex_edits"] = "5504A0E3r",
            ["float_value"] = 8796093022208
        }, {
            ["hex_edits"] = "5604A0E3r",
            ["float_value"] = 35184372088832
        }, {
            ["hex_edits"] = "5704A0E3r",
            ["float_value"] = 140737488355328
        }, {
            ["hex_edits"] = "1603A0E3r",
            ["float_value"] = 562949953421312
        }, {
            ["hex_edits"] = "5904A0E3r",
            ["float_value"] = 2251799813685248
        }, {
            ["hex_edits"] = "0602A0E3r",
            ["float_value"] = 36893488147419103000
        }},
        ["ARM8"] = {{
            ["hex_edits"] = "0000A852r",
            ["float_value"] = 2
        }, {
            ["hex_edits"] = "0020A852r",
            ["float_value"] = 8
        }, {
            ["hex_edits"] = "0040A852r",
            ["float_value"] = 32
        }, {
            ["hex_edits"] = "0060A852r",
            ["float_value"] = 128
        }, {
            ["hex_edits"] = "0080A852r",
            ["float_value"] = 512
        }, {
            ["hex_edits"] = "00A0A852r",
            ["float_value"] = 2048
        }, {
            ["hex_edits"] = "00C0A852r",
            ["float_value"] = 8192
        }, {
            ["hex_edits"] = "00E0A852r",
            ["float_value"] = 32768
        }, {
            ["hex_edits"] = "0000A952r",
            ["float_value"] = 131072
        }, {
            ["hex_edits"] = "0020A952r",
            ["float_value"] = 524288
        }, {
            ["hex_edits"] = "0000AA52r",
            ["float_value"] = 8589934592
        }, {
            ["hex_edits"] = "0020AA52r",
            ["float_value"] = 34359738368
        }, {
            ["hex_edits"] = "0040AA52r",
            ["float_value"] = 137438953472
        }, {
            ["hex_edits"] = "0060AA52r",
            ["float_value"] = 549755813888
        }, {
            ["hex_edits"] = "0080AA52r",
            ["float_value"] = 2199023255552
        }, {
            ["hex_edits"] = "00A0AA52r",
            ["float_value"] = 8796093022208
        }, {
            ["hex_edits"] = "00C0AA52r",
            ["float_value"] = 35184372088832
        }, {
            ["hex_edits"] = "00E0AA52r",
            ["float_value"] = 140737488355328
        }, {
            ["hex_edits"] = "0000AB52r",
            ["float_value"] = 562949953421312
        }, {
            ["hex_edits"] = "0020AB52r",
            ["float_value"] = 2251799813685248
        }, {
            ["hex_edits"] = "0000AC52r",
            ["float_value"] = 36893488147419103000
        }}
    },
    getSimpleFloatEdit = function()
        local edits_arm7 = {}
        local edits_arm8 = {}
        local menu_table = {}
        for i, v in pairs(Il2Cpp.simpleFloatsTable["ARM7"]) do
            menu_table[#menu_table + 1] = v.float_value
        end
        local menu = gg.choice(menu_table, nil, bc.Choice("Select Float Value", "", "ℹ️"))
        if menu ~= nil then
            edits_arm7[1] = Il2Cpp.simpleFloatsTable["ARM7"][menu].hex_edits
            edits_arm7[2] = "~A BX LR"
            edits_arm8[1] = Il2Cpp.simpleFloatsTable["ARM8"][menu].hex_edits
            edits_arm8[2] = "~A8 RET"
            return {edits_arm7, edits_arm8}
        end
    end,
}

bc = {
	Toast = function(toast_string,emoji)
	local _ = utf8.char(9552)
	gg.toast(script_title .. "\n\n"..emoji.._.._.._.._.._.._.._.._.._.._.._.._.._..emoji.."\n\n" .. toast_string .. "\n\n"..emoji.._.._.._.._.._.._.._.._.._.._.._.._.._..emoji)
    end,
    createDirectory = function(savePath)
        directory_created = true
        for i, v in pairs(gg.getRangesList()) do
            if v["end"] - v.start < 10240 then
                if not v["name"]:find( "deleted") then
                    create_start = v.start
                    create_end = v["end"]
                    break
                end
            end
        end
        gg.dumpMemory(create_start, create_end, savePath, gg.DUMP_SKIP_SYSTEM_LIBS)
    end,
    saveTable = function(tableName,savePath,JSON,atOnce)
		
		local temp_table 
        if tableName:find("[.]") then
			temp_table = _G[tableName:gsub("(.+)[.].+","%1")][tableName:gsub(".+[.](.+)","%1")]
        else
			temp_table = _G[tableName]
        end
        if JSON == true then
            local file = io.open(savePath, "w+")
            file:write(json.encode(temp_table))
            file:close()
        else
            if atOnce == true then
                local file = io.open(savePath, "w+")
                file:write(tableName .. " = "..tostring(temp_table))
                file:close()
            else
                local file = io.open(savePath, "w+")
                file:write("")
                file:close()
                local file = io.open(savePath, "a")
                file:write(tableName .. " = {\n")
                for i,v in ipairs (temp_table) do
                    file:write(tostring(v) .. ",\n")
                end
                file:write("}")
                file:close()
            end
        end
    end,
    Alert = function(headerString, bodyString, emoji)
        if #bodyString > 0 then
            gg.alert(script_title .. "\n\n" .. emoji .. " " .. headerString .. " " .. emoji .. "\n\n" .. bodyString)
        else
            gg.alert(script_title .. "\n\n" .. emoji .. " " .. headerString .. " " .. emoji)
        end
    end,
    Choice = function(headerString, bodyString, emoji)
        if #bodyString > 0 then
            return script_title .. "\n\n" .. emoji .. " " .. headerString .. " " .. emoji .. "\n\n" .. bodyString
        else
            return script_title .. "\n\n" .. emoji .. " " .. headerString .. " " .. emoji
        end
    end,
    Prompt = function(headerString, emoji)
        return script_title .. "\n\n" .. emoji .. " " .. headerString .. " " .. emoji
    end,
    readFile = function(filePath,JSON)
        local file = io.open(filePath, "r")
        local content = file:read("*a")
        file:close()
        if JSON == true then
            content = json.decode(content)
        end
        return content
    end,
    isDirtyString = function(checkString)
    if checkString:find( " ") or 
		checkString:find( "") or
        checkString:find( "") or 
		checkString:find( "\r\n") or
        checkString:find( "\r") or 
		checkString:find( "\n") or
        checkString:find( "") or 
		checkString:find( '"') then
			return true
		end
    end,
    tagPointers = function(pointersTable)
		for i,v in pairs (pointersTable) do
			pointersTable[i].address = tostring(pointersTable[i].address):gsub("0x","0xB40000")
		end
		return pointersTable
    end,
    untagPointers = function(pointersTable)
		for i,v in pairs (pointersTable) do
			pointersTable[i].address = tostring(pointersTable[i].address):gsub("0xB40000","0x")
		end
		return pointersTable
    end,
}

if pcall(pM.initPluginManager) == false then
    pM.toolboxAllPlugins = pM.toolboxPlugins
    pM.saveAllPlugins()
    pM.saveMenuLimit()
end

pM.savePlugins()

Il2Cpp.loadCustomBuilds()

pM.home()

gg.showUiButton()

while true do
    pM.doWhileLoop()
    if gg.isClickedUiButton() then
        pM.home()
    end
    gg.sleep(100)
end
