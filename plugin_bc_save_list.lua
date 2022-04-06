saveListManager = {
    list = {},
    --[[
	---------------------------------------
	
	saveListManager.home()
	
	---------------------------------------
	]] --
    home = function()
        local mainMenu = gg.choice({"➕ Add items in Saved Tab to Save List", 
									"☰ Load Save List to Saved Tab",
                                    "🔀 Replace current Save List with items in Saved Tab"}, 
									nil,
									script_title .. "\n\nℹ️ Save List Manager ℹ️")
        if mainMenu ~= nil then
            if mainMenu == 1 then
                for i, v in pairs(gg.getListItems()) do
                    table.insert(saveListManager.list, v)
                end
                gg.alert(script_title .. "\n\nℹ️ " .. #gg.getListItems() .. " items added to the Save List. ℹ️")
            end
            if mainMenu == 2 then
                gg.clearList()
                gg.addListItems(saveListManager.list)
                gg.alert(script_title .. "\n\nℹ️ " .. #gg.getListItems() .. " items loaded from Save List to Save Tab. ℹ️")
            end
            if mainMenu == 3 then
                local confirm = gg.choice({"✅ Yes", "❌ No"}, nil, script_title .. "\n\nℹ️ Are you sure you want to replace your current Save List? ℹ️\nThis can not be undone.")
                if confirm ~= nil then
                    if confirm == 1 then
                        saveListManager.list = gg.getListItems()
                    end
                    gg.alert(script_title .. "\n\nℹ️ Save List replaced with items in Saved Tab. ℹ️")
                end
            end
        end
    end
}

saveListManager.home()
