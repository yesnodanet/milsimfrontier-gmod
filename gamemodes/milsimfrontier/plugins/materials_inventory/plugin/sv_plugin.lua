util.AddNetworkString("MFS.SyncMaterials")

local function ClampAmount(value)
    return math.max(0, math.floor(value or 0))
end

function PLUGIN:IsMaterialItemID(itemID)
    for _, materialInfo in pairs(MFS.Materials) do
        if materialInfo.itemID == itemID then
            return true
        end
    end

    return false
end

function PLUGIN:GetMaterialItemID(materialID)
    local materialInfo = MFS.Materials[materialID]
    return materialInfo and materialInfo.itemID or nil
end

function PLUGIN:GetMaterialAmount(player, materialID)
    local itemID = self:GetMaterialItemID(materialID)
    if not itemID then
        return 0
    end

    local matches = player:GetItemsByID(itemID) or {}
    return table.Count(matches)
end

function PLUGIN:GetMaterialSnapshot(player)
    local snapshot = {}

    for _, materialID in ipairs(MFS.GetMaterialKeys()) do
        snapshot[materialID] = self:GetMaterialAmount(player, materialID)
    end

    return snapshot
end

function PLUGIN:SyncMaterialInventory(player)
    if not IsValid(player) then
        return
    end

    local snapshot = self:GetMaterialSnapshot(player)
    local keys = MFS.GetMaterialKeys()

    net.Start("MFS.SyncMaterials")
    net.WriteUInt(#keys, 8)

    for _, materialID in ipairs(keys) do
        net.WriteString(materialID)
        net.WriteUInt(ClampAmount(snapshot[materialID]), 16)
    end

    net.Send(player)
    player:SetCharacterData("MFSMaterials", snapshot, true)
end

function PLUGIN:AddMaterial(player, materialID, amount, silent)
    if not IsValid(player) then
        return 0
    end

    local itemID = self:GetMaterialItemID(materialID)
    if not itemID then
        return 0
    end

    local toGive = ClampAmount(amount)
    local given = 0

    for _ = 1, toGive do
        local item = player:GiveItem(itemID)
        if item then
            given = given + 1
        else
            break
        end
    end

    self:SyncMaterialInventory(player)

    if not silent and given > 0 then
        local matName = (MFS.Materials[materialID] and MFS.Materials[materialID].name) or materialID
        Clockwork.player:Notify(player, string.format("Received %s x%d.", matName, given))
    end

    if not silent and given < toGive then
        Clockwork.player:Notify(player, "Inventory full, some materials were not added.")
    end

    return given
end

function PLUGIN:TakeMaterial(player, materialID, amount)
    if not IsValid(player) then
        return 0
    end

    local itemID = self:GetMaterialItemID(materialID)
    if not itemID then
        return 0
    end

    local toTake = ClampAmount(amount)
    local taken = 0

    for _ = 1, toTake do
        local item = player:FindItemByID(itemID)
        if not item then
            break
        end

        player:TakeItem(item)
        taken = taken + 1
    end

    self:SyncMaterialInventory(player)
    return taken
end

function PLUGIN:HasMaterials(player, costs)
    for materialID, needed in pairs(costs or {}) do
        if self:GetMaterialAmount(player, materialID) < ClampAmount(needed) then
            return false, materialID
        end
    end

    return true
end

function PLUGIN:ConsumeMaterials(player, costs)
    local hasAll, missing = self:HasMaterials(player, costs)
    if not hasAll then
        return false, missing
    end

    for materialID, needed in pairs(costs or {}) do
        self:TakeMaterial(player, materialID, needed)
    end

    return true
end

function PLUGIN:PlayerCharacterInitialized(player)
    self:SyncMaterialInventory(player)
end

function PLUGIN:PlayerItemGiven(player, itemTable)
    if itemTable and self:IsMaterialItemID(itemTable("uniqueID")) then
        self:SyncMaterialInventory(player)
    end
end

function PLUGIN:PlayerItemTaken(player, itemTable)
    if itemTable and self:IsMaterialItemID(itemTable("uniqueID")) then
        self:SyncMaterialInventory(player)
    end
end
