local classCfg = MFS.Classes.fighter

local CLASS = Clockwork.class:New(classCfg.name)
CLASS.color = Color(84, 143, 255)
CLASS.factions = {classCfg.faction}
CLASS.isDefault = classCfg.isDefault
CLASS.isOnCharScreen = classCfg.isOnCharScreen
CLASS.description = classCfg.description
CLASS_ALLIANCE_FIGHTER = CLASS:Register()
