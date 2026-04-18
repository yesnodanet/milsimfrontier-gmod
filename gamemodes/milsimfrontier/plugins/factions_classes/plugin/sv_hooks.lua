local function FindClassByName(className)
    if not className then
        return nil
    end

    for _, classTable in pairs(Clockwork.class:GetAll()) do
        if string.lower(classTable.name) == string.lower(className) then
            return classTable
        end
    end

    return nil
end

function PLUGIN:GetDefaultClassForFaction(factionName)
    return MFS.DefaultClassByFaction[factionName]
end

function PLUGIN:EnsureClassForPlayer(player)
    if not IsValid(player) then
        return false
    end

    local factionName = player:GetFaction()
    if not factionName or factionName == "" then
        return false
    end

    local className = player:GetCharacterData("Class")
    local classTable = FindClassByName(className)

    if classTable and classTable.factions and table.HasValue(classTable.factions, factionName) then
        if player:Team() ~= classTable.index then
            Clockwork.class:Set(player, classTable.index, true)
        end
        return true
    end

    local defaultClassName = self:GetDefaultClassForFaction(factionName)
    local defaultClass = FindClassByName(defaultClassName)

    if defaultClass and defaultClass.factions and table.HasValue(defaultClass.factions, factionName) then
        player:SetCharacterData("Class", defaultClass.name, true)
        Clockwork.class:Set(player, defaultClass.index, true)
        return true
    end

    return false
end

function PLUGIN:PlayerAdjustCharacterCreationInfo(player, info, data)
    if not info or not info.faction or not info.data then
        return
    end

    if not info.data["Class"] then
        local defaultClassName = self:GetDefaultClassForFaction(info.faction)
        if defaultClassName then
            info.data["Class"] = defaultClassName
        end
    end
end

function PLUGIN:PlayerCharacterInitialized(player)
    self:EnsureClassForPlayer(player)
end
