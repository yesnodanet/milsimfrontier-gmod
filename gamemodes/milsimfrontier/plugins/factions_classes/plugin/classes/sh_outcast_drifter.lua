local classCfg = MFS.Classes.drifter

local CLASS = Clockwork.class:New(classCfg.name)
CLASS.color = Color(230, 136, 76)
CLASS.factions = {classCfg.faction}
CLASS.isDefault = classCfg.isDefault
CLASS.isOnCharScreen = classCfg.isOnCharScreen
CLASS.description = classCfg.description
CLASS_OUTCAST_DRIFTER = CLASS:Register()
