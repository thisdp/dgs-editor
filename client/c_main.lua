--[[
	Full Name:	Editor for thisdp's graphical user interface system
	Short Name: DGS Editor
	Language:	Lua
	Platform:	MTASA
	Author:		thisdp
	License: 	DPL v1 (The same as DGS)
	State:		OpenSourced
	Note:		This script uses the OOP syntax of DGS
]]

dgsEditor = {}

------------------------------------------------------State Switch
function dgsEditorSwitchState(state)
	--If someone want to enable dgs editor
	if state == "enabled" then
		if dgsEditorContext.state == "available" then --First, state need to be "available"
			dgsEditor.state = "enabled"	--Enabled
			dgsEditorMakeOutput(translateText({"EditorEnabled"}))
			triggerEvent("onClientDGSEditorStateChanged",resourceRoot,dgsEditor.state)
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
		end
	elseif state == "disabled" then		--If someone want to disable dgs editor
		--Just disable
		dgsEditor.state = "disabled"
		dgsEditorMakeOutput(translateText({"EditorDisabled"}))
		dgsEditor.BackGround.visible = false
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

------------------------------------------------------Main Panel
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
			print(cursorX,cursorY)
			dgsEditorCreateElement(data)
		end)
	dgsEditor.Canvas.bgColor = tocolor(0,0,0,128)
	--Widgets Window
	dgsEditor.WidgetMain = dgsWindow(0,0,250,0.5*sH,{"DGSWidgets"},false)
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setMovable(false)
		:setParent(dgsEditor.BackGround)
		:setProperty("shadow",{1,1,0xFF000000})
		:setProperty("titleColorBlur",false)
		:setProperty("color",tocolor(0,0,0,128))
		:setProperty("titleColor",tocolor(0,0,0,128))
		:setProperty("textSize",{1.3,1.3})
	--The Vertical Spliter Line
	dgsEditor.WidgetSpliter = dgsEditor.WidgetMain
		:dgsImage(80,0,5,0.5*sH-25,_,false,tocolor(50,50,50,200))
	--Type List
	dgsEditor.WidgetTypeList = dgsEditor.WidgetMain
		:dgsGridList(0,0,80,200,false)
		:setProperty("rowHeight",25)
		:setProperty("columnHeight",0)
		:setProperty("rowTextSize",{1.2,1.2})
		:setProperty("bgColor",tocolor(0,0,0,0))
		:setProperty("sortEnabled",false)
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 then
				

				if rNew == -1 then
					source:setSelectedItem(rOld)
				end
			end
		end)
	dgsEditor.WidgetTypeList:addColumn("",0.9)
	dgsEditor.WidgetTypeList:addRow(_,{"Basic"})
	dgsEditor.WidgetTypeList:addRow(_,{"Plugins"})
	--Widget List
	dgsEditor.WidgetList = dgsEditor.WidgetMain
		:dgsGridList(85,0,165,0.5*sH-25,false)
		:setProperty("rowHeight",30)
		:setProperty("columnHeight",0)
		:setProperty("rowTextSize",{1.2,1.2})
		:setProperty("scrollBarThick",10)
		:setProperty("bgColor",tocolor(0,0,0,0))
		:setProperty("sortEnabled",false)
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 then


				if rNew == -1 then
					source:setSelectedItem(rOld)
				end
			end
		end)
		:on("dgsGridListItemDoubleClick",function(button,state,row)
			if button == "left" and state == "down" then
				local widgetID = source:getItemData(row,1)
				dgsEditorCreateElement(DGSTypeReference[widgetID][1])
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
	dgsEditor.PluginList = dgsEditor.WidgetMain	--PluginList List
		:dgsGridList(85,0,155,370,false)
		:setProperty("rowHeight",30)
		:setProperty("columnHeight",0)
		:setProperty("rowTextSize",{1.2,1.2})
		:setProperty("bgColor",tocolor(0,0,0,0))
		:on("dgsGridListSelect",function(rNew,_,rOld,_)
			if rOld ~= -1 then
				
				if rNew == -1 then
					source:setSelectedItem(rOld)
				end
			end
		end)
		:on("dgsGridListItemDoubleClick",function(row)
			
		end)
	dgsEditor.WidgetList:addColumn(_,0.2)
	dgsEditor.WidgetList:addColumn(_,0.7)
	for i=1,#DGSTypeReference do
		dgsEditor.WidgetList:addRow(_,_,{DGSTypeReference[i][2]})
	end
	
	dgsEditor.PropertyList = dgsWindow(0,0,200,400,{"DGSPropertyList"})
		:center()
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setProperty("color",tocolor(0,0,0,128))
		:setProperty("titleColor",tocolor(0,0,0,128))
		:setLayer("top")]]

	dgsEditor.WidgetPropertiesMain  = dgsWindow(sW-300,0,300,0.5*sH,{"DGSProperties"},false) --Properties Main
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setMovable(false)
		:setParent(dgsEditor.BackGround)
		:setProperty("shadow",{1,1,0xFF000000})
		:setProperty("titleColorBlur",false)
		:setProperty("color",tocolor(0,0,0,128))
		:setProperty("titleColor",tocolor(0,0,0,128))
		:setProperty("textSize",{1.3,1.3})
		:setParent(dgsEditor.BackGround)

	local titleHeight = dgsEditor.WidgetPropertiesMain.titleHeight

	--Properties List
	dgsEditor.WidgetPropertiesMenu = dgsEditor.WidgetPropertiesMain
		:dgsGridList(0,0,300,0.5*sH-titleHeight,false)
		:setProperty("columnHeight",0)
		:setProperty("rowHeight",30)
		:setProperty("sortEnabled",false)
		:setProperty("scrollBarState",{nil,false})
		:setProperty("rowTextPosOffset",{10,0})

	--set rows default color
	local defaultRowColor = dgsEditor.WidgetPropertiesMenu.rowColor[1]
	dgsEditor.WidgetPropertiesMenu:setProperty("rowColor",{defaultRowColor,defaultRowColor,defaultRowColor})

	dgsEditor.WidgetPropertiesMenu:addColumn("",0.35)	-- property name
	dgsEditor.WidgetPropertiesMenu:addColumn("",0.65)	-- edit

	--Color Main
	dgsEditor.WidgetColorMain = dgsWindow(0,0,380,250,{"DGSColorPicker"},false)
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setMovable(false)
		:setParent(dgsEditor.BackGround)
		:setProperty("shadow",{1,1,0xFF000000})
		:setProperty("titleColorBlur",false)
		:setProperty("color",tocolor(80,80,80,200))
		:setProperty("titleColor",tocolor(80,80,80,200))
		:setProperty("textSize",{1.3,1.3})
		:setParent(dgsEditor.BackGround)

	--Color Picker
	dgsEditor.ColorPicker = dgsEditor.WidgetColorMain
		:dgsColorPicker("HSVRing",10,10,200,200,false)
	--Red Selector
	dgsEditor.WidgetColorMain:dgsComponentSelector(260,10,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker,"RGB","R")
	dgsEditor.WidgetColorMain:dgsLabel(230,10,25,25,"Red:",false)
		:setProperty("alignment",{"right","center"})
	--Green Selector
	dgsEditor.WidgetColorMain:dgsComponentSelector(260,50,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker,"RGB","G")
	dgsEditor.WidgetColorMain:dgsLabel(230,50,25,25,"Green:",false)
		:setProperty("alignment",{"right","center"})
	--Blue Selector
	dgsEditor.WidgetColorMain:dgsComponentSelector(260,90,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker,"RGB","B")
	dgsEditor.WidgetColorMain:dgsLabel(230,90,25,25,"Blue:",false)
		:setProperty("alignment",{"right","center"})
	--Alpha Selector
	dgsEditor.WidgetColorMain:dgsComponentSelector(260,130,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker,"RGB","A")
	dgsEditor.WidgetColorMain:dgsLabel(230,130,25,25,"Alpha:",false)
		:setProperty("alignment",{"right","center"})
	
	--detach from color picker
	dgsEditor.BackGround:on("dgsMouseClickDown",function()
		if source ~= dgsEditor.WidgetColorMain then
			for _, element in pairs(dgsEditor.WidgetColorMain.children) do
				if source == element then
					return
				end
			end
			dgsEditor.WidgetColorMain.visible = false
			if colorEdit then
				for _, tableEdits in pairs(colorEdit) do
					for e, edit in pairs(tableEdits) do
						if edit.bindColorPicker then
							edit:unbindFromColorPicker()
						end
					end
				end
			end
			if textColorEdit then
				for e, edit in pairs(textColorEdit) do
					if edit.bindColorPicker then
						edit:unbindFromColorPicker()
					end
				end
			end
			if shadowColorEdit then
				for e, edit in pairs(shadowColorEdit) do
					if edit.bindColorPicker then
						edit:unbindFromColorPicker()
					end
				end
			end
		end
	end,true)

	dgsEditor.WidgetColorMain.visible = false
	
	dgsEditor.Controller = dgsEditorCreateController(dgsEditor.Canvas)
end
-----------------------------------------------------Element management
function dgsEditorCreateElement(dgsType,...)
	local arguments = {...}
--	if #arguments == 0 then
	local createdElement
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
			:setProperty("ignoreTitle",true)
	elseif dgsType == "dgs-dxtabpanel" then
		createdElement = dgsEditor.Canvas:dgsTabPanel(0,0,100,100,false)
	end
	createdElement.isCreatedByEditor = true
	--When clicking the element
	createdElement:on("dgsMouseClickDown",function()
		dgsEditorControllerDetach()
		--When clicked the element, turn it into "operating element"
		dgsEditor.Controller.visible = true	--Make the controller visible
		dgsEditorControllerAttach(createdElement)
	end)
	--Set the parent to the element
	createdElement:on("dgsMouseClickUp",function()
		local source = dgsGetInstance(dgsEditor.Controller.BoundChild)
		local parent = dgsEditor.Canvas
		for _, element in pairs(dgsEditor.ElementList) do
			if dgsIsMouseWithinGUI(element.dgsElement) then
				if source.dgsElement ~= element.dgsElement and source.parent ~= element.dgsElement then
					if table.find(DGSParents,element:getType()) then
						parent = element
						break
					end
				end
			end
		end
		dgsEditorControllerDetach()
		source:setParent(parent)
		dgsEditorControllerAttach(source)
	end)
	--Record the element
	dgsEditor.ElementList[createdElement.dgsElement] = createdElement
end

function dgsEditorControllerAttach(targetElement)
	--Save position/size
	local pos,size = targetElement.position,targetElement.size
	--Record the parent element of operating element
	dgsEditor.Controller.BoundParent = targetElement:getParent().dgsElement
	--Record the operating element as the child element of controller (to proxy the positioning and resizing of operating element with controller)
	dgsEditor.Controller.BoundChild = targetElement.dgsElement
	--Set the parent element
	dgsEditor.Controller:setParent(dgsEditor.Canvas)
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
	--Get the instance of parent (controller's & operating element's)
	local p = dgsGetInstance(dgsEditor.Controller.BoundParent)
	--If the operating element exists
	if dgsEditor.Controller.BoundChild then
		--Get the instance of child (controller's) [the operating element]
		local c = dgsGetInstance(dgsEditor.Controller.BoundChild)
		--Use the position/size/parent of the controller
		c:setParent(p)
		c.position.relative = dgsEditor.Controller.position.relative
		c.position = dgsEditor.Controller.position
		c.size.relative = dgsEditor.Controller.size.relative
		c.size = dgsEditor.Controller.size
	end
	dgsEditorPropertiesMenuDetach()
end

local ctrlSize = 10
--Controller Create Function  
function dgsEditorCreateController(theCanvas)
	--Declear the 8 controlling circles
	local RightCenter,RightTop,CenterTop,LeftTop,LeftCenter,LeftBottom,CenterBottom,RightBottom	
	local Ring = dgsCreateCircle(0.45,0.3,360)	--circles
	dgsCircleSetColorOverwritten(Ring,false)
	local Line = theCanvas:dgsLine(0,0,0,0,false,2,tocolor(255,0,0,255))	--the highlight line (controller)
		:setProperty("childOutsideHit",true)
		:setProperty("isController",true)
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
		:setProperty("image",{Ring,Ring,Ring})
		:setProperty("color",{predefColors.hlightN,predefColors.hlightH,predefColors.hlightC})
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
	theCanvas:on("dgsMouseClickDown",function()
		Line.visible = false
		dgsEditorControllerDetach()
	end)
	return Line
end

function dgsEditorPropertiesMenuAttach(targetElement)
	for i, property in pairs(DGSPropertiesList[targetElement:getType()]) do
		local row = dgsEditor.WidgetPropertiesMenu:addRow(row,property)
		dgsEditor.WidgetPropertiesMenu:setRowAsSection(row,true)
		dgsEditor.WidgetPropertiesMenu:setItemData(i,1,property)
		if property == "alignment" then
			local text = {"alignX","alignY"}
			for a, align in pairs(targetElement[property]) do
				local rowSection = dgsEditor.WidgetPropertiesMenu:addRow(rowSection,text[a])
				local combobox = dgsEditor.WidgetPropertiesMenu
					:dgsComboBox(0,5,150,20,false)
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
				for i, alignment in pairs(alignments[a]) do
					combobox:addItem(alignment)
					if alignment == align then
						combobox:setSelectedItem(i)
					end
				end
				combobox:on("dgsComboBoxSelect",function(row)
					targetElement:setProperty(property, combobox:getItemText(row))
				end)
				combobox:on("dgsMouseClick",function()
					source:bringToFront() -- no effect, maybe bring to front item list
				end)
			end
		elseif property == "color" then
			colorEdit = {}
			imageColor = {}
			for c, color in pairs(targetElement[property]) do
				local rowSection = dgsEditor.WidgetPropertiesMenu:addRow(rowSection,colors[c])
				local color = {fromcolor(color,true)}
				local bind = {"R","G","B","A"}
				colorEdit[rowSection] = {}
				for i,v in pairs(color) do
					colorEdit[rowSection][i] = dgsEditor.WidgetPropertiesMenu
						:dgsEdit(i*35-35,5,30,20,v,false)
						:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
						:on("dgsTextChange",function()
							local tempColor = {}
							local color = 1
							for _, tableEdits in pairs(colorEdit) do
								tempColor[color] = {}
								for e, edit in pairs(tableEdits) do
									local arg = tonumber(edit:getText())
									if not arg then arg = 0 end
									if arg > 255 then return edit:setText("255") end
									if arg < 0 then return edit:setText("0") end
									tempColor[color][e] = arg
								end
								color = color+1
							end
							if tempColor[1] and tempColor[2] and tempColor[3] then
								local r1,g1,b1,a1 = unpack(tempColor[1])
								local r2,g2,b2,a2 = unpack(tempColor[2])
								local r3,g3,b3,a3 = unpack(tempColor[3])
								if r1 and g1 and b1 and a1 and r2 and g2 and b2 and a2 and r3 and g3 and b3 and a3 then
									targetElement:setProperty(property, {tocolor(r1,g1,b1,a1),tocolor(r2,g2,b2,a2),tocolor(r3,g3,b3,a3)})
									if #imageColor == 3 then
										imageColor[1]:setProperty("color",tocolor(r1,g1,b1,a1))
										imageColor[2]:setProperty("color",tocolor(r2,g2,b2,a2))
										imageColor[3]:setProperty("color",tocolor(r3,g3,b3,a3))
									end
								end
							end
						end)
					colorEdit[rowSection][i]:setMaxLength(3)
						:setWhiteList("[^0-9]")
					if i < 4 then
						local label = dgsEditor.WidgetPropertiesMenu
							:dgsLabel(i*35-5,5,5,20,",")
							:setProperty("alignment",{"left","bottom"})
							:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
					end
				end
				local button = dgsEditor.WidgetPropertiesMenu
					:dgsButton(140,5,20,20,"+",false)
					:setProperty("alignment",{"center","center"})
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
					:on("dgsMouseClickUp",function()
						dgsEditor.WidgetColorMain.visible = true
						local x,y = source:getPosition(false,true)
						local w,h = unpack(source.size)
						dgsEditor.WidgetColorMain.position.x = x+w-dgsEditor.WidgetColorMain.size.w
						dgsEditor.WidgetColorMain.position.y = y+h+5
						dgsEditor.WidgetColorMain:bringToFront()
						local tempColor = {}
						for e, edit in pairs(colorEdit[source.attachedToGridList[2]]) do
							tempColor[e] = tonumber(edit:getText())
							edit:bindToColorPicker(dgsEditor.ColorPicker,"RGB",bind[e])
						end
						local r,g,b,a = unpack(tempColor)
						dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
					end)
				local r,g,b,a = unpack(color)
				imageColor[c] = dgsEditor.WidgetPropertiesMenu
					:dgsImage(0,25,160,5,_,false,tocolor(r,g,b,a))
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
			end
		elseif property == "colorCoded" then
			local switch = dgsEditor.WidgetPropertiesMenu
				:dgsSwitchButton(10,5,50,20,"","",targetElement[property])
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
				:on("dgsSwitchButtonStateChange",function(state)
					targetElement:setProperty(property,state)
				end)
		elseif property == "text" then
			local edit = dgsEditor.WidgetPropertiesMenu
				:dgsEdit(10,5,150,20,targetElement[property],false)
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
				:on("dgsEditAccepted",function()
					targetElement:setProperty(property, source:getText())
				end)
		elseif property == "textColor" then
			local color = {fromcolor(targetElement[property],true)}
			local bind = {"R","G","B","A"}
			textColorEdit = {}
			for i,v in pairs(color) do
				textColorEdit[i] = dgsEditor.WidgetPropertiesMenu
					:dgsEdit(i*35-35+10,5,30,20,v,false)
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
					:on("dgsTextChange",function()
						local tempColor = {}
						for e, edit in pairs(textColorEdit) do
							local arg = tonumber(edit:getText())
							if not arg then arg = 0 end
							if arg > 255 then return edit:setText("255") end
							if arg < 0 then return edit:setText("0") end
							tempColor[e] = arg
						end
						if tempColor then
							local r,g,b,a = unpack(tempColor)
							if r and g and b and a then
								targetElement:setProperty(property, tocolor(r,g,b,a))
								if imageTextColor then
									imageTextColor:setProperty("color",tocolor(r,g,b,a))
								end
							end
						end
					end)	
				textColorEdit[i]:setMaxLength(3)
					:setWhiteList("[^0-9]")
				if i < 4 then
					local label = dgsEditor.WidgetPropertiesMenu
						:dgsLabel(i*35+5,5,5,20,",")
						:setProperty("alignment",{"left","bottom"})
						:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
				end
			end
			local button = dgsEditor.WidgetPropertiesMenu
				:dgsButton(150,5,20,20,"+",false)
				:setProperty("alignment",{"center","center"})
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
				:on("dgsMouseClickUp",function()
					dgsEditor.WidgetColorMain.visible = true
					local x,y = source:getPosition(false,true)
					local w,h = unpack(source.size)
					dgsEditor.WidgetColorMain.position.x = x+w-dgsEditor.WidgetColorMain.size.w
					dgsEditor.WidgetColorMain.position.y = y+h+5
					dgsEditor.WidgetColorMain:bringToFront()
					local tempColor = {}
					for e, edit in pairs(textColorEdit) do
						tempColor[e] = tonumber(edit:getText())
						edit:bindToColorPicker(dgsEditor.ColorPicker, "RGB", bind[e])
					end
					local r,g,b,a = unpack(tempColor)
					dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
				end)
				local r,g,b,a = unpack(color)
				imageTextColor = dgsEditor.WidgetPropertiesMenu
					:dgsImage(10,25,160,5,_,false,tocolor(r,g,b,a))
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
		elseif property == "textSize" then
			local text = {"scaleX","scaleY"}
			local edit = {}
			for i, scale in pairs(targetElement[property]) do
				local rowSection = dgsEditor.WidgetPropertiesMenu:addRow(rowSection,text[i])
				edit[i] = dgsEditor.WidgetPropertiesMenu
					:dgsEdit(0,5,50,20,scale,false)
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
					:on("dgsEditAccepted",function()
						targetElement:setProperty(property,{tonumber(edit[1]:getText()),tonumber(edit[2]:getText())})
					end)
			end
		elseif property == "font" then
			local combobox = dgsEditor.WidgetPropertiesMenu
				:dgsComboBox(10,5,150,20,false)
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
			for r, font in pairs(fonts) do
				combobox:addItem(font)
				if font == targetElement:getFont() then
					combobox:setSelectedItem(r)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				targetElement:setProperty("font", combobox:getItemText(row))
			end)
		elseif property == "shadow" then
			if targetElement[property] then
				local button = dgsEditor.WidgetPropertiesMenu
					:dgsButton(10,5,150,20,"remove shadow",false)
					:setProperty("alignment",{"center","center"})
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
					:on("dgsMouseClickDown",function()
						targetElement:setProperty(property,nil)
						dgsEditorPropertiesMenuDetach()
						dgsEditorPropertiesMenuAttach(targetElement)
					end)
				local text = {"offsetX","offsetY","color","outline"}
				local shadowEdit = {}
				for i, value in pairs(targetElement[property]) do
					local rowSection = dgsEditor.WidgetPropertiesMenu:addRow(rowSection,text[i])
					if text[i] == "color" then
						local color = {fromcolor(value,true)}
						local bind = {"R","G","B","A"}
						shadowColorEdit = {}
						for i, v in pairs(color) do
							shadowColorEdit[i] = dgsEditor.WidgetPropertiesMenu
								:dgsEdit(i*35-35,5,30,20,v,false)
								:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
								:on("dgsTextChange",function()
									local tempColor = {}
									for e, edit in pairs(shadowColorEdit) do
										local arg = tonumber(edit:getText())
										if not arg then arg = 0 end
										if arg > 255 then return edit:setText("255") end
										if arg < 0 then return edit:setText("0") end
										tempColor[e] = arg
									end
									if tempColor then
										local r,g,b,a = unpack(tempColor)
										if r and g and b and a and shadowEdit[4] then
											targetElement:setProperty(property,{tonumber(shadowEdit[1]:getText()),tonumber(shadowEdit[2]:getText()),tocolor(r,g,b,a),shadowEdit[4]:getState()})
											if imageShadowColor then
												imageShadowColor:setProperty("color",tocolor(r,g,b,a))
											end
										end
									end
								end)
							shadowColorEdit[i]:setMaxLength(3)
								:setWhiteList("[^0-9]")
							if i < 4 then
								local label = dgsEditor.WidgetPropertiesMenu
									:dgsLabel(i*35-5,5,5,20,",")
									:setProperty("alignment",{"left","bottom"})
									:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
							end
						end
						local r,g,b,a = unpack(color)
						imageShadowColor = dgsEditor.WidgetPropertiesMenu
							:dgsImage(0,25,160,5,_,false,tocolor(r,g,b,a))
							:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
						local button = dgsEditor.WidgetPropertiesMenu
							:dgsButton(140,5,20,20,"+",false)
							:setProperty("alignment",{"center","center"})
							:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
							:on("dgsMouseClickUp",function()
								dgsEditor.WidgetColorMain.visible = true
								local x,y = source:getPosition(false,true)
								local w,h = unpack(source.size)
								dgsEditor.WidgetColorMain.position.x = x+w-dgsEditor.WidgetColorMain.size.w
								dgsEditor.WidgetColorMain.position.y = y+h+5
								dgsEditor.WidgetColorMain:bringToFront()
								local tempColor = {}
								for e, edit in pairs(shadowColorEdit) do
									tempColor[e] = tonumber(edit:getText())
									edit:bindToColorPicker(dgsEditor.ColorPicker, "RGB", bind[e])
								end
								local r,g,b,a = unpack(tempColor)
								dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
							end)
					elseif text[i] == "outline" then
						shadowEdit[i] = dgsEditor.WidgetPropertiesMenu
							:dgsSwitchButton(0,5,50,20,"","",targetElement[property])
							:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
							:on("dgsSwitchButtonStateChange",function(state)
								local tempColor = {}
								for e, edit in pairs(shadowColorEdit) do
									local arg = tonumber(edit:getText())
									if not arg then arg = 0 end
									if arg > 255 then return edit:setText("255") end
									if arg < 0 then return edit:setText("0") end
									tempColor[e] = arg
								end
								if tempColor then
									local r,g,b,a = unpack(tempColor)
									if r and g and b and a then
										targetElement:setProperty(property,{tonumber(shadowEdit[1]:getText()),tonumber(shadowEdit[2]:getText()),tocolor(r,g,b,a),state})
									end
								end
							end)
					else
					shadowEdit[i] = dgsEditor.WidgetPropertiesMenu
						:dgsEdit(0,5,50,20,value,false)
						:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,2)
						:on("dgsEditAccepted",function()
							local tempColor = {}
							for e, edit in pairs(shadowColorEdit) do
								local arg = tonumber(edit:getText())
								if not arg then arg = 0 end
								if arg > 255 then return edit:setText("255") end
								if arg < 0 then return edit:setText("0") end
								tempColor[e] = arg
							end
							if tempColor then
								local r,g,b,a = unpack(tempColor)
								if r and g and b and a then
									targetElement:setProperty(property,{tonumber(shadowEdit[1]:getText()),tonumber(shadowEdit[2]:getText()),tocolor(r,g,b,a),shadowEdit[4]:getState()})
								end
							end
						end)
					end
				end
			else
				local button = dgsEditor.WidgetPropertiesMenu
					:dgsButton(10,5,150,20,"add shadow",false)
					:setProperty("alignment",{"center","center"})
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
					:on("dgsMouseClickDown",function()
						targetElement:setProperty(property,{1,1,tocolor(0,0,0,255),true})
						dgsEditorPropertiesMenuDetach()
						dgsEditorPropertiesMenuAttach(targetElement)
					end)
			end
		elseif property == "wordBreak" then
			local switch = dgsEditor.WidgetPropertiesMenu
				:dgsSwitchButton(10,5,50,20,"","",targetElement[property])
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
				:on("dgsSwitchButtonStateChange",function(state)
					targetElement:setProperty(property,state)
				end)
		end
	end
	local row = dgsEditor.WidgetPropertiesMenu:addRow(row,"")
	local button = dgsEditor.WidgetPropertiesMenu
		:dgsButton(0,5,150,20,"destroy element",false)
		:setProperty("alignment",{"center","center"})
		:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,2)
		:on("dgsMouseClickUp",function()
			dgsEditorDestroyElement()
		end)
end

function dgsEditorPropertiesMenuDetach()
	dgsEditor.WidgetPropertiesMenu:clearRow()
	for _, child in pairs(dgsEditor.WidgetPropertiesMenu.children) do
		if child:getType() ~= "dgs-dxscrollbar" then
			child:destroy()
		end
	end
	colorEdit = nil
	textColorEdit = nil
	shadowColorEdit = nil
	imageColor = nil
	imageTextColor = nil
	imageShadowColor = nil
end

-- destroy element
function dgsEditorDestroyElement()
	dgsEditorControllerDetach()
	dgsEditor.Controller.visible = false
	if dgsEditor.Controller.BoundChild then
		dgsEditor.ElementList[dgsEditor.Controller.BoundChild] = nil
		dgsGetInstance(dgsEditor.Controller.BoundChild):destroy()
		dgsEditor.Controller.BoundChild = nil
	end
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
			dgsEditorDestroyElement()
		end
	end
end
-----------------------------------------------------Start up
function startup()
	loadEditorSettings()
	checkLanguages()
	setCurrentLanguage(dgsEditorSettings.UsingLanguage)
end
startup()
