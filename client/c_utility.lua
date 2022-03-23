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

function fromcolor(int,useMath,relative)
	local a,r,g,b
	if useMath then
		b = int%256
		local int = (int-b)/256
		g = int%256
		local int = (int-g)/256
		r = int%256
		local int = (int-r)/256
		a = int%256
	else
		a,r,g,b = getColorFromString(format("#%.8x",int))
	end
	if relative then
		a,r,g,b = a/255,r/255,g/255,b/255
	end
	return r,g,b,a
end
------------------Color Utility
predefColors = {
	hlightN = tocolor(255,255,255,200),
	hlightH = tocolor(100,160,228,200),
	hlightC = tocolor(3,114,239,200),
}

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

function table.count(tabl)
	local cnt = 0
	for k,v in pairs(tabl) do
		cnt = cnt + 1
	end
	return cnt
end

function table.find(tab,ke,num)
	if num then
		for k,v in pairs(tab) do
			if v[num] == ke then
				return k
			end
		end
	else
		for k,v in pairs(tab) do
			if v == ke then
				return k
			end
		end
	end
	return false
end

function table.listKeys(tab)
	local key = {}
	for k,v in pairs(tab) do
		key[#key+1] = k
	end
	return key
end

function serializeTable(val,skipnewlines,depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0
	local tmp = string.rep("", depth)
	if type(val) == "table" then
		tmp = tmp.."{"
		for k, v in pairs(val) do
			tmp =  tmp..serializeTable(v, skipnewlines, depth + 1)..(k ~= #val and "," or "")
		end
		tmp = tmp..string.rep("", depth).."}"
	elseif type(val) == "number" then
		tmp = tmp..tostring(val)
	elseif type(val) == "string" then
		tmp = tmp..string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp..(val and "true" or "false")
	end
	return tmp
end
------------------SVG
outlineSVG = [[
<svg width="100" height="30">
	<rect width="100%" height="100%" style="fill-opacity:0;stroke-width:3;stroke:black;" />
</svg>
]]

function addElementOutline(element,offset)
	local offset = offset or 1
	element.size.relative = false
	local svg = dgsSVG(element.size.w+offset*2,element.size.h+offset*2,outlineSVG)
	element:dgsImage(-offset,-offset,element.size.w+offset*2,element.size.h+offset*2,svg,false)
		:setEnabled(false)
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
	{"dgs-dxedit","DGSEdit"},
	{"dgs-dxprogressbar","DGSProgressBar"},
	{"dgs-dxradiobutton","DGSRadioButton"},
	{"dgs-dxscrollbar","DGSScrollBar"},
	{"dgs-dxscrollpane","DGSScrollPane"},
	{"dgs-dxselector","DGSSelector"},
	{"dgs-dxswitchbutton","DGSSwitchButton"},
	{"dgs-dxtabpanel","DGSTabPanel"},
	{"dgs-dxwindow","DGSWindow"},
}

DGSPropertyItemNames = {
	absPos = {"x","y"},
	absSize = {"width","height"},
	alignment = {"alignX","alignY"},
	arrowColor = {"colorNormal","colorHover","colorClick"},
	arrowWidth = {"width","relative"},
	buttonLen = {"len","relative"},
	buttonSize = {"size","relative"},
	caretPos = {"index","line"},
	caretWidth = {"caretWidth","caretDefaultWidth","relative"},
	clickOffset = {"offsetX","offsetY"},
	color = {"colorNormal","colorHover","colorClick"},
	colorChecked = {"colorNormal","colorHover","colorClick"},
	colorIndeterminate = {"colorNormal","colorHover","colorClick"},
	colorOff = {"colorNormal","colorHover","colorClick"},
	colorOn = {"colorNormal","colorHover","colorClick"},
	colorUnchecked = {"colorNormal","colorHover","colorClick"},
	columnShadow = {"offsetX","offsetY","color","outline"},
	columnTextPosOffset = {"offsetX","offsetY"},
	columnTextSize = {"scaleX","scaleY"},
	cursorColor = {"colorNormal","colorHover","colorClick"},
	cursorLength = {"length","relative"},
	cursorWidth = {"width","relative"},
	defaultSortFunctions = {"lowerSortFunction","upperSortFunction"},
	defaultSortIcons = {"iconA","iconB"},
	iconOffset = {"offsetX","offsetY"},
	iconSize = {"scaleX","scaleY","relative"},
	image = {"normalImage","hoveringImage","clickedImage"},
	imageChecked = {"imageNormal","imageHover","imageClick"},
	imageIndeterminate = {"imageNormal","imageHover","imageClick"},
	imageRotation = {"horizontal", "vertical"},
	imageUnchecked = {"imageNormal","imageHover","imageClick"},
	indicatorColor = {"progressed","unprogressed"},
	itemAlignment = {"alignX","alignY"},
	itemColor = {"colorNormal","colorHover","colorSelected"},
	itemTextPadding = {"paddingX","paddingY"},
	itemTextSize = {"scaleX","scaleY"},
	length = {"length","relative"},
	map = {"mapMin","mapMax"},
	maxSize = {"width","height"},
	minSize = {"width","height"},
	mouseSelectButton = {"canLeftButton","canMiddleButton","canRightButton"},
	moveHardness = {"scrollHardness","dragHardness"},
	multiplier = {"multiplier","relative"},
	padding = {"horizontal", "vertical"},
	placeHolderOffset = {"offsetX","offsetY"},
	relative = {"relativePos","relativeSize"},
	rltPos = {"x","y"},
	rltSize = {"width","height"},
	rotationCenter = {"offsetX","offsetY","relative"},
	rowColor = {"colorNormal","colorHover","colorClick"},
	rowShadow = {"offsetX","offsetY","color","outline"},
	rowTextColor = {"colorNormal","colorHover","colorClick"},
	rowTextPosOffset = {"offsetX","offsetY"},
	rowTextSize = {"scaleX","scaleY"},
	scrollBarLength = {
		{"vertical","length","relative"},
		{"horizontal","length","relative"},
	},
	scrollBarState = {"vertical","horizontal"},
	scrollSpeed = {"speed","relative"},
	selectorImageColorLeft = {"colorNormal","colorHover","colorClick"},
	selectorImageColorRight = {"colorNormal","colorHover","colorClick"},
	selectorSize = {"sizeX","sizeY","relative"},
	selectorText = {"selectorTextLeft","selectorTextRight"},
	selectorTextColor = {"colorNormal","colorHover","colorClick"},
	selectorTextSize = {"scaleX","scaleY"},
	shadow = {"offsetX","offsetY","color","outline"},
	tabGapSize = {"size","relative"},
	tabHeight = {"height","relative"},
	tabMaxWidth = {"width","relative"},
	tabMinWidth = {"width","relative"},
	tabOffset = {"offset","relative"},
	tabPadding = {"padding","relative"},
	textOffset = {"offsetX","offsetY","relative"},
	textPadding = {"padding","relative"},
	textSize = {"scaleX","scaleY"},
	troughColor = {"troughColorPart1","troughColorPart2"},
	troughWidth = {"width","relative"},
	UVPos = {"UPos","VPos","relative"},
	UVSize = {"USize","VSize","relative"},
}

fonts = {"default","default-bold","clear","arial","sans","pricedown","bankgothic","diploma","beckett"}

alignments = {
	alignX = {"left","center","right"},
	alignY = {"top","center","bottom"},
}
