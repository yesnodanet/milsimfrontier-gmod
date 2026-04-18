local factionCfg = MFS.Factions.alliance

local FACTION = Clockwork.faction:New(factionCfg.name)
FACTION.description = factionCfg.description
FACTION.color = factionCfg.color
FACTION.useFullName = true
FACTION.models = {
    male = factionCfg.models,
    female = factionCfg.models
}
FACTION_ALLIANCE = FACTION:Register()
