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
	--Init the slash commands
	InitSlashCommands();
	--Start the refresh timer, set to run every second
	timer:Bind(UpdateAllDeployableTimeleft)
	timer:Schedule(1)
end

function CreateDeployable(entityId)
	--Creates a new deployable for insertion into the activeDeployables table
	local info = Game.GetTargetInfo(entityId)
	local abilityId = tonumber(info["sourceAbilityId"])
	--Create a new widget from our template, and grabs important children widgets
	local deployable = {group = Component.CreateWidget("deployableInfo", FRAME)};
	deployable.icon = deployable.group:GetChild("icon");
	deployable.icon:SetRegion(TRACKED_ENTITY_IDS[abilityId].icon)
	deployable.healthbar = {group = deployable.group:GetChild("healthbar")};
	deployable.healthbar.fg = deployable.healthbar.group:GetChild("hbFg");
	deployable.timeLeft = deployable.group:GetChild("timeleft");
	deployable.statusicon = deployable.group:GetChild("si");
	
	--Sets a duration on the entity if it has one
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
	--Update the entity's info
	local info = Game.GetTargetInfo(entityId);
	--Do nothing, for now
end

function UpdateDeployableVitals(entityId)
	--Update the entity's vitals
	local vitals = Game.GetTargetVitals(entityId);
	activeDeployables[entityId].healthbar.fg:SetDims("bottom:" .. (FRAME_SIZE-FRAME_BUFFER/2) .."; height:" .. tostring((FRAME_SIZE-FRAME_BUFFER)*vitals["health_pct"]) .. ";")
end

function UpdateDeployableStatus(entityId)
	--Update the entity's status
	local status = Game.GetTargetStatus(entityId);
	local state = status["state"]
	if (state ~= nil) then
		activeDeployables[entityId].statusicon:SetRegion(string.lower(tostring(state)))
	end
end

function UpdateAllDeployableTimeleft()
	--The function that the timer calls. Updates the time left on all deployables.
	--Also prunes the deployable list
	for i,j in pairs(activeDeployables) do
		UpdateDeployableTimeleft(i);
		UpdateDeployableStatus(i);
	end
	PruneDeployables()
	timer:Reschedule(1)
end

function GetTimeRemainingStr(entityId)
	--Grabs the remaining time of a deployable and returns a formatted string in the form of MM:SS
	if (activeDeployables[entityId].time > 0) then
		local timeLeft = math.floor((tonumber(activeDeployables[entityId].time) - tonumber(System.GetClientTime())) / 1000);
		local minutesLeft = math.floor(timeLeft / 60);
		local secondsLeft = timeLeft % 60;
		
		if (secondsLeft < 10) then
			secondsLeft = "0" .. secondsLeft;
		end
		
		return minutesLeft .. ":" .. secondsLeft;
	end
end

function UpdateDeployableTimeleft(entityId)
	--Updates the deployable's remaining time if it has one
	if (activeDeployables[entityId].time > 0) then
		activeDeployables[entityId].timeLeft:SetText(GetTimeRemainingStr(entityId));
	end
end

function UpdateDeployable(entityId)
	--Update all of a deployable's info by entityId
	UpdateDeployableInfo(entityId);
	UpdateDeployableVitals(entityId);
	UpdateDeployableStatus(entityId);
	UpdateDeployableTimeleft(entityId);
end

function UpdateFramePositions()
	--Iterates through all the activeDeployables, assigning them positions and grouping deployables from the same ability together
	local idCount = {}
	local currentRow = 0
	for i,j in pairs(activeDeployables) do
		local abilityId = tostring(j.abilityId)
		if idCount[abilityId] == nil then
			j.group:SetDims("left:0; top:" .. currentRow*(FRAME_SIZE+FRAME_BUFFER+10) .. ";")
			idCount[abilityId] = { count = 1, row = currentRow }
			currentRow = currentRow + 1
		else
			j.group:SetDims("left:" .. (idCount[abilityId]["count"] * (FRAME_SIZE+FRAME_BUFFER)) .. "; top:" .. (idCount[abilityId]["row"]*(FRAME_SIZE+FRAME_BUFFER+10)) .. ";")
			idCount[abilityId]["count"] = idCount[abilityId]["count"] + 1
		end
	end
	
end

function UpdateAllDeployables()
	--Iterates through all deployables assigned to a player
	-- Adds new deployables that are tracked to the activeDeployables table and updates them
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
	--Checks to see if any deployables no longer exist. If they do not, remove them and update the positions of the active frames if any were removed
	local removeDeployable = false
	for i,k in pairs(activeDeployables) do
		if (Game.GetTargetStatus(i) == nil) then
			--["frame"]]:SetParam("alpha", 0.0)
			Component.RemoveWidget(activeDeployables[i].group);
			activeDeployables[i] = nil
			removeDeployable = true
		end
	end
	
	if (removeDeployable) then
		UpdateFramePositions()
	end
end

function UpdateAbilities()
	--Checks the equipped abilities of the player. Not called anywhere at the moment
	local abilities = Player.GetAbilities();
	for i,j in pairs(abilities["slotted"]) do
		local ability = Player.GetAbilityInfo(j["abilityId"]);
		log(tostring(ability));
	end
end

function OnMyAbilityDeployable(args)
	--Called when the MY_ABILITY_DEPLOYABLE event is triggered
	PruneDeployables()
	UpdateAllDeployables();
end

function OnDeployableStatusChanged(args)
	--Called when the ON_DEPLOYABLE_STATUS_CHANGED event is triggered
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployableStatus(entityId);
	end
end

function OnDeployableVitalsChanged(args)
	--Called when the ON_DEPLOYABLE_VITALS_CHANGED event is triggered
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployableVitals(entityId);
	end
end

function OnDeployableInfoChanged(args)
	--Called when the ON_DEPLOYABLE_INFO_CHANGED event is triggered
	local entityId = tostring(args["entityId"])
	if IsEntityTracked(entityId) then
		UpdateDeployableInfo(entityId);
	end
end

function OnCombatEvent(args)
	--Called when the ON_COMBAT_EVENT event is triggered
	local targetId = activeDeployables[tostring(args['TargetId'])]
	local sourceId = activeDeployables[tostring(args['SourceId'])]
	log(tostring(args))
	if (targetId ~= nil) or (sourceId ~= nil) then
		print('a')
		--log(tostring(args))
	end
end

function IsTrackedDeployable(entityId)
	--Returns true if an entity's sourceAbilityId is one that we track
	local id = Game.GetTargetInfo(entityId)
	if id["sourceAbilityId"] ~= nil then
		return TRACKED_ENTITY_IDS[tonumber(id["sourceAbilityId"])] ~= nil
	end
	return false
end


function OnMessage()
end

function InitSlashCommands()
	--Inits the slash commands
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
