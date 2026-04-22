extends Node
class_name CampaignManager

const PATROL_SIZE := 6

var campaign_started: bool = false
var current_mission: int = 1
var roster: Array[Soldier] = []

func ensure_campaign_started() -> void:
	if campaign_started:
		return
	_build_initial_platoon()
	campaign_started = true

func _build_initial_platoon() -> void:
	roster.clear()
	for role in _historical_platoon_roles():
		var soldier := SoldierGenerator.generate(role)
		soldier.primary_role = role
		soldier.portrait_id = randi() % 12
		roster.append(soldier)

func _historical_platoon_roles() -> Array[int]:
	# Vietnam-era platoon inspired structure: HQ + 3 rifle squads + medic
	var roles: Array[int] = [
		Globals.UnitType.RIFLEMAN,
		Globals.UnitType.RIFLEMAN,
		Globals.UnitType.MEDIC,
	]

	for _squad in range(3):
		roles.append(Globals.UnitType.RIFLEMAN)       # squad leader
		roles.append(Globals.UnitType.GRENADIER)
		roles.append(Globals.UnitType.MACHINE_GUNNER)
		for _rifleman in range(5):
			roles.append(Globals.UnitType.RIFLEMAN)

	return roles

func create_patrol(size: int = PATROL_SIZE) -> Array[Soldier]:
	var available: Array[Soldier] = _available_soldiers()
	var patrol: Array[Soldier] = []

	_take_role(available, patrol, Globals.UnitType.MACHINE_GUNNER, 1)
	_take_role(available, patrol, Globals.UnitType.GRENADIER, 1)
	_take_role(available, patrol, Globals.UnitType.MEDIC, 1)
	_take_role(available, patrol, Globals.UnitType.RIFLEMAN, max(0, size - patrol.size()))

	while patrol.size() < size and not available.is_empty():
		patrol.append(available.pop_front())

	for soldier in patrol:
		soldier.missions_deployed += 1

	return patrol

func mark_casualty(unit: Node) -> void:
	if unit == null or not unit.has_method("get_soldier"):
		return
	var soldier: Soldier = unit.get_soldier()
	if soldier == null:
		return
	soldier.wound_state = "kia"

func complete_mission(surviving_units: Array, mission_won: bool) -> void:
	for unit in surviving_units:
		if unit == null or not unit.has_method("get_soldier"):
			continue
		var soldier: Soldier = unit.get_soldier()
		if soldier == null or soldier.wound_state == "kia":
			continue
		soldier.missions_survived += 1
		soldier.experience += 2 if mission_won else 1
		soldier.check_earned_traits()

	current_mission += 1

func _available_soldiers() -> Array[Soldier]:
	var list: Array[Soldier] = []
	for soldier in roster:
		if soldier.is_available() and soldier.wound_state != "kia":
			list.append(soldier)
	return list

func _take_role(pool: Array[Soldier], target: Array[Soldier], role: int, count: int) -> void:
	for _i in range(count):
		var selected := _pop_role_candidate(pool, role)
		if selected == null:
			return
		target.append(selected)

func _pop_role_candidate(pool: Array[Soldier], role: int) -> Soldier:
	var best_idx := -1
	for i in range(pool.size()):
		var s: Soldier = pool[i]
		if s.primary_role != role:
			continue
		if best_idx == -1 or s.missions_deployed < pool[best_idx].missions_deployed:
			best_idx = i
	if best_idx == -1:
		return null
	var picked: Soldier = pool[best_idx]
	pool.remove_at(best_idx)
	return picked
