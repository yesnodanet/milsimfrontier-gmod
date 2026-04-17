# Milsim Frontier Gamemode

This addon now ships a separate gamemode:

- **Folder:** `gamemodes/milsimfrontier`
- **Base:** `sandbox`
- **Target map:** `gm_fork`

## Included systems

- Initial faction selection menu (opens automatically on first spawn)
- Factions with class loadouts
- Outcasts spawn logic changed to isolated/navmesh-based positions
- Outcasts start with **pistol only** (`tacrp_p2000`)
- Material inventory (server-synced, persistent via PData)
- Crafting system for weapons and medkits
- Material nodes spawning across the map
- Enemy (zombie) spawning and material drops on kill
- Debug tools for material node visibility and counters

## Workshop IDs

- Map `gm_fork`: `326332456`
- `[TacRP] Tactical RP Weapons`: `2588031232`
- Alliance models `EJ's Combine Playermodels`: `3332624202`
- Rebel models `Tactical rebel playermodels`: `1594326092`
- Outcast models `Stalker playermodels (factions)`: `355101935`

## How to start

1. Put addon in `garrysmod/addons`.
2. Start server with `+gamemode milsimfrontier +map gm_fork`.
3. Join and choose faction in menu.
4. Use `mfs_open_craft` to open crafting.

## Commands

### Player

- `mfs_choose_faction` - reopen faction menu
- `mfs_open_craft` - open crafting menu
- `mfs_join_class <class>` - switch class in current faction
- Chat shortcuts:
  - `!faction`
  - `!craft`

### Admin

- `mfs_validate` - validate map/weapons/navmesh setup
- `mfs_debug_materials 1/0` - toggle material node debug overlay
- `mfs_spawn_material [material] [amount]` - spawn node at aim position
- `mfs_debug_nodes` - print current node/enemy counts

## Main CVars

- `mfs_enabled 1`
- `mfs_lock_map 1`
- `mfs_apply_models 1`
- `mfs_apply_loadouts 1`
- `mfs_resources_enabled 1`
- `mfs_enemies_enabled 1`
- `mfs_ally_buff 1`
- `mfs_debug 0`
