extends CanvasLayer
class_name RosterSelection

signal deploy_confirmed(selected_soldiers: Array)
signal cancel_requested

const MAX_SELECTION := 6

var _status_label: Label
var _list: VBoxContainer
var _deploy_button: Button
var _selected: Array[Soldier] = []

func _ready() -> void:
	_build_ui()

func populate(soldiers: Array[Soldier]) -> void:
	_selected.clear()
	for child in _list.get_children():
		child.queue_free()

	for soldier in soldiers:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 30)

		var check := CheckBox.new()
		check.custom_minimum_size = Vector2(24, 0)
		check.toggled.connect(func(pressed: bool): _on_toggled(soldier, check, pressed))
		row.add_child(check)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
		label.text = "%s | %s | %s | XP %d (%s)" % [
			soldier.full_name(),
			Globals.UNIT_NAMES.get(soldier.primary_role, "Rifleman"),
			soldier.hometown,
			soldier.experience,
			soldier.experience_label()
		]
		row.add_child(label)

		var portrait := ColorRect.new()
		portrait.custom_minimum_size = Vector2(30, 20)
		portrait.color = _portrait_color_for(soldier)
		row.add_child(portrait)

		_list.add_child(row)

	_update_status()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.03, 0.03, 0.97)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 30)
	root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Select Patrol"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.78, 0.16, 0.13))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose exactly 6 soldiers for this mission"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.84, 0.78))
	vbox.add_child(subtitle)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	vbox.add_child(actions)

	var cancel_button := Button.new()
	cancel_button.text = "Back"
	cancel_button.custom_minimum_size = Vector2(140, 42)
	cancel_button.pressed.connect(func(): emit_signal("cancel_requested"))
	actions.add_child(cancel_button)

	_deploy_button = Button.new()
	_deploy_button.text = "Deploy Patrol"
	_deploy_button.custom_minimum_size = Vector2(180, 42)
	_deploy_button.disabled = true
	_deploy_button.pressed.connect(_on_deploy_pressed)
	actions.add_child(_deploy_button)

func _on_toggled(soldier: Soldier, check: CheckBox, pressed: bool) -> void:
	if pressed:
		if soldier not in _selected:
			_selected.append(soldier)
	else:
		_selected.erase(soldier)

	if _selected.size() > MAX_SELECTION:
		_selected.erase(soldier)
		check.button_pressed = false

	_update_status()

func _on_deploy_pressed() -> void:
	if _selected.size() != MAX_SELECTION:
		return
	emit_signal("deploy_confirmed", _selected.duplicate())

func _update_status() -> void:
	_status_label.text = "Selected %d / %d" % [_selected.size(), MAX_SELECTION]
	if _selected.size() == MAX_SELECTION:
		_status_label.modulate = Color(0.7, 1.0, 0.7)
		_deploy_button.disabled = false
	else:
		_status_label.modulate = Color(1.0, 0.75, 0.5)
		_deploy_button.disabled = true

func _portrait_color_for(soldier: Soldier) -> Color:
	return Globals.portrait_color(soldier.portrait_id)
