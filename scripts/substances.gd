## substances.gd
## Autoload — add in Project Settings > Autoload, name it "Substances"
## Defines all substances, their effects, and addiction thresholds

extends Node
class_name Substances

enum SubstanceType {
	NONE,
	AMPHETAMINES,
	HEROIN,
	MARIJUANA,
	ALCOHOL
}

enum AddictionState {
	CLEAN,
	AT_RISK,    # used multiple times, threshold approaching
	ADDICTED,   # requires substance or suffers withdrawal
	WITHDRAWING # addicted and hasn't used this mission
}

# ─── Substance Definitions ────────────────────────────────────────────────────

const SUBSTANCE_DATA = {
	SubstanceType.AMPHETAMINES: {
		"name":             "Amphetamines",
		"short":            "Uppers",
		"supply_cost":      2,
		"addiction_chance": 0.25,   # 25% per use once at-risk
		"buffs": {
			"movement_bonus":   2,
			"attack_bonus":     1,
			"morale_immune":    false,
			"vision_penalty":   0,
		},
		"crash": {                  # applied NEXT mission if used
			"movement_bonus":  -1,
			"attack_bonus":    -1,
			"morale_penalty":   1,
		},
		"withdrawal": {             # applied if addicted and not used
			"movement_bonus":  -2,
			"attack_bonus":    -2,
			"morale_penalty":   3,
		},
		"flavor": "Stays sharp. Maybe too sharp."
	},
	SubstanceType.HEROIN: {
		"name":             "Heroin",
		"short":            "Smack",
		"supply_cost":      3,
		"addiction_chance": 0.45,
		"buffs": {
			"movement_bonus":  -1,
			"attack_bonus":     0,
			"morale_immune":    true,   # cannot lose morale this mission
			"vision_penalty":   0,
		},
		"crash": {
			"movement_bonus":   0,
			"attack_bonus":    -1,
			"morale_penalty":   0,
		},
		"withdrawal": {
			"movement_bonus":  -3,
			"attack_bonus":    -2,
			"morale_penalty":   4,
		},
		"flavor": "Nothing touches him out there. Nothing touches him at all."
	},
	SubstanceType.MARIJUANA: {
		"name":             "Marijuana",
		"short":            "Grass",
		"supply_cost":      1,
		"addiction_chance": 0.08,
		"buffs": {
			"movement_bonus":   0,
			"attack_bonus":     0,
			"morale_immune":    false,
			"vision_penalty":  -1,      # vision radius shrinks by 1
			"morale_restore":   true,   # fully restores morale before mission
		},
		"crash": {
			"movement_bonus":   0,
			"attack_bonus":     0,
			"morale_penalty":   0,
		},
		"withdrawal": {
			"movement_bonus":   0,
			"attack_bonus":    -1,
			"morale_penalty":   1,
		},
		"flavor": "Calmer than he should be. Slower than you'd like."
	},
	SubstanceType.ALCOHOL: {
		"name":             "Alcohol",
		"short":            "Booze",
		"supply_cost":      1,
		"addiction_chance": 0.12,
		"buffs": {
			"movement_bonus":  -1,
			"attack_bonus":     1,
			"morale_immune":    false,
			"vision_penalty":   0,
		},
		"crash": {
			"movement_bonus":  -1,
			"attack_bonus":     0,
			"morale_penalty":   0,
		},
		"withdrawal": {
			"movement_bonus":  -1,
			"attack_bonus":    -1,
			"morale_penalty":   2,
		},
		"flavor": "Loose. Loud. Effective, sometimes."
	}
}

# ─── Policy Options ───────────────────────────────────────────────────────────

enum PlatoonPolicy {
	BLIND_EYE,       # usage unrestricted, addiction risk unmodified
	MANAGE_QUIETLY,  # costs 1 supply/mission, addiction chance reduced 50%
	ENFORCE_STRICT   # no usage allowed, platoon morale -1/turn but no addiction
}

const POLICY_NAMES = {
	PlatoonPolicy.BLIND_EYE:      "Turn a Blind Eye",
	PlatoonPolicy.MANAGE_QUIETLY: "Manage It Quietly",
	PlatoonPolicy.ENFORCE_STRICT: "Enforce Discipline",
}

const POLICY_DESCRIPTIONS = {
	PlatoonPolicy.BLIND_EYE:
		"Men use freely. Short-term edge. Long-term risk.",
	PlatoonPolicy.MANAGE_QUIETLY:
		"Costs supply to contain. Reduces addiction risk.",
	PlatoonPolicy.ENFORCE_STRICT:
		"No usage tolerated. Morale penalty. No addiction risk.",
}
