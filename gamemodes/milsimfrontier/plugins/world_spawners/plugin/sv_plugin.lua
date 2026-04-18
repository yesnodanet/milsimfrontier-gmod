PLUGIN.resourceNodes = PLUGIN.resourceNodes or {}
PLUGIN.enemyNPCs = PLUGIN.enemyNPCs or {}

local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

local function PickRandom(source)
    if not source or #source < 1 then
        return nil
    end

    return source[math.random(1, #source)]
end

local function DistSqrToNearestPlayer(pos)
    local nearest = nil

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local dist = pos:DistToSqr(ply:GetPos())
            if not nearest or dist < nearest then
                nearest = dist
            end
        end
    end

    return nearest
end

function PLUGIN:IsSpawningEnabled()
    if MFS.CVars and MFS.CVars.enabled and not MFS.CVars.enabled:GetBool() then
        return false
    end

    return true
end

function PLUGIN:TryPickNavPosition()
    if not navmesh.IsLoaded() then
        return nil
    end

    local areas = navmesh.GetAllNavAreas()
    if not areas or #areas < 1 then
        return nil
    end

    for _ = 1, 70 do
        local area = areas[math.random(1, #areas)]
        if area and area:IsValid() then
            local candidate = area:GetRandomPoint()
            if util.IsInWorld(candidate + Vector(0, 0, 16)) then
                return candidate
            end
        end
    end

    return nil
end

function PLUGIN:SpawnResourceNode(position, materialID, amount, lifetime)
    if not position or not MFS.Materials[materialID] then
        return nil
    end

    local node = ents.Create("mf_resource_node")
    if not IsValid(node) then
        return nil
    end

    node:SetPos(position + Vector(0, 0, 8))
    node:SetAngles(Angle(0, math.random(0, 359), 0))
    node:Spawn()
    node:ConfigureNode(materialID, ClampAmount(amount))

    self.resourceNodes[node] = true

    timer.Simple(lifetime or MFS.Resource.nodeLifetime, function()
        if IsValid(node) then
            node:Remove()
        end
    end)

    return node
end

function PLUGIN:CountResourceNodes()
    local count = 0

    for node in pairs(self.resourceNodes) do
        if IsValid(node) then
            count = count + 1
        else
            self.resourceNodes[node] = nil
        end
    end

    return count
end

function PLUGIN:CountAliveEnemies()
    local count = 0

    for npc in pairs(self.enemyNPCs) do
        if IsValid(npc) then
            count = count + 1
        else
            self.enemyNPCs[npc] = nil
        end
    end

    return count
end

function PLUGIN:PickResourceSpawnPosition()
    local minDistSqr = MFS.Resource.minPlayerDistance * MFS.Resource.minPlayerDistance

    for _ = 1, 70 do
        local pos = self:TryPickNavPosition()
        if pos then
            local nearest = DistSqrToNearestPlayer(pos)
            if (not nearest) or nearest >= minDistSqr then
                return pos
            end
        end
    end

    return nil
end

function PLUGIN:TickResourceSpawner()
    if not self:IsSpawningEnabled() then
        return
    end

    if MFS.CVars and MFS.CVars.resourcesEnabled and not MFS.CVars.resourcesEnabled:GetBool() then
        return
    end

    if self:CountResourceNodes() >= MFS.Resource.maxNodes then
        return
    end

    local position = self:PickResourceSpawnPosition()
    if not position then
        return
    end

    local materialID = PickRandom(MFS.MaterialDropPool)
    local amount = math.random(MFS.Resource.amountMin, MFS.Resource.amountMax)

    self:SpawnResourceNode(position, materialID, amount, MFS.Resource.nodeLifetime)
end

function PLUGIN:PickEnemySpawnPosition()
    local minDistSqr = MFS.Enemies.minDistanceFromPlayers * MFS.Enemies.minDistanceFromPlayers
    local maxDistSqr = MFS.Enemies.maxDistanceFromPlayers * MFS.Enemies.maxDistanceFromPlayers

    for _ = 1, 70 do
        local pos = self:TryPickNavPosition()
        if pos then
            local nearest = DistSqrToNearestPlayer(pos)
            if nearest and nearest >= minDistSqr and nearest <= maxDistSqr then
                return pos
            end
        end
    end

    return nil
end

function PLUGIN:SpawnEnemy(className)
    local npcClass = className or PickRandom(MFS.Enemies.classes)
    if not npcClass then
        return nil
    end

    local position = self:PickEnemySpawnPosition()
    if not position then
        return nil
    end

    local npc = ents.Create(npcClass)
    if not IsValid(npc) then
        return nil
    end

    npc:SetPos(position + Vector(0, 0, 16))
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:Spawn()
    npc:Activate()

    self.enemyNPCs[npc] = true
    return npc
end

function PLUGIN:TickEnemySpawner()
    if not self:IsSpawningEnabled() then
        return
    end

    if MFS.CVars and MFS.CVars.enemyEnabled and not MFS.CVars.enemyEnabled:GetBool() then
        return
    end

    if not MFS.Enemies.enabled then
        return
    end

    if self:CountAliveEnemies() >= MFS.Enemies.maxAlive then
        return
    end

    self:SpawnEnemy()
end

function PLUGIN:DropEnemyMaterials(victim)
    local materialID = PickRandom(MFS.MaterialDropPool)
    if not materialID then
        return
    end

    local amount = math.random(MFS.Enemies.dropAmountMin, MFS.Enemies.dropAmountMax)
    self:SpawnResourceNode(victim:GetPos(), materialID, amount, MFS.Resource.nodeLifetime)
end

function PLUGIN:GetDebugCounts()
    return self:CountResourceNodes(), self:CountAliveEnemies()
end

function PLUGIN:HandleNPCKilled(victim)
    if not IsValid(victim) then
        return
    end

    if not table.HasValue(MFS.Enemies.classes, victim:GetClass()) then
        return
    end

    if not self:IsSpawningEnabled() then
        return
    end

    self:DropEnemyMaterials(victim)
end

function PLUGIN:ClockworkInitialized()
    timer.Create("MFS.ResourceSpawner", MFS.Resource.spawnInterval, 0, function()
        if cwMFSWorld then
            cwMFSWorld:TickResourceSpawner()
        end
    end)

    timer.Create("MFS.EnemySpawner", MFS.Enemies.spawnInterval, 0, function()
        if cwMFSWorld then
            cwMFSWorld:TickEnemySpawner()
        end
    end)

    hook.Add("OnNPCKilled", "MFS.WorldNPCKilled", function(victim, attacker, inflictor)
        if cwMFSWorld then
            cwMFSWorld:HandleNPCKilled(victim)
        end
    end)
end
