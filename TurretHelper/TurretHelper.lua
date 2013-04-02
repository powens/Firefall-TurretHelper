require "math";
require "string";
require "table";
require "./lib/lib_qol";
require "lib/lib_InterfaceOptions";
require "lib/lib_Slash";
require "lib/lib_Callback2"

local FRAME = Component.GetFrame("TurretHelper");
local DEPLOYABLES = Component.GetWidget("deployables");
local FRAME_SIZE = 40
local FRAME_BUFFER = 2
local activeDeployables = {}
--[[
'entityId' : {
	'deployTime': blah,
	group: { FRAMESTUFF },
	'abilityId': id,
}
]]--

local TRACKED_ENTITY_IDS = { 
	[35542] = { duration = 0, icon = "heavyturret"}, 
	[34629] = { duration = 300, icon = "multiturret" },
	[35487] = { duration = 180, icon = "sentpod"  },
};

local TURRET_HELPER_SLASH_CMDS = {};
local timer = Callback2.Create() 

InterfaceOptions.AddMovableFrame({
	frame = FRAME,
	label = "TurretHelper",
	scalable = true,
});

function OnLoad()
	--Called when the addon loads
	InitSlashCommands();
	
	timer:Bind(UpdateAllDeployableTimeleft)
	timer:Schedule(1)
end

function CreateDeployable(entityId)
	local info = Game.GetTargetInfo(entityId)
	local abilityId = tonumber(info["sourceAbilityId"])
	local deployable = {group = Component.CreateWidget("deployableInfo", FRAME)};
	deployable.icon = deployable.group:GetChild("icon");
	deployable.icon:SetRegion(TRACKED_ENTITY_IDS[abilityId].icon)
	deployable.healthbar = {group = deployable.group:GetChild("healthbar")};
	deployable.healthbar.fg = deployable.healthbar.group:GetChild("hbFg");
	deployable.timeLeft = deployable.group:GetChild("timeleft");
	
	local duration = TRACKED_ENTITY_IDS[abilityId].duration;
	if duration > 0 then
		deployable.time = tonumber(System.GetClientTime()) + (duration * 1000)
		
	else
		deployable.time = 0
	end
	
	deployable.abilityId = abilityId;
	return deployable
end

function IsEntityTracked(entityId)
	--Check to see if the entity is currently being tracked
	return activeDeployables[tostring(entityId)] ~= nil;
end

function UpdateDeployableInfo(entityId)
	local info = Game.GetTargetInfo(entityId);
	--Do nothing, for now
end

function UpdateDeployableVitals(entityId)
	local vitals = Game.GetTargetVitals(entityId);
	activeDeployables[entityId].healthbar.fg:SetDims("bottom:" .. (FRAME_SIZE-FRAME_BUFFER/2) .."; height:" .. tostring((FRAME_SIZE-FRAME_BUFFER)*vitals["health_pct"]) .. ";")
end

function UpdateDeployableStatus(entityId)
	local status = Game.GetTargetStatus(entityId);
	local stateStr = "";
	if status["state"] ~= nil then
		stateStr = "[" .. status["state"] .. "]";
	end
end

function UpdateAllDeployableTimeleft()
	for i,j in pairs(activeDeployables) do
		UpdateDeployableTimeleft(i);
	end
	timer:Reschedule(1)
end

function UpdateDeployableTimeleft(entityId)
	if (activeDeployables[entityId].time > 0) then
		activeDeployables[entityId].timeLeft:SetText(math.floor((tonumber(activeDeployables[entityId].time) - tonumber(System.GetClientTime())) / 1000));
	end
end

function UpdateDeployable(entityId)
	--Update a deployable's info by entityId
	UpdateDeployableInfo(entityId);
	UpdateDeployableVitals(entityId);
	UpdateDeployableStatus(entityId);
	UpdateDeployableTimeleft(entityId);
end

function UpdateFramePositions()
	local idCount = {}
	local currentRow = 0
	for i,j in pairs(activeDeployables) do
		local abilityId = tostring(j.abilityId)
		if idCount[abilityId] == nil then
			j.group:SetDims("left:0; top:" .. currentRow*(FRAME_SIZE+FRAME_BUFFER) .. ";")
			idCount[abilityId] = { count = 1, row = currentRow }
			currentRow = currentRow + 1
		else
			j.group:SetDims("left:" .. (idCount[abilityId]["count"] * (FRAME_SIZE+FRAME_BUFFER)) .. "; top:" .. (idCount[abilityId]["row"]*(FRAME_SIZE+FRAME_BUFFER)) .. ";")
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
				activeDeployables[entityId] = CreateDeployable(entityId)
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
			--["frame"]]:SetParam("alpha", 0.0)
			Component.RemoveWidget(activeDeployables[i].group);
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
		UpdateDeployableStatus(entityId);
	end
end

function OnDeployableVitalsChanged(args)
	--local vitals = Game.GetTargetVitals(args["entityId"]);
	--log("[VitalsChanged] " .. tostring(vitals));--vitals["Health"] .. "/" .. vitals["MaxHealth"]);
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployableVitals(entityId);
	end
end

function OnDeployableInfoChanged(args)
	--local info = Game.GetTargetInfo(args["entityId"]);
	--log("[InfoChanged] " .. " " .. info["name"]);
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployableInfo(entityId);
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
