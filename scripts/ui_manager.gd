## ui_manager.gd
## Attach to a CanvasLayer node called "UIManager"
## 
## Expected scene structure:
##   UIManager (CanvasLayer)
##     TopBar (PanelContainer, anchored top-full)
##       HBoxContainer
##         TurnLabel (Label)
##         SupplyLabel (Label)
##         APLabel (Label)
##         EndTurnButton (Button)
##         MenuButton (Button)  <- optional for now
##     Sidebar (PanelContainer, anchored left, width ~280px)
##       VBoxContainer
##         UnitPortrait (TextureRect)  <- placeholder ColorRect is fine
##         UnitNameLabel (Label)
##         HealthLabel (Label)
##         MovementLabel (Label)
##         MoveButton (Button)
##         AttackButton (Button)
##         FortifyButton (Button)
##     GameOverPanel (PanelContainer)  <- hidden by default
##       VBoxContainer
##         ResultLabel (Label)
##         RestartButton (Button)

extends CanvasLayer

signal move_pressed
signal attack_pressed
signal fortify_pressed
signal end_turn_pressed
signal menu_pressed

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var turn_label: Label       = $TopBar/HBoxContainer/TurnLabel
@onready var supply_label: Label     = $TopBar/HBoxContainer/SupplyLabel
@onready var ap_label: Label         = $TopBar/HBoxContainer/APLabel
@onready var end_turn_btn: Button    = $TopBar/HBoxContainer/EndTurnButton
@onready var menu_btn: Button        = get_node_or_null("TopBar/HBoxContainer/MenuButton")

@onready var sidebar: PanelContainer = $Sidebar
@onready var unit_portrait: ColorRect = $Sidebar/VBoxContainer/UnitPortrait
@onready var unit_name_label: Label  = $Sidebar/VBoxContainer/UnitNameLabel
@onready var health_label: Label     = $Sidebar/VBoxContainer/HealthLabel
@onready var movement_label: Label   = $Sidebar/VBoxContainer/MovementLabel
@onready var move_btn: Button        = $Sidebar/VBoxContainer/MoveButton
@onready var attack_btn: Button      = $Sidebar/VBoxContainer/AttackButton
@onready var fortify_btn: Button     = $Sidebar/VBoxContainer/FortifyButton

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var result_label: Label             = $GameOverPanel/VBoxContainer/ResultLabel

var pause_overlay: ColorRect = ColorRect.new()
var pause_panel: PanelContainer = PanelContainer.new()
var _cached_button_states: Dictionary = {}

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	move_btn.pressed.connect(func(): emit_signal("move_pressed"))
	attack_btn.pressed.connect(func(): emit_signal("attack_pressed"))
	fortify_btn.pressed.connect(func(): emit_signal("fortify_pressed"))
	end_turn_btn.pressed.connect(func(): emit_signal("end_turn_pressed"))
	if menu_btn != null:
		menu_btn.pressed.connect(_on_menu_pressed)
	_setup_pause_menu()
	$GameOverPanel/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	hide_unit_panel()
	game_over_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if pause_overlay.visible:
			_hide_pause_menu()
		else:
			_on_menu_pressed()
		get_viewport().set_input_as_handled()

func _setup_pause_menu() -> void:
	pause_overlay.name = "PauseOverlay"
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	pause_overlay.color = Color(0, 0, 0, 0.45)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(pause_overlay)

	pause_panel.name = "PausePanel"
	pause_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pause_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(260, 0)
	container.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "Mission Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	container.add_child(HSeparator.new())

	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_on_resume_pressed)
	container.add_child(resume_btn)

	var restart_btn := Button.new()
	restart_btn.text = "Restart Mission"
	restart_btn.pressed.connect(_on_restart_pressed)
	container.add_child(restart_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit Game"
	quit_btn.pressed.connect(_on_quit_pressed)
	container.add_child(quit_btn)

	pause_panel.add_child(container)
	pause_overlay.add_child(pause_panel)
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -140
	pause_panel.offset_top = -90
	pause_panel.offset_right = 140
	pause_panel.offset_bottom = 90

func _on_menu_pressed() -> void:
	emit_signal("menu_pressed")
	if pause_overlay.visible:
		_hide_pause_menu()
		return
	_show_pause_menu()

func _show_pause_menu() -> void:
	_capture_and_disable_gameplay_buttons()
	pause_overlay.visible = true
	get_tree().paused = true

func _hide_pause_menu() -> void:
	pause_overlay.visible = false
	_restore_gameplay_buttons()
	if get_tree() != null:
		get_tree().paused = false

func _capture_and_disable_gameplay_buttons() -> void:
	_cached_button_states = {
		"end_turn": end_turn_btn.disabled,
		"move": move_btn.disabled,
		"attack": attack_btn.disabled,
		"fortify": fortify_btn.disabled
	}
	end_turn_btn.disabled = true
	move_btn.disabled = true
	attack_btn.disabled = true
	fortify_btn.disabled = true

func _restore_gameplay_buttons() -> void:
	if _cached_button_states.is_empty():
		return
	end_turn_btn.disabled = _cached_button_states.get("end_turn", true)
	move_btn.disabled = _cached_button_states.get("move", true)
	attack_btn.disabled = _cached_button_states.get("attack", true)
	fortify_btn.disabled = _cached_button_states.get("fortify", true)
	_cached_button_states.clear()

func _on_resume_pressed() -> void:
	_hide_pause_menu()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

# ─── Top Bar ──────────────────────────────────────────────────────────────────

func update_turn(turn: int) -> void:
	turn_label.text = "TURN %d" % turn

func update_ap(ap: int) -> void:
	ap_label.text = "AP : %d" % ap

func update_supply(supply: int) -> void:
	supply_label.text = "SUPPLY : %d" % supply

func set_end_turn_button_enabled(enabled: bool) -> void:
	end_turn_btn.disabled = not enabled

# ─── Sidebar ──────────────────────────────────────────────────────────────────

func show_unit_panel(unit: Node, can_move_now: bool = true, can_attack_now: bool = true, can_fortify_now: bool = true) -> void:
	sidebar.visible = true
	unit_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unit_name_label.text = unit.unit_display_name
	unit_portrait.color = unit.get_portrait_color()
	if unit.has_method("get_soldier"):
		var soldier: Soldier = unit.get_soldier()
		if soldier != null:
			unit_name_label.text = "%s\n%s\n\"%s\"\nXP %d (%s)" % [
				soldier.full_name(),
				soldier.hometown,
				soldier.backstory,
				soldier.experience,
				soldier.experience_label()
			]
	health_label.text    = "HEALTH      %d / %d" % [unit.current_health, unit.max_health]
	movement_label.text  = "MOVEMENT  %d / %d" % [unit.current_movement, unit.max_movement]
	move_btn.disabled    = not can_move_now
	attack_btn.disabled  = not can_attack_now
	fortify_btn.disabled = not can_fortify_now

func hide_unit_panel() -> void:
	sidebar.visible = false

# ─── Game Over ────────────────────────────────────────────────────────────────

func show_game_over(player_won: bool) -> void:
	game_over_panel.visible = true
	if player_won:
		result_label.text = "MISSION COMPLETE"
	else:
		result_label.text = "PLATOON ELIMINATED"

func _on_restart() -> void:
	get_tree().reload_current_scene()
