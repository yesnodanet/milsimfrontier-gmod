AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local RESOURCE_MODELS = {
    "models/props_junk/wood_crate001a.mdl",
    "models/props_junk/garbage_metalcan001a.mdl",
    "models/props_junk/cardboard_box004a.mdl",
    "models/props_junk/PlasticCrate01a.mdl"
}

local function PickRandomModel()
    return RESOURCE_MODELS[math.random(1, #RESOURCE_MODELS)]
end

function ENT:Initialize()
    self:SetModel(PickRandomModel())
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysicsInit(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
end

function ENT:ConfigureNode(materialID, amount)
    self:SetMaterialID(materialID)
    self:SetAmount(math.max(1, math.floor(amount or 1)))
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then
        return
    end

    if self.NextUse and self.NextUse > CurTime() then
        return
    end
    self.NextUse = CurTime() + 0.25

    local materialID = self:GetMaterialID()
    local amount = math.max(1, self:GetAmount())
    if GAMEMODE and GAMEMODE.AddMaterial and materialID ~= "" then
        GAMEMODE:AddMaterial(activator, materialID, amount, true)
        activator:ChatPrint(string.format("Picked up %s x%d", (MFS and MFS.Materials[materialID] and MFS.Materials[materialID].name) or materialID, amount))
    end

    self:EmitSound("items/ammo_pickup.wav", 70, 105, 0.8)
    self:Remove()
end

