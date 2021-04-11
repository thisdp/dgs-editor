defaultLanguage = "en-us"
dgsEditorSettings = {
	UsingLanguage = defaultLanguage,
}

function loadEditorSettings()
	local settings = {}
	if fileExists("settings.lua") then
		local f = fileOpen("settings.lua")
		local str = fileRead(f,fileGetSize(f))
		fileClose(f)
		local fnc,err = loadstring("return "..str)
		assert(fnc,"Failed to load string file: "..(err or ""))
		settings = fnc()
		fileDelete("settings.lua")
	end
	local newSettingTable = table.integrate(dgsEditorSettings,settings)
	local f = fileCreate("settings.lua")
	fileWrite(f,inspect(newSettingTable))
	fileClose(f)
	dgsEditorSettings = newSettingTable
end

function setEditorSetting(key,value)
	dgsEditorSettings[key] = value
	fileDelete("settings.lua")
	local f = fileCreate("settings.lua")
	fileWrite(f,inspect(dgsEditorSettings))
	fileClose(f)
end
