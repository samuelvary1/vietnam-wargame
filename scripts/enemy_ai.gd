## enemy_ai.gd
## Attach to a Node called "EnemyAI" in Main scene
## Simple AI: each VC unit moves toward the nearest US unit and attacks if in range

extends Node

signal turn_complete

# ─── Entry Point ──────────────────────────────────────────────────────────────

func take_turn(enemy_units: Array, player_units: Array, hex_grid: Node) -> void:
	## Called by Main when the enemy phase begins.
	## Processes each enemy unit with a short delay for visual clarity.
	_process_units(enemy_units.duplicate(), player_units, hex_grid)

func _process_units(enemies: Array, players: Array, hex_grid: Node) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		await get_tree().create_timer(0.4).timeout
		_act(enemy, players, hex_grid)
	await get_tree().create_timer(0.3).timeout
	emit_signal("turn_complete")

# ─── Unit Logic ───────────────────────────────────────────────────────────────

func _act(enemy: Node, players: Array, hex_grid: Node) -> void:
	var target: Node = _nearest_player(enemy, players, hex_grid)
	if target == null:
		return

	var dist: int = int(hex_grid.hex_distance(enemy.hex_position, target.hex_position))

	# Already in attack range — attack immediately
	if dist <= enemy.attack_range:
		target.take_damage(enemy.attack_power)
		return

	# Move toward target
	var reachable: Array[Vector2i] = hex_grid.get_reachable_cells(enemy.hex_position, enemy.current_movement)
	if reachable.is_empty():
		return

	var best_cell := _closest_cell_to(reachable, target.hex_position, hex_grid)
	hex_grid.move_unit(enemy, best_cell)

	# Attack after moving if now in range
	var new_dist: int = int(hex_grid.hex_distance(enemy.hex_position, target.hex_position))
	if new_dist <= enemy.attack_range:
		target.take_damage(enemy.attack_power)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _nearest_player(enemy: Node, players: Array, hex_grid: Node) -> Node:
	var nearest: Node = null
	var min_dist: int = 9999
	for p in players:
		if not is_instance_valid(p):
			continue
		var d: int = int(hex_grid.hex_distance(enemy.hex_position, p.hex_position))
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

func _closest_cell_to(cells: Array, target: Vector2i, hex_grid: Node) -> Vector2i:
	var best: Vector2i = cells[0]
	var best_dist: int = int(hex_grid.hex_distance(cells[0], target))
	for cell in cells:
		var d: int = int(hex_grid.hex_distance(cell, target))
		if d < best_dist:
			best_dist = d
			best = cell
	return best
