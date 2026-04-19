AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local function Clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function ENT:Initialize()
    self:SetModel("models/props_junk/wood_crate001a.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysicsInit(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
end

function ENT:ConfigureStructure(state, structureDef)
    local level = Clamp(tonumber(state.level) or 1, 1, structureDef.maxLevel)
    local model = structureDef.model
    if model and util.IsValidModel(model) then
        self:SetModel(model)
    end

    local maxHealth = structureDef.baseHealth + ((level - 1) * structureDef.healthPerLevel)
    local health = Clamp(tonumber(state.health) or maxHealth, 1, maxHealth)

    self:SetStructureUID(state.uid or "")
    self:SetStructureTypeID(state.typeID or "")
    self:SetOwnerSteamID64(state.ownerSteamID64 or "")
    self:SetOwnerFaction(state.ownerFaction or "")
    self:SetStructureLevel(level)
    self:SetStructureMaxHealth(maxHealth)
    self:SetStructureHealth(health)
end

function ENT:ApplyLevel(level, structureDef)
    local clampedLevel = Clamp(tonumber(level) or 1, 1, structureDef.maxLevel)
    local previousMax = math.max(1, self:GetStructureMaxHealth())
    local healthFraction = Clamp(self:GetStructureHealth() / previousMax, 0, 1)

    local nextMax = structureDef.baseHealth + ((clampedLevel - 1) * structureDef.healthPerLevel)
    self:SetStructureLevel(clampedLevel)
    self:SetStructureMaxHealth(nextMax)
    self:SetStructureHealth(Clamp(math.floor(nextMax * healthFraction), 1, nextMax))
end

function ENT:Repair(amount)
    local maxHealth = math.max(1, self:GetStructureMaxHealth())
    local current = Clamp(self:GetStructureHealth(), 0, maxHealth)
    self:SetStructureHealth(Clamp(current + amount, 0, maxHealth))
end

function ENT:IsDestroyed()
    return self:GetStructureHealth() <= 0
end

function ENT:OnTakeDamage(damageInfo)
    if not (cwMFSBase and cwMFSBase.IsEnabled and cwMFSBase:IsEnabled()) then
        return
    end

    local current = self:GetStructureHealth()
    if current <= 0 then
        return
    end

    local nextValue = current - math.max(0, math.floor(damageInfo:GetDamage()))
    self:SetStructureHealth(nextValue)

    if nextValue <= 0 and cwMFSBase and cwMFSBase.HandleStructureDestroyed then
        cwMFSBase:HandleStructureDestroyed(self, damageInfo:GetAttacker(), damageInfo)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then
        return
    end

    local structureID = self:GetStructureTypeID()
    local structureDef = MFS.GetStructureDef(structureID)
    if not structureDef then
        return
    end

    if structureID == "workbench" then
        activator:ChatPrint("Workbench ready. Use mfs_recipes and mfs_craft <recipeID>.")
    elseif structureID == "storage" then
        activator:ChatPrint("Storage structure deployed.")
    else
        activator:ChatPrint(string.format("%s L%d | HP: %d/%d", structureDef.name, self:GetStructureLevel(), self:GetStructureHealth(), self:GetStructureMaxHealth()))
    end
end
