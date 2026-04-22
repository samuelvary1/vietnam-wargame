## unit.gd
## Attach to a Node2D scene (Unit.tscn)
## Scene structure:
##   Unit (Node2D) <- this script
##     Background (ColorRect)   -- 48x48 colored square
##     Sprite2D                 -- unit icon (placeholder: leave empty)
##     Label                    -- shows "HP/MV" e.g. "4/3"
##     Area2D                   -- for click detection
##       CollisionShape2D       -- RectangleShape2D, 48x48

extends Node2D

const UNIT_HEX_RADIUS: float = 18.0

signal unit_clicked(unit: Node)
signal unit_died(unit: Node)

# ─── Properties ───────────────────────────────────────────────────────────────

@export var unit_display_name: String = "Rifleman"
@export var team: int = Globals.Team.US
@export var unit_type: int = Globals.UnitType.RIFLEMAN
@export var max_health: int = 6
@export var max_movement: int = 3
@export var attack_power: int = 2
@export var attack_range: int = 1

# ─── State ────────────────────────────────────────────────────────────────────

var current_health: int
var current_movement: int
var has_attacked: bool = false
var is_fortified: bool = false
var hex_position: Vector2i
var soldier: Soldier = null

# ─── Node refs ────────────────────────────────────────────────────────────────

@onready var background: ColorRect = $Background
@onready var label: Label = $Label
@onready var click_area: Area2D = $Area2D

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	current_health = max_health
	current_movement = max_movement
	background.visible = false
	click_area.input_pickable = true
	click_area.input_event.connect(_on_input_event)
	_refresh_display()

func setup_from_type() -> void:
	## Call this after setting unit_type to auto-fill stats from globals
	var stats: Array = Globals.UNIT_STATS[unit_type]
	max_health      = stats[0]
	max_movement    = stats[1]
	attack_power    = stats[2]
	attack_range    = stats[3]
	unit_display_name = Globals.UNIT_NAMES[unit_type]
	current_health  = max_health
	current_movement = max_movement
	_refresh_display()

func assign_soldier(soldier_data: Soldier) -> void:
	soldier = soldier_data
	if soldier == null:
		return
	unit_display_name = soldier.full_name()
	max_movement = max(1, max_movement + soldier.get_movement_modifier())
	attack_power = max(1, attack_power + soldier.get_attack_modifier())
	current_health = max_health
	current_movement = max_movement
	_refresh_display()

func get_soldier() -> Soldier:
	return soldier

func get_portrait_color() -> Color:
	if soldier == null:
		return Color(0.18, 0.18, 0.18, 1.0)
	var palette := [
		Color(0.46, 0.35, 0.28),
		Color(0.58, 0.42, 0.31),
		Color(0.71, 0.56, 0.43),
		Color(0.33, 0.24, 0.18),
		Color(0.62, 0.5, 0.41),
		Color(0.4, 0.3, 0.22),
	]
	return palette[soldier.portrait_id % palette.size()]

# ─── Display ──────────────────────────────────────────────────────────────────

func _refresh_display() -> void:
	label.text = "%d/%d" % [current_health, current_movement]
	queue_redraw()

func set_selected(selected: bool) -> void:
	if selected:
		modulate = Color(1.6, 1.6, 0.5, 1.0)  # yellow glow
	else:
		modulate = Color.WHITE

# ─── Turn Management ──────────────────────────────────────────────────────────

func reset_for_new_turn() -> void:
	current_movement = max_movement
	has_attacked = false
	is_fortified = false
	modulate = Color.WHITE
	_refresh_display()

func mark_exhausted() -> void:
	## Dim the unit when it has no AP left to spend
	modulate = Color(0.6, 0.6, 0.6, 1.0)

# ─── Queries ──────────────────────────────────────────────────────────────────

func can_move() -> bool:
	return current_movement > 0

func can_attack() -> bool:
	return not has_attacked

# ─── Actions ──────────────────────────────────────────────────────────────────

func spend_movement(amount: int) -> void:
	current_movement = max(0, current_movement - amount)
	_refresh_display()

func take_damage(amount: int) -> void:
	var effective := amount
	if is_fortified:
		effective = max(1, amount - 1)  # fortify reduces damage by 1, min 1
	current_health -= effective
	_refresh_display()
	_flash_damage()
	if current_health <= 0:
		emit_signal("unit_died", self)
		queue_free()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	_refresh_display()

# ─── Visuals ──────────────────────────────────────────────────────────────────

func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.2, 0.2), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _draw() -> void:
	var outer_points: PackedVector2Array = _unit_hex_points(UNIT_HEX_RADIUS)
	var inner_points: PackedVector2Array = _unit_hex_points(UNIT_HEX_RADIUS - 4.0)
	draw_colored_polygon(outer_points, Color(0.1, 0.12, 0.12, 0.95))
	draw_colored_polygon(inner_points, _unit_fill_color())
	draw_polyline(_closed_points(outer_points), Color(0.85, 0.9, 0.82, 0.7), 1.4, true)

func contains_point(point: Vector2) -> bool:
	var local_point: Vector2 = point - position
	return Geometry2D.is_point_in_polygon(local_point, _unit_hex_points(UNIT_HEX_RADIUS + 3.0))

func _unit_fill_color() -> Color:
	if team == Globals.Team.US:
		return Color(0.2, 0.5, 0.2, 0.96)
	return Color(0.72, 0.16, 0.14, 0.96)

func _unit_hex_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * float(i))
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if not closed.is_empty():
		closed.append(closed[0])
	return closed

# ─── Input ────────────────────────────────────────────────────────────────────

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("unit_clicked", self)
