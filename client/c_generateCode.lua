--[[
	Author:		YappiDoor, thisdp, R3mp
	Note:		Generate the output code from the created elements
]]

gDecimalPlaces = 2
gNumberFormat = "%."..tostring(gDecimalPlaces).."f"
--exceptions for properties
gExceptions = {"absPos","absSize","rltPos","rltSize","isHorizontal","state"}
gTableName = "dgs"

function generateCode()
	local code = ""
	variables = {}
	
	if #dgsEditor.Textures > 0 then
		local prefix = "\ntexture = {\n"

		local count = 1
		for i, texture in pairs(dgsEditor.Textures) do
			local name, url = unpack(dgsGetProperty(texture, "textureInfo"))
			local texture = dgsRemoteImageGetTexture(texture)
			if url and texture and isElement(texture) then
				prefix = prefix.."    ["..count.."] = {dgsCreateRemoteImage('"..url.."')},\n"
				count = count + 1
			end
		end
		local prefix = prefix.."}\n"

		code = prefix..code
	end

	for dgsElement, element in pairs(dgsEditor.ElementList) do
		if element.isCreatedByEditor and not element.editorParent then
			local c = generateCode_process(element)
			element.editorParent = false

			if c and c ~= "" then
				local count = 1
				while string.sub(c, -string.len("\n")) == "\n" do
					c = string.sub(c, 0, #c - string.len("\n"))

					count = count + 1
					if count > 10 then
						break
					end
				end

				-- between each high level (screen) element
				code = code..c..(i == #dgsEditor.ElementList and "" or "\n\n")
			end
		end
	end

	if table.count(variables) > 0 then
		local prefix = gTableName.." = {\n"

		for type, _ in pairs(variables) do
			prefix = prefix.."    "..type.." = {},\n"
		end
		local prefix = prefix.."}\n"

		code = prefix..code
	end	

	return code
end

function generateCode_process(element,parent,parentType)
	local code = ""

	local elementType = element:getType():sub(7)
	if not variables[elementType] then
		variables[elementType] = 1
	end

	code = generateCode_element(element,parent,parentType) --[[.. "\n"]]

	local c = element.children

	if c and #c > 0 then
		local done = false

		for i, child in ipairs(c) do
			if child and child == dgsEditor.Controller then
				child = dgsGetInstance(dgsEditor.Controller.BoundChild)
			end

			if child and child.isCreatedByEditor then
				if not done then
					code = code.."\n"
					if i == #c then
						done = true
					end
				end
				child.editorParent = true
				code = code..generateCode_process(child,variables[elementType]-1,elementType)
			end
		end

		if done then
			code = code.."\n"
		end
	end

	return code
end

function generateCode_element(element,parent,parentType)
	local elementType = element:getType():sub(5)

	if generateCodeWidget[elementType] then
		local code = "\n"..generateCodeWidget[elementType](element, generateCode_common(element,elementType:sub(3),parent,parentType))
		return code
	end

	return ""
end

function generateCode_common(element,elementType,parent,parentType)
	local common = {}

	local variable = variables[elementType]
	common.variable = gTableName.."."..elementType.."["..variable.."]"
	variables[elementType] = variable + 1

	local text = element:getText()
	if text then
		common.text = text:gsub("\n", "\\n"):gsub("\"", "\\\"") or ""
	else
		common.text = ""
	end

	if parent and parentType then
		common.parent = ", "..gTableName.."."..parentType.."["..parent.."]"..")"
	else
		common.parent = ")"
	end

	local properties = element.dgsEditorPropertyList -- property list
	common.propertiesString = ""

	if properties then 
		for property, value in pairs(properties) do
			if value ~= nil and not table.find(gExceptions,property) and not (elementType == "image" and property == "image") then
				local propertyValues = unpack(dgsGetRegisteredProperties(element:getType(),true)[property])
				-- Find color argument
				if type(propertyValues) ~= "table" then
					if table.find(dgsListPropertyTypes(propertyValues),"Color") then
						local r,g,b,a = fromcolor(value,true)
						value = "tocolor("..r..", "..g..", "..b..", "..a..")"
					end
				end
				if type(propertyValues) == "table" then
					for i, v in pairs(propertyValues) do
						if type(v) ~= "table" then
							if table.find(dgsListPropertyTypes(v),"Color") then
								local r,g,b,a = fromcolor(value[i],true)
								value[i] = "tocolor("..r..", "..g..", "..b..", "..a..")"
							end
						end
					end
				end
				-- Find material argument
				if type(propertyValues) ~= "table" then
					if table.find(dgsListPropertyTypes(propertyValues),"Material") then
						value = "texture["..(element.textureID or 1).."]"
					end
				end
				if type(propertyValues) == "table" then
					for i, v in pairs(propertyValues) do
						if type(v) ~= "table" then
							if table.find(dgsListPropertyTypes(v),"Material") then
								value[i] = "texture["..(element.textureID or 1).."]"
							end
						end
					end
				end
				local value = inspect(value)
				local value = value:gsub("{ ","{"):gsub(" }","}"):gsub('"tocolor','tocolor'):gsub('%)"','%)'):gsub('"texture%[',"texture%["):gsub('%]"','%]')
				common.propertiesString = common.propertiesString.."\ndgsSetProperty("..common.variable..", \""..property.."\", "..value..")"
			end
		end
	end

	if dgsEditor.Controller.BoundChild == element.dgsElement then
		element = dgsEditor.Controller
	end

	local x, y = unpack(element.position)

	if element.position.relative then
		common.position = string.format(gNumberFormat..", "..gNumberFormat, x, y)
	else
		common.position = x..", "..y
	end

	local w, h = unpack(element.size)
	if element.size.relative then
		common.size = string.format(gNumberFormat..", "..gNumberFormat, w, h)
	else
		common.size = w..", "..h
	end

	common.relative = tostring(element.position.relative)

	return common
end

generateCodeWidget = {
	dxbutton = function(element, common)
		local output = common.variable.." = dgsCreateButton("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxcheckbox = function(element, common)
		local select = tostring(element:getSelected())
		local output = common.variable.." = dgsCreateCheckBox("..common.position..", "..common.size..", \""..common.text.."\", "..select..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxcombobox = function(element, common)
		local output = common.variable.." = dgsCreateComboBox("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxgridlist = function(element, common)
		local output = common.variable.." = dgsCreateGridList("..common.position..", "..common.size..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dximage = function(element, common)
		local image = element.textureID and "texture["..(element.textureID or 1).."]" or "nil"
		local output = common.variable.." = dgsCreateImage("..common.position..", "..common.size..", "..image..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxlabel = function(element, common)
		local output = common.variable.." = dgsCreateLabel("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxmemo = function(element, common)
		local output = common.variable.." = dgsCreateMemo("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxedit = function(element, common)
		local output = common.variable.." = dgsCreateEdit("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxprogressbar = function(element, common)
		local output = common.variable.." = dgsCreateProgressBar("..common.position..", "..common.size..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxradiobutton = function(element, common)
		local output = common.variable.." = dgsCreateRadioButton("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxscrollbar = function(element, common)
		local vertical = tostring(element.isHorizontal)
		local output = common.variable.." = dgsCreateScrollBar("..common.position..", "..common.size..", "..vertical..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxscrollpane = function(element, common)
		local output = common.variable.." = dgsCreateScrollPane("..common.position..", "..common.size..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxselector = function(element, common)
		local output = common.variable.." = dgsCreateSelector("..common.position..", "..common.size..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxswitchbutton = function(element, common)
		local textOn = "\""..tostring(element.textOn).."\""
		local textOff = "\""..tostring(element.textOff).."\""
		local state = tostring(element.state)
		local output = common.variable.." = dgsCreateSwitchButton("..common.position..", "..common.size..", "..textOn..", "..textOff..", "..state..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxtabpanel = function(element, common)
		local output = common.variable.." = dgsCreateTabPanel("..common.position..", "..common.size..", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxwindow = function(element, common)
		local output = common.variable.." = dgsCreateWindow("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
}
