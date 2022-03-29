loadstring(exports.dgs:dgsImportOOPClass())()

gDecimalPlaces = 2
gNumberFormat = "%."..tostring(gDecimalPlaces).."f"
--exceptions for properties
gExceptions = {"absPos","absSize","rltPos","rltSize","isHorizontal","state"}
gTableName = "dgs"

function generateCode()
	local code = ""
	variables = {}

	for dgsElement, element in pairs(dgsEditor.ElementList) do
		if element.isCreatedByEditor then
			local c = generateCode_process(element, 1)

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

function generateCode_process(element)
	local code = ""

	code = generateCode_element(element) --[[.. "\n"]]

	local c = element.children

	if c and #c > 0 then
		local done = false

		for _, child in ipairs(c) do
			if child.isCreatedByEditor then
				if not done then
					code = code.."\n"
					done = true
				end

				code = code..generateCode_process(child)
			end
		end

		if done then
			code = code.."\n"
		end
	end

	return code
end

function generateCode_element(element)
	local elementType = element:getType():sub(5)

	if generateCodeWidget[elementType] then
		local code = "\n"..generateCodeWidget[elementType](element, generateCode_common(element,elementType:sub(3)))
		return code
	end

	return ""
end

function generateCode_common(element,elementType)
	local common = {}

	if not variables[elementType] then
		variables[elementType] = 1
	end
	local variable = variables[elementType] or 0
	common.variable = gTableName.."."..elementType.."["..variable.."]"
	variables[elementType] = variable + 1

	local text = element:getText()
	if text then
		common.text = text:gsub("\n", "\\n"):gsub("\"", "\\\"") or ""
	else
		common.text = ""
	end

	if element.parent then
		common.parent = ", "..tostring(element.parent.dgsElment)..")"
	else
		common.parent = ")"
	end

	local properties = element.dgsEditorPropertyList -- property list
	common.propertiesString = ""

	if properties then 
		for property, value in pairs(properties) do
			if not table.find(gExceptions,property) then
				local propertyValues = unpack(dgsGetRegisteredProperties(element:getType(),true)[property])
				-- Find color argument
				if type(propertyValues) ~= "table" and tostring(propertyValues):find(128) then
					local r,g,b,a = fromcolor(value,true)
					value = "tocolor("..r..", "..g..", "..b..", "..a..")"
				end
				if type(propertyValues) == "table" then
					for i, v in pairs(propertyValues) do
						if type(v) ~= "table" and tostring(v):find(128) then
							local r,g,b,a = fromcolor(value[i],true)
							value[i] = "tocolor("..r..", "..g..", "..b..", "..a..")"
						end
					end
				end
				local value = inspect(value)
				local value = value:gsub("{ ","{"):gsub(" }","}"):gsub('"tocolor','tocolor'):gsub('%)"',')')
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
		local image = "image" -- path
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
