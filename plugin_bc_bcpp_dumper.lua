bcpp_dumper = {
    home = function(passed_data)
        if Il2Cpp.configureScript() ~= false then
            gg.clearList()
            if not Il2Cpp.method_types then
                ::menu2::
                local menu = gg.choice({"Yes (SLOW)", "No (Faster)"}, nil, bc.Choice("Getting Method Types", "Do you want to try and get all types from memory? All fields and methods will be retrieved regardless.", "ℹ️"))
                if menu == nil then
                    goto menu2
                else
                    if menu == 1 then
                        if Il2Cpp.followTypePointers == true then
                            if Il2Cpp.arch.x64 then
                                Il2Cpp.getMethodTypes()
                            else
                                Il2Cpp.getTypes27()
                                Il2Cpp.getMethodTypes()
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
                    if menu == 2 then
                        Il2Cpp.getMethodTypes()
                    end
                end

                Il2Cpp.scan()
                bc.Alert("Dump Complete", "The dump has been saved to your Download folder.", "ℹ️")
            end
        end
    end
}
pluginManager.returnHome = false
pluginManager.returnPluginTable = "bcpp_dumper"
bcpp_dumper.home()
