if pluginManager.installingPlugin == true then
    --[[
	---------------------------------------
	pluginManager.installingPluginName = "Menu Name"
	
	Set the name that appears in the main menu for your plugin.
	---------------------------------------
	]] --
    pluginManager.installingPluginName = "Template Plugin"
    --[[
	---------------------------------------
	pluginManager.installingPluginTable = "changeMeToUniqueName"
	
	Set the name of the main table for your plugin that contains your home() menu.
	---------------------------------------
	]] --
    pluginManager.installingPluginTable = "changeMeToUniqueName"
else
    changeMeToUniqueName = {
        --[[
	---------------------------------------
	changeMeToUniqueName.home(passed_data)
	
	The home menu or main function of your plugin.
	Data can be passed to your plugin from other plugins
	with passed_data.
	---------------------------------------
	]] --
        home = function(passed_data)
            --[[
	    ---------------------------------------
	    Sets toolbox to return to your plugin. See below for more information.
	    ---------------------------------------
	    ]] --
            pluginManager.returnHome = true
            pluginManager.returnPluginTable = "changeMeToUniqueName"
            if passed_data then
                --[[
	        ---------------------------------------
	        Do something with passed data here
	        ---------------------------------------
	        ]] --
                gg.alert(passed_data)
            else
                local menu = gg.choice({"Call a plugin and pass data",
                                        "Call the default plugin for method search results",
                                        "Exit and stop returning to your plugin menu"}, 
										nil,
										"ℹ️ BadCase's Toolbox Plugin Template ℹ️")
                if menu ~= nil then
                    if menu == 1 then
                        --[[
	                ---------------------------------------
	                pluginManager.callPlugin(plugin_path, function_table, passed_data)
 
                    Calls a plugin and optionally passes data to it.
                    plugin_path and  function_table are required.
	                ---------------------------------------
	                ]] --
                        pluginManager.callPlugin(pluginsDataPath .. "plugin_bc_template.lua", "changeMeToUniqueName", "Hello World !!!")
                    end
                    if menu == 2 then
                        --[[
	                ---------------------------------------
	                pluginManager.defaultHandler(handler, passed_data)
 
                    Calls a default plugin and optionally passes data to it.
                    handler is required.
                    Handlers: method_results, class_results, enum_results, field_results
	                ---------------------------------------
	                ]] --
                        pluginManager.defaultHandler("class_results", "isUnlocked")
                    end
                    if menu == 3 then
                        --[[
	                ---------------------------------------
	                Exit your scripts menu and return normal functionality to the floating [Sx] button.
	                See below for more details.
	                ---------------------------------------
	                ]] --
                        pluginManager.returnHome = false
                    end
                end
            end
        end
    }
    --[[
	---------------------------------------
	pluginManager.returnHome = boolean
	true : makes GG return to your plugins menu when the floating [Sx] button is pressed
	false : set to false when you want normal functionality to return to the floating [Sx] button
	---------------------------------------
	]] --
    pluginManager.returnHome = true
    --[[
	---------------------------------------
	pluginManager.returnPluginTable = "table_name"
	When setting pluginManager.returnHome to true set your plugins table name to this variable
	---------------------------------------
	]] --
    pluginManager.returnPluginTable = "changeMeToUniqueName"
    changeMeToUniqueName.home()
end
