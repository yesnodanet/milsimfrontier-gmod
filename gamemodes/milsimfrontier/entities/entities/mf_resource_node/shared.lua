ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Resource Node"
ENT.Category = "Milsim Frontier"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MaterialID")
    self:NetworkVar("Int", 0, "Amount")
end

