addEvent("onDGSEditorExport",true)
addEvent("onDGSEditorImport",true)

function onDGSEditorExport()

end

function onDGSEditorImport(fileName)
	if fileExists(fileName) then
		local file = fileOpen(fileName)
		local str = fileRead(file,fileGetSie(file))
		fileClose(file)
		triggerClientEvent(client,"onClientDGSEditorImport",client,str)
	end
end
addEventHandler("onDGSEditorImport",root,onDGSEditorImport)