# Volley Shot Survivor

## Dimension

2D Godot project using GDScript.

## Input Actions

| Action | Keys |
|--------|------|
| shoot | Space |
| restart | R |

Mouse:
- Hold/release left mouse button mirrors `shoot`.
- Mouse horizontal position controls aim angle and bend direction.

## Scenes

### Main
- **File:** `res://scenes/main.tscn`
- **Root type:** `Node2D`
- **Script:** `res://scripts/Main.gd`
- **Responsibilities:** Owns game state, procedural drawing, input, ball feeding, volley shots, enemies, scoring, UI, and restart.

## Scripts

### Main
- **File:** `res://scripts/Main.gd`
- **Extends:** `Node2D`
- **Instantiates:** No child scenes in v1; uses arrays of dictionaries for feed ball, shot balls, enemies, particles, and floating text.

## Asset Hints

- Future player sprite: footballer in striking stance, about 110x150 px.
- Future launcher sprite: compact football feeder machine, about 120x80 px.
- Future enemy sprite: simple robot defender or target dummy, about 60x70 px.
- Future ball sprite: football with strong spin readability, about 32x32 px.
- Future field background: TV challenge show football field, 1280x720.

## Build Order

1. Godot runs `res://scenes/main.tscn` directly.
2. No generated scene builders are required for the GDScript prototype.
