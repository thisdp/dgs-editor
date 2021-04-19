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
	if state == "enabled" then			--If someone want to enable dgs editor
		if dgsEditorContext.state == "available" then	--First, need to be "available"
			dgsEditor.state = "enabled"					--Enabled
			dgsEditorMakeOutput(translateText({"EditorEnabled"}))
			triggerEvent("onClientDGSEditorStateChanged",resourceRoot,dgsEditor.state)
			if not dgsEditor.Created then
				loadstring(exports[dgsEditorContext.dgsResourceName]:dgsImportOOPClass())()
				dgsRootInstance:setElementKeeperEnabled(true)
				dgsRootInstance:setTranslationTable("DGSEditorLanguage",Language.UsingLanguageTable)	--Set translation dictionary whenever a new language applies
				dgsRootInstance:setAttachTranslation("DGSEditorLanguage")	--Use this dictionary
				dgsEditorCreateMainPanel()
			else
				dgsEditor.BackGround.visible = true
			end
			showCursor(true)
		end
	elseif state == "disabled" then		--If someone want to disable dgs editor
		dgsEditor.state = "disabled"	--Just disable
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
	dgsEditor.ElementList = {}	--Used to store created elements createed by user
	dgsEditor.Created = true
	dgsEditor.BackGround = dgsImage(0,0,1,1,_,true,tocolor(0,0,0,100))	--Main Background
	dgsEditor.Canvas = dgsEditor.BackGround:dgsScalePane(0.2,0.2,0.6,0.6,true,sW,sH)	--Main Canvas
	dgsEditor.Canvas.bgColor = tocolor(0,0,0,128)
	dgsEditor.WidgetMain = dgsWindow(0,0,0.18,0.5,{"DGSWidgets"},true)	--Widgets Window
		:setCloseButtonEnabled(false)
		:setSizable(false)
		:setProperty("color",tocolor(0,0,0,128))
		:setProperty("titleColor",tocolor(0,0,0,128))
		:setLayer("top")
		:setProperty("textSize",{1.3,1.3})
	
	dgsEditor.WidgetSpliter = dgsEditor.WidgetMain	--The Vertical Spliter Line
		:dgsImage(80,0,5,100,_,false,tocolor(50,50,50,200))
		
	dgsEditor.WidgetTypeList = dgsEditor.WidgetMain	--Type List
		:dgsGridList(10,0,70,200,false)
		:setProperty("rowHeight",25)
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
	dgsEditor.WidgetTypeList:addColumn("",0.9)
	dgsEditor.WidgetTypeList:addRow(_,{"Basic"})
	dgsEditor.WidgetTypeList:addRow(_,{"Plugins"})
	
	dgsEditor.WidgetList = dgsEditor.WidgetMain	--Widget List
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
		:on("dgsGridListItemDoubleClick",function(button,state,row)
			if button == "left" and state == "down" then
				local widgetID = dgsEditor.WidgetList:getItemData(row,1)
				dgsEditorCreateElement(DGSTypeReference[widgetID][1])
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
	dgsEditor.Controller = dgsEditorCreateController(dgsEditor.Canvas)
end
-----------------------------------------------------Element management
function dgsEditorCreateElement(dgsType,...)
	local arguments = {...}
--	if #arguments == 0 then
	local createdElement
	if dgsType == "dgs-dxbutton" then
		createdElement = dgsEditor.Canvas:dgsButton(0,0,50,30,"Button",false)
	elseif dgsType == "dgs-dximage" then
		createdElement = dgsEditor.Canvas:dgsImage(0,0,50,30,_,false)
	end
	createdElement.isCreatedByEditor = true
	createdElement:on("dgsMouseClickDown",function()	--When clicking the element
		dgsEditorControllerDetach()
		--When clicked the element, turn it into "operating element"
		dgsEditor.Controller.visible = true	--Make the controller visible
		dgsEditorControllerAttach(source)
	end)
	table.insert(dgsEditor.ElementList,source)	--Record the element
end

function dgsEditorControllerAttach(targetElement)
	local pos,size = targetElement.position,targetElement.size	--Save position/size
	dgsEditor.Controller.BoundParent = targetElement:getParent().dgsElement	--Record the parent element of operating element
	dgsEditor.Controller.BoundChild = targetElement.dgsElement	--Record the operating element as the child element of controller (to proxy the positioning and resizing of operating element with controller)
	dgsEditor.Controller:setParent(targetElement:getParent())	--Set the parent element
	targetElement:setParent(dgsEditor.Controller)	--Set the child element
	dgsEditor.Controller.position = pos	--Use operating element's position
	dgsEditor.Controller.size = size	--Use operating element's size
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
end

function dgsEditorControllerDetach()
	local p = dgsGetInstance(dgsEditor.Controller.BoundParent)	--Get the instance of parent (controller's & operating element's)
	if dgsEditor.Controller.BoundChild then	--If the operating element exists
		local c = dgsGetInstance(dgsEditor.Controller.BoundChild)	--Get the instance of child (controller's) [the operating element]
		--Use the position/size/parent of the controller
		c:setParent(p)
		c.position.relative = dgsEditor.Controller.position.relative
		c.position = dgsEditor.Controller.position
		c.size.relative = dgsEditor.Controller.size.relative
		c.size = dgsEditor.Controller.size
	end
end

local ctrlSize = 10
function dgsEditorCreateController(theCanvas)	--Create the controller
	local RightCenter,RightTop,CenterTop,LeftTop,LeftCenter,LeftBottom,CenterBottom,RightBottom	--Define the 8 controlling circles
	local Ring = dgsCreateCircle(0.45,0.3,360)	--circles
	local Line = theCanvas:dgsLine(0,0,0,0,false,2,tocolor(255,0,0,255))	--the highlight line (controller)
		:setProperty("hitoutofparent",true)
		:setProperty("isController",true)
	addEventHandler("onDgsMouseClickDown",root,function(button,state,mx,my)	--When clicking the element
		if dgsGetInstance(source) == dgsGetInstance(dgsEditor.Controller.BoundChild) then	--check whether the clicked element is handled by the controller
			--Save the position, size and mouse position
			dgsEditor.Controller.startDGSPos = Vector2(dgsEditor.Controller:getPosition(false))
			dgsEditor.Controller.startDGSSize = Vector2(dgsEditor.Controller:getSize(false))
			dgsEditor.Controller.startMousePos = Vector2(mx,my)
		end
	end)
	addEventHandler("onDgsMouseDrag",root,function(mx,my)	--When attempt to moving the element
		if dgsGetInstance(source) == dgsGetInstance(dgsEditor.Controller.BoundChild) then	--check whether the clicked element is handled by the controller
			if dgsEditor.Controller.startMousePos then	--Is the element is able to move?
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
	local RightCenter = Line:dgsImage(-ctrlSize/2,0,ctrlSize,ctrlSize,Ring,false)
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
	local CenterTop = Line:dgsImage(0,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
	local LeftTop = Line:dgsImage(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
	local LeftCenter = Line:dgsImage(-ctrlSize/2,0,ctrlSize,ctrlSize,Ring,false)
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
	local LeftBottom = Line:dgsImage(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
	local CenterBottom = Line:dgsImage(0,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
	local RightBottom = Line:dgsImage(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
	local RightTop = Line:dgsImage(-ctrlSize/2,-ctrlSize/2,ctrlSize,ctrlSize,Ring,false)
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
-----------------------------------------------------Start up
function startup()
	loadEditorSettings()
	checkLanguages()
	setCurrentLanguage(dgsEditorSettings.UsingLanguage)
end
startup()