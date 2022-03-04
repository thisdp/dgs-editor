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

	dgsEditor.WidgetPropertiesMenu = dgsEditor.WidgetPropertiesMain --Properties List
		:dgsGridList(0,0,1,1,true)
		:setProperty("columnHeight",0)
		:setProperty("rowHeight",30)
		:setProperty("sortEnabled",false)
		:setProperty("scrollBarState",{nil,false})

	dgsEditor.WidgetPropertiesMenu:addColumn("",0.1)	-- description button?
	dgsEditor.WidgetPropertiesMenu:addColumn("",0.3)	-- property name
	dgsEditor.WidgetPropertiesMenu:addColumn("",0.6)	-- edit

	dgsEditor.WidgetColorMain = dgsWindow(0,0,400,300,{"DGSColorPicker"},false)	--Color Main
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setMovable(false)
		:setParent(dgsEditor.BackGround)
		:setProperty("shadow",{1,1,0xFF000000})
		:setProperty("titleColorBlur",false)
		:setProperty("color",tocolor(30,30,30,200))
		:setProperty("titleColor",tocolor(30,30,30,200))
		:setProperty("textSize",{1.3,1.3})
		:setParent(dgsEditor.BackGround)

	dgsEditor.ColorPicker = dgsEditor.WidgetColorMain		--Color Picker
		:dgsColorPicker("HSVRing",10,10,200,200,false)
	
	dgsEditor.ColorPicker:dgsComponentSelector(225,10,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker, "RGB", "R")
	dgsEditor.ColorPicker:dgsComponentSelector(225,50,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker, "RGB", "G")
	dgsEditor.ColorPicker:dgsComponentSelector(225,90,100,25,true,false)
		:bindToColorPicker(dgsEditor.ColorPicker, "RGB", "B")
	
	dgsEditor.BackGround:on("dgsMouseClickDown",function()
		if source ~= dgsEditor.WidgetColorMain and source ~= dgsEditor.ColorPicker then
			dgsEditor.WidgetColorMain.visible = false
			dgsEditor.ColorPicker.childRow = nil
			if colorEdit then
				for _, tableEdits in pairs(colorEdit) do
					for e, edit in pairs(tableEdits) do
						if edit:getProperty("bindColorPicker") then
							edit:unbindFromColorPicker()	--detach
						end
					end
				end
			end
			if textColorEdit then
				for e, edit in pairs(textColorEdit) do
					if edit:getProperty("bindColorPicker") then
						edit:unbindFromColorPicker()		--detach
					end
				end
			end
		end
	end,true)

	dgsEditor.WidgetColorMain.visible = false
	
	dgsEditor.Controller = dgsEditorCreateController(dgsEditor.Canvas)
	--dgsEditor.ContextMenu = dgsEditorCreateContextMenu(dgsEditor.Canvas) --Context Menu
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
	elseif dgsType == "dgs-dxtabpanel" then
		createdElement = dgsEditor.Canvas:dgsTabPanel(0,0,100,100,false)
	end
	createdElement.isCreatedByEditor = true
	--When clicking the element
	createdElement:on("dgsMouseClickDown",function()
		dgsEditorControllerDetach()
		--When clicked the element, turn it into "operating element"
		dgsEditor.Controller.visible = true	--Make the controller visible
		dgsEditorControllerAttach(source)
	end)
	--Record the element
	dgsEditor.ElementList[dgsGetInstance(createdElement)] = source
end

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
	Line.controller = {	--Record the 8 circle controller
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
	theCanvas:on("dgsMouseClickDown",function()	--When clicking the canvas, hide the controller
		Line.visible = false
		dgsEditorControllerDetach()
	end)
	return Line
end

function dgsEditorPropertiesMenuAttach(targetElement)
	for i, property in pairs(DGSPropertiesList[targetElement:getType()]) do
		local row = dgsEditor.WidgetPropertiesMenu:getRowCount()+1
		dgsEditor.WidgetPropertiesMenu:addRow(row,"",property)
		dgsEditor.WidgetPropertiesMenu:setItemData(i,1,property)
		if property == "alignment" then
			dgsEditor.WidgetPropertiesMenu:setRowAsSection(row,true)
			local text = {"alignX","alignY"}
			for a, align in pairs(dgsGetInstance(dgsEditor.Controller.BoundChild):getProperty(property)) do
				local rowSection = dgsEditor.WidgetPropertiesMenu:getRowCount()+1
				dgsEditor.WidgetPropertiesMenu:addRow(rowSection,"",text[a])
				local combobox = dgsEditor.WidgetPropertiesMenu
					:dgsComboBox(0,0,150,20,false)
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,3)
				for i, alignment in pairs(alignments[a]) do
					combobox:addItem(alignment)
					if alignment == align then
						combobox:setSelectedItem(i)
					end
				end
				combobox:on("dgsComboBoxSelect",function(row)
					dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, combobox:getItemText(row))
				end)
				combobox:on("dgsMouseClick",function()
					source:bringToFront() -- no effect, maybe bring to front item list
				end)
				combobox:setPosition(0,5,false)
			end
		elseif property == "color" then
			dgsEditor.WidgetPropertiesMenu:setRowAsSection(row,true)
			colorEdit = {}
			for c, color in pairs(dgsGetInstance(dgsEditor.Controller.BoundChild):getProperty(property)) do
				local rowSection = dgsEditor.WidgetPropertiesMenu:getRowCount()+1
				dgsEditor.WidgetPropertiesMenu:addRow(rowSection,"",colors[c])
				local color = {fromcolor(color,true)}
				local bind = {"R","G","B","A"}
				colorEdit[rowSection] = {}
				for i,v in pairs(color) do
					colorEdit[rowSection][i] = dgsEditor.WidgetPropertiesMenu
						:dgsEdit(0,0,30,20,false)
						:setText(v)
						:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,3)
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
									dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, {tocolor(r1,g1,b1,a1),tocolor(r2,g2,b2,a2),tocolor(r3,g3,b3,a3)})
								end
							end
						end)
					colorEdit[rowSection][i]:setPosition(i*35-35,5,false)
						:setMaxLength(3)
						:setWhiteList("[^0-9]")
				end
				local button = dgsEditor.WidgetPropertiesMenu
					:dgsButton(0,0,20,20)
					:setText("+")
					:setProperty("alignment",{"center","center"})
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,rowSection,3)
					:on("dgsMouseClickUp",function()
						dgsEditor.WidgetColorMain.visible = true
						local x,y = source:getPosition(false,true)
						local w,h = unpack(source.size)
						dgsEditor.WidgetColorMain.position.x = x+w-dgsEditor.WidgetColorMain.size.w
						dgsEditor.WidgetColorMain.position.y = y+h
						dgsEditor.WidgetColorMain:bringToFront()
						dgsEditor.ColorPicker.childRow = source:getProperty("attachedToGridList")[2]
						local tempColor = {}
						for e, edit in pairs(colorEdit[dgsEditor.ColorPicker.childRow]) do
							tempColor[e] = tonumber(edit:getText())
							edit:bindToColorPicker(dgsEditor.ColorPicker,"RGB",bind[e])
						end
						local r,g,b,a = unpack(tempColor)
						dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
					end)
				button:setPosition(140,5,false)
			end
		elseif property == "colorCoded" then
			local switch = dgsEditor.WidgetPropertiesMenu
				:dgsSwitchButton(0,0,50,20,"","",dgsGetInstance(dgsEditor.Controller.BoundChild):getProperty(property))
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,3)
				:on("dgsMouseClickDown",function()
					dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, not source:getState())
				end)
			switch:setPosition(0,5,false)
		elseif property == "text" then
			local edit = dgsEditor.WidgetPropertiesMenu
				:dgsEdit(0,0,150,20,false)
				:setPlaceHolder(dgsGetInstance(dgsEditor.Controller.BoundChild):getProperty(property))
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,3)
				:on("dgsEditAccepted",function()
					dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, source:getText())
					source:setText("")
					source:setPlaceHolder(source:getText())
					source:blur()
				end)
			edit:setPosition(0,5,false)
		elseif property == "textColor" then
			local color = dgsGetInstance(dgsEditor.Controller.BoundChild):getProperty(property)
			local color = {fromcolor(color,true)}
			local bind = {"R","G","B","A"}
			textColorEdit = {}
			for i,v in pairs(color) do
				textColorEdit[i] = dgsEditor.WidgetPropertiesMenu
					:dgsEdit(0,0,30,20,false)
					:setText(v)
					:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,3)
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
								dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, tocolor(r,g,b,a))
							end
						end
					end)
				textColorEdit[i]:setPosition(i*35-35,5,false)
					:setMaxLength(3)
					:setWhiteList("[^0-9]")
			end
			local button = dgsEditor.WidgetPropertiesMenu
				:dgsButton(0,0,20,20)
				:setText("+")
				:setProperty("alignment",{"center","center"})
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,3)
				:on("dgsMouseClickUp",function()
					dgsEditor.WidgetColorMain.visible = true
					local x,y = source:getPosition(false,true)
					local w,h = unpack(source.size)
					dgsEditor.WidgetColorMain.position.x = x+w-dgsEditor.WidgetColorMain.size.w
					dgsEditor.WidgetColorMain.position.y = y+h
					dgsEditor.WidgetColorMain:bringToFront()
					dgsEditor.ColorPicker.childRow = source:getProperty("attachedToGridList")[2]
					local tempColor = {}
					for e, edit in pairs(textColorEdit) do
						tempColor[e] = tonumber(edit:getText())
						edit:bindToColorPicker(dgsEditor.ColorPicker, "RGB", bind[e])
					end
					local r,g,b,a = unpack(tempColor)
					dgsEditor.ColorPicker:setColor(r,g,b,a,"RGB")
				end)
			button:setPosition(140,5,false)
		elseif property == "font" then
			local combobox = dgsEditor.WidgetPropertiesMenu
				:dgsComboBox(0,0,150,20,false)
				:attachToGridList(dgsEditor.WidgetPropertiesMenu.dgsElement,row,3)
			for r, font in pairs(fonts) do
				combobox:addItem(font)
				if font == dgsGetInstance(dgsEditor.Controller.BoundChild):getFont() then
					combobox:setSelectedItem(r)
				end
			end
			combobox:on("dgsComboBoxSelect",function(row)
				dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty("font", combobox:getItemText(row))
			end)
			combobox:setPosition(0,5,false)
		end
	end
	local row = dgsEditor.WidgetPropertiesMenu:getRowCount()+1
	dgsEditor.WidgetPropertiesMenu:addRow(row,"","destroy")
	dgsEditor.WidgetPropertiesMenu:setItemData(row,1,"destroy")
	dgsEditor.WidgetPropertiesMenu:on("dgsGridListItemDoubleClick",function(btn,state,item)
		if state ~= "down" then return end
		if item ~= row then return end
		dgsEditorDestroyElement()
	end)
end

function dgsEditorPropertiesMenuDetach()
	dgsEditor.WidgetPropertiesMenu:clearRow()
	for _, child in pairs(dgsEditor.WidgetPropertiesMenu.children) do
		if child:getType() ~= "dgs-dxscrollbar" then
			--child:destroy() -- error move controller
		end
	end
end

-- Context Menu
function dgsEditorContextMenuAttach(targetElement)
	dgsEditor.ContextMenu.position = {dgsRootInstance:getCursorPosition(targetElement)}
	local rows = #DGSPropertiesList[targetElement:getType()]
	if rows > 5 then rows = 5 end
	dgsEditor.ContextMenu.size.h = 25*rows
	for i, property in pairs(DGSPropertiesList[targetElement:getType()]) do
		dgsEditor.ContextMenu:addRow(i,property)
		dgsEditor.ContextMenu:setItemData(i,1,property)
	end
	dgsEditor.ContextMenu:bringToFront()
end

function dgsEditorContextMenuDetach()
	dgsEditor.ContextMenu:clearRow()
end

function dgsEditorCreateContextMenu(theCanvas)
	local Gridlist = theCanvas:dgsGridList(0,0,100,25*#DGSPropertiesList,false)
		:setProperty("columnHeight",0)
		:setProperty("rowHeight",25)
		:setProperty("sortEnabled",false)
		:setProperty("scrollBarState",{nil,false})
		:setProperty("scrollBarThick",10)
		:on("dgsGridListItemDoubleClick",function(button,state,row)
			if button == "left" and state == "down" then
				dgsEditor.ContextMenu.visible = false
				dgsEditorCreateEditProperty(source:getItemData(row,1))
			end
		end)

	Gridlist:addColumn("",1)

	Gridlist.visible = false
	theCanvas:on("dgsMouseClickDown",function()
		Gridlist.visible = false
		dgsEditorContextMenuDetach()
	end)
	return Gridlist
end

function dgsEditorCreateEditProperty(property)
	if property == "Set text" then
		local property = "text"
		local edit = dgsEditor.Canvas:dgsEdit(0,0,100,25,false)
			:setPlaceHolder("text")
			:on("dgsEditAccepted",function()
				local value = source:gsub(getText(),"%s+","")
				if value == "true" then value = true end
				if value == "false" then value = false end
				dgsGetInstance(dgsEditor.Controller.BoundChild):setProperty(property, value)
				source:destroy()
			end)
		edit.position = dgsEditor.ContextMenu.position
	elseif property == "Destroy" then
		dgsEditor.Controller.visible = false
		dgsEditorControllerDetach()
		dgsGetInstance(dgsEditor.Controller.BoundChild):destroy()
	end
end

-- destroy element
function dgsEditorDestroyElement()
	dgsEditorControllerDetach()
	dgsEditor.Controller.visible = false
	if dgsEditor.Controller.BoundChild then
		dgsGetInstance(dgsEditor.Controller.BoundChild):destroy()
		dgsEditor.ElementList[dgsEditor.Controller.BoundChild] = nil
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