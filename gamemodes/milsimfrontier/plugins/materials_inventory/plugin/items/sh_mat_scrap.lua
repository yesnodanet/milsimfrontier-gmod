local ITEM = Clockwork.item:New()
ITEM.name = "Scrap"
ITEM.uniqueID = "mf_mat_scrap"
ITEM.model = "models/props_junk/garbage_metalcan001a.mdl"
ITEM.weight = 0
ITEM.space = 0
ITEM.category = "Materials"
ITEM.description = "A stack of scrap metal parts for crafting."
ITEM.business = false

function ITEM:OnDrop(player, position)
    Clockwork.player:Notify(player, "Materials cannot be dropped.")
    return false
end

function ITEM:OnUse(player)
    return false
end

ITEM:Register()
