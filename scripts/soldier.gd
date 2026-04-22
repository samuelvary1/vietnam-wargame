## soldier.gd
## Resource that holds a soldier's persistent RPG data across missions.
## Attach alongside unit.gd — the Unit node holds both a unit_type (tactics)
## and a Soldier resource (the person).

extends Resource
class_name Soldier

const TRAIT_HARDENED := "Hardened"
const TRAIT_SHAKEN := "Shaken"
const TRAIT_SHORT_TIMER := "Short-Timer"

# ─── Identity ─────────────────────────────────────────────────────────────────

@export var first_name: String = ""
@export var last_name: String = ""
@export var hometown: String = ""
@export var rank: String = "Pvt."
@export var backstory: String = ""
@export var missions_survived: int = 0
@export var missions_deployed: int = 0
@export var kills: int = 0
@export var times_wounded: int = 0
@export var experience: int = 0
@export var portrait_id: int = 0
@export var primary_role: int = Globals.UnitType.RIFLEMAN

# ─── Traits (earned through play) ─────────────────────────────────────────────

@export var traits: Array[String] = []
# Possible values:
# "Hardened"   — 3+ kills, +1 attack, -1 morale
# "Shaken"     — low morale, reduced combat effectiveness
# "Short-Timer"— 8+ missions, survival stress penalty

# ─── Wound State ──────────────────────────────────────────────────────────────

@export var wound_state: String = "healthy"
# "healthy" | "light_wound" | "serious_wound" | "kia"
@export var missions_until_return: int = 0  # for serious wounds

# ─── Morale ───────────────────────────────────────────────────────────────────

@export var morale: int = 5
@export var max_morale: int = 5

# ─── Substance State ──────────────────────────────────────────────────────────

@export var addiction_state: int = Substances.AddictionState.CLEAN
@export var addicted_to: int = Substances.SubstanceType.NONE
@export var times_used: Dictionary = {}   # SubstanceType -> int count
@export var used_this_mission: int = Substances.SubstanceType.NONE
@export var crash_pending: bool = false   # will suffer crash next mission
@export var crash_substance: int = Substances.SubstanceType.NONE
@export var days_since_fix: int = 0       # for withdrawal tracking

# ─── Letters Home ─────────────────────────────────────────────────────────────

@export var letters: Array[String] = []
# Populated by narrative events, displayed on roster screen

# ─── Computed Properties ──────────────────────────────────────────────────────

func full_name() -> String:
	return "%s %s %s" % [rank, first_name, last_name]

func short_name() -> String:
	return "%s. %s" % [last_name, first_name[0]]

func is_short_timer() -> bool:
	return missions_survived >= 8

func is_available() -> bool:
	return wound_state == "healthy" or wound_state == "light_wound"

func morale_ok() -> bool:
	return morale > 2

func experience_label() -> String:
	if experience >= 12:
		return "Veteran"
	if experience >= 6:
		return "Experienced"
	return "Green"

# ─── Stat Modifiers from Traits ───────────────────────────────────────────────

func get_movement_modifier() -> int:
	var mod := 0
	if TRAIT_SHAKEN in traits: mod -= 1
	return mod

func get_attack_modifier() -> int:
	var mod := 0
	if TRAIT_HARDENED in traits: mod += 1
	if TRAIT_SHAKEN in traits: mod -= 1
	return mod

func get_morale_modifier() -> int:
	var mod := 0
	if TRAIT_HARDENED in traits: mod -= 1
	if TRAIT_SHORT_TIMER in traits: mod -= 1
	return mod

# ─── Trait Acquisition ────────────────────────────────────────────────────────

func add_trait(trait_name: String) -> String:
	if trait_name not in traits:
		traits.append(trait_name)
		return "%s earned the '%s' trait." % [full_name(), trait_name]
	return ""

func check_earned_traits() -> Array[String]:
	## Call after each mission. Returns list of narrative strings for new traits.
	var new_events: Array[String] = []

	if kills >= 3 and TRAIT_HARDENED not in traits:
		new_events.append(add_trait(TRAIT_HARDENED))

	if missions_survived >= 8 and TRAIT_SHORT_TIMER not in traits:
		new_events.append(add_trait(TRAIT_SHORT_TIMER))
		new_events.append("%s is getting short. Everyone knows it." % full_name())

	if morale <= 1 and TRAIT_SHAKEN not in traits:
		new_events.append(add_trait(TRAIT_SHAKEN))

	return new_events

# ─── Wound System ─────────────────────────────────────────────────────────────

func apply_wound(severity: String) -> String:
	times_wounded += 1
	match severity:
		"light":
			wound_state = "light_wound"
			return "%s took a light wound. He'll be slower next mission." % full_name()
		"serious":
			wound_state = "serious_wound"
			missions_until_return = randi_range(2, 3)
			return "%s is seriously wounded. He's out for %d missions." % [full_name(), missions_until_return]
		"kia":
			wound_state = "kia"
			return "%s has been killed in action." % full_name()
	return ""

func tick_recovery() -> String:
	if wound_state == "serious_wound":
		missions_until_return -= 1
		if missions_until_return <= 0:
			wound_state = "healthy"
			return "%s has returned from the hospital." % full_name()
	elif wound_state == "light_wound":
		wound_state = "healthy"
	return ""
