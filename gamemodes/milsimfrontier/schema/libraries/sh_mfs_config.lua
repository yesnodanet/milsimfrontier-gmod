MFS = MFS or {}

local cfg = MFS

cfg.Version = "3.0.0-cw"
cfg.TargetMap = "gm_fork"

cfg.WorkshopIDs = {
    map = "326332456",
    weapons = "2588031232",
    allianceModels = "3332624202",
    rebelModels = "1594326092",
    outcastModels = "355101935"
}

cfg.Materials = {
    scrap = {name = "Scrap", itemID = "mf_mat_scrap", color = Color(192, 192, 192)},
    cloth = {name = "Cloth", itemID = "mf_mat_cloth", color = Color(200, 170, 140)},
    chemicals = {name = "Chemicals", itemID = "mf_mat_chemicals", color = Color(130, 220, 130)},
    electronics = {name = "Electronics", itemID = "mf_mat_electronics", color = Color(130, 170, 255)},
    meds = {name = "Med Supplies", itemID = "mf_mat_meds", color = Color(255, 150, 150)}
}

cfg.MaterialDropPool = {
    "scrap",
    "scrap",
    "cloth",
    "chemicals",
    "electronics",
    "meds"
}

cfg.Recipes = {
    medkit = {
        name = "Field Medkit",
        blueprintID = "mfs_medkit",
        resultType = "weapon",
        resultClass = "tacrp_medkit",
        resultMagazines = 0,
        costs = {
            cloth = 4,
            chemicals = 3,
            meds = 4
        }
    },
    mp5 = {
        name = "TacRP MP5",
        blueprintID = "mfs_mp5",
        resultType = "weapon",
        resultClass = "tacrp_mp5",
        resultMagazines = 2,
        costs = {
            scrap = 8,
            electronics = 3,
            cloth = 2
        }
    },
    k1a = {
        name = "TacRP K1A",
        blueprintID = "mfs_k1a",
        resultType = "weapon",
        resultClass = "tacrp_k1a",
        resultMagazines = 2,
        costs = {
            scrap = 9,
            electronics = 4,
            chemicals = 1
        }
    },
    skorpion = {
        name = "TacRP Skorpion",
        blueprintID = "mfs_skorpion",
        resultType = "weapon",
        resultClass = "tacrp_skorpion",
        resultMagazines = 2,
        costs = {
            scrap = 6,
            electronics = 2
        }
    }
}

cfg.Resource = {
    maxNodes = 140,
    spawnInterval = 18,
    nodeLifetime = 1200,
    amountMin = 2,
    amountMax = 5,
    minPlayerDistance = 180
}

cfg.Enemies = {
    enabled = true,
    maxAlive = 64,
    spawnInterval = 20,
    minDistanceFromPlayers = 1500,
    maxDistanceFromPlayers = 7000,
    classes = {
        "npc_zombie",
        "npc_fastzombie",
        "npc_poisonzombie"
    },
    dropAmountMin = 1,
    dropAmountMax = 3
}

cfg.OutcastSpawn = {
    minDistanceFromPlayers = 2600,
    minDistanceFromRebelAlliance = 1800
}

cfg.AllyBuff = {
    radius = 600,
    resistancePerAlly = 0.04,
    maxResistance = 0.20
}

cfg.BaseBuilding = {
    enabled = true,
    maxStructuresPerPlayer = 45,
    maxStructuresGlobal = 300,
    placementDistance = 240,
    minSpacing = 70,
    saveInterval = 45,
    repairChunk = 120,
    structureClass = "mf_build_structure",
    types = {
        barricade = {
            name = "Barricade",
            model = "models/props_debris/wood_board04a.mdl",
            maxLevel = 3,
            baseHealth = 350,
            healthPerLevel = 200,
            buildCost = {scrap = 6, cloth = 2},
            upgradeCosts = {
                [2] = {scrap = 5, cloth = 2},
                [3] = {scrap = 8, electronics = 2}
            },
            repairCost = {scrap = 1}
        },
        workbench = {
            name = "Workbench",
            model = "models/props_c17/FurnitureTable001a.mdl",
            maxLevel = 3,
            baseHealth = 420,
            healthPerLevel = 240,
            buildCost = {scrap = 9, electronics = 3, cloth = 1},
            upgradeCosts = {
                [2] = {scrap = 6, electronics = 2},
                [3] = {scrap = 9, electronics = 4, chemicals = 1}
            },
            repairCost = {scrap = 1, electronics = 1}
        },
        storage = {
            name = "Field Storage",
            model = "models/props_junk/wood_crate001a.mdl",
            maxLevel = 3,
            baseHealth = 500,
            healthPerLevel = 260,
            buildCost = {scrap = 8, cloth = 3},
            upgradeCosts = {
                [2] = {scrap = 6, cloth = 3},
                [3] = {scrap = 9, cloth = 5, electronics = 2}
            },
            repairCost = {scrap = 2, cloth = 1}
        }
    }
}

cfg.TradePosts = {
    enabled = true,
    tickInterval = 1,
    activeDuration = 320,
    cooldownDuration = 720,
    mapZones = {
        gm_fork = {
            {id = "fork_market_north", position = Vector(1210, -2500, 120), radius = 420, activeOffset = 30},
            {id = "fork_market_south", position = Vector(-3160, 820, 116), radius = 420, activeOffset = 180},
            {id = "fork_market_valley", position = Vector(3380, 4550, 130), radius = 420, activeOffset = 330}
        }
    }
}

cfg.NodeModels = {
    "models/props_junk/wood_crate001a.mdl",
    "models/props_junk/garbage_metalcan001a.mdl",
    "models/props_junk/cardboard_box004a.mdl",
    "models/props_junk/PlasticCrate01a.mdl"
}

cfg.Factions = {
    rebels = {
        name = "Rebels",
        description = "Scavenging survivors focused on long-term resilience.",
        color = Color(104, 193, 108),
        models = {
            "models/gst_defectors/pm/gst_defector_03.mdl",
            "models/humans/group03/male_04.mdl",
            "models/humans/group03/female_04.mdl"
        }
    },
    alliance = {
        name = "Alliance",
        description = "Structured military force with strict class specialisation.",
        color = Color(84, 143, 255),
        models = {
            "models/player/combine_soldier.mdl",
            "models/player/combine_super_soldier.mdl",
            "models/player/police.mdl"
        }
    },
    outcasts = {
        name = "Outcasts",
        description = "Solo opportunists hostile to everyone.",
        color = Color(230, 136, 76),
        models = {
            "models/player/odessa.mdl",
            "models/player/group03m/male_06.mdl",
            "models/player/group03m/female_02.mdl"
        }
    }
}

cfg.Classes = {
    survivor = {
        name = "Survivor",
        faction = "Rebels",
        isDefault = true,
        isOnCharScreen = false,
        description = "Default rebel survivalist role."
    },
    fighter = {
        name = "Fighter",
        faction = "Alliance",
        isDefault = true,
        isOnCharScreen = true,
        description = "Frontline assault specialist."
    },
    engineer = {
        name = "Engineer",
        faction = "Alliance",
        isDefault = false,
        isOnCharScreen = true,
        description = "Support and utility specialist."
    },
    collector = {
        name = "Collector",
        faction = "Alliance",
        isDefault = false,
        isOnCharScreen = true,
        description = "Fast looter and resource runner."
    },
    drifter = {
        name = "Drifter",
        faction = "Outcasts",
        isDefault = true,
        isOnCharScreen = false,
        description = "Lone outcast operative."
    }
}

cfg.Loadouts = {
    Survivor = {
        weapons = {
            {class = "tacrp_p2000", magazines = 2}
        },
        utility = {
            "tacrp_medkit"
        },
        health = 100,
        armor = 0
    },
    Fighter = {
        weapons = {
            {class = "tacrp_mp5", magazines = 4},
            {class = "tacrp_p250", magazines = 2}
        },
        utility = {
            "tacrp_medkit",
            "tacrp_nade_smoke"
        },
        health = 100,
        armor = 45
    },
    Engineer = {
        weapons = {
            {class = "tacrp_k1a", magazines = 3},
            {class = "tacrp_p2000", magazines = 2}
        },
        utility = {
            "tacrp_medkit",
            "weapon_physgun",
            "gmod_tool"
        },
        health = 100,
        armor = 30
    },
    Collector = {
        weapons = {
            {class = "tacrp_mp7", magazines = 3},
            {class = "tacrp_p2000", magazines = 2}
        },
        utility = {
            "tacrp_medkit",
            "weapon_crowbar"
        },
        health = 100,
        armor = 20
    },
    Drifter = {
        weapons = {
            {class = "tacrp_p2000", magazines = 2}
        },
        utility = {},
        health = 100,
        armor = 0
    }
}

cfg.DefaultClassByFaction = {
    Rebels = "Survivor",
    Alliance = "Fighter",
    Outcasts = "Drifter"
}

local materialKeys = nil

function MFS.GetMaterialKeys()
    if materialKeys then
        return materialKeys
    end

    materialKeys = {}
    for materialID in pairs(MFS.Materials) do
        table.insert(materialKeys, materialID)
    end
    table.sort(materialKeys)
    return materialKeys
end

function MFS.GetFactionDataByName(name)
    if not name then
        return nil, nil
    end

    local lowered = string.lower(name)
    for key, data in pairs(MFS.Factions) do
        if string.lower(data.name) == lowered then
            return key, data
        end
    end

    return nil, nil
end

function MFS.GetRecipeByBlueprintID(blueprintID)
    local lowered = string.lower(blueprintID or "")
    for recipeID, recipe in pairs(MFS.Recipes) do
        if string.lower(recipe.blueprintID or "") == lowered then
            return recipeID, recipe
        end
    end

    return nil, nil
end

function MFS.GetStructureDef(structureID)
    if not structureID then
        return nil
    end

    return MFS.BaseBuilding.types[string.lower(structureID)]
end

function MFS.GetTradeZonesForMap(mapName)
    local zones = MFS.TradePosts.mapZones[mapName or game.GetMap()]
    if not zones then
        return {}
    end

    return zones
end

function MFS.Log(text, ...)
    local payload = text
    if select("#", ...) > 0 then
        payload = string.format(text, ...)
    end
    print("[MilsimFrontier] " .. payload)
end

function MFS.Debug(text, ...)
    if not (MFS.CVars and MFS.CVars.debug and MFS.CVars.debug:GetBool()) then
        return
    end

    MFS.Log(text, ...)
end
