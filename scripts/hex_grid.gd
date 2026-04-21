## hex_grid.gd
## Attach to a TileMapLayer node (Godot 4.x)
## Handles hex math, terrain, movement ranges, and unit tracking

extends TileMapLayer

signal hex_clicked(hex_coords: Vector2i)

const HEX_SIZE: float = 32.0
const BOARD_ORIGIN: Vector2 = Vector2(620.0, 320.0)

# ─── Hex Direction Vectors (flat-top axial) ───────────────────────────────────
const DIRECTIONS = [
	Vector2i(1,  0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0,  1)
]

# ─── State ────────────────────────────────────────────────────────────────────
var terrain_map: Dictionary = {}          # Vector2i -> TerrainType
var units_on_grid: Dictionary = {}        # Vector2i -> Unit node
var highlighted_cells: Array[Vector2i] = []

# TileSet source IDs — set these to match your actual TileSet
# For placeholder: just use colored rectangles in a single-tile atlas
const TERRAIN_SOURCE_ID = 0
const HIGHLIGHT_SOURCE_ID = 1  # a semi-transparent tile for movement range

# Atlas coords per terrain (row 0 = your terrain tiles in order)
var TERRAIN_ATLAS: Dictionary = {
	Globals.TerrainType.JUNGLE:     Vector2i(0, 0),
	Globals.TerrainType.RICE_PADDY: Vector2i(1, 0),
	Globals.TerrainType.VILLAGE:    Vector2i(2, 0),
	Globals.TerrainType.PATH:       Vector2i(3, 0),
	Globals.TerrainType.WATER:      Vector2i(4, 0),
}

# ─── Setup ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	generate_test_map()
	queue_redraw()

func generate_test_map() -> void:
	## Produces a simple 11x11 hex map for prototyping.
	## Replace with hand-crafted mission maps later.
	for q in range(-5, 6):
		for r in range(-5, 6):
			var coords := Vector2i(q, r)
			var terrain := _assign_terrain(q, r)
			terrain_map[coords] = terrain
			set_cell(coords, TERRAIN_SOURCE_ID, TERRAIN_ATLAS[terrain])
	queue_redraw()

func _assign_terrain(q: int, r: int) -> int:
	# Simple procedural rules — swap for real mission design later
	if abs(q) <= 1 and abs(r) <= 1:
		return Globals.TerrainType.RICE_PADDY
	if q >= 3:
		return Globals.TerrainType.VILLAGE
	if r == -2 and q < 3:
		return Globals.TerrainType.PATH
	if abs(q + r) == 4:
		return Globals.TerrainType.WATER
	return Globals.TerrainType.JUNGLE

# ─── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var unit: Node = get_unit_under_point(mouse_pos)
		if unit != null:
			emit_signal("hex_clicked", unit.hex_position)
			return

		var hex := world_to_axial(mouse_pos)
		if terrain_map.has(hex):
			emit_signal("hex_clicked", hex)

func get_unit_under_point(point: Vector2) -> Node:
	for unit in units_on_grid.values():
		if unit == null or not is_instance_valid(unit):
			continue
		if unit.has_method("contains_point") and unit.contains_point(point):
			return unit
	return null

func axial_to_world(hex: Vector2i) -> Vector2:
	# Flat-top axial conversion independent of TileSet.
	var x: float = HEX_SIZE * (1.5 * float(hex.x))
	var y: float = HEX_SIZE * (sqrt(3.0) * (float(hex.y) + float(hex.x) * 0.5))
	return BOARD_ORIGIN + Vector2(x, y)

func world_to_axial(pos: Vector2) -> Vector2i:
	# Convert world position to nearest axial hex using cube rounding.
	var rel: Vector2 = pos - BOARD_ORIGIN
	var qf: float = (2.0 / 3.0) * rel.x / HEX_SIZE
	var rf: float = ((-1.0 / 3.0) * rel.x + (sqrt(3.0) / 3.0) * rel.y) / HEX_SIZE
	var xf: float = qf
	var zf: float = rf
	var yf: float = -xf - zf

	var rx: int = int(round(xf))
	var ry: int = int(round(yf))
	var rz: int = int(round(zf))

	var x_diff: float = abs(float(rx) - xf)
	var y_diff: float = abs(float(ry) - yf)
	var z_diff: float = abs(float(rz) - zf)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)

func _draw() -> void:
	for hex in terrain_map.keys():
		var cell: Vector2i = hex
		var center: Vector2 = axial_to_world(cell)
		var points: PackedVector2Array = _hex_points(center, HEX_SIZE - 1.0)
		draw_colored_polygon(points, _terrain_color(int(terrain_map[cell])))
		draw_polyline(points, Color(0.18, 0.2, 0.2, 0.9), 1.5, true)

	for cell in highlighted_cells:
		var center: Vector2 = axial_to_world(cell)
		var points: PackedVector2Array = _hex_points(center, HEX_SIZE - 6.0)
		draw_colored_polygon(points, Color(1.0, 1.0, 0.3, 0.35))

func _hex_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * float(i))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	pts.append(pts[0])
	return pts

func _terrain_color(terrain: int) -> Color:
	match terrain:
		Globals.TerrainType.JUNGLE:
			return Color(0.16, 0.34, 0.18, 1.0)
		Globals.TerrainType.RICE_PADDY:
			return Color(0.42, 0.56, 0.34, 1.0)
		Globals.TerrainType.VILLAGE:
			return Color(0.5, 0.42, 0.32, 1.0)
		Globals.TerrainType.PATH:
			return Color(0.55, 0.48, 0.35, 1.0)
		Globals.TerrainType.WATER:
			return Color(0.18, 0.32, 0.5, 1.0)
		_:
			return Color(0.2, 0.2, 0.2, 1.0)

# ─── Hex Math ─────────────────────────────────────────────────────────────────

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	## Axial distance between two hex coords
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2

func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var n: Vector2i = hex + dir
		if terrain_map.has(n):
			result.append(n)
	return result

# ─── Movement & Range ─────────────────────────────────────────────────────────

func get_reachable_cells(start: Vector2i, movement_points: int) -> Array[Vector2i]:
	## BFS — returns all cells reachable within movement_points,
	## excluding cells occupied by any unit.
	var visited: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	var reachable: Array[Vector2i] = []

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var cost_so_far: int = visited[current]

		for neighbor in get_neighbors(current):
			var terrain: int = terrain_map.get(neighbor, Globals.TerrainType.JUNGLE)
			var move_cost: int = Globals.TERRAIN_MOVE_COST[terrain]
			var new_cost: int = cost_so_far + move_cost

			if new_cost <= movement_points:
				if not visited.has(neighbor) or visited[neighbor] > new_cost:
					visited[neighbor] = new_cost
					if not units_on_grid.has(neighbor):
						reachable.append(neighbor)
						queue.append(neighbor)

	return reachable

func get_cells_in_range(center: Vector2i, attack_range: int) -> Array[Vector2i]:
	## Returns all valid hex cells within attack_range of center.
	var result: Array[Vector2i] = []
	for q in range(-attack_range, attack_range + 1):
		var r_min: int = int(max(-attack_range, -q - attack_range))
		var r_max: int = int(min(attack_range, -q + attack_range))
		for r in range(r_min, r_max + 1):
			var hex := center + Vector2i(q, r)
			if hex != center and terrain_map.has(hex):
				result.append(hex)
	return result

# ─── Highlighting ─────────────────────────────────────────────────────────────

func highlight_move_range(cells: Array[Vector2i]) -> void:
	clear_highlights()
	for cell in cells:
		# Layer 1 stores highlights — needs a semi-transparent tile in your TileSet
		# For placeholder: just tint the cell using a second TileMapLayer above this one
		set_cell(cell, HIGHLIGHT_SOURCE_ID, Vector2i(0, 0))
	highlighted_cells = cells.duplicate()
	queue_redraw()

func highlight_attack_range(cells: Array[Vector2i]) -> void:
	clear_highlights()
	for cell in cells:
		set_cell(cell, HIGHLIGHT_SOURCE_ID, Vector2i(1, 0))  # red highlight tile
	highlighted_cells = cells.duplicate()
	queue_redraw()

func clear_highlights() -> void:
	for cell in highlighted_cells:
		var terrain: int = int(terrain_map.get(cell, -1))
		if terrain != -1:
			set_cell(cell, TERRAIN_SOURCE_ID, TERRAIN_ATLAS[terrain])
		else:
			erase_cell(cell)
	highlighted_cells.clear()
	queue_redraw()

# ─── Unit Placement ───────────────────────────────────────────────────────────

func place_unit(unit: Node, hex: Vector2i) -> void:
	units_on_grid[hex] = unit
	unit.hex_position = hex
	unit.position = axial_to_world(hex)

func move_unit(unit: Node, to: Vector2i) -> void:
	units_on_grid.erase(unit.hex_position)
	units_on_grid[to] = unit
	unit.hex_position = to
	# Tween the unit to the new position for visual smoothness
	var tween := create_tween()
	tween.tween_property(unit, "position", axial_to_world(to), 0.25)

func remove_unit(unit: Node) -> void:
	units_on_grid.erase(unit.hex_position)

func get_unit_at(hex: Vector2i) -> Node:
	return units_on_grid.get(hex, null)
