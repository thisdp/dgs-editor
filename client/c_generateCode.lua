loadstring(exports.dgs:dgsImportOOPClass())()

gDecimalPlaces = 2
gNumberFormat = "%."..tostring(gDecimalPlaces).."f"

function generateCode()
	local code = ""

	for dgsElement, element in pairs(dgsEditor.ElementList) do
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

	return code
end

function generateCode_process(element)
	local code = ""

	code = generateCode_element(element) --[[.. "\n"]]

	local c = element.children

	if c and #c > 0 then
		local done = false

		for _, child in ipairs(c) do
			if not child.attachedToParent then
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
		local code = "\n"..generateCodeWidget[elementType](element, generateCode_common(element))
		return code
	end

	return ""
end

function generateCode_common(element)
	local common = {}
	local elementType = element:getType()

	common.elementType = elementType
	common.variable = elementType.."[]"

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
			if property ~= "text" and property ~= "absPos" and property ~= "absSize" and property ~= "rltPos" and property ~= "rltSize" then
				if type(value) == "table" then value = serializeTable(value,true) end
				common.propertiesString = common.propertiesString.."\ndgsSetProperty("..common.variable..", \""..property.."\", "..tostring(value)..")"
			end
		end
	end

	return common
end

generateCodeWidget = {
	dxbutton = function(element, common)
		local output = common.variable.." = dgsCreateButton("..common.position..", "..common.size..", \""..common.text.."\", "..common.relative..common.parent

		output = output..common.propertiesString

		return output
	end,
	dxcheckbox = function(element, common)
		local output = common.variable.." = dgsCreateCheckBox("..common.position..", "..common.size..", \""..common.text.."\", "..tostring(element:getSelected())..", "..common.relative..common.parent

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
		local output = common.variable.." = dgsCreateImage("..common.position..", "..common.size..", image, "..common.relative..common.parent

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
		local output = common.variable.." = dgsCreateScrollBar("..common.position..", "..common.size..", "..(vertical and "false" or "true")..", "..common.relative..common.parent

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
