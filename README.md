# Milsim Frontier (CW Rebuild v1)

Clockwork-first rebuild of the Milsim Frontier mode.

## Structure

- Framework (vendored): `gamemodes/clockwork`
- Schema gamemode: `gamemodes/milsimfrontier`
- Schema root: `gamemodes/milsimfrontier/schema`
- Gameplay plugins: `gamemodes/milsimfrontier/plugins/*`

## Clean Wipe Notice

This release is a clean wipe for the Clockwork schema rollout.

- Persistence source of truth: Clockwork + SQLite.
- Legacy standalone PData flows are not used.

## Included Plugins

- `factions_classes`: Rebels / Alliance / Outcasts factions and Alliance classes
- `spawn_loadout`: role loadouts and isolated outcast spawn
- `ally_synergy`: proximity resistance buff for non-outcast allies
- `materials_inventory`: persistent material items + sync HUD data
- `crafting`: CW blueprints for weapon and medkit crafting
- `world_spawners`: resource nodes, zombies and NPC material drops
- `base_building`: build/upgrade/repair/remove persistent structures
- `trade_posts`: static trade zones with timed hard safe-zone windows
- `debug_tools`: validation commands, counters and debug overlays

## Workshop Dependencies

- Map `gm_fork`: `326332456`
- `[TacRP] Tactical RP Weapons`: `2588031232`
- Alliance models `EJ's Combine Playermodels`: `3332624202`
- Rebel models `Tactical rebel playermodels`: `1594326092`
- Outcast models `Stalker playermodels (factions)`: `355101935`

Dependencies are auto-registered with `resource.AddWorkshop`.

## Start Server

```bash
+gamemode milsimfrontier +map gm_fork
```

## Gameplay Contracts

- Faction and class selection go through Clockwork character creation.
- Outcasts start pistol-only (`tacrp_p2000`) and use solo spawn relocation.
- Materials, crafted unlocks and base structures are persisted by CW schema data.
- Trade zones are static per map and become hard safe-zones when active.

## Commands (`mfs_*`)

### Player

- `mfs_open_craft`
- `mfs_recipes`
- `mfs_craft <recipeID>`
- `mfs_build_list`
- `mfs_build_place <structureID>`
- `mfs_build_upgrade`
- `mfs_build_repair`
- `mfs_build_remove`

### Admin

- `mfs_validate`
- `mfs_debug_materials 1/0`
- `mfs_debug_zones 1/0`
- `mfs_debug_build 1/0`
- `mfs_debug_nodes`
- `mfs_spawn_material [material] [amount]`
- `mfs_spawn_enemy [npc_class]`
- `mfs_trade_status`

## Main CVars

- `mfs_enabled 1`
- `mfs_lock_map 1`
- `mfs_apply_models 1`
- `mfs_apply_loadouts 1`
- `mfs_resources_enabled 1`
- `mfs_enemies_enabled 1`
- `mfs_ally_buff 1`
- `mfs_basebuilding_enabled 1`
- `mfs_tradeposts_enabled 1`
- `mfs_debug 0`
