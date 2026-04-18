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

function GM:SpawnResourceNode(position, materialID, amount, lifetime)
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
    node:SetNWFloat("MFSDiesAt", CurTime() + (lifetime or MFS.Resource.nodeLifetime))

    self.MFSResourceNodes = self.MFSResourceNodes or {}
    self.MFSResourceNodes[node] = true

    timer.Simple(lifetime or MFS.Resource.nodeLifetime, function()
        if IsValid(node) then
            node:Remove()
        end
    end)

    return node
end

function GM:CountResourceNodes()
    self.MFSResourceNodes = self.MFSResourceNodes or {}
    local count = 0
    for ent in pairs(self.MFSResourceNodes) do
        if IsValid(ent) then
            count = count + 1
        else
            self.MFSResourceNodes[ent] = nil
        end
    end
    return count
end

function GM:PickResourceSpawnPosition()
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

function GM:TickResourceSpawner()
    if not MFS.CVars.enabled:GetBool() or not MFS.CVars.resourcesEnabled:GetBool() then
        return
    end

    local currentNodes = self:CountResourceNodes()
    if currentNodes >= MFS.Resource.maxNodes then
        return
    end

    local pos = self:PickResourceSpawnPosition()
    if not pos then
        return
    end

    local materialID = PickRandom(MFS.MaterialDropPool)
    local amount = math.random(MFS.Resource.amountMin, MFS.Resource.amountMax)
    self:SpawnResourceNode(pos, materialID, amount, MFS.Resource.nodeLifetime)
end

function GM:CountAliveEnemies()
    self.MFSEnemyNPCs = self.MFSEnemyNPCs or {}
    local count = 0
    for npc in pairs(self.MFSEnemyNPCs) do
        if IsValid(npc) then
            count = count + 1
        else
            self.MFSEnemyNPCs[npc] = nil
        end
    end
    return count
end

function GM:PickEnemySpawnPosition()
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

function GM:SpawnEnemy()
    local npcClass = PickRandom(MFS.Enemies.classes)
    if not npcClass then
        return nil
    end

    local pos = self:PickEnemySpawnPosition()
    if not pos then
        return nil
    end

    local npc = ents.Create(npcClass)
    if not IsValid(npc) then
        return nil
    end

    npc:SetPos(pos + Vector(0, 0, 16))
    npc:SetAngles(Angle(0, math.random(0, 359), 0))
    npc:Spawn()
    npc:Activate()

    self.MFSEnemyNPCs = self.MFSEnemyNPCs or {}
    self.MFSEnemyNPCs[npc] = true
    return npc
end

function GM:TickEnemySpawner()
    if not MFS.CVars.enabled:GetBool() or not MFS.CVars.enemyEnabled:GetBool() or not MFS.Enemies.enabled then
        return
    end

    local alive = self:CountAliveEnemies()
    if alive >= MFS.Enemies.maxAlive then
        return
    end

    self:SpawnEnemy()
end

function GM:DropEnemyMaterials(victim)
    local materialID = PickRandom(MFS.MaterialDropPool)
    if not materialID then
        return
    end

    local amount = math.random(MFS.Enemies.dropAmountMin, MFS.Enemies.dropAmountMax)
    self:SpawnResourceNode(victim:GetPos(), materialID, amount, MFS.Resource.nodeLifetime)
end

function GM:OnNPCKilled(victim, attacker, inflictor)
    if self.BaseClass and self.BaseClass.OnNPCKilled then
        self.BaseClass.OnNPCKilled(self, victim, attacker, inflictor)
    end

    if not MFS.CVars.enabled:GetBool() or not MFS.CVars.enemyEnabled:GetBool() then
        return
    end
    if not IsValid(victim) then
        return
    end

    if table.HasValue(MFS.Enemies.classes, victim:GetClass()) then
        self:DropEnemyMaterials(victim)
    end
end

hook.Add("Initialize", "MFS.WorldTimersInit", function()
    timer.Create("MFS.ResourceSpawner", MFS.Resource.spawnInterval, 0, function()
        if GAMEMODE and GAMEMODE.TickResourceSpawner then
            GAMEMODE:TickResourceSpawner()
        end
    end)

    timer.Create("MFS.EnemySpawner", MFS.Enemies.spawnInterval, 0, function()
        if GAMEMODE and GAMEMODE.TickEnemySpawner then
            GAMEMODE:TickEnemySpawner()
        end
    end)
end)

concommand.Add("mfs_debug_materials", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Admin permissions required.\n")
        return
    end

    local enable = (tonumber(args[1] or "1") or 1) > 0
    if IsValid(ply) then
        ply:SetNWBool("MFSDebugMaterials", enable)
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("[MilsimFrontier] Material debug %s.\n", enable and "enabled" or "disabled"))
    end
end)

concommand.Add("mfs_spawn_material", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Admin permissions required.\n")
        return
    end

    local materialID = args[1]
    if not MFS.Materials[materialID] then
        materialID = PickRandom(MFS.MaterialDropPool)
    end

    local amount = ClampAmount(tonumber(args[2] or "3") or 3)
    local spawnPos = nil

    if IsValid(ply) then
        spawnPos = ply:GetEyeTrace().HitPos
    else
        spawnPos = GAMEMODE:TryPickNavPosition()
    end

    if spawnPos then
        GAMEMODE:SpawnResourceNode(spawnPos, materialID, amount, MFS.Resource.nodeLifetime)
    end
end)

concommand.Add("mfs_debug_nodes", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Admin permissions required.\n")
        return
    end

    local nodeCount = GAMEMODE:CountResourceNodes()
    local enemyCount = GAMEMODE:CountAliveEnemies()
    local msg = string.format("[MilsimFrontier] Nodes: %d | Enemies: %d\n", nodeCount, enemyCount)

    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    else
        MFS.Log("Nodes: %d | Enemies: %d", nodeCount, enemyCount)
    end
end)

hook.Add("PlayerSay", "MFS.ChatShortcuts", function(ply, text)
    local cleaned = string.Trim(string.lower(text or ""))
    if cleaned == "!faction" then
        GAMEMODE:SendFactionMenu(ply, true)
        return ""
    end
    if cleaned == "!craft" then
        ply:ConCommand("mfs_open_craft")
        return ""
    end
    if cleaned == "!matdebug" and ply:IsAdmin() then
        local enabled = not ply:GetNWBool("MFSDebugMaterials", false)
        ply:SetNWBool("MFSDebugMaterials", enabled)
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("[MilsimFrontier] Material debug %s.\n", enabled and "enabled" or "disabled"))
        return ""
    end
end)
