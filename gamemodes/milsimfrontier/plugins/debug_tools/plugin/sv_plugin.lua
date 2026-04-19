local function IsWeaponAvailable(className)
    return weapons.GetStored(className) ~= nil
end

local function IsAdminOrConsole(player)
    if not IsValid(player) then
        return true
    end

    return player:IsAdmin()
end

local function RequireAdmin(player)
    if IsAdminOrConsole(player) then
        return true
    end

    Clockwork.player:Notify(player, "Admin permissions required.")
    return false
end

local function PrintToTarget(target, text)
    if IsValid(target) then
        target:PrintMessage(HUD_PRINTCONSOLE, text)
    else
        print(string.Trim(text))
    end
end

function PLUGIN:ValidateSetup(target)
    local ok = true

    if game.GetMap() ~= MFS.TargetMap then
        MFS.Log("Validation warning: current map '%s', target '%s'.", game.GetMap(), MFS.TargetMap)
    end

    if not file.Exists("maps/" .. MFS.TargetMap .. ".bsp", "GAME") then
        ok = false
        MFS.Log("Validation error: target map BSP is missing.")
    end

    for className, loadout in pairs(MFS.Loadouts) do
        for _, weaponInfo in ipairs(loadout.weapons or {}) do
            if not IsWeaponAvailable(weaponInfo.class) then
                ok = false
                MFS.Log("Validation error: missing loadout weapon '%s' (%s).", weaponInfo.class, className)
            end
        end
    end

    for recipeID, recipe in pairs(MFS.Recipes) do
        if recipe.resultType == "weapon" and not IsWeaponAvailable(recipe.resultClass) then
            ok = false
            MFS.Log("Validation error: missing craft weapon '%s' (recipe: %s).", recipe.resultClass, recipeID)
        end
    end

    if not navmesh.IsLoaded() then
        MFS.Log("Validation warning: navmesh is not loaded.")
    end

    local nodeCount, enemyCount = 0, 0
    if cwMFSWorld and cwMFSWorld.GetDebugCounts then
        nodeCount, enemyCount = cwMFSWorld:GetDebugCounts()
    end

    local structureCount, damagedStructureCount = 0, 0
    if cwMFSBase and cwMFSBase.GetDebugCounts then
        structureCount, damagedStructureCount = cwMFSBase:GetDebugCounts()
    end

    local zoneCount, activeZoneCount = 0, 0
    if cwMFSTradePosts and cwMFSTradePosts.GetDebugCounts then
        zoneCount, activeZoneCount = cwMFSTradePosts:GetDebugCounts()
    end

    local message = string.format(
        "[MilsimFrontier] Validation %s | Nodes: %d | Enemies: %d | Structures: %d (%d damaged) | Trade Zones: %d (%d active)\n",
        ok and "passed" or "has errors",
        nodeCount,
        enemyCount,
        structureCount,
        damagedStructureCount,
        zoneCount,
        activeZoneCount
    )

    PrintToTarget(target, message)
    return ok
end

concommand.Add("mfs_validate", function(player)
    if not RequireAdmin(player) then
        return
    end

    if cwMFSDebug then
        cwMFSDebug:ValidateSetup(player)
    end
end)

concommand.Add("mfs_debug_materials", function(player, _, args)
    if not RequireAdmin(player) then
        return
    end

    local enable = (tonumber(args[1] or "1") or 1) > 0
    if IsValid(player) then
        player:SetNWBool("MFSDebugMaterials", enable)
        player:PrintMessage(HUD_PRINTCONSOLE, string.format("[MilsimFrontier] Material debug %s.\n", enable and "enabled" or "disabled"))
    end
end)

concommand.Add("mfs_debug_zones", function(player, _, args)
    if not RequireAdmin(player) then
        return
    end

    local enable = (tonumber(args[1] or "1") or 1) > 0
    if IsValid(player) then
        player:SetNWBool("MFSDebugZones", enable)
        player:PrintMessage(HUD_PRINTCONSOLE, string.format("[MilsimFrontier] Zone debug %s.\n", enable and "enabled" or "disabled"))
    end
end)

concommand.Add("mfs_debug_build", function(player, _, args)
    if not RequireAdmin(player) then
        return
    end

    local enable = (tonumber(args[1] or "1") or 1) > 0
    if IsValid(player) then
        player:SetNWBool("MFSDebugBuild", enable)
        player:PrintMessage(HUD_PRINTCONSOLE, string.format("[MilsimFrontier] Build debug %s.\n", enable and "enabled" or "disabled"))
    end
end)

concommand.Add("mfs_debug_nodes", function(player)
    if not RequireAdmin(player) then
        return
    end

    local nodeCount, enemyCount = 0, 0
    if cwMFSWorld and cwMFSWorld.GetDebugCounts then
        nodeCount, enemyCount = cwMFSWorld:GetDebugCounts()
    end

    local structureCount, damagedStructureCount = 0, 0
    if cwMFSBase and cwMFSBase.GetDebugCounts then
        structureCount, damagedStructureCount = cwMFSBase:GetDebugCounts()
    end

    local zoneCount, activeZoneCount = 0, 0
    if cwMFSTradePosts and cwMFSTradePosts.GetDebugCounts then
        zoneCount, activeZoneCount = cwMFSTradePosts:GetDebugCounts()
    end

    local msg = string.format(
        "[MilsimFrontier] Nodes: %d | Enemies: %d | Structures: %d (%d damaged) | Trade Zones: %d (%d active)\n",
        nodeCount,
        enemyCount,
        structureCount,
        damagedStructureCount,
        zoneCount,
        activeZoneCount
    )

    PrintToTarget(player, msg)
end)

concommand.Add("mfs_spawn_material", function(player, _, args)
    if not RequireAdmin(player) then
        return
    end

    if not cwMFSWorld then
        return
    end

    local materialID = args[1]
    if not MFS.Materials[materialID] then
        materialID = MFS.MaterialDropPool[math.random(1, #MFS.MaterialDropPool)]
    end

    local amount = math.max(1, math.floor(tonumber(args[2] or "3") or 3))
    local spawnPos

    if IsValid(player) then
        spawnPos = player:GetEyeTrace().HitPos
    else
        spawnPos = cwMFSWorld:TryPickNavPosition()
    end

    if spawnPos then
        cwMFSWorld:SpawnResourceNode(spawnPos, materialID, amount, MFS.Resource.nodeLifetime)
    end
end)

concommand.Add("mfs_spawn_enemy", function(player, _, args)
    if not RequireAdmin(player) then
        return
    end

    if not cwMFSWorld then
        return
    end

    local className = args[1]
    if className and className ~= "" then
        cwMFSWorld:SpawnEnemy(className)
    else
        cwMFSWorld:SpawnEnemy()
    end
end)

hook.Add("PlayerSay", "MFS.ChatShortcuts", function(player, text)
    local cleaned = string.Trim(string.lower(text or ""))

    if cleaned == "!craft" then
        player:ConCommand("mfs_open_craft")
        return ""
    end

    if cleaned == "!matdebug" and player:IsAdmin() then
        local enabled = not player:GetNWBool("MFSDebugMaterials", false)
        player:SetNWBool("MFSDebugMaterials", enabled)
        Clockwork.player:Notify(player, string.format("Material debug %s.", enabled and "enabled" or "disabled"))
        return ""
    end
end)
