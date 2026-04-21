## game_manager.gd
## Attach to a Node called "GameManager" in Main scene
## Manages turn order, action points, supply, and win/loss conditions

extends Node

signal turn_changed(turn_number: int)
signal ap_changed(ap: int)
signal supply_changed(supply: int)
signal phase_changed(phase: int)
signal game_over(player_won: bool)

var current_turn: int = 1
var action_points: int = 3
var max_action_points: int = 3
var supply: int = 12
var current_phase: int = Globals.Phase.PLAYER_TURN

var player_units: Array = []
var enemy_units: Array = []

# ─── Turn Flow ────────────────────────────────────────────────────────────────

func start_player_turn() -> void:
	current_phase = Globals.Phase.PLAYER_TURN
	action_points = max_action_points
	for unit in player_units:
		unit.reset_for_new_turn()
	emit_signal("ap_changed", action_points)
	emit_signal("phase_changed", current_phase)

func end_player_turn() -> void:
	current_phase = Globals.Phase.ENEMY_TURN
	emit_signal("phase_changed", current_phase)

func start_next_turn() -> void:
	current_turn += 1
	emit_signal("turn_changed", current_turn)
	start_player_turn()

# ─── Resources ────────────────────────────────────────────────────────────────

func spend_ap(amount: int) -> bool:
	if action_points >= amount:
		action_points -= amount
		emit_signal("ap_changed", action_points)
		return true
	return false

func spend_supply(amount: int) -> bool:
	if supply >= amount:
		supply -= amount
		emit_signal("supply_changed", supply)
		return true
	return false

# ─── Win / Loss ───────────────────────────────────────────────────────────────

func check_victory() -> void:
	if enemy_units.is_empty():
		emit_signal("game_over", true)
	elif player_units.is_empty():
		emit_signal("game_over", false)

func register_unit_death(unit: Node) -> void:
	player_units.erase(unit)
	enemy_units.erase(unit)
	check_victory()
