--[[
	Full Name:	Editor for thisdp's graphical user interface system
	Short Name: DGS Editor
	Language:	Lua
	Platform:	MTASA
	Author:		YappiDoor, thisdp
	License: 	DPL v1 (The same as DGS)
	State:		OpenSourced
	Note:		This script uses the OOP syntax of DGS
]]

dgsEditor = {}
historyActionState = 0 -- state history
dgsEditor.ActionHistory = {
	Undo = {},
	Redo = {}
}
dgsEditor.Action = {}
dgsEditor.ActionFunctions = {
    destroy = function(action)
		local element = unpack(action.arguments)
		if element then
			return dgsEditorDestroyElement(element)
		end
    end,
    show = function(action)
		local element = unpack(action.arguments)
		if element then
			element.visible = true
			element.isCreatedByEditor = true
			if element.children then
				for _, child in pairs(element.children) do
					--if it is not an internal element
					if child.isCreatedByEditor then
						child.isCreatedByEditor = true
					end
				end
			end
			return true
		end
    end,
	cancelProperty = function(action)
		local element,property,newValue,oldValue = unpack(action.arguments)
		element[property] = oldValue
		local tempPropertyList = element.dgsEditorPropertyList
		if not tempPropertyList then tempPropertyList = {} end
		tempPropertyList[property] = oldValue
		element.dgsEditorPropertyList = tempPropertyList
		dgsEditorPropertiesMenuDetach()
		dgsEditorPropertiesMenuAttach(element)
		return true
	end,
	returnProperty = function(action)
		local element,property,newValue,oldValue = unpack(action.arguments)
		element[property] = newValue
		local tempPropertyList = element.dgsEditorPropertyList
		if not tempPropertyList then tempPropertyList = {} end
		tempPropertyList[property] = newValue
		element.dgsEditorPropertyList = tempPropertyList
		dgsEditorPropertiesMenuDetach()
		dgsEditorPropertiesMenuAttach(element)
		return true
	end,
}
setmetatable(dgsEditor.Action,{__index = function(self, theIndex)
    return setmetatable({action=theIndex},{ __call = function(self,...)
        self.arguments = {...}
        self.result = {dgsEditor.ActionFunctions[self.action](self)}
        return self
    end})
end})

----------------State Switch
function dgsEditorSwitchState(state)
	--If someone want to enable dgs editor
	if state == "enabled" then
		if dgsEditorContext.state == "available" then --First, state need to be "available"
			dgsEditor.state = "enabled"	--Enabled
			dgsEditorMakeOutput(translateText({"EditorEnabled"}))
			if not dgsEditor.Created then
				loadstring(exports[dgsEditorContext.dgsResourceName]:dgsImportOOPClass())()
				dgsRootInstance:setElementKeeperEnabled(true)
				--Set translation dictionary whenever a new language applies
				dgsRootInstance:setTranslationTable("DGSEditorLanguage",Language.UsingLanguageTable)
				--Use this dictionary
				dgsRootInstance:setAttachTranslation("DGSEditorLanguage")
				dgsEditorCreateMainPanel()
			else
				dgsEditor.BackGround.visible = true
			end
			showCursor(true)
			triggerEvent("onClientDGSEditorStateChanged",resourceRoot,dgsEditor.state)
		end
	elseif state == "disabled" then		--If someone want to disable dgs editor
		--Just disable
		dgsEditor.state = "disabled"
		dgsEditorMakeOutput(translateText({"EditorDisabled"}))
		dgsEditor.BackGround.visible = false
		for _, menu in pairs(dgsEditor.Menus) do
			dgsSetVisible(menu,false)
		end
		showCursor(false)
		triggerEvent("onClientDGSEditorStateChanged",resourceRoot,dgsEditor.state)
	end
end
addEventHandler("onClientDGSEditorRequestStateChange",root,dgsEditorSwitchState)

--Alt + D
bindKey("d","down",function()
	if getKeyState("lalt") then
		triggerEvent("onClientDGSEditorRequestStateChange",resourceRoot,dgsEditor.state == "enabled" and "disabled" or "enabled")
	end
end)

----------------Main Panel
function dgsEditorCreateMainPanel()
	--Used to store created elements createed by user
	dgsEditor.ElementList = {}
	dgsEditor.Created = true
	--Main Background
	dgsEditor.BackGround = dgsImage(0,0,1,1,_,true,tocolor(0,0,0,100))
	--Main Canvas
	dgsEditor.Canvas = dgsEditor.BackGround:dgsScalePane(0.2,0.2,0.6,0.6,true,sW,sH)
		:on("dgsDrop",function(data)
			local cursorX,cursorY = dgsRootInstance:getCursorPosition(source)
			dgsEditorCreateElement(data,cursorX,cursorY)
		end)
	dgsEditor.Canvas.bgColor = tocolor(0,0,0,128)
	--Widgets Window
	dgsEditor.WidgetMain = dgsEditor.BackGround:dgsWindow(0,0,270,0.5*sH,{"DGSWidgets"},false)
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setMovable(false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = tocolor(0,0,0,128),
			titleColor = tocolor(0,0,0,128),
			textSize = {1.3,1.3},
		})
	--The Vertical Spliter Line
	dgsEditor.WidgetSpliter = dgsEditor.WidgetMain
		:dgsImage(100,0,5,0.5*sH-25,_,false,tocolor(50,50,50,200))
	--Type List
	dgsEditor.WidgetTypeList = dgsEditor.WidgetMain
		:dgsGridList(0,0,100,200,false)
		:setProperties({
			rowHeight = 30,
			columnHeight = 0,
			rowTextSize = {1.2,1.2},
			scrollBarThick = 10,
			bgColor = tocolor(0,0,0,0),
			sortEnabled = false,
		})
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 and rNew == -1 then
				source:setSelectedItem(rOld)
			end
			if rNew ~= -1 then
				local row = source:getSelectedItem()
				if row == 1 then
					dgsEditor.WidgetList.visible = true
					--dgsEditor.PluginList.visible = false
					dgsEditor.Languages.visible = false
				elseif row == 2 then
					dgsEditor.WidgetList.visible = false
					--dgsEditor.PluginList.visible = true
					dgsEditor.Languages.visible = false
				elseif row == 3 then
					dgsEditor.WidgetList.visible = false
					--dgsEditor.PluginList.visible = false
					dgsEditor.Languages.visible = true
				end
			end
		end)
	dgsEditor.WidgetTypeList:addColumn("",0.9)
	dgsEditor.WidgetTypeList:addRow(_,{"Basic"})
	dgsEditor.WidgetTypeList:addRow(_,{"Plugins"})
	dgsEditor.WidgetTypeList:addRow(_,{"Languages"})
	--Widget List
	dgsEditor.WidgetList = dgsEditor.WidgetMain
		:dgsGridList(105,0,165,0.5*sH-25,false)
		:setProperties({
			rowHeight = 30,
			columnHeight = 0,
			rowTextSize = {1.2,1.2},
			scrollBarThick = 10,
			bgColor = tocolor(0,0,0,0),
			sortEnabled = false,
		})
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 and rNew == -1 then
				source:setSelectedItem(rOld)
			end
		end)
		:on("dgsGridListItemDoubleClick",function(button,state,row)
			if button == "left" and state == "down" then
				if row and row ~= -1 then
					local widgetID = source:getItemData(row,1)
					dgsEditorCreateElement(DGSTypeReference[widgetID][1])
				end
			end
		end)
		:on("dgsDrag",function()
			local selectedItem = source:getSelectedItem()
			if selectedItem ~= -1 then
				local widgetID = source:getItemData(selectedItem,1)
				local widgetIcon = source:getItemImage(selectedItem,1)
				source:sendDragNDropData(DGSTypeReference[widgetID][1],widgetIcon)
			end
		end)
	
	dgsEditor.WidgetList:addColumn(_,0.2)	--Icon
	dgsEditor.WidgetList:addColumn(_,0.7)	--Namne
	for i=1,#DGSTypeReference do
		local row = dgsEditor.WidgetList:addRow(_,_,{DGSTypeReference[i][2]})
		local texture = DxTexture("icons/"..DGSTypeReference[i][2]..".png")
		dgsRootInstance:attachToAutoDestroy(texture,dgsEditor.WidgetList)
		dgsEditor.WidgetList:setItemImage(row,1,texture)
		dgsEditor.WidgetList:setItemData(row,1,i)
	end
	--[[
	--PluginList List
	dgsEditor.PluginList = dgsEditor.WidgetMain
		:dgsGridList(105,0,165,0.5*sH-25,false)
		:setProperties({
			rowHeight = 30,
			columnHeight = 0,
			rowTextSize = {1.2,1.2},
			bgColor = tocolor(0,0,0,0)
		})
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 and rNew == -1 then
				source:setSelectedItem(rOld)
			end
		end)
		:on("dgsGridListItemDoubleClick",function(button,state,row)
			if button == "left" and state == "down" then
				-- todo
			end
		end)
	dgsEditor.WidgetList:addColumn(_,0.2)
	dgsEditor.WidgetList:addColumn(_,0.7)
	for i=1,#DGSTypeReference do
		dgsEditor.WidgetList:addRow(_,_,{DGSTypeReference[i][2]})
	end
	
	dgsEditor.PluginList.visible = false]]

	--Languages settings
	dgsEditor.Languages = dgsEditor.WidgetMain
		:dgsGridList(105,0,165,0.5*sH-25,false)
		:setProperties({
			rowHeight = 30,
			columnHeight = 0,
			rowTextSize = {1.2,1.2},
			bgColor = tocolor(0,0,0,0)
		})
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 and rNew == -1 then
				source:setSelectedItem(rOld)
				return
			end
			if rNew ~= -1 then
				local lang = source:getItemData(rNew,1)
				setEditorSetting("UsingLanguage",lang)
				setCurrentLanguage(lang)
			end
		end)
	dgsEditor.Languages:addColumn(_,1)
	for i, lang in pairs(Language.Loaded) do
		local row = dgsEditor.Languages:addRow(_,lang.LanguageDetail)
		dgsEditor.Languages:setItemData(row,1,i)
	end

	dgsEditor.Languages.visible = false

	--Properties Main
	dgsEditor.WidgetPropertiesMain  = dgsEditor.BackGround:dgsWindow(sW-350,0,350,0.5*sH,{"DGSProperties"},false)
		:setCloseButtonEnabled(false)
		:setMovable(false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = tocolor(0,0,0,128),
			titleColor = tocolor(0,0,0,128),
			textSize = {1.3,1.3},
			minSize = {350,0.5*sH},
			maxSize = {350,sH},
			borderSize = 10,
		})
	--Properties List
	dgsEditor.WidgetPropertiesMenu = dgsEditor.WidgetPropertiesMain
		:dgsScrollPane(0,0,350,0.5*sH-dgsEditor.WidgetPropertiesMain.titleHeight-dgsEditor.WidgetPropertiesMain.borderSize,false)
		:setProperties({
			rowHeight = 30,
			scrollBarState = {nil,false},
			bgColor = tocolor(30,32,35,255),
		})
	
	--Resize scroll pane
	dgsEditor.WidgetPropertiesMain:on("dgsSizeChange",function()
		local w,h = source:getSize()
		dgsEditor.WidgetPropertiesMenu:setSize(w,h-source.titleHeight-source.borderSize)
	end)
	
	dgsEditor.Controller = dgsEditorCreateController(dgsEditor.Canvas)
	--Menu list
	dgsEditor.Menus = {}
	table.insert(dgsEditor.Menus,dgsEditorCreateColorPicker())
	table.insert(dgsEditor.Menus,dgsEditorCreateGridListDataMenu())
	table.insert(dgsEditor.Menus,dgsEditorCreateTexturesMenu())
	table.insert(dgsEditor.Menus,dgsEditorCreateGenerateCode())

	--Buttons show menu
	for i, name in pairs(DGSEditorMenuReference) do
		local texture = DxTexture("icons/"..name[1]..".png")
		local btn = dgsEditor.BackGround:dgsButton(40*(i-1)+10*i,sH-50,40,40,"",false)
			:setProperties({
				iconImage = texture,
				iconSize = {30,30,false},
				iconOffset = {15,0}
			})
			:on("dgsMouseClickDown",function()
				dgsEditor[name[2]].visible = not dgsEditor[name[2]].visible
				dgsEditor[name[2]]:bringToFront()
			end)
		dgsRootInstance:attachToAutoDestroy(texture,btn)
	end
end

----------------Element management
function dgsEditorCreateElement(...)
	local args = {...}
--	if #arguments == 0 then
	local createdElement
	local dgsType,x,y = unpack(args)
	if dgsType == "dgs-dxbutton" then
		createdElement = dgsEditor.Canvas:dgsButton(0,0,80,30,"Button",false)
	elseif dgsType == "dgs-dximage" then
		createdElement = dgsEditor.Canvas:dgsImage(0,0,80,80,_,false)
	elseif dgsType == "dgs-dxcheckbox" then
		createdElement = dgsEditor.Canvas:dgsCheckBox(0,0,80,30,"Check Box",false,false)
	elseif dgsType == "dgs-dxradiobutton" then
		createdElement = dgsEditor.Canvas:dgsRadioButton(0,0,80,30,"Radio Button",false)
	elseif dgsType == "dgs-dxedit" then
		createdElement = dgsEditor.Canvas:dgsEdit(0,0,100,30,"Edit",false)
	elseif dgsType == "dgs-dxgridlist" then
		createdElement = dgsEditor.Canvas:dgsGridList(0,0,100,100,false)
		--test data
		--[[
		createdElement:addColumn("c1",0.5)
		createdElement:addColumn("c2",0.5)
		createdElement:addRow(_,"c1r1","c2r1")
		createdElement:addRow(_,"c1r2","c2r2")
		--]]
	elseif dgsType == "dgs-dxscrollpane" then
		createdElement = dgsEditor.Canvas:dgsScrollPane(0,0,100,100,false)
	elseif dgsType == "dgs-dxcombobox" then
		createdElement = dgsEditor.Canvas:dgsComboBox(0,0,100,30,false)
	elseif dgsType == "dgs-dxmemo" then
		createdElement = dgsEditor.Canvas:dgsMemo(0,0,100,60,"Memo",false)
	elseif dgsType == "dgs-dxprogressbar" then
		createdElement = dgsEditor.Canvas:dgsProgressBar(0,0,100,30,false)
	elseif dgsType == "dgs-dxlabel" then
		createdElement = dgsEditor.Canvas:dgsLabel(0,0,50,30,"Label",false)
	elseif dgsType == "dgs-dxscrollbar" then
		createdElement = dgsEditor.Canvas:dgsScrollBar(0,0,20,150,false,false)
	elseif dgsType == "dgs-dxswitchbutton" then
		createdElement = dgsEditor.Canvas:dgsSwitchButton(0,0,80,20,"On","Off",false)
	elseif dgsType == "dgs-dxselector" then
		createdElement = dgsEditor.Canvas:dgsSelector(0,0,80,20,false)
	elseif dgsType == "dgs-dxwindow" then
		createdElement = dgsEditor.Canvas:dgsWindow(0,0,100,100,"window",false)
			:setMovable(false)
			:setSizable(false)
	elseif dgsType == "dgs-dxtabpanel" then
		createdElement = dgsEditor.Canvas:dgsTabPanel(0,0,100,100,false)
	end
	if x and y then createdElement:setPosition(x,y,false,true) end
	createdElement.isCreatedByEditor = true
	createdElement.childOutsideHit = true
	--When clicking the element
	createdElement:on("dgsMouseClickDown",function(button,state)
		--Make the 8 circle controller always front
		for i=1,#dgsEditor.Controller.controller do
			dgsGetInstance(dgsEditor.Controller.controller[i]):bringToFront()
		end
		if button == "left" then
			if dgsEditor.Controller.FindParent then
				--Set the parent to the element
				local c = dgsGetInstance(dgsEditor.Controller.BoundChild)
				if c == createdElement then return end
				c:setParent(createdElement)
				c.position.relative = dgsEditor.Controller.position.relative
				c.position = {0,0}
				c.size.relative = dgsEditor.Controller.size.relative
				c.size = dgsEditor.Controller.size
				dgsEditor.Controller.FindParent = nil
				dgsEditorPropertiesMenuDetach()
				dgsEditorControllerAttach(c)
			else
				--Don't attach if the element is already attached
				if dgsEditor.Controller.BoundChild and dgsEditor.Controller.BoundChild == createdElement.dgsElement then
					return
				end
				--Just click
				dgsEditorControllerDetach()
				--When clicked the element, turn it into "operating element"
				dgsEditor.Controller.visible = true	--Make the controller visible
				dgsEditorControllerAttach(createdElement)
			end
		end
	end)
	--Record the element
	dgsEditor.ElementList[createdElement.dgsElement] = createdElement
	--Add action
	saveAction("destroy",{createdElement})
	return createdElement
end

----------------Controller attach/detach
function dgsEditorControllerAttach(targetElement)
	--Save position/size
	local pos,size = targetElement.position,targetElement.size
	--Record the parent element of operating element
	dgsEditor.Controller.BoundParent = targetElement:getParent().dgsElement
	--Record the operating element as the child element of controller (to proxy the positioning and resizing of operating element with controller)
	dgsEditor.Controller.BoundChild = targetElement.dgsElement
	--Set the parent element
	dgsEditor.Controller:setParent(targetElement:getParent())
	--Set the child element
	targetElement:setParent(dgsEditor.Controller)
	--Use operating element's position
	dgsEditor.Controller.position = pos
	--Use operating element's size
	dgsEditor.Controller.size = size
	--Make operating element fullscreen to the controller
	targetElement.position.relative = true
	targetElement.position.x = 0
	targetElement.position.y = 0
	targetElement.size.relative = true
	targetElement.size.w = 1
	targetElement.size.h = 1
	--Make the 8 circle controller always front
	for i=1,#dgsEditor.Controller.controller do
		dgsGetInstance(dgsEditor.Controller.controller[i]):bringToFront()
	end
	dgsEditorPropertiesMenuAttach(targetElement)
end

function dgsEditorControllerDetach()
	--Remove find parent
	dgsEditor.Controller.FindParent = nil
	--Get the instance of parent (controller's & operating element's)
	local p = dgsGetInstance(dgsEditor.Controller.BoundParent)
	--If the operating element exists
	if dgsEditor.Controller.BoundChild then
		--Get the instance of child (controller's) [the operating element]
		local c = dgsGetInstance(dgsEditor.Controller.BoundChild)
		dgsEditor.Controller.BoundChild = nil
		--Use the position/size/parent of the controller
		c:setParent(p)
		c.position.relative = dgsEditor.Controller.position.relative
		c.position = dgsEditor.Controller.position
		c.size.relative = dgsEditor.Controller.size.relative
		c.size = dgsEditor.Controller.size
	end
	dgsEditorPropertiesMenuDetach()
end

----------------Controller Create Function
local ctrlSize = 10
function dgsEditorCreateController(theCanvas)
	--Declear the 8 controlling circles
	local RightCenter,RightTop,CenterTop,LeftTop,LeftCenter,LeftBottom,CenterBottom,RightBottom	
	local Ring = dgsCreateCircle(0.45,0.3,360)	--circles
	dgsCircleSetColorOverwritten(Ring,false)
	local Line = theCanvas:dgsLine(0,0,0,0,false,2,tocolor(255,0,0,255))	--the highlight line (controller)
		:setProperties({
			childOutsideHit = true,
			isController = true,
		})
	--When clicking the element
	addEventHandler("onDgsMouseClickDown",root,function(button,state,mx,my)
		--Check whether the clicked element is handled by the controller
		if dgsGetInstance(source) == dgsGetInstance(dgsEditor.Controller.BoundChild) then
			--Save the position, size and mouse position
			dgsEditor.Controller.startDGSPos = Vector2(dgsEditor.Controller:getPosition(false))
			dgsEditor.Controller.startDGSSize = Vector2(dgsEditor.Controller:getSize(false))
			dgsEditor.Controller.startMousePos = Vector2(mx,my)
		end
	end)
	--When attempt to moving the element
	addEventHandler("onDgsMouseDrag",root,function(mx,my)
		--Check whether the clicked element is handled by the controller
		if dgsGetInstance(source) == dgsGetInstance(dgsEditor.Controller.BoundChild) then
			--Is the element is able to move?
			if dgsEditor.Controller.startMousePos then
				--Move
				local pRlt = dgsEditor.Controller.position.rlt
				local mPos = Vector2(mx,my)
				dgsEditor.Controller.position = Vector2(mx,my)-(dgsEditor.Controller.startMousePos-dgsEditor.Controller.startDGSPos)
			end
		end
	end)
	--Draw 4 lines
	Line:addItem(0,0,1,0,_,_,true)
	Line:addItem(1,0,1,1,_,_,true)
	Line:addItem(1,1,0,1,_,_,true)
	Line:addItem(0,1,0,0,_,_,true)
	--8 circles controller creating and resizing function
	local RightCenter = Line:dgsButton(-ctrlSize/2,0,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("right","center")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.size = Vector2(-source.parent.startMousePos.x+mPos.x+source.parent.startDGSSize.x,source.parent.startDGSSize.y)
			end
		end)
	local CenterTop = Line:dgsButton(0,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("center","top")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.position = Vector2(source.parent.startDGSPos.x,mPos.y-(source.parent.startMousePos.y-source.parent.startDGSPos.y))
				source.parent.size = Vector2(source.parent.startDGSSize.x,source.parent.startMousePos.y-mPos.y+source.parent.startDGSSize.y)
			end
		end)
	local LeftTop = Line:dgsButton(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("left","top")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.position = mPos-(source.parent.startMousePos-source.parent.startDGSPos)
				source.parent.size = (source.parent.startMousePos-mPos+source.parent.startDGSSize)
			end
		end)
	local LeftCenter = Line:dgsButton(-ctrlSize/2,0,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("left","center")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.position = Vector2(mPos.x-(source.parent.startMousePos.x-source.parent.startDGSPos.x),source.parent.startDGSPos.y)
				source.parent.size = Vector2(source.parent.startMousePos.x-mPos.x+source.parent.startDGSSize.x,source.parent.startDGSSize.y)
			end
		end)
	local LeftBottom = Line:dgsButton(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("left","bottom")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.position = Vector2(mPos.x-(source.parent.startMousePos.x-source.parent.startDGSPos.x),source.parent.startDGSPos.y)
				source.parent.size = ((source.parent.startMousePos-mPos)*Vector2(1,-1)+source.parent.startDGSSize)
			end
		end)
	local CenterBottom = Line:dgsButton(0,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("center","bottom")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local mPos = Vector2(mx,my)
				source.parent.size = Vector2(source.parent.startDGSSize.x,-source.parent.startMousePos.y+mPos.y+source.parent.startDGSSize.y)
			end
		end)
	local RightBottom = Line:dgsButton(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("right","bottom")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.size = ((source.parent.startMousePos-mPos)*Vector2(-1,-1)+source.parent.startDGSSize)
			end
		end)
	local RightTop = Line:dgsButton(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,"",false)
		:setPositionAlignment("right","top")
		:on("dgsMouseClickDown",function(button,state,mx,my)
			source.parent.startDGSPos = Vector2(source.parent:getPosition(false))
			source.parent.startDGSSize = Vector2(source.parent:getSize(false))
			source.parent.startMousePos = Vector2(mx,my)
		end)
		:on("dgsMouseDrag",function(mx,my)
			if source.parent.startMousePos then
				local pRlt = source.parent.position.rlt
				local sRlt = source.parent.size.rlt
				local mPos = Vector2(mx,my)
				source.parent.position = Vector2(source.parent.startDGSPos.x,mPos.y-(source.parent.startMousePos.y-source.parent.startDGSPos.y))
				source.parent.size = ((source.parent.startMousePos-mPos)*Vector2(-1,1)+source.parent.startDGSSize)
			end
		end)
	--Set property buttons
	for _, child in pairs(Line.children) do
		child:setProperties({
			image = {Ring,Ring,Ring},
			color = {predefColors.hlightN,predefColors.hlightH,predefColors.hlightC},
		})
	end
	--Record the 8 circle controller
	Line.controller = {
		RightCenter.dgsElement,
		CenterTop.dgsElement,
		LeftTop.dgsElement,
		LeftCenter.dgsElement,
		LeftBottom.dgsElement,
		CenterBottom.dgsElement,
		RightBottom.dgsElement,
		RightTop.dgsElement,
	}
	Line.visible = false
	--When clicking the canvas, hide the controller
	theCanvas:on("dgsMouseClickDown",function(button,state)
		if button == "left" then
			Line.visible = false
			dgsEditorControllerDetach()
		end
	end)
	return Line
end

----------------Table attach property
dgsEditorAttachProperty = {
	Number = function(targetElement,property,row,text,i,t)
		if property == "absPos" or property == "absSize" or property == "rltPos" or property == "rltSize" then
			targetElement = dgsEditor.Controller
		end
		local arg = targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		if i and type(arg) == "table" then arg = arg[i] end
		if not arg then arg = 0 end
		local edit = dgsEditor.WidgetPropertiesMenu:dgsEdit(0,0,150,20,arg,false)
			:on("dgsTextChange",function()
				changeProperty(targetElement,property,tonumber(source:getText()),i,t)
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end,
	Bool = function(targetElement,property,row,text,i,t)
		local arg = property == "noCloseButton" and targetElement:getCloseButtonEnabled() or targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		if i and type(arg) == "table" then arg = arg[i] end
		local edit = dgsEditor.WidgetPropertiesMenu:dgsSwitchButton(0,0,50,20,"","",arg)
			:on("dgsSwitchButtonStateChange",function(state)
				changeProperty(targetElement,property,state,i,t)
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end,
	String = function(targetElement,property,row,text,i,t)
		local arg = targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		if i and type(arg) == "table" then arg = arg[i] end
		if not arg then arg = "" end
		if property:lower():find("align") or (text and text:lower():find("align")) then
			--Align combobox
			local combobox = dgsEditor.WidgetPropertiesMenu:dgsComboBox(0,0,150,20,false)
			for i, align in pairs(alignments[text or "alignX"]) do
				combobox:addItem(align)
				if align == arg then
					combobox:setSelectedItem(i)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				changeProperty(targetElement,property,source:getItemText(row),i,t)
			end)
			attachToScrollPane(combobox,dgsEditor.WidgetPropertiesMenu,row)
		elseif property:lower():find("font") then
			--Font combobox
			local combobox = dgsEditor.WidgetPropertiesMenu:dgsComboBox(0,0,150,20,false)
			for i, font in pairs(fonts) do
				combobox:addItem(font)
				if font == arg then
					combobox:setSelectedItem(i)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				changeProperty(targetElement,property,source:getItemText(row),i,t)
			end)
			attachToScrollPane(combobox,dgsEditor.WidgetPropertiesMenu,row)
		else
			local edit = dgsEditor.WidgetPropertiesMenu:dgsEdit(0,0,150,20,arg,false)
				:on("dgsTextChange",function()
					changeProperty(targetElement,property,source:getText(),i,t)
				end)
			attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
		end
	end,
	Color = function(targetElement,property,row,text,i,t)
		local arg = targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		local text = property
		if i then
			if type(arg) == "table" then
				arg = arg[i]
			end
			if DGSPropertyItemNames[property] then
				text = DGSPropertyItemNames[property][i] or property
			end
		end
		if not arg or type(arg) == "table" then arg = 0 end
		local r,g,b,a = fromcolor(arg,true)
		local shader = dxCreateShader("client/alphaCircle.fx")
		local imgBack = dgsEditor.WidgetPropertiesMenu:dgsImage(0,0,20,20,shader,false)
		attachToScrollPane(imgBack,dgsEditor.WidgetPropertiesMenu,row)
		dgsAttachToAutoDestroy(shader,imgBack.dgsElement)
		local circleImage = dgsCreateCircle(0.48,0,360,tocolor(r,g,b,a))
		dxSetShaderValue(circleImage,"borderSoft",0.02)
		dgsAddPropertyListener(circleImage,"color")
		addEventHandler("onDgsPropertyChange",circleImage,function(key,newValue,oldValue)
			if key == "color" then
				changeProperty(targetElement,property,tocolor(fromcolor(newValue,true)),i,t)
			end
		end)
		local img = dgsEditor.WidgetPropertiesMenu
			:dgsImage(0,0,20,20,circleImage,false)
			:on("dgsMouseClickUp",function()
				dgsEditor.ColorMain.visible = true
				local x,y = dgsRootInstance:getCursorPosition()
				dgsEditor.ColorMain.position.x = x-dgsEditor.ColorMain.size.w
				dgsEditor.ColorMain.position.y = y
				dgsEditor.ColorMain:bringToFront()
				dgsEditor.ColorMain:setText(targetElement:getType()..", "..text)
				dgsEditor.ColorPicker.childImage = source:getImage()
				local r,g,b,a = fromcolor(dgsCircleGetColor(dgsEditor.ColorPicker.childImage),true)
				dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
				dgsSetProperty(dgsEditor.ColorPicker.oldImage.dgsElement,"color",tocolor(r,g,b,a))
			end)
		img:applyDetectArea(dgsEditor.DA)
		imgBack:applyDetectArea(dgsEditor.DA)
		attachToScrollPane(img,dgsEditor.WidgetPropertiesMenu,row)
	end,
	Text = function(targetElement,property,row,text,i,t)
		local arg = targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		if i and type(arg) == "table" then arg = arg[i] end
		if not arg then arg = "" end
		local edit = dgsEditor.WidgetPropertiesMenu:dgsEdit(0,0,150,20,arg,false)
			:on("dgsTextChange",function()
				changeProperty(targetElement,property,source:getText(),i,t)
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end,
	Material = function(targetElement,property,row,text,i,t)
		local arg = targetElement[property]
		if t and type(arg) == "table" then arg = arg[t] end
		if i and type(arg) == "table" then arg = arg[i] end
		if not arg then arg = "" end
		--Textures combobox
		if #dgsEditor.Textures > 0 then
			local combobox = dgsEditor.WidgetPropertiesMenu:dgsComboBox(0,0,150,20,false)
			local empty = combobox:addItem("None")
			combobox:setItemData(empty,emptyTexture)
			for i, texture in pairs(dgsEditor.Textures) do
				local textureName = unpack(dgsGetProperty(texture, "textureInfo"))
				local texture = dgsRemoteImageGetTexture(texture)
				if textureName and texture and isElement(texture) then
					local row = combobox:addItem(textureName)
					combobox:setItemData(row,texture)
					if textureName == arg then
						combobox:setSelectedItem(row)
					end
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				changeProperty(targetElement,property,source:getItemData(row),i,t)
				local row = row - 1
				if row == 0 then row = nil end
				targetElement.textureID = row
			end)
			attachToScrollPane(combobox,dgsEditor.WidgetPropertiesMenu,row)
		else
			local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(0,0,150,20,"textures",false)
				:on("dgsMouseClickUp",function()
					dgsEditor.TexturesMain.visible = true
					dgsEditor.TexturesMain:bringToFront()
				end)
			attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
		end
	end,
	add = function(targetElement,property,row,text,i,t)
		local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(0,0,150,20,"add "..property,false)
			:setProperty("alignment",{"center","center"})
			:on("dgsMouseClickUp",function()
				local values = {}
				local propertyValues = dgsGetRegisteredProperties(targetElement:getType(),true)[property]
				for a, arguments in pairs(propertyValues) do
					if type(arguments) == "table" then
						if arguments[1] == 1 then break end
						for b, args in pairs(arguments) do
							if type(args) == "table" then
								values[b] = {}
								for c, arg in pairs(args) do
									local arg = dgsListPropertyTypes(arg)
									if type(arg) == "table" then
										local check = table.find(arg,"Nil")
										if check then table.remove(arg,check) end
									end
									local arg = arg[1] or arg[2]
									local value
									if arg == "Number" then value = 0 end
									if arg == "Bool" then value = false end
									if arg == "String" then value = "" end
									if arg == "Color" then value = tocolor(0,0,0,255) end
									if arg == "Text" then value = "" end
									if arg == "Material" then value = emptyTexture end
									values[b][c] = value
								end
							else
								local arg = dgsListPropertyTypes(args)
								if type(arg) == "table" then
									local check = table.find(arg,"Nil")
									if check then table.remove(arg,check) end
								end
								local arg = arg[1] or arg[2]
								local value
								if arg == "Number" then value = 0 end
								if arg == "Bool" then value = false end
								if arg == "String" then value = "" end
								if arg == "Color" then value = tocolor(0,0,0,255) end
								if arg == "Text" then value = "" end
								if arg == "Material" then value = emptyTexture end
								values[b] = value
							end
						end
					end
				end
				changeProperty(targetElement,property,values)
				values = nil
				dgsEditorPropertiesMenuDetach()
				dgsEditorPropertiesMenuAttach(targetElement)
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end,
}

dgsEditorGridListAttachProperty = {
	Number = function(targetElement,property,row,offset,data,id,i)
		if data == nil then data = 0 end
		local edit = dgsEditor.GridListDataColumnProperty:dgsEdit(0,0,100,20,data,false)
			:on("dgsTextChange",function()
				local tempData = targetElement.columnData
				tempData[id][i] = tonumber(source:getText()) or 0
				targetElement.columnData = tempData
				dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
			end)
		attachToScrollPane(edit,dgsEditor.GridListDataColumnProperty,row)
	end,
	Bool = function(targetElement,property,row,offset,data,id,i)
		local edit = dgsEditor.GridListDataColumnProperty:dgsSwitchButton(0,0,50,20,"","",data)
			:on("dgsSwitchButtonStateChange",function(state)
				local tempData = targetElement.columnData
				tempData[id][i] = state
				targetElement.columnData = tempData
				dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
			end)
		attachToScrollPane(edit,dgsEditor.GridListDataColumnProperty,row)
	end,
	String = function(targetElement,property,row,offset,data,id,i)
		if property:lower():find("align") then
			--Align combobox
			if data == nil then data = "" end
			local combobox = dgsEditor.GridListDataColumnProperty:dgsComboBox(0,0,100,20,false)
			for i, align in pairs(alignments[text or "alignX"]) do
				combobox:addItem(align)
				if align == data then
					combobox:setSelectedItem(i)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				local tempData = targetElement.columnData
				tempData[id][i] = source:getItemText(row)
				targetElement.columnData = tempData
				dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
			end)
			attachToScrollPane(combobox,dgsEditor.GridListDataColumnProperty,row)
		elseif property:lower():find("font") then
			--Font combobox
			if data == nil then data = "default" end
			local combobox = dgsEditor.GridListDataColumnProperty:dgsComboBox(0,0,100,20,false)
			for i, font in pairs(fonts) do
				combobox:addItem(font)
				if font == data then
					combobox:setSelectedItem(i)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				local tempData = targetElement.columnData
				tempData[id][i] = source:getItemText(row)
				targetElement.columnData = tempData
				dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
			end)
			attachToScrollPane(combobox,dgsEditor.GridListDataColumnProperty,row)
		else
			if data == nil then data = "" end
			local edit = dgsEditor.GridListDataColumnProperty:dgsEdit(0,0,100,20,data,false)
				:on("dgsTextChange",function()
					if property == "text" then
						dgsEditor.GridListDataColumn:setItemText(id,2,source:getText())
					end
					local tempData = targetElement.columnData
					tempData[id][i] = source:getText()
					targetElement.columnData = tempData
					dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
				end)
			attachToScrollPane(edit,dgsEditor.GridListDataColumnProperty,row)
		end
	end,
	Color = function(targetElement,property,row,offset,data,id,i)
		if data == nil then data = 0 end
		local r,g,b,a = fromcolor(data,true)
		local shader = dxCreateShader("client/alphaCircle.fx")
		local imgBack = dgsEditor.GridListDataColumnProperty:dgsImage(0,0,20,20,shader,false)
		attachToScrollPane(imgBack,dgsEditor.GridListDataColumnProperty,row)
		dgsAttachToAutoDestroy(shader,imgBack.dgsElement)
		local circleImage = dgsCreateCircle(0.48,0,360,tocolor(r,g,b,a))
		dxSetShaderValue(circleImage,"borderSoft",0.02)
		dgsAddPropertyListener(circleImage,"color")
		addEventHandler("onDgsPropertyChange",circleImage,function(key,newValue,oldValue)
			if key == "color" then
				local tempData = targetElement.columnData
				tempData[id][i] = tocolor(fromcolor(newValue,true))
				targetElement.columnData = tempData
				dgsEditor.GridListDataColumn:setItemData(id,1,targetElement.columnData[id])
			end
		end)
		local img = dgsEditor.GridListDataColumnProperty
			:dgsImage(0,0,20,20,circleImage,false)
			:on("dgsMouseClickUp",function()
				dgsEditor.ColorMain.visible = true
				local x,y = dgsRootInstance:getCursorPosition()
				dgsEditor.ColorMain.position.x = x-dgsEditor.ColorMain.size.w
				dgsEditor.ColorMain.position.y = y
				dgsEditor.ColorMain:bringToFront()
				dgsEditor.ColorMain:setText(targetElement:getType())
				dgsEditor.ColorPicker.childImage = source:getImage()
				local r,g,b,a = fromcolor(dgsCircleGetColor(dgsEditor.ColorPicker.childImage),true)
				dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
				dgsSetProperty(dgsEditor.ColorPicker.oldImage.dgsElement,"color",tocolor(r,g,b,a))
			end)
		img:applyDetectArea(dgsEditor.DA)
		imgBack:applyDetectArea(dgsEditor.DA)
		attachToScrollPane(img,dgsEditor.GridListDataColumnProperty,row)
	end,
}

----------------Properties attach/detach
function dgsEditorPropertiesMenuAttach(targetElement)
	--Window type element
	dgsEditor.WidgetPropertiesMain:setText(Language.UsingLanguageTable.DGSProperties or "DGSProperties"..", "..targetElement:getType())
	local propertiesList = dgsGetRegisteredProperties(targetElement:getType(),true)
	local keys = table.listKeys(propertiesList)
	table.sort(keys)
	for i=1,#keys do
		local property = keys[i]
		if property ~= "visible" and property ~= "enabled" then
			local pTemplate = propertiesList[property]
			for t, arguments in pairs(pTemplate) do
				if type(arguments) == "table" then
					--Сhecking whether this property is set
					if targetElement[property] and type(targetElement[property]) == "table" and #targetElement[property] > 0 then
						if #pTemplate > 1 and pTemplate[#pTemplate] ~= 1 then
							--If there are several arguments in the argument
							for i, arg in pairs(arguments) do
								if type(arg) == "table" then
									for c, a in pairs(arg) do
										local arg = dgsListPropertyTypes(a)
										if type(arg) == "table" then
											local check = table.find(arg,"Nil")
											if check then table.remove(arg,check) end
										end
										local arg = arg[2] or arg[1]
										local attach = dgsEditorAttachProperty[arg]
										if attach then
											--Add row section
											local text = DGSPropertyItemNames[property] and DGSPropertyItemNames[property][i] or i
											if c == 1 then
												local rowSection = addRow(dgsEditor.WidgetPropertiesMenu,property.." "..(text[c] or ""),true)
											end
											local row = addRow(dgsEditor.WidgetPropertiesMenu,text[c+1])
											attach(targetElement,property,row,text[i+c],c,i)
										end
									end
								else
									local arg = dgsListPropertyTypes(arg)
									if type(arg) == "table" then
										local check = table.find(arg,"Nil")
										if check then table.remove(arg,check) end
									end
									local arg = arg[2] or arg[1]
									local attach = dgsEditorAttachProperty[arg]
									if attach then
										--Add row section
										local text = DGSPropertyItemNames[property] and DGSPropertyItemNames[property][t] or {}
										if i == 1 then
											local rowSection = addRow(dgsEditor.WidgetPropertiesMenu,property.." "..(text[i] or ""),true)
										end
										local row = addRow(dgsEditor.WidgetPropertiesMenu,text[i+1])
										attach(targetElement,property,row,text[i+1],i,t)
									end
								end
							end
						else
							--If there are several arguments
							for i, arg in pairs(arguments) do
								local arg = dgsListPropertyTypes(arg)
								if type(arg) == "table" then
									local check = table.find(arg,"Nil")
									if check then table.remove(arg,check) end
								end
								local arg = arg[2] or arg[1]
								local attach = dgsEditorAttachProperty[arg]
								if attach then
									--Add row section
									if i == 1 then
										local rowSection = addRow(dgsEditor.WidgetPropertiesMenu,property,true)
									end
									local text = DGSPropertyItemNames[property] and DGSPropertyItemNames[property][i] or i
									local row = addRow(dgsEditor.WidgetPropertiesMenu,text)
									attach(targetElement,property,row,text,i)
								end
							end
						end
					else
						--Add a button to add a property
						local row = addRow(dgsEditor.WidgetPropertiesMenu,property,true)
						dgsEditorAttachProperty.add(targetElement,property,row)
						break
					end
				else
					--If one argument
					local arg = dgsListPropertyTypes(arguments)
					if type(arg) == "table" then
						local check = table.find(arg,"Nil")
						if check then table.remove(arg,check) end
					end
					local arg = arg[2] or arg[1]
					local attach = dgsEditorAttachProperty[arg]
					if attach then
						local row = addRow(dgsEditor.WidgetPropertiesMenu,property,true)
						attach(targetElement,property,row)
					end
				end
			end
		end
	end
	--gridlist data
	if targetElement:getType() == "dgs-dxgridlist" then
		local row = addRow(dgsEditor.WidgetPropertiesMenu,"gridlist data",true)
		local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(10,5,150,20,"settings",false)
			:setProperty("alignment",{"center","center"})
			:on("dgsMouseClickUp",function()
				dgsEditor.GridListDataMain.visible = true
				local x,y = dgsRootInstance:getCursorPosition()
				dgsEditor.GridListDataMain.position.x = x-dgsEditor.GridListDataMain.size.w
				dgsEditor.GridListDataMain.position.y = y
				dgsEditor.GridListDataMain:bringToFront()
				dgsEditor.GridListDataColumn:clearRow()
				for i, properties in pairs(targetElement.columnData) do
					local row = dgsEditor.GridListDataColumn:addRow(_,i..".",properties[1])
					dgsEditor.GridListDataColumn:setItemData(row,1,properties)
				end
				dgsEditor.GridListDataRow:clearRow()
				for i, properties in pairs(targetElement.rowData) do
					--local row = dgsEditor.GridListDataRow:addRow(_,i..".",properties[1][1][1])
					--dgsEditor.GridListDataRow:setItemData(row,1,properties)
				end
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end 
	--parent element
	local p = dgsGetInstance(dgsEditor.Controller.BoundParent)
	if p and p ~= dgsEditor.Canvas then
		local row = addRow(dgsEditor.WidgetPropertiesMenu,"parent",true)
		local rowSection = addRow(dgsEditor.WidgetPropertiesMenu,"")
		local edit = dgsEditor.WidgetPropertiesMenu:dgsLabel(10,5,150,20,p:getType(),false)
			:setProperty("alignment",{"center","center"})
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
		local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(0,5,150,20,"remove parent",false)
			:setProperty("alignment",{"center","center"})
			:on("dgsMouseClickUp",function()
				local c = dgsGetInstance(dgsEditor.Controller.BoundChild)
				--Set parent element the Canvas
				c:setParent(dgsEditor.Canvas)
				c.position.relative = dgsEditor.Controller.position.relative
				c.position = {0,0}
				c.size.relative = dgsEditor.Controller.size.relative
				c.size = dgsEditor.Controller.size
				dgsEditorPropertiesMenuDetach()
				dgsEditorControllerAttach(c)
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,rowSection)
	else
		local row = addRow(dgsEditor.WidgetPropertiesMenu,"parent",true)
		local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(10,5,150,20,"set parent",false)
			:setProperty("alignment",{"center","center"})
			:on("dgsMouseClickUp",function()
				source:setText("click on the element")
				--Create find the parent
				dgsEditor.Controller.FindParent = true
			end)
		attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
	end
	--destroy element
	local row = addRow(dgsEditor.WidgetPropertiesMenu,"destroy",true)
	local edit = dgsEditor.WidgetPropertiesMenu:dgsButton(10,5,150,20,"destroy element",false)
		:setProperty("alignment",{"center","center"})
		:on("dgsMouseClickUp",function()
			dgsEditorDestroyElement(targetElement,true)
		end)
	attachToScrollPane(edit,dgsEditor.WidgetPropertiesMenu,row)
end

function dgsEditorPropertiesMenuDetach()
	dgsEditor.WidgetPropertiesMain:setText(Language.UsingLanguageTable.DGSProperties or "DGSProperties")
	dgsEditor.WidgetPropertiesMenu.row = 0
	for _, child in pairs(dgsEditor.WidgetPropertiesMenu.children) do
		--don't touch scrollbar
		if not child.attachedToParent then
			child:destroy()
		end
	end
	--color menu detach
	dgsEditor.ColorMain.visible = false
	dgsEditor.ColorPicker.childImage = nil
	--data menu detach
	dgsEditor.GridListDataMain.visible = false
	dgsEditor.GridListDataColumn:clearRow()
	dgsEditor.GridListDataColumnProperty.row = 0
	for _, child in pairs(dgsEditor.GridListDataColumnProperty.children) do
		--don't touch scrollbar
		if not child.attachedToParent then
			child:destroy()
		end
	end
	dgsEditor.GridListDataRow:clearRow()
	dgsEditor.GridListDataRowProperty.row = 0
	for _, child in pairs(dgsEditor.GridListDataRowProperty.children) do
		--don't touch scrollbar
		if not child.attachedToParent then
			child:destroy()
		end
	end
end

----------------Color Menu
function dgsEditorCreateColorPicker()
	--Color Main
	dgsEditor.ColorMain = dgsWindow(0,0,390,350,"",false)
		:setSizable(false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = backgroundColor,
			titleColor = backgroundColor,
			textSize = {1.2,1.2},
		})
		:center()
	dgsEditor.ColorMain:setLayer("top")
	dgsEditor.ColorMain:dgsImage(0,-1,390,1,_,false,tocolor(0,0,0,255))

	--Color Picker
	dgsEditor.ColorPicker = dgsEditor.ColorMain:dgsColorPicker("HSVRing",10,10,160,160,false)

	--RGB selectors
	local RGB = {"R","G","B","A"}
	for i, attr in pairs(RGB) do
		dgsEditor.ColorMain:dgsLabel(200,10+i*30-30,0,15,attr..":",false)
			:setProperty("alignment",{"right","center"})
		if attr == "A" then
			dgsEditor.ColorMain:dgsComponentSelector(205,10+i*30-30,115,15,true,false,_,2)
			:bindToColorPicker(dgsEditor.ColorPicker,"RGB","A")
			local edit = dgsEditor.ColorMain:dgsEdit(325,97.5,50,20,"",false)
				:on("dgsTextChange",function()
					if source:getText() == "" then return end
					if tonumber(source:getText()) > 255 then return source:setText("255") end
				end)
			addElementOutline(edit)
			local btnUp = edit:dgsButton(0.6,0,0.4,0.5," ▲",true)
				:setProperties({
					alignment = {"center","center"},
					textSize = {0.7,0.7},
				})
				:on("dgsMouseClickDown",function()
					local arg = tonumber(source.parent:getText()) or 0
					local arg = arg + 1
					if arg > 255 then arg = 255 end
					source.parent:setText(arg)
				end)
			addElementOutline(btnUp)
			local btnDown = edit:dgsButton(0.6,0.5,0.4,0.5," ▼",true)
				:setProperties({
					alignment = {"center","center"},
					textSize = {0.7,0.7},
				})
				:on("dgsMouseClickDown",function()
					local arg = tonumber(source.parent:getText()) or 0
					local arg = arg - 1
					if arg < 0 then arg = 0 end
					source.parent:setText(arg)
				end)
			addElementOutline(btnDown)
			edit:setWhiteList("[^0-9]")
			edit:bindToColorPicker(dgsEditor.ColorPicker,"RGB","A")
		else
			dgsEditor.ColorMain:dgsComponentSelector(205,10+i*30-30,170,15,true,false,_,2)
				:bindToColorPicker(dgsEditor.ColorPicker,"RGB",attr)
		end
	end

	--HEX edit
	dgsEditor.ColorMain:dgsLabel(200,140,0,20,"HEX:",false)
		:setProperty("alignment",{"right","center"})
	local edit = dgsEditor.ColorMain:dgsEdit(205,140,80,20,"",false)
	addElementOutline(edit)
	edit:bindToColorPicker(dgsEditor.ColorPicker,"#RGBAHEX","RGBA",_,true)
	
	--RGB edits
	local RGB = {"R","G","B"}
	for i, attr in pairs(RGB) do
		dgsEditor.ColorMain:dgsLabel(25,190+i*30-30,0,20,attr..":",false)
			:setProperty("alignment",{"right","center"})
		local edit = dgsEditor.ColorMain:dgsEdit(30,190+i*30-30,50,20,"",false)
			:on("dgsTextChange",function()
				if source:getText() == "" then return end
				if tonumber(source:getText()) > 255 then return source:setText("255") end
			end)
		addElementOutline(edit)
		local btnUp = edit:dgsButton(0.6,0,0.4,0.5," ▲",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg + 1
				if arg > 255 then arg = 255 end
				source.parent:setText(arg)
			end)
		addElementOutline(btnUp)
		local btnDown = edit:dgsButton(0.6,0.5,0.4,0.5," ▼",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg - 1
				if arg < 0 then arg = 0 end
				source.parent:setText(arg)
			end)
		addElementOutline(btnDown)
		edit:setWhiteList("[^0-9]")
		edit:bindToColorPicker(dgsEditor.ColorPicker,"RGB",attr)
	end

	--HSL edits
	local HSL = {"H","S","L"}
	for i, attr in pairs(HSL) do
		dgsEditor.ColorMain:dgsLabel(115,190+i*30-30,0,20,attr..":",false)
			:setProperty("alignment",{"right","center"})

		local edit = dgsEditor.ColorMain:dgsEdit(120,190+i*30-30,50,20,"",false)
			:on("dgsTextChange",function()
				if attr == "H" then
					if source:getText() == "" then return end
					if tonumber(source:getText()) > 360 then return source:setText("360") end
				else
					if source:getText() == "" then return end
					if tonumber(source:getText()) > 100 then return source:setText("100") end
				end
			end)
		addElementOutline(edit)
		local btnUp = edit:dgsButton(0.6,0,0.4,0.5," ▲",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg + 1
				if attr == "H" then
					if arg > 360 then arg = 360 end
				else
					if arg > 100 then arg = 100 end
				end
				source.parent:setText(arg)
			end)
		addElementOutline(btnUp)
		local btnDown = edit:dgsButton(0.6,0.5,0.4,0.5," ▼",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg - 1
				if arg < 0 then arg = 0 end
				source.parent:setText(arg)
			end)
		addElementOutline(btnDown)
		edit:setWhiteList("[^0-9]")
		edit:bindToColorPicker(dgsEditor.ColorPicker,"HSL",attr)
		if attr ~= "H" then
			dgsEditor.ColorMain:dgsLabel(175,190+i*30-30,0,20,"%",false)
				:setProperty("alignment",{"left","center"})
		end
	end

	--HSV edits
	local HSV = {"H","S","V"}
	for i, attr in pairs(HSV) do
		dgsEditor.ColorMain:dgsLabel(215,190+i*30-30,0,20,attr..":",false)
			:setProperty("alignment",{"right","center"})

		local edit = dgsEditor.ColorMain:dgsEdit(220,190+i*30-30,50,20,"",false)
			:on("dgsTextChange",function()
				if attr == "H" then
					if source:getText() == "" then return end
					if tonumber(source:getText()) > 360 then return source:setText("360") end
				else
					if source:getText() == "" then return end
					if tonumber(source:getText()) > 100 then return source:setText("100") end
				end
			end)
		addElementOutline(edit)
		local btnUp = edit:dgsButton(0.6,0,0.4,0.5," ▲",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg + 1
				if attr == "H" then
					if arg > 360 then arg = 360 end
				else
					if arg > 100 then arg = 100 end
				end
				source.parent:setText(arg)
			end)
		addElementOutline(btnUp)
		local btnDown = edit:dgsButton(0.6,0.5,0.4,0.5," ▼",true)
			:setProperties({
				alignment = {"center","center"},
				textSize = {0.7,0.7},
			})
			:on("dgsMouseClickDown",function()
				local arg = tonumber(source.parent:getText()) or 0
				local arg = arg - 1
				if arg < 0 then arg = 0 end
				source.parent:setText(arg)
			end)
		addElementOutline(btnDown)
		edit:setWhiteList("[^0-9]")
		edit:bindToColorPicker(dgsEditor.ColorPicker,"HSV",attr)
		if attr ~= "H" then
			dgsEditor.ColorMain:dgsLabel(275,190+i*30-30,0,20,"%",false)
				:setProperty("alignment",{"left","center"})
		end
	end

	--old/new color
	local shader = dxCreateShader("client/alphaCircle.fx")
	dxSetShaderValue(shader,"items",6)
	dxSetShaderValue(shader,"radius",1)
	local background = dgsEditor.ColorMain
		:dgsImage(300,190,80,80,shader,false)
	addElementOutline(background)

	dgsEditor.ColorMain:dgsLabel(300,190,80,0,"new",false)
		:setProperty("alignment",{"center","bottom"})
	local newImage = dgsEditor.ColorMain
		:dgsImage(300,190,80,40,_,false,tocolor(0,0,0,255))

	dgsEditor.ColorPicker:on("dgsColorPickerChange",function()
			newImage:setProperty("color",tocolor(source:getColor()))
		end)

	dgsEditor.ColorMain:dgsLabel(300,270,80,0,"old",false)
		:setProperty("alignment",{"center","top"})
	dgsEditor.ColorPicker.oldImage = dgsEditor.ColorMain
		:dgsImage(300,230,80,40,_,false,tocolor(255,255,255,255))

	--confirm button
	local btn = dgsEditor.ColorMain:dgsButton(10,300,80,20,"confirm",false)
		:on("dgsMouseClickUp",function()
			if dgsEditor.ColorPicker.childImage then
				local r,g,b,a = dgsEditor.ColorPicker:getColor()
				dgsCircleSetColor(dgsEditor.ColorPicker.childImage,tocolor(r,g,b,a))
			end
			dgsEditor.ColorMain.visible = false
			dgsEditor.ColorPicker.childImage = nil
		end)
	addElementOutline(btn)

	--cancel button
	local btn = dgsEditor.ColorMain:dgsButton(300,300,80,20,"cancel",false)
		:on("dgsMouseClickUp",function()
			dgsEditor.ColorMain.visible = false
			dgsEditor.ColorPicker.childImage = nil
		end)
	addElementOutline(btn)
			
	dgsEditor.ColorMain.visible = false
	--circle detect area
	dgsEditor.DA = dgsDetectArea()
		:setFunction("circle")

	--detach from color picker
	dgsEditor.BackGround:on("dgsMouseClickDown",function(button,state)
		if button == "left" then
			if dgsIsMouseWithinGUI(dgsEditor.Controller.dgsElement) then return end
			for _, menu in pairs(dgsEditor.Menus) do
				if dgsIsMouseWithinGUI(menu) then
					return
				end
			end
			dgsEditor.ColorMain.visible = false
			dgsEditor.ColorPicker.childImage = nil
		end
	end,true)
	return dgsEditor.ColorMain.dgsElement
end

----------------Generation Code Menu
function dgsEditorCreateGenerateCode()
	--Generate Code Main
	dgsEditor.GenerateMain = dgsWindow(0,sH-300,300,300,"Generate Code",false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = backgroundColor,
			titleColor = backgroundColor,
			textSize = {1.2,1.2},
			minSize = {200,200},
			borderSize = 5,
		})
		:center()
	dgsEditor.GenerateMain:setLayer("top")
	local line = dgsEditor.GenerateMain:dgsImage(0,-1,300,1,_,false,tocolor(0,0,0,255))

	dgsEditor.CodeMemo = dgsEditor.GenerateMain:dgsMemo(10,10,280,250-dgsEditor.GenerateMain.titleHeight,"",false)
	addElementOutline(dgsEditor.CodeMemo)
	
	local btn = dgsEditor.GenerateMain
		:dgsButton(210,270-dgsEditor.GenerateMain.titleHeight,80,20,"generate",false)
		:on("dgsMouseClickDown",function(btn,state)
			if btn == "left" and state == "down" then
				dgsEditor.CodeMemo:setText(generateCode())
			end
		end)
	addElementOutline(btn)
	--Press G to generate the code
	bindKey("G","down",function()
		btn:simulateClick("left")
	end)
	
	local edit = dgsEditor.GenerateMain
		:dgsEdit(10,270-dgsEditor.GenerateMain.titleHeight,80,20,gTableName,false)
		:on("dgsTextChange",function()
			gTableName = source:getText()
			btn:simulateClick("left")
		end)
	addElementOutline(edit)

	dgsEditor.GenerateMain.visible = false

	--Resize childs
	dgsEditor.GenerateMain:on("dgsSizeChange",function()
		local w,h = source:getSize()
		dgsEditor.CodeMemo:setSize(w-20,h-source.titleHeight-50)
		btn:setPosition(w-90,h-30-source.titleHeight)
		edit:setPosition(10,h-30-source.titleHeight)
		line:setSize(w,1)
	end)
	return dgsEditor.GenerateMain.dgsElement
end

----------------GridList Data Menu
function dgsEditorCreateGridListDataMenu()
	--rowData Main
	dgsEditor.GridListDataMain = dgsWindow(0,0,470,350,"Grid list data settings",false)
		:setSizable(false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = backgroundColor,
			titleColor = backgroundColor,
			textSize = {1.2,1.2},
		})
		:center()
	dgsEditor.GridListDataMain:setLayer("top")
	dgsEditor.GridListDataMain:dgsImage(0,-1,470,1,_,false,tocolor(0,0,0,255))

	local tabPanel = dgsEditor.GridListDataMain:dgsTabPanel(0,1,470,330,false)
		:setProperty("bgColor",backgroundColor)
	tabPanel:dgsImage(0,20,470,1,_,false,tocolor(0,0,0,255))

	--column data
	local tabColumn = tabPanel:dgsTab("column data")
	
	--buttons
	local btnAdd = tabColumn:dgsButton(15,10,40,20,"+",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local id = element:addColumn("name",0.5)
				local data = element.columnData
				local row = dgsEditor.GridListDataColumn:addRow(_,id..".","name")
				dgsEditor.GridListDataColumn:setItemData(row,1,data[id])
				dgsEditor.GridListDataColumn:setSelectedItem(row)
			end
		end)
	addElementOutline(btnAdd)
	local btnRemove = tabColumn:dgsButton(65,10,40,20,"▬",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataColumn:getSelectedItem()
				if row ~= -1 then
					element:removeColumn(row)
					--refresh list
					dgsEditor.GridListDataColumn:clearRow()
					for i, properties in pairs(element.columnData) do
						local row = dgsEditor.GridListDataColumn:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataColumn:setItemData(row,1,properties)
					end
				end
			end
		end)
	addElementOutline(btnRemove)
	local btnUp = tabColumn:dgsButton(115,10,40,20,"▲",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataColumn:getSelectedItem()
				if row ~= -1 and row > 1 then
					local tempData = element.columnData
					--swap
					tempData[row][3],tempData[row-1][3] = tempData[row-1][3],tempData[row][3]
					tempData[row],tempData[row-1] = tempData[row-1],tempData[row]
					element.columnData = tempData
					--refresh list
					dgsEditor.GridListDataColumn:clearRow()
					for i, properties in pairs(element.columnData) do
						local row = dgsEditor.GridListDataColumn:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataColumn:setItemData(row,1,properties)
					end
					dgsEditor.GridListDataColumn:setSelectedItem(row-1)
				end
			end
		end)
	addElementOutline(btnUp)
	local btnDown = tabColumn:dgsButton(165,10,40,20,"▼",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataColumn:getSelectedItem()
				if row ~= -1 and row < dgsEditor.GridListDataColumn:getRowCount() then
					local tempData = element.columnData
					--swap
					tempData[row][3],tempData[row+1][3] = tempData[row+1][3],tempData[row][3]
					tempData[row],tempData[row+1] = tempData[row+1],tempData[row]
					element.columnData = tempData
					--refresh list
					dgsEditor.GridListDataColumn:clearRow()
					for i, properties in pairs(element.columnData) do
						local row = dgsEditor.GridListDataColumn:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataColumn:setItemData(row,1,properties)
					end
					dgsEditor.GridListDataColumn:setSelectedItem(row+1)
				end
			end
		end)
	addElementOutline(btnDown)

	--list
	dgsEditor.GridListDataColumn = tabColumn:dgsGridList(10,40,200,250,false)
		:setProperties({
			rowHeight = 20,
			scrollBarThick = 10,
			sortEnabled = false,
		})
		:on("dgsGridListSelect",function(rowNew)
			dgsEditor.GridListDataColumnProperty.row = 0
			for _, child in pairs(dgsEditor.GridListDataColumnProperty.children) do
				--don't touch scrollbar
				if not child.attachedToParent then
					child:destroy()
				end
			end
			if rowNew ~= -1 then
				local properties = dgsEditor.GridListDataColumn:getItemData(rowNew,1)
				if properties then
					local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
					if element then
						for i, data in pairs(columnData) do
							local row = addRow(dgsEditor.GridListDataColumnProperty,data[1],true)
							local attach = dgsEditorGridListAttachProperty[data[2]]
							if attach then
								attach(element,data[1],row,0,properties[i] or nil,rowNew,i)
							end
						end
					end
				end
			end
		end)
	dgsEditor.GridListDataColumn:addColumn("id",0.1)
	dgsEditor.GridListDataColumn:addColumn("name",0.9)

	--proeprties
	tabColumn:dgsLabel(220,10,200,20,"Column properties:",false)
		:setProperty("alignment",{"left","center"})
	dgsEditor.GridListDataColumnProperty = tabColumn:dgsScrollPane(220,40,240,250,false)
		:setProperties({
			rowHeight = 30,
			scrollBarThick = 10,
			scrollBarState = {nil,false},
			bgColor = tocolor(30,32,35,255),
		})

	--row data
	local tabRow = tabPanel:dgsTab("row data")
	--buttons
	local btnAdd = tabRow:dgsButton(15,10,40,20,"+",false)
		:on("dgsMouseClickDown",function()
			--[[local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local id = element:addRow("name",0.5)
				local data = element.rowData
				local row = dgsEditor.GridListDataRow:addRow(_,id..".","name")
				dgsEditor.GridListDataRow:setItemData(row,1,data[id])
				dgsEditor.GridListDataRow:setSelectedItem(row)
			end]]
		end)
	addElementOutline(btnAdd)
	local btnRemove = tabRow:dgsButton(65,10,40,20,"▬",false)
		:on("dgsMouseClickDown",function()
			--[[local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataRow:getSelectedItem()
				if row ~= -1 then
					element:removeRow(row)
					--refresh list
					dgsEditor.GridListDataRow:clearRow(false,true)
					for i, properties in pairs(element.rowData) do
						local row = dgsEditor.GridListDataRow:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataRow:setItemData(row,1,properties)
					end
				end
			end]]
		end)
	addElementOutline(btnRemove)
	local btnUp = tabRow:dgsButton(115,10,40,20,"▲",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataRow:getSelectedItem()
				if row ~= -1 and row > 1 then
					local tempData = element.rowData
					--swap
					tempData[row][3],tempData[row-1][3] = tempData[row-1][3],tempData[row][3]
					tempData[row],tempData[row-1] = tempData[row-1],tempData[row]
					element.rowData = tempData
					--refresh list
					dgsEditor.GridListDataRow:clearRow()
					for i, properties in pairs(element.rowData) do
						local row = dgsEditor.GridListDataRow:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataRow:setItemData(row,1,properties)
					end
					dgsEditor.GridListDataRow:setSelectedItem(row-1)
				end
			end
		end)
	addElementOutline(btnUp)
	local btnDown = tabRow:dgsButton(165,10,40,20,"▼",false)
		:on("dgsMouseClickDown",function()
			local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
			if element then
				local row = dgsEditor.GridListDataRow:getSelectedItem()
				if row ~= -1 and row < dgsEditor.GridListDataRow:getRowCount() then
					local tempData = element.rowData
					--swap
					tempData[row][3],tempData[row+1][3] = tempData[row+1][3],tempData[row][3]
					tempData[row],tempData[row+1] = tempData[row+1],tempData[row]
					element.rowData = tempData
					--refresh list
					dgsEditor.GridListDataRow:clearRow()
					for i, properties in pairs(element.rowData) do
						local row = dgsEditor.GridListDataRow:addRow(_,i..".",properties[1])
						dgsEditor.GridListDataRow:setItemData(row,1,properties)
					end
					dgsEditor.GridListDataRow:setSelectedItem(row+1)
				end
			end
		end)
	addElementOutline(btnDown)

	--list
	dgsEditor.GridListDataRow = tabRow:dgsGridList(10,40,200,250,false)
		:setProperties({
			rowHeight = 20,
			scrollBarThick = 10,
			sortEnabled = false,
		})
		:on("dgsGridListSelect",function(rowNew)
			dgsEditor.GridListDataRowProperty.row = 0
			for _, child in pairs(dgsEditor.GridListDataRowProperty.children) do
				--don't touch scrollbar
				if not child.attachedToParent then
					child:destroy()
				end
			end
			if rowNew ~= -1 then
				local properties = dgsEditor.GridListDataRow:getItemData(rowNew,1)
				if properties then
					local element = dgsGetInstance(dgsEditor.Controller.BoundChild)
					if element then
						for i, data in pairs(rowData) do
							local row = addRow(dgsEditor.GridListDataRowProperty,data[1],true)
							local attach = dgsEditorGridListAttachProperty[data[2]]
							if attach then
								attach(element,data[1],row,0,properties[i] or nil,rowNew,i)
							end
						end
					end
				end
			end
		end)
	dgsEditor.GridListDataRow:addColumn("id",0.1)
	dgsEditor.GridListDataRow:addColumn("name",0.9)

	--proeprties
	tabRow:dgsLabel(220,10,200,20,"Row properties:",false)
		:setProperty("alignment",{"left","center"})
	dgsEditor.GridListDataRowProperty = tabRow:dgsScrollPane(220,40,240,250,false)
		:setProperties({
			rowHeight = 30,
			scrollBarThick = 10,
			scrollBarState = {nil,false},
			bgColor = tocolor(30,32,35,255),
		})

	--hide menu
	dgsEditor.GridListDataMain.visible = false
	dgsEditor.BackGround:on("dgsMouseClickDown",function(button,state)
		if button == "left" then
			if dgsIsMouseWithinGUI(dgsEditor.Controller.dgsElement) then return end
			for _, menu in pairs(dgsEditor.Menus) do
				if dgsIsMouseWithinGUI(menu) then
					return
				end
			end
			dgsEditor.GridListDataMain.visible = false
			dgsEditor.GridListDataColumn:clearRow()
			dgsEditor.GridListDataColumnProperty.row = 0
			for _, child in pairs(dgsEditor.GridListDataColumnProperty.children) do
				--don't touch scrollbar
				if not child.attachedToParent then
					child:destroy()
				end
			end
			dgsEditor.GridListDataRow:clearRow()
			dgsEditor.GridListDataRowProperty.row = 0
			for _, child in pairs(dgsEditor.GridListDataRowProperty.children) do
				--don't touch scrollbar
				if not child.attachedToParent then
					child:destroy()
				end
			end
		end
	end,true)
	return dgsEditor.GridListDataMain.dgsElement
end

----------------Textures Menu
function dgsEditorCreateTexturesMenu()
	dgsEditor.Textures = {}
	--textures Main
	dgsEditor.TexturesMain = dgsWindow(0,0,470,350,"Textures",false)
		:setSizable(false)
		:setProperties({
			shadow = {1,1,0xFF000000},
			titleColorBlur = false,
			color = backgroundColor,
			titleColor = backgroundColor,
			textSize = {1.2,1.2},
		})
		:center()
	dgsEditor.TexturesMain:setLayer("top")
	dgsEditor.TexturesMain:dgsImage(0,-1,470,1,_,false,tocolor(0,0,0,255))

	--buttons
	local btnAdd = dgsEditor.TexturesMain:dgsButton(15,10,40,20,"+",false)
		:on("dgsMouseClickDown",function()
			local id = dgsEditor.TexturesList:getRowCount()+1
			local row = dgsEditor.TexturesList:addRow(_,id..".","texture"..id)
			dgsEditor.TexturesList:setItemData(row,2,"texture"..id)
			dgsEditor.TexturesList:setSelectedItem(row)
			dgsEditor.Textures[row] = dgsCreateRemoteImage("")
			dgsSetProperty(dgsEditor.Textures[row],"textureInfo",{"texture"..id,false})
			dgsEditor.TexturePrivew:setImage(dgsEditor.Textures[row])
		end)
	addElementOutline(btnAdd)
	local btnRemove = dgsEditor.TexturesMain:dgsButton(65,10,40,20,"▬",false)
		:on("dgsMouseClickDown",function()
			local row = dgsEditor.TexturesList:getSelectedItem()
			if row ~= -1 then
				dgsEditor.TextureURL:setEnabled(false)
				dgsEditor.TextureName:setEnabled(false)
				dgsEditor.TexturesList:removeRow(row)
				dgsEditor.TextureURL:setText("")
				dgsEditor.TextureName:setText("")
				dgsEditor.TexturePrivew:setImage(nil)
				--Destroy remote image
				local remoteImage = dgsEditor.Textures[row]
				local texture = dgsRemoteImageGetTexture(remoteImage)
				if texture and isElement(texture) then
					--Remove the property if the element has this texture set
					for dgsElement, element in pairs(dgsEditor.ElementList) do
						if element.dgsEditorPropertyList then
							for property, value in pairs(element.dgsEditorPropertyList) do
								if type(value) == "table" and table.find(value,tostring(texture)) then
									element.textureID = nil
									resetProperty(element,property)
								end
								if type(value) ~= "table" and tostring(value):find(tostring(texture)) then
									element.textureID = nil
									resetProperty(element,property)
								end
							end
						end
					end
					destroyElement(texture)
				end
				destroyElement(remoteImage)
				dgsEditor.Textures[row] = nil
			end
		end)
	addElementOutline(btnRemove)

	--textures list
	dgsEditor.TexturesList = dgsEditor.TexturesMain:dgsGridList(10,40,200,250,false)
		:setProperties({
			rowHeight = 20,
			scrollBarThick = 10,
			sortEnabled = false,
		})
		:on("dgsGridListSelect",function(row)
			if row ~= -1 then
				local dataURL = dgsEditor.TexturesList:getItemData(row,1)
				if dataURL then
					dgsEditor.TextureURL:setText(dataURL)
				else
					dgsEditor.TextureURL:setText("")
				end
				local dataName = dgsEditor.TexturesList:getItemText(row,2)
				dgsEditor.TextureName:setText(dataName)
				dgsEditor.TexturePrivew:setImage(dgsEditor.Textures[row])
				dgsEditor.TextureURL:setEnabled(true)
				dgsEditor.TextureName:setEnabled(true)
			else
				dgsEditor.TextureURL:setEnabled(false)
				dgsEditor.TextureName:setEnabled(false)
				dgsEditor.TextureURL:setText("")
				dgsEditor.TextureName:setText("")
				dgsEditor.TexturePrivew:setImage(nil)
			end
		end)
	dgsEditor.TexturesList:addColumn("id",0.1)
	dgsEditor.TexturesList:addColumn("name",0.9)
	dgsEditor.TexturesList:addColumn("",0)
	
	dgsEditor.TexturesMain:dgsLabel(220,10,240,20,"Texture preview:",false)
		:setProperty("alignment",{"left","center"})
	dgsEditor.TexturePrivew = dgsEditor.TexturesMain:dgsImage(220,40,240,150,_,false)
	--texture URL
	dgsEditor.TexturesMain:dgsLabel(220,200,240,20,"URL:",false)
		:setProperty("alignment",{"left","center"})
	dgsEditor.TextureURL = dgsEditor.TexturesMain:dgsEdit(220,220,240,20,"",false)
		:setEnabled(false)
		:on("dgsTextChange",function()
			local row = dgsEditor.TexturesList:getSelectedItem()
			if row ~= -1 and source:getEnabled() then
				local texture = dgsEditor.Textures[row]
				if texture then
					if not dgsGetRemoteImageLoadState(texture) then
						dgsRemoteImageAbort(texture)
					end
					if dgsRemoteImageGetTexture(texture) then
						destroyElement(dgsRemoteImageGetTexture(texture))
					end
					dgsRemoteImageRequest(texture,source:getText())
					dgsSetProperty(dgsEditor.Textures[row],"textureInfo",{dgsEditor.TextureName:getText(),source:getText()})
					dgsEditor.TexturesList:setItemData(row,1,source:getText())
				end
			end
		end)
	addElementOutline(dgsEditor.TextureURL)

	--texture name
	dgsEditor.TexturesMain:dgsLabel(220,250,240,20,"Name:",false)
		:setProperty("alignment",{"left","center"})
	dgsEditor.TextureName = dgsEditor.TexturesMain:dgsEdit(220,270,240,20,"",false)
		:setEnabled(false)
		:on("dgsTextChange",function()
			local row = dgsEditor.TexturesList:getSelectedItem()
			if row ~= -1 and source:getEnabled() then
				dgsEditor.TexturesList:setItemText(row,2,source:getText())
				if dgsEditor.Textures[row] then
					dgsSetProperty(dgsEditor.Textures[row],"textureInfo",{source:getText(),dgsEditor.TextureURL:getText()})
				end
			end
		end)
	addElementOutline(dgsEditor.TextureName)

	dgsEditor.TexturesMain.visible = false
	
	return dgsEditor.TexturesMain.dgsElement
end

----------------Hot Key Controller
KeyHolder = {}
function onClientKeyCheckInRender()
	if KeyHolder.repeatKey then
		local tick = getTickCount()
		if tick-KeyHolder.repeatStartTick >= KeyHolder.repeatDuration then
			KeyHolder.repeatStartTick = tick
			if getKeyState(KeyHolder.lastKey) then
				onClientKeyTriggered(KeyHolder.lastKey)
			else
				KeyHolder = {}
			end
		end
	end
end
addEventHandler("onClientRender",root,onClientKeyCheckInRender)

function onClientKeyCheck(button,state)
	if state and button:sub(1,5) ~= "mouse" then
		if isTimer(KeyHolder.Timer) then killTimer(KeyHolder.Timer) end
		KeyHolder = {}
		KeyHolder.lastKey = button
		KeyHolder.Timer = setTimer(function()
			if not getKeyState(KeyHolder.lastKey) then
				KeyHolder = {}
				return
			end
			KeyHolder.repeatKey = true
			KeyHolder.repeatStartTick = getTickCount()
			KeyHolder.repeatDuration = 25
		end,400,1)
		if onClientKeyTriggered(button) then
			cancelEvent()
		end
	end
end
addEventHandler("onClientKey",root,onClientKeyCheck)

function onClientKeyTriggered(button)
	--Undo/redo action
	local shift = getKeyState("lshift") or getKeyState("rshift")
	local ctrl = getKeyState("lctrl") or getKeyState("rctrl")
	if ctrl and button == "z" then
		if shift then
			if dgsEditor.ActionHistory.Redo and #dgsEditor.ActionHistory.Redo > 0 then
				historyActionState = historyActionState - 1
				local name,args = unpack(dgsEditor.ActionHistory.Redo[1])
				table.remove(dgsEditor.ActionHistory.Redo,1)
				dgsEditor.Action[name](unpack(args))
				if name == "destroy" then
					saveAction("show",args,true)
				elseif name == "show" then
					saveAction("destroy",args,true)
				elseif name == "returnProperty" then
					saveAction("cancelProperty",args,true)
				end
			end
		else
			if dgsEditor.ActionHistory.Undo and #dgsEditor.ActionHistory.Undo > 0 then
				historyActionState = historyActionState + 1
				local name,args = unpack(dgsEditor.ActionHistory.Undo[1])
				table.remove(dgsEditor.ActionHistory.Undo,1)
				dgsEditor.Action[name](unpack(args))
				if name == "destroy" then
					table.insert(dgsEditor.ActionHistory.Redo,1,{"show",args})
				elseif name == "show" then
					table.insert(dgsEditor.ActionHistory.Redo,1,{"destroy",args})
				elseif name == "cancelProperty" then
					table.insert(dgsEditor.ActionHistory.Redo,1,{"returnProperty",args})
				end
			end
		end
	end
	if dgsEditor.Controller and dgsEditor.Controller.visible then
		if button == "arrow_u" then
			dgsEditor.Controller.position = dgsEditor.Controller.position.toVector+Vector2(0,-1)
		elseif button == "arrow_d" then
			dgsEditor.Controller.position = dgsEditor.Controller.position.toVector+Vector2(0,1)
		elseif button == "arrow_l" then
			dgsEditor.Controller.position = dgsEditor.Controller.position.toVector+Vector2(-1,0)
		elseif button == "arrow_r" then
			dgsEditor.Controller.position = dgsEditor.Controller.position.toVector+Vector2(1,0)
		elseif button == "delete" then
			if dgsEditor.Controller.BoundChild then
				dgsEditorDestroyElement(dgsGetInstance(dgsEditor.Controller.BoundChild),true)
			end
		elseif button == "enter" then
			--Confirm color picker
			if dgsEditor.ColorMain.visible then
				if dgsEditor.ColorPicker.childImage then
					local r,g,b,a = dgsEditor.ColorPicker:getColor()
					dgsCircleSetColor(dgsEditor.ColorPicker.childImage,tocolor(r,g,b,a))
				end
				dgsEditor.ColorMain.visible = false
				dgsEditor.ColorPicker.childImage = nil
			end			
		end
	end
end

--Save property changes 
function changeProperty(element,property,newValue,i,t)
	local tempValue = element[property]
	local oldValue = element[property]
	if t then
		tempValue[t][i] = newValue
	else
		if i then
			tempValue[i] = newValue
		else
			tempValue = newValue
		end
	end
	element[property] = tempValue
	local newValue = element[property]
	
	local tempPropertyList = element.dgsEditorPropertyList
	if not tempPropertyList then tempPropertyList = {} end
	--Save initial property
	if tempPropertyList[property] == nil then
		local initialValue = element.dgsEditorInitialValue
		if not initialValue then initialValue = {} end
		initialValue[property] = oldValue
		element.dgsEditorInitialValue = initialValue
	end
	tempPropertyList[property] = newValue
	element.dgsEditorPropertyList = tempPropertyList
	saveAction("cancelProperty",{element,property,newValue,oldValue})
end

--Reset property
function resetProperty(element,property)
	if element and element.dgsEditorInitialValue and element.dgsEditorInitialValue[property] ~= nil then
		element[property] = element.dgsEditorInitialValue[property]

		local initialValue = element.dgsEditorInitialValue
		initialValue[property] = nil
		element.dgsEditorInitialValue = initialValue

		local tempPropertyList = element.dgsEditorPropertyList
		tempPropertyList[property] = nil
		element.dgsEditorPropertyList = tempPropertyList 
	end
end

--Save actions
function saveAction(name,args,isAction)
	if not isAction then
		if historyActionState > 0 then
			historyActionState = 0 -- reset state
			dgsEditor.ActionHistory.Redo = {} -- clear redo actions
		end
	end
	table.insert(dgsEditor.ActionHistory.Undo,1,{name,args})
	if #dgsEditor.ActionHistory.Undo > historyLimit then
		table.remove(dgsEditor.ActionHistory.Undo,#dgsEditor.ActionHistory.Undo)
	end
end

--destroy element
function dgsEditorDestroyElement(element,isAction)
	if element then
		--if save action
		if isAction then
			saveAction("show",{element})
		end
		if element.children then
			for _, child in pairs(element.children) do
				--if it is not an internal element
				if child.isCreatedByEditor then
					child.isCreatedByEditor = false
				end
			end
		end
		element.visible = false
		element.isCreatedByEditor = false
		dgsEditorControllerDetach()
		dgsEditor.Controller.BoundChild = nil
		dgsEditor.Controller.visible = false
	end
end

--add row scroll pane
function addRow(panel,text,isSection)
	local rowTextOffset = 20
	local rowHeight = panel.rowHeight
	local row = panel.row or 0
	local row = row+1
	panel.row = row
	if isSection then rowTextOffset = 10 end
	panel:dgsLabel(rowTextOffset,row*rowHeight-rowHeight,0,rowHeight,text)
		:setProperty("alignment",{"left","center"})
	return row
end

--attach to scroll pane
function attachToScrollPane(element,panel,row)
	local rowHeight = panel.rowHeight
	element:setPosition(panel.size.w*0.5,row*rowHeight-rowHeight+5)
end

--hide menu
addEventHandler("onDgsWindowClose",root,function()
	cancelEvent()
	if table.find(dgsEditor.Menus,source) then
		dgsSetVisible(source,false)
	end
end)
-----------------------------------------------------Start up
function startup()
	loadEditorSettings()
	checkLanguages()
	setCurrentLanguage(dgsEditorSettings.UsingLanguage)
end
startup()