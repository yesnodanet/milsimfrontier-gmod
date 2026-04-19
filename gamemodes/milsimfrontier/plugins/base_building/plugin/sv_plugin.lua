PLUGIN.structures = PLUGIN.structures or {}
PLUGIN.structureByEntity = PLUGIN.structureByEntity or {}

local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

local function SerializeVector(vector)
    return string.format("%.3f, %.3f, %.3f", vector.x, vector.y, vector.z)
end

local function SerializeAngle(angle)
    return string.format("%.3f, %.3f, %.3f", angle.p, angle.y, angle.r)
end

local function DeserializeVector(data)
    if isvector(data) then
        return data
    end

    if not isstring(data) then
        return nil
    end

    local x, y, z = string.match(data, "(.-), (.-), (.+)")
    if not x or not y or not z then
        return nil
    end

    return Vector(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
end

local function DeserializeAngle(data)
    if isangle(data) then
        return data
    end

    if not isstring(data) then
        return nil
    end

    local p, y, r = string.match(data, "(.-), (.-), (.+)")
    if not p or not y or not r then
        return nil
    end

    return Angle(tonumber(p) or 0, tonumber(y) or 0, tonumber(r) or 0)
end

local function FormatCost(cost)
    local parts = {}
    for materialID, amount in pairs(cost or {}) do
        table.insert(parts, string.format("%s:%d", materialID, ClampAmount(amount)))
    end
    table.sort(parts)
    return table.concat(parts, ", ")
end

function PLUGIN:IsEnabled()
    if MFS.CVars and MFS.CVars.enabled and not MFS.CVars.enabled:GetBool() then
        return false
    end

    if MFS.CVars and MFS.CVars.baseBuilding and not MFS.CVars.baseBuilding:GetBool() then
        return false
    end

    return MFS.BaseBuilding.enabled
end

function PLUGIN:GetSavePath()
    return "plugins/mfs_base_building/" .. game.GetMap()
end

function PLUGIN:CountPlayerStructures(steamID64)
    local count = 0
    for _, state in pairs(self.structures) do
        if state.ownerSteamID64 == steamID64 then
            count = count + 1
        end
    end

    return count
end

function PLUGIN:GenerateUID(player, structureID)
    local seed = string.format("%s:%s:%s:%d", player:SteamID64(), structureID, CurTime(), math.random(10000, 99999))
    return util.CRC(seed)
end

function PLUGIN:GetLookedStructure(player)
    local trace = player:GetEyeTrace()
    if not trace or not IsValid(trace.Entity) then
        return nil
    end

    if trace.Entity:GetClass() ~= MFS.BaseBuilding.structureClass then
        return nil
    end

    if player:GetShootPos():DistToSqr(trace.Entity:GetPos()) > (MFS.BaseBuilding.placementDistance * MFS.BaseBuilding.placementDistance) then
        return nil
    end

    return trace.Entity
end

function PLUGIN:CanManipulate(player, structureEntity)
    if not IsValid(player) or not IsValid(structureEntity) then
        return false
    end

    if player:IsAdmin() then
        return true
    end

    if structureEntity:GetOwnerSteamID64() == player:SteamID64() then
        return true
    end

    local faction = player:GetFaction()
    return faction ~= "" and faction == structureEntity:GetOwnerFaction()
end

function PLUGIN:GetStructureStateFromEntity(structureEntity)
    local uid = structureEntity:GetStructureUID()
    if uid == "" then
        return nil
    end

    return self.structures[uid]
end

function PLUGIN:SaveStructures()
    local payload = {}

    for uid, state in pairs(self.structures) do
        local structureEntity = self.structureByEntity[uid]
        if IsValid(structureEntity) then
            state.level = structureEntity:GetStructureLevel()
            state.health = structureEntity:GetStructureHealth()
            state.position = structureEntity:GetPos()
            state.angles = structureEntity:GetAngles()
        end

        payload[#payload + 1] = {
            uid = uid,
            typeID = state.typeID,
            level = ClampAmount(state.level),
            health = ClampAmount(state.health),
            ownerSteamID64 = state.ownerSteamID64,
            ownerName = state.ownerName,
            ownerFaction = state.ownerFaction,
            position = SerializeVector(state.position),
            angles = SerializeAngle(state.angles)
        }
    end

    Clockwork.kernel:SaveSchemaData(self:GetSavePath(), payload)
end

function PLUGIN:RegisterStructureEntity(structureEntity, state)
    self.structures[state.uid] = state
    self.structureByEntity[state.uid] = structureEntity
    structureEntity.MFSRegistered = true
end

function PLUGIN:SpawnStructureFromState(state)
    local structureDef = MFS.GetStructureDef(state.typeID)
    if not structureDef then
        return nil
    end

    local structureClass = MFS.BaseBuilding.structureClass
    local structureEntity = ents.Create(structureClass)
    if not IsValid(structureEntity) then
        return nil
    end

    structureEntity:SetPos(state.position + Vector(0, 0, 4))
    structureEntity:SetAngles(state.angles)
    structureEntity:Spawn()
    structureEntity:Activate()
    structureEntity:ConfigureStructure(state, structureDef)

    self:RegisterStructureEntity(structureEntity, state)
    return structureEntity
end

function PLUGIN:LoadStructures()
    self.structures = {}
    self.structureByEntity = {}

    local saved = Clockwork.kernel:RestoreSchemaData(self:GetSavePath()) or {}

    for _, entry in ipairs(saved) do
        local state = {
            uid = tostring(entry.uid or ""),
            typeID = tostring(entry.typeID or ""),
            level = ClampAmount(entry.level),
            health = ClampAmount(entry.health),
            ownerSteamID64 = tostring(entry.ownerSteamID64 or ""),
            ownerName = tostring(entry.ownerName or "Unknown"),
            ownerFaction = tostring(entry.ownerFaction or ""),
            position = DeserializeVector(entry.position),
            angles = DeserializeAngle(entry.angles)
        }

        if state.uid ~= "" and state.typeID ~= "" and state.position and state.angles and util.IsInWorld(state.position + Vector(0, 0, 12)) then
            self:SpawnStructureFromState(state)
        end
    end
end

function PLUGIN:CountActiveStructures()
    local count = 0
    for uid, structureEntity in pairs(self.structureByEntity) do
        if IsValid(structureEntity) then
            count = count + 1
        else
            self.structureByEntity[uid] = nil
            self.structures[uid] = nil
        end
    end

    return count
end

function PLUGIN:CountDamagedStructures()
    local count = 0
    for _, structureEntity in pairs(self.structureByEntity) do
        if IsValid(structureEntity) and structureEntity:GetStructureHealth() < structureEntity:GetStructureMaxHealth() then
            count = count + 1
        end
    end

    return count
end

function PLUGIN:GetDebugCounts()
    return self:CountActiveStructures(), self:CountDamagedStructures()
end

function PLUGIN:GetPlacementPosition(player)
    local trace = player:GetEyeTrace()
    if not trace or not trace.Hit then
        return nil, "Invalid placement trace."
    end

    if trace.HitSky then
        return nil, "Cannot place structures on sky surfaces."
    end

    local placementDistanceSqr = MFS.BaseBuilding.placementDistance * MFS.BaseBuilding.placementDistance
    if player:GetShootPos():DistToSqr(trace.HitPos) > placementDistanceSqr then
        return nil, "Placement is too far away."
    end

    local position = trace.HitPos + (trace.HitNormal * 14)
    if not util.IsInWorld(position + Vector(0, 0, 8)) then
        return nil, "Placement point is outside map bounds."
    end

    if cwMFSTradePosts and cwMFSTradePosts.IsPointInActiveZone and cwMFSTradePosts:IsPointInActiveZone(position) then
        return nil, "Cannot build inside active trade safe-zones."
    end

    local spacingSqr = MFS.BaseBuilding.minSpacing * MFS.BaseBuilding.minSpacing
    for _, structureEntity in pairs(self.structureByEntity) do
        if IsValid(structureEntity) and structureEntity:GetPos():DistToSqr(position) <= spacingSqr then
            return nil, "Too close to another structure."
        end
    end

    return position, nil
end

function PLUGIN:PlaceStructure(player, structureID)
    if not self:IsEnabled() then
        Clockwork.player:Notify(player, "Base building is disabled.")
        return false
    end

    local structureDef = MFS.GetStructureDef(structureID)
    if not structureDef then
        Clockwork.player:Notify(player, "Unknown structure type.")
        return false
    end

    if self:CountActiveStructures() >= MFS.BaseBuilding.maxStructuresGlobal then
        Clockwork.player:Notify(player, "Global structure cap reached.")
        return false
    end

    if self:CountPlayerStructures(player:SteamID64()) >= MFS.BaseBuilding.maxStructuresPerPlayer then
        Clockwork.player:Notify(player, "You reached your structure limit.")
        return false
    end

    local position, reason = self:GetPlacementPosition(player)
    if not position then
        Clockwork.player:Notify(player, reason or "Cannot place structure here.")
        return false
    end

    if not (cwMFSMaterials and cwMFSMaterials.ConsumeMaterials) then
        Clockwork.player:Notify(player, "Material inventory plugin unavailable.")
        return false
    end

    local consumed, missing = cwMFSMaterials:ConsumeMaterials(player, structureDef.buildCost)
    if not consumed then
        Clockwork.player:Notify(player, string.format("Missing materials: %s", missing or "unknown"))
        return false
    end

    local state = {
        uid = self:GenerateUID(player, structureID),
        typeID = structureID,
        level = 1,
        health = structureDef.baseHealth,
        ownerSteamID64 = player:SteamID64(),
        ownerName = player:Name(),
        ownerFaction = player:GetFaction(),
        position = position,
        angles = Angle(0, player:EyeAngles().y, 0)
    }

    local structureEntity = self:SpawnStructureFromState(state)
    if not IsValid(structureEntity) then
        Clockwork.player:Notify(player, "Failed to spawn structure entity.")
        return false
    end

    Clockwork.player:Notify(player, string.format("%s constructed.", structureDef.name))
    self:SaveStructures()
    return true
end

function PLUGIN:UpgradeStructure(player, structureEntity)
    if not IsValid(structureEntity) then
        return false, "No structure targeted."
    end

    if not self:CanManipulate(player, structureEntity) then
        return false, "You do not have permission for this structure."
    end

    local structureID = structureEntity:GetStructureTypeID()
    local structureDef = MFS.GetStructureDef(structureID)
    if not structureDef then
        return false, "Structure definition is missing."
    end

    local nextLevel = structureEntity:GetStructureLevel() + 1
    if nextLevel > structureDef.maxLevel then
        return false, "Structure is already at max level."
    end

    local upgradeCost = structureDef.upgradeCosts[nextLevel]
    if not upgradeCost then
        return false, "Upgrade path is missing for this level."
    end

    if not (cwMFSMaterials and cwMFSMaterials.ConsumeMaterials) then
        return false, "Material inventory plugin unavailable."
    end

    local consumed, missing = cwMFSMaterials:ConsumeMaterials(player, upgradeCost)
    if not consumed then
        return false, string.format("Missing materials: %s", missing or "unknown")
    end

    structureEntity:ApplyLevel(nextLevel, structureDef)
    self:SaveStructures()
    return true, string.format("%s upgraded to L%d.", structureDef.name, nextLevel)
end

function PLUGIN:RepairStructure(player, structureEntity)
    if not IsValid(structureEntity) then
        return false, "No structure targeted."
    end

    if not self:CanManipulate(player, structureEntity) then
        return false, "You do not have permission for this structure."
    end

    local structureID = structureEntity:GetStructureTypeID()
    local structureDef = MFS.GetStructureDef(structureID)
    if not structureDef then
        return false, "Structure definition is missing."
    end

    local current = structureEntity:GetStructureHealth()
    local maxHealth = structureEntity:GetStructureMaxHealth()
    if current >= maxHealth then
        return false, "Structure is already at full health."
    end

    if not (cwMFSMaterials and cwMFSMaterials.ConsumeMaterials) then
        return false, "Material inventory plugin unavailable."
    end

    local consumed, missing = cwMFSMaterials:ConsumeMaterials(player, structureDef.repairCost)
    if not consumed then
        return false, string.format("Missing materials: %s", missing or "unknown")
    end

    structureEntity:Repair(MFS.BaseBuilding.repairChunk)
    self:SaveStructures()

    return true, string.format("%s repaired to %d/%d.", structureDef.name, structureEntity:GetStructureHealth(), structureEntity:GetStructureMaxHealth())
end

function PLUGIN:RemoveStructure(player, structureEntity, silent)
    if not IsValid(structureEntity) then
        return false, "No structure targeted."
    end

    if not player:IsAdmin() and not self:CanManipulate(player, structureEntity) then
        return false, "You do not have permission for this structure."
    end

    local structureID = structureEntity:GetStructureTypeID()
    local structureDef = MFS.GetStructureDef(structureID)

    local uid = structureEntity:GetStructureUID()
    self.structures[uid] = nil
    self.structureByEntity[uid] = nil

    structureEntity.MFSRemoving = true
    structureEntity:Remove()

    self:SaveStructures()
    if not silent then
        return true, string.format("%s removed.", structureDef and structureDef.name or "Structure")
    end

    return true
end

function PLUGIN:HandleStructureDestroyed(structureEntity, attacker, damageInfo)
    if not IsValid(structureEntity) then
        return
    end

    local uid = structureEntity:GetStructureUID()
    self.structures[uid] = nil
    self.structureByEntity[uid] = nil

    local position = structureEntity:GetPos()
    structureEntity.MFSRemoving = true
    structureEntity:EmitSound("physics/wood/wood_furniture_break1.wav", 80, 95, 0.9)
    structureEntity:Remove()

    if cwMFSWorld and cwMFSWorld.SpawnResourceNode then
        cwMFSWorld:SpawnResourceNode(position, "scrap", math.random(1, 4), MFS.Resource.nodeLifetime)
    end

    self:SaveStructures()
end

function PLUGIN:ClockworkInitialized()
    timer.Create("MFS.BaseBuilding.Save", MFS.BaseBuilding.saveInterval, 0, function()
        if cwMFSBase and cwMFSBase:IsEnabled() then
            cwMFSBase:SaveStructures()
        end
    end)
end

function PLUGIN:ClockworkInitPostEntity()
    if self:IsEnabled() then
        self:LoadStructures()
    end
end

function PLUGIN:PlayerDisconnected(player)
    timer.Simple(0.1, function()
        if cwMFSBase then
            cwMFSBase:SaveStructures()
        end
    end)
end

function PLUGIN:ShutDown()
    self:SaveStructures()
end

function PLUGIN:EntityRemoved(entity)
    if not IsValid(entity) then
        return
    end

    if entity:GetClass() ~= MFS.BaseBuilding.structureClass then
        return
    end

    local uid = entity:GetStructureUID()
    if uid == "" then
        return
    end

    if entity.MFSRemoving then
        return
    end

    self.structures[uid] = nil
    self.structureByEntity[uid] = nil
end

concommand.Add("mfs_build_list", function(player)
    local lines = {"[MilsimFrontier] Build structures:\n"}
    for structureID, structureDef in pairs(MFS.BaseBuilding.types) do
        lines[#lines + 1] = string.format(" - %s (%s) cost [%s]\n", structureID, structureDef.name, FormatCost(structureDef.buildCost))
    end

    if IsValid(player) then
        for _, line in ipairs(lines) do
            player:PrintMessage(HUD_PRINTCONSOLE, line)
        end
    else
        for _, line in ipairs(lines) do
            print(string.Trim(line))
        end
    end
end)

concommand.Add("mfs_build_place", function(player, _, args)
    if not IsValid(player) then
        return
    end

    local structureID = string.lower(args[1] or "")
    if structureID == "" then
        Clockwork.player:Notify(player, "Usage: mfs_build_place <structureID>. Use mfs_build_list.")
        return
    end

    if cwMFSBase then
        cwMFSBase:PlaceStructure(player, structureID)
    end
end)

concommand.Add("mfs_build_upgrade", function(player)
    if not IsValid(player) or not cwMFSBase then
        return
    end

    local structureEntity = cwMFSBase:GetLookedStructure(player)
    local ok, message = cwMFSBase:UpgradeStructure(player, structureEntity)
    Clockwork.player:Notify(player, message or (ok and "Structure upgraded." or "Structure upgrade failed."))
end)

concommand.Add("mfs_build_repair", function(player)
    if not IsValid(player) or not cwMFSBase then
        return
    end

    local structureEntity = cwMFSBase:GetLookedStructure(player)
    local ok, message = cwMFSBase:RepairStructure(player, structureEntity)
    Clockwork.player:Notify(player, message or (ok and "Structure repaired." or "Structure repair failed."))
end)

concommand.Add("mfs_build_remove", function(player)
    if not IsValid(player) or not cwMFSBase then
        return
    end

    local structureEntity = cwMFSBase:GetLookedStructure(player)
    local ok, message = cwMFSBase:RemoveStructure(player, structureEntity)
    Clockwork.player:Notify(player, message or (ok and "Structure removed." or "Structure remove failed."))
end)
