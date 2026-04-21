## soldier_generator.gd
## Autoload — name it "SoldierGenerator"
## Generates randomized but believable soldiers with names, hometowns, backstories

extends Node
class_name SoldierGenerator

const FIRST_NAMES = [
	"Danny", "Ray", "Tommy", "Carl", "Eddie", "Marcus", "Jesse",
	"Bobby", "Frank", "Pete", "Gary", "Leon", "Walt", "Hank",
	"Luis", "Jerome", "Terry", "Marvin", "Curtis", "Dale",
	"Ricky", "Earl", "Gene", "Sal", "Darnell", "Cody", "Victor"
]

const LAST_NAMES = [
	"Reyes", "Kowalski", "Washington", "Martinez", "O'Brien",
	"Jackson", "Nowak", "Taylor", "Rivera", "Hutchins",
	"Williams", "Nguyen", "Briggs", "Cole", "Dominguez",
	"Patterson", "Russo", "King", "Flores", "Dixon",
	"Harmon", "Patel", "Webb", "Garrett", "Malone"
]

const HOMETOWNS = [
	"Albuquerque, NM", "Detroit, MI", "Baton Rouge, LA",
	"Pittsburgh, PA", "Fresno, CA", "Memphis, TN",
	"Omaha, NE", "Louisville, KY", "Hartford, CT",
	"Shreveport, LA", "Akron, OH", "Tulsa, OK",
	"El Paso, TX", "Savannah, GA", "Youngstown, OH",
	"Gary, IN", "Reno, NV", "Dayton, OH",
	"Camden, NJ", "Stockton, CA", "Flint, MI"
]

const BACKSTORIES = [
	"Worked the line at the Ford plant before the draft found him.",
	"Dropped out of junior college. Figured the Army beat staying home.",
	"Third brother to serve. The other two made it back.",
	"Had a girl waiting. Stopped writing her letters after month two.",
	"Volunteered. Still not sure why.",
	"Was gonna be a mechanic. Good with his hands.",
	"Played football in high school. Small town stuff, nothing serious.",
	"His daddy did Korea. Never talked about it.",
	"Used to be funny. Less so now.",
	"Reads paperbacks when he can find them.",
	"Sends half his pay home every month without fail.",
	"Was an Eagle Scout. Swears it helps.",
	"Got here eight months ago. Acts like he's been here forever.",
	"Quiet. Watches everything. Hard to read.",
	"Keeps a photo of his dog in his helmet band.",
	"Was supposed to go to college on a scholarship. Knee went out senior year.",
	"Doesn't talk about home much. Nobody asks anymore.",
	"Good at cards. Too good. You wonder how.",
]

var RANKS_BY_TYPE: Dictionary = {
	Globals.UnitType.RIFLEMAN:       ["Pvt.", "PFC", "Cpl."],
	Globals.UnitType.GRENADIER:      ["PFC", "Cpl.", "Sgt."],
	Globals.UnitType.RECON:          ["Cpl.", "Sgt."],
	Globals.UnitType.MEDIC:          ["Spc.", "Cpl."],
	Globals.UnitType.MACHINE_GUNNER: ["PFC", "Cpl.", "Sgt."],
	Globals.UnitType.TUNNEL_RAT:     ["PFC", "Cpl."],
	Globals.UnitType.M113:           ["Sgt.", "S.Sgt."],
}

# ─── Personalities (affects addiction and morale behavior) ────────────────────

const PERSONALITIES = [
	{
		"name": "Stoic",
		"morale_resistance": 1,    # harder to lose morale
		"addiction_resistance": 1, # less likely to use
	},
	{
		"name": "Reckless",
		"morale_resistance": 0,
		"addiction_resistance": -1, # more likely to use
	},
	{
		"name": "Anxious",
		"morale_resistance": -1,
		"addiction_resistance": -1, # more likely to self-medicate
	},
	{
		"name": "Loyal",
		"morale_resistance": 1,
		"addiction_resistance": 0,
	},
	{
		"name": "Cynical",
		"morale_resistance": 0,
		"addiction_resistance": -1,
	},
]

# ─── Letters Home Pool ────────────────────────────────────────────────────────

const LETTERS_HOME = [
	"%s wrote home. His mother sent cookies that arrived crushed.",
	"%s started a letter. Crossed out the first three lines and gave up.",
	"%s got mail. He didn't say who it was from.",
	"%s hasn't written home in six weeks.",
	"A letter arrived for %s. It was from his girl. He didn't look right after.",
	"%s wrote home about the weather. Said nothing else.",
	"The chaplain helped %s write a letter to his father.",
	"%s received a package from his mother — socks and a Bible verse.",
]

# ─── Generation ───────────────────────────────────────────────────────────────

func generate(unit_type: int) -> Soldier:
	var s := Soldier.new()
	s.first_name = FIRST_NAMES.pick_random()
	s.last_name  = LAST_NAMES.pick_random()
	s.hometown   = HOMETOWNS.pick_random()
	s.backstory  = BACKSTORIES.pick_random()
	s.rank       = RANKS_BY_TYPE.get(unit_type, ["Pvt."])[randi() % RANKS_BY_TYPE.get(unit_type, ["Pvt."]).size()]
	s.morale     = 5
	s.max_morale = 5

	# Attach a personality (stored as a trait for simplicity)
	var personality: Dictionary = PERSONALITIES.pick_random()
	s.traits.append(personality["name"])

	return s

func random_letter(soldier_name: String) -> String:
	var template: String = LETTERS_HOME.pick_random()
	return template % soldier_name
