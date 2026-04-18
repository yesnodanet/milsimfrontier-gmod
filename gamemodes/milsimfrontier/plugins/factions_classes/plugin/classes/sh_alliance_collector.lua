local classCfg = MFS.Classes.collector

local CLASS = Clockwork.class:New(classCfg.name)
CLASS.color = Color(64, 191, 223)
CLASS.factions = {classCfg.faction}
CLASS.isDefault = classCfg.isDefault
CLASS.isOnCharScreen = classCfg.isOnCharScreen
CLASS.description = classCfg.description
CLASS_ALLIANCE_COLLECTOR = CLASS:Register()
