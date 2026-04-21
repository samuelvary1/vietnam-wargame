## substance_manager.gd
## Attach to a Node in Main scene (or as Autoload)
## Handles all substance logic: usage decisions, addiction rolls,
## buff application, crash/withdrawal tracking

extends Node

signal addiction_developed(soldier: Soldier, substance: int)
signal narrative_event(text: String)

# Current platoon policy — set from UI
var platoon_policy: int = Substances.PlatoonPolicy.BLIND_EYE

# ─── Pre-Mission Phase ────────────────────────────────────────────────────────

func process_pre_mission(soldiers: Array[Soldier], supply: int) -> Dictionary:
	## Call before each mission. Returns:
	##   { "supply_spent": int, "events": [String], "unit_buffs": {soldier_id: buff_dict} }

	var result := {
		"supply_spent": 0,
		"events": [],
		"unit_buffs": {}
	}

	# Policy enforcement cost
	if platoon_policy == Substances.PlatoonPolicy.MANAGE_QUIETLY:
		result["supply_spent"] += 1
		result["events"].append("You look the other way. It costs you.")

	if platoon_policy == Substances.PlatoonPolicy.ENFORCE_STRICT:
		result["events"].append("You run a tight ship today. The men aren't happy about it.")
		return result  # no usage, skip the rest

	for soldier in soldiers:
		if not soldier.is_available():
			continue

		# Apply crash from last mission if pending
		if soldier.crash_pending:
			_apply_crash(soldier, result)
			soldier.crash_pending = false

		# Addicted soldiers need their fix or suffer withdrawal
		if soldier.addiction_state == Substances.AddictionState.ADDICTED:
			var substance_data: Dictionary = Substances.SUBSTANCE_DATA[soldier.addicted_to]
			if supply >= substance_data["supply_cost"] + result["supply_spent"]:
				_apply_buff(soldier, soldier.addicted_to, result)
				result["supply_spent"] += substance_data["supply_cost"]
				soldier.days_since_fix = 0
			else:
				_apply_withdrawal(soldier, result)
				soldier.days_since_fix += 1
			continue

		# Non-addicted: roll for voluntary use based on personality + morale
		if _rolls_for_use(soldier):
			var chosen := _pick_substance(soldier)
			var substance_data: Dictionary = Substances.SUBSTANCE_DATA[chosen]
			if supply >= substance_data["supply_cost"] + result["supply_spent"]:
				_apply_buff(soldier, chosen, result)
				result["supply_spent"] += substance_data["supply_cost"]
				_roll_addiction(soldier, chosen, result)

	return result

# ─── Buff Application ─────────────────────────────────────────────────────────

func _apply_buff(soldier: Soldier, substance: int, result: Dictionary) -> void:
	var data: Dictionary = Substances.SUBSTANCE_DATA[substance]
	var buffs: Dictionary = data["buffs"]

	soldier.used_this_mission = substance
	soldier.crash_pending = true
	soldier.crash_substance = substance

	if not soldier.times_used.has(substance):
		soldier.times_used[substance] = 0
	soldier.times_used[substance] += 1

	var buf := _empty_buff()
	buf["movement_bonus"]  = buffs.get("movement_bonus", 0)
	buf["attack_bonus"]    = buffs.get("attack_bonus", 0)
	buf["morale_immune"]   = buffs.get("morale_immune", false)
	buf["vision_penalty"]  = buffs.get("vision_penalty", 0)
	buf["morale_restore"]  = buffs.get("morale_restore", false)

	result["unit_buffs"][soldier.get_instance_id()] = buf

	var flavor: String = data.get("flavor", "")
	result["events"].append(
		"%s is on %s. %s" % [soldier.full_name(), data["short"], flavor]
	)

func _apply_crash(soldier: Soldier, result: Dictionary) -> void:
	var data: Dictionary = Substances.SUBSTANCE_DATA[soldier.crash_substance]
	var crash: Dictionary = data["crash"]
	var buf := _empty_buff()
	buf["movement_bonus"] = crash.get("movement_bonus", 0)
	buf["attack_bonus"]   = crash.get("attack_bonus", 0)
	buf["morale_restore"] = false
	buf["is_crash"]       = true

	result["unit_buffs"][soldier.get_instance_id()] = buf
	result["events"].append(
		"%s is crashing from last mission. He's not right." % soldier.full_name()
	)

func _apply_withdrawal(soldier: Soldier, result: Dictionary) -> void:
	var data: Dictionary = Substances.SUBSTANCE_DATA[soldier.addicted_to]
	var wd: Dictionary = data["withdrawal"]
	var buf := _empty_buff()
	buf["movement_bonus"]   = wd.get("movement_bonus", 0)
	buf["attack_bonus"]     = wd.get("attack_bonus", 0)
	buf["morale_penalty"]   = wd.get("morale_penalty", 0)
	buf["is_withdrawal"]    = true

	result["unit_buffs"][soldier.get_instance_id()] = buf
	result["events"].append(
		"%s is in withdrawal. He's shaking. He needs it." % soldier.full_name()
	)

# ─── Addiction Roll ───────────────────────────────────────────────────────────

func _roll_addiction(soldier: Soldier, substance: int, result: Dictionary) -> void:
	if soldier.addiction_state == Substances.AddictionState.ADDICTED:
		return

	var data: Dictionary = Substances.SUBSTANCE_DATA[substance]
	var base_chance: float = data["addiction_chance"]

	# Policy modifier
	if platoon_policy == Substances.PlatoonPolicy.MANAGE_QUIETLY:
		base_chance *= 0.5

	# Personality modifier
	var addiction_resistance: int = _get_addiction_resistance(soldier)
	base_chance -= addiction_resistance * 0.08
	base_chance = clamp(base_chance, 0.02, 0.90)

	# Times used increases risk
	var use_count: int = soldier.times_used.get(substance, 0)
	if use_count >= 3:
		base_chance += 0.10
	if use_count >= 6:
		base_chance += 0.15

	if soldier.addiction_state == Substances.AddictionState.CLEAN:
		soldier.addiction_state = Substances.AddictionState.AT_RISK

	if randf() < base_chance:
		soldier.addiction_state = Substances.AddictionState.ADDICTED
		soldier.addicted_to = substance
		result["events"].append(
			"%s has developed a dependency. He needs %s now." % [
				soldier.full_name(), data["name"]
			]
		)
		emit_signal("addiction_developed", soldier, substance)

# ─── Voluntary Use Logic ──────────────────────────────────────────────────────

func _rolls_for_use(soldier: Soldier) -> bool:
	## Higher chance to use if low morale or "Reckless"/"Anxious" personality
	var base_chance: float = 0.15

	if soldier.morale <= 2:
		base_chance += 0.25
	if soldier.morale <= 1:
		base_chance += 0.20

	var resistance: int = _get_addiction_resistance(soldier)
	base_chance -= resistance * 0.08

	return randf() < base_chance

func _pick_substance(soldier: Soldier) -> int:
	## Anxious soldiers prefer heroin, reckless prefer amphetamines
	if "Anxious" in soldier.traits:
		return Substances.SubstanceType.HEROIN if randf() > 0.4 else Substances.SubstanceType.MARIJUANA
	if "Reckless" in soldier.traits:
		return Substances.SubstanceType.AMPHETAMINES if randf() > 0.3 else Substances.SubstanceType.ALCOHOL
	# Default: marijuana most common, others less so
	var roll := randf()
	if roll < 0.45:  return Substances.SubstanceType.MARIJUANA
	if roll < 0.65:  return Substances.SubstanceType.ALCOHOL
	if roll < 0.82:  return Substances.SubstanceType.AMPHETAMINES
	return Substances.SubstanceType.HEROIN

func _get_addiction_resistance(soldier: Soldier) -> int:
	if "Stoic" in soldier.traits:   return 1
	if "Reckless" in soldier.traits: return -1
	if "Anxious" in soldier.traits:  return -1
	if "Cynical" in soldier.traits:  return -1
	return 0

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _empty_buff() -> Dictionary:
	return {
		"movement_bonus":  0,
		"attack_bonus":    0,
		"morale_immune":   false,
		"morale_restore":  false,
		"vision_penalty":  0,
		"morale_penalty":  0,
		"is_crash":        false,
		"is_withdrawal":   false,
	}

# ─── Apply to Unit Node ───────────────────────────────────────────────────────

func apply_buffs_to_units(unit_buffs: Dictionary, unit_nodes: Array) -> void:
	## Call after pre_mission processing.
	## unit_nodes: array of Unit nodes that have a .soldier property
	for unit in unit_nodes:
		if not unit.has_method("get") or unit.soldier == null:
			continue
		var id: int = unit.soldier.get_instance_id()
		if not unit_buffs.has(id):
			continue

		var buf: Dictionary = unit_buffs[id]
		unit.max_movement  += buf["movement_bonus"]
		unit.current_movement = unit.max_movement
		unit.attack_power  += buf["attack_bonus"]

		if buf.get("morale_restore", false) and unit.soldier:
			unit.soldier.morale = unit.soldier.max_morale

		if buf.get("morale_penalty", 0) > 0 and unit.soldier:
			unit.soldier.morale = max(0, unit.soldier.morale - buf["morale_penalty"])

		# Tag unit for in-mission visual (subtle color shift)
		if buf.get("is_withdrawal", false):
			unit.modulate = Color(0.7, 0.7, 1.0)   # pale blue — sick
		elif buf.get("is_crash", false):
			unit.modulate = Color(0.9, 0.8, 0.5)   # yellow — depleted
