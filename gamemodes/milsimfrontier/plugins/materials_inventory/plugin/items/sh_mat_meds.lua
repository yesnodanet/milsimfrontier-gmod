local ITEM = Clockwork.item:New()
ITEM.name = "Med Supplies"
ITEM.uniqueID = "mf_mat_meds"
ITEM.model = "models/items/healthkit.mdl"
ITEM.weight = 0
ITEM.space = 0
ITEM.category = "Materials"
ITEM.description = "Medical components for treatment gear and healing kits."
ITEM.business = false

function ITEM:OnDrop(player, position)
    Clockwork.player:Notify(player, "Materials cannot be dropped.")
    return false
end

function ITEM:OnUse(player)
    return false
end

ITEM:Register()
