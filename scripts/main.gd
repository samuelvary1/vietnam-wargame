## main.gd
## Attach to the root Node2D of Main.tscn
## This is the central controller — it wires all systems together
## and handles the player's action flow.

extends Node2D

const SCENE_SPLASH := preload("res://scenes/SplashScreen.tscn")
const SCENE_MAIN_MENU := preload("res://scenes/MainMenu.tscn")
const SCENE_ROSTER_SELECTION := preload("res://scenes/RosterSelection.tscn")
const SCENE_UNIT := preload("res://scenes/Unit.tscn")

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var hex_grid: TileMapLayer   = $HexGrid
@onready var game_manager: Node       = $GameManager
@onready var ui_manager: CanvasLayer  = $UIManager
@onready var enemy_ai: Node           = $EnemyAI

# ─── Action state ─────────────────────────────────────────────────────────────

var selected_unit: Node = null
var action_mode: String = ""   # "move" | "attack" | ""
var game_started: bool = false
var menu_layer: MainMenu = null
var roster_layer: RosterSelection = null
var selected_patrol: Array[Soldier] = []

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	ui_manager.visible = false
	_show_splash()

func _show_splash() -> void:
	var splash := SCENE_SPLASH.instantiate()
	add_child(splash)
	splash.splash_finished.connect(_show_main_menu)

func _show_main_menu() -> void:
	menu_layer = SCENE_MAIN_MENU.instantiate() as MainMenu
	add_child(menu_layer)
	menu_layer.new_game_requested.connect(_on_new_game_requested)
	menu_layer.load_game_requested.connect(_on_load_game_requested)
	menu_layer.exit_requested.connect(_on_exit_requested)

func _on_new_game_requested() -> void:
	Campaign.ensure_campaign_started()
	_open_roster_selection()

func _on_load_game_requested() -> void:
	if FileAccess.file_exists("user://campaign.save"):
		Campaign.ensure_campaign_started()
		_open_roster_selection()
		return
	if menu_layer != null:
		menu_layer.show_status("No save file found yet. Start a new game.")

func _on_exit_requested() -> void:
	get_tree().quit()

func _open_roster_selection() -> void:
	_close_main_menu()

	roster_layer = SCENE_ROSTER_SELECTION.instantiate() as RosterSelection
	add_child(roster_layer)
	roster_layer.deploy_confirmed.connect(_on_roster_deploy_confirmed)
	roster_layer.cancel_requested.connect(_on_roster_cancel_requested)
	roster_layer.populate(Campaign.get_available_soldiers())

func _on_roster_deploy_confirmed(selection: Array) -> void:
	selected_patrol = Campaign.confirm_patrol(selection)
	_close_roster_selection()
	_start_game()

func _on_roster_cancel_requested() -> void:
	_close_roster_selection()
	_show_main_menu()

func _close_main_menu() -> void:
	if menu_layer == null:
		return
	menu_layer.queue_free()
	menu_layer = null

func _close_roster_selection() -> void:
	if roster_layer == null:
		return
	roster_layer.queue_free()
	roster_layer = null

func _start_game() -> void:
	if game_started:
		return
	game_started = true
	_bootstrap_mission()

func _bootstrap_mission() -> void:
	ui_manager.visible = true
	Campaign.ensure_campaign_started()
	_connect_signals()
	_spawn_starting_units()
	game_manager.start_player_turn()
	ui_manager.update_turn(game_manager.current_turn)
	ui_manager.update_ap(game_manager.action_points)
	ui_manager.update_supply(game_manager.supply)

func _connect_signals() -> void:
	hex_grid.hex_clicked.connect(_on_hex_clicked)

	game_manager.turn_changed.connect(ui_manager.update_turn)
	game_manager.ap_changed.connect(_on_ap_changed)
	game_manager.supply_changed.connect(ui_manager.update_supply)
	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.game_over.connect(_on_game_over)

	ui_manager.move_pressed.connect(_on_move_pressed)
	ui_manager.attack_pressed.connect(_on_attack_pressed)
	ui_manager.fortify_pressed.connect(_on_fortify_pressed)
	ui_manager.end_turn_pressed.connect(_on_end_turn_pressed)

	enemy_ai.turn_complete.connect(_on_enemy_turn_complete)

# ─── Unit Spawning ────────────────────────────────────────────────────────────

func _spawn_starting_units() -> void:
	_spawn_player_patrol()
	_spawn_enemy_force()

func _spawn_enemy_force() -> void:
	# VC units (right side of map)
	_spawn_unit(Vector2i(2, -1), Globals.Team.VC, Globals.UnitType.RIFLEMAN)
	_spawn_unit(Vector2i(2,  0), Globals.Team.VC, Globals.UnitType.RIFLEMAN)
	_spawn_unit(Vector2i(2,  1), Globals.Team.VC, Globals.UnitType.RIFLEMAN)
	_spawn_unit(Vector2i(3,  0), Globals.Team.VC, Globals.UnitType.MACHINE_GUNNER)

func _spawn_player_patrol() -> void:
	var patrol_slots: Array[Vector2i] = [
		Vector2i(-4, 0),
		Vector2i(-4, 1),
		Vector2i(-3, -1),
		Vector2i(-3, 0),
		Vector2i(-3, 1),
		Vector2i(-2, 0),
	]
	var patrol: Array[Soldier] = _consume_selected_patrol(patrol_slots.size())
	for i in range(min(patrol.size(), patrol_slots.size())):
		var soldier: Soldier = patrol[i]
		_spawn_unit(patrol_slots[i], Globals.Team.US, soldier.primary_role, soldier)

func _consume_selected_patrol(size: int) -> Array[Soldier]:
	var patrol: Array[Soldier] = selected_patrol
	if patrol.is_empty():
		patrol = Campaign.create_patrol(size)
	selected_patrol.clear()
	return patrol

func _spawn_unit(hex: Vector2i, team: int, unit_type: int, soldier: Soldier = null) -> Node:
	var unit: Node = SCENE_UNIT.instantiate()
	unit.team = team
	unit.unit_type = unit_type
	add_child(unit)
	unit.setup_from_type()
	unit.assign_soldier(soldier)
	hex_grid.place_unit(unit, hex)
	unit.unit_clicked.connect(_on_unit_clicked)
	unit.unit_died.connect(_on_unit_died)

	if team == Globals.Team.US:
		game_manager.player_units.append(unit)
	else:
		game_manager.enemy_units.append(unit)

	return unit

# ─── Input Handling ───────────────────────────────────────────────────────────

func _on_unit_clicked(unit: Node) -> void:
	if game_manager.current_phase != Globals.Phase.PLAYER_TURN:
		return

	# Clicking an enemy unit
	if unit.team == Globals.Team.VC:
		if action_mode == "attack" and selected_unit != null:
			_try_attack(selected_unit, unit)
		return

	# Clicking a friendly unit — select it
	_select_unit(unit)

func _on_hex_clicked(hex: Vector2i) -> void:
	if game_manager.current_phase != Globals.Phase.PLAYER_TURN:
		return

	var unit_at_hex: Node = hex_grid.get_unit_at(hex)
	if unit_at_hex != null:
		_on_unit_clicked(unit_at_hex)
		return

	if action_mode == "move" and selected_unit != null:
		_try_move(selected_unit, hex)
	else:
		_deselect()

# ─── Selection ────────────────────────────────────────────────────────────────

func _select_unit(unit: Node) -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
	hex_grid.clear_highlights()
	action_mode = ""
	selected_unit = unit
	selected_unit.set_selected(true)
	_refresh_selected_unit_panel()

func _deselect() -> void:
	if selected_unit != null:
		selected_unit.set_selected(false)
		selected_unit = null
	hex_grid.clear_highlights()
	action_mode = ""
	ui_manager.hide_unit_panel()

# ─── Actions ──────────────────────────────────────────────────────────────────

func _try_move(unit: Node, target: Vector2i) -> void:
	var reachable: Array[Vector2i] = _get_affordable_move_cells(unit)
	if target not in reachable:
		return

	var terrain: int = hex_grid.terrain_map.get(target, Globals.TerrainType.JUNGLE)
	var cost: int = Globals.TERRAIN_MOVE_COST[terrain]
	if not game_manager.spend_ap(cost):
		return

	hex_grid.move_unit(unit, target)
	unit.spend_movement(cost)
	hex_grid.clear_highlights()
	action_mode = ""
	_refresh_selected_unit_panel()

func _try_attack(attacker: Node, defender: Node) -> void:
	var dist: int = int(hex_grid.hex_distance(attacker.hex_position, defender.hex_position))
	if dist > attacker.attack_range:
		return
	if not attacker.can_attack():
		return
	if not game_manager.spend_ap(1):
		return

	defender.take_damage(attacker.attack_power)
	attacker.has_attacked = true
	hex_grid.clear_highlights()
	action_mode = ""
	_refresh_selected_unit_panel()

# ─── UI Button Callbacks ──────────────────────────────────────────────────────

func _on_move_pressed() -> void:
	if selected_unit == null:
		return
	var reachable: Array[Vector2i] = _get_affordable_move_cells(selected_unit)
	if reachable.is_empty():
		return
	action_mode = "move"
	hex_grid.highlight_move_range(reachable)

func _on_attack_pressed() -> void:
	if selected_unit == null or not selected_unit.can_attack():
		return
	action_mode = "attack"
	var in_range: Array[Vector2i] = hex_grid.get_cells_in_range(
		selected_unit.hex_position, selected_unit.attack_range
	)
	# Filter to cells that actually have an enemy on them
	var enemy_cells: Array[Vector2i] = []
	for hex in in_range:
		var u: Node = hex_grid.get_unit_at(hex)
		if u != null and u.team == Globals.Team.VC:
			enemy_cells.append(hex)
	hex_grid.highlight_attack_range(enemy_cells)

func _on_fortify_pressed() -> void:
	if selected_unit == null:
		return
	if not game_manager.spend_ap(1):
		return
	selected_unit.is_fortified = true
	action_mode = ""
	_refresh_selected_unit_panel()

func _on_end_turn_pressed() -> void:
	_deselect()
	game_manager.end_player_turn()
	enemy_ai.take_turn(
		game_manager.enemy_units,
		game_manager.player_units,
		hex_grid
	)

# ─── Phase & Game State ───────────────────────────────────────────────────────

func _on_phase_changed(phase: int) -> void:
	ui_manager.set_end_turn_button_enabled(phase == Globals.Phase.PLAYER_TURN)
	_refresh_selected_unit_panel()

func _on_ap_changed(ap: int) -> void:
	ui_manager.update_ap(ap)
	_refresh_selected_unit_panel()

func _on_enemy_turn_complete() -> void:
	game_manager.start_next_turn()

func _on_unit_died(unit: Node) -> void:
	if unit.team == Globals.Team.US:
		Campaign.mark_casualty(unit)
	hex_grid.remove_unit(unit)
	game_manager.register_unit_death(unit)

func _on_game_over(player_won: bool) -> void:
	Campaign.complete_mission(game_manager.player_units, player_won)
	ui_manager.show_game_over(player_won)

func _get_affordable_move_cells(unit: Node) -> Array[Vector2i]:
	var move_budget: int = min(unit.current_movement, game_manager.action_points)
	if move_budget <= 0:
		return []
	return hex_grid.get_reachable_cells(unit.hex_position, move_budget)

func _refresh_selected_unit_panel() -> void:
	if selected_unit == null:
		return
	var can_move_now: bool = not _get_affordable_move_cells(selected_unit).is_empty()
	var can_attack_now: bool = selected_unit.can_attack() and game_manager.action_points >= 1
	var can_fortify_now: bool = not selected_unit.is_fortified and game_manager.action_points >= 1
	ui_manager.show_unit_panel(selected_unit, can_move_now, can_attack_now, can_fortify_now)
