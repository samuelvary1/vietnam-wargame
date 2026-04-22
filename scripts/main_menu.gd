extends CanvasLayer
class_name MainMenu

signal new_game_requested
signal load_game_requested
signal exit_requested

var _status_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.04, 0.94)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 360)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "VIETNAM PATROL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.78, 0.16, 0.13))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "1968-1971 campaign prototype"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.74))
	vbox.add_child(subtitle)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(top_spacer)

	var new_btn := Button.new()
	new_btn.text = "New Game"
	new_btn.custom_minimum_size = Vector2(260, 44)
	new_btn.pressed.connect(_on_new_game_pressed)
	vbox.add_child(new_btn)

	var load_btn := Button.new()
	load_btn.text = "Load Game"
	load_btn.custom_minimum_size = Vector2(260, 44)
	load_btn.pressed.connect(_on_load_pressed)
	vbox.add_child(load_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Exit"
	exit_btn.custom_minimum_size = Vector2(260, 44)
	exit_btn.pressed.connect(func(): emit_signal("exit_requested"))
	vbox.add_child(exit_btn)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(bottom_spacer)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.66))
	_status_label.text = ""
	vbox.add_child(_status_label)

func _on_new_game_pressed() -> void:
	emit_signal("new_game_requested")

func _on_load_pressed() -> void:
	emit_signal("load_game_requested")

func show_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
