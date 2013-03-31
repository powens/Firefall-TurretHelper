require "math";
require "string";
require "table";
require "./lib/lib_qol";
require "lib/lib_InterfaceOptions";
require "lib/lib_Slash";

local FRAME = Component.GetFrame("TurretHelper");
local DEPLOYABLEINFO = Component.GetWidget("deployables");
local FRAME_SIZE = 40
local FRAME_BUFFER = 2
local deployableFrames = {}
local activeDeployables = {}
--[[
'entityId' : {
	'deployTime': blah,
	'frame': frame,
	'abilityId': id,
}
]]--

local TRACKED_ENTITY_IDS = { [35542] = 0, [34629] = 300, [35487] = 180 };
local ENTITY_DURATION_SEC = {};

local TURRET_HELPER_SLASH_CMDS = {};

InterfaceOptions.AddMovableFrame({
	frame = FRAME,
	label = "TurretHelper",
	scalable = true,
});

function OnLoad()
	for i = 1, DEPLOYABLEINFO:GetChildCount() do
		deployableFrames[i] = DEPLOYABLEINFO:GetChild(i)
		deployableFrames[i]:SetParam("alpha", 0.0)
	end
	InitSlashCommands();
end

function IsEntityTracked(entityId)
	return activeDeployables[tostring(entityId)] ~= nil
end

function UpdateDeployable(entityId)
	local info = Game.GetTargetInfo(entityId);
	local vitals = Game.GetTargetVitals(entityId);
	local status = Game.GetTargetStatus(entityId);
	local stateStr = "";
	if status["state"] ~= nil then
		stateStr = "[" .. status["state"] .. "]";
	end
	local timeLeft = ""
	--log(tostring(info["name"]))
	if TRACKED_ENTITY_IDS[tonumber(info["sourceAbilityId"])] > 0 then
		timeLeft = "[" .. 300 + ( tonumber(activeDeployables[entityId]["time"]) - tonumber(System.GetClientTime())) / 1000 .."]"
	end
	
	local displayStr = "[" .. info["name"] .. "]\n" .. timeLeft .. "\n" .. stateStr .. "\n";
	
	local deployableFrame = deployableFrames[activeDeployables[entityId]["frame"]]
	
	deployableFrame:GetChild("deployableName"):SetText(displayStr)
	deployableFrame:GetChild("healthBarFG"):SetDims("bottom:" .. (FRAME_SIZE-FRAME_BUFFER/2) .."; height:" .. tostring((FRAME_SIZE-FRAME_BUFFER)*vitals["health_pct"]) .. ";")
	deployableFrame:SetParam("alpha", 1.0)
end

function GetFirstUnusedFrame()
	--Kind of hacky right now. Need to make better
	for i = 1, #deployableFrames do
		if (deployableFrames[i]:GetParam("alpha") == 0) then
			return i
		end
	end
	
	return -1
end

function UpdateFramePositions()
	local idCount = {}
	local currentRow = 0
	for i,j in pairs(activeDeployables) do
		local abilityId = tostring(j["abilityId"])
		if idCount[abilityId] == nil then
			deployableFrames[j["frame"]]:SetDims("left:0; top:" .. currentRow*(FRAME_SIZE+FRAME_BUFFER) .. ";")
			idCount[abilityId] = { count = 1, row = currentRow }
			currentRow = currentRow + 1
			log('a')
			log(tostring(idCount))
		else
			log('b')
			deployableFrames[j["frame"]]:SetDims("left:" .. (idCount[abilityId]["count"] * (FRAME_SIZE+FRAME_BUFFER)) .. "; top:" .. (idCount[abilityId]["row"]*(FRAME_SIZE+FRAME_BUFFER)) .. ";")
			idCount[abilityId]["count"] = idCount[abilityId]["count"] + 1
		end
	end
	
end

function UpdateAllDeployables()
	PruneDeployables()
	local deployableList = Player.GetActiveDeployables();
	for i = 1, #deployableList do
		local entityId = tostring(deployableList[i])
		if IsEntityTracked(entityId) == false then
			if IsTrackedDeployable(entityId) then
				local id = Game.GetTargetInfo(entityId)
				activeDeployables[entityId] = { time = System.GetClientTime(), frame = GetFirstUnusedFrame(), abilityId = id["sourceAbilityId"] }
				UpdateDeployable(entityId)
			end
		else
			UpdateDeployable(entityId)
		end
	end
	UpdateFramePositions()
end

function PruneDeployables()
	for i,k in pairs(activeDeployables) do
		if Game.GetTargetStatus(i) == nil then
			deployableFrames[k["frame"]]:SetParam("alpha", 0.0)
			activeDeployables[i] = nil
		end
	end
end

function UpdateAbilities()
	local abilities = Player.GetAbilities();
	for i,j in pairs(abilities["slotted"]) do
		local ability = Player.GetAbilityInfo(j["abilityId"]);
		log(tostring(ability));
	end
end

function OnMyAbilityDeployable(args)
	PruneDeployables()
	UpdateAllDeployables();
end

function OnDeployableStatusChanged(args)
	--[[local status = Game.GetTargetStatus(args["entityId"]);
	local info = Game.GetTargetInfo(args["entityId"]);
	local stateStr = "";
	if status["state"] ~= nil then
		stateStr = "[" .. status["state"] .. "]";
	end]]--
	--log("[StatusChanged] " .. info["name"] .. " " .. stateStr);
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployable(entityId);
	end
end

function OnDeployableVitalsChanged(args)
	--local vitals = Game.GetTargetVitals(args["entityId"]);
	--log("[VitalsChanged] " .. tostring(vitals));--vitals["Health"] .. "/" .. vitals["MaxHealth"]);
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployable(entityId);
	end
end

function OnDeployableInfoChanged(args)
	--local info = Game.GetTargetInfo(args["entityId"]);
	--log("[InfoChanged] " .. " " .. info["name"]);
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployable(entityId);
	end
end

function OnCombatEvent(args)
	local targetId = activeDeployables[tostring(args['TargetId'])]
	local sourceId = activeDeployables[tostring(args['SourceId'])]
	
	if (targetId ~= nil) or (sourceId ~= nil) then
		print('a')
		log(tostring(args))
	end
end


function IsTrackedDeployable(entityId)
	local id = Game.GetTargetInfo(entityId)
	if id["sourceAbilityId"] ~= nil then
		return TRACKED_ENTITY_IDS[tonumber(id["sourceAbilityId"])] ~= nil
	end
	return false
end


function OnMessage()
end

function InitSlashCommands()
	LIB_SLASH.BindCallback({slash_list = "th", description = "", func = TURRET_HELPER_SLASH_CMDS.cmdroot})
end

TURRET_HELPER_SLASH_CMDS.cmdroot = function(text)
	--print("TH: " .. tostring(activeDeployables))
	--UpdateAbilities();
	--local info = Game.GetTargetVitals(23234)
	--print(tostring(info))
	log(tostring(activeDeployables))
	--local t = tonumber(System.GetClientTime()) / 1000;
	--print(tostring(t))
	UpdateAllDeployables()
end
