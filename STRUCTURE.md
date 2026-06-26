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
- **Responsibilities:** Owns game state, image-backed drawing, input, ball feeding, volley shots, enemies, scoring, UI, and restart.

## Scripts

### Main
- **File:** `res://scripts/Main.gd`
- **Extends:** `Node2D`
- **Instantiates:** No child scenes in v1; uses arrays of dictionaries for feed ball, shot balls, enemies, particles, and floating text.

## Asset Hints

- Runtime art is in `res://assets/img/`.
- Original generated sheets are in `_meta/generated_sources/`.
- `tools/process_generated_assets.py` crops and converts generated sheets into transparent runtime sprites.
- Most animation and gameplay feedback still comes from code: ball trails, particles, shake, hit text, power bar, wave bar, and aim line.

## Build Order

1. Godot runs `res://scenes/main.tscn` directly.
2. No generated scene builders are required for the GDScript prototype.
