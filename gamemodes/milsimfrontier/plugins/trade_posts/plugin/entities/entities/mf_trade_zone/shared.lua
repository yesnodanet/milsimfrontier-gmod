ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "MFS Trade Zone"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ZoneID")
    self:NetworkVar("Float", 0, "ZoneRadius")
    self:NetworkVar("Bool", 0, "ZoneActive")
    self:NetworkVar("Float", 1, "NextSwitchAt")
end
