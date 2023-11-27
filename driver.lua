--Globals
EC = {}
OPC = {}
RFP = {}
DRV = {}
REQ = {}
EntityID = Properties["Entity ID"]
Connected = false
PollTimer = nil

JSON = require("module.json")
require('Control4-HA-Base.helpers')
require('commands')

function HandlerDebug(init, tParams, args)
	if (not DEBUGPRINT) then
		return
	end

	if (type(init) ~= 'table') then
		return
	end

	local output = init

	if (type(tParams) == 'table' and next(tParams) ~= nil) then
		table.insert(output, '----PARAMS----')
		for k, v in pairs(tParams) do
			local line = tostring(k) .. ' = ' .. tostring(v)
			table.insert(output, line)
		end
	end

	if (type(args) == 'table' and next(args) ~= nil) then
		table.insert(output, '----ARGS----')
		for k, v in pairs(args) do
			local line = tostring(k) .. ' = ' .. tostring(v)
			table.insert(output, line)
		end
	end

	local t, ms
	if (C4.GetTime) then
		t = C4:GetTime()
		ms = '.' .. tostring(t % 1000)
		t = math.floor(t / 1000)
	else
		t = os.time()
		ms = ''
	end
	local s = os.date('%x %X') .. ms

	table.insert(output, 1, '-->  ' .. s)
	table.insert(output, '<--')
	output = table.concat(output, '\r\n')
	print(output)
	C4:DebugLog(output)
end

function ExecuteCommand(strCommand, tParams)
	tParams = tParams or {}
	local init = {
		'ExecuteCommand: ' .. strCommand,
	}
	HandlerDebug(init, tParams)

	if (strCommand == 'LUA_ACTION') then
		if (tParams.ACTION) then
			strCommand = tParams.ACTION
			tParams.ACTION = nil
		end
	end

	strCommand = string.gsub(strCommand, '%s+', '_')

	local success, ret

	if (EC and EC[strCommand] and type(EC[strCommand]) == 'function') then
		success, ret = pcall(EC[strCommand], tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print('ExecuteCommand error: ', ret, strCommand)
	end
end

function OnPropertyChanged(strProperty)
	local value = Properties[strProperty]
	if (type(value) ~= 'string') then
		value = ''
	end

	local init = {
		'OnPropertyChanged: ' .. strProperty,
		value,
	}
	HandlerDebug(init)

	strProperty = string.gsub(strProperty, '%s+', '_')

	local success, ret

	if (OPC and OPC[strProperty] and type(OPC[strProperty]) == 'function') then
		success, ret = pcall(OPC[strProperty], value)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print('OnPropertyChanged error: ', ret, strProperty, value)
	end
end

function ReceivedFromProxy(idBinding, strCommand, tParams)
	strCommand = strCommand or ''
	tParams = tParams or {}
	local args = {}
	if (tParams.ARGS) then
		local parsedArgs = C4:ParseXml(tParams.ARGS)
		for _, v in pairs(parsedArgs.ChildNodes) do
			args[v.Attributes.name] = v.Value
		end
		tParams.ARGS = nil
	end

	local init = {
		'ReceivedFromProxy: ' .. idBinding, strCommand,
	}
	HandlerDebug(init, tParams, args)

	local success, ret

	if (RFP and RFP[strCommand] and type(RFP[strCommand]) == 'function') then
		success, ret = pcall(RFP[strCommand], idBinding, strCommand, tParams, args)
	elseif (RFP and RFP[idBinding] and type(RFP[idBinding]) == 'function') then
		success, ret = pcall(RFP[idBinding], idBinding, strCommand, tParams, args)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print('ReceivedFromProxy error: ', ret, idBinding, strCommand)
	end
end

function OnDriverInit(init)
	print("--driver init--")

	Delegate(DRV, { "OnDriverInit" }, init)

	C4:AddVariable("ENTITY_ID", "", "STRING")
end

function OnDriverLateInit(init)
	print("--driver late init--")

	for property, _ in pairs(Properties) do
		OnPropertyChanged(property)
	end

	Delegate(DRV, { "OnDriverLateInit" }, init)
end

function OnDriverInitComplete(init)
	print("--driver init complete--")

	Delegate(DRV, { "OnDriverInitComplete" }, init)
end

function OnDriverRemovedFromProject(init)
	print("--driver removed--")

	Delegate(DRV, { "OnDriverRemovedFromProject" }, init)
end

function OnDriverDestroyed(init)
	print("--driver destroyed--")

	Delegate(DRV, { "OnDriverDestroyed" }, init)
end

function OnBindingChanged(idBinding, strClass, bIsBound)
	print("--change binding--")

	Delegate(DRV, { "OnBindingChanged" }, idBinding, strClass, bIsBound)
end

function OnVariableChanged(strName)
	Delegate(DRV, { "OnVariableChanged" }, strName, Variables[strName])
end

function Delegate(GLOB, nameTable, ...)
	local args = { ... }

	if not table.unpack then
		table.unpack = unpack
	end

	for _, name in pairs(nameTable) do
		if GLOB[name] then
			return GLOB[name](table.unpack(args))
		end
	end

	if GLOB.DEFAULT then
		return GLOB.DEFAULT(table.unpack(args))
	end
end

function UIRequest(strCommand, tParams)
	local success, ret

	if (REQ and REQ[strCommand] and type(REQ[strCommand]) == 'function') then
		success, ret = pcall(REQ[strCommand], strCommand, tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		print('UIRequest error: ', ret, strCommand)
	end
end

function OPC.Entity_ID(value)
	EntityID = value

	EC.REFRESH()

	C4:SetVariable("ENTITY_ID", value)
end

function OPC.Sensor_Type(value)
	EC.REFRESH()
end

function OPC.Driver_Version(value)
	local version = C4:GetDriverConfigInfo('version')
	C4:UpdateProperty('Driver Version', version)
end

function OPC.Debug_Mode(value)
	if (DebugPrintTimer and DebugPrintTimer.Cancel) then
		DebugPrintTimer = DebugPrintTimer:Cancel()
	end
	DEBUGPRINT = (value == 'On')

	if (DEBUGPRINT) then
		local _timer = function(timer)
			C4:UpdateProperty('Debug Mode', 'Off')
			OnPropertyChanged('Debug Mode')
		end
		DebugPrintTimer = C4:SetTimer(60 * 60 * 1000, _timer)
	end
end

function OPC.Poll_Timer(value)
	if value == "On" then
		if PollTimer ~= nil then
			PollTimer:Cancel()
		end

		PollTimer = C4:SetTimer(30000, EC.REFRESH, true)
	else
		if PollTimer ~= nil then
			PollTimer:Cancel()
		end
	end
end

function EC.REFRESH()
	local tParams = {
		entity = EntityID
	}

	C4:SendToProxy(999, "HA_GET_STATE", tParams)
end
