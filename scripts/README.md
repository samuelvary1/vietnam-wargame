# Vietnam Wargame — Godot 4 Starter Project

A hex-grid turn-based wargame. US platoon vs. Viet Cong.
Chess-like movement, action points, supply, morale.

---

## Files in /scripts/

| File | Purpose |
|------|---------|
| globals.gd | Autoload — enums, unit stats, terrain costs |
| game_manager.gd | Turns, AP, supply, win/loss |
| hex_grid.gd | Hex math, movement BFS, unit tracking |
| unit.gd | Unit data, health, combat, display |
| enemy_ai.gd | VC AI — move toward player, attack |
| ui_manager.gd | Top bar + sidebar panel |
| main.gd | Central controller, wires everything |

---

## Step 1 — Project Setup

1. Download and install **Godot 4** from godotengine.org
2. Create a new project (2D, Forward+)
3. Copy all .gd files into `res://scripts/`
4. Go to **Project > Project Settings > Globals (Autoload)**
5. Add `res://scripts/globals.gd` with the name `Globals`

---

## Step 2 — Create scenes/Unit.tscn

In the Scene panel, build this tree:

```
Node2D  (name: Unit)  <-- attach unit.gd
  ColorRect  (name: Background)
    size: 48 x 48
    position: -24, -24
  Label  (name: Label)
    position: -20, 10
    font_size: 12
  Area2D  (name: Area2D)
    CollisionShape2D
      shape: RectangleShape2D, size 48x48
```

Save as `res://scenes/Unit.tscn`

---

## Step 3 — Create scenes/Main.tscn

Build this tree:

```
Node2D  (name: Main)  <-- attach main.gd
  TileMapLayer  (name: HexGrid)  <-- attach hex_grid.gd
  Node  (name: GameManager)  <-- attach game_manager.gd
  Node  (name: EnemyAI)  <-- attach enemy_ai.gd
  CanvasLayer  (name: UIManager)  <-- attach ui_manager.gd
    PanelContainer  (name: TopBar)
      anchor: top-full (top=0, left=0, right=1, bottom=0)
      min_size_y: 50
      HBoxContainer
        Label  (name: TurnLabel)   text: "TURN 1"
        Label  (name: SupplyLabel) text: "SUPPLY : 12"
        Label  (name: APLabel)     text: "AP : 3"
        Button (name: EndTurnButton) text: "END TURN"
    PanelContainer  (name: Sidebar)
      anchor: left (top=0, left=0, right=0, bottom=1)
      min_size_x: 280
      VBoxContainer
        Label  (name: UnitNameLabel)
        Label  (name: HealthLabel)
        Label  (name: MovementLabel)
        Button (name: MoveButton)    text: "MOVE"
        Button (name: AttackButton)  text: "ATTACK"
        Button (name: FortifyButton) text: "FORTIFY"
    PanelContainer  (name: GameOverPanel)  visible: false
      VBoxContainer
        Label  (name: ResultLabel)
        Button (name: RestartButton) text: "RESTART"
```

Save as `res://scenes/Main.tscn`
Set Main.tscn as the main scene in Project Settings.

---

## Step 4 — TileMap Setup (placeholder)

1. Select the HexGrid TileMapLayer node
2. In Inspector, create a new TileSet
3. Set tile_shape to **Hexagon**
4. Set tile_layout to **Stacked** (or Offset Rows)
5. Set tile_size to 64 x 74 (standard hex size)
6. In the TileSet editor, add a new source
7. For placeholder: create a 512x74 image with 5 colored rectangles side by side
   (one per terrain type: dark green, light green, tan, brown, blue)
8. Set the atlas tile size to 64x74

For highlights, add a second source with two semi-transparent tiles:
- Index 0: green tint (movement range)
- Index 1: red tint (attack range)

---

## Step 5 — Run It

Hit F5. You should see:
- A hex grid with colored terrain
- US units (green tokens) on the left
- VC units (red tokens) on the right
- Top bar with TURN / SUPPLY / AP / END TURN
- Click a US unit → sidebar panel appears
- Click MOVE → green cells highlight
- Click a highlighted cell → unit moves
- Click ATTACK → red cells highlight
- Click an enemy on a red cell → damage dealt
- Click END TURN → VC units move toward you

---

## What to Build Next

**Short term:**
- Fog of war (darken tiles outside unit vision range)
- Terrain defense bonuses (jungle = +1 defense)
- Tunnel tiles (VC appear from unexpected hexes)
- Sound effects (gunshot, move)

**Medium term:**
- Campaign map screen between missions
- Persistent unit names — soldiers survive or die
- Booby trap tiles (hidden, revealed on movement)
- Helicopter extraction win condition

**Long term:**
- Mission editor
- Second playable side (VC campaign)
- Morale system (units retreat when morale hits zero)
- Historical mission scripts (Ia Drang, Hue City, Khe Sanh)

---

## Key Godot 4 Docs to Bookmark

- TileMapLayer: https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html
- NavigationAgent2D: https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html
- Tween: https://docs.godotengine.org/en/stable/classes/class_tween.html
- GDQuest YouTube: best free Godot tutorials, has hex grid + RTS content
