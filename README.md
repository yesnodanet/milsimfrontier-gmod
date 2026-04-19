# Milsim Frontier (Clockwork Migration)

This repository now contains a full **Clockwork-based** schema implementation.

## Structure

- **Framework (vendored):** `gamemodes/clockwork`
- **Schema gamemode:** `gamemodes/milsimfrontier`
- **Schema root:** `gamemodes/milsimfrontier/schema`
- **Gameplay plugins:** `gamemodes/milsimfrontier/plugins/*`
- **Legacy standalone backup (not used at runtime):** `gamemodes/milsimfrontier/legacy_standalone`

> Note: `gamemodes/milsimfrontier/gamemode` contains a marker file on purpose.
> Do not delete it, or the mode can disappear from the in-game gamemode list after clone/update.

## Clean Wipe Notice

This migration is a **clean wipe** for v1 Clockwork rollout.

- Persistence source of truth is now Clockwork character/inventory data (SQLite).
- Legacy PData keys from standalone mode are deprecated and ignored.

## Included Plugins

- `factions_classes`
  - Rebels / Alliance / Outcasts factions
  - Alliance class split: Fighter / Engineer / Collector
- `spawn_loadout`
  - Role loadouts on spawn
  - Outcasts isolated spawn logic
  - Outcasts baseline is pistol-only (`tacrp_p2000`)
  - Ally proximity resistance buff
- `materials_inventory`
  - Materials as Clockwork items (persistent)
  - Character-data snapshot sync
  - Client material HUD
- `crafting`
  - Clockwork blueprint crafting for weapons + medkit
  - Weapon unlock persistence per character
- `world_spawners`
  - Resource node spawning
  - Zombie spawning and material drops on kill
- `debug_tools`
  - Validation, node counters, debug overlays, compatibility wrappers

## Workshop Dependencies

- Map `gm_fork`: `326332456`
- `[TacRP] Tactical RP Weapons`: `2588031232`
- Alliance models `EJ's Combine Playermodels`: `3332624202`
- Rebel models `Tactical rebel playermodels`: `1594326092`
- Outcast models `Stalker playermodels (factions)`: `355101935`

These are auto-registered with `resource.AddWorkshop`.

## Start Server

Use:

```bash
+gamemode milsimfrontier +map gm_fork
```

## Behavior Changes

- Initial faction selection is now part of **Clockwork character creation**.
- Class choice is also CW-native (Alliance classes shown during character creation).
- Old custom faction popup flow is removed.

## Compatibility Commands (`mfs_*`)

### Player

- `mfs_choose_faction` - open CW character menu (faction flow is CW-native)
- `mfs_open_craft` - crafting helper hint
- `mfs_recipes` - list recipe IDs
- `mfs_craft <recipeID>` - craft a recipe
- `mfs_join_class <class>` - switch class inside current faction

### Admin

- `mfs_validate` - validate map, weapons, navmesh, counters
- `mfs_debug_materials 1/0` - toggle material node overlay
- `mfs_debug_nodes` - print node/enemy counters
- `mfs_spawn_material [material] [amount]` - spawn resource node
- `mfs_spawn_enemy [npc_class]` - spawn zombie/NPC

### Chat Shortcuts

- `!faction`
- `!craft`
- `!matdebug` (admin)

## Main CVars

- `mfs_enabled 1`
- `mfs_lock_map 1`
- `mfs_apply_models 1`
- `mfs_apply_loadouts 1`
- `mfs_resources_enabled 1`
- `mfs_enemies_enabled 1`
- `mfs_ally_buff 1`
- `mfs_debug 0`
