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

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var turn_label: Label       = $TopBar/HBoxContainer/TurnLabel
@onready var supply_label: Label     = $TopBar/HBoxContainer/SupplyLabel
@onready var ap_label: Label         = $TopBar/HBoxContainer/APLabel
@onready var end_turn_btn: Button    = $TopBar/HBoxContainer/EndTurnButton

@onready var sidebar: PanelContainer = $Sidebar
@onready var unit_name_label: Label  = $Sidebar/VBoxContainer/UnitNameLabel
@onready var health_label: Label     = $Sidebar/VBoxContainer/HealthLabel
@onready var movement_label: Label   = $Sidebar/VBoxContainer/MovementLabel
@onready var move_btn: Button        = $Sidebar/VBoxContainer/MoveButton
@onready var attack_btn: Button      = $Sidebar/VBoxContainer/AttackButton
@onready var fortify_btn: Button     = $Sidebar/VBoxContainer/FortifyButton

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var result_label: Label             = $GameOverPanel/VBoxContainer/ResultLabel

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	move_btn.pressed.connect(func(): emit_signal("move_pressed"))
	attack_btn.pressed.connect(func(): emit_signal("attack_pressed"))
	fortify_btn.pressed.connect(func(): emit_signal("fortify_pressed"))
	end_turn_btn.pressed.connect(func(): emit_signal("end_turn_pressed"))
	$GameOverPanel/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	hide_unit_panel()
	game_over_panel.visible = false

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
	unit_name_label.text = unit.unit_display_name
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
