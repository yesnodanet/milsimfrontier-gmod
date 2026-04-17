MFS.CVars.resourcesEnabled = MFS.CVars.resourcesEnabled or CreateConVar("mfs_resources_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable material spawning.")
MFS.CVars.enemyEnabled = MFS.CVars.enemyEnabled or CreateConVar("mfs_enemies_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable enemy spawning.")

local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

local function IsWeaponAvailable(className)
    return weapons.GetStored(className) ~= nil
end

function GM:InitializeMaterialInventory(ply)
    ply.MFSMaterials = ply.MFSMaterials or {}
    for _, materialID in ipairs(MFS.GetMaterialKeys()) do
        local storedAmount = ClampAmount(tonumber(ply:GetPData("mfs_mat_" .. materialID, "0")) or 0)
        ply.MFSMaterials[materialID] = storedAmount
        ply:SetNWInt("MFSMat_" .. materialID, storedAmount)
    end
end

function GM:SaveMaterialInventory(ply)
    if not IsValid(ply) or ply:IsBot() then
        return
    end

    local inventory = ply.MFSMaterials or {}
    for _, materialID in ipairs(MFS.GetMaterialKeys()) do
        local amount = ClampAmount(inventory[materialID] or 0)
        ply:SetPData("mfs_mat_" .. materialID, tostring(amount))
    end
end

function GM:SyncMaterialInventory(ply)
    if not IsValid(ply) then
        return
    end

    local inventory = ply.MFSMaterials or {}
    local keys = MFS.GetMaterialKeys()

    net.Start(MFS.Net.syncMaterials)
    net.WriteUInt(#keys, 8)
    for _, materialID in ipairs(keys) do
        net.WriteString(materialID)
        net.WriteUInt(ClampAmount(inventory[materialID] or 0), 16)
    end
    net.Send(ply)
end

function GM:GetMaterialAmount(ply, materialID)
    local inventory = ply.MFSMaterials or {}
    return ClampAmount(inventory[materialID] or 0)
end

function GM:SetMaterialAmount(ply, materialID, amount, saveImmediately)
    if not IsValid(ply) or not MFS.Materials[materialID] then
        return
    end

    ply.MFSMaterials = ply.MFSMaterials or {}
    local clamped = ClampAmount(amount)
    ply.MFSMaterials[materialID] = clamped
    ply:SetNWInt("MFSMat_" .. materialID, clamped)

    if saveImmediately then
        ply:SetPData("mfs_mat_" .. materialID, tostring(clamped))
    end

    self:SyncMaterialInventory(ply)
end

function GM:AddMaterial(ply, materialID, amount, saveImmediately)
    local current = self:GetMaterialAmount(ply, materialID)
    self:SetMaterialAmount(ply, materialID, current + ClampAmount(amount), saveImmediately)
end

function GM:LoadCraftUnlocks(ply)
    ply.MFSUnlocks = {}
    if not IsValid(ply) or ply:IsBot() then
        return
    end

    local decoded = util.JSONToTable(ply:GetPData("mfs_unlocks", "{}") or "{}")
    if not istable(decoded) then
        return
    end

    for weaponClass, magCount in pairs(decoded) do
        if isstring(weaponClass) and IsWeaponAvailable(weaponClass) then
            ply.MFSUnlocks[weaponClass] = ClampAmount(magCount)
        end
    end
end

function GM:SaveCraftUnlocks(ply)
    if not IsValid(ply) or ply:IsBot() then
        return
    end

    ply.MFSUnlocks = ply.MFSUnlocks or {}
    ply:SetPData("mfs_unlocks", util.TableToJSON(ply.MFSUnlocks))
end

function GM:CanAffordRecipe(ply, recipeID)
    local recipe = MFS.Recipes[recipeID]
    if not recipe then
        return false, "Unknown recipe."
    end

    for materialID, requiredAmount in pairs(recipe.costs or {}) do
        if self:GetMaterialAmount(ply, materialID) < requiredAmount then
            return false, string.format("Not enough %s.", MFS.Materials[materialID].name)
        end
    end

    return true, recipe
end

function GM:ConsumeRecipeMaterials(ply, recipe)
    for materialID, requiredAmount in pairs(recipe.costs or {}) do
        local current = self:GetMaterialAmount(ply, materialID)
        self:SetMaterialAmount(ply, materialID, current - requiredAmount, true)
    end
end

function GM:TryCraftRecipe(ply, recipeID)
    if not IsValid(ply) then
        return false, "Invalid player."
    end

    local canAfford, recipeOrMessage = self:CanAffordRecipe(ply, recipeID)
    if not canAfford then
        return false, recipeOrMessage
    end

    local recipe = recipeOrMessage
    if recipe.resultType == "weapon" and not IsWeaponAvailable(recipe.resultClass) then
        return false, "Result weapon class is missing."
    end

    self:ConsumeRecipeMaterials(ply, recipe)

    if recipe.resultType == "weapon" then
        if recipe.resultClass == "tacrp_medkit" then
            local medkit = ply:Give(recipe.resultClass)
            if not IsValid(medkit) then
                return false, "Failed to give medkit."
            end
        else
            ply.MFSUnlocks = ply.MFSUnlocks or {}
            local currentMags = ClampAmount(ply.MFSUnlocks[recipe.resultClass] or 0)
            local targetMags = math.max(currentMags, ClampAmount(recipe.resultMagazines or 0))
            ply.MFSUnlocks[recipe.resultClass] = targetMags
            self:SaveCraftUnlocks(ply)
            self:GiveWeaponWithMags(ply, recipe.resultClass, targetMags)
        end
    end

    return true, string.format("Crafted %s.", recipe.name)
end

function GM:ValidateSetup(target)
    local ok = true

    if game.GetMap() ~= MFS.TargetMap then
        MFS.Log("Validation warning: current map '%s', target '%s'.", game.GetMap(), MFS.TargetMap)
    end

    if not file.Exists("maps/" .. MFS.TargetMap .. ".bsp", "GAME") then
        ok = false
        MFS.Log("Validation error: target map BSP is missing.")
    end

    for factionID, factionData in pairs(MFS.Factions) do
        for classID, classData in pairs(factionData.classes) do
            for _, weaponInfo in ipairs(classData.weapons or {}) do
                if not IsWeaponAvailable(weaponInfo.class) then
                    ok = false
                    MFS.Log("Validation error: missing loadout weapon '%s' (%s/%s).", weaponInfo.class, factionID, classID)
                end
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

    if IsValid(target) then
        target:PrintMessage(HUD_PRINTCONSOLE, ok and "[MilsimFrontier] Validation passed.\n" or "[MilsimFrontier] Validation has errors.\n")
    end
end

net.Receive(MFS.Net.craftRequest, function(_, ply)
    local recipeID = net.ReadString()
    local success, message = GAMEMODE:TryCraftRecipe(ply, recipeID)

    net.Start(MFS.Net.craftResult)
    net.WriteBool(success)
    net.WriteString(message or "")
    net.Send(ply)
end)

concommand.Add("mfs_open_craft", function(ply)
    if not IsValid(ply) then
        return
    end
    ply:SendLua("if MFS and MFS.OpenCraftMenu then MFS.OpenCraftMenu() end")
end)

concommand.Add("mfs_validate", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Admin permissions required.\n")
        return
    end
    GAMEMODE:ValidateSetup(ply)
end)

