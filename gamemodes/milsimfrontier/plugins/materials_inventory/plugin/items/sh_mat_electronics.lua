local ITEM = Clockwork.item:New()
ITEM.name = "Electronics"
ITEM.uniqueID = "mf_mat_electronics"
ITEM.model = "models/props_lab/harddrive01.mdl"
ITEM.weight = 0
ITEM.space = 0
ITEM.category = "Materials"
ITEM.description = "Electronic parts required for advanced weapon construction."
ITEM.business = false

function ITEM:OnDrop(player, position)
    Clockwork.player:Notify(player, "Materials cannot be dropped.")
    return false
end

function ITEM:OnUse(player)
    return false
end

ITEM:Register()
