ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "MFS Build Structure"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "StructureUID")
    self:NetworkVar("String", 1, "StructureTypeID")
    self:NetworkVar("String", 2, "OwnerSteamID64")
    self:NetworkVar("String", 3, "OwnerFaction")
    self:NetworkVar("Int", 0, "StructureLevel")
    self:NetworkVar("Float", 0, "StructureHealth")
    self:NetworkVar("Float", 1, "StructureMaxHealth")
end
