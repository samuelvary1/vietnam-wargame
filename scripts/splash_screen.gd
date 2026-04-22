extends CanvasLayer

signal splash_finished

# Paste the lyric lines here (4 lines of the Rooster verse)
const LYRIC_LINES: Array[String] = [
	"Here they come to snuff the Rooster, aw, yeah",
	"Yeah, here come the Rooster, yeah",
	"You know he ain't gonna die",
	"No, no, no, you know he ain't gonna die",
]

const ATTRIBUTION := "- Alice in Chains, 'Rooster'"

var _fade_tween: Tween
var _root: Control

func _ready() -> void:
	_build_ui()
	_run_sequence()

func _build_ui() -> void:
	# Root control — this is what we animate
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# Black background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var red := Color(0.85, 0.05, 0.05)
	var cream := Color(0.85, 0.82, 0.75)

	# Lyric lines — italic, red, large
	for line in LYRIC_LINES:
		var lbl := Label.new()
		lbl.text = line
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", red)
		lbl.add_theme_font_size_override("font_size", 40)
		# Italic-ish slant via theme isn't built-in without a font; rely on size + color
		vbox.add_child(lbl)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(spacer)

	# Attribution
	var attr := Label.new()
	attr.text = ATTRIBUTION
	attr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr.add_theme_color_override("font_color", cream)
	attr.add_theme_font_size_override("font_size", 22)
	vbox.add_child(attr)

	# Click-to-continue hint
	var hint_spacer := Control.new()
	hint_spacer.custom_minimum_size = Vector2(0, 56)
	vbox.add_child(hint_spacer)

	var hint := Label.new()
	hint.text = "[ click to continue ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	hint.add_theme_font_size_override("font_size", 16)
	vbox.add_child(hint)

func _run_sequence() -> void:
	_root.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 1.0, 2.0).set_ease(Tween.EASE_IN)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventKey and event.pressed and not event.echo:
		_dismiss()

func _dismiss() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(func(): emit_signal("splash_finished"); queue_free())
