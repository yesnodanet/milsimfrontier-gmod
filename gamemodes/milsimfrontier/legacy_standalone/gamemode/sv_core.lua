util.AddNetworkString(MFS.Net.openFactionMenu)
util.AddNetworkString(MFS.Net.submitFaction)
util.AddNetworkString(MFS.Net.syncMaterials)
util.AddNetworkString(MFS.Net.craftRequest)
util.AddNetworkString(MFS.Net.craftResult)

MFS.CVars = MFS.CVars or {}
MFS.CVars.enabled = CreateConVar("mfs_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable Milsim Frontier systems.")
MFS.CVars.lockMap = CreateConVar("mfs_lock_map", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Lock server to target map.")
MFS.CVars.applyModels = CreateConVar("mfs_apply_models", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable faction model assignment.")
MFS.CVars.applyLoadouts = CreateConVar("mfs_apply_loadouts", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable faction loadouts.")
MFS.CVars.allyBuff = CreateConVar("mfs_ally_buff", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable ally proximity resistance.")
MFS.CVars.debug = CreateConVar("mfs_debug", "0", { FCVAR_ARCHIVE }, "Verbose debug logs.")

function MFS.Log(text, ...)
    local payload = text
    if select("#", ...) > 0 then
        payload = string.format(text, ...)
    end
    print("[MilsimFrontier] " .. payload)
end

function MFS.Debug(text, ...)
    if not MFS.CVars.debug:GetBool() then
        return
    end
    MFS.Log(text, ...)
end

local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

local function AnyKeywordMatches(haystack, keywords)
    for _, keyword in ipairs(keywords) do
        if string.find(haystack, keyword, 1, true) then
            return true
        end
    end
    return false
end

function GM:CreateGameplayTeams()
    team.SetUp(MFS.Team.unassigned, "Unassigned", Color(140, 140, 140), true)
    team.SetUp(MFS.Team.rebels, MFS.GetFactionName("rebels"), Color(104, 193, 108), true)
    team.SetUp(MFS.Team.alliance, MFS.GetFactionName("alliance"), Color(84, 143, 255), true)
    team.SetUp(MFS.Team.outcasts, MFS.GetFactionName("outcasts"), Color(230, 136, 76), true)
end

function GM:AddWorkshopDependencies()
    for _, workshopID in pairs(MFS.WorkshopIDs) do
        resource.AddWorkshop(workshopID)
    end
end

function GM:EnforceTargetMap()
    if not MFS.CVars.lockMap:GetBool() then
        return
    end
    if game.GetMap() == MFS.TargetMap then
        return
    end

    local mapPath = "maps/" .. MFS.TargetMap .. ".bsp"
    if not file.Exists(mapPath, "GAME") then
        MFS.Log("Map lock skipped, target map not mounted: %s", mapPath)
        return
    end

    MFS.Log("Changing map to '%s' by map lock.", MFS.TargetMap)
    RunConsoleCommand("changelevel", MFS.TargetMap)
end

function GM:BuildModelPools()
    MFS.ModelPools = {}
    local allModels = player_manager.AllValidModels() or {}

    for factionID in pairs(MFS.Factions) do
        MFS.ModelPools[factionID] = {}
    end

    for modelName, modelPath in pairs(allModels) do
        local haystack = string.lower((modelName or "") .. " " .. (modelPath or ""))
        for factionID, keywords in pairs(MFS.ModelKeywords) do
            if AnyKeywordMatches(haystack, keywords) then
                MFS.ModelPools[factionID][modelPath] = true
            end
        end
    end

    for factionID, fallbackList in pairs(MFS.FallbackModels) do
        for _, modelPath in ipairs(fallbackList) do
            if file.Exists(modelPath, "GAME") then
                MFS.ModelPools[factionID][modelPath] = true
            end
        end
    end

    for factionID, pathSet in pairs(MFS.ModelPools) do
        local list = {}
        for modelPath in pairs(pathSet) do
            table.insert(list, modelPath)
        end
        table.sort(list)
        MFS.ModelPools[factionID] = list
        MFS.Debug("Model pool %s: %d entries.", factionID, #list)
    end
end

function GM:PickFactionModel(factionID)
    local pool = MFS.ModelPools[factionID]
    if not pool or #pool < 1 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

function GM:GetPlayerFaction(ply)
    return MFS.NormalizeFaction(ply:GetNWString("MFSFaction", ""))
end

function GM:GetPlayerClass(ply, factionID)
    return MFS.NormalizeClass(factionID, ply:GetNWString("MFSClass", ""))
end

function GM:SavePlayerRoleSelection(ply)
    if not IsValid(ply) or ply:IsBot() then
        return
    end

    local factionID = self:GetPlayerFaction(ply)
    local classID = self:GetPlayerClass(ply, factionID)
    if not factionID or not classID then
        return
    end

    ply:SetPData("mfs_faction", factionID)
    ply:SetPData("mfs_class", classID)
end

function GM:LoadPlayerRoleSelection(ply)
    local factionID = MFS.NormalizeFaction(ply:GetPData("mfs_faction", ""))
    if not factionID then
        return nil, nil
    end

    local classID = MFS.NormalizeClass(factionID, ply:GetPData("mfs_class", ""))
    if not classID then
        classID = MFS.DefaultClassByFaction[factionID]
    end

    return factionID, classID
end

function GM:SetPlayerRoleSelection(ply, rawFaction, rawClass, persist)
    local factionID = MFS.NormalizeFaction(rawFaction)
    if not factionID then
        return false, "Unknown faction."
    end

    local classID = MFS.NormalizeClass(factionID, rawClass)
    if not classID then
        return false, "Unknown class."
    end

    ply:SetNWString("MFSFaction", factionID)
    ply:SetNWString("MFSClass", classID)
    ply:SetNWBool("MFSChosenFaction", true)
    ply:SetTeam(MFS.Factions[factionID].team)

    if persist then
        self:SavePlayerRoleSelection(ply)
    end

    return true, factionID, classID
end

function GM:SendFactionMenu(ply, forced)
    net.Start(MFS.Net.openFactionMenu)
    net.WriteBool(forced and true or false)
    net.Send(ply)
end

function GM:EnsureFactionSelectionOrPrompt(ply)
    local factionID = self:GetPlayerFaction(ply)
    local classID = self:GetPlayerClass(ply, factionID)
    if factionID and classID then
        return true
    end

    local storedFaction, storedClass = self:LoadPlayerRoleSelection(ply)
    if storedFaction and storedClass then
        self:SetPlayerRoleSelection(ply, storedFaction, storedClass, false)
        return true
    end

    ply:SetNWBool("MFSChosenFaction", false)
    ply:SetTeam(MFS.Team.unassigned)
    ply:StripWeapons()
    ply:StripAmmo()
    ply:Freeze(true)
    ply:GodEnable()
    self:SendFactionMenu(ply, true)
    return false
end

function GM:GiveWeaponWithMags(ply, weaponClass, magazines)
    local wep = ply:Give(weaponClass)
    if not IsValid(wep) then
        return false
    end

    local ammoType = wep:GetPrimaryAmmoType()
    if ammoType and ammoType >= 0 then
        local clipSize = wep:GetMaxClip1()
        if not clipSize or clipSize <= 0 then
            clipSize = (wep.Primary and wep.Primary.ClipSize) or 30
        end
        local reserve = ClampAmount(magazines) * math.max(1, clipSize)
        if reserve > 0 then
            ply:GiveAmmo(reserve, ammoType, true)
        end
    end

    return true
end

function GM:ApplyFactionLoadout(ply)
    if not MFS.CVars.applyLoadouts:GetBool() then
        return
    end

    local factionID = self:GetPlayerFaction(ply)
    local classID = self:GetPlayerClass(ply, factionID)
    if not factionID or not classID then
        return
    end

    local classData = MFS.Factions[factionID].classes[classID]
    ply:StripWeapons()
    ply:StripAmmo()

    for _, weaponInfo in ipairs(classData.weapons or {}) do
        self:GiveWeaponWithMags(ply, weaponInfo.class, weaponInfo.magazines or 0)
    end
    for _, utilityClass in ipairs(classData.utility or {}) do
        if not ply:HasWeapon(utilityClass) then
            ply:Give(utilityClass)
        end
    end

    if ply.MFSUnlocks then
        for weaponClass, magazines in pairs(ply.MFSUnlocks) do
            self:GiveWeaponWithMags(ply, weaponClass, magazines)
        end
    end

    local health = math.max(1, ClampAmount(classData.health or 100))
    local armor = math.max(0, ClampAmount(classData.armor or 0))
    ply:SetMaxHealth(health)
    ply:SetHealth(health)
    ply:SetArmor(armor)
end

function GM:ApplyFactionModel(ply)
    if not MFS.CVars.applyModels:GetBool() then
        return
    end

    local factionID = self:GetPlayerFaction(ply)
    local modelPath = factionID and self:PickFactionModel(factionID) or nil
    if modelPath then
        ply:SetModel(modelPath)
    end
end

function GM:TryPickNavPosition()
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

local function DistSqrToNearest(candidatePos, predicate)
    local nearestSqr = nil
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and (not predicate or predicate(ply)) then
            local distSqr = candidatePos:DistToSqr(ply:GetPos())
            if not nearestSqr or distSqr < nearestSqr then
                nearestSqr = distSqr
            end
        end
    end
    return nearestSqr
end

function GM:RelocateOutcastSpawn(ply)
    local minPlayersSqr = MFS.OutcastSpawn.minDistanceFromPlayers ^ 2
    local minFactionSqr = MFS.OutcastSpawn.minDistanceFromRebelAlliance ^ 2

    for _ = 1, 80 do
        local pos = self:TryPickNavPosition()
        if pos then
            local nearAny = DistSqrToNearest(pos, nil)
            local nearMain = DistSqrToNearest(pos, function(target)
                local factionID = self:GetPlayerFaction(target)
                return factionID == "rebels" or factionID == "alliance"
            end)

            local passAny = (not nearAny) or nearAny >= minPlayersSqr
            local passMain = (not nearMain) or nearMain >= minFactionSqr
            if passAny and passMain then
                ply:SetPos(pos + Vector(0, 0, 12))
                ply:SetEyeAngles(Angle(0, math.random(0, 359), 0))
                return
            end
        end
    end
end

function GM:PlayerInitialSpawn(ply)
    if self.BaseClass and self.BaseClass.PlayerInitialSpawn then
        self.BaseClass.PlayerInitialSpawn(self, ply)
    end
    if self.InitializeMaterialInventory then
        self:InitializeMaterialInventory(ply)
        self:SyncMaterialInventory(ply)
    end
    if self.LoadCraftUnlocks then
        self:LoadCraftUnlocks(ply)
    end
end

function GM:PlayerSpawn(ply)
    if self.BaseClass and self.BaseClass.PlayerSpawn then
        self.BaseClass.PlayerSpawn(self, ply)
    end
    if not MFS.CVars.enabled:GetBool() then
        return
    end

    timer.Simple(0.05, function()
        if not IsValid(ply) then
            return
        end
        if not self:EnsureFactionSelectionOrPrompt(ply) then
            return
        end

        ply:Freeze(false)
        ply:GodDisable()
        self:ApplyFactionLoadout(ply)
        self:ApplyFactionModel(ply)

        if self:GetPlayerFaction(ply) == "outcasts" then
            self:RelocateOutcastSpawn(ply)
        end
    end)
end

function GM:PlayerDisconnected(ply)
    if self.BaseClass and self.BaseClass.PlayerDisconnected then
        self.BaseClass.PlayerDisconnected(self, ply)
    end
    self:SavePlayerRoleSelection(ply)
    if self.SaveMaterialInventory then
        self:SaveMaterialInventory(ply)
    end
    if self.SaveCraftUnlocks then
        self:SaveCraftUnlocks(ply)
    end
end

function GM:UpdateAllyBuff()
    if not MFS.CVars.allyBuff:GetBool() then
        for _, ply in ipairs(player.GetAll()) do
            ply:SetNWFloat("MFSAllyResistance", 0)
        end
        return
    end

    local radiusSqr = MFS.AllyBuff.radius * MFS.AllyBuff.radius
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local factionID = self:GetPlayerFaction(ply)
            if not factionID or factionID == "outcasts" then
                ply:SetNWFloat("MFSAllyResistance", 0)
            else
                local allies = 0
                local origin = ply:GetPos()
                for _, other in ipairs(player.GetAll()) do
                    if other ~= ply and IsValid(other) and other:Alive() then
                        if self:GetPlayerFaction(other) == factionID and origin:DistToSqr(other:GetPos()) <= radiusSqr then
                            allies = allies + 1
                        end
                    end
                end
                local res = math.min(MFS.AllyBuff.maxResistance, allies * MFS.AllyBuff.resistancePerAlly)
                ply:SetNWFloat("MFSAllyResistance", res)
            end
        end
    end
end

function GM:EntityTakeDamage(target, dmgInfo)
    if self.BaseClass and self.BaseClass.EntityTakeDamage then
        self.BaseClass.EntityTakeDamage(self, target, dmgInfo)
    end
    if target:IsPlayer() then
        local resistance = math.Clamp(target:GetNWFloat("MFSAllyResistance", 0), 0, 0.9)
        if resistance > 0 then
            dmgInfo:ScaleDamage(1 - resistance)
        end
    end
end

function GM:Initialize()
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize(self)
    end
    self:CreateGameplayTeams()
    self:AddWorkshopDependencies()

    timer.Simple(5, function()
        if GAMEMODE and GAMEMODE.EnforceTargetMap then
            GAMEMODE:EnforceTargetMap()
        end
    end)

    timer.Create("MFS.AllyBuffTick", 1, 0, function()
        if GAMEMODE and GAMEMODE.UpdateAllyBuff then
            GAMEMODE:UpdateAllyBuff()
        end
    end)

    timer.Create("MFS.FactionMenuReminder", 8, 0, function()
        if not GAMEMODE or not GAMEMODE.EnsureFactionSelectionOrPrompt then
            return
        end

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then
                local factionID = GAMEMODE:GetPlayerFaction(ply)
                local classID = GAMEMODE:GetPlayerClass(ply, factionID)
                if not factionID or not classID then
                    GAMEMODE:EnsureFactionSelectionOrPrompt(ply)
                end
            end
        end
    end)
end

function GM:InitPostEntity()
    if self.BaseClass and self.BaseClass.InitPostEntity then
        self.BaseClass.InitPostEntity(self)
    end
    self:BuildModelPools()
    if self.ValidateSetup then
        self:ValidateSetup(nil)
    end
end

net.Receive(MFS.Net.submitFaction, function(_, ply)
    local factionID = net.ReadString()
    local classID = net.ReadString()
    local ok = GAMEMODE:SetPlayerRoleSelection(ply, factionID, classID, true)
    if ok then
        ply:Spawn()
    else
        GAMEMODE:SendFactionMenu(ply, true)
    end
end)

concommand.Add("mfs_choose_faction", function(ply)
    if IsValid(ply) then
        GAMEMODE:SendFactionMenu(ply, true)
    end
end)

concommand.Add("mfs_join_class", function(ply, _, args)
    if not IsValid(ply) then
        return
    end
    local classID = args[1]
    if not classID then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Usage: mfs_join_class <class>\n")
        return
    end

    local factionID = GAMEMODE:GetPlayerFaction(ply)
    if not factionID then
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] Select faction first.\n")
        return
    end

    local ok, message = GAMEMODE:SetPlayerRoleSelection(ply, factionID, classID, true)
    if ok then
        ply:Spawn()
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "[MilsimFrontier] " .. (message or "Unknown error") .. "\n")
    end
end)
