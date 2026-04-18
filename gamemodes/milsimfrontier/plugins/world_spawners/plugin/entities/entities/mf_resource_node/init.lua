AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local function PickRandomModel()
    local models = (MFS and MFS.NodeModels) or {
        "models/props_junk/wood_crate001a.mdl",
        "models/props_junk/garbage_metalcan001a.mdl"
    }

    return models[math.random(1, #models)]
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

    if materialID ~= "" and cwMFSMaterials and cwMFSMaterials.AddMaterial then
        local granted = cwMFSMaterials:AddMaterial(activator, materialID, amount, true)

        if granted > 0 then
            local matName = (MFS and MFS.Materials[materialID] and MFS.Materials[materialID].name) or materialID
            activator:ChatPrint(string.format("Picked up %s x%d", matName, granted))
        else
            activator:ChatPrint("Inventory is full.")
            return
        end
    end

    self:EmitSound("items/ammo_pickup.wav", 70, 105, 0.8)
    self:Remove()
end
