DeriveGamemode("sandbox")

GM.Name = "Milsim Frontier"
GM.Author = "Codex + User"
GM.Email = ""
GM.Website = ""

include("sh_config.lua")

MFS.Net = {
    openFactionMenu = "mfs_open_faction_menu",
    submitFaction = "mfs_submit_faction",
    syncMaterials = "mfs_sync_materials",
    craftRequest = "mfs_craft_request",
    craftResult = "mfs_craft_result"
}

MFS.ModelPools = MFS.ModelPools or {}

local materialKeyCache = nil

function MFS.GetMaterialKeys()
    if materialKeyCache then
        return materialKeyCache
    end

    materialKeyCache = {}
    for materialID in pairs(MFS.Materials) do
        table.insert(materialKeyCache, materialID)
    end
    table.sort(materialKeyCache)
    return materialKeyCache
end

function MFS.NormalizeFaction(rawFaction)
    if not rawFaction then
        return nil
    end

    local cleaned = string.Trim(string.lower(rawFaction))
    if MFS.Factions[cleaned] then
        return cleaned
    end

    for factionID, factionData in pairs(MFS.Factions) do
        if string.lower(factionData.name or "") == cleaned then
            return factionID
        end
    end

    return nil
end

function MFS.NormalizeClass(factionID, rawClass)
    if not factionID or not MFS.Factions[factionID] then
        return nil
    end

    local classMap = MFS.Factions[factionID].classes or {}
    if not rawClass or rawClass == "" then
        return MFS.DefaultClassByFaction[factionID]
    end

    local cleaned = string.Trim(string.lower(rawClass))
    if classMap[cleaned] then
        return cleaned
    end

    for classID, classData in pairs(classMap) do
        if string.lower(classData.name or "") == cleaned then
            return classID
        end
    end

    return nil
end

function MFS.GetFactionName(factionID)
    return (MFS.Factions[factionID] and MFS.Factions[factionID].name) or factionID or "Unknown"
end

function MFS.GetClassName(factionID, classID)
    local factionData = MFS.Factions[factionID]
    if not factionData then
        return classID or "Unknown"
    end

    local classData = factionData.classes and factionData.classes[classID]
    return (classData and classData.name) or classID or "Unknown"
end

