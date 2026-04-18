local ITEM = Clockwork.item:New()
ITEM.name = "Cloth"
ITEM.uniqueID = "mf_mat_cloth"
ITEM.model = "models/props_junk/cardboard_box004a.mdl"
ITEM.weight = 0
ITEM.space = 0
ITEM.category = "Materials"
ITEM.description = "Bandages and textile scraps used in survival recipes."
ITEM.business = false

function ITEM:OnDrop(player, position)
    Clockwork.player:Notify(player, "Materials cannot be dropped.")
    return false
end

function ITEM:OnUse(player)
    return false
end

ITEM:Register()
