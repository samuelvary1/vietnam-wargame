## pre_mission_screen.gd
## Attach to a CanvasLayer scene (PreMissionScreen.tscn)
## Shown between missions — displays roster, events, and policy controls
##
## Scene structure:
##   CanvasLayer
##     PanelContainer (full screen, dark background)
##       VBoxContainer
##         Label (name: MissionTitle)       -- "MISSION 3 — IA DRANG VALLEY"
##         HSeparator
##         HBoxContainer
##           ── LEFT: Roster ──
##           VBoxContainer (name: RosterPanel, size_flags expand)
##             Label "PLATOON"
##             VBoxContainer (name: SoldierList)  -- populated in code
##           ── RIGHT: Events + Policy ──
##           VBoxContainer (size_flags expand)
##             Label "INTEL"
##             VBoxContainer (name: EventLog)    -- narrative events
##             HSeparator
##             Label "COMMAND POLICY"
##             HBoxContainer (name: PolicyButtons)
##               Button (name: BlindEyeBtn)
##               Button (name: ManageBtn)
##               Button (name: StrictBtn)
##             HSeparator
##             Label (name: SupplyDisplay) "SUPPLY: 12"
##         HSeparator
##         Button (name: DeployButton) "DEPLOY"

extends CanvasLayer

signal deploy_ready

@onready var mission_title: Label         = $PanelContainer/VBoxContainer/MissionTitle
@onready var soldier_list: VBoxContainer  = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/SoldierList
@onready var event_log: VBoxContainer     = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/EventLog
@onready var supply_display: Label        = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/SupplyDisplay
@onready var deploy_btn: Button           = $PanelContainer/VBoxContainer/DeployButton

@onready var blind_eye_btn: Button        = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PolicyButtons/BlindEyeBtn
@onready var manage_btn: Button           = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PolicyButtons/ManageBtn
@onready var strict_btn: Button           = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/PolicyButtons/StrictBtn

var substance_manager: Node = null
var current_supply: int = 12
var soldiers: Array[Soldier] = []

# ─── Setup ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	deploy_btn.pressed.connect(func(): emit_signal("deploy_ready"))
	blind_eye_btn.pressed.connect(func(): _set_policy(Substances.PlatoonPolicy.BLIND_EYE))
	manage_btn.pressed.connect(func(): _set_policy(Substances.PlatoonPolicy.MANAGE_QUIETLY))
	strict_btn.pressed.connect(func(): _set_policy(Substances.PlatoonPolicy.ENFORCE_STRICT))

func populate(mission_name: String, platoon: Array[Soldier], supply: int, mgr: Node) -> void:
	soldiers = platoon
	current_supply = supply
	substance_manager = mgr

	mission_title.text = mission_name
	supply_display.text = "SUPPLY: %d" % supply

	_build_roster()
	_run_pre_mission_events()
	_highlight_policy_button(substance_manager.platoon_policy)

# ─── Roster Panel ─────────────────────────────────────────────────────────────

func _build_roster() -> void:
	for child in soldier_list.get_children():
		child.queue_free()

	for soldier in soldiers:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		var status_lbl := Label.new()

		name_lbl.text = "%s — %s" % [soldier.full_name(), soldier.hometown]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		status_lbl.text = _status_text(soldier)
		status_lbl.modulate = _status_color(soldier)

		row.add_child(name_lbl)
		row.add_child(status_lbl)
		soldier_list.add_child(row)

		# Backstory on second line
		if soldier.backstory != "":
			var backstory_lbl := Label.new()
			backstory_lbl.text = "    \"%s\"" % soldier.backstory
			backstory_lbl.modulate = Color(0.7, 0.7, 0.7)
			backstory_lbl.add_theme_font_size_override("font_size", 11)
			soldier_list.add_child(backstory_lbl)

		# Traits
		if not soldier.traits.is_empty():
			var trait_lbl := Label.new()
			trait_lbl.text = "    [%s]" % ", ".join(soldier.traits)
			trait_lbl.modulate = Color(0.85, 0.75, 0.4)
			trait_lbl.add_theme_font_size_override("font_size", 11)
			soldier_list.add_child(trait_lbl)

		# Letters
		if not soldier.letters.is_empty():
			var letter_lbl := Label.new()
			letter_lbl.text = "    %s" % soldier.letters[-1]
			letter_lbl.modulate = Color(0.6, 0.8, 0.6)
			letter_lbl.add_theme_font_size_override("font_size", 11)
			soldier_list.add_child(letter_lbl)

		# Spacer
		soldier_list.add_child(HSeparator.new())

# ─── Event Log ────────────────────────────────────────────────────────────────

func _run_pre_mission_events() -> void:
	for child in event_log.get_children():
		child.queue_free()

	if substance_manager == null:
		return

	var result: Dictionary = substance_manager.process_pre_mission(soldiers, current_supply)

	current_supply -= result["supply_spent"]
	supply_display.text = "SUPPLY: %d" % current_supply

	for event_text in result["events"]:
		_add_event(event_text)

	# Random letter home
	if soldiers.size() > 0 and randf() > 0.5:
		var random_soldier: Soldier = soldiers.pick_random()
		var letter: String = SoldierGenerator.random_letter(random_soldier.first_name)
		random_soldier.letters.append(letter)
		_add_event(letter)

func _add_event(text: String) -> void:
	var lbl := Label.new()
	lbl.text = "— " + text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_log.add_child(lbl)

# ─── Policy ───────────────────────────────────────────────────────────────────

func _set_policy(policy: int) -> void:
	substance_manager.platoon_policy = policy
	_highlight_policy_button(policy)
	_add_event("Policy changed: %s" % Substances.POLICY_NAMES[policy])
	_add_event(Substances.POLICY_DESCRIPTIONS[policy])

func _highlight_policy_button(policy: int) -> void:
	blind_eye_btn.modulate = Color.WHITE
	manage_btn.modulate    = Color.WHITE
	strict_btn.modulate    = Color.WHITE

	match policy:
		Substances.PlatoonPolicy.BLIND_EYE:      blind_eye_btn.modulate = Color(1.0, 0.85, 0.3)
		Substances.PlatoonPolicy.MANAGE_QUIETLY: manage_btn.modulate    = Color(1.0, 0.85, 0.3)
		Substances.PlatoonPolicy.ENFORCE_STRICT: strict_btn.modulate    = Color(1.0, 0.85, 0.3)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _status_text(soldier: Soldier) -> String:
	match soldier.wound_state:
		"kia":          return "KIA"
		"serious_wound": return "WOUNDED (%d)" % soldier.missions_until_return
		"light_wound":  return "LIGHT WOUND"
	match soldier.addiction_state:
		Substances.AddictionState.ADDICTED:   return "DEPENDENT"
		Substances.AddictionState.AT_RISK:    return "AT RISK"
	if soldier.is_short_timer():           return "SHORT-TIMER"
	return "FIT"

func _status_color(soldier: Soldier) -> Color:
	match soldier.wound_state:
		"kia":           return Color(0.4, 0.4, 0.4)
		"serious_wound": return Color(1.0, 0.3, 0.3)
		"light_wound":   return Color(1.0, 0.65, 0.2)
	match soldier.addiction_state:
		Substances.AddictionState.ADDICTED: return Color(0.8, 0.4, 1.0)
		Substances.AddictionState.AT_RISK:  return Color(1.0, 0.7, 0.3)
	if soldier.is_short_timer():          return Color(0.5, 1.0, 0.8)
	return Color(0.7, 1.0, 0.7)
