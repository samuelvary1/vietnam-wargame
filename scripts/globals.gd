## globals.gd
## Autoload — add this in Project > Project Settings > Autoload
## Name it "Globals"

extends Node
class_name Globals

enum Team { US, VC }

enum UnitType {
	RIFLEMAN,
	GRENADIER,
	RECON,
	MEDIC,
	MACHINE_GUNNER,
	TUNNEL_RAT,
	M113
}

enum TerrainType {
	JUNGLE,
	RICE_PADDY,
	VILLAGE,
	PATH,
	WATER
}

enum Phase { PLAYER_TURN, ENEMY_TURN }

# Movement cost per terrain type
const TERRAIN_MOVE_COST = {
	TerrainType.JUNGLE:     2,
	TerrainType.RICE_PADDY: 2,
	TerrainType.VILLAGE:    1,
	TerrainType.PATH:       1,
	TerrainType.WATER:      99  # impassable
}

# Unit base stats [max_health, max_movement, attack_power, attack_range]
const UNIT_STATS = {
	UnitType.RIFLEMAN:      [6, 3, 2, 1],
	UnitType.GRENADIER:     [5, 2, 3, 2],
	UnitType.RECON:         [4, 5, 1, 1],
	UnitType.MEDIC:         [4, 3, 1, 1],
	UnitType.MACHINE_GUNNER:[6, 2, 4, 2],
	UnitType.TUNNEL_RAT:    [4, 4, 2, 1],
	UnitType.M113:          [8, 3, 3, 1],
}

const UNIT_NAMES = {
	UnitType.RIFLEMAN:       "US Infantry",
	UnitType.GRENADIER:      "Grenadier",
	UnitType.RECON:          "Recon",
	UnitType.MEDIC:          "Medic",
	UnitType.MACHINE_GUNNER: "M60 Gunner",
	UnitType.TUNNEL_RAT:     "Tunnel Rat",
	UnitType.M113:           "M113 APC",
}
