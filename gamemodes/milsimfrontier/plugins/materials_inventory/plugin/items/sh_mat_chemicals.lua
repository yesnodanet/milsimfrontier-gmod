local ITEM = Clockwork.item:New()
ITEM.name = "Chemicals"
ITEM.uniqueID = "mf_mat_chemicals"
ITEM.model = "models/props_lab/jar01b.mdl"
ITEM.weight = 0
ITEM.space = 0
ITEM.category = "Materials"
ITEM.description = "Chemical reagents used for medical and weapon assembly."
ITEM.business = false

function ITEM:OnDrop(player, position)
    Clockwork.player:Notify(player, "Materials cannot be dropped.")
    return false
end

function ITEM:OnUse(player)
    return false
end

ITEM:Register()
