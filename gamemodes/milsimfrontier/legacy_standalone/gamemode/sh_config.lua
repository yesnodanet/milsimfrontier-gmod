MFS = MFS or {}

local cfg = MFS

cfg.Version = "2.0.0"
cfg.TargetMap = "gm_fork"

cfg.WorkshopIDs = {
    map = "326332456",
    weapons = "2588031232",
    allianceModels = "3332624202",
    rebelModels = "1594326092",
    outcastModels = "355101935"
}

cfg.Team = {
    unassigned = 300,
    rebels = 301,
    alliance = 302,
    outcasts = 303
}

cfg.Factions = {
    rebels = {
        name = "Rebels",
        team = cfg.Team.rebels,
        classes = {
            survivor = {
                name = "Survivor",
                weapons = {
                    { class = "tacrp_p2000", magazines = 2 }
                },
                utility = {
                    "tacrp_medkit"
                },
                health = 100,
                armor = 0
            }
        }
    },
    alliance = {
        name = "Alliance",
        team = cfg.Team.alliance,
        classes = {
            fighter = {
                name = "Fighter",
                weapons = {
                    { class = "tacrp_mp5", magazines = 4 },
                    { class = "tacrp_p250", magazines = 2 }
                },
                utility = {
                    "tacrp_medkit",
                    "tacrp_nade_smoke"
                },
                health = 100,
                armor = 45
            },
            engineer = {
                name = "Engineer",
                weapons = {
                    { class = "tacrp_k1a", magazines = 3 },
                    { class = "tacrp_p2000", magazines = 2 }
                },
                utility = {
                    "tacrp_medkit",
                    "weapon_physgun",
                    "gmod_tool"
                },
                health = 100,
                armor = 30
            },
            collector = {
                name = "Collector",
                weapons = {
                    { class = "tacrp_mp7", magazines = 3 },
                    { class = "tacrp_p2000", magazines = 2 }
                },
                utility = {
                    "tacrp_medkit",
                    "weapon_crowbar"
                },
                health = 100,
                armor = 20
            }
        }
    },
    outcasts = {
        name = "Outcasts",
        team = cfg.Team.outcasts,
        classes = {
            drifter = {
                name = "Drifter",
                weapons = {
                    { class = "tacrp_p2000", magazines = 2 }
                },
                utility = {},
                health = 100,
                armor = 8
            }
        }
    }
}

cfg.DefaultFaction = nil
cfg.DefaultClassByFaction = {
    rebels = "survivor",
    alliance = "fighter",
    outcasts = "drifter"
}

cfg.Materials = {
    scrap = { name = "Scrap", color = Color(192, 192, 192) },
    cloth = { name = "Cloth", color = Color(200, 170, 140) },
    chemicals = { name = "Chemicals", color = Color(130, 220, 130) },
    electronics = { name = "Electronics", color = Color(130, 170, 255) },
    meds = { name = "Med Supplies", color = Color(255, 150, 150) }
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
        name = "Medkit",
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

cfg.ModelKeywords = {
    rebels = {
        "rebel",
        "resistance",
        "insurgent",
        "citizen",
        "freedom"
    },
    alliance = {
        "combine",
        "metrocop",
        "civil protection",
        "overwatch",
        "ota",
        "cp"
    },
    outcasts = {
        "stalker",
        "bandit",
        "merc",
        "loner",
        "outcast"
    }
}

cfg.FallbackModels = {
    rebels = {
        "models/gst_defectors/pm/gst_defector_03.mdl",
        "models/gst_defectors/pm/gst_defector_03.mdl"
    },
    alliance = {
        "models/player/combine_soldier.mdl",
        "models/player/combine_super_soldier.mdl"
    },
    outcasts = {
        "models/player/odessa.mdl",
        "models/player/group03m/male_06.mdl"
    }
}

cfg.AllyBuff = {
    radius = 600,
    resistancePerAlly = 0.04,
    maxResistance = 0.20
}

