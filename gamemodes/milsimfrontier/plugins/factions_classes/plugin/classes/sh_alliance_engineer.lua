local classCfg = MFS.Classes.engineer

local CLASS = Clockwork.class:New(classCfg.name)
CLASS.color = Color(74, 170, 255)
CLASS.factions = {classCfg.faction}
CLASS.isDefault = classCfg.isDefault
CLASS.isOnCharScreen = classCfg.isOnCharScreen
CLASS.description = classCfg.description
CLASS_ALLIANCE_ENGINEER = CLASS:Register()
