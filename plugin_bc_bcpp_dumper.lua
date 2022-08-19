bcpp_dumper = {
        home = function(passed_data)
            if Il2Cpp.configureScript() ~= false then
                Il2Cpp.scan()
                bc.Alert("Dump Complete","The dump has been saved to your Download folder.","ℹ️")
            end
        end
    }
pluginManager.returnHome = false
pluginManager.returnPluginTable = "bcpp_dumper"
bcpp_dumper.home()