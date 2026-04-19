MFS = MFS or {}
MFS.CVars = MFS.CVars or {}

local FCVAR_FLAGS = {FCVAR_ARCHIVE, FCVAR_NOTIFY}

local function BuildCVars()
    MFS.CVars.enabled = MFS.CVars.enabled or CreateConVar("mfs_enabled", "1", FCVAR_FLAGS, "Enable Milsim Frontier systems.")
    MFS.CVars.lockMap = MFS.CVars.lockMap or CreateConVar("mfs_lock_map", "1", FCVAR_FLAGS, "Lock server to target map.")
    MFS.CVars.applyModels = MFS.CVars.applyModels or CreateConVar("mfs_apply_models", "1", FCVAR_FLAGS, "Enable faction model assignment.")
    MFS.CVars.applyLoadouts = MFS.CVars.applyLoadouts or CreateConVar("mfs_apply_loadouts", "1", FCVAR_FLAGS, "Enable class loadouts.")
    MFS.CVars.resourcesEnabled = MFS.CVars.resourcesEnabled or CreateConVar("mfs_resources_enabled", "1", FCVAR_FLAGS, "Enable world material spawners.")
    MFS.CVars.enemyEnabled = MFS.CVars.enemyEnabled or CreateConVar("mfs_enemies_enabled", "1", FCVAR_FLAGS, "Enable zombie spawners.")
    MFS.CVars.allyBuff = MFS.CVars.allyBuff or CreateConVar("mfs_ally_buff", "1", FCVAR_FLAGS, "Enable ally proximity resistance.")
    MFS.CVars.baseBuilding = MFS.CVars.baseBuilding or CreateConVar("mfs_basebuilding_enabled", "1", FCVAR_FLAGS, "Enable MFS base building systems.")
    MFS.CVars.tradePosts = MFS.CVars.tradePosts or CreateConVar("mfs_tradeposts_enabled", "1", FCVAR_FLAGS, "Enable dynamic trade post zones.")
    MFS.CVars.debug = MFS.CVars.debug or CreateConVar("mfs_debug", "0", {FCVAR_ARCHIVE}, "Verbose debug logs.")
end

function Schema:AddWorkshopDependencies()
    for _, workshopID in pairs(MFS.WorkshopIDs or {}) do
        resource.AddWorkshop(workshopID)
    end
end

function Schema:EnsureTargetMap()
    if not (MFS.CVars.lockMap and MFS.CVars.lockMap:GetBool()) then
        return
    end

    if game.GetMap() == MFS.TargetMap then
        return
    end

    local mapPath = "maps/" .. MFS.TargetMap .. ".bsp"
    if not file.Exists(mapPath, "GAME") then
        MFS.Log("Map lock skipped, missing BSP: %s", mapPath)
        return
    end

    MFS.Log("Changing level to required map '%s'.", MFS.TargetMap)
    RunConsoleCommand("changelevel", MFS.TargetMap)
end

function Schema:ClockworkInitialized()
    BuildCVars()
    self:AddWorkshopDependencies()

    timer.Simple(5, function()
        if GAMEMODE and GAMEMODE.EnsureTargetMap then
            GAMEMODE:EnsureTargetMap()
        end
    end)
end

function Schema:ClockworkInitPostEntity()
    if MFS and MFS.Log then
        MFS.Log("Schema loaded on map '%s'.", game.GetMap())
    end
end
