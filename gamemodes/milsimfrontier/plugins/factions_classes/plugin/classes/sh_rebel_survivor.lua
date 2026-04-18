local classCfg = MFS.Classes.survivor

local CLASS = Clockwork.class:New(classCfg.name)
CLASS.color = Color(104, 193, 108)
CLASS.factions = {classCfg.faction}
CLASS.isDefault = classCfg.isDefault
CLASS.isOnCharScreen = classCfg.isOnCharScreen
CLASS.description = classCfg.description
CLASS_REBEL_SURVIVOR = CLASS:Register()
