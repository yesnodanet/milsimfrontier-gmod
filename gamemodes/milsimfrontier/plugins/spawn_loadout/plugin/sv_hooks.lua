local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

local function DistSqrToNearest(candidatePos, predicate)
    local nearestSqr = nil

    for _, target in ipairs(player.GetAll()) do
        if IsValid(target) and target:Alive() and (not predicate or predicate(target)) then
            local distSqr = candidatePos:DistToSqr(target:GetPos())
            if not nearestSqr or distSqr < nearestSqr then
                nearestSqr = distSqr
            end
        end
    end

    return nearestSqr
end

local function FindClassByName(className)
    if not className then
        return nil
    end

    for _, classTable in pairs(Clockwork.class:GetAll()) do
        if string.lower(classTable.name) == string.lower(className) then
            return classTable
        end
    end

    return nil
end

function PLUGIN:IsSystemEnabled()
    return not MFS.CVars or not MFS.CVars.enabled or MFS.CVars.enabled:GetBool()
end

function PLUGIN:GetClassName(player)
    local className = player:GetCharacterData("Class")
    if className and className ~= "" then
        return className
    end

    local classTable = Clockwork.class:FindByID(player:Team())
    return classTable and classTable.name or nil
end

function PLUGIN:GetLoadoutForPlayer(player)
    local className = self:GetClassName(player)
    local loadout = className and MFS.Loadouts[className] or nil

    if loadout then
        return loadout, className
    end

    local factionName = player:GetFaction()
    local defaultClass = MFS.DefaultClassByFaction[factionName]
    return MFS.Loadouts[defaultClass], defaultClass
end

function PLUGIN:GiveWeaponWithMags(player, weaponClass, magazines)
    local weapon = player:Give(weaponClass)
    if not IsValid(weapon) then
        return false
    end

    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then
        local clipSize = weapon:GetMaxClip1()
        if not clipSize or clipSize <= 0 then
            clipSize = (weapon.Primary and weapon.Primary.ClipSize) or 30
        end

        local reserve = ClampAmount(magazines) * math.max(1, clipSize)
        if reserve > 0 then
            player:GiveAmmo(reserve, ammoType, true)
        end
    end

    return true
end

function PLUGIN:GetWeaponUnlocks(player)
    local unlocks = player:GetCharacterData("MFSWeaponUnlocks", {})
    if not istable(unlocks) then
        return {}
    end

    local sanitized = {}
    for weaponClass, magazines in pairs(unlocks) do
        if isstring(weaponClass) then
            sanitized[weaponClass] = ClampAmount(magazines)
        end
    end

    return sanitized
end

function PLUGIN:GrantWeaponUnlock(player, weaponClass, magazines, giveNow)
    if not IsValid(player) or not isstring(weaponClass) then
        return false
    end

    local weaponDef = weapons.GetStored(weaponClass)
    if not weaponDef then
        return false
    end

    local unlocks = self:GetWeaponUnlocks(player)
    local targetMags = math.max(unlocks[weaponClass] or 0, ClampAmount(magazines))
    unlocks[weaponClass] = targetMags

    player:SetCharacterData("MFSWeaponUnlocks", unlocks, true)

    if giveNow then
        self:GiveWeaponWithMags(player, weaponClass, targetMags)
    end

    return true
end

function PLUGIN:ApplyClassModel(player)
    if MFS.CVars and MFS.CVars.applyModels and not MFS.CVars.applyModels:GetBool() then
        return
    end

    local factionKey, factionData = MFS.GetFactionDataByName(player:GetFaction())
    if not factionKey or not factionData then
        return
    end

    local models = factionData.models
    if not models or #models == 0 then
        return
    end

    local modelPath = models[math.random(1, #models)]
    if modelPath and util.IsValidModel(modelPath) then
        player:SetModel(modelPath)
    end
end

function PLUGIN:ApplyClassLoadout(player)
    if MFS.CVars and MFS.CVars.applyLoadouts and not MFS.CVars.applyLoadouts:GetBool() then
        return
    end

    local loadout = self:GetLoadoutForPlayer(player)
    if not loadout then
        return
    end

    player:StripWeapons()
    player:StripAmmo()

    for _, weaponInfo in ipairs(loadout.weapons or {}) do
        self:GiveWeaponWithMags(player, weaponInfo.class, weaponInfo.magazines or 0)
    end

    for _, utilityClass in ipairs(loadout.utility or {}) do
        if not player:HasWeapon(utilityClass) then
            player:Give(utilityClass)
        end
    end

    for weaponClass, magazines in pairs(self:GetWeaponUnlocks(player)) do
        self:GiveWeaponWithMags(player, weaponClass, magazines)
    end

    local health = math.max(1, ClampAmount(loadout.health or 100))
    local armor = math.max(0, ClampAmount(loadout.armor or 0))

    player:SetMaxHealth(health)
    player:SetHealth(health)
    player:SetArmor(armor)
end

function PLUGIN:TryPickNavPosition()
    if not navmesh.IsLoaded() then
        return nil
    end

    local areas = navmesh.GetAllNavAreas()
    if not areas or #areas < 1 then
        return nil
    end

    for _ = 1, 50 do
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

function PLUGIN:RelocateOutcastSpawn(player)
    local minPlayersSqr = MFS.OutcastSpawn.minDistanceFromPlayers ^ 2
    local minFactionSqr = MFS.OutcastSpawn.minDistanceFromRebelAlliance ^ 2

    for _ = 1, 80 do
        local pos = self:TryPickNavPosition()
        if pos then
            local nearAny = DistSqrToNearest(pos, nil)
            local nearMain = DistSqrToNearest(pos, function(target)
                local factionName = target:GetFaction()
                return factionName == "Rebels" or factionName == "Alliance"
            end)

            local passAny = (not nearAny) or nearAny >= minPlayersSqr
            local passMain = (not nearMain) or nearMain >= minFactionSqr
            if passAny and passMain then
                player:SetPos(pos + Vector(0, 0, 12))
                player:SetEyeAngles(Angle(0, math.random(0, 359), 0))
                return true
            end
        end
    end

    return false
end

function PLUGIN:UpdateAllyBuff()
    if MFS.CVars and MFS.CVars.allyBuff and not MFS.CVars.allyBuff:GetBool() then
        for _, target in ipairs(player.GetAll()) do
            target:SetNWFloat("MFSAllyResistance", 0)
        end
        return
    end

    local radiusSqr = MFS.AllyBuff.radius * MFS.AllyBuff.radius

    for _, subject in ipairs(player.GetAll()) do
        if IsValid(subject) and subject:Alive() then
            local factionName = subject:GetFaction()
            if not factionName or factionName == "Outcasts" then
                subject:SetNWFloat("MFSAllyResistance", 0)
            else
                local allies = 0
                local origin = subject:GetPos()

                for _, other in ipairs(player.GetAll()) do
                    if other ~= subject and IsValid(other) and other:Alive() then
                        if other:GetFaction() == factionName and origin:DistToSqr(other:GetPos()) <= radiusSqr then
                            allies = allies + 1
                        end
                    end
                end

                local resistance = math.min(MFS.AllyBuff.maxResistance, allies * MFS.AllyBuff.resistancePerAlly)
                subject:SetNWFloat("MFSAllyResistance", resistance)
            end
        end
    end
end

function PLUGIN:SetPlayerClassByName(player, requestedClass)
    local classTable = FindClassByName(requestedClass)
    if not classTable then
        return false, "Unknown class."
    end

    local factionName = player:GetFaction()
    if not classTable.factions or not table.HasValue(classTable.factions, factionName) then
        return false, "Class is not available for your faction."
    end

    player:SetCharacterData("Class", classTable.name, true)
    Clockwork.class:Set(player, classTable.index, true)
    return true, classTable.name
end

function PLUGIN:ClockworkInitialized()
    timer.Create("MFS.AllyBuffTick", 1, 0, function()
        if cwMFSLoadout then
            cwMFSLoadout:UpdateAllyBuff()
        end
    end)
end

function PLUGIN:PlayerCharacterInitialized(player)
    if cwMFSFactions and cwMFSFactions.EnsureClassForPlayer then
        cwMFSFactions:EnsureClassForPlayer(player)
    end
end

function PLUGIN:PostPlayerSpawn(player)
    if not self:IsSystemEnabled() or not IsValid(player) then
        return
    end

    timer.Simple(0.05, function()
        if not IsValid(player) or not player:Alive() then
            return
        end

        if cwMFSFactions and cwMFSFactions.EnsureClassForPlayer then
            cwMFSFactions:EnsureClassForPlayer(player)
        end

        self:ApplyClassModel(player)
        self:ApplyClassLoadout(player)

        if player:GetFaction() == "Outcasts" then
            self:RelocateOutcastSpawn(player)
        end

        if cwMFSMaterials and cwMFSMaterials.SyncMaterialInventory then
            cwMFSMaterials:SyncMaterialInventory(player)
        end
    end)
end

function PLUGIN:PlayerTakeDamage(player, inflictor, attacker, hitGroup, damageInfo)
    local resistance = math.Clamp(player:GetNWFloat("MFSAllyResistance", 0), 0, 0.9)
    if resistance > 0 then
        damageInfo:ScaleDamage(1 - resistance)
    end
end
