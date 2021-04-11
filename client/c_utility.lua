dgsEditorContext = {}	--Stores DGS editor context
sW,sH = guiGetScreenSize()

----Locate DGS Resource
function locateDGSResource(dgsResName)
	if dgsEditorContext.dgsResource then return end	--If DGS is already started, just skip
	local dgsResName = type(dgsResName) == "string" and dgsResName or root:getData("DGS-ResName")	--Get DGS resource name from element data if dgs started
	if not dgsResName or not Resource.getFromName(dgsResName) or Resource.getFromName(dgsResName):getState() ~= "running" then	--Find resource
		dgsEditorMakeOutput(translateText({"DGSIsNotRun"}),"red")	--No Running DGS Detected
		return false
	end
	dgsEditorMakeOutput(translateText({"DGSIsRun"}),"green")	--Detected Running DGS
	--Save the context
	dgsEditorContext.dgsResourceName = dgsResName
	dgsEditorContext.dgsResource = Resource.getFromName(dgsResName)
	dgsEditorContext.state = "available"
	
	addEventHandler("onClientResourceStop",dgsEditorContext.dgsResource:getRootElement(),function()	--When DGS stopped, gives message and disable editor
		if dgsEditorContext.state ~= "disabled" then
			dgsEditorMakeOutput(translateText({"DGSStop"}),"red")	--DGS Stops
			triggerEvent("onClientDGSEditorRequestStateChange",resourceRoot,"disabled",true)					--Disable Editor (Forcely)
			--Removes context
			dgsEditorContext.dgsResourceName = nil
			dgsEditorContext.dgsResource = nil
			dgsEditorContext.state = "disabled"	--Set state to "disabled"
		end
	end)
end

addEventHandler("onClientElementDataChange",root,function(key,value)	--When DGS starts, "DGS-ResName" will be set
	if key == "DGS-ResName" then
		locateDGSResource()
	end
end)

addEvent("onDgsStart",true)
addEventHandler("onDgsStart",root,locateDGSResource)	--When DGS starts, locate DGS resource
addEventHandler("onClientResourceStart",resourceRoot,locateDGSResource)	--When this resource starts, locate DGS resource

------------------Utility
--Level: white/green/yellow/red
function dgsEditorMakeOutput(text,level,isDebugMessage)
	local r,g,b = 255,255,255
	if level == "green" then
		r,b = 0,0
	elseif level == "yellow" then
		b = 0
	elseif level == "red" then
		g,b = 0,0
	end
	if isDebugMessage then
		outputDebugString("[DGS-E]"..text,4,r,g,b)
	else
		outputChatBox("[DGS-E]"..text,r,g,b,true)
	end
end


------------------Table
--t1<--t2
function table.deepcopy(obj)
    local InTable = {}
    local function Func(obj)
        if type(obj) ~= "table" then
            return obj
        end
        local NewTable = {}
        InTable[obj] = NewTable
        for k,v in pairs(obj) do
            NewTable[Func(k)] = Func(v)
        end
        return setmetatable(NewTable,getmetatable(obj))
    end
    return Func(obj)
end

function table.integrate(t1,t2)
	local newTable = table.deepcopy(t1)
	for k,v in pairs(t2) do
		if type(newTable[k]) ~= type(t2[k]) then
			newTable[k] = t2[k]
		elseif type(v) == "table" then
			newTable[k] = table.integrate(newTable[k],t2[k])
		else
			newTable[k] = t2[k]
		end
	end
	return newTable
end

------------------Events

addEvent("onClientDGSEditorRequestStateChange",true)	--When DGS editor's state changes (available or disabled)
addEvent("onClientDGSEditorStateChanged",true)	--When DGS editor's state changes (available or disabled)

------------------Storage
DGSTypeReference = {
	{"dgs-dxbutton","DGSButton"},
	{"dgs-dxcheckbox","DGSCheckBox"},
	{"dgs-dxcombobox","DGSComboBox"},
	{"dgs-dxgridlist","DGSGridList"},
	{"dgs-dximage","DGSImage"},
	{"dgs-dxlabel","DGSLabel"},
	{"dgs-dxmemo","DGSMemo"},
	{"dgs-dxprogressbar","DGSProgressBar"},
	{"dgs-dxradiobutton","DGSRadioButton"},
	{"dgs-dxscrollbar","DGSScrollBar"},
	{"dgs-dxscrollpane","DGSScrollPane"},
	{"dgs-dxselector","DGSSelector"},
	{"dgs-dxswitchbutton","DGSSwitchButton"},
	{"dgs-dxtabpanel","DGSTabPanel"},
	{"dgs-dxwindow","DGSWindow"},
}