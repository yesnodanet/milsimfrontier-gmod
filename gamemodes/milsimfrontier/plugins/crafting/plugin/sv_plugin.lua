PLUGIN.registeredBlueprints = PLUGIN.registeredBlueprints or {}

local function BuildTakeItemTable(costs)
    local takeItems = {}

    for materialID, amount in pairs(costs or {}) do
        local material = MFS.Materials[materialID]
        if material and material.itemID then
            takeItems[material.itemID] = math.max(0, math.floor(amount or 0))
        end
    end

    return takeItems
end

local function IsWeaponAvailable(className)
    return weapons.GetStored(className) ~= nil
end

function PLUGIN:HandleRecipeResult(player, recipeID)
    local recipe = MFS.Recipes[recipeID]
    if not recipe then
        return
    end

    if recipe.resultType == "weapon" then
        if not IsWeaponAvailable(recipe.resultClass) then
            Clockwork.player:Notify(player, "Craft result is missing on server.")
            return
        end

        if recipe.resultClass == "tacrp_medkit" then
            player:Give(recipe.resultClass)
        elseif cwMFSLoadout and cwMFSLoadout.GrantWeaponUnlock then
            cwMFSLoadout:GrantWeaponUnlock(player, recipe.resultClass, recipe.resultMagazines or 0, true)
        else
            player:Give(recipe.resultClass)
        end
    end
end

function PLUGIN:RegisterBlueprints()
    for recipeID, recipe in pairs(MFS.Recipes) do
        local blueprint = Clockwork.crafting:New()
        blueprint.uniqueID = recipe.blueprintID
        blueprint.name = recipe.name
        blueprint.model = "models/weapons/w_smg1.mdl"
        blueprint.category = "Milsim Frontier"
        blueprint.description = "Crafted through collected world materials."
        blueprint.itemRequirements = BuildTakeItemTable(recipe.costs)
        blueprint.takeItems = BuildTakeItemTable(recipe.costs)
        blueprint.giveItems = {}

        function blueprint:CanCraft(player)
            if recipe.resultType == "weapon" and not IsWeaponAvailable(recipe.resultClass) then
                return false, "Result weapon class is missing."
            end

            return true
        end

        function blueprint:PostCraft(player)
            if cwMFSCrafting then
                cwMFSCrafting:HandleRecipeResult(player, recipeID)
            end
        end

        blueprint:Register()
        self.registeredBlueprints[recipeID] = blueprint.uniqueID
    end
end

function PLUGIN:ClockworkInitialized()
    self:RegisterBlueprints()
end

concommand.Add("mfs_recipes", function(player)
    if not IsValid(player) then
        print("[MilsimFrontier] Recipes:")
        for recipeID, recipe in pairs(MFS.Recipes) do
            print(string.format(" - %s (%s)", recipeID, recipe.name))
        end
        return
    end

    player:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Crafting recipes:\n")
    for recipeID, recipe in pairs(MFS.Recipes) do
        player:PrintMessage(HUD_PRINTCONSOLE, string.format(" - %s (%s)\n", recipeID, recipe.name))
    end
end)

concommand.Add("mfs_craft", function(player, _, args)
    if not IsValid(player) then
        return
    end

    local recipeID = string.lower(args[1] or "")
    local recipe = MFS.Recipes[recipeID]

    if not recipe then
        Clockwork.player:Notify(player, "Unknown recipe. Use mfs_recipes.")
        return
    end

    local blueprint = Clockwork.crafting:FindByID(recipe.blueprintID)
    if not blueprint then
        Clockwork.player:Notify(player, "Blueprint is not registered yet.")
        return
    end

    Clockwork.crafting:Craft(player, blueprint)
end)

concommand.Add("mfs_open_craft", function(player)
    if not IsValid(player) then
        return
    end

    Clockwork.player:Notify(player, "Use mfs_recipes, then mfs_craft <recipeID>.")
end)
