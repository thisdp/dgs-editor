Language = {
	Files = {
		"en-us",
		"zh-cn",
	},
	Loaded = {},
	UsingLanguageTable = false,
}

function checkLanguages()	--Check all languages
	for i=1,#Language.Files do
		local languageFile = "languages/"..Language.Files[i]..".lang"
		if fileExists(languageFile) then
			local f = fileOpen(languageFile)
			local str = fileRead(f,fileGetSize(f))
			fileClose(f)
			local fnc,err = loadstring("return { "..str.." }")
			if fnc then
				dgsEditorMakeOutput("Language file: "..languageFile.." was loaded","green",true)
				Language.Loaded[ Language.Files[i] ] = fnc()
				if Language.Files[i] == defaultLanguage then
					Language.UsingLanguageTable = Language.Loaded[ Language.Files[i] ]
				end
			else
				dgsEditorMakeOutput("Failed to load language file: "..languageFile.." : "..err,"yellow",true)
			end
		else
			dgsEditorMakeOutput("Missing language file: "..languageFile,"yellow",true)
		end
	end
	if not Language.UsingLanguageTable then
		outputChatBox("Error: can not load default language!",255,0,0)
		error("Error: can not load default language!")
	end
end

function setCurrentLanguage(lang)
	if Language.Loaded[lang] then
		Language.UsingLanguageTable = Language.Loaded[lang]	--Change the global translation dictionary
		dgsEditorSettings.UsingLanguage = lang	--Change the using language
		dgsEditorMakeOutput(translateText({"ChgLang",{"LanguageDetail"},lang}),"green")	--Successfully to change language
		if dgsEditorContext.state == "available" then	--Only when dgs editor is available
			dgsRootInstance:setTranslationTable("DGSEditorLanguage",Language.UsingLanguageTable)	--Set translation dictionary whenever a new language applies
			dgsRootInstance:setAttachTranslation("DGSEditorLanguage")	--Use this dictionary
		end
	else
		dgsEditorMakeOutput(translateText({"FailToChgLang",lang}),"yellow")	--Failed to change language
	end
end


-----------------Translation
function translateText(textTable)
	if type(textTable) == "table" then
		local value = Language.UsingLanguageTable[textTable[1]] or textTable[1]
		local count = 2
		while true do
			local textArg = textTable[count]
			if not textArg then break end
			if type(textArg) == "table" then
				textArg = translateText(textArg)
			end
			local _value = value:gsub("%%rep%%",textArg,1)
			if _value == value then break end
			count = count+1
			value = _value
		end
		value = value:gsub("%%rep%%","")
		return value
	end
	return false
end